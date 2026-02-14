import 'dart:math';

import '/models/vibe_profile.dart';
import '/vibe/vibe_dealbreaker.dart';
import '/vibe/vibe_tuning.dart';

class VibePref {
  const VibePref({
    required this.value,
    required this.tolerance,
    this.weight = 1.0,
    this.dealbreaker = false,
    this.isDefault = false,
  });

  final int value;
  final int tolerance;
  final double weight;
  final bool dealbreaker;
  final bool isDefault;
}

class VibeWeightedScore {
  const VibeWeightedScore({
    required this.scorePercent,
    required this.weight,
    required this.dealbreakerTriggered,
  });

  final double scorePercent;
  final double weight;
  final bool dealbreakerTriggered;
}

class VibeAggregateScore {
  const VibeAggregateScore({
    required this.totalScore,
    required this.cappedScore,
    required this.isCapped,
  });

  /// Legacy fields preserved for backward compatibility; dealbreaker caps are removed.
  final double totalScore;
  final double? cappedScore;
  final bool isCapped;
}

class VibeAnalyticsPayload {
  const VibeAnalyticsPayload({
    required this.score,
    required this.isCapped,
    required this.perCategoryScores,
    required this.effectiveWeights,
  });

  final double score;
  final bool isCapped;
  final Map<VibeCategory, double> perCategoryScores;
  final Map<VibeCategory, double> effectiveWeights;
}

class VibeAnalytics {
  static void logMatchScore(VibeAnalyticsPayload payload) {
    // Intentionally no-op: hook for analytics integration.
  }
}

/// Computes a one-sided category score: how well does the distance
/// fit within one player's tolerance?
///
/// Returns 1.0 if within tolerance, decays via gamma curve beyond it.
double oneSidedCategoryScore({
  required int distance,
  required int tolerance,
  double gamma = VibeTuning.gamma,
  int scaleMax = VibeTuning.scaleMax,
}) {
  if (scaleMax <= 0) {
    return 1;
  }

  final clampedDistance = distance.clamp(0, scaleMax);
  final tolMax = max(0, scaleMax - 1);
  final clampedTolerance = tolerance.clamp(0, tolMax);

  if (clampedDistance <= clampedTolerance) {
    return 1;
  }

  var safeGamma = gamma;
  if (safeGamma.isNaN || safeGamma.isInfinite || safeGamma <= 0) {
    safeGamma = VibeTuning.gamma;
  }

  final remaining = scaleMax - clampedTolerance;
  if (remaining <= 0) {
    return 1;
  }

  final over = clampedDistance - clampedTolerance;
  final x = (over / remaining).clamp(0, 1).toDouble();
  final score = 1 - pow(x, safeGamma);
  return score.clamp(0, 1).toDouble();
}

/// Two-sided category score: blends both players' one-sided scores,
/// weighting the stricter (lower) side more heavily.
double twoSidedCategoryScore({
  required int distance,
  required int myTolerance,
  required int theirTolerance,
  double gamma = VibeTuning.gamma,
  int scaleMax = VibeTuning.scaleMax,
}) {
  final sMe = oneSidedCategoryScore(
    distance: distance,
    tolerance: myTolerance,
    gamma: gamma,
    scaleMax: scaleMax,
  );
  final sThem = oneSidedCategoryScore(
    distance: distance,
    tolerance: theirTolerance,
    gamma: gamma,
    scaleMax: scaleMax,
  );
  final stricter = min(sMe, sThem);
  final avg = (sMe + sThem) / 2;
  var minW = VibeTuning.asymmetricMinWeight.clamp(0, 1).toDouble();
  var avgW = VibeTuning.asymmetricAvgWeight.clamp(0, 1).toDouble();
  final weightSum = minW + avgW;
  if ((weightSum - 1).abs() > 1e-6) {
    if (weightSum <= 0) {
      minW = VibeTuning.asymmetricMinWeight;
      avgW = VibeTuning.asymmetricAvgWeight;
    } else {
      minW /= weightSum;
      avgW /= weightSum;
    }
  }
  final combined = (minW * stricter) + (avgW * avg);
  return combined.clamp(0, 1).toDouble();
}

double categoryMatch(
  num a,
  num b, {
  int? tolerance,
  int? myTolerance,
  int? theirTolerance,
  double? gamma,
  int? scaleMax,
}) {
  final safeScaleMax = max(1, scaleMax ?? VibeTuning.scaleMax);
  final fallbackTolerance = tolerance ?? VibeTuning.defaultTolerance;
  final clampedA = a.clamp(0, safeScaleMax).toDouble();
  final clampedB = b.clamp(0, safeScaleMax).toDouble();
  final distance = (clampedA - clampedB).abs().clamp(0, safeScaleMax).round();
  final score = twoSidedCategoryScore(
    distance: distance,
    myTolerance: myTolerance ?? fallbackTolerance,
    theirTolerance: theirTolerance ?? fallbackTolerance,
    gamma: gamma ?? VibeTuning.gamma,
    scaleMax: safeScaleMax,
  );
  return (score * VibeTuning.maxScore)
      .clamp(VibeTuning.minScore, VibeTuning.maxScore)
      .toDouble();
}

double categoryScoreOneWay(VibePref a, VibePref b) {
  final distance = (a.value - b.value).abs();
  return oneSidedCategoryScore(
    distance: distance,
    tolerance: a.tolerance,
    gamma: VibeTuning.gamma,
    scaleMax: VibeTuning.scaleMax,
  );
}

double categoryScoreSymmetric(VibePref a, VibePref b) {
  final distance = (a.value - b.value).abs();
  return twoSidedCategoryScore(
    distance: distance,
    myTolerance: a.tolerance,
    theirTolerance: b.tolerance,
    gamma: VibeTuning.gamma,
    scaleMax: VibeTuning.scaleMax,
  );
}

double categoryEffectiveWeight(VibePref a, VibePref b) {
  final baseWeight = (a.weight + b.weight) / 2;
  return baseWeight * getDefaultMultiplier(a.isDefault, b.isDefault);
}

double combinedTolerance(double aTol, double bTol) {
  final minTol = min(aTol, bTol);
  final avgTol = (aTol + bTol) / 2;
  var minW = VibeTuning.asymmetricMinWeight.clamp(0, 1).toDouble();
  var avgW = VibeTuning.asymmetricAvgWeight.clamp(0, 1).toDouble();
  final weightSum = minW + avgW;
  if ((weightSum - 1).abs() > 1e-6) {
    if (weightSum <= 0) {
      minW = VibeTuning.asymmetricMinWeight;
      avgW = VibeTuning.asymmetricAvgWeight;
    } else {
      minW /= weightSum;
      avgW /= weightSum;
    }
  }
  return (minW * minTol) + (avgW * avgTol);
}

bool dealbreakerTriggered(
  VibeCategory category,
  VibePref a,
  VibePref b,
) {
  return dealbreakerTriggeredForCategory(
    category: category,
    aValue: a.value,
    aDealbreaker: a.dealbreaker,
    aIsDefault: a.isDefault,
    bValue: b.value,
    bDealbreaker: b.dealbreaker,
    bIsDefault: b.isDefault,
  );
}

VibeAggregateScore aggregateVibeScore(
  Iterable<VibeWeightedScore> categories,
) {
  var weightedSum = 0.0;
  var weightTotal = 0.0;

  for (final entry in categories) {
    weightedSum += entry.scorePercent * entry.weight;
    weightTotal += entry.weight;
  }

  final baseScore =
      (weightTotal > 0 ? weightedSum / weightTotal : 0).toDouble();
  final totalScore =
      baseScore.clamp(VibeTuning.minScore, VibeTuning.maxScore).toDouble();

  return VibeAggregateScore(
    totalScore: totalScore,
    cappedScore: null,
    isCapped: false,
  );
}

bool isDefault(
  VibeCategory category,
  int selectedValue, {
  bool? isDefaultFlag,
}) {
  if (isDefaultFlag != null) {
    return isDefaultFlag;
  }
  final defaultValue = VibeTuning.defaultValuesByCategory[category] ??
      VibePreference.defaultValue;
  return selectedValue == defaultValue;
}

double getDefaultMultiplier(bool aIsDefault, bool bIsDefault) {
  if (aIsDefault && bIsDefault) {
    return VibeTuning.defaultMultBoth;
  }
  if (aIsDefault || bIsDefault) {
    return VibeTuning.defaultMultOne;
  }
  return VibeTuning.defaultMultNone;
}

double defaultCompleteness(bool aIsDefault, bool bIsDefault) {
  if (aIsDefault && bIsDefault) {
    return VibeTuning.completenessBoth;
  }
  if (aIsDefault || bIsDefault) {
    return VibeTuning.completenessOne;
  }
  return VibeTuning.completenessNone;
}

double importanceMultiplier(VibeImportance importance) {
  switch (importance) {
    case VibeImportance.top:
      return VibeTuning.importanceTopMultiplier;
    case VibeImportance.bottom:
      return VibeTuning.importanceBottomMultiplier;
    case VibeImportance.normal:
      return VibeTuning.importanceNormalMultiplier;
  }
}

/// Phase 1 change: importance blending now uses max() instead of average.
///
/// Old behavior: avg(1.30, 0.80) = 1.05 — a "top" and "bottom" nearly
/// cancel out, which masks that one player cares deeply.
///
/// New behavior: max(1.30, 0.80) = 1.30 — if EITHER player considers
/// this category important, it gets the full importance boost. This means
/// mismatches on categories anyone cares about are weighted more heavily.
double blendedImportanceMultiplier(
  VibeImportance mine,
  VibeImportance theirs,
) {
  final myMult = importanceMultiplier(mine);
  final theirMult = importanceMultiplier(theirs);
  return max(myMult, theirMult).toDouble();
}
