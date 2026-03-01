/// Trust profile data models — plain Dart value objects (not FirestoreRecord).
///
/// Public trust data is sourced from UsersRecord fields.
/// Use TrustProfile.fromUsersRecord(record) to construct.
library;

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum BadgeTier {
  newPlayer,
  confirmed,
  regular,
  starter,
  anchor,
}

// ─────────────────────────────────────────────────────────────────────────────
// BadgeProgress
// ─────────────────────────────────────────────────────────────────────────────

class BadgeProgress {
  const BadgeProgress({
    required this.weightedRoundsRequired,
    required this.weightedRoundsCurrent,
    required this.uniqueCoPlayersRequired,
    required this.uniqueCoPlayersCurrent,
    this.cancellationRateRequired,
    this.cancellationRateCurrent,
    this.gamesHostedRequired,
    required this.gamesHostedCurrent,
  });

  final double weightedRoundsRequired;
  final double weightedRoundsCurrent;
  final int uniqueCoPlayersRequired;
  final int uniqueCoPlayersCurrent;

  /// null if cancellation rate is not needed for the next tier
  final double? cancellationRateRequired;
  final double? cancellationRateCurrent;

  /// null if games hosted is not required for the next tier
  final int? gamesHostedRequired;
  final int gamesHostedCurrent;

  static const BadgeProgress empty = BadgeProgress(
    weightedRoundsRequired: 0,
    weightedRoundsCurrent: 0,
    uniqueCoPlayersRequired: 0,
    uniqueCoPlayersCurrent: 0,
    gamesHostedCurrent: 0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CancellationWarning
// ─────────────────────────────────────────────────────────────────────────────

class CancellationWarning {
  const CancellationWarning({
    required this.active,
    required this.count,
    required this.detail,
  });

  /// true when the cancellation warning icon should be shown on the public profile
  final bool active;

  /// e.g. 2
  final int count;

  /// e.g. "2 late cancellations in the last 90 days"
  final String detail;

  static const CancellationWarning none = CancellationWarning(
    active: false,
    count: 0,
    detail: '',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TrustProfile
// ─────────────────────────────────────────────────────────────────────────────

/// Public trust data — readable by any authenticated user.
///
/// Constructed from UsersRecord fields via [fromMap].
class TrustProfile {
  const TrustProfile({
    required this.verifiedRounds,
    required this.weightedRounds,
    required this.uniqueCoPlayers,
    required this.gamesHosted,
    this.showUpRate,
    required this.joinDate,
    required this.currentBadge,
    this.nextBadge,
    required this.nextBadgeProgress,
    required this.cancellationWarning,
    this.handicap,
    this.homeCourse,
  });

  /// Raw count of community-verified rounds
  final int verifiedRounds;

  /// Weighted count for badge progression
  final double weightedRounds;

  /// Distinct app users played with
  final int uniqueCoPlayers;

  /// Games this user created
  final int gamesHosted;

  /// null if < 5 verified rounds (not public yet)
  final double? showUpRate;

  final DateTime joinDate;
  final BadgeTier currentBadge;

  /// null if already Anchor
  final BadgeTier? nextBadge;

  final BadgeProgress nextBadgeProgress;
  final CancellationWarning cancellationWarning;
  final int? handicap;
  final String? homeCourse;

  /// Construct from a raw map (e.g. subset of UsersRecord fields).
  factory TrustProfile.fromMap(Map<String, dynamic> map) {
    final badgeStr = map['badge_level'] as String? ?? 'new';
    final verifiedRounds = (map['verified_round_count'] as num?)?.toInt() ?? 0;
    final uniqueCoPlayersList = map['unique_co_players'] as List<dynamic>? ?? [];
    final cancellationWarningActive = map['cancellation_warning'] as bool? ?? false;
    final cancellationWarningCount = (map['cancellation_warning_count'] as num?)?.toInt() ?? 0;

    return TrustProfile(
      verifiedRounds: verifiedRounds,
      weightedRounds: (map['weighted_rounds'] as num?)?.toDouble() ?? 0.0,
      uniqueCoPlayers: uniqueCoPlayersList.length,
      gamesHosted: (map['games_hosted'] as num?)?.toInt() ?? 0,
      showUpRate: verifiedRounds >= 5 ? (map['show_up_rate'] as num?)?.toDouble() : null,
      joinDate: map['created_time'] is DateTime
          ? map['created_time'] as DateTime
          : DateTime.now(),
      currentBadge: parseBadgeTier(badgeStr),
      nextBadge: _parseNextBadge(badgeStr),
      nextBadgeProgress: BadgeProgress.empty,
      cancellationWarning: CancellationWarning(
        active: cancellationWarningActive,
        count: cancellationWarningCount,
        detail: cancellationWarningCount == 1
            ? '1 late cancellation in the last 90 days'
            : '$cancellationWarningCount late cancellations in the last 90 days',
      ),
      handicap: map['handicap'] as int?,
      homeCourse: (map['home_course'] as String?)?.isNotEmpty == true
          ? map['home_course'] as String
          : null,
    );
  }

  static BadgeTier parseBadgeTier(String value) {
    switch (value) {
      case 'anchor':
        return BadgeTier.anchor;
      case 'starter':
        return BadgeTier.starter;
      case 'regular':
        return BadgeTier.regular;
      case 'confirmed':
        return BadgeTier.confirmed;
      default:
        return BadgeTier.newPlayer;
    }
  }

  static BadgeTier? _parseNextBadge(String currentBadge) {
    switch (currentBadge) {
      case 'new':
        return BadgeTier.confirmed;
      case 'confirmed':
        return BadgeTier.regular;
      case 'regular':
        return BadgeTier.starter;
      case 'starter':
        return BadgeTier.anchor;
      default:
        return null;
    }
  }

  /// Human-readable tier name used in display contexts.
  static String tierLabel(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.newPlayer:
        return 'New';
      case BadgeTier.confirmed:
        return 'Confirmed';
      case BadgeTier.regular:
        return 'Regular';
      case BadgeTier.starter:
        return 'Starter';
      case BadgeTier.anchor:
        return 'Anchor';
    }
  }
}
