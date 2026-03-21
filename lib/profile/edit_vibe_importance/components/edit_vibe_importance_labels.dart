import '/models/vibe_profile.dart';

/// Feature-specific display labels for the Edit Vibe Importance screen.
///
/// Distinct from [VibeLabels] which holds full-sentence slider descriptions.
class EditVibeImportanceLabels {
  EditVibeImportanceLabels._();

  static const Map<VibeCategory, String> categoryTitles = {
    VibeCategory.pace: 'Pace of play',
    VibeCategory.competitive: 'Competition vibe',
    VibeCategory.chat: 'Chat level',
    VibeCategory.music: 'Music',
    VibeCategory.drinking: 'Drinking',
    VibeCategory.money: 'Money / stakes',
  };

  static const Map<VibeCategory, Map<int, String>> _shortValueLabels = {
    VibeCategory.pace: {
      0: 'Very relaxed',
      1: 'Easygoing',
      2: 'Reasonable',
      3: 'Steady',
      4: 'Fast',
      5: 'Very fast',
    },
    VibeCategory.competitive: {
      0: 'Very casual',
      1: 'Light',
      2: 'Friendly',
      3: 'Structured',
      4: 'Highly competitive',
      5: 'Tournament intensity',
    },
    VibeCategory.drinking: {
      0: 'None',
      1: 'Very limited',
      2: 'Occasional',
      3: 'A couple is fine',
      4: 'Regular',
      5: 'Love it',
    },
    VibeCategory.chat: {
      0: 'Very quiet',
      1: 'Mostly quiet',
      2: 'Light chat',
      3: 'Balanced',
      4: 'Very social',
      5: 'Constant',
    },
    VibeCategory.money: {
      0: 'None',
      1: 'Very low stakes',
      2: 'Occasional',
      3: 'Casual games',
      4: 'Regular action',
      5: 'Love gambling',
    },
    VibeCategory.music: {
      0: 'Silence',
      1: 'Rare, low volume',
      2: 'Occasional',
      3: 'Usually fine',
      4: 'Most of the round',
      5: 'Always on',
    },
  };

  static String shortValueLabel(VibeCategory category, int value) =>
      _shortValueLabels[category]?[value] ?? 'Set';
}
