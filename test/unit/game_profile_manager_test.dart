import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skytunnel/services/logger_service.dart';
import 'package:skytunnel/services/settings_manager.dart';
import 'package:skytunnel/services/game_profile_manager.dart';
import 'package:skytunnel/models/game_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GameProfileManager', () {
    late GameProfileManager manager;
    late LoggerService logger;
    late SettingsManager settingsManager;

    setUp(() async {
      logger = LoggerService();
      settingsManager = SettingsManager(logger);
      await settingsManager.init();
      manager = GameProfileManager(logger, settingsManager);
      await manager.init();
    });

    tearDown(() {
      manager.dispose();
      settingsManager.dispose();
      logger.dispose();
    });

    test('has all built-in profiles', () {
      expect(manager.allProfiles.length, GameProfile.builtInProfiles.length);
    });

    test('findById returns correct profile', () {
      final profile = manager.findById('terraria');
      expect(profile, isNotNull);
      expect(profile!.name, 'Terraria');
      expect(profile.defaultPort, 7777);
    });

    test('findById returns null for unknown', () {
      expect(manager.findById('nonexistent'), isNull);
    });

    test('addCustomProfile adds to list', () async {
      final profile = GameProfile(
        id: '',
        name: 'Custom Game',
        description: 'A custom game',
        defaultPort: 5555,
        icon: '🎮',
      );
      await manager.addCustomProfile(profile);
      expect(manager.customProfiles.length, 1);
      expect(manager.customProfiles.first.name, 'Custom Game');
      expect(manager.customProfiles.first.isCustom, isTrue);
    });

    test('removeCustomProfile removes from list', () async {
      final profile = GameProfile(
        id: '',
        name: 'To Delete',
        description: '',
        defaultPort: 1111,
        icon: '🗑️',
      );
      await manager.addCustomProfile(profile);
      final id = manager.customProfiles.first.id;
      await manager.removeCustomProfile(id);
      expect(manager.customProfiles.length, 0);
    });

    test('custom profiles included in allProfiles', () async {
      expect(manager.allProfiles.length, GameProfile.builtInProfiles.length);
      await manager.addCustomProfile(GameProfile(
        id: '',
        name: 'Added',
        description: '',
        defaultPort: 2222,
        icon: '➕',
      ));
      expect(manager.allProfiles.length, GameProfile.builtInProfiles.length + 1);
    });

    test('onProfilesChanged emits on add', () async {
      final changes = <List<GameProfile>>[];
      manager.onProfilesChanged.listen((p) => changes.add(p));
      await manager.addCustomProfile(GameProfile(
        id: '',
        name: 'Stream Test',
        description: '',
        defaultPort: 3333,
        icon: '📡',
      ));
      await Future.delayed(Duration.zero);
      expect(changes.length, 1);
    });

    test('updateCustomProfile updates existing', () async {
      await manager.addCustomProfile(GameProfile(
        id: '',
        name: 'Original',
        description: '',
        defaultPort: 4444,
        icon: '📝',
      ));
      final id = manager.customProfiles.first.id;
      await manager.updateCustomProfile(GameProfile(
        id: id,
        name: 'Updated',
        description: 'Updated desc',
        defaultPort: 5555,
        icon: '✅',
      ));
      expect(manager.customProfiles.first.name, 'Updated');
      expect(manager.customProfiles.first.defaultPort, 5555);
    });
  });
}
