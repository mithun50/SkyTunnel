import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/tunnel.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';

/// Card widget displaying tunnel information and controls.
class TunnelCard extends StatefulWidget {
  final Tunnel tunnel;

  const TunnelCard({super.key, required this.tunnel});

  @override
  State<TunnelCard> createState() => _TunnelCardState();
}

class _TunnelCardState extends State<TunnelCard> {
  Timer? _uptimeTimer;

  @override
  void initState() {
    super.initState();
    // Update uptime display every second.
    _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uptimeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tunnel = widget.tunnel;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, tunnel),
            const SizedBox(height: 12),
            _buildAddressRow(context, tunnel),
            const SizedBox(height: 12),
            _buildStatsRow(tunnel),
            const SizedBox(height: 12),
            _buildActionButtons(context, tunnel),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Tunnel tunnel) {
    return Row(
      children: [
        // Status indicator.
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _getStatusColor(tunnel.status),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        // Name and status.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tunnel.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tunnel.status.displayName,
                style: TextStyle(
                  color: _getStatusColor(tunnel.status),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        // Port info.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            ':${tunnel.localPort}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressRow(BuildContext context, Tunnel tunnel) {
    final hasAddress = tunnel.publicAddress != null;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: hasAddress
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasAddress
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.language,
            size: 18,
            color: hasAddress
                ? AppTheme.primaryColor
                : Colors.white38,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tunnel.displayAddress,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: hasAddress ? Colors.white : Colors.white38,
              ),
            ),
          ),
          if (hasAddress)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Copy address',
              onPressed: () => _copyAddress(context, tunnel),
            ),
          if (hasAddress)
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              tooltip: 'Open in browser',
              onPressed: () {
                // Copy to clipboard (TCP addresses can't be opened in browser).
                _copyAddress(context, tunnel);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Tunnel tunnel) {
    return Row(
      children: [
        _statChip(Icons.upload, '↑ ${tunnel.formattedBytesOut}'),
        const SizedBox(width: 8),
        _statChip(Icons.download, '↓ ${tunnel.formattedBytesIn}'),
        const SizedBox(width: 8),
        _statChip(Icons.people, '${tunnel.activeConnections}'),
        const SizedBox(width: 8),
        if (tunnel.status.isActive)
          _statChip(Icons.timer, _formatDuration(tunnel.uptime)),
      ],
    );
  }

  Widget _statChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white54),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Tunnel tunnel) {
    final state = context.read<AppState>();

    return Row(
      children: [
        if (tunnel.status.isActive) ...[
          ElevatedButton.icon(
            onPressed: () => state.stopTunnel(tunnel.id),
            icon: const Icon(Icons.stop, size: 16),
            label: const Text('Stop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => state.restartTunnel(tunnel.id),
            icon: const Icon(Icons.restart_alt, size: 16),
            label: const Text('Restart'),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ] else if (tunnel.status == TunnelStatus.disconnected ||
            tunnel.status == TunnelStatus.error) ...[
          ElevatedButton.icon(
            onPressed: () => state.restartTunnel(tunnel.id),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ] else if (tunnel.status.isTransition) ...[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(tunnel.status.displayName),
        ],
        const Spacer(),
        if (tunnel.publicAddress != null)
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copy address',
            onPressed: () => _copyAddress(context, tunnel),
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          tooltip: 'Remove tunnel',
          color: AppTheme.errorColor,
          onPressed: () => _confirmRemove(context, state),
        ),
      ],
    );
  }

  void _copyAddress(BuildContext context, Tunnel tunnel) {
    final address = tunnel.publicAddress ?? '';
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Address copied: $address'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmRemove(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Tunnel'),
        content: Text('Remove "${widget.tunnel.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              state.removeTunnel(widget.tunnel.id);
            },
            style:
                TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TunnelStatus status) {
    switch (status) {
      case TunnelStatus.connected:
        return AppTheme.successColor;
      case TunnelStatus.connecting:
      case TunnelStatus.reconnecting:
        return AppTheme.warningColor;
      case TunnelStatus.disconnected:
        return Colors.white38;
      case TunnelStatus.error:
        return AppTheme.errorColor;
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }
}
