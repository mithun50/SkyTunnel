import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';
import '../widgets/shortcuts_wrapper.dart';
import 'dashboard_screen.dart';
import 'profiles_screen.dart';
import 'settings_screen.dart';
import 'logs_screen.dart';

/// Main application shell with responsive navigation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Widget> _screens = const [
    DashboardScreen(),
    ProfilesScreen(),
    SettingsScreen(),
    LogsScreen(),
  ];

  final List<String> _titles = const [
    'Dashboard',
    'Game Profiles',
    'Settings',
    'Logs',
  ];

  final List<IconData> _icons = const [
    Icons.dashboard,
    Icons.sports_esports,
    Icons.settings,
    Icons.article,
  ];

  static const double _sidebarWidth = 220;
  static const double _breakpoint = 800;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return ShortcutsWrapper(
          child: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > _breakpoint;
                return Row(
                  children: [
                    if (isWide) _buildFullSidebar(state),
                    if (!isWide) _buildCompactNav(state),
                    // Main content area.
                    Expanded(
                      child: Column(
                        children: [
                          if (!isWide) _buildTopBar(state),
                          Expanded(
                            child: _screens[state.selectedNavIndex],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Full sidebar for wide screens (>=800px).
  Widget _buildFullSidebar(AppState state) {
    return Container(
      width: _sidebarWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo header.
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.accentColor],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.cable,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'SkyTunnel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Navigation items.
          ...List.generate(_titles.length, (index) {
            return _buildNavItem(state, index, showLabel: true);
          }),
          const Spacer(),
          // Footer status.
          _buildFooterStatus(state),
        ],
      ),
    );
  }

  /// Compact navigation rail for narrow screens (<800px).
  Widget _buildCompactNav(AppState state) {
    return NavigationRail(
      selectedIndex: state.selectedNavIndex,
      onDestinationSelected: (index) => state.setNavIndex(index),
      backgroundColor: Theme.of(context).colorScheme.surface,
      indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.accentColor],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.cable,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
      destinations: List.generate(_titles.length, (index) {
        return NavigationRailDestination(
          icon: Icon(
            _icons[index],
            color: state.selectedNavIndex == index
                ? AppTheme.primaryColor
                : Colors.white54,
          ),
          selectedIcon: Icon(
            _icons[index],
            color: AppTheme.primaryColor,
          ),
          label: Text(
            _titles[index],
            style: const TextStyle(fontSize: 11),
          ),
        );
      }),
    );
  }

  /// Top bar for narrow screens showing current page title.
  Widget _buildTopBar(AppState state) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            _titles[state.selectedNavIndex],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Status indicator.
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: state.ngrokStatus.isReady
                  ? AppTheme.successColor
                  : Colors.white38,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single nav item (used in full sidebar).
  Widget _buildNavItem(AppState state, int index, {bool showLabel = true}) {
    final isSelected = state.selectedNavIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => state.setNavIndex(index),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  _icons[index],
                  size: 20,
                  color: isSelected ? AppTheme.primaryColor : Colors.white54,
                ),
                if (showLabel) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _titles[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color:
                            isSelected ? AppTheme.primaryColor : Colors.white54,
                      ),
                    ),
                  ),
                  if (index == 0 && state.activeTunnelCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${state.activeTunnelCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Footer status widget.
  Widget _buildFooterStatus(AppState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: state.ngrokStatus.isReady
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'ngrok: ${state.ngrokStatus.installationStatus.displayName}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
