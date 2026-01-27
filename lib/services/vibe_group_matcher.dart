import 'dart:math';

import '/models/vibe_profile.dart';
import '/services/vibe_matcher.dart';
import '/vibe/vibe_scoring.dart';
import '/vibe/vibe_tuning.dart';

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
    required this.confidenceScore,
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
  final double confidenceScore;
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
    var weightTotal = 0.0;
    var defaultCount = 0;
    var completenessSum = 0.0;

    for (final category in VibeCategory.values) {
      final myPref = mine.preferenceFor(category);
      final average = others.isEmpty
          ? myPref.value.toDouble()
          : _averageValue(category, others);
      final averageThreshold = others.isEmpty
          ? myPref.threshold.toDouble()
          : _averageThreshold(category, others);
      final distance = (myPref.value - average).abs();

      final myIsDefault = isDefault(
        category,
        myPref.value,
        isDefaultFlag: myPref.isDefault,
      );
      final otherIsDefault = _groupHasDefault(category, others);
      final importanceMultiplierValue = _groupImportanceMultiplier(
        category,
        mine,
        others,
      );
      if (myIsDefault || otherIsDefault) {
        defaultCount += 1;
      }
      completenessSum += defaultCompleteness(myIsDefault, otherIsDefault);

      groupAverages[category] = average;
      differences.add(
        GroupVibeDifference(category: category, distance: distance),
      );

      final matchScore = categoryMatch(
        myPref.value,
        average,
        myTolerance: myPref.threshold,
        theirTolerance: averageThreshold.round(),
        gamma: VibeTuning.gamma,
        scaleMax: VibeTuning.scaleMax,
      );
      final baseWeight = VibeMatcher.weights[category] ?? 0;
      final weight = baseWeight *
          getDefaultMultiplier(myIsDefault, otherIsDefault) *
          importanceMultiplierValue;
      weightedSum += matchScore * weight;
      weightTotal += weight;
    }

    final groupFitScore =
        (weightTotal > 0 ? weightedSum / weightTotal : 0).toDouble();
    final topDifferences = _topDifferences(differences);
    final defaultPercent = defaultCount / VibeCategory.values.length;
    final completeness =
        (completenessSum / max(1, VibeCategory.values.length)).toDouble();
    final confidence = _confidenceFromCompleteness(completeness);

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
      confidenceScore: completeness,
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

  static double _averageThreshold(
    VibeCategory category,
    List<GroupVibeMember> others,
  ) {
    final total = others.fold<double>(
      0,
      (sum, member) => sum + member.profile.preferenceFor(category).threshold,
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

  static bool _groupHasDefault(
    VibeCategory category,
    List<GroupVibeMember> others,
  ) {
    for (final member in others) {
      final pref = member.profile.preferenceFor(category);
      if (isDefault(category, pref.value, isDefaultFlag: pref.isDefault)) {
        return true;
      }
    }
    return false;
  }

  static double _groupImportanceMultiplier(
    VibeCategory category,
    VibeProfile mine,
    List<GroupVibeMember> others,
  ) {
    final myMult = importanceMultiplier(mine.importanceFor(category));
    final theirMult = others.isEmpty
        ? myMult
        : _averageImportanceMultiplier(category, others);
    return ((myMult + theirMult) / 2).toDouble();
  }

  static double _averageImportanceMultiplier(
    VibeCategory category,
    List<GroupVibeMember> others,
  ) {
    if (others.isEmpty) {
      return VibeTuning.importanceNormalMultiplier;
    }
    final total = others.fold<double>(
      0,
      (sum, member) =>
          sum + importanceMultiplier(member.profile.importanceFor(category)),
    );
    return total / others.length;
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

  static VibeConfidence _confidenceFromCompleteness(double completeness) {
    if (completeness >= 0.8) {
      return VibeConfidence.high;
    }
    if (completeness >= 0.6) {
      return VibeConfidence.medium;
    }
    return VibeConfidence.low;
  }

  static String _confidenceLabel(VibeConfidence confidence) {
    switch (confidence) {
      case VibeConfidence.high:
        return 'high';
      case VibeConfidence.medium:
        return 'medium';
      case VibeConfidence.low:
        return 'low';
    }
  }
}
