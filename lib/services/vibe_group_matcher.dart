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
    required this.yourFitScore,
    required this.hasCohesionIssue,
    this.cohesionWarning,
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
  final double yourFitScore;        // your one-sided average vs all members
  final bool hasCohesionIssue;      // true if any other-other pair is hard-blocked or < 40%
  final String? cohesionWarning;    // explanation text when cohesion issue exists
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
    var defaultCount = 0;
    var completenessSum = 0.0;

    for (final category in VibeCategory.values) {
      final myPref = mine.preferenceFor(category);
      final average = others.isEmpty
          ? myPref.value.toDouble()
          : _averageValue(category, others);
      final distance = (myPref.value - average).abs();

      final myIsDefault = isDefault(
        category,
        myPref.value,
        isDefaultFlag: myPref.isDefault,
      );
      final otherIsDefault = _groupHasDefault(category, others);
      if (myIsDefault || otherIsDefault) {
        defaultCount += 1;
      }
      completenessSum += defaultCompleteness(myIsDefault, otherIsDefault);

      groupAverages[category] = average;
      differences.add(
        GroupVibeDifference(category: category, distance: distance),
      );
    }

    final topDifferences = _topDifferences(differences);
    final defaultPercent = defaultCount / VibeCategory.values.length;
    final completeness =
        (completenessSum / max(1, VibeCategory.values.length)).toDouble();
    final confidence = _confidenceFromCompleteness(completeness);

    // Step 1: compute your one-sided fit against each member
    final memberResults = <GroupVibeMemberResult>[];
    var yourFitSum = 0.0;

    for (final member in others) {
      final matchResult = VibeMatcher.score(mine, member.profile);
      // Blend your fit (60%) with their fit (40%) for balanced group scoring
      final displayScore = VibeTuning.groupMyFitWeight * matchResult.myFitPercent +
          VibeTuning.groupMutualFitWeight * matchResult.theirFitPercent;
      yourFitSum += displayScore;
      memberResults.add(GroupVibeMemberResult(
        member: member,
        matchResult: matchResult,
        displayScore: displayScore,
      ));
    }

    final yourFitScore = others.isEmpty
        ? 0.0
        : (yourFitSum / others.length);

    // Step 2: check cohesion among other members (other-other pairs only)
    var hasCohesionIssue = false;
    final otherOtherResults = <_PairwiseMatch>[];
    for (var i = 0; i < others.length; i++) {
      for (var j = i + 1; j < others.length; j++) {
        final result = VibeMatcher.score(others[i].profile, others[j].profile);
        otherOtherResults.add(_PairwiseMatch(
          a: _PairwiseMember(id: others[i].id, name: others[i].name, profile: others[i].profile, isSelf: false),
          b: _PairwiseMember(id: others[j].id, name: others[j].name, profile: others[j].profile, isSelf: false),
          result: result,
        ));
        if (result.recommendation == VibeRecommendation.notRecommended ||
            result.finalScorePercent < 40.0) {
          hasCohesionIssue = true;
        }
      }
    }

    // Step 3: apply cohesion penalty (15% reduction when other members clash)
    final adjustedFitScore = hasCohesionIssue
        ? (yourFitScore * VibeTuning.groupCohesionPenaltyFactor)
        : yourFitScore;

    final String? cohesionWarning = hasCohesionIssue
        ? 'Some players in this group may not mesh well together.'
        : null;

    // Step 4: determine recommendation from YOUR matches (me-vs-others only)
    final myHardBlocked = memberResults
        .any((r) => r.matchResult.recommendation == VibeRecommendation.notRecommended);
    // Also check other-other hard blocks — a group fight ruins everyone's round
    final groupHardBlocked = myHardBlocked ||
        otherOtherResults.any((p) => p.result.recommendation == VibeRecommendation.notRecommended);

    final finalScore = groupHardBlocked
        ? min(adjustedFitScore, 40.0)
        : adjustedFitScore.clamp(VibeTuning.minScore, VibeTuning.maxScore).toDouble();

    // Soft risk penalty — average from your matches only
    final yourSoftPenalty = memberResults.isEmpty
        ? 0.0
        : memberResults.map((r) => r.matchResult.softRiskPenalty01).reduce((a, b) => a + b) / memberResults.length;

    final recommendation = groupHardBlocked
        ? VibeRecommendation.notRecommended
        : yourSoftPenalty >= VibeTuning.riskCautionThreshold
            ? VibeRecommendation.caution
            : VibeRecommendation.recommended;

    // Collect conflicts from ALL pairwise (me-vs-other + other-other)
    final allPairwise = <_PairwiseMatch>[
      ...memberResults.map((r) => _PairwiseMatch(
        a: _PairwiseMember(id: 'me', name: 'You', profile: mine, isSelf: true),
        b: _PairwiseMember(id: r.member.id, name: r.member.name, profile: r.member.profile, isSelf: false),
        result: r.matchResult,
      )),
      ...otherOtherResults,
    ];
    final conflicts = _collectConflicts(allPairwise);
    final softRisks = _collectSoftRisks(allPairwise);
    final lowestMatch = _lowestMatch(memberResults);

    return GroupVibeMatchResult(
      groupFitScore: finalScore,
      yourFitScore: yourFitScore,
      hasCohesionIssue: hasCohesionIssue,
      cohesionWarning: cohesionWarning,
      baseScorePercent: yourFitScore,
      finalScorePercent: finalScore,
      softRiskPenalty01: yourSoftPenalty,
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
