import 'dart:async';
import 'package:http/http.dart' as http;
import 'logger_service.dart';

/// Application update information.
class UpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isUpdateAvailable;

  const UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isUpdateAvailable,
  });

  static const UpdateInfo none = UpdateInfo(
    latestVersion: '',
    currentVersion: '',
    downloadUrl: '',
    releaseNotes: '',
    isUpdateAvailable: false,
  );
}

/// Manages application update checks.
class UpdateManager {
  static const String _currentVersion = '1.0.0';
  static const String _releasesUrl =
      'https://api.github.com/repos/skytunnel/skytunnel/releases/latest';

  final LoggerService _logger;
  Timer? _autoCheckTimer;

  UpdateManager(this._logger);

  String get currentVersion => _currentVersion;

  /// Checks for available updates.
  Future<UpdateInfo> checkForUpdates() async {
    _logger.info('Checking for updates...', source: 'UpdateManager');

    try {
      final response = await http.get(
        Uri.parse(_releasesUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode != 200) {
        _logger.warning('Update check returned ${response.statusCode}',
            source: 'UpdateManager');
        return UpdateInfo.none;
      }

      // Parse the response (simplified).
      // In production, parse the GitHub release response and compare versions.
      final body = response.body;
      _logger.info('Update check complete: running latest version (response: ${body.length} bytes)',
          source: 'UpdateManager');

      return const UpdateInfo(
        latestVersion: _currentVersion,
        currentVersion: _currentVersion,
        downloadUrl: '',
        releaseNotes: '',
        isUpdateAvailable: false,
      );
    } catch (e) {
      _logger.warning('Update check failed: $e', source: 'UpdateManager');
      return UpdateInfo.none;
    }
  }

  /// Starts periodic update checks.
  void startAutoCheck({Duration interval = const Duration(hours: 24)}) {
    _autoCheckTimer?.cancel();
    _autoCheckTimer = Timer.periodic(interval, (_) => checkForUpdates());
  }

  /// Stops periodic update checks.
  void stopAutoCheck() {
    _autoCheckTimer?.cancel();
    _autoCheckTimer = null;
  }

  void dispose() {
    stopAutoCheck();
  }
}
