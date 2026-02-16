import '/models/vibe_profile.dart';
import '/vibe/vibe_tuning.dart';

@Deprecated('Use VibeTuning instead.')
class VibeScoreConfig {
  static const int scaleMax = VibeTuning.scaleMax;
  static const int defaultTolerance = VibeTuning.defaultTolerance;
  static const double defaultGamma = VibeTuning.gamma;
  static const double importanceTopMultiplier = VibeTuning.importanceTopMultiplier;
  static const double importanceBottomMultiplier =
      VibeTuning.importanceBottomMultiplier;
  static const double importanceNormalMultiplier =
      VibeTuning.importanceNormalMultiplier;
  static const Map<VibeCategory, int> defaultValuesByCategory = {
    VibeCategory.drinking: VibePreference.defaultValue,
    VibeCategory.music: VibePreference.defaultValue,
    VibeCategory.pace: VibePreference.defaultValue,
    VibeCategory.money: VibePreference.defaultValue,
    VibeCategory.chat: VibePreference.defaultValue,
    VibeCategory.competitive: VibePreference.defaultValue,
  };
}
