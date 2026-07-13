import 'package:intl/intl.dart';

/// Severity level for log entries.
enum LogLevel {
  debug,
  info,
  warning,
  error,
  success;

  String get displayName {
    switch (this) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.success:
        return 'SUCCESS';
    }
  }
}

/// A single log entry with timestamp, level, and message.
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? source;
  final String? tunnelId;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.source,
    this.tunnelId,
  });

  /// Formatted timestamp for display.
  String get formattedTime =>
      DateFormat('HH:mm:ss.SSS').format(timestamp);

  /// Full formatted line.
  String get formattedMessage => '[$formattedTime] [${level.displayName}] $message';

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.index,
        'message': message,
        'source': source,
        'tunnelId': tunnelId,
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      level: LogLevel.values[json['level'] as int],
      message: json['message'] as String,
      source: json['source'] as String?,
      tunnelId: json['tunnelId'] as String?,
    );
  }

  @override
  String toString() => formattedMessage;
}
