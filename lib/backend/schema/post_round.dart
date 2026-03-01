/// Post-round flow data models — plain Dart value objects.
///
/// Used by HostCheckinScreen and PlayerRatingScreen.
library;

// ─────────────────────────────────────────────────────────────────────────────
// Host Check-In Models
// ─────────────────────────────────────────────────────────────────────────────

class HostCheckInPlayer {
  HostCheckInPlayer({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.isAppUser,
    this.attended,
  });

  final String id;
  final String name;
  final String? avatarUrl;

  /// false = guest placeholder (no app account)
  final bool isAppUser;

  /// null = not yet answered
  bool? attended;

  factory HostCheckInPlayer.fromMap(Map<String, dynamic> map) {
    return HostCheckInPlayer(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      isAppUser: map['isAppUser'] as bool? ?? true,
    );
  }
}

class HostCheckIn {
  const HostCheckIn({
    required this.gameId,
    required this.courseName,
    required this.teeTime,
    required this.players,
  });

  final String gameId;
  final String courseName;
  final DateTime teeTime;

  /// All players including guests
  final List<HostCheckInPlayer> players;

  factory HostCheckIn.fromMap(Map<String, dynamic> map) {
    final rawPlayers = (map['players'] as List<dynamic>?) ?? [];
    return HostCheckIn(
      gameId: map['gameId'] as String? ?? '',
      courseName: map['courseName'] as String? ?? '',
      teeTime: map['teeTime'] is DateTime
          ? map['teeTime'] as DateTime
          : DateTime.fromMillisecondsSinceEpoch(
              (map['teeTime'] as num?)?.toInt() ?? 0),
      players: rawPlayers
          .whereType<Map<String, dynamic>>()
          .map(HostCheckInPlayer.fromMap)
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Player Rating Models
// ─────────────────────────────────────────────────────────────────────────────

class RateablePlayer {
  RateablePlayer({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.playAgain,
  });

  final String id;
  final String name;
  final String? avatarUrl;

  /// null = not yet rated, true = would play again, false = would not
  bool? playAgain;

  factory RateablePlayer.fromMap(Map<String, dynamic> map) {
    return RateablePlayer(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
    );
  }
}

class PlayerRating {
  const PlayerRating({
    required this.gameId,
    required this.courseName,
    required this.teeTime,
    required this.coPlayers,
  });

  final String gameId;
  final String courseName;
  final DateTime teeTime;

  /// Only app users — guests are excluded
  final List<RateablePlayer> coPlayers;

  factory PlayerRating.fromMap(Map<String, dynamic> map) {
    final rawPlayers = (map['coPlayers'] as List<dynamic>?) ?? [];
    return PlayerRating(
      gameId: map['gameId'] as String? ?? '',
      courseName: map['courseName'] as String? ?? '',
      teeTime: map['teeTime'] is DateTime
          ? map['teeTime'] as DateTime
          : DateTime.fromMillisecondsSinceEpoch(
              (map['teeTime'] as num?)?.toInt() ?? 0),
      coPlayers: rawPlayers
          .whereType<Map<String, dynamic>>()
          .map(RateablePlayer.fromMap)
          .toList(),
    );
  }
}
