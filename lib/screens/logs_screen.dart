import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';

/// Full-screen log viewer with filtering.
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  LogLevel? _filterLevel;
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final filteredLogs = _filterLogs(state.logEntries);

        return Column(
          children: [
            _buildToolbar(context, state, filteredLogs.length),
            Expanded(
              child: filteredLogs.isEmpty
                  ? _buildEmptyState()
                  : _buildLogList(filteredLogs),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(
      BuildContext context, AppState state, int filteredCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Logs',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 12),
          Text(
            '$filteredCount entries',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const Spacer(),
          // Search field.
          SizedBox(
            width: 200,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          const SizedBox(width: 12),
          // Level filter.
          FilterChip(
            label: const Text('All'),
            selected: _filterLevel == null,
            onSelected: (_) => setState(() => _filterLevel = null),
            selectedColor: AppTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          FilterChip(
            label: const Text('Errors'),
            selected: _filterLevel == LogLevel.error,
            onSelected: (_) => setState(() {
              _filterLevel =
                  _filterLevel == LogLevel.error ? null : LogLevel.error;
            }),
            selectedColor: AppTheme.errorColor,
          ),
          const SizedBox(width: 4),
          FilterChip(
            label: const Text('Warnings'),
            selected: _filterLevel == LogLevel.warning,
            onSelected: (_) => setState(() {
              _filterLevel =
                  _filterLevel == LogLevel.warning ? null : LogLevel.warning;
            }),
            selectedColor: AppTheme.warningColor,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear logs',
            onPressed: () {
              state.logger.clear();
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward),
            tooltip: 'Scroll to bottom',
            onPressed: _scrollToBottom,
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(List<LogEntry> logs) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: logs.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final entry = logs[index];
        return _LogEntryWidget(entry: entry);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.article_outlined,
            size: 48,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'No log entries',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  List<LogEntry> _filterLogs(List<LogEntry> entries) {
    return entries.where((entry) {
      if (_filterLevel != null && entry.level != _filterLevel) return false;
      if (_searchQuery.isNotEmpty &&
          !entry.message.toLowerCase().contains(_searchQuery)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}

class _LogEntryWidget extends StatelessWidget {
  final LogEntry entry;

  const _LogEntryWidget({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp.
          Text(
            entry.formattedTime,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 8),
          // Level badge.
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: _getLevelColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              entry.level.displayName,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _getLevelColor(),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // Source.
          if (entry.source != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                entry.source!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          // Message.
          Expanded(
            child: Text(
              entry.message,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
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

  Color? _getBackgroundColor() {
    if (entry.level == LogLevel.error) {
      return AppTheme.errorColor.withValues(alpha: 0.05);
    }
    if (entry.level == LogLevel.success) {
      return AppTheme.successColor.withValues(alpha: 0.03);
    }
    return null;
  }
}
