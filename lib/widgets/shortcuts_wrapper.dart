import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'create_tunnel_dialog.dart';

/// Wraps child with keyboard shortcuts for common actions.
class ShortcutsWrapper extends StatelessWidget {
  final Widget child;

  const ShortcutsWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        // Ctrl+N: New tunnel.
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          _createTunnel(context);
        },
        // Ctrl+1-4: Navigate tabs.
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () {
          context.read<AppState>().setNavIndex(0);
        },
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () {
          context.read<AppState>().setNavIndex(1);
        },
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () {
          context.read<AppState>().setNavIndex(2);
        },
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () {
          context.read<AppState>().setNavIndex(3);
        },
        // Ctrl+L: Clear logs.
        const SingleActivator(LogicalKeyboardKey.keyL, control: true): () {
          context.read<AppState>().logger.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logs cleared'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        // Ctrl+Shift+C: Copy first active tunnel address.
        const SingleActivator(LogicalKeyboardKey.keyC,
            control: true, shift: true): () {
          _copyFirstTunnelAddress(context);
        },
        // Escape: Close any open dialog.
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      },
      child: child,
    );
  }

  void _createTunnel(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const CreateTunnelDialog(),
    );
  }

  void _copyFirstTunnelAddress(BuildContext context) {
    final state = context.read<AppState>();
    final activeTunnel = state.tunnels
        .where((t) => t.publicAddress != null)
        .firstOrNull;
    if (activeTunnel != null) {
      Clipboard.setData(ClipboardData(text: activeTunnel.publicAddress!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: ${activeTunnel.publicAddress}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
