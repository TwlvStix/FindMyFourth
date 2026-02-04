import 'dart:math';

import '/models/vibe_profile.dart';
import '/services/vibe_matcher.dart';
import '/vibe/vibe_match_types.dart';
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
  final double distance;
  final double threshold;
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
    required this.baseScorePercent,
    required this.finalScorePercent,
    required this.softRiskPenalty01,
    required this.recommendation,
    required this.conflicts,
    required this.softRisks,
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
  final double baseScorePercent;
  final double finalScorePercent;
  final double softRiskPenalty01;
  final VibeRecommendation recommendation;
  final List<GroupVibeConflict> conflicts;
  final List<VibeSoftRisk> softRisks;
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

    final topDifferences = _topDifferences(differences);
    final defaultPercent = defaultCount / VibeCategory.values.length;
    final completeness =
        (completenessSum / max(1, VibeCategory.values.length)).toDouble();
    final confidence = _confidenceFromCompleteness(completeness);

    final memberResults = _memberResults(mine, others);
    final pairwiseResults = _pairwiseResults(mine, others);
    final groupHardBlocked = pairwiseResults
        .any((entry) => entry.result.recommendation == VibeRecommendation.notRecommended);
    final baseScorePercent = _averageScore(
      pairwiseResults.map((entry) => entry.result.baseScorePercent),
    );
    final softRiskPenalty01 = _averageScore(
      pairwiseResults.map((entry) => entry.result.softRiskPenalty01),
    );
    final finalScorePercent = (baseScorePercent * (1 - softRiskPenalty01))
        .clamp(VibeTuning.minScore, VibeTuning.maxScore)
        .toDouble();
    final recommendation = groupHardBlocked
        ? VibeRecommendation.notRecommended
        : softRiskPenalty01 >= VibeTuning.riskCautionThreshold
            ? VibeRecommendation.caution
            : VibeRecommendation.recommended;

    final conflicts = _collectConflicts(pairwiseResults);
    final softRisks = _collectSoftRisks(pairwiseResults);
    final lowestMatch = _lowestMatch(memberResults);

    return GroupVibeMatchResult(
      groupFitScore: finalScorePercent,
      baseScorePercent: baseScorePercent,
      finalScorePercent: finalScorePercent,
      softRiskPenalty01: softRiskPenalty01,
      recommendation: recommendation,
      conflicts: conflicts,
      softRisks: softRisks,
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
      final displayScore = matchResult.finalScorePercent;
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

  static List<_PairwiseMatch> _pairwiseResults(
    VibeProfile mine,
    List<GroupVibeMember> others,
  ) {
    final results = <_PairwiseMatch>[];
    final me = _PairwiseMember(id: 'me', name: 'You', profile: mine, isSelf: true);
    for (final other in others) {
      results.add(
        _PairwiseMatch(
          a: me,
          b: _PairwiseMember(
            id: other.id,
            name: other.name,
            profile: other.profile,
            isSelf: false,
          ),
          result: VibeMatcher.score(mine, other.profile),
        ),
      );
    }
    for (var i = 0; i < others.length; i++) {
      for (var j = i + 1; j < others.length; j++) {
        final a = others[i];
        final b = others[j];
        results.add(
          _PairwiseMatch(
            a: _PairwiseMember(
              id: a.id,
              name: a.name,
              profile: a.profile,
              isSelf: false,
            ),
            b: _PairwiseMember(
              id: b.id,
              name: b.name,
              profile: b.profile,
              isSelf: false,
            ),
            result: VibeMatcher.score(a.profile, b.profile),
          ),
        );
      }
    }
    return results;
  }

  static List<GroupVibeConflict> _collectConflicts(
    List<_PairwiseMatch> pairwiseResults,
  ) {
    final conflicts = <GroupVibeConflict>[];
    for (final pair in pairwiseResults) {
      for (final conflict in pair.result.hardConflicts) {
        final pairLabel = _pairLabel(pair.a, pair.b);
        final memberId = _pairId(pair.a, pair.b);
        conflicts.add(
          GroupVibeConflict(
            memberId: memberId,
            memberName: pairLabel,
            category: conflict.category,
            distance: conflict.distance,
            threshold: conflict.thresholdOrLimit,
            whoHasDealbreaker:
                _dealbreakerOwner(conflict.myDealbreaker, conflict.theirDealbreaker),
          ),
        );
      }
    }
    return conflicts;
  }

  static List<VibeSoftRisk> _collectSoftRisks(
    List<_PairwiseMatch> pairwiseResults,
  ) {
    final risks = <VibeSoftRisk>[];
    for (final pair in pairwiseResults) {
      final pairLabel = _pairLabel(pair.a, pair.b);
      for (final risk in pair.result.softRisks) {
        risks.add(
          VibeSoftRisk(
            category: risk.category,
            distance: risk.distance,
            tolerance: risk.tolerance,
            overBy: risk.overBy,
            severity01: risk.severity01,
            weight: risk.weight,
            reason:
                '${VibeLabels.titleFor(risk.category)} mismatch between $pairLabel is ${risk.overBy.toStringAsFixed(1)} past tolerance.',
          ),
        );
      }
    }
    final sorted = List<VibeSoftRisk>.from(risks)
      ..sort((a, b) => b.severity01.compareTo(a.severity01));
    return sorted.take(3).toList();
  }

  static double _averageScore(Iterable<double> scores) {
    var count = 0;
    var sum = 0.0;
    for (final score in scores) {
      sum += score;
      count += 1;
    }
    if (count == 0) {
      return 0;
    }
    return (sum / count).toDouble();
  }

  static String _pairLabel(_PairwiseMember a, _PairwiseMember b) {
    if (a.isSelf && !b.isSelf) {
      return b.name;
    }
    if (!a.isSelf && b.isSelf) {
      return a.name;
    }
    return '${a.name} & ${b.name}';
  }

  static String _pairId(_PairwiseMember a, _PairwiseMember b) {
    if (a.isSelf && !b.isSelf) {
      return b.id;
    }
    if (!a.isSelf && b.isSelf) {
      return a.id;
    }
    final ordered = [a.id, b.id]..sort();
    return ordered.join('|');
  }

  static VibeDealbreakerOwner _dealbreakerOwner(
    bool myDealbreaker,
    bool theirDealbreaker,
  ) {
    if (myDealbreaker && theirDealbreaker) {
      return VibeDealbreakerOwner.both;
    }
    if (myDealbreaker) {
      return VibeDealbreakerOwner.me;
    }
    return VibeDealbreakerOwner.them;
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

class _PairwiseMember {
  const _PairwiseMember({
    required this.id,
    required this.name,
    required this.profile,
    required this.isSelf,
  });

  final String id;
  final String name;
  final VibeProfile profile;
  final bool isSelf;
}

class _PairwiseMatch {
  const _PairwiseMatch({
    required this.a,
    required this.b,
    required this.result,
  });

  final _PairwiseMember a;
  final _PairwiseMember b;
  final VibeMatchResult result;
}
