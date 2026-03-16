/// Challenge progress model for tracking user progress on challenges.
///
/// Stored in `users/{uid}.challenge_progress` as a map of challenge ID to
/// progress data. This model represents one entry in that map.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Immutable progress snapshot for a single challenge.
class ChallengeProgress {
  const ChallengeProgress({
    required this.challengeId,
    required this.current,
    required this.target,
    this.data,
    this.completedAt,
  });

  /// The challenge ID this progress tracks.
  final String challengeId;

  /// Current progress value.
  final int current;

  /// Target value for completion.
  final int target;

  /// Optional tracking data (unique course IDs, format keys, etc.).
  final List<String>? data;

  /// When the challenge was completed. Null if not yet completed.
  final DateTime? completedAt;

  // ── Computed Properties ─────────────────────────────────────────────────

  /// Whether the challenge has been completed.
  bool get isCompleted => completedAt != null;

  /// Progress as a percentage (0.0 to 1.0).
  double get progressPercent {
    if (target <= 0) return 0.0;
    return (current / target).clamp(0.0, 1.0);
  }

  /// Remaining count to complete.
  int get remaining => (target - current).clamp(0, target);

  // ── Factory ─────────────────────────────────────────────────────────────

  /// Creates a ChallengeProgress from a Firestore map entry.
  ///
  /// Example input:
  /// ```
  /// fromMap('courses_5', {
  ///   'current': 3,
  ///   'target': 5,
  ///   'data': ['courseId1', 'courseId2', 'courseId3'],
  /// })
  /// ```
  factory ChallengeProgress.fromMap(String id, Map<String, dynamic> map) {
    DateTime? completed;
    final completedAtRaw = map['completedAt'];
    if (completedAtRaw is Timestamp) {
      completed = completedAtRaw.toDate();
    } else if (completedAtRaw is DateTime) {
      completed = completedAtRaw;
    }

    List<String>? dataList;
    final rawData = map['data'];
    if (rawData is List) {
      dataList = rawData.map((e) => e.toString()).toList();
    }

    return ChallengeProgress(
      challengeId: id,
      current: (map['current'] as num?)?.toInt() ?? 0,
      target: (map['target'] as num?)?.toInt() ?? 0,
      data: dataList,
      completedAt: completed,
    );
  }

  /// Creates an empty/default progress for a challenge.
  factory ChallengeProgress.empty(String challengeId, {int target = 0}) {
    return ChallengeProgress(
      challengeId: challengeId,
      current: 0,
      target: target,
    );
  }

  /// Parses the full challenge_progress map from a user document.
  ///
  /// Returns a map of challenge ID → ChallengeProgress.
  static Map<String, ChallengeProgress> fromUserDoc(
    Map<String, dynamic>? progressMap,
  ) {
    if (progressMap == null) return {};

    final result = <String, ChallengeProgress>{};
    for (final entry in progressMap.entries) {
      // Skip sentinel fields
      if (entry.key.startsWith('_')) continue;
      if (entry.value is Map<String, dynamic>) {
        result[entry.key] = ChallengeProgress.fromMap(
          entry.key,
          entry.value as Map<String, dynamic>,
        );
      }
    }
    return result;
  }

  // ── Serialization ─────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'current': current,
      'target': target,
    };
    if (data != null) map['data'] = data;
    if (completedAt != null) map['completedAt'] = Timestamp.fromDate(completedAt!);
    return map;
  }

  @override
  String toString() =>
      'ChallengeProgress($challengeId: $current/$target${isCompleted ? ' ✓' : ''})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChallengeProgress &&
          other.challengeId == challengeId &&
          other.current == current &&
          other.target == target &&
          other.completedAt == completedAt);

  @override
  int get hashCode => Object.hash(challengeId, current, target, completedAt);
}
