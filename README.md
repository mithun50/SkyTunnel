# SkyTunnel

**One-click game server hosting via ngrok**

SkyTunnel is a cross-platform desktop application built with Flutter that allows users to expose local game servers to the internet using ngrok with a single click.

## Features

### Core
- **Auto-detect ngrok** - Automatically finds ngrok on your system
- **One-click authentication** - Set your ngrok auth token once
- **TCP Tunnel creation** - Create tunnels with a single click
- **Auto-reconnect** - Automatically reconnects if a tunnel drops
- **Multiple tunnels** - Run multiple game server tunnels simultaneously
- **Real-time monitoring** - Live tunnel status, uptime, and data transfer stats

### Game Profiles
Built-in presets with correct default ports:
- Minecraft Java (25565)
- Minecraft Bedrock (19132)
- Terraria (7777)
- Valheim (2456)
- Factorio (34197)
- Palworld (8211)
- Generic TCP (custom port)

### Dashboard
- Tunnel status indicators
- Public address display with copy button
- Uptime tracking, data transfer, active connections
- Start/Stop/Restart controls
- Event log with filtering

### Settings
- ngrok auth token configuration
- Default game and port
- Auto-reconnect, dark mode, update preferences
- Diagnostics panel and log export

### UX
- **Onboarding wizard** - First-run setup guide
- **Keyboard shortcuts** - Ctrl+N (new tunnel), Ctrl+1-4 (navigate), Ctrl+L (clear logs)
- **Responsive layout** - Adapts to different window sizes
- **Port detection** - Check if a port is available before creating a tunnel
- **Window management** - Proper desktop window with minimum size

## Getting Started

### Prerequisites
- Flutter SDK 3.x
- ngrok (auto-detected or downloadable from ngrok.com)

### Development
```bash
flutter pub get
flutter run -d windows  # or macos / linux
```

### Build
```bash
flutter build windows   # Windows .exe
flutter build macos     # macOS .app
flutter build linux     # Linux binary
```

### Tests
```bash
flutter test
```

## Architecture

```
lib/
  main.dart              # App entry point
  models/                # Data models (Tunnel, GameProfile, AppSettings, etc.)
  services/              # Business logic (NgrokService, TunnelManager, etc.)
  providers/             # State management (ChangeNotifier)
  screens/               # UI screens (Dashboard, Settings, Profiles, Logs, Onboarding)
  widgets/               # Reusable widgets (TunnelCard, CreateTunnelDialog, etc.)
  utils/                 # Theme configuration
test/
  unit/                  # Unit tests for services
  widget_test.dart       # Model tests
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+N | Create new tunnel |
| Ctrl+1-4 | Navigate to tab |
| Ctrl+L | Clear logs |
| Ctrl+Shift+C | Copy first active tunnel address |
| Escape | Close dialog |
