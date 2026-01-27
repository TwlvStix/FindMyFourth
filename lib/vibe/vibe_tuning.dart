import '/models/vibe_profile.dart';

class VibeTuning {
  static const int minValue = VibePreference.minValue;
  static const int maxValue = VibePreference.maxValue;
  static const int scaleMax = maxValue;
  static const int defaultTolerance = VibePreference.defaultThreshold;

  static const double gamma = 2.0;
  static const double nearPerfect = 100.0;

  static const double minScore = 0.0;
  static const double maxScore = 100.0;

  static const double defaultMultNone = 1.0;
  static const double defaultMultOne = 0.7;
  static const double defaultMultBoth = 0.5;

  static const double completenessNone = 1.0;
  static const double completenessOne = 0.6;
  static const double completenessBoth = 0.3;

  static const double asymmetricMinWeight = 0.6;
  static const double asymmetricAvgWeight = 0.4;

  static const double confidenceHighThreshold = 0.8;
  static const double confidenceMediumThreshold = 0.6;

  static const double dealbreakerCap = 39.0;

  static const double importanceTopMultiplier = 1.30;
  static const double importanceBottomMultiplier = 0.80;
  static const double importanceNormalMultiplier = 1.0;

  static const Map<VibeCategory, int> defaultValuesByCategory = {
    VibeCategory.drinking: VibePreference.defaultValue,
    VibeCategory.music: VibePreference.defaultValue,
    VibeCategory.pace: VibePreference.defaultValue,
    VibeCategory.money: VibePreference.defaultValue,
    VibeCategory.weed: VibePreference.defaultValue,
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
    VibeCategory.weed: DealbreakerBounds(
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
