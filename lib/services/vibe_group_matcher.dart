import 'dart:math';

import '/models/vibe_profile.dart';
import '/services/vibe_matcher.dart';

class GroupVibeMember {
  const GroupVibeMember({
    required this.id,
    required this.name,
    required this.profile,
  });

  final String id;
  final String name;
  final VibeProfile profile;
}

class GroupVibeMemberResult {
  const GroupVibeMemberResult({
    required this.member,
    required this.matchResult,
    required this.displayScore,
  });

  final GroupVibeMember member;
  final VibeMatchResult matchResult;
  final double displayScore;
}

class GroupVibeConflict {
  const GroupVibeConflict({
    required this.memberId,
    required this.memberName,
    required this.category,
    required this.distance,
    required this.threshold,
    required this.whoHasDealbreaker,
  });

  final String memberId;
  final String memberName;
  final VibeCategory category;
  final int distance;
  final int threshold;
  final VibeDealbreakerOwner whoHasDealbreaker;
}

class GroupVibeDifference {
  const GroupVibeDifference({
    required this.category,
    required this.distance,
  });

  final VibeCategory category;
  final double distance;
}

class GroupVibeMatchResult {
  const GroupVibeMatchResult({
    required this.groupFitScore,
    required this.conflicts,
    required this.topDifferences,
    required this.memberResults,
    required this.lowestMatch,
    required this.groupAverages,
    required this.confidence,
    required this.confidenceLabel,
    required this.defaultCount,
    required this.defaultPercent,
  });

  final double groupFitScore;
  final List<GroupVibeConflict> conflicts;
  final List<GroupVibeDifference> topDifferences;
  final List<GroupVibeMemberResult> memberResults;
  final GroupVibeMemberResult? lowestMatch;
  final Map<VibeCategory, double> groupAverages;
  final VibeConfidence confidence;
  final String confidenceLabel;
  final int defaultCount;
  final double defaultPercent;

  bool get hasConflicts => conflicts.isNotEmpty;
}

class GroupVibeMatcher {
  static GroupVibeMatchResult scoreGroup({
    required VibeProfile mine,
    required List<GroupVibeMember> others,
  }) {
    // Group average is computed from other members only (excluding me).
    final groupAverages = <VibeCategory, double>{};
    final differences = <GroupVibeDifference>[];
    var weightedSum = 0.0;
    var defaultCount = 0;

    for (final category in VibeCategory.values) {
      final myPref = mine.preferenceFor(category);
      final average = others.isEmpty
          ? myPref.value.toDouble()
          : _averageValue(category, others);
      final distance = (myPref.value - average).abs();

      groupAverages[category] = average;
      differences.add(
        GroupVibeDifference(category: category, distance: distance),
      );

      final categoryMatch = (1 - (distance / 5)) * 100;
      final weight = VibeMatcher.weights[category] ?? 0;
      weightedSum += categoryMatch * weight;

      if (myPref.isDefault ||
          others.any((member) =>
              member.profile.preferenceFor(category).isDefault)) {
        defaultCount += 1;
      }
    }

    final groupFitScore = weightedSum / 100;
    final topDifferences = _topDifferences(differences);
    final defaultPercent = defaultCount / VibeCategory.values.length;
    final confidence = _confidenceFromDefaults(defaultCount);

    final memberResults = _memberResults(mine, others);
    final conflicts = _collectConflicts(memberResults);
    final lowestMatch = _lowestMatch(memberResults);

    return GroupVibeMatchResult(
      groupFitScore: groupFitScore,
      conflicts: conflicts,
      topDifferences: topDifferences,
      memberResults: memberResults,
      lowestMatch: lowestMatch,
      groupAverages: groupAverages,
      confidence: confidence,
      confidenceLabel: _confidenceLabel(confidence),
      defaultCount: defaultCount,
      defaultPercent: defaultPercent,
    );
  }

  static double _averageValue(
    VibeCategory category,
    List<GroupVibeMember> others,
  ) {
    final total = others.fold<double>(
      0,
      (sum, member) => sum + member.profile.preferenceFor(category).value,
    );
    return total / others.length;
  }

  static List<GroupVibeDifference> _topDifferences(
    List<GroupVibeDifference> differences,
  ) {
    final sorted = List<GroupVibeDifference>.from(differences)
      ..sort((a, b) => b.distance.compareTo(a.distance));
    return sorted.take(min(2, sorted.length)).toList();
  }

  static List<GroupVibeMemberResult> _memberResults(
    VibeProfile mine,
    List<GroupVibeMember> others,
  ) {
    return others.map((member) {
      final matchResult = VibeMatcher.score(mine, member.profile);
      final displayScore = matchResult.cappedScore ?? matchResult.totalScore;
      return GroupVibeMemberResult(
        member: member,
        matchResult: matchResult,
        displayScore: displayScore,
      );
    }).toList();
  }

  static GroupVibeMemberResult? _lowestMatch(
    List<GroupVibeMemberResult> results,
  ) {
    if (results.isEmpty) {
      return null;
    }
    return results.reduce(
      (a, b) => a.displayScore <= b.displayScore ? a : b,
    );
  }

  static List<GroupVibeConflict> _collectConflicts(
    List<GroupVibeMemberResult> memberResults,
  ) {
    final conflicts = <GroupVibeConflict>[];
    for (final memberResult in memberResults) {
      for (final conflict in memberResult.matchResult.conflicts) {
        conflicts.add(
          GroupVibeConflict(
            memberId: memberResult.member.id,
            memberName: memberResult.member.name,
            category: conflict.category,
            distance: conflict.distance,
            threshold: conflict.threshold,
            whoHasDealbreaker: conflict.whoHasDealbreaker,
          ),
        );
      }
    }
    return conflicts;
  }

  static VibeConfidence _confidenceFromDefaults(int defaultCount) {
    if (defaultCount >= 3) {
      return VibeConfidence.low;
    }
    if (defaultCount == 2) {
      return VibeConfidence.medium;
    }
    return VibeConfidence.high;
  }

  static String _confidenceLabel(VibeConfidence confidence) {
    switch (confidence) {
      case VibeConfidence.high:
        return 'high confidence';
      case VibeConfidence.medium:
        return 'medium confidence';
      case VibeConfidence.low:
        return 'low confidence';
    }
  }
}
