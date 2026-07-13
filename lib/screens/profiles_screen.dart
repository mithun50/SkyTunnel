import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';

/// Game profiles management screen.
class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Game Profiles',
                    style:
                        Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddProfileDialog(context, state),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Custom'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select a game profile to auto-configure the local port.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Built-in Profiles',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...GameProfile.builtInProfiles.map(
                (profile) => _buildProfileCard(context, state, profile),
              ),
              if (state.gameProfileManager.customProfiles.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Custom Profiles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                ...state.gameProfileManager.customProfiles.map(
                  (profile) => _buildProfileCard(context, state, profile,
                      canDelete: true),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(
      BuildContext context, AppState state, GameProfile profile,
      {bool canDelete = false}) {
    final isSelected = state.settings.defaultGameId == profile.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _useProfile(context, state, profile),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.2)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  profile.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              // Info.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Port.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Port ${profile.defaultPort}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Actions.
              if (isSelected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (canDelete) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppTheme.errorColor,
                  onPressed: () =>
                      _confirmDeleteProfile(context, state, profile),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _useProfile(BuildContext context, AppState state, GameProfile profile) {
    state.updateSettings(
        state.settings.copyWith(defaultGameId: profile.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${profile.name} selected as default'),
        action: SnackBarAction(
          label: 'Create Tunnel',
          onPressed: () {
            // Navigate to create tunnel with this profile.
            showDialog(
              context: context,
              builder: (_) => _QuickTunnelDialog(profile: profile),
            );
          },
        ),
      ),
    );
  }

  void _showAddProfileDialog(BuildContext context, AppState state) {
    final nameController = TextEditingController();
    final portController = TextEditingController(text: '8080');
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Profile Name',
                hintText: 'My Custom Game',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Default Port',
                hintText: '8080',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Description of the game server',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final port = int.tryParse(portController.text.trim()) ?? 8080;
              final desc = descController.text.trim();

              if (name.isNotEmpty) {
                state.gameProfileManager.addCustomProfile(GameProfile(
                  id: '',
                  name: name,
                  description: desc.isNotEmpty ? desc : 'Custom game server',
                  defaultPort: port,
                  icon: '🎮',
                ));
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProfile(
      BuildContext context, AppState state, GameProfile profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text('Delete "${profile.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              state.gameProfileManager.removeCustomProfile(profile.id);
              Navigator.of(ctx).pop();
            },
            style:
                TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Quick tunnel creation dialog from profile selection.
class _QuickTunnelDialog extends StatefulWidget {
  final GameProfile profile;

  const _QuickTunnelDialog({required this.profile});

  @override
  State<_QuickTunnelDialog> createState() => _QuickTunnelDialogState();
}

class _QuickTunnelDialogState extends State<_QuickTunnelDialog> {
  late TextEditingController _portController;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _portController =
        TextEditingController(text: widget.profile.defaultPort.toString());
    _nameController =
        TextEditingController(text: widget.profile.name);
  }

  @override
  void dispose() {
    _portController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create ${widget.profile.name} Tunnel'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Tunnel Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Local Port',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final port = int.tryParse(_portController.text.trim()) ??
                widget.profile.defaultPort;
            final name = _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : widget.profile.name;

            Navigator.of(context).pop();

            final state = context.read<AppState>();
            await state.createTunnel(
              gameId: widget.profile.id,
              localPort: port,
              customName: name,
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
