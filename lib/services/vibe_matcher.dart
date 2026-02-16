import 'dart:math';

import '/models/vibe_profile.dart';
import '/services/vibe_interaction_adjustments.dart';
import '/vibe/vibe_dealbreaker.dart';
import '/vibe/vibe_match_types.dart';
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
    required this.recommendation,
    required this.hardConflicts,
    required this.softRisks,
    required this.softRiskPenalty01,
    required this.baseScorePercent,
    required this.finalScorePercent,
    required this.myFitPercent,
    required this.theirFitPercent,
    required this.confidence,
    required this.confidenceLabel,
    required this.confidenceScore,
    required this.defaultCount,
    required this.defaultPercent,
  });

  /// Serializes the match result and both profiles into a map suitable
  /// for storing in a match_feedback document. Call this at the time
  /// the score is displayed so the snapshot reflects exactly what the
  /// user saw, even if profiles change later.
  Map<String, dynamic> toFeedbackSnapshot({
    required VibeProfile reviewerProfile,
    required VibeProfile reviewedProfile,
  }) {
    return <String, dynamic>{
      'vibe_score_shown': finalScorePercent,
      'base_score_shown': baseScorePercent,
      'my_fit_shown': myFitPercent,
      'their_fit_shown': theirFitPercent,
      'recommendation_shown': recommendation.name,
      'confidence_shown': confidenceLabel,
      'soft_risk_penalty': softRiskPenalty01,
      'interaction_bonus': interactionBonus,
      'hard_blocked': !isRecommended,
      'category_scores': {
        for (final entry in perCategory.entries)
          entry.key.key: {
            'match': entry.value.categoryMatch,
            'distance': entry.value.distance,
            'weight': entry.value.weight,
          },
      },
      'profile_snapshot_reviewer': _profileToSnapshot(reviewerProfile),
      'profile_snapshot_reviewed': _profileToSnapshot(reviewedProfile),
    };
  }

  static Map<String, dynamic> _profileToSnapshot(VibeProfile profile) {
    return <String, dynamic>{
      for (final category in VibeCategory.values)
        category.key: {
          'value': profile.preferenceFor(category).value,
          'importance': profile.importanceFor(category).key,
          'dealbreaker': profile.preferenceFor(category).dealbreaker,
          'threshold': profile.preferenceFor(category).threshold,
          'is_default': profile.preferenceFor(category).isDefault,
        },
    };
  }

  final double totalScore;
  final double? cappedScore;
  final bool isRecommended;
  final double interactionBonus;
  final List<String> interactionReasons;
  final List<AppliedRule> interactionAppliedRules;
  final List<VibeConflict> conflicts;
  final List<VibeDifference> topDifferences;
  final Map<VibeCategory, VibeCategoryScore> perCategory;
  final VibeRecommendation recommendation;
  final List<VibeHardConflict> hardConflicts;
  final List<VibeSoftRisk> softRisks;
  final double softRiskPenalty01;
  final double baseScorePercent;
  final double finalScorePercent;
  final double myFitPercent; // score from MY perspective only
  final double theirFitPercent; // score from THEIR perspective only
  final VibeConfidence confidence;
  final String confidenceLabel;
  final double confidenceScore;
  final int defaultCount;
  final double defaultPercent;
}

class VibeMatcher {
  static const Map<VibeCategory, double> weights = {
    VibeCategory.pace: 28,
    VibeCategory.competitive: 22,
    VibeCategory.drinking: 18,
    VibeCategory.chat: 14,
    VibeCategory.money: 12,
    VibeCategory.music: 6,
  };

  /// Computes a one-sided fit score: how much will [viewer] enjoy playing
  /// with [other], using only [viewer]'s tolerances, importance, and weights.
  static double _computeOneSidedFit({
    required VibeProfile viewer,
    required VibeProfile other,
  }) {
    var weightedSum = 0.0;
    var weightTotal = 0.0;

    for (final category in VibeCategory.values) {
      final viewerPref = viewer.preferenceFor(category);
      final otherPref = other.preferenceFor(category);

      final viewerIsDefault = isDefault(
        category,
        viewerPref.value,
        isDefaultFlag: viewerPref.isDefault,
      );
      final otherIsDefault = isDefault(
        category,
        otherPref.value,
        isDefaultFlag: otherPref.isDefault,
      );

      final distance = (viewerPref.value - otherPref.value).abs();

      // One-sided: only use VIEWER's tolerance
      final matchScore01 = oneSidedCategoryScore(
        distance: distance,
        tolerance: viewerPref.threshold,
        gamma: VibeTuning.gamma,
        scaleMax: VibeTuning.scaleMax,
      );
      final matchPercent = (matchScore01 * 100.0)
          .clamp(VibeTuning.minScore, VibeTuning.maxScore);

      // Weight uses VIEWER's importance only (not blended)
      final viewerImportanceMult = importanceMultiplier(
        viewer.importanceFor(category),
      );
      final baseWeight = weights[category] ?? 0;
      final weight = baseWeight *
          getDefaultMultiplier(viewerIsDefault, otherIsDefault) *
          viewerImportanceMult;

      weightedSum += matchPercent * weight;
      weightTotal += weight;
    }

    if (weightTotal <= 0) return 0.0;
    return (weightedSum / weightTotal)
        .clamp(VibeTuning.minScore, VibeTuning.maxScore)
        .toDouble();
  }

  static VibeMatchResult score(
    VibeProfile mine,
    VibeProfile theirs, {
    bool enableInteractionLayer = false, // was true
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
      final normalizedWeight =
          weightTotal > 0 ? (rawWeight / weightTotal * 100).toDouble() : 0.0;
      perCategory[category] = VibeCategoryScore(
        categoryMatch: existing.categoryMatch,
        weight: normalizedWeight,
        distance: existing.distance,
      );
    }

    final baseScore =
        (weightTotal > 0 ? weightedSum / weightTotal : 0).toDouble();

    // ── Phase 1 change: interaction bonus is capped via VibeTuning ──
    // The interactionAdjustments function still computes bonuses, but
    // we enforce the new cap (0.04 vs old 0.12) here as a safety net.
    final adjustment = interactionAdjustments(
      scoresByCategory,
      mismatchedByCategory,
      enableInteractionLayer: enableInteractionLayer,
    );
    final cappedBonus = adjustment.bonusTotal.clamp(
      0.0,
      VibeTuning.interactionBonusCap,
    );

    final adjustedScore = clampDouble(
      (baseScore / 100) + cappedBonus,
      0,
      1,
    );
    final totalScore = (adjustedScore * 100).toDouble();

    // Decision layers: hard blocks mark not recommended, soft risks apply penalties.
    final hardBlockResult = evaluateHardBlocks(mine, theirs);
    final isRecommended = !hardBlockResult.isHardBlocked;
    final cappedScore = null;
    final topDifferences = _topDifferences(
      differences,
      perCategory,
      scoresByCategory,
    );
    final defaultPercent = defaultCount / VibeCategory.values.length;
    final completeness =
        (completenessSum / max(1, VibeCategory.values.length)).toDouble();
    final confidence = _confidenceFromCompleteness(completeness);

    // ── Soft-risk penalty computation ──
    // Always computed, even on hard-blocked matches, so the score
    // reflects the full severity of mismatches rather than relying
    // solely on the hard-block cap.
    final softRisks = <VibeSoftRisk>[];
    var softRiskPenalty01 = 0.0;
    {
      var weightedPenaltySum = 0.0;
      for (final category in VibeCategory.values) {
        final myPref = mine.preferenceFor(category);
        final theirPref = theirs.preferenceFor(category);
        final distance = (myPref.value - theirPref.value).abs().toDouble();
        final tolerance = combinedTolerance(
          myPref.threshold.toDouble(),
          theirPref.threshold.toDouble(),
        );
        final overBy = max(0.0, distance - tolerance).toDouble();
        if (overBy <= 0) {
          continue;
        }
        final normalized = (overBy / VibeTuning.riskScale).clamp(0, 1);
        final severity01 =
            pow(normalized, VibeTuning.riskCurveP).clamp(0, 1).toDouble();
        final riskMax = VibeTuning.riskMaxDefault;
        final weight = weightsByCategory[category] ?? 0;
        weightedPenaltySum += weight * severity01 * riskMax;
        softRisks.add(
          VibeSoftRisk(
            category: category,
            distance: distance,
            tolerance: tolerance,
            overBy: overBy,
            severity01: severity01,
            weight: weight,
            reason:
                '${VibeLabels.titleFor(category)} mismatch is ${overBy.toStringAsFixed(1)} past tolerance.',
          ),
        );
      }
      if (weightTotal > 0) {
        softRiskPenalty01 =
            (weightedPenaltySum / weightTotal).clamp(0, 1).toDouble();
      }
    }

    // Phase 2: additive penalty model
    final baseScorePercent = totalScore;
    final softPenaltyPoints =
        softRiskPenalty01 * VibeTuning.softPenaltyMaxPoints;

    // ── Compatibility floor ──
    // A single category scoring below 15% with meaningful weight
    // represents a non-compensatory mismatch — great pace can't make
    // up for a total drinking conflict. For each such category,
    // subtract a penalty proportional to its weight so the average
    // can't bury it.
    var floorPenalty = 0.0;
    if (weightTotal > 0) {
      for (final category in VibeCategory.values) {
        final catScore = scoresByCategory[category] ?? 1.0;
        final catWeight = weightsByCategory[category] ?? 0;
        if (catWeight <= 0) continue;

        // Skip default categories — no real signal to penalize
        final myPref = mine.preferenceFor(category);
        final theirPref = theirs.preferenceFor(category);
        final myIsDefault =
            isDefault(category, myPref.value, isDefaultFlag: myPref.isDefault);
        final theirIsDefault = isDefault(category, theirPref.value,
            isDefaultFlag: theirPref.isDefault);
        if (myIsDefault || theirIsDefault) continue;

        // If category match is below 15%, apply a floor penalty
        // scaled by the category's share of total weight.
        if (catScore < 0.15) {
          final weightShare = catWeight / weightTotal;
          floorPenalty += weightShare * 30.0;
        }
      }
    }

    final finalScorePercent =
        (baseScorePercent - softPenaltyPoints - floorPenalty)
            .clamp(VibeTuning.minScore, VibeTuning.maxScore)
            .toDouble();

    // ── Asymmetric per-user scoring ──
    // Compute how much each player will enjoy the other from their own perspective.
    final myFitRaw = _computeOneSidedFit(viewer: mine, other: theirs);
    final theirFitRaw = _computeOneSidedFit(viewer: theirs, other: mine);

    // Apply the same soft penalty and floor penalty to each one-sided score
    final myFitPercent = (myFitRaw - softPenaltyPoints - floorPenalty)
        .clamp(VibeTuning.minScore, VibeTuning.maxScore)
        .toDouble();
    final theirFitPercent = (theirFitRaw - softPenaltyPoints - floorPenalty)
        .clamp(VibeTuning.minScore, VibeTuning.maxScore)
        .toDouble();

    // Per-dealbreaker penalty: each dealbreaker subtracts 15 points.
    // 1 dealbreaker = -15, 2 = -30, 3 = -45. This differentiates
    // "one issue you might look past" from "fundamentally incompatible."
    final dealbreakerCount = hardBlockResult.conflicts.length;
    final dealbreakerPenalty =
        dealbreakerCount * VibeTuning.perDealbreakerPenalty;

    final myFitDisplay = hardBlockResult.isHardBlocked
        ? (myFitPercent - dealbreakerPenalty)
            .clamp(VibeTuning.minScore, VibeTuning.maxScore)
            .toDouble()
        : myFitPercent;
    final theirFitDisplay = hardBlockResult.isHardBlocked
        ? (theirFitPercent - dealbreakerPenalty)
            .clamp(VibeTuning.minScore, VibeTuning.maxScore)
            .toDouble()
        : theirFitPercent;

    final recommendation = hardBlockResult.isHardBlocked
        ? VibeRecommendation.notRecommended
        : softRiskPenalty01 >= VibeTuning.riskCautionThreshold
            ? VibeRecommendation.caution
            : VibeRecommendation.recommended;

    final displayScore = hardBlockResult.isHardBlocked
        ? (finalScorePercent - dealbreakerPenalty)
            .clamp(VibeTuning.minScore, VibeTuning.maxScore)
            .toDouble()
        : finalScorePercent;

    VibeAnalytics.logMatchScore(
      VibeAnalyticsPayload(
        score: finalScorePercent,
        isCapped: false,
        perCategoryScores: scoresByCategory,
        effectiveWeights: weightsByCategory,
      ),
    );

    return VibeMatchResult(
      totalScore: totalScore,
      cappedScore: cappedScore,
      isRecommended: isRecommended,
      interactionBonus: cappedBonus,
      interactionReasons: adjustment.reasons,
      interactionAppliedRules: adjustment.appliedRules,
      conflicts: conflicts,
      topDifferences: topDifferences,
      perCategory: perCategory,
      recommendation: recommendation,
      hardConflicts: hardBlockResult.conflicts,
      softRisks: softRisks,
      softRiskPenalty01: softRiskPenalty01,
      baseScorePercent: baseScorePercent,
      finalScorePercent: displayScore,
      myFitPercent: myFitDisplay,
      theirFitPercent: theirFitDisplay,
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
