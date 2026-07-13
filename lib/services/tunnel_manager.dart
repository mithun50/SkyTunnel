import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/tunnel.dart';
import 'logger_service.dart';
import 'ngrok_service.dart';
import 'settings_manager.dart';

/// Manages multiple TCP tunnels through ngrok.
class TunnelManager {
  final LoggerService _logger;
  final NgrokService _ngrokService;
  final SettingsManager _settingsManager;

  final List<Tunnel> _tunnels = [];
  final StreamController<List<Tunnel>> _tunnelsController =
      StreamController<List<Tunnel>>.broadcast();
  final StreamController<Tunnel> _tunnelUpdateController =
      StreamController<Tunnel>.broadcast();

  Timer? _statsTimer;
  Timer? _healthTimer;
  final Map<String, int> _reconnectAttempts = {};

  TunnelManager(
    this._logger,
    this._ngrokService,
    this._settingsManager,
  );

  List<Tunnel> get tunnels => List.unmodifiable(_tunnels);
  Stream<List<Tunnel>> get onTunnelsChanged => _tunnelsController.stream;
  Stream<Tunnel> get onTunnelUpdated => _tunnelUpdateController.stream;

  /// Number of active (connected) tunnels.
  int get activeTunnelCount =>
      _tunnels.where((t) => t.status.isActive).length;

  /// Initializes by loading saved tunnel configurations.
  Future<void> init() async {
    await _loadTunnels();
    _logger.info('TunnelManager initialized with ${_tunnels.length} tunnels',
        source: 'TunnelManager');
  }

  /// Creates and starts a new tunnel.
  Future<Tunnel?> createTunnel({
    required String name,
    required String gameId,
    required int localPort,
    int? remotePort,
  }) async {
    // Ensure ngrok API server is running.
    final apiStarted = await _ngrokService.startNgrokApiServer();
    if (!apiStarted) {
      _logger.error('Failed to start ngrok API', source: 'TunnelManager');
      return null;
    }

    final tunnelId = 'tunnel_${DateTime.now().millisecondsSinceEpoch}';
    var tunnel = Tunnel(
      id: tunnelId,
      name: name,
      localPort: localPort,
      gameId: gameId,
      remotePort: remotePort,
      createdAt: DateTime.now(),
      status: TunnelStatus.connecting,
    );

    _tunnels.add(tunnel);
    _notifyTunnelsChanged();

    _logger.info('Starting tunnel: $name ($gameId) on port $localPort',
        source: 'TunnelManager', tunnelId: tunnelId);

    // Create the tunnel via ngrok API.
    final result = await _ngrokService.createTcpTunnel(
      localPort: localPort,
      name: tunnelId,
      remotePort: remotePort,
    );

    if (result == null) {
      tunnel = tunnel.copyWith(
        status: TunnelStatus.error,
        errorMessage: 'Failed to create tunnel via ngrok API',
      );
      _updateTunnel(tunnel);
      return null;
    }

    final publicUrl = result['public_url'] as String?;
    // Extract host:port from tcp://host:port
    String? publicAddress;
    if (publicUrl != null && publicUrl.startsWith('tcp://')) {
      publicAddress = publicUrl.substring(6);
    }

    tunnel = tunnel.copyWith(
      status: TunnelStatus.connected,
      publicAddress: publicAddress,
      publicUrl: publicUrl,
      connectedAt: DateTime.now(),
      clearErrorMessage: true,
    );

    _updateTunnel(tunnel);
    _reconnectAttempts.remove(tunnelId);
    await _saveTunnels();

    _logger.success(
        'Tunnel active: $name -> $publicAddress',
        source: 'TunnelManager',
        tunnelId: tunnelId);

    return tunnel;
  }

  /// Stops a running tunnel.
  Future<void> stopTunnel(String tunnelId) async {
    final index = _tunnels.indexWhere((t) => t.id == tunnelId);
    if (index == -1) return;

    var tunnel = _tunnels[index];
    _logger.info('Stopping tunnel: ${tunnel.name}',
        source: 'TunnelManager', tunnelId: tunnelId);

    // Delete via ngrok API.
    await _ngrokService.deleteTunnel(tunnelId);

    tunnel = tunnel.copyWith(
      status: TunnelStatus.disconnected,
      disconnectedAt: DateTime.now(),
      clearPublicAddress: true,
    );

    _updateTunnel(tunnel);
    _reconnectAttempts.remove(tunnelId);
    await _saveTunnels();
  }

  /// Restarts a tunnel (stop + start with same config).
  Future<void> restartTunnel(String tunnelId) async {
    final index = _tunnels.indexWhere((t) => t.id == tunnelId);
    if (index == -1) return;

    final tunnel = _tunnels[index];
    final name = tunnel.name;
    final gameId = tunnel.gameId;
    final localPort = tunnel.localPort;
    final remotePort = tunnel.remotePort;

    await stopTunnel(tunnelId);
    // Brief pause before restart.
    await Future.delayed(const Duration(seconds: 1));
    await createTunnel(
      name: name,
      gameId: gameId,
      localPort: localPort,
      remotePort: remotePort,
    );
  }

  /// Removes a tunnel entirely.
  Future<void> removeTunnel(String tunnelId) async {
    await stopTunnel(tunnelId);
    _tunnels.removeWhere((t) => t.id == tunnelId);
    _notifyTunnelsChanged();
    await _saveTunnels();
    _logger.info('Tunnel removed: $tunnelId', source: 'TunnelManager');
  }

  /// Stops all tunnels.
  Future<void> stopAllTunnels() async {
    for (final tunnel in List<Tunnel>.from(_tunnels)) {
      if (tunnel.status.isActive || tunnel.status.isTransition) {
        await stopTunnel(tunnel.id);
      }
    }
  }

  /// Starts periodic stats collection for active tunnels.
  void startStatsCollection({Duration interval = const Duration(seconds: 15)}) {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(interval, (_) => _collectStats());
  }

  /// Stops stats collection.
  void stopStatsCollection() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  /// Starts health monitoring with auto-reconnect.
  void startHealthMonitoring(
      {Duration interval = const Duration(seconds: 30)}) {
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(interval, (_) => _checkHealth());
  }

  /// Stops health monitoring.
  void stopHealthMonitoring() {
    _healthTimer?.cancel();
    _healthTimer = null;
  }

  /// Reconnects a single tunnel.
  Future<void> _attemptReconnect(String tunnelId) async {
    if (!_settingsManager.settings.autoReconnect) return;

    final maxAttempts = _settingsManager.settings.maxReconnectAttempts;
    final attempts = _reconnectAttempts[tunnelId] ?? 0;

    if (attempts >= maxAttempts) {
      _logger.warning(
          'Max reconnect attempts reached for $tunnelId',
          source: 'TunnelManager',
          tunnelId: tunnelId);
      return;
    }

    _reconnectAttempts[tunnelId] = attempts + 1;
    final delay = _settingsManager.settings.reconnectDelaySeconds;

    _logger.info(
        'Reconnecting tunnel $tunnelId (attempt ${attempts + 1}/$maxAttempts) in ${delay}s...',
        source: 'TunnelManager',
        tunnelId: tunnelId);

    await Future.delayed(Duration(seconds: delay));

    final index = _tunnels.indexWhere((t) => t.id == tunnelId);
    if (index == -1) return;

    final tunnel = _tunnels[index];
    _updateTunnel(tunnel.copyWith(status: TunnelStatus.reconnecting));

    final result = await _ngrokService.createTcpTunnel(
      localPort: tunnel.localPort,
      name: tunnelId,
      remotePort: tunnel.remotePort,
    );

    if (result != null) {
      final publicUrl = result['public_url'] as String?;
      String? publicAddress;
      if (publicUrl != null && publicUrl.startsWith('tcp://')) {
        publicAddress = publicUrl.substring(6);
      }

      _updateTunnel(tunnel.copyWith(
        status: TunnelStatus.connected,
        publicAddress: publicAddress,
        publicUrl: publicUrl,
        connectedAt: DateTime.now(),
        clearErrorMessage: true,
      ));
      _reconnectAttempts.remove(tunnelId);

      _logger.success(
          'Tunnel reconnected: ${tunnel.name} -> $publicAddress',
          source: 'TunnelManager',
          tunnelId: tunnelId);
    } else {
      _updateTunnel(tunnel.copyWith(
        status: TunnelStatus.error,
        errorMessage: 'Reconnect failed',
      ));
      // Schedule another attempt.
      _attemptReconnect(tunnelId);
    }
  }

  /// Checks health of all tunnels and reconnects if needed.
  Future<void> _checkHealth() async {
    for (final tunnel in List<Tunnel>.from(_tunnels)) {
      if (!tunnel.status.isActive) continue;

      try {
        final details =
            await _ngrokService.getTunnelDetails(tunnel.id);
        if (details == null) {
          // Tunnel not found in ngrok, mark as disconnected.
          _updateTunnel(tunnel.copyWith(
            status: TunnelStatus.disconnected,
            disconnectedAt: DateTime.now(),
            clearPublicAddress: true,
          ));
          _attemptReconnect(tunnel.id);
        }
      } catch (e) {
        _logger.warning(
            'Health check failed for ${tunnel.name}: $e',
            source: 'TunnelManager',
            tunnelId: tunnel.id);
      }
    }
  }

  /// Collects stats for all active tunnels.
  Future<void> _collectStats() async {
    for (final tunnel in List<Tunnel>.from(_tunnels)) {
      if (!tunnel.status.isActive) continue;

      try {
        final stats =
            await _ngrokService.getTunnelStats(tunnel.id);
        if (stats != null) {
          final conns = stats['conns'] as Map<String, dynamic>?;
          final bytesIn = conns?['bytes_in'] as int? ?? 0;
          final bytesOut = conns?['bytes_out'] as int? ?? 0;
          final count = conns?['count'] as int? ?? 0;

          _updateTunnel(tunnel.copyWith(
            bytesIn: bytesIn,
            bytesOut: bytesOut,
            activeConnections: count,
          ));
        }
      } catch (_) {}
    }
  }

  void _updateTunnel(Tunnel updated) {
    final index = _tunnels.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _tunnels[index] = updated;
      _notifyTunnelsChanged();
      _tunnelUpdateController.add(updated);
    }
  }

  void _notifyTunnelsChanged() {
    _tunnelsController.add(List<Tunnel>.from(_tunnels));
  }

  /// Persists tunnel configurations.
  Future<void> _saveTunnels() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/tunnels.json');
      final json = _tunnels.map((t) => t.toJson()).toList();
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      _logger.warning('Failed to save tunnels: $e',
          source: 'TunnelManager');
    }
  }

  /// Loads persisted tunnel configurations.
  Future<void> _loadTunnels() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/tunnels.json');
      if (await file.exists()) {
        final json = await file.readAsString();
        final List<dynamic> decoded = jsonDecode(json);
        _tunnels.clear();
        for (final item in decoded) {
          final tunnel = Tunnel.fromJson(item as Map<String, dynamic>);
          // Reset any connecting/reconnecting tunnels to disconnected.
          if (tunnel.status.isTransition) {
            _tunnels.add(tunnel.copyWith(
                status: TunnelStatus.disconnected,
                clearDisconnectedAt: false));
          } else {
            _tunnels.add(tunnel);
          }
        }
        _notifyTunnelsChanged();
      }
    } catch (e) {
      _logger.warning('Failed to load tunnels: $e',
          source: 'TunnelManager');
    }
  }

  void dispose() {
    stopStatsCollection();
    stopHealthMonitoring();
    _tunnelsController.close();
    _tunnelUpdateController.close();
  }
}
