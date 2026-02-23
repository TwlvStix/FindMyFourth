import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/services/vibe_matcher.dart';
import 'package:find_my_fourth/vibe/vibe_match_types.dart';
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
  group('categoryMatch', () {
    test('tolerance == scaleMax behaves like scaleMax - 1', () {
      final score = categoryMatch(0, 5, tolerance: 5, scaleMax: 5);
      expect(score, closeTo(0, 0.01));
    });

    test('distance within tolerance returns 100', () {
      final score = categoryMatch(1, 3, tolerance: 2, scaleMax: 5);
      expect(score, 100);
    });

    test('beyond tolerance drops using gamma curve', () {
      final score = categoryMatch(0, 4, tolerance: 2, gamma: 2.0, scaleMax: 5);
      expect(score, closeTo(55.56, 0.1));
    });

    test('max distance returns 0 when tolerance < scaleMax', () {
      final score = categoryMatch(0, 5, tolerance: 1, gamma: 2.0, scaleMax: 5);
      expect(score, closeTo(0, 0.01));
    });

    test('tolerance > scaleMax clamps to scaleMax - 1', () {
      final score = categoryMatch(2, 5, tolerance: 10, scaleMax: 5);
      expect(score, 100);
    });

    test('invalid gamma falls back to default', () {
      final invalidScore = categoryMatch(0, 4,
          tolerance: 2, gamma: 0, scaleMax: 5);
      final nanScore = categoryMatch(0, 4,
          tolerance: 2, gamma: double.nan, scaleMax: 5);
      final expected = categoryMatch(0, 4,
          tolerance: 2,
          gamma: VibeTuning.gamma,
          scaleMax: 5);
      expect(invalidScore, closeTo(expected, 0.01));
      expect(nanScore, closeTo(expected, 0.01));
    });

    test('tolerance 0 behaves like pure gamma curve', () {
      final score = categoryMatch(0, 3, tolerance: 0, gamma: 2.0, scaleMax: 5);
      expect(score, closeTo(64, 0.1));
    });

    test('output is clamped to 0..100', () {
      final score = categoryMatch(0, 999, tolerance: -5, gamma: 2.0, scaleMax: 5);
      expect(score, inInclusiveRange(0, 100));
    });

    test('fractional differences do not always round to 0 distance', () {
      final score = categoryMatch(3.0, 3.9, tolerance: 0, scaleMax: 5);
      expect(score, lessThan(100));
    });

    test('scaleMax 0 does not yield universal 100', () {
      final score = categoryMatch(0, 1, tolerance: 0, scaleMax: 0);
      expect(score, closeTo(0, 0.01));
    });
  });

  group('twoSidedCategoryScore', () {
    test('symmetry matches one-sided when tolerances are equal', () {
      final oneSided = oneSidedCategoryScore(
        distance: 3,
        tolerance: 2,
        gamma: 2.0,
        scaleMax: 5,
      );
      final twoSided = twoSidedCategoryScore(
        distance: 3,
        myTolerance: 2,
        theirTolerance: 2,
        gamma: 2.0,
        scaleMax: 5,
      );
      expect(twoSided, closeTo(oneSided, 0.0001));
    });

    test('asymmetry penalizes when tolerances differ', () {
      final score = twoSidedCategoryScore(
        distance: 3,
        myTolerance: 4,
        theirTolerance: 0,
        gamma: 2.0,
        scaleMax: 5,
      );
      expect(score, closeTo(0.712, 0.01));
      expect(score, lessThan(1.0));
    });

    test('tolerance == 5 still penalizes if other side is strict', () {
      final score = twoSidedCategoryScore(
        distance: 5,
        myTolerance: 5,
        theirTolerance: 0,
        gamma: 2.0,
        scaleMax: 5,
      );
      expect(score, closeTo(0, 0.01));
    });

    test('both tolerance == 5 does not guarantee full match', () {
      final score = twoSidedCategoryScore(
        distance: 5,
        myTolerance: 5,
        theirTolerance: 5,
        gamma: 2.0,
        scaleMax: 5,
      );
      expect(score, closeTo(0, 0.01));
    });

    test('score is non-increasing as distance grows', () {
      final nearScore = twoSidedCategoryScore(
        distance: 1,
        myTolerance: 1,
        theirTolerance: 1,
        gamma: 2.0,
        scaleMax: 5,
      );
      final farScore = twoSidedCategoryScore(
        distance: 3,
        myTolerance: 1,
        theirTolerance: 1,
        gamma: 2.0,
        scaleMax: 5,
      );
      expect(nearScore, greaterThanOrEqualTo(farScore));
    });

    test('tolerance == 5 does not divide by zero', () {
      final score = twoSidedCategoryScore(
        distance: 2,
        myTolerance: 5,
        theirTolerance: 5,
        gamma: 2.0,
        scaleMax: 5,
      );
      expect(score, 1.0);
    });
  });

  group('default helpers', () {
    test('default multiplier uses expected weights', () {
      expect(getDefaultMultiplier(false, false), VibeTuning.defaultMultNone);
      expect(getDefaultMultiplier(true, false), VibeTuning.defaultMultOne);
      expect(getDefaultMultiplier(false, true), VibeTuning.defaultMultOne);
      expect(getDefaultMultiplier(true, true), VibeTuning.defaultMultBoth);
    });

    test('default completeness uses expected contributions', () {
      expect(defaultCompleteness(false, false), VibeTuning.completenessNone);
      expect(defaultCompleteness(true, false), VibeTuning.completenessOne);
      expect(defaultCompleteness(false, true), VibeTuning.completenessOne);
      expect(defaultCompleteness(true, true), VibeTuning.completenessBoth);
    });
  });

  group('VibeMatcher', () {
    test('exact match yields 100', () {
      final myProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 4,
        },
      );
      final theirProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 4,
        },
      );

      final result = VibeMatcher.score(myProfile, theirProfile);

      expect(result.totalScore, closeTo(100, 0.01));
      expect(result.isRecommended, isTrue);
      expect(result.conflicts, isEmpty);
      expect(result.recommendation, VibeRecommendation.recommended);
      expect(result.hardConflicts, isEmpty);
      expect(result.softRisks, isEmpty);
      expect(result.softRiskPenalty01, 0);
      expect(result.baseScorePercent, closeTo(result.totalScore, 0.0001));
      expect(result.finalScorePercent, closeTo(result.totalScore, 0.0001));
    });

    test('max difference yields 0 for that category', () {
      final myProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 4,
          VibeCategory.chat: 0,
        },
      );
      final theirProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 4,
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
          for (final category in VibeCategory.values) category: 4,
          VibeCategory.pace: 0,
        },
      );
      final theirProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 4,
          VibeCategory.pace: 5,
        },
      );

      final result = VibeMatcher.score(myProfile, theirProfile);

      expect(result.totalScore, closeTo(72, 0.5));
    });

    test('default weighting normalizes by effective weight sum', () {
      final myProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 4,
          VibeCategory.money: 0,
        },
        defaultCategories: {
          VibeCategory.money,
        },
      );
      final theirProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 4,
          VibeCategory.money: 5,
        },
        defaultCategories: {
          VibeCategory.money,
        },
      );

      final result = VibeMatcher.score(myProfile, theirProfile);

      expect(result.totalScore, closeTo(100, 0.5));
    });

    test('dealbreaker conflict triggers hard block without capping score', () {
      final myProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 4,
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
          for (final category in VibeCategory.values) category: 4,
          VibeCategory.pace: 4,
        },
      );

      final result = VibeMatcher.score(myProfile, theirProfile);

      expect(result.isRecommended, isFalse);
      expect(result.recommendation, VibeRecommendation.notRecommended);
      expect(result.hardConflicts, isNotEmpty);
      expect(result.cappedScore, isNull);
      expect(result.totalScore, greaterThan(0));
    });

    test('soft risk reduces score when over tolerance', () {
      final myProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 4,
          VibeCategory.pace: 1,
        },
        thresholds: {
          VibeCategory.pace: 2,
        },
      );
      final theirProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 4,
          VibeCategory.pace: 4,
        },
        thresholds: {
          VibeCategory.pace: 2,
        },
      );

      final result = VibeMatcher.score(myProfile, theirProfile);

      expect(result.finalScorePercent, lessThan(result.baseScorePercent));
      // Verify soft risk penalty is applied correctly with new weights
      expect(result.softRiskPenalty01, greaterThan(0));
      expect(result.finalScorePercent, closeTo(84.3, 1.0));
    });

    test('larger overage yields larger penalty', () {
      final smallOver = VibeMatcher.score(
        _buildProfile(
          values: {
            for (final category in VibeCategory.values) category: 4,
            VibeCategory.pace: 1,
          },
          thresholds: {
            VibeCategory.pace: 2,
          },
        ),
        _buildProfile(
          values: {
            for (final category in VibeCategory.values) category: 4,
            VibeCategory.pace: 4,
          },
          thresholds: {
            VibeCategory.pace: 2,
          },
        ),
      );
      final largeOver = VibeMatcher.score(
        _buildProfile(
          values: {
            for (final category in VibeCategory.values) category: 4,
            VibeCategory.pace: 0,
          },
          thresholds: {
            VibeCategory.pace: 1,
          },
        ),
        _buildProfile(
          values: {
            for (final category in VibeCategory.values) category: 4,
            VibeCategory.pace: 5,
          },
          thresholds: {
            VibeCategory.pace: 1,
          },
        ),
      );

      // With new weights, both penalties are similar but large should still be >= small
      expect(
        largeOver.softRiskPenalty01,
        greaterThanOrEqualTo(smallOver.softRiskPenalty01),
      );
    });

    test('higher tolerance reduces penalty for same distance', () {
      final strict = VibeMatcher.score(
        _buildProfile(
          values: {
            for (final category in VibeCategory.values) category: 4,
            VibeCategory.pace: 1,
          },
          thresholds: {
            VibeCategory.pace: 1,
          },
        ),
        _buildProfile(
          values: {
            for (final category in VibeCategory.values) category: 4,
            VibeCategory.pace: 4,
          },
          thresholds: {
            VibeCategory.pace: 1,
          },
        ),
      );
      final lenient = VibeMatcher.score(
        _buildProfile(
          values: {
            for (final category in VibeCategory.values) category: 4,
            VibeCategory.pace: 1,
          },
          thresholds: {
            VibeCategory.pace: 3,
          },
        ),
        _buildProfile(
          values: {
            for (final category in VibeCategory.values) category: 4,
            VibeCategory.pace: 4,
          },
          thresholds: {
            VibeCategory.pace: 3,
          },
        ),
      );

      expect(
        lenient.softRiskPenalty01,
        lessThan(strict.softRiskPenalty01),
      );
    });

    test('importance weighting shifts match impact', () {
      final baseValues = {
        for (final category in VibeCategory.values) category: 4,
      };
      final myProfile = _buildProfile(
        values: {
          ...baseValues,
          VibeCategory.pace: 0,
        },
        importance: {
          for (final category in VibeCategory.values)
            category: VibeImportance.normal,
          VibeCategory.pace: VibeImportance.top,
        },
      );
      final theirProfile = _buildProfile(
        values: {
          ...baseValues,
          VibeCategory.pace: 5,
        },
        importance: {
          for (final category in VibeCategory.values)
            category: VibeImportance.normal,
        },
      );
      final lowImportanceProfile = _buildProfile(
        values: {
          ...baseValues,
          VibeCategory.pace: 0,
        },
        importance: {
          for (final category in VibeCategory.values)
            category: VibeImportance.normal,
          VibeCategory.pace: VibeImportance.bottom,
        },
      );

      final topResult = VibeMatcher.score(myProfile, theirProfile);
      final bottomResult =
          VibeMatcher.score(lowImportanceProfile, theirProfile);

      // With new weights: topResult ~66.4, bottomResult ~72.0
      expect(topResult.totalScore, lessThan(bottomResult.totalScore));
      expect(topResult.totalScore, closeTo(66.4, 1.0));
      expect(bottomResult.totalScore, closeTo(72.0, 1.0));
    });

    test('threshold prevents conflict when distance is below', () {
      final myProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 4,
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
          for (final category in VibeCategory.values) category: 4,
          VibeCategory.music: 4,
        },
      );

      final result = VibeMatcher.score(myProfile, theirProfile);

      expect(result.conflicts, isEmpty);
      expect(result.isRecommended, isTrue);
    });

    test('confidence classification uses weighted completeness', () {
      final myProfile = _buildProfile(
        defaultCategories: {
          VibeCategory.chat,
          VibeCategory.music,
          VibeCategory.pace,
        },
      );
      final theirProfile = _buildProfile(
        values: {
          for (final category in VibeCategory.values) category: 4,
        },
      );

      final result = VibeMatcher.score(myProfile, theirProfile);

      expect(result.confidence, VibeConfidence.high);
      expect(result.confidenceLabel, 'high');
      expect(result.confidenceScore, greaterThanOrEqualTo(0.8));

      final mediumProfile = _buildProfile(
        defaultCategories: {
          VibeCategory.chat,
          VibeCategory.music,
          VibeCategory.pace,
          VibeCategory.money,
        },
      );
      final mediumResult = VibeMatcher.score(
        mediumProfile,
        _buildProfile(
          values: {
            for (final category in VibeCategory.values) category: 4,
          },
        ),
      );

      expect(mediumResult.confidence, VibeConfidence.medium);
      expect(mediumResult.confidenceLabel, 'medium');
      expect(mediumResult.confidenceScore, inInclusiveRange(0.6, 0.79));

      final lowProfile = _buildProfile(
        defaultCategories: {
          VibeCategory.chat,
          VibeCategory.music,
          VibeCategory.pace,
          VibeCategory.money,
        },
      );
      final lowResult = VibeMatcher.score(
        lowProfile,
        _buildProfile(
          defaultCategories: {
            VibeCategory.chat,
            VibeCategory.music,
            VibeCategory.pace,
            VibeCategory.money,
          },
        ),
      );

      expect(lowResult.confidence, VibeConfidence.low);
      expect(lowResult.confidenceLabel, 'low');
      expect(lowResult.confidenceScore, lessThan(0.6));
    });
  });
}
