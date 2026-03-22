/// Player standing data models — plain Dart value objects (not FirestoreRecord).
///
/// Private standing data — only the owning user should see this.
/// Constructed from the `Map<String, dynamic>` returned by the getMyStanding
/// cloud function.
library;

import 'trust_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum StrikeReason { lateCancel, dayOfCancel, ghostNoShow }

enum RestrictionType { cooldown24h, restricted7d, restricted30d, suspended }

// ─────────────────────────────────────────────────────────────────────────────
// Strike
// ─────────────────────────────────────────────────────────────────────────────

class Strike {
  const Strike({
    required this.id,
    required this.reason,
    required this.gameDate,
    required this.courseName,
    required this.strikeDate,
    required this.expiresDate,
    required this.strikesIssued,
  });

  final String id;
  final StrikeReason reason;
  final DateTime gameDate;
  final String courseName;
  final DateTime strikeDate;

  /// Strikes expire 6 months from strikeDate
  final DateTime expiresDate;

  /// 1 for day-of/late cancel, 2 for ghost no-show
  final int strikesIssued;

  factory Strike.fromMap(Map<String, dynamic> map) {
    return Strike(
      id: map['id'] as String? ?? '',
      reason: _parseReason(map['reason'] as String? ?? ''),
      gameDate: _parseDate(map['gameDate']),
      courseName: map['courseName'] as String? ?? '',
      strikeDate: _parseDate(map['strikeDate']),
      expiresDate: _parseDate(map['expiresAt']),
      strikesIssued: (map['strikesIssued'] as num?)?.toInt() ?? 1,
    );
  }

  static StrikeReason _parseReason(String value) {
    switch (value) {
      case 'late_cancel':
      case 'late_cancel_pattern':
        return StrikeReason.lateCancel;
      case 'day_of_cancel':
        return StrikeReason.dayOfCancel;
      case 'ghost_no_show':
        return StrikeReason.ghostNoShow;
      default:
        return StrikeReason.dayOfCancel;
    }
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  String get reasonLabel {
    switch (reason) {
      case StrikeReason.lateCancel:
        return 'Late cancel';
      case StrikeReason.dayOfCancel:
        return 'Day-of cancel';
      case StrikeReason.ghostNoShow:
        return 'Ghost no-show';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Restriction
// ─────────────────────────────────────────────────────────────────────────────

class Restriction {
  const Restriction({
    required this.type,
    required this.startsAt,
    this.endsAt,
    required this.reason,
  });

  final RestrictionType type;
  final DateTime startsAt;

  /// null for suspended (manual review required)
  final DateTime? endsAt;

  final String reason;

  factory Restriction.fromMap(Map<String, dynamic> map) {
    return Restriction(
      type: _parseType(map['type'] as String? ?? ''),
      startsAt: Strike._parseDate(map['startsAt']),
      endsAt: map['endsAt'] != null ? Strike._parseDate(map['endsAt']) : null,
      reason: map['reason'] as String? ?? '',
    );
  }

  static RestrictionType _parseType(String value) {
    switch (value) {
      case 'cooldown_24h':
      case 'cooldown24h':
        return RestrictionType.cooldown24h;
      case 'restricted_7d':
      case 'restricted7d':
        return RestrictionType.restricted7d;
      case 'restricted_30d':
      case 'restricted30d':
        return RestrictionType.restricted30d;
      case 'suspended':
        return RestrictionType.suspended;
      default:
        return RestrictionType.cooldown24h;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PlayerStanding
// ─────────────────────────────────────────────────────────────────────────────

/// Private standing data — only readable by the owning user.
///
/// Constructed from the response of the getMyStanding cloud function.
class PlayerStanding {
  const PlayerStanding({
    required this.strikes,
    required this.totalActiveStrikes,
    this.currentRestriction,
    this.showUpRate,
    required this.showUpRateExplainer,
    required this.cancellationRate,
    required this.cancellationRateExplainer,
    required this.weightedRoundProgress,
    required this.currentBadge,
    this.nextBadge,
    this.nextBadgeRequirements,
    this.nextThreshold,
    this.comebackMessage,
  });

  final List<Strike> strikes;
  final int totalActiveStrikes;

  /// null if no active restriction
  final Restriction? currentRestriction;

  /// null if < 5 verified rounds
  final double? showUpRate;

  /// e.g. "Based on 14 attended / 14 committed"
  final String showUpRateExplainer;

  final double cancellationRate;

  /// e.g. "2 late/day-of cancels out of 20 total commitments"
  final String cancellationRateExplainer;

  final double weightedRoundProgress;
  final BadgeTier currentBadge;
  final BadgeTier? nextBadge;

  /// Raw requirements map from cloud function for badge progress bars
  final Map<String, dynamic>? nextBadgeRequirements;

  /// Next restriction threshold from cloud function (strikes, restriction, strikesNeeded)
  final Map<String, dynamic>? nextThreshold;

  /// Shown once after a restriction ends
  final String? comebackMessage;

  factory PlayerStanding.fromMap(Map<String, dynamic> map) {
    final rawStrikes = (map['strikes'] as List<dynamic>?) ?? [];
    final totalActive = (map['activeStrikeCount'] as num?)?.toInt() ?? 0;

    final rawRestriction = map['currentRestriction'] as Map<String, dynamic>?;

    final showUpRate = (map['showUpRate'] as num?)?.toDouble();
    final showUpDenom = (map['showUpRateDenominator'] as num?)?.toInt() ?? 0;
    final cancelRate = (map['cancellationRate'] as num?)?.toDouble() ?? 0.0;
    final cancelNum = (map['cancellationRateNumerator'] as num?)?.toInt() ?? 0;
    final cancelDenom = (map['cancellationRateDenominator'] as num?)?.toInt() ?? 0;

    final badgeStr = map['currentBadge'] as String? ?? 'new';
    final nextBadgeStr = map['nextBadge'] as String?;

    return PlayerStanding(
      strikes: rawStrikes
          .whereType<Map<String, dynamic>>()
          .map(Strike.fromMap)
          .toList(),
      totalActiveStrikes: totalActive,
      currentRestriction:
          rawRestriction != null ? Restriction.fromMap(rawRestriction) : null,
      showUpRate: showUpDenom >= 5 ? showUpRate : null,
      showUpRateExplainer: showUpDenom > 0
          ? 'Based on ${(showUpRate != null ? (showUpRate * showUpDenom).round() : 0)} attended / $showUpDenom committed'
          : 'Play 5 verified rounds to unlock your show-up rate.',
      cancellationRate: cancelRate,
      cancellationRateExplainer: cancelDenom > 0
          ? '$cancelNum late/day-of cancel${cancelNum == 1 ? '' : 's'} out of $cancelDenom total commitment${cancelDenom == 1 ? '' : 's'}'
          : 'No cancellation history yet.',
      weightedRoundProgress:
          (map['weightedRounds'] as num?)?.toDouble() ?? 0.0,
      currentBadge: TrustProfile.parseBadgeTier(badgeStr),
      nextBadge: nextBadgeStr != null
          ? TrustProfile.parseBadgeTier(nextBadgeStr)
          : null,
      nextBadgeRequirements:
          map['nextBadgeRequirements'] as Map<String, dynamic>?,
      nextThreshold: map['nextThreshold'] as Map<String, dynamic>?,
      comebackMessage: map['comebackMessage'] as String?,
    );
  }

  /// Returns empty standing (e.g. while loading)
  static const PlayerStanding empty = PlayerStanding(
    strikes: [],
    totalActiveStrikes: 0,
    showUpRateExplainer: '',
    cancellationRate: 0.0,
    cancellationRateExplainer: '',
    weightedRoundProgress: 0.0,
    currentBadge: BadgeTier.newPlayer,
  );
}
