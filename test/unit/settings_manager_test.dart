import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skytunnel/services/logger_service.dart';
import 'package:skytunnel/services/settings_manager.dart';
import 'package:skytunnel/models/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsManager', () {
    late SettingsManager manager;
    late LoggerService logger;

    setUp(() async {
      logger = LoggerService();
      manager = SettingsManager(logger);
      await manager.init();
    });

    tearDown(() {
      manager.dispose();
      logger.dispose();
    });

    test('initial settings are defaults', () {
      expect(manager.settings, const AppSettings());
      expect(manager.settings.darkMode, isTrue);
      expect(manager.settings.autoReconnect, isTrue);
    });

    test('updateSettings persists values', () async {
      final newSettings = manager.settings.copyWith(
        ngrokAuthToken: 'test-token-123',
        darkMode: false,
      );
      await manager.updateSettings(newSettings);
      expect(manager.settings.ngrokAuthToken, 'test-token-123');
      expect(manager.settings.darkMode, isFalse);
    });

    test('updateField updates single field', () async {
      await manager.updateField('defaultPort', 7777);
      expect(manager.settings.defaultPort, 7777);
      expect(manager.settings.darkMode, isTrue);
    });

    test('onSettingsChanged emits on update', () async {
      final updates = <AppSettings>[];
      manager.onSettingsChanged.listen((s) => updates.add(s));
      await manager.updateField('darkMode', false);
      // Allow stream to emit.
      await Future.delayed(Duration.zero);
      expect(updates.length, 1);
      expect(updates.first.darkMode, isFalse);
    });

    test('clearAll resets to defaults', () async {
      await manager.updateField('ngrokAuthToken', 'token');
      await manager.clearAll();
      expect(manager.settings.ngrokAuthToken, isEmpty);
      expect(manager.settings.darkMode, isTrue);
    });

    test('custom profiles can be saved and loaded', () async {
      final profiles = [
        {'id': 'custom_1', 'name': 'My Game', 'defaultPort': 9999},
      ];
      await manager.saveCustomProfiles(profiles);
      final loaded = manager.loadCustomProfiles();
      expect(loaded.length, 1);
      expect(loaded.first['name'], 'My Game');
    });

    test('loadCustomProfiles returns empty when none saved', () {
      final loaded = manager.loadCustomProfiles();
      expect(loaded, isEmpty);
    });

    test('persists across re-init', () async {
      await manager.updateField('ngrokAuthToken', 'persistent-token');
      // Re-initialize a new manager with same prefs.
      final manager2 = SettingsManager(logger);
      await manager2.init();
      expect(manager2.settings.ngrokAuthToken, 'persistent-token');
      manager2.dispose();
    });
  });
}
