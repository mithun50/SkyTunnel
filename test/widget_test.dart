import 'package:flutter_test/flutter_test.dart';
import 'package:skytunnel/models/models.dart';

void main() {
  group('GameProfile', () {
    test('has built-in profiles', () {
      expect(GameProfile.builtInProfiles.length, greaterThanOrEqualTo(7));
    });

    test('finds profile by id', () {
      final profile = GameProfile.findById('minecraft_java');
      expect(profile, isNotNull);
      expect(profile!.name, 'Minecraft Java');
      expect(profile.defaultPort, 25565);
    });

    test('returns null for unknown id', () {
      expect(GameProfile.findById('nonexistent'), isNull);
    });

    test('serializes to JSON', () {
      const profile = GameProfile(
        id: 'test',
        name: 'Test',
        description: 'A test',
        defaultPort: 1234,
        icon: '🎮',
      );
      final json = profile.toJson();
      expect(json['id'], 'test');
      expect(json['defaultPort'], 1234);
    });

    test('deserializes from JSON', () {
      final json = {
        'id': 'test',
        'name': 'Test',
        'description': 'A test',
        'defaultPort': 1234,
        'icon': '🎮',
        'isCustom': false,
      };
      final profile = GameProfile.fromJson(json);
      expect(profile.id, 'test');
      expect(profile.defaultPort, 1234);
    });
  });

  group('Tunnel', () {
    test('formats bytes correctly', () {
      final tunnel = Tunnel(
        id: 't1',
        name: 'Test',
        localPort: 25565,
        gameId: 'minecraft_java',
        createdAt: DateTime.now(),
        bytesIn: 1024 * 1024 * 5,
        bytesOut: 500,
      );
      expect(tunnel.formattedBytesIn, '5.0 MB');
      expect(tunnel.formattedBytesOut, '500 B');
    });

    test('displayAddress returns not connected when null', () {
      final tunnel = Tunnel(
        id: 't1',
        name: 'Test',
        localPort: 25565,
        gameId: 'minecraft_java',
        createdAt: DateTime.now(),
      );
      expect(tunnel.displayAddress, 'Not connected');
    });

    test('status displayName is correct', () {
      expect(TunnelStatus.connected.displayName, 'Connected');
      expect(TunnelStatus.disconnected.displayName, 'Disconnected');
      expect(TunnelStatus.error.displayName, 'Error');
    });

    test('status isActive is correct', () {
      expect(TunnelStatus.connected.isActive, isTrue);
      expect(TunnelStatus.reconnecting.isActive, isTrue);
      expect(TunnelStatus.disconnected.isActive, isFalse);
    });

    test('copyWith works correctly', () {
      final tunnel = Tunnel(
        id: 't1',
        name: 'Test',
        localPort: 25565,
        gameId: 'minecraft_java',
        createdAt: DateTime.now(),
      );
      final updated = tunnel.copyWith(name: 'Updated', localPort: 7777);
      expect(updated.name, 'Updated');
      expect(updated.localPort, 7777);
      expect(updated.id, 't1');
    });

    test('serializes and deserializes', () {
      final tunnel = Tunnel(
        id: 't1',
        name: 'Test',
        localPort: 25565,
        gameId: 'minecraft_java',
        createdAt: DateTime(2024),
        status: TunnelStatus.connected,
        publicAddress: '0.tcp.ngrok.io:12345',
      );
      final json = tunnel.toJson();
      final restored = Tunnel.fromJson(json);
      expect(restored.id, tunnel.id);
      expect(restored.name, tunnel.name);
      expect(restored.localPort, tunnel.localPort);
      expect(restored.publicAddress, tunnel.publicAddress);
    });
  });

  group('AppSettings', () {
    test('defaults are sensible', () {
      const settings = AppSettings();
      expect(settings.darkMode, isTrue);
      expect(settings.autoReconnect, isTrue);
      expect(settings.defaultPort, 25565);
      expect(settings.hasAuthToken, isFalse);
    });

    test('copyWith preserves values', () {
      const settings = AppSettings(ngrokAuthToken: 'abc');
      final updated = settings.copyWith(darkMode: false);
      expect(updated.ngrokAuthToken, 'abc');
      expect(updated.darkMode, isFalse);
    });

    test('serializes and deserializes', () {
      const settings = AppSettings(
        ngrokAuthToken: 'token123',
        defaultGameId: 'terraria',
        darkMode: false,
      );
      final json = settings.toJson();
      final restored = AppSettings.fromJson(json);
      expect(restored.ngrokAuthToken, 'token123');
      expect(restored.defaultGameId, 'terraria');
      expect(restored.darkMode, isFalse);
    });
  });

  group('LogEntry', () {
    test('formatted time has expected format', () {
      final entry = LogEntry(
        timestamp: DateTime(2024, 1, 15, 14, 30, 45, 123),
        level: LogLevel.info,
        message: 'Test message',
      );
      expect(entry.formattedTime, contains('14:30:45'));
    });

    test('formatted message includes level', () {
      final entry = LogEntry(
        timestamp: DateTime(2024),
        level: LogLevel.error,
        message: 'Something failed',
      );
      expect(entry.formattedMessage, contains('ERROR'));
      expect(entry.formattedMessage, contains('Something failed'));
    });
  });

  group('NgrokStatus', () {
    test('isReady when installed and authenticated', () {
      const status = NgrokStatus(
        installationStatus: NgrokInstallationStatus.installed,
        authStatus: NgrokAuthStatus.authenticated,
      );
      expect(status.isReady, isTrue);
    });

    test('isReady when not installed', () {
      const status = NgrokStatus(
        installationStatus: NgrokInstallationStatus.notInstalled,
        authStatus: NgrokAuthStatus.authenticated,
      );
      expect(status.isReady, isFalse);
    });

    test('copyWith preserves values', () {
      const status = NgrokStatus(
        installationStatus: NgrokInstallationStatus.installed,
        ngrokVersion: 'v3.0.0',
      );
      final updated = status.copyWith(
        authStatus: NgrokAuthStatus.authenticated,
      );
      expect(updated.installationStatus, NgrokInstallationStatus.installed);
      expect(updated.ngrokVersion, 'v3.0.0');
      expect(updated.authStatus, NgrokAuthStatus.authenticated);
    });
  });
}
