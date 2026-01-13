import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/services/vibe_matcher.dart';

VibeProfile _buildProfile({
  Map<VibeCategory, int>? values,
  Map<VibeCategory, bool>? dealbreakers,
  Map<VibeCategory, int>? thresholds,
  Set<VibeCategory>? defaultCategories,
}) {
  final defaults = defaultCategories ?? <VibeCategory>{};
  final prefs = <VibeCategory, VibePreference>{
    for (final category in VibeCategory.values) category: VibePreference.defaults(),
  };

  for (final category in VibeCategory.values) {
    var pref = prefs[category]!;
    final isDefault = defaults.contains(category);
    pref = pref.copyWith(isDefault: isDefault);

    if (values != null && values.containsKey(category)) {
      pref = pref.copyWith(value: values[category], isDefault: isDefault);
    }
    if (dealbreakers != null && dealbreakers.containsKey(category)) {
      pref = pref.copyWith(
        dealbreaker: dealbreakers[category],
        isDefault: isDefault,
      );
    }
    if (thresholds != null && thresholds.containsKey(category)) {
      pref = pref.copyWith(
        threshold: thresholds[category],
        isDefault: isDefault,
      );
    }
    prefs[category] = pref;
  }

  return VibeProfile(prefs: prefs);
}

void main() {
  group('VibeMatcher', () {
    test('exact match yields 100', () {
      final myProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 3,
        },
      );
      final theirProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 3,
        },
      );

      final result = VibeMatcher.score(myProfile, theirProfile);

      expect(result.totalScore, closeTo(100, 0.01));
      expect(result.isRecommended, isTrue);
      expect(result.conflicts, isEmpty);
    });

    test('max difference yields 0 for that category', () {
      final myProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 3,
          VibeCategory.chat: 0,
        },
      );
      final theirProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 3,
          VibeCategory.chat: 5,
        },
      );

      final result = VibeMatcher.score(myProfile, theirProfile);
      final chatScore = result.perCategory[VibeCategory.chat];

      expect(chatScore, isNotNull);
      expect(chatScore!.distance, 5);
      expect(chatScore.categoryMatch, closeTo(0, 0.01));
    });

    test('weighted math uses category weights', () {
      final myProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 3,
          VibeCategory.pace: 0,
        },
      );
      final theirProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 3,
          VibeCategory.pace: 5,
        },
      );

      final result = VibeMatcher.score(myProfile, theirProfile);

      expect(result.totalScore, closeTo(75, 0.01));
    });

    test('dealbreaker conflict caps score and flags not recommended', () {
      final myProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 3,
          VibeCategory.pace: 0,
        },
        dealbreakers: {
          VibeCategory.pace: true,
        },
        thresholds: {
          VibeCategory.pace: 2,
        },
      );
      final theirProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 3,
          VibeCategory.pace: 3,
        },
      );

      final result = VibeMatcher.score(myProfile, theirProfile);

      expect(result.isRecommended, isFalse);
      expect(result.cappedScore, isNotNull);
      expect(result.cappedScore!, closeTo(39, 0.01));
      expect(result.conflicts, isNotEmpty);
    });

    test('threshold prevents conflict when distance is below', () {
      final myProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 3,
          VibeCategory.music: 2,
        },
        dealbreakers: {
          VibeCategory.music: true,
        },
        thresholds: {
          VibeCategory.music: 3,
        },
      );
      final theirProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 3,
          VibeCategory.music: 4,
        },
      );

      final result = VibeMatcher.score(myProfile, theirProfile);

      expect(result.conflicts, isEmpty);
      expect(result.isRecommended, isTrue);
    });

    test('confidence classification uses defaults count', () {
      final myProfile = _buildProfile(
        defaultCategories: {
          VibeCategory.chat,
          VibeCategory.music,
          VibeCategory.pace,
        },
      );
      final theirProfile = _buildProfile();

      final result = VibeMatcher.score(myProfile, theirProfile);

      expect(result.confidence, VibeConfidence.low);
      expect(result.confidenceLabel, 'low confidence');

      final mediumProfile = _buildProfile(
        defaultCategories: {
          VibeCategory.chat,
          VibeCategory.music,
        },
      );
      final mediumResult = VibeMatcher.score(mediumProfile, _buildProfile());

      expect(mediumResult.confidence, VibeConfidence.medium);
      expect(mediumResult.confidenceLabel, 'medium confidence');
    });
  });
}
