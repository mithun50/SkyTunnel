/// Application settings model.
class AppSettings {
  final String ngrokAuthToken;
  final String defaultGameId;
  final int defaultPort;
  final bool launchOnStartup;
  final bool autoReconnect;
  final bool darkMode;
  final bool checkForUpdates;
  final String ngrokPath;
  final int reconnectDelaySeconds;
  final int maxReconnectAttempts;
  final int healthCheckIntervalSeconds;
  final bool hasCompletedOnboarding;

  const AppSettings({
    this.ngrokAuthToken = '',
    this.defaultGameId = 'minecraft_java',
    this.defaultPort = 25565,
    this.launchOnStartup = false,
    this.autoReconnect = true,
    this.darkMode = true,
    this.checkForUpdates = true,
    this.ngrokPath = '',
    this.reconnectDelaySeconds = 5,
    this.maxReconnectAttempts = 10,
    this.healthCheckIntervalSeconds = 30,
    this.hasCompletedOnboarding = false,
  });

  /// Whether the user has configured an auth token.
  bool get hasAuthToken => ngrokAuthToken.isNotEmpty;

  /// Whether a custom ngrok path has been set.
  bool get hasCustomNgrokPath => ngrokPath.isNotEmpty;

  AppSettings copyWith({
    String? ngrokAuthToken,
    String? defaultGameId,
    int? defaultPort,
    bool? launchOnStartup,
    bool? autoReconnect,
    bool? darkMode,
    bool? checkForUpdates,
    String? ngrokPath,
    int? reconnectDelaySeconds,
    int? maxReconnectAttempts,
    int? healthCheckIntervalSeconds,
    bool? hasCompletedOnboarding,
  }) {
    return AppSettings(
      ngrokAuthToken: ngrokAuthToken ?? this.ngrokAuthToken,
      defaultGameId: defaultGameId ?? this.defaultGameId,
      defaultPort: defaultPort ?? this.defaultPort,
      launchOnStartup: launchOnStartup ?? this.launchOnStartup,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      darkMode: darkMode ?? this.darkMode,
      checkForUpdates: checkForUpdates ?? this.checkForUpdates,
      ngrokPath: ngrokPath ?? this.ngrokPath,
      reconnectDelaySeconds:
          reconnectDelaySeconds ?? this.reconnectDelaySeconds,
      maxReconnectAttempts:
          maxReconnectAttempts ?? this.maxReconnectAttempts,
      healthCheckIntervalSeconds:
          healthCheckIntervalSeconds ?? this.healthCheckIntervalSeconds,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  Map<String, dynamic> toJson() => {
        'ngrokAuthToken': ngrokAuthToken,
        'defaultGameId': defaultGameId,
        'defaultPort': defaultPort,
        'launchOnStartup': launchOnStartup,
        'autoReconnect': autoReconnect,
        'darkMode': darkMode,
        'checkForUpdates': checkForUpdates,
        'ngrokPath': ngrokPath,
        'reconnectDelaySeconds': reconnectDelaySeconds,
        'maxReconnectAttempts': maxReconnectAttempts,
        'healthCheckIntervalSeconds': healthCheckIntervalSeconds,
        'hasCompletedOnboarding': hasCompletedOnboarding,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      ngrokAuthToken: json['ngrokAuthToken'] as String? ?? '',
      defaultGameId: json['defaultGameId'] as String? ?? 'minecraft_java',
      defaultPort: json['defaultPort'] as int? ?? 25565,
      launchOnStartup: json['launchOnStartup'] as bool? ?? false,
      autoReconnect: json['autoReconnect'] as bool? ?? true,
      darkMode: json['darkMode'] as bool? ?? true,
      checkForUpdates: json['checkForUpdates'] as bool? ?? true,
      ngrokPath: json['ngrokPath'] as String? ?? '',
      reconnectDelaySeconds: json['reconnectDelaySeconds'] as int? ?? 5,
      maxReconnectAttempts: json['maxReconnectAttempts'] as int? ?? 10,
      healthCheckIntervalSeconds:
          json['healthCheckIntervalSeconds'] as int? ?? 30,
      hasCompletedOnboarding:
          json['hasCompletedOnboarding'] as bool? ?? false,
    );
  }
}
