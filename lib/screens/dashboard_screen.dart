import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';
import '../widgets/tunnel_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/log_panel.dart';
import '../widgets/create_tunnel_dialog.dart';

/// Main dashboard screen showing tunnels and status.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, state),
              const SizedBox(height: 20),
              _buildNgrokStatus(context, state),
              const SizedBox(height: 20),
              _buildQuickStats(context, state),
              const SizedBox(height: 20),
              _buildTunnelsSection(context, state),
              const SizedBox(height: 20),
              _buildLogSection(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SkyTunnel',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            Text(
              'One-click game server hosting',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white54,
                  ),
            ),
          ],
        ),
        Row(
          children: [
            if (state.activeTunnelCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.successColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${state.activeTunnelCount} Active',
                      style: const TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showCreateTunnelDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Tunnel'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNgrokStatus(BuildContext context, AppState state) {
    final ngrok = state.ngrokStatus;
    final isReady = ngrok.isReady;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isReady
                    ? AppTheme.successColor.withValues(alpha: 0.2)
                    : ngrok.installationStatus ==
                            NgrokInstallationStatus.downloading
                        ? AppTheme.warningColor.withValues(alpha: 0.2)
                        : AppTheme.errorColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isReady
                    ? Icons.check_circle
                    : ngrok.installationStatus ==
                            NgrokInstallationStatus.downloading
                        ? Icons.hourglass_top
                        : Icons.error_outline,
                color: isReady
                    ? AppTheme.successColor
                    : ngrok.installationStatus ==
                            NgrokInstallationStatus.downloading
                        ? AppTheme.warningColor
                        : AppTheme.errorColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ngrok',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ngrok.installationStatus.displayName,
                    style: TextStyle(
                      color: isReady
                          ? AppTheme.successColor
                          : Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (ngrok.ngrokVersion != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ngrok.ngrokVersion!,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            const SizedBox(width: 12),
            if (!state.settings.hasAuthToken)
              TextButton(
                onPressed: () => state.setNavIndex(2),
                child: const Text('Configure'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, AppState state) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Active Tunnels',
            value: '${state.activeTunnelCount}',
            icon: Icons.cable,
            color: AppTheme.accentColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Total Tunnels',
            value: '${state.tunnels.length}',
            icon: Icons.layers,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'ngrok Status',
            value: state.ngrokStatus.isReady ? 'Ready' : 'Not Ready',
            icon: state.ngrokStatus.isReady
                ? Icons.check_circle
                : Icons.warning,
            color: state.ngrokStatus.isReady
                ? AppTheme.successColor
                : AppTheme.warningColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Logs',
            value: '${state.logEntries.length}',
            icon: Icons.article,
            color: AppTheme.infoColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTunnelsSection(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tunnels',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (state.tunnels.isNotEmpty)
              TextButton(
                onPressed: () => _confirmStopAll(context, state),
                child: const Text(
                  'Stop All',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (state.tunnels.isEmpty)
          _buildEmptyState(context)
        else
          ...state.tunnels.map((tunnel) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TunnelCard(tunnel: tunnel),
              )),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.cable,
                size: 48,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12),
              Text(
                'No tunnels running',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create a tunnel to expose your game server',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showCreateTunnelDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Tunnel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogSection(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Logs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            TextButton(
              onPressed: () => state.setNavIndex(3),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const LogPanel(maxEntries: 8),
      ],
    );
  }

  void _showCreateTunnelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const CreateTunnelDialog(),
    );
  }

  void _confirmStopAll(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop All Tunnels'),
        content: const Text('Are you sure you want to stop all active tunnels?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              state.stopAllTunnels();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Stop All'),
          ),
        ],
      ),
    );
  }
}
