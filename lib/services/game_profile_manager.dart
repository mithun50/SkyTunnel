import 'dart:async';
import '../models/game_profile.dart';
import 'logger_service.dart';
import 'settings_manager.dart';

/// Manages game profiles (built-in and custom).
class GameProfileManager {
  final LoggerService _logger;
  final SettingsManager _settingsManager;
  final List<GameProfile> _customProfiles = [];
  final StreamController<List<GameProfile>> _profilesController =
      StreamController<List<GameProfile>>.broadcast();

  GameProfileManager(this._logger, this._settingsManager);

  /// All available profiles (built-in + custom).
  List<GameProfile> get allProfiles =>
      GameProfile.builtInProfiles + _customProfiles;

  /// Only custom profiles.
  List<GameProfile> get customProfiles => List.unmodifiable(_customProfiles);

  /// Stream of profile list changes.
  Stream<List<GameProfile>> get onProfilesChanged =>
      _profilesController.stream;

  /// Initializes by loading custom profiles from settings.
  Future<void> init() async {
    final saved = _settingsManager.loadCustomProfiles();
    _customProfiles.clear();
    for (final json in saved) {
      try {
        _customProfiles.add(GameProfile.fromJson(json));
      } catch (e) {
        _logger.warning('Failed to load custom profile: $e',
            source: 'GameProfileManager');
      }
    }
    _logger.info(
        'Loaded ${_customProfiles.length} custom profiles',
        source: 'GameProfileManager');
  }

  /// Finds a profile by ID.
  GameProfile? findById(String id) {
    return GameProfile.findById(id, custom: _customProfiles);
  }

  /// Adds a custom profile.
  Future<void> addCustomProfile(GameProfile profile) async {
    final custom = profile.copyWith(isCustom: true, id: 'custom_${DateTime.now().millisecondsSinceEpoch}');
    _customProfiles.add(custom);
    await _persistCustomProfiles();
    _profilesController.add(allProfiles);
    _logger.info('Added custom profile: ${custom.name}',
        source: 'GameProfileManager');
  }

  /// Updates a custom profile.
  Future<void> updateCustomProfile(GameProfile profile) async {
    final index = _customProfiles.indexWhere((p) => p.id == profile.id);
    if (index == -1) return;
    _customProfiles[index] = profile;
    await _persistCustomProfiles();
    _profilesController.add(allProfiles);
    _logger.info('Updated custom profile: ${profile.name}',
        source: 'GameProfileManager');
  }

  /// Removes a custom profile.
  Future<void> removeCustomProfile(String profileId) async {
    _customProfiles.removeWhere((p) => p.id == profileId);
    await _persistCustomProfiles();
    _profilesController.add(allProfiles);
    _logger.info('Removed custom profile: $profileId',
        source: 'GameProfileManager');
  }

  Future<void> _persistCustomProfiles() async {
    final jsonList = _customProfiles.map((p) => p.toJson()).toList();
    await _settingsManager.saveCustomProfiles(jsonList);
  }

  void dispose() {
    _profilesController.close();
  }
}
