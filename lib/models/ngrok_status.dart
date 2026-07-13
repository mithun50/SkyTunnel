/// The installation/running status of ngrok.
enum NgrokInstallationStatus {
  unknown,
  notInstalled,
  installed,
  downloading,
  error;

  String get displayName {
    switch (this) {
      case NgrokInstallationStatus.unknown:
        return 'Unknown';
      case NgrokInstallationStatus.notInstalled:
        return 'Not Installed';
      case NgrokInstallationStatus.installed:
        return 'Installed';
      case NgrokInstallationStatus.downloading:
        return 'Downloading';
      case NgrokInstallationStatus.error:
        return 'Error';
    }
  }
}

/// The authentication status of ngrok.
enum NgrokAuthStatus {
  unknown,
  notAuthenticated,
  authenticated,
  checking;

  String get displayName {
    switch (this) {
      case NgrokAuthStatus.unknown:
        return 'Unknown';
      case NgrokAuthStatus.notAuthenticated:
        return 'Not Authenticated';
      case NgrokAuthStatus.authenticated:
        return 'Authenticated';
      case NgrokAuthStatus.checking:
        return 'Checking...';
    }
  }
}

/// Combined ngrok status information.
class NgrokStatus {
  final NgrokInstallationStatus installationStatus;
  final NgrokAuthStatus authStatus;
  final String? ngrokVersion;
  final String? ngrokPath;
  final String? errorMessage;

  const NgrokStatus({
    this.installationStatus = NgrokInstallationStatus.unknown,
    this.authStatus = NgrokAuthStatus.unknown,
    this.ngrokVersion,
    this.ngrokPath,
    this.errorMessage,
  });

  /// Whether ngrok is ready to create tunnels.
  bool get isReady =>
      installationStatus == NgrokInstallationStatus.installed &&
      authStatus == NgrokAuthStatus.authenticated;

  NgrokStatus copyWith({
    NgrokInstallationStatus? installationStatus,
    NgrokAuthStatus? authStatus,
    String? ngrokVersion,
    String? ngrokPath,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return NgrokStatus(
      installationStatus: installationStatus ?? this.installationStatus,
      authStatus: authStatus ?? this.authStatus,
      ngrokVersion: ngrokVersion ?? this.ngrokVersion,
      ngrokPath: ngrokPath ?? this.ngrokPath,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
