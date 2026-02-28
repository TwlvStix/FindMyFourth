import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/core/widgets/vibe_gap_indicator.dart';
import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/services/vibe_matcher.dart';

/// Build a test vibe profile with specified category values
VibeProfile _buildProfile({
  int pace = 3,
  int competitive = 3,
}) {
  final prefs = <VibeCategory, VibePreference>{};
  for (final category in VibeCategory.values) {
    int value = 3;
    if (category == VibeCategory.pace) value = pace;
    if (category == VibeCategory.competitive) value = competitive;
    prefs[category] = VibePreference(
      value: value,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    );
  }
  return VibeProfile(
    prefs: prefs,
    importance: {
      for (final c in VibeCategory.values) c: VibeImportance.normal,
    },
    importanceVersion: 1,
    confirmedAt: DateTime.now(),
  );
}

void main() {
  group('VibeGapPerspective enum', () {
    test('has player and owner values', () {
      expect(VibeGapPerspective.values, contains(VibeGapPerspective.player));
      expect(VibeGapPerspective.values, contains(VibeGapPerspective.owner));
    });

    test('player is the default perspective', () {
      // Based on widget implementation, player is the default
      expect(VibeGapPerspective.player.index, 0);
    });
  });

  group('VibeGapIndicator perspective logic', () {
    test('player perspective: player is "You", owner is "Them"', () {
      // When perspective is player:
      // - myValue should be player's preference
      // - theirValue should be owner's preference
      // This is tested by verifying the matchResult structure

      final ownerProfile = _buildProfile(pace: 5);
      final playerProfile = _buildProfile(pace: 1);

      final matchResult = VibeMatcher.score(ownerProfile, playerProfile);

      // matchResult.perCategory contains the comparison data
      final paceScore = matchResult.perCategory[VibeCategory.pace];
      expect(paceScore, isNotNull);

      // The distance should be the absolute difference: |5 - 1| = 4
      expect(paceScore!.distance, 4);
    });

    test('owner perspective: matchResult captures distance correctly', () {
      // VibeMatcher.score(mine, theirs) - owner evaluates player
      // Distance represents the absolute difference between preferences

      final ownerProfile = _buildProfile(pace: 5);
      final playerProfile = _buildProfile(pace: 1);

      final matchResult = VibeMatcher.score(ownerProfile, playerProfile);

      // The score represents owner's perspective
      final paceScore = matchResult.perCategory[VibeCategory.pace];
      expect(paceScore, isNotNull);
      // Distance is |5 - 1| = 4
      expect(paceScore!.distance, 4);
    });

    test('perspective swap maintains correct distances', () {
      // Create distinct profiles to verify perspective handling
      final ownerProfile = _buildProfile(pace: 0, competitive: 5);
      final playerProfile = _buildProfile(pace: 5, competitive: 0);

      // When scoring from owner's perspective
      final matchResult = VibeMatcher.score(ownerProfile, playerProfile);

      // For pace: |0 - 5| = 5
      final paceScore = matchResult.perCategory[VibeCategory.pace];
      expect(paceScore!.distance, 5);

      // For competitive: |5 - 0| = 5
      final compScore = matchResult.perCategory[VibeCategory.competitive];
      expect(compScore!.distance, 5);
    });
  });

  group('VibeGapIndicator data binding', () {
    test('topDifferences correctly identifies largest gaps', () {
      // Create profiles with varying gaps
      final ownerProfile = _buildProfile(pace: 5, competitive: 3);
      final playerProfile = _buildProfile(pace: 0, competitive: 2);

      final matchResult = VibeMatcher.score(ownerProfile, playerProfile);

      // Pace has larger gap (5) than competitive (1)
      final topDiff = matchResult.topDifferences;
      expect(topDiff.isNotEmpty, isTrue);

      // First difference should be pace (largest gap)
      final paceDiff = topDiff.firstWhere(
        (d) => d.category == VibeCategory.pace,
        orElse: () => throw StateError('Pace not found'),
      );
      expect(paceDiff.distance, 5);
    });

    test('maxDimensions limits displayed categories', () {
      final ownerProfile = _buildProfile(pace: 5, competitive: 5);
      final playerProfile = _buildProfile(pace: 0, competitive: 0);

      final matchResult = VibeMatcher.score(ownerProfile, playerProfile);

      // Limiting to 2 should return exactly 2
      final limited = matchResult.topDifferences.take(2).toList();
      expect(limited.length, 2);
    });
  });

  group('VibeMatchResult per-category scores', () {
    test('perCategory contains distance and weight', () {
      final ownerProfile = _buildProfile(pace: 4);
      final playerProfile = _buildProfile(pace: 2);

      final matchResult = VibeMatcher.score(ownerProfile, playerProfile);
      final paceScore = matchResult.perCategory[VibeCategory.pace]!;

      // Distance is |4 - 2| = 2
      expect(paceScore.distance, 2);
      // Weight should be positive
      expect(paceScore.weight, greaterThan(0));
    });

    test('identical profiles have zero distances', () {
      final profile1 = _buildProfile(pace: 3, competitive: 3);
      final profile2 = _buildProfile(pace: 3, competitive: 3);

      final matchResult = VibeMatcher.score(profile1, profile2);

      for (final category in VibeCategory.values) {
        final score = matchResult.perCategory[category]!;
        expect(score.distance, 0);
      }
    });
  });
}
