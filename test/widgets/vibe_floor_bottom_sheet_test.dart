import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/core/content/app_copy.dart';
import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/services/vibe_matcher.dart';

/// Build a test vibe profile with specified category values
VibeProfile _buildProfile({
  int pace = 3,
  int competitive = 3,
  int drinking = 3,
  int chat = 3,
  int money = 3,
  int music = 3,
}) {
  final prefs = <VibeCategory, VibePreference>{
    VibeCategory.pace: VibePreference(
      value: pace,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
    VibeCategory.competitive: VibePreference(
      value: competitive,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
    VibeCategory.drinking: VibePreference(
      value: drinking,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
    VibeCategory.chat: VibePreference(
      value: chat,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
    VibeCategory.money: VibePreference(
      value: money,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
    VibeCategory.music: VibePreference(
      value: music,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
  };
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
  group('AppVibeFloorCopy', () {
    test('mismatch copy uses correct structure', () {
      expect(AppVibeFloorCopy.mismatchTitle, 'Approval needed');
      expect(
        AppVibeFloorCopy.mismatchBody('John'),
        contains('John'),
      );
      expect(
        AppVibeFloorCopy.mismatchBody('John'),
        contains('This round\'s play style differs'),
      );
    });

    test('confirmation copy uses correct structure', () {
      expect(AppVibeFloorCopy.requestSentTitle, 'Request sent');
      expect(
        AppVibeFloorCopy.requestSentBody('John'),
        contains('John'),
      );
      expect(
        AppVibeFloorCopy.requestSentBody('John'),
        contains('notified'),
      );
    });

    test('button labels are concise', () {
      expect(AppVibeFloorCopy.requestToJoinButton.split(' ').length, lessThanOrEqualTo(4));
      expect(AppVibeFloorCopy.notNowButton.split(' ').length, lessThanOrEqualTo(4));
      expect(AppVibeFloorCopy.doneButton.split(' ').length, lessThanOrEqualTo(4));
    });

    test('declined subtitle is clear', () {
      expect(
        AppVibeFloorCopy.requestDeclinedSubtitle,
        contains('play style'),
      );
    });
  });

  group('VibeGapIndicator', () {
    test('matchResult.topDifferences returns sorted categories', () {
      // Create profiles with different values to create gaps
      final ownerProfile = _buildProfile(
        pace: 5,        // Big gap
        competitive: 4, // Medium gap
        drinking: 3,    // No gap
        chat: 3,
        money: 3,
        music: 3,
      );
      final playerProfile = _buildProfile(
        pace: 0,        // Big gap from 5
        competitive: 1, // Medium gap from 4
        drinking: 3,    // No gap
        chat: 3,
        money: 3,
        music: 3,
      );

      final matchResult = VibeMatcher.score(ownerProfile, playerProfile);

      // topDifferences should exist and be sorted by impact
      expect(matchResult.topDifferences.isNotEmpty, isTrue);
      expect(matchResult.topDifferences.length, lessThanOrEqualTo(3));

      // First difference should have the highest impact
      if (matchResult.topDifferences.length >= 2) {
        final first = matchResult.topDifferences[0];
        final second = matchResult.topDifferences[1];
        // The first should have equal or higher distance (already sorted)
        expect(first.distance, greaterThanOrEqualTo(second.distance));
      }
    });

    test('matchResult includes pace when it has largest gap', () {
      final ownerProfile = _buildProfile(pace: 5);
      final playerProfile = _buildProfile(pace: 0);

      final matchResult = VibeMatcher.score(ownerProfile, playerProfile);

      // Pace should be in topDifferences due to the large gap
      final paceInTop = matchResult.topDifferences.any(
        (d) => d.category == VibeCategory.pace,
      );
      expect(paceInTop, isTrue);
    });

    test('dimensions shown are limited to maxDimensions', () {
      // This is a logic test - VibeGapIndicator takes maxDimensions parameter
      // and filters topDifferences.take(maxDimensions)
      final ownerProfile = _buildProfile(
        pace: 5,
        competitive: 5,
        drinking: 5,
      );
      final playerProfile = _buildProfile(
        pace: 0,
        competitive: 0,
        drinking: 0,
      );

      final matchResult = VibeMatcher.score(ownerProfile, playerProfile);

      // Taking 2 should give exactly 2
      final top2 = matchResult.topDifferences.take(2).toList();
      expect(top2.length, 2);

      // Taking 3 should give at most 3
      final top3 = matchResult.topDifferences.take(3).toList();
      expect(top3.length, lessThanOrEqualTo(3));
    });
  });

  group('VibeMatchResult for gap indicator', () {
    test('perCategory contains all 6 categories', () {
      final profile1 = _buildProfile();
      final profile2 = _buildProfile();

      final matchResult = VibeMatcher.score(profile1, profile2);

      expect(matchResult.perCategory.length, 6);
      for (final category in VibeCategory.values) {
        expect(matchResult.perCategory.containsKey(category), isTrue);
      }
    });

    test('perCategory includes distance for each category', () {
      final profile1 = _buildProfile(pace: 5);
      final profile2 = _buildProfile(pace: 0);

      final matchResult = VibeMatcher.score(profile1, profile2);

      final paceScore = matchResult.perCategory[VibeCategory.pace];
      expect(paceScore, isNotNull);
      expect(paceScore!.distance, 5); // |5 - 0| = 5
    });
  });
}
