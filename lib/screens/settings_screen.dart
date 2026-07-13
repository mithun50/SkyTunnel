import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';

/// Settings screen for application configuration.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _authTokenController;
  late TextEditingController _ngrokPathController;
  late TextEditingController _portController;
  String _selectedGameId = 'minecraft_java';
  bool _autoReconnect = true;
  bool _darkMode = true;
  bool _checkForUpdates = true;
  bool _launchOnStartup = false;
  bool _showAuthToken = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _authTokenController =
        TextEditingController(text: state.settings.ngrokAuthToken);
    _ngrokPathController =
        TextEditingController(text: state.settings.ngrokPath);
    _portController =
        TextEditingController(text: state.settings.defaultPort.toString());
    _selectedGameId = state.settings.defaultGameId;
    _autoReconnect = state.settings.autoReconnect;
    _darkMode = state.settings.darkMode;
    _checkForUpdates = state.settings.checkForUpdates;
    _launchOnStartup = state.settings.launchOnStartup;
  }

  @override
  void dispose() {
    _authTokenController.dispose();
    _ngrokPathController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildNgrokSection(context, state),
              const SizedBox(height: 20),
              _buildDefaultsSection(context, state),
              const SizedBox(height: 20),
              _buildBehaviorSection(context, state),
              const SizedBox(height: 20),
              _buildDiagnosticsSection(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      'Settings',
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildNgrokSection(BuildContext context, AppState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.vpn_key, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'ngrok Configuration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Auth Token.
            TextField(
              controller: _authTokenController,
              obscureText: !_showAuthToken,
              decoration: InputDecoration(
                labelText: 'Auth Token',
                hintText: 'Enter your ngrok auth token',
                prefixIcon: const Icon(Icons.key, size: 20),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _showAuthToken
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _showAuthToken = !_showAuthToken;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get your token at https://dashboard.ngrok.com/get-started/your-authtoken',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 12),
            // ngrok path.
            TextField(
              controller: _ngrokPathController,
              decoration: const InputDecoration(
                labelText: 'ngrok Path (optional)',
                hintText: 'Leave empty for auto-detect',
                prefixIcon: Icon(Icons.folder, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            // Status indicator.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: state.ngrokStatus.isReady
                    ? AppTheme.successColor.withValues(alpha: 0.1)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: state.ngrokStatus.isReady
                      ? AppTheme.successColor.withValues(alpha: 0.3)
                      : Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    state.ngrokStatus.isReady
                        ? Icons.check_circle
                        : Icons.info_outline,
                    color: state.ngrokStatus.isReady
                        ? AppTheme.successColor
                        : Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Status: ${state.ngrokStatus.installationStatus.displayName} | Auth: ${state.ngrokStatus.authStatus.displayName}',
                      style: TextStyle(
                        color: state.ngrokStatus.isReady
                            ? AppTheme.successColor
                            : Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _saveNgrokSettings(state),
                  child: const Text('Save & Verify'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _detectNgrok(state),
                  child: const Text('Detect ngrok'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultsSection(BuildContext context, AppState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gamepad, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Text(
                  'Defaults',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Default game.
            DropdownButtonFormField<String>(
              value: _selectedGameId,
              decoration: const InputDecoration(
                labelText: 'Default Game',
                prefixIcon: Icon(Icons.sports_esports, size: 20),
              ),
              items: state.gameProfiles.map((profile) {
                return DropdownMenuItem(
                  value: profile.id,
                  child: Text('${profile.icon} ${profile.name}'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedGameId = value);
                }
              },
            ),
            const SizedBox(height: 12),
            // Default port.
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Default Port',
                prefixIcon: Icon(Icons.numbers, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _saveDefaults(state),
              child: const Text('Save Defaults'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBehaviorSection(BuildContext context, AppState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                Text(
                  'Behavior',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Auto Reconnect'),
              subtitle: const Text('Automatically reconnect disconnected tunnels'),
              value: _autoReconnect,
              onChanged: (v) => setState(() => _autoReconnect = v),
              activeColor: AppTheme.primaryColor,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark theme'),
              value: _darkMode,
              onChanged: (v) => setState(() => _darkMode = v),
              activeColor: AppTheme.primaryColor,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Check for Updates'),
              subtitle: const Text('Automatically check for app updates'),
              value: _checkForUpdates,
              onChanged: (v) => setState(() => _checkForUpdates = v),
              activeColor: AppTheme.primaryColor,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Launch on Startup'),
              subtitle: const Text('Start SkyTunnel when system boots'),
              value: _launchOnStartup,
              onChanged: (v) => setState(() => _launchOnStartup = v),
              activeColor: AppTheme.primaryColor,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _saveBehavior(state),
              child: const Text('Save Behavior'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsSection(BuildContext context, AppState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: AppTheme.infoColor),
                const SizedBox(width: 8),
                Text(
                  'Diagnostics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _diagRow('ngrok Path',
                state.ngrokStatus.ngrokPath ?? 'Not found'),
            _diagRow('ngrok Version',
                state.ngrokStatus.ngrokVersion ?? 'Unknown'),
            _diagRow('Auth Token',
                state.settings.hasAuthToken ? 'Configured' : 'Not set'),
            _diagRow('Active Tunnels', '${state.activeTunnelCount}'),
            _diagRow('Total Logs', '${state.logEntries.length}'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _showExportDialog(context, state),
              child: const Text('Export Logs'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _diagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _saveNgrokSettings(AppState state) {
    final token = _authTokenController.text.trim();
    final path = _ngrokPathController.text.trim();

    state.updateSettings(state.settings.copyWith(
      ngrokAuthToken: token,
      ngrokPath: path,
    ));

    if (token.isNotEmpty) {
      state.authenticateNgrok(token);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ngrok settings saved')),
    );
  }

  void _detectNgrok(AppState state) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Detecting ngrok...')),
    );
    await state.ngrokService.detectNgrok();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ngrok: ${state.ngrokStatus.installationStatus.displayName}',
          ),
        ),
      );
    }
  }

  void _saveDefaults(AppState state) {
    final port = int.tryParse(_portController.text) ?? 25565;
    state.updateSettings(state.settings.copyWith(
      defaultGameId: _selectedGameId,
      defaultPort: port,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default settings saved')),
    );
  }

  void _saveBehavior(AppState state) {
    state.updateSettings(state.settings.copyWith(
      autoReconnect: _autoReconnect,
      darkMode: _darkMode,
      checkForUpdates: _checkForUpdates,
      launchOnStartup: _launchOnStartup,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Behavior settings saved')),
    );
  }

  void _showExportDialog(BuildContext context, AppState state) {
    final logs = state.logger.exportAsString();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Logs'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: SelectableText(
            logs.isEmpty ? 'No logs available' : logs,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
