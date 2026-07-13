import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ngrok_status.dart';
import 'logger_service.dart';
import 'process_manager.dart';
import 'settings_manager.dart';

/// Core service for interacting with ngrok (process + local API).
class NgrokService {
  static const String _apiBase = 'http://127.0.0.1:4040';
  static const String _apiTunnels = '$_apiBase/api/tunnels';

  final LoggerService _logger;
  final ProcessManager _processManager;
  final SettingsManager _settingsManager;

  NgrokStatus _status = const NgrokStatus();
  Timer? _healthCheckTimer;
  final StreamController<NgrokStatus> _statusController =
      StreamController<NgrokStatus>.broadcast();

  NgrokService(this._logger, this._processManager, this._settingsManager);

  NgrokStatus get status => _status;
  Stream<NgrokStatus> get onStatusChanged => _statusController.stream;

  /// Initializes ngrok service and detects installation.
  Future<void> init() async {
    await detectNgrok();
  }

  /// Detects ngrok installation and version.
  Future<NgrokStatus> detectNgrok() async {
    _logger.info('Detecting ngrok installation...', source: 'NgrokService');

    // Check custom path first, then auto-detect.
    String? ngrokPath;
    final customPath = _settingsManager.settings.ngrokPath;
    if (customPath.isNotEmpty) {
      final fullPath = customPath.endsWith('ngrok')
          ? customPath
          : '$customPath/ngrok${Platform.isWindows ? '.exe' : ''}';
      if (await File(fullPath).exists()) {
        ngrokPath = fullPath;
      }
    }

    ngrokPath ??= await _processManager.findNgrokExecutable();

    if (ngrokPath == null) {
      _updateStatus(_status.copyWith(
        installationStatus: NgrokInstallationStatus.notInstalled,
        clearErrorMessage: true,
      ));
      _logger.warning('ngrok not found', source: 'NgrokService');
      return _status;
    }

    _logger.info('Found ngrok at: $ngrokPath', source: 'NgrokService');

    // Get version.
    try {
      final result = await Process.run(ngrokPath, ['version']);
      final version = (result.stdout as String).trim();
      _updateStatus(_status.copyWith(
        installationStatus: NgrokInstallationStatus.installed,
        ngrokVersion: version,
        ngrokPath: ngrokPath,
        clearErrorMessage: true,
      ));
      _logger.info('ngrok version: $version', source: 'NgrokService');
    } catch (e) {
      _updateStatus(_status.copyWith(
        installationStatus: NgrokInstallationStatus.error,
        errorMessage: 'Failed to get version: $e',
      ));
    }

    // Check auth.
    await checkAuth();

    return _status;
  }

  /// Checks if ngrok is authenticated.
  Future<NgrokAuthStatus> checkAuth() async {
    _updateStatus(_status.copyWith(
      authStatus: NgrokAuthStatus.checking,
    ));

    final ngrokPath = _status.ngrokPath;
    if (ngrokPath == null) {
      _updateStatus(_status.copyWith(
        authStatus: NgrokAuthStatus.unknown,
      ));
      return NgrokAuthStatus.unknown;
    }

    try {
      final result = await Process.run(ngrokPath, ['config', 'check']);
      final output = (result.stdout as String) + (result.stderr as String);

      // Check for valid auth token.
      if (output.contains('Valid') ||
          output.contains('is valid') ||
          (result.exitCode == 0 && !output.contains('Error'))) {
        _updateStatus(_status.copyWith(
          authStatus: NgrokAuthStatus.authenticated,
          clearErrorMessage: true,
        ));
        _logger.info('ngrok is authenticated', source: 'NgrokService');
        return NgrokAuthStatus.authenticated;
      }
    } catch (_) {}

    // Fall back to checking the API if ngrok is running.
    try {
      final tunnels = await getActiveTunnels();
      if (tunnels.isNotEmpty) {
        _updateStatus(_status.copyWith(
          authStatus: NgrokAuthStatus.authenticated,
          clearErrorMessage: true,
        ));
        return NgrokAuthStatus.authenticated;
      }
    } catch (_) {}

    // Check if token is set in settings.
    final token = _settingsManager.settings.ngrokAuthToken;
    if (token.isNotEmpty) {
      // Try authenticating with the stored token.
      return await authenticate(token);
    }

    _updateStatus(_status.copyWith(
      authStatus: NgrokAuthStatus.notAuthenticated,
    ));
    return NgrokAuthStatus.notAuthenticated;
  }

  /// Authenticates ngrok with the given auth token.
  Future<NgrokAuthStatus> authenticate(String token) async {
    final ngrokPath = _status.ngrokPath;
    if (ngrokPath == null) {
      _logger.error('Cannot authenticate: ngrok not found',
          source: 'NgrokService');
      return NgrokAuthStatus.notAuthenticated;
    }

    _logger.info('Authenticating ngrok...', source: 'NgrokService');

    try {
      final result = await Process.run(
        ngrokPath,
        ['config', 'add-authtoken', token],
      );

      if (result.exitCode == 0) {
        _updateStatus(_status.copyWith(
          authStatus: NgrokAuthStatus.authenticated,
          clearErrorMessage: true,
        ));
        _logger.success('ngrok authenticated successfully',
            source: 'NgrokService');
        return NgrokAuthStatus.authenticated;
      } else {
        final error = (result.stderr as String).trim();
        _updateStatus(_status.copyWith(
          authStatus: NgrokAuthStatus.notAuthenticated,
          errorMessage: error,
        ));
        _logger.error('Auth failed: $error', source: 'NgrokService');
        return NgrokAuthStatus.notAuthenticated;
      }
    } catch (e) {
      _updateStatus(_status.copyWith(
        authStatus: NgrokAuthStatus.notAuthenticated,
        errorMessage: e.toString(),
      ));
      _logger.error('Auth error: $e', source: 'NgrokService');
      return NgrokAuthStatus.notAuthenticated;
    }
  }

  /// Starts the ngrok HTTP API server (ngrok http 0).
  Future<bool> startNgrokApiServer() async {
    final ngrokPath = _status.ngrokPath;
    if (ngrokPath == null) return false;

    // Check if API is already available.
    try {
      await getActiveTunnels();
      _logger.info('ngrok API already running', source: 'NgrokService');
      return true;
    } catch (_) {}

    _logger.info('Starting ngrok API server...', source: 'NgrokService');

    final info = await _processManager.startProcess(
      processId: 'ngrok_api',
      executable: ngrokPath,
      arguments: ['http', '0', '--log=stdout', '--log-format=json'],
    );

    if (info == null) {
      _logger.error('Failed to start ngrok API server',
          source: 'NgrokService');
      return false;
    }

    // Listen to stdout for structured log output.
    info.stdout?.listen((line) {
      _parseNgrokLog(line);
    });

    info.stderr?.listen((line) {
      _parseNgrokLog(line);
    });

    // Wait for the API to become available.
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        await getActiveTunnels();
        _logger.success('ngrok API server started',
            source: 'NgrokService');
        return true;
      } catch (_) {}
    }

    _logger.warning('ngrok API server may still be starting',
        source: 'NgrokService');
    return true;
  }

  /// Creates a TCP tunnel via the ngrok API.
  Future<Map<String, dynamic>?> createTcpTunnel({
    required int localPort,
    required String name,
    int? remotePort,
  }) async {
    _logger.info(
        'Creating TCP tunnel: $name -> localhost:$localPort',
        source: 'NgrokService');

    try {
      final body = {
        'name': name,
        'addr': 'localhost:$localPort',
        'proto': 'tcp',
      };

      if (remotePort != null) {
        body['remote_addr'] = '0.0.0.0:$remotePort';
      }

      final response = await http.post(
        Uri.parse(_apiTunnels),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final publicUrl = data['public_url'] as String?;
        _logger.success(
            'Tunnel created: $publicUrl',
            source: 'NgrokService');
        return data;
      } else {
        final error =
            jsonDecode(response.body) as Map<String, dynamic>;
        final msg = error['error']?['msg'] as String? ?? 'Unknown error';
        _logger.error('Failed to create tunnel: $msg',
            source: 'NgrokService');
        return null;
      }
    } catch (e) {
      _logger.error('Tunnel creation error: $e', source: 'NgrokService');
      return null;
    }
  }

  /// Deletes a tunnel by name.
  Future<bool> deleteTunnel(String tunnelName) async {
    _logger.info('Deleting tunnel: $tunnelName', source: 'NgrokService');
    try {
      final response = await http.delete(
        Uri.parse('$_apiTunnels/$tunnelName'),
      );
      if (response.statusCode == 204) {
        _logger.success('Tunnel deleted: $tunnelName',
            source: 'NgrokService');
        return true;
      }
      _logger.warning(
          'Delete returned ${response.statusCode}',
          source: 'NgrokService');
      return false;
    } catch (e) {
      _logger.error('Delete tunnel error: $e', source: 'NgrokService');
      return false;
    }
  }

  /// Gets all active tunnels from the ngrok API.
  Future<List<Map<String, dynamic>>> getActiveTunnels() async {
    final response = await http.get(Uri.parse(_apiTunnels));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tunnels = data['tunnels'] as List<dynamic>?;
      if (tunnels == null) return [];
      return tunnels.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to get tunnels: ${response.statusCode}');
  }

  /// Gets tunnel details from the ngrok API.
  Future<Map<String, dynamic>?> getTunnelDetails(String tunnelName) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiTunnels/$tunnelName'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Gets connection metadata (bytes transferred, active connections).
  Future<Map<String, dynamic>?> getTunnelStats(String tunnelName) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiTunnels/$tunnelName/connections'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Starts health checking for the ngrok API.
  void startHealthCheck({Duration interval = const Duration(seconds: 10)}) {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(interval, (_) async {
      try {
        await getActiveTunnels();
      } catch (_) {
        // API might be down.
      }
    });
  }

  /// Stops health checking.
  void stopHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  /// Parses ngrok's JSON log output for useful events.
  void _parseNgrokLog(String line) {
    try {
      final data = jsonDecode(line) as Map<String, dynamic>;
      final level = data['lvl'] as String?;
      final message = data['msg'] as String?;
      final err = data['err'] as String?;

      if (err != null && err.isNotEmpty) {
        _logger.error('[ngrok] $err', source: 'ngrok');
      } else if (level == 'err') {
        _logger.error('[ngrok] $message', source: 'ngrok');
      } else if (level == 'warn') {
        _logger.warning('[ngrok] $message', source: 'ngrok');
      } else if (message != null) {
        _logger.debug('[ngrok] $message', source: 'ngrok');
      }
    } catch (_) {
      // Non-JSON log line.
      if (line.trim().isNotEmpty) {
        _logger.debug('[ngrok] $line', source: 'ngrok');
      }
    }
  }

  void _updateStatus(NgrokStatus newStatus) {
    _status = newStatus;
    _statusController.add(_status);
  }

  void dispose() {
    stopHealthCheck();
    _statusController.close();
  }
}
