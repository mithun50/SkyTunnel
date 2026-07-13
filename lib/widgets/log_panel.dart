import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/log_entry.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';

/// Compact log panel widget for displaying recent log entries.
class LogPanel extends StatelessWidget {
  final int maxEntries;

  const LogPanel({super.key, this.maxEntries = 10});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final entries = state.logEntries;
        final displayEntries =
            entries.length > maxEntries ? entries.sublist(entries.length - maxEntries) : entries;

        if (displayEntries.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No log entries yet',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: displayEntries.reversed.map((entry) {
                return _LogLine(entry: entry);
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _LogLine extends StatelessWidget {
  final LogEntry entry;

  const _LogLine({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      decoration: BoxDecoration(
        color: entry.level == LogLevel.error
            ? AppTheme.errorColor.withValues(alpha: 0.05)
            : null,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          // Level indicator.
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: _getLevelColor(),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          // Time.
          Text(
            entry.formattedTime,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 6),
          // Level.
          SizedBox(
            width: 52,
            child: Text(
              entry.level.displayName,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _getLevelColor(),
              ),
            ),
          ),
          // Message.
          Expanded(
            child: Text(
              entry.message,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor() {
    switch (entry.level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return AppTheme.infoColor;
      case LogLevel.warning:
        return AppTheme.warningColor;
      case LogLevel.error:
        return AppTheme.errorColor;
      case LogLevel.success:
        return AppTheme.successColor;
    }
  }
}
