import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';

/// Dialog for creating a new tunnel with game profile selection.
class CreateTunnelDialog extends StatefulWidget {
  const CreateTunnelDialog({super.key});

  @override
  State<CreateTunnelDialog> createState() => _CreateTunnelDialogState();
}

class _CreateTunnelDialogState extends State<CreateTunnelDialog> {
  String _selectedGameId = 'minecraft_java';
  late TextEditingController _portController;
  late TextEditingController _nameController;
  bool _isCreating = false;
  String? _error;
  bool _isScanning = false;
  bool? _portAvailable;
  String? _portProcessInfo;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _selectedGameId = state.settings.defaultGameId;
    final profile = state.gameProfileManager.findById(_selectedGameId);
    _portController =
        TextEditingController(text: (profile?.defaultPort ?? 25565).toString());
    _nameController =
        TextEditingController(text: profile?.name ?? 'Minecraft Java');
  }

  @override
  void dispose() {
    _portController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return AlertDialog(
          title: const Text('Create Tunnel'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Game profile selector.
                Text(
                  'Game Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: state.gameProfiles.map((profile) {
                      return RadioListTile<String>(
                        value: profile.id,
                        groupValue: _selectedGameId,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedGameId = value;
                              final p = state.gameProfileManager
                                  .findById(value);
                              if (p != null) {
                                _portController.text =
                                    p.defaultPort.toString();
                                _nameController.text = p.name;
                              }
                            });
                          }
                        },
                        title: Row(
                          children: [
                            Text(profile.icon),
                            const SizedBox(width: 8),
                            Text(profile.name),
                            const Spacer(),
                            Text(
                              ':${profile.defaultPort}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          profile.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        activeColor: AppTheme.primaryColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // Tunnel name.
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tunnel Name',
                    prefixIcon: Icon(Icons.label, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                // Local port.
                TextField(
                  controller: _portController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Local Port',
                    prefixIcon: const Icon(Icons.numbers, size: 20),
                    suffixIcon: _isScanning
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.search, size: 18),
                            tooltip: 'Check if port is available',
                            onPressed: () => _scanPort(),
                          ),
                  ),
                ),
                // Port status indicator.
                if (_portAvailable != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _portAvailable!
                          ? AppTheme.successColor.withValues(alpha: 0.1)
                          : AppTheme.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _portAvailable!
                              ? Icons.check_circle
                              : Icons.warning,
                          size: 14,
                          color: _portAvailable!
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _portAvailable!
                              ? 'Port is available'
                              : 'Port is in use${_portProcessInfo != null ? ' ($_portProcessInfo)' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _portAvailable!
                                ? AppTheme.successColor
                                : AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.errorColor, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // ngrok auth warning.
                if (!state.settings.hasAuthToken) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.warningColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            color: AppTheme.warningColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ngrok auth token not configured. Go to Settings to set it up.',
                            style: TextStyle(
                              color: AppTheme.warningColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isCreating
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isCreating ? null : () => _createTunnel(state),
              child: _isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _scanPort() async {
    final port = int.tryParse(_portController.text.trim());
    if (port == null || port < 1 || port > 65535) return;

    setState(() {
      _isScanning = true;
      _portAvailable = null;
      _portProcessInfo = null;
    });

    final state = context.read<AppState>();
    final result = await state.portDetection.checkPort(port);

    if (mounted) {
      setState(() {
        _isScanning = false;
        _portAvailable = !result.isOccupied;
        _portProcessInfo = result.processName;
      });
    }
  }

  Future<void> _createTunnel(AppState state) async {
    final port = int.tryParse(_portController.text.trim());
    if (port == null || port < 1 || port > 65535) {
      setState(() => _error = 'Invalid port number');
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a tunnel name');
      return;
    }

    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final tunnel = await state.createTunnel(
        gameId: _selectedGameId,
        localPort: port,
        customName: name,
      );

      if (mounted) {
        if (tunnel != null) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tunnel created: ${tunnel.publicAddress ?? 'connecting...'}'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          setState(() {
            _isCreating = false;
            _error = 'Failed to create tunnel. Check ngrok status and try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _error = 'Error: $e';
        });
      }
    }
  }
}
