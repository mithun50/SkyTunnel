import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'services/services.dart';
import 'screens/screens.dart';
import 'utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SkyTunnelApp());
}

/// Root application widget.
class SkyTunnelApp extends StatefulWidget {
  const SkyTunnelApp({super.key});

  @override
  State<SkyTunnelApp> createState() => _SkyTunnelAppState();
}

class _SkyTunnelAppState extends State<SkyTunnelApp> {
  late AppState _appState;
  bool _isReady = false;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Create services.
    final logger = LoggerService();
    final processManager = ProcessManager();
    final settingsManager = SettingsManager(logger);
    final ngrokService = NgrokService(logger, processManager, settingsManager);
    final gameProfileManager = GameProfileManager(logger, settingsManager);
    final tunnelManager =
        TunnelManager(logger, ngrokService, settingsManager);
    final updateManager = UpdateManager(logger);
    final portDetection = PortDetectionService(logger);
    final windowService = WindowService(logger);

    // Create app state.
    _appState = AppState(
      logger: logger,
      settingsManager: settingsManager,
      ngrokService: ngrokService,
      tunnelManager: tunnelManager,
      gameProfileManager: gameProfileManager,
      processManager: processManager,
      updateManager: updateManager,
      portDetection: portDetection,
      windowService: windowService,
    );

    // Initialize all services.
    await _appState.init();

    // Check if onboarding is needed.
    final needsOnboarding = !_appState.settings.hasCompletedOnboarding;

    // Start background services.
    tunnelManager.startStatsCollection();
    tunnelManager.startHealthMonitoring();

    setState(() {
      _isReady = true;
      _showOnboarding = needsOnboarding;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _LoadingScreen(),
      );
    }

    return ChangeNotifierProvider.value(
      value: _appState,
      child: Consumer<AppState>(
        builder: (context, state, _) {
          return MaterialApp(
            title: 'SkyTunnel',
            debugShowCheckedModeBanner: false,
            theme: state.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: _showOnboarding
                ? OnboardingScreen(
                    onComplete: () {
                      setState(() => _showOnboarding = false);
                      state.completeOnboarding();
                    },
                  )
                : const HomeScreen(),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }
}

/// Loading screen shown during initialization.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.cable,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'SkyTunnel',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'One-click game server hosting',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(),
            ),
            const SizedBox(height: 16),
            Text(
              'Initializing...',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
