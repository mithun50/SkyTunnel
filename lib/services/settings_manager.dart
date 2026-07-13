import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import 'logger_service.dart';

/// Manages persistent application settings using shared_preferences.
class SettingsManager {
  static const String _settingsKey = 'sky_tunnel_settings';
  static const String _customProfilesKey = 'sky_tunnel_custom_profiles';

  final LoggerService _logger;
  AppSettings _settings = const AppSettings();
  SharedPreferences? _prefs;
  final StreamController<AppSettings> _settingsController =
      StreamController<AppSettings>.broadcast();

  SettingsManager(this._logger);

  /// Current settings.
  AppSettings get settings => _settings;

  /// Stream of settings changes.
  Stream<AppSettings> get onSettingsChanged => _settingsController.stream;

  /// Initializes settings from persistent storage.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
    _logger.info('Settings loaded', source: 'SettingsManager');
  }

  /// Updates settings and persists them.
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    _settingsController.add(_settings);
    _logger.info('Settings updated', source: 'SettingsManager');
  }

  /// Updates a single setting field.
  Future<void> updateField<T>(String field, T value) async {
    switch (field) {
      case 'ngrokAuthToken':
        _settings = _settings.copyWith(ngrokAuthToken: value as String);
        break;
      case 'defaultGameId':
        _settings = _settings.copyWith(defaultGameId: value as String);
        break;
      case 'defaultPort':
        _settings = _settings.copyWith(defaultPort: value as int);
        break;
      case 'launchOnStartup':
        _settings = _settings.copyWith(launchOnStartup: value as bool);
        break;
      case 'autoReconnect':
        _settings = _settings.copyWith(autoReconnect: value as bool);
        break;
      case 'darkMode':
        _settings = _settings.copyWith(darkMode: value as bool);
        break;
      case 'checkForUpdates':
        _settings = _settings.copyWith(checkForUpdates: value as bool);
        break;
      case 'ngrokPath':
        _settings = _settings.copyWith(ngrokPath: value as String);
        break;
    }
    await _saveSettings();
    _settingsController.add(_settings);
  }

  /// Clears all stored settings.
  Future<void> clearAll() async {
    _settings = const AppSettings();
    await _prefs?.remove(_settingsKey);
    _settingsController.add(_settings);
    _logger.info('Settings cleared', source: 'SettingsManager');
  }

  /// Saves custom game profiles.
  Future<void> saveCustomProfiles(List<Map<String, dynamic>> profiles) async {
    await _prefs?.setString(_customProfilesKey, jsonEncode(profiles));
  }

  /// Loads custom game profiles.
  List<Map<String, dynamic>> loadCustomProfiles() {
    final json = _prefs?.getString(_customProfilesKey);
    if (json == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<void> _loadSettings() async {
    final json = _prefs?.getString(_settingsKey);
    if (json != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(json);
        _settings = AppSettings.fromJson(decoded);
      } catch (e) {
        _logger.warning('Failed to parse saved settings, using defaults',
            source: 'SettingsManager');
        _settings = const AppSettings();
      }
    }
  }

  Future<void> _saveSettings() async {
    final json = jsonEncode(_settings.toJson());
    await _prefs?.setString(_settingsKey, json);
  }

  void dispose() {
    _settingsController.close();
  }
}
