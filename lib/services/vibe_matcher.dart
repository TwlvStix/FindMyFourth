import 'dart:math';

import '/models/vibe_profile.dart';
import '/services/vibe_interaction_adjustments.dart';
import '/vibe/vibe_dealbreaker.dart';
import '/vibe/vibe_scoring.dart';
import '/vibe/vibe_tuning.dart';

enum VibeConfidence {
  high,
  medium,
  low,
}

enum VibeDealbreakerOwner {
  me,
  them,
  both,
}

class VibeCategoryScore {
  const VibeCategoryScore({
    required this.categoryMatch,
    required this.weight,
    required this.distance,
  });

  final double categoryMatch;
  final double weight;
  final int distance;
}

class VibeConflict {
  const VibeConflict({
    required this.category,
    required this.myValue,
    required this.theirValue,
    required this.distance,
    required this.threshold,
    required this.whoHasDealbreaker,
  });

  final VibeCategory category;
  final int myValue;
  final int theirValue;
  final int distance;
  final int threshold;
  final VibeDealbreakerOwner whoHasDealbreaker;
}

class VibeDifference {
  const VibeDifference({
    required this.category,
    required this.distance,
  });

  final VibeCategory category;
  final int distance;
}

class VibeMatchResult {
  const VibeMatchResult({
    required this.totalScore,
    required this.cappedScore,
    required this.isRecommended,
    required this.interactionBonus,
    required this.interactionReasons,
    required this.interactionAppliedRules,
    required this.conflicts,
    required this.topDifferences,
    required this.perCategory,
    required this.confidence,
    required this.confidenceLabel,
    required this.confidenceScore,
    required this.defaultCount,
    required this.defaultPercent,
  });

  final double totalScore;
  final double? cappedScore;
  final bool isRecommended;
  final double interactionBonus;
  final List<String> interactionReasons;
  final List<AppliedRule> interactionAppliedRules;
  final List<VibeConflict> conflicts;
  final List<VibeDifference> topDifferences;
  final Map<VibeCategory, VibeCategoryScore> perCategory;
  final VibeConfidence confidence;
  final String confidenceLabel;
  final double confidenceScore;
  final int defaultCount;
  final double defaultPercent;
}

class VibeMatcher {
  static const Map<VibeCategory, double> weights = {
    VibeCategory.pace: 25,
    VibeCategory.money: 20,
    VibeCategory.drinking: 15,
    VibeCategory.weed: 10,
    VibeCategory.music: 10,
    VibeCategory.chat: 10,
    VibeCategory.competitive: 10,
  };

  static VibeMatchResult score(
    VibeProfile mine,
    VibeProfile theirs, {
    bool enableInteractionLayer = true,
  }) {
    final perCategory = <VibeCategory, VibeCategoryScore>{};
    final conflicts = <VibeConflict>[];
    final differences = <VibeDifference>[];
    final scoresByCategory = <VibeCategory, double>{};
    final weightsByCategory = <VibeCategory, double>{};
    final mismatchedByCategory = <VibeCategory, bool>{};

    var weightedSum = 0.0;
    var weightTotal = 0.0;
    var defaultCount = 0;
    var completenessSum = 0.0;

    for (final category in VibeCategory.values) {
      final myPref = mine.preferenceFor(category);
      final theirPref = theirs.preferenceFor(category);

      final myIsDefault = isDefault(
        category,
        myPref.value,
        isDefaultFlag: myPref.isDefault,
      );
      final theirIsDefault = isDefault(
        category,
        theirPref.value,
        isDefaultFlag: theirPref.isDefault,
      );
      final importanceMultiplierValue = blendedImportanceMultiplier(
        mine.importanceFor(category),
        theirs.importanceFor(category),
      );
      if (myIsDefault || theirIsDefault) {
        defaultCount += 1;
      }

      final distance = (myPref.value - theirPref.value).abs();
      final matchScore = categoryMatch(
        myPref.value,
        theirPref.value,
        myTolerance: myPref.threshold,
        theirTolerance: theirPref.threshold,
        gamma: VibeTuning.gamma,
        scaleMax: VibeTuning.scaleMax,
      );
      // Mismatch is asymmetric: either side exceeding their own tolerance counts.
      mismatchedByCategory[category] =
          distance > myPref.threshold || distance > theirPref.threshold;
      final baseWeight = weights[category] ?? 0;
      final weight = baseWeight *
          getDefaultMultiplier(myIsDefault, theirIsDefault) *
          importanceMultiplierValue;
      weightedSum += matchScore * weight;
      weightTotal += weight;
      completenessSum += defaultCompleteness(myIsDefault, theirIsDefault);
      weightsByCategory[category] = weight;

      perCategory[category] = VibeCategoryScore(
        categoryMatch: matchScore,
        weight: weight,
        distance: distance,
      );
      scoresByCategory[category] = (matchScore / 100).clamp(0, 1).toDouble();

      differences.add(VibeDifference(category: category, distance: distance));

      if (_hasDealbreakerConflict(category, myPref, theirPref)) {
        conflicts.add(
          VibeConflict(
            category: category,
            myValue: myPref.value,
            theirValue: theirPref.value,
            distance: distance,
            threshold: _conflictThreshold(myPref, theirPref),
            whoHasDealbreaker: _dealbreakerOwner(myPref, theirPref),
          ),
        );
      }
    }

    for (final category in VibeCategory.values) {
      final existing = perCategory[category];
      if (existing == null) {
        continue;
      }
      final rawWeight = weightsByCategory[category] ?? 0;
      final normalizedWeight = weightTotal > 0
          ? (rawWeight / weightTotal * 100).toDouble()
          : 0.0;
      perCategory[category] = VibeCategoryScore(
        categoryMatch: existing.categoryMatch,
        weight: normalizedWeight,
        distance: existing.distance,
      );
    }

    final baseScore =
        (weightTotal > 0 ? weightedSum / weightTotal : 0).toDouble();
    final adjustment = interactionAdjustments(
      scoresByCategory,
      mismatchedByCategory,
      enableInteractionLayer: enableInteractionLayer,
    );
    final adjustedScore = clampDouble(
      (baseScore / 100) + adjustment.bonusTotal,
      0,
      1,
    );
    final totalScore = (adjustedScore * 100).toDouble();
    final isRecommended = conflicts.isEmpty;
    final cappedScore = dealbreakerCappedScore(
      score: totalScore,
      isDealbreaker: !isRecommended,
      cap: VibeTuning.dealbreakerCap,
    );
    final topDifferences = _topDifferences(
      differences,
      perCategory,
      scoresByCategory,
    );
    final defaultPercent = defaultCount / VibeCategory.values.length;
    final completeness =
        (completenessSum / max(1, VibeCategory.values.length)).toDouble();
    final confidence = _confidenceFromCompleteness(completeness);

    VibeAnalytics.logMatchScore(
      VibeAnalyticsPayload(
        score: cappedScore ?? totalScore,
        isCapped: cappedScore != null,
        perCategoryScores: scoresByCategory,
        effectiveWeights: weightsByCategory,
      ),
    );

    return VibeMatchResult(
      totalScore: totalScore,
      cappedScore: cappedScore,
      isRecommended: isRecommended,
      interactionBonus: adjustment.bonusTotal,
      interactionReasons: adjustment.reasons,
      interactionAppliedRules: adjustment.appliedRules,
      conflicts: conflicts,
      topDifferences: topDifferences,
      perCategory: perCategory,
      confidence: confidence,
      confidenceLabel: _confidenceLabel(confidence),
      confidenceScore: completeness,
      defaultCount: defaultCount,
      defaultPercent: defaultPercent,
    );
  }

  static bool _hasDealbreakerConflict(
    VibeCategory category,
    VibePreference mine,
    VibePreference theirs,
  ) {
    return dealbreakerTriggeredForCategory(
      category: category,
      aValue: mine.value,
      aDealbreaker: mine.dealbreaker,
      aIsDefault: mine.isDefault,
      bValue: theirs.value,
      bDealbreaker: theirs.dealbreaker,
      bIsDefault: theirs.isDefault,
    );
  }

  static int _conflictThreshold(
    VibePreference mine,
    VibePreference theirs,
  ) {
    return dealbreakerConflictThreshold(
      mineDealbreaker: mine.dealbreaker,
      theirsDealbreaker: theirs.dealbreaker,
      myThreshold: mine.threshold,
      theirThreshold: theirs.threshold,
    );
  }

  static VibeDealbreakerOwner _dealbreakerOwner(
    VibePreference mine,
    VibePreference theirs,
  ) {
    if (mine.dealbreaker && theirs.dealbreaker) {
      return VibeDealbreakerOwner.both;
    }
    if (mine.dealbreaker) {
      return VibeDealbreakerOwner.me;
    }
    return VibeDealbreakerOwner.them;
  }

  static List<VibeDifference> _topDifferences(
    List<VibeDifference> differences,
    Map<VibeCategory, VibeCategoryScore> perCategory,
    Map<VibeCategory, double> scoresByCategory,
  ) {
    double impactFor(VibeDifference difference) {
      final score01 = scoresByCategory[difference.category] ?? 0;
      final weightPct = perCategory[difference.category]?.weight ?? 0;
      final impact = (1 - score01) * weightPct;
      return impact.abs() < 1e-6 ? 0 : impact;
    }

    final sorted = List<VibeDifference>.from(differences)
      ..sort((a, b) {
        final impactA = impactFor(a);
        final impactB = impactFor(b);
        if (impactA != impactB) {
          return impactB.compareTo(impactA);
        }
        return b.distance.compareTo(a.distance);
      });
    final count = min(3, sorted.length);
    return sorted.take(count).toList();
  }

  static VibeConfidence _confidenceFromCompleteness(double completeness) {
    if (completeness >= VibeTuning.confidenceHighThreshold) {
      return VibeConfidence.high;
    }
    if (completeness >= VibeTuning.confidenceMediumThreshold) {
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
