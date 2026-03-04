/// Weekly streak profile for seasonal outdoor golf rounds.
///
/// Season runs May 1 - Oct 31 in Vancouver time.
/// Weeks are Monday-Sunday, identified by Monday's date (YYYY-MM-DD).
///
/// Tiers based on current consecutive weeks:
///   - Ember:   1-3 weeks
///   - Flame:   4-7 weeks
///   - Blaze:   8-12 weeks
///   - Inferno: 13-25 weeks
///   - Legend:  26+ weeks
library;

import '/backend/schema/users_record.dart';

/// Visual tier for streak display.
enum StreakTier {
  none(0, 'No Streak'),
  ember(1, 'Ember'),
  flame(4, 'Flame'),
  blaze(8, 'Blaze'),
  inferno(13, 'Inferno'),
  legend(26, 'Legend');

  const StreakTier(this.minWeeks, this.label);

  /// Minimum weeks required for this tier.
  final int minWeeks;

  /// Display label for this tier.
  final String label;

  /// Returns the tier for a given week count.
  static StreakTier forWeeks(int weeks) {
    if (weeks >= 26) return StreakTier.legend;
    if (weeks >= 13) return StreakTier.inferno;
    if (weeks >= 8) return StreakTier.blaze;
    if (weeks >= 4) return StreakTier.flame;
    if (weeks >= 1) return StreakTier.ember;
    return StreakTier.none;
  }
}

/// Milestones that trigger notifications.
enum StreakMilestone {
  none(0),
  week4(4),
  week8(8),
  week13(13),
  week26(26);

  const StreakMilestone(this.weeks);

  final int weeks;

  static StreakMilestone forWeeks(int weeks) {
    if (weeks >= 26) return StreakMilestone.week26;
    if (weeks >= 13) return StreakMilestone.week13;
    if (weeks >= 8) return StreakMilestone.week8;
    if (weeks >= 4) return StreakMilestone.week4;
    return StreakMilestone.none;
  }
}

/// Immutable streak profile value object.
class StreakProfile {
  const StreakProfile({
    required this.currentWeeks,
    this.previousWeeks,
    required this.longestWeeks,
    this.seasonId,
    required this.weeksPlayed,
    required this.weeksPending,
    this.lastCompletedWeekKey,
    required this.freezeEarned,
    required this.freezeUsed,
    this.freezeUsedWeekKey,
    required this.milestoneLevel,
  });

  /// Current consecutive weeks in active season.
  final int currentWeeks;

  /// Previous streak before break (same season). Null if no previous streak.
  final int? previousWeeks;

  /// Lifetime best streak.
  final int longestWeeks;

  /// Season ID (year string, e.g., "2026"). Null if no streak data yet.
  final String? seasonId;

  /// List of Monday keys (YYYY-MM-DD) played this season.
  final List<String> weeksPlayed;

  /// Weeks awaiting verification.
  final List<String> weeksPending;

  /// Last completed week key.
  final String? lastCompletedWeekKey;

  /// Whether freeze has been earned (reached 4 consecutive weeks).
  final bool freezeEarned;

  /// Whether freeze has been used this season.
  final bool freezeUsed;

  /// Week key where freeze was used.
  final String? freezeUsedWeekKey;

  /// Highest milestone level reached (0, 4, 8, 13, or 26).
  final int milestoneLevel;

  // ── Computed Properties ─────────────────────────────────────────────────

  /// Visual tier based on current streak.
  StreakTier get visualTier => StreakTier.forWeeks(currentWeeks);

  /// Whether user has an active streak (1+ consecutive weeks).
  bool get hasActiveStreak => currentWeeks > 0;

  /// Whether user has a previous streak that ended this season.
  bool get hasPreviousStreak => previousWeeks != null && previousWeeks! > 0;

  /// Whether freeze is available to use.
  bool get canUseFreeze => freezeEarned && !freezeUsed;

  /// Whether there's pending verification that might extend the streak.
  bool get hasPendingWeeks => weeksPending.isNotEmpty;

  /// Current milestone level as an enum.
  StreakMilestone get milestone => StreakMilestone.forWeeks(milestoneLevel);

  /// Display-friendly current weeks text (e.g., "4 weeks").
  String get currentWeeksText {
    if (currentWeeks == 0) return 'No streak';
    if (currentWeeks == 1) return '1 week';
    return '$currentWeeks weeks';
  }

  /// Display-friendly longest weeks text.
  String get longestWeeksText {
    if (longestWeeks == 0) return 'No record';
    if (longestWeeks == 1) return '1 week';
    return '$longestWeeks weeks';
  }

  /// Display-friendly previous weeks text (for showing after a break).
  String? get previousWeeksText {
    if (previousWeeks == null || previousWeeks == 0) return null;
    if (previousWeeks == 1) return '1 week';
    return '$previousWeeks weeks';
  }

  // ── Factory Constructors ────────────────────────────────────────────────

  /// Creates a StreakProfile from a UsersRecord.
  factory StreakProfile.fromUserRecord(UsersRecord record) {
    return StreakProfile(
      currentWeeks: record.streakCurrentWeeks,
      previousWeeks: record.streakPreviousWeeks,
      longestWeeks: record.streakLongestWeeks,
      seasonId: record.streakSeasonId,
      weeksPlayed: List<String>.from(record.streakWeeksPlayed),
      weeksPending: List<String>.from(record.streakWeeksPending),
      lastCompletedWeekKey: record.streakLastCompletedWeekKey,
      freezeEarned: record.streakFreezeEarned,
      freezeUsed: record.streakFreezeUsed,
      freezeUsedWeekKey: record.streakFreezeUsedWeekKey,
      milestoneLevel: record.streakMilestoneLevel,
    );
  }

  /// Creates an empty/default StreakProfile.
  factory StreakProfile.empty() {
    return const StreakProfile(
      currentWeeks: 0,
      previousWeeks: null,
      longestWeeks: 0,
      seasonId: null,
      weeksPlayed: [],
      weeksPending: [],
      lastCompletedWeekKey: null,
      freezeEarned: false,
      freezeUsed: false,
      freezeUsedWeekKey: null,
      milestoneLevel: 0,
    );
  }

  // ── Copy With ───────────────────────────────────────────────────────────

  StreakProfile copyWith({
    int? currentWeeks,
    int? previousWeeks,
    int? longestWeeks,
    String? seasonId,
    List<String>? weeksPlayed,
    List<String>? weeksPending,
    String? lastCompletedWeekKey,
    bool? freezeEarned,
    bool? freezeUsed,
    String? freezeUsedWeekKey,
    int? milestoneLevel,
  }) {
    return StreakProfile(
      currentWeeks: currentWeeks ?? this.currentWeeks,
      previousWeeks: previousWeeks ?? this.previousWeeks,
      longestWeeks: longestWeeks ?? this.longestWeeks,
      seasonId: seasonId ?? this.seasonId,
      weeksPlayed: weeksPlayed ?? this.weeksPlayed,
      weeksPending: weeksPending ?? this.weeksPending,
      lastCompletedWeekKey: lastCompletedWeekKey ?? this.lastCompletedWeekKey,
      freezeEarned: freezeEarned ?? this.freezeEarned,
      freezeUsed: freezeUsed ?? this.freezeUsed,
      freezeUsedWeekKey: freezeUsedWeekKey ?? this.freezeUsedWeekKey,
      milestoneLevel: milestoneLevel ?? this.milestoneLevel,
    );
  }

  @override
  String toString() =>
      'StreakProfile(current: $currentWeeks, longest: $longestWeeks, tier: $visualTier)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreakProfile &&
        other.currentWeeks == currentWeeks &&
        other.previousWeeks == previousWeeks &&
        other.longestWeeks == longestWeeks &&
        other.seasonId == seasonId &&
        other.freezeEarned == freezeEarned &&
        other.freezeUsed == freezeUsed &&
        other.milestoneLevel == milestoneLevel;
  }

  @override
  int get hashCode => Object.hash(
        currentWeeks,
        previousWeeks,
        longestWeeks,
        seasonId,
        freezeEarned,
        freezeUsed,
        milestoneLevel,
      );
}
