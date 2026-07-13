import 'package:flutter_test/flutter_test.dart';
import 'package:skytunnel/services/logger_service.dart';
import 'package:skytunnel/models/log_entry.dart';

void main() {
  group('LoggerService', () {
    late LoggerService logger;

    setUp(() {
      logger = LoggerService();
    });

    tearDown(() {
      logger.dispose();
    });

    test('info adds entry with correct level', () {
      logger.info('Test message');
      expect(logger.entries.length, 1);
      expect(logger.entries.first.level, LogLevel.info);
      expect(logger.entries.first.message, 'Test message');
    });

    test('error adds entry with error level', () {
      logger.error('Error occurred');
      expect(logger.entries.first.level, LogLevel.error);
      expect(logger.entries.first.message, 'Error occurred');
    });

    test('warning adds entry with warning level', () {
      logger.warning('Warning');
      expect(logger.entries.first.level, LogLevel.warning);
    });

    test('debug adds entry with debug level', () {
      logger.debug('Debug info');
      expect(logger.entries.first.level, LogLevel.debug);
    });

    test('success adds entry with success level', () {
      logger.success('Done!');
      expect(logger.entries.first.level, LogLevel.success);
    });

    test('source and tunnelId are stored', () {
      logger.info('msg', source: 'TestService', tunnelId: 't1');
      expect(logger.entries.first.source, 'TestService');
      expect(logger.entries.first.tunnelId, 't1');
    });

    test('clear removes all entries', () {
      logger.info('msg1');
      logger.info('msg2');
      expect(logger.entries.length, 2);
      logger.clear();
      expect(logger.entries.length, 0);
    });

    test('trims to maxLogEntries', () {
      for (var i = 0; i < 600; i++) {
        logger.info('msg $i');
      }
      expect(logger.entries.length, LoggerService.maxLogEntries);
      expect(logger.entries.first.message, contains('100'));
    });

    test('getEntriesByLevel filters correctly', () {
      logger.info('info1');
      logger.error('err1');
      logger.info('info2');
      logger.error('err2');
      final errors = logger.getEntriesByLevel(LogLevel.error);
      expect(errors.length, 2);
      expect(errors.every((e) => e.level == LogLevel.error), isTrue);
    });

    test('getEntriesForTunnel filters by tunnelId', () {
      logger.info('msg1', tunnelId: 't1');
      logger.info('msg2', tunnelId: 't2');
      logger.info('msg3', tunnelId: 't1');
      final t1Logs = logger.getEntriesForTunnel('t1');
      expect(t1Logs.length, 2);
    });

    test('onLog stream emits entries', () async {
      final received = <LogEntry>[];
      final sub = logger.onLog.listen((e) => received.add(e));
      await Future.delayed(Duration.zero); // Let listener register.
      logger.info('stream test');
      await Future.delayed(Duration.zero); // Let stream deliver.
      expect(received.length, 1);
      expect(received.first.message, 'stream test');
      await sub.cancel();
    });

    test('exportAsString returns formatted log', () {
      logger.info('line1');
      logger.error('line2');
      final output = logger.exportAsString();
      expect(output, contains('line1'));
      expect(output, contains('line2'));
      expect(output, contains('\n'));
    });

    test('getEntriesByLevel returns empty for unmatched level', () {
      logger.info('only info');
      expect(logger.getEntriesByLevel(LogLevel.error).length, 0);
    });
  });
}
