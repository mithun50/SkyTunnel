

/// Represents the status of a tunnel.
enum TunnelStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error;

  String get displayName {
    switch (this) {
      case TunnelStatus.disconnected:
        return 'Disconnected';
      case TunnelStatus.connecting:
        return 'Connecting';
      case TunnelStatus.connected:
        return 'Connected';
      case TunnelStatus.reconnecting:
        return 'Reconnecting';
      case TunnelStatus.error:
        return 'Error';
    }
  }

  bool get isActive =>
      this == TunnelStatus.connected || this == TunnelStatus.reconnecting;

  bool get isTransition =>
      this == TunnelStatus.connecting || this == TunnelStatus.reconnecting;
}

/// Represents a TCP tunnel through ngrok.
class Tunnel {
  final String id;
  final String name;
  final int localPort;
  final String? publicAddress;
  final String? publicUrl;
  final TunnelStatus status;
  final DateTime createdAt;
  final DateTime? connectedAt;
  final DateTime? disconnectedAt;
  final String? errorMessage;
  final String gameId;
  final int? remotePort;
  final int bytesIn;
  final int bytesOut;
  final int activeConnections;

  const Tunnel({
    required this.id,
    required this.name,
    required this.localPort,
    this.publicAddress,
    this.publicUrl,
    this.status = TunnelStatus.disconnected,
    required this.createdAt,
    this.connectedAt,
    this.disconnectedAt,
    this.errorMessage,
    required this.gameId,
    this.remotePort,
    this.bytesIn = 0,
    this.bytesOut = 0,
    this.activeConnections = 0,
  });

  /// Returns the formatted public address for display (host:port).
  String get displayAddress {
    if (publicAddress == null) return 'Not connected';
    return publicAddress!;
  }

  /// Returns the formatted public address with protocol prefix.
  String get fullUrl {
    if (publicUrl != null) return publicUrl!;
    if (publicAddress != null) return 'tcp://$publicAddress';
    return '';
  }

  /// Calculates uptime from connectedAt to now.
  Duration get uptime {
    if (connectedAt == null) return Duration.zero;
    return DateTime.now().difference(connectedAt!);
  }

  /// Formats bytes transferred as human-readable string.
  String get formattedBytesIn => _formatBytes(bytesIn);
  String get formattedBytesOut => _formatBytes(bytesOut);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Tunnel copyWith({
    String? id,
    String? name,
    int? localPort,
    String? publicAddress,
    String? publicUrl,
    TunnelStatus? status,
    DateTime? createdAt,
    DateTime? connectedAt,
    DateTime? disconnectedAt,
    String? errorMessage,
    String? gameId,
    int? remotePort,
    int? bytesIn,
    int? bytesOut,
    int? activeConnections,
    bool clearPublicAddress = false,
    bool clearErrorMessage = false,
    bool clearConnectedAt = false,
    bool clearDisconnectedAt = false,
  }) {
    return Tunnel(
      id: id ?? this.id,
      name: name ?? this.name,
      localPort: localPort ?? this.localPort,
      publicAddress:
          clearPublicAddress ? null : (publicAddress ?? this.publicAddress),
      publicUrl: clearPublicAddress ? null : (publicUrl ?? this.publicUrl),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      connectedAt:
          clearConnectedAt ? null : (connectedAt ?? this.connectedAt),
      disconnectedAt:
          clearDisconnectedAt ? null : (disconnectedAt ?? this.disconnectedAt),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      gameId: gameId ?? this.gameId,
      remotePort: remotePort ?? this.remotePort,
      bytesIn: bytesIn ?? this.bytesIn,
      bytesOut: bytesOut ?? this.bytesOut,
      activeConnections: activeConnections ?? this.activeConnections,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'localPort': localPort,
        'publicAddress': publicAddress,
        'publicUrl': publicUrl,
        'status': status.index,
        'createdAt': createdAt.toIso8601String(),
        'connectedAt': connectedAt?.toIso8601String(),
        'disconnectedAt': disconnectedAt?.toIso8601String(),
        'errorMessage': errorMessage,
        'gameId': gameId,
        'remotePort': remotePort,
        'bytesIn': bytesIn,
        'bytesOut': bytesOut,
        'activeConnections': activeConnections,
      };

  factory Tunnel.fromJson(Map<String, dynamic> json) {
    return Tunnel(
      id: json['id'] as String,
      name: json['name'] as String,
      localPort: json['localPort'] as int,
      publicAddress: json['publicAddress'] as String?,
      publicUrl: json['publicUrl'] as String?,
      status: TunnelStatus.values[json['status'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
      connectedAt: json['connectedAt'] != null
          ? DateTime.parse(json['connectedAt'] as String)
          : null,
      disconnectedAt: json['disconnectedAt'] != null
          ? DateTime.parse(json['disconnectedAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
      gameId: json['gameId'] as String,
      remotePort: json['remotePort'] as int?,
      bytesIn: json['bytesIn'] as int? ?? 0,
      bytesOut: json['bytesOut'] as int? ?? 0,
      activeConnections: json['activeConnections'] as int? ?? 0,
    );
  }
}
