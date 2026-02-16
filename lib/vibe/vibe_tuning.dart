import '/models/vibe_profile.dart';

class VibeTuning {
  static const int minValue = VibePreference.minValue;
  static const int maxValue = VibePreference.maxValue;
  static const int scaleMax = maxValue;
  static const int defaultTolerance = VibePreference.defaultThreshold;

  static const double gamma = 1.2;
  static const double nearPerfect = 100.0;

  static const double minScore = 0.0;
  static const double maxScore = 100.0;

  static const double defaultMultNone = 1.0;
  static const double defaultMultOne = 0.15;
  static const double defaultMultBoth = 0.0;

  static const double completenessNone = 1.0;
  static const double completenessOne = 0.6;
  static const double completenessBoth = 0.3;

  static const double asymmetricMinWeight = 0.6;
  static const double asymmetricAvgWeight = 0.4;

  static const double confidenceHighThreshold = 0.8;
  static const double confidenceMediumThreshold = 0.6;
  static const double groupCohesionPenaltyFactor = 0.85;

  // ── Phase 1 tuning changes ──────────────────────────────────

  /// Was 2.0 → now 1.0
  /// Dealbreakers trigger a hard block much sooner.
  /// On a 0-5 scale, threshold + 1 is enough to block
  /// instead of needing a 3+ point gap.
  static const double hardMargin = 1.0;

  /// Was 1.75 → now 1.0
  /// Moderate tolerance overruns now produce meaningful
  /// penalties instead of being absorbed.
  static const double riskScale = 1.0;

  /// Was 2.0 → now 1.3
  /// Flattens the curve so mid-range mismatches aren't
  /// nearly zeroed out by the square. A 1-point overrun
  /// now contributes real penalty weight.
  static const double riskCurveP = 1.3;

  /// Was 0.45 → now 0.65
  /// Each category's max penalty contribution is higher,
  /// so a single bad mismatch can drag the score further.
  static const double riskMaxDefault = 0.65;

  /// Unchanged — 0.25 is a reasonable caution threshold
  /// given the more aggressive penalties above.
  static const double riskCautionThreshold = 0.25;

  // ── End Phase 1 tuning changes ──────────────────────────────
  /// Phase 2: max percentage points the soft-risk layer can subtract.
  /// Used in the additive penalty model:
  ///   finalScore = baseScore - (softPenalty * softPenaltyMaxPoints)
  static const double softPenaltyMaxPoints = 45.0;
  static const double importanceTopMultiplier = 1.30;
  static const double importanceBottomMultiplier = 0.80;
  static const double importanceNormalMultiplier = 1.0;

  /// Cap for interaction bonus adjustments.
  /// Was 0.12 (in vibe_interaction_adjustments.dart) → now 0.04.
  /// Kept here as a single source of truth so the interaction
  /// layer can reference VibeTuning.interactionBonusCap.
  static const double interactionBonusCap = 0.04;

  static const Map<VibeCategory, int> defaultValuesByCategory = {
    VibeCategory.drinking: VibePreference.defaultValue,
    VibeCategory.music: VibePreference.defaultValue,
    VibeCategory.pace: VibePreference.defaultValue,
    VibeCategory.money: VibePreference.defaultValue,
    VibeCategory.chat: VibePreference.defaultValue,
    VibeCategory.competitive: VibePreference.defaultValue,
  };

  // Conservative boundaries to avoid over-triggering dealbreakers.
  static const Map<VibeCategory, DealbreakerBounds> dealbreakerBounds = {
    VibeCategory.drinking: DealbreakerBounds(
      lowAnchor: 1,
      lowForbiddenMin: 3,
      highAnchor: 4,
      highForbiddenMax: 2,
    ),
    VibeCategory.music: DealbreakerBounds(
      lowAnchor: 1,
      lowForbiddenMin: 3,
      highAnchor: 4,
      highForbiddenMax: 2,
    ),
    VibeCategory.chat: DealbreakerBounds(
      lowAnchor: 1,
      lowForbiddenMin: 3,
      highAnchor: 4,
      highForbiddenMax: 2,
    ),
    VibeCategory.pace: DealbreakerBounds(
      lowAnchor: 1,
      lowForbiddenMin: 4,
      highAnchor: 4,
      highForbiddenMax: 1,
    ),
    VibeCategory.competitive: DealbreakerBounds(
      lowAnchor: 1,
      lowForbiddenMin: 4,
      highAnchor: 4,
      highForbiddenMax: 1,
    ),
    VibeCategory.money: DealbreakerBounds(
      lowAnchor: 1,
      lowForbiddenMin: 4,
      highAnchor: 4,
      highForbiddenMax: 1,
    ),
  };
}

class DealbreakerBounds {
  const DealbreakerBounds({
    required this.lowAnchor,
    required this.lowForbiddenMin,
    required this.highAnchor,
    required this.highForbiddenMax,
  });

  final int lowAnchor;
  final int lowForbiddenMin;
  final int highAnchor;
  final int highForbiddenMax;
}
