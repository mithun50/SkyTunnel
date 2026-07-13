/// Represents a game server profile with predefined port and metadata.
class GameProfile {
  final String id;
  final String name;
  final String description;
  final int defaultPort;
  final String icon;
  final bool isCustom;

  const GameProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultPort,
    required this.icon,
    this.isCustom = false,
  });

  /// Built-in game profiles with their default ports.
  static const List<GameProfile> builtInProfiles = [
    GameProfile(
      id: 'minecraft_java',
      name: 'Minecraft Java',
      description: 'Minecraft Java Edition server',
      defaultPort: 25565,
      icon: '⛏️',
    ),
    GameProfile(
      id: 'minecraft_bedrock',
      name: 'Minecraft Bedrock',
      description: 'Minecraft Bedrock Edition server',
      defaultPort: 19132,
      icon: '🟫',
    ),
    GameProfile(
      id: 'terraria',
      name: 'Terraria',
      description: 'Terraria dedicated server',
      defaultPort: 7777,
      icon: '🏗️',
    ),
    GameProfile(
      id: 'valheim',
      name: 'Valheim',
      description: 'Valheim dedicated server',
      defaultPort: 2456,
      icon: '⚔️',
    ),
    GameProfile(
      id: 'factorio',
      name: 'Factorio',
      description: 'Factorio dedicated server',
      defaultPort: 34197,
      icon: '⚙️',
    ),
    GameProfile(
      id: 'palworld',
      name: 'Palworld',
      description: 'Palworld dedicated server',
      defaultPort: 8211,
      icon: '🐾',
    ),
    GameProfile(
      id: 'generic',
      name: 'Generic TCP',
      description: 'Custom TCP application',
      defaultPort: 8080,
      icon: '🌐',
    ),
  ];

  /// Returns all available profiles (built-in + custom).
  static List<GameProfile> allProfiles({List<GameProfile> custom = const []}) {
    return [...builtInProfiles, ...custom];
  }

  /// Finds a profile by ID.
  static GameProfile? findById(String id, {List<GameProfile> custom = const []}) {
    final all = allProfiles(custom: custom);
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  GameProfile copyWith({
    String? id,
    String? name,
    String? description,
    int? defaultPort,
    String? icon,
    bool? isCustom,
  }) {
    return GameProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      defaultPort: defaultPort ?? this.defaultPort,
      icon: icon ?? this.icon,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'defaultPort': defaultPort,
        'icon': icon,
        'isCustom': isCustom,
      };

  factory GameProfile.fromJson(Map<String, dynamic> json) {
    return GameProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      defaultPort: json['defaultPort'] as int,
      icon: json['icon'] as String? ?? '🎮',
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'GameProfile($name, port: $defaultPort)';
}
