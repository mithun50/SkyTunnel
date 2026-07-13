import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Central application state provider using ChangeNotifier.
class AppState extends ChangeNotifier {
  final LoggerService logger;
  final SettingsManager settingsManager;
  final NgrokService ngrokService;
  final TunnelManager tunnelManager;
  final GameProfileManager gameProfileManager;
  final ProcessManager processManager;
  final UpdateManager updateManager;
  final PortDetectionService portDetection;
  final WindowService windowService;

  // Navigation.
  int _selectedNavIndex = 0;
  int get selectedNavIndex => _selectedNavIndex;

  // Subscriptions.
  final List<StreamSubscription> _subscriptions = [];

  // Initialization state.
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;

  String _initStatus = 'Starting...';
  String get initStatus => _initStatus;

  AppState({
    required this.logger,
    required this.settingsManager,
    required this.ngrokService,
    required this.tunnelManager,
    required this.gameProfileManager,
    required this.processManager,
    required this.updateManager,
    required this.portDetection,
    required this.windowService,
  });

  // Convenience accessors.
  AppSettings get settings => settingsManager.settings;
  NgrokStatus get ngrokStatus => ngrokService.status;
  List<Tunnel> get tunnels => tunnelManager.tunnels;
  int get activeTunnelCount => tunnelManager.activeTunnelCount;
  List<GameProfile> get gameProfiles => gameProfileManager.allProfiles;
  List<LogEntry> get logEntries => logger.entries;
  bool get isDarkMode => settings.darkMode;

  /// Initializes all services and starts the application.
  Future<void> init() async {
    _isInitializing = true;
    notifyListeners();

    _setInitStatus('Loading settings...');
    await settingsManager.init();
    _listenToSettings();

    _setInitStatus('Initializing profiles...');
    await gameProfileManager.init();
    _listenToProfiles();

    _setInitStatus('Detecting ngrok...');
    await ngrokService.init();
    _listenToNgrok();

    _setInitStatus('Loading tunnels...');
    await tunnelManager.init();
    _listenToTunnels();

    _setInitStatus('Ready');
    _isInitializing = false;
    _isInitialized = true;
    notifyListeners();

    logger.success('SkyTunnel initialized', source: 'AppState');
  }

  /// Navigates to a tab.
  void setNavIndex(int index) {
    _selectedNavIndex = index;
    notifyListeners();
  }

  /// Creates a new tunnel with the given profile configuration.
  Future<Tunnel?> createTunnel({
    required String gameId,
    required int localPort,
    String? customName,
    int? remotePort,
  }) async {
    final profile = gameProfileManager.findById(gameId);
    final name = customName ?? profile?.name ?? 'Tunnel';

    final tunnel = await tunnelManager.createTunnel(
      name: name,
      gameId: gameId,
      localPort: localPort,
      remotePort: remotePort,
    );

    if (tunnel != null) {
      notifyListeners();
    }

    return tunnel;
  }

  /// Stops a tunnel.
  Future<void> stopTunnel(String tunnelId) async {
    await tunnelManager.stopTunnel(tunnelId);
    notifyListeners();
  }

  /// Restarts a tunnel.
  Future<void> restartTunnel(String tunnelId) async {
    await tunnelManager.restartTunnel(tunnelId);
    notifyListeners();
  }

  /// Removes a tunnel.
  Future<void> removeTunnel(String tunnelId) async {
    await tunnelManager.removeTunnel(tunnelId);
    notifyListeners();
  }

  /// Stops all active tunnels.
  Future<void> stopAllTunnels() async {
    await tunnelManager.stopAllTunnels();
    notifyListeners();
  }

  /// Updates settings.
  Future<void> updateSettings(AppSettings newSettings) async {
    await settingsManager.updateSettings(newSettings);
  }

  /// Authenticates ngrok with a token.
  Future<bool> authenticateNgrok(String token) async {
    final result = await ngrokService.authenticate(token);
    if (result == NgrokAuthStatus.authenticated) {
      await settingsManager.updateField('ngrokAuthToken', token);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Marks onboarding as completed.
  Future<void> completeOnboarding() async {
    await updateSettings(settings.copyWith(hasCompletedOnboarding: true));
  }

  /// Sets initial status message.
  void _setInitStatus(String status) {
    _initStatus = status;
    notifyListeners();
  }

  // Stream listeners.

  void _listenToSettings() {
    _subscriptions.add(
      settingsManager.onSettingsChanged.listen((_) {
        notifyListeners();
      }),
    );
  }

  void _listenToProfiles() {
    _subscriptions.add(
      gameProfileManager.onProfilesChanged.listen((_) {
        notifyListeners();
      }),
    );
  }

  void _listenToNgrok() {
    _subscriptions.add(
      ngrokService.onStatusChanged.listen((_) {
        notifyListeners();
      }),
    );
  }

  void _listenToTunnels() {
    _subscriptions.add(
      tunnelManager.onTunnelsChanged.listen((_) {
        notifyListeners();
      }),
    );
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    logger.dispose();
    settingsManager.dispose();
    ngrokService.dispose();
    tunnelManager.dispose();
    gameProfileManager.dispose();
    processManager.dispose();
    updateManager.dispose();
    windowService.dispose();
    super.dispose();
  }
}
