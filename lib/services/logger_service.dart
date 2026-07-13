import 'dart:async';
import 'dart:collection';
import '../models/log_entry.dart';

/// Centralized logging service with stream-based log distribution.
class LoggerService {
  static const int maxLogEntries = 500;

  final List<LogEntry> _entries = [];
  final StreamController<LogEntry> _logController =
      StreamController<LogEntry>.broadcast();
  final StreamController<List<LogEntry>> _entriesController =
      StreamController<List<LogEntry>>.broadcast();

  /// Stream of individual log entries as they arrive.
  Stream<LogEntry> get onLog => _logController.stream;

  /// Stream of the full log list (emitted on each new entry).
  Stream<List<LogEntry>> get onEntriesChanged => _entriesController.stream;

  /// Unmodifiable view of all current log entries.
  UnmodifiableListView<LogEntry> get entries =>
      UnmodifiableListView(_entries);

  /// Logs a debug message.
  void debug(String message, {String? source, String? tunnelId}) {
    _addEntry(LogLevel.debug, message, source: source, tunnelId: tunnelId);
  }

  /// Logs an informational message.
  void info(String message, {String? source, String? tunnelId}) {
    _addEntry(LogLevel.info, message, source: source, tunnelId: tunnelId);
  }

  /// Logs a warning message.
  void warning(String message, {String? source, String? tunnelId}) {
    _addEntry(LogLevel.warning, message, source: source, tunnelId: tunnelId);
  }

  /// Logs an error message.
  void error(String message, {String? source, String? tunnelId}) {
    _addEntry(LogLevel.error, message, source: source, tunnelId: tunnelId);
  }

  /// Logs a success message.
  void success(String message, {String? source, String? tunnelId}) {
    _addEntry(LogLevel.success, message, source: source, tunnelId: tunnelId);
  }

  void _addEntry(
    LogLevel level,
    String message, {
    String? source,
    String? tunnelId,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      source: source,
      tunnelId: tunnelId,
    );

    _entries.add(entry);

    // Trim to max size (remove oldest entries).
    if (_entries.length > maxLogEntries) {
      _entries.removeRange(0, _entries.length - maxLogEntries);
    }

    _logController.add(entry);
    _entriesController.add(UnmodifiableListView(_entries));
  }

  /// Clears all log entries.
  void clear() {
    _entries.clear();
    _entriesController.add(UnmodifiableListView(_entries));
  }

  /// Returns entries filtered by level.
  List<LogEntry> getEntriesByLevel(LogLevel level) {
    return _entries.where((e) => e.level == level).toList();
  }

  /// Returns entries filtered by tunnel ID.
  List<LogEntry> getEntriesForTunnel(String tunnelId) {
    return _entries.where((e) => e.tunnelId == tunnelId).toList();
  }

  /// Returns all entries as a single formatted string.
  String exportAsString() {
    return _entries.map((e) => e.formattedMessage).join('\n');
  }

  void dispose() {
    _logController.close();
    _entriesController.close();
  }
}
