import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/services/vibe_interaction_adjustments.dart';
import 'package:find_my_fourth/services/vibe_matcher.dart';
import 'package:find_my_fourth/vibe/vibe_scoring.dart';
import 'package:find_my_fourth/vibe/vibe_tuning.dart';

VibeProfile _buildProfile({
  Map<VibeCategory, int>? values,
  Map<VibeCategory, bool>? dealbreakers,
  Map<VibeCategory, int>? thresholds,
  Set<VibeCategory>? defaultCategories,
  Map<VibeCategory, VibeImportance>? importance,
}) {
  final defaults = defaultCategories ?? <VibeCategory>{};
  final importanceMap = importance ??
      {
        for (final category in VibeCategory.values)
          category: VibeImportance.normal,
      };
  final prefs = <VibeCategory, VibePreference>{};

  for (final category in VibeCategory.values) {
    final isDefault = defaults.contains(category);
    final value = values != null && values.containsKey(category)
        ? values[category]!
        : isDefault
            ? VibePreference.defaultValue
            : 4;
    prefs[category] = VibePreference(
      value: value,
      dealbreaker: dealbreakers?[category] ?? false,
      threshold: thresholds?[category] ?? VibePreference.defaultThreshold,
      isDefault: isDefault,
    );
  }

  return VibeProfile(
    prefs: prefs,
    importance: importanceMap,
    importanceVersion: 1,
  );
}

void main() {
  group('Vibe scoring additional coverage', () {
    test('within tolerance => categoryMatch returns 100', () {
      final score = categoryMatch(2, 4, tolerance: 2, scaleMax: 5);
      expect(score, 100);
    });

    test('beyond tolerance => score decreases monotonically as distance grows', () {
      final score2 = categoryMatch(0, 2, tolerance: 0, scaleMax: 5);
      final score3 = categoryMatch(0, 3, tolerance: 0, scaleMax: 5);
      final score4 = categoryMatch(0, 4, tolerance: 0, scaleMax: 5);

      expect(score2, greaterThanOrEqualTo(score3));
      expect(score3, greaterThanOrEqualTo(score4));
    });

    test('asymmetric tolerance skews toward stricter side', () {
      const distance = 3;
      final sTight = oneSidedCategoryScore(
        distance: distance,
        tolerance: 0,
        gamma: 2.0,
        scaleMax: 5,
      );
      final sLoose = oneSidedCategoryScore(
        distance: distance,
        tolerance: 4,
        gamma: 2.0,
        scaleMax: 5,
      );
      final combined = twoSidedCategoryScore(
        distance: distance,
        myTolerance: 0,
        theirTolerance: 4,
        gamma: 2.0,
        scaleMax: 5,
      );

      final minScore = sTight < sLoose ? sTight : sLoose;
      final avgScore = (sTight + sLoose) / 2;
      expect(combined, inInclusiveRange(minScore, avgScore));
      expect(combined - minScore, lessThanOrEqualTo(avgScore - combined));
    });

    test('interaction bonus does not apply when supporting scores are below thresholds', () {
      final scores = {
        VibeCategory.pace: 0.84,
        VibeCategory.chat: 0.7,
        VibeCategory.competitive: 0.9,
        VibeCategory.money: 0.8,
        VibeCategory.drinking: 0.2,
        VibeCategory.music: 0.4,
        VibeCategory.weed: 0.4,
      };
      final mismatches = {
        for (final value in VibeCategory.values)
          value: value == VibeCategory.drinking,
      };

      final result = interactionAdjustments(scores, mismatches);

      expect(result.bonusTotal, 0);
      expect(result.appliedRules, isEmpty);
    });

    test('normalized perCategory weights sum to ~100', () {
      final mine = _buildProfile(
        values: {
          VibeCategory.pace: 1,
          VibeCategory.chat: 2,
          VibeCategory.money: 3,
        },
      );
      final theirs = _buildProfile(
        values: {
          VibeCategory.pace: 4,
          VibeCategory.chat: 5,
          VibeCategory.money: 0,
        },
      );

      final result = VibeMatcher.score(mine, theirs, enableInteractionLayer: false);
      final totalWeight = result.perCategory.values
          .map((entry) => entry.weight)
          .fold<double>(0, (sum, value) => sum + value);

      expect(totalWeight, closeTo(100, 0.01));
    });

    test('topDifferences prefers highest impact over largest distance', () {
      final mine = _buildProfile(
        values: {
          VibeCategory.pace: 0,
          VibeCategory.music: 0,
        },
        thresholds: {
          VibeCategory.pace: 0,
          VibeCategory.music: 0,
        },
        importance: {
          VibeCategory.pace: VibeImportance.top,
          VibeCategory.music: VibeImportance.bottom,
        },
      );
      final theirs = _buildProfile(
        values: {
          VibeCategory.pace: 3,
          VibeCategory.music: 5,
        },
        thresholds: {
          VibeCategory.pace: 0,
          VibeCategory.music: 0,
        },
        importance: {
          VibeCategory.pace: VibeImportance.normal,
          VibeCategory.music: VibeImportance.normal,
        },
      );

      final result = VibeMatcher.score(mine, theirs, enableInteractionLayer: false);
      final top = result.topDifferences.first;

      expect(top.category, VibeCategory.pace);
      final paceDistance = result.perCategory[VibeCategory.pace]!.distance;
      final musicDistance = result.perCategory[VibeCategory.music]!.distance;
      expect(paceDistance, lessThan(musicDistance));
    });

    test('dealbreaker cap triggers when distance >= threshold', () {
      final mine = _buildProfile(
        values: {
          VibeCategory.chat: 0,
        },
        dealbreakers: {
          VibeCategory.chat: true,
        },
        thresholds: {
          VibeCategory.chat: 2,
        },
      );
      final theirs = _buildProfile(
        values: {
          VibeCategory.chat: 5,
        },
        thresholds: {
          VibeCategory.chat: 2,
        },
      );

      final result = VibeMatcher.score(mine, theirs, enableInteractionLayer: false);

      expect(result.isRecommended, isFalse);
      expect(result.cappedScore, VibeTuning.dealbreakerCap);
    });
  });
}
