import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/services/vibe_matcher.dart';
import 'package:find_my_fourth/services/vibe_match_explanation.dart';

VibeProfile _buildProfile({
  Map<VibeCategory, int>? values,
  Map<VibeCategory, int>? thresholds,
  Map<VibeCategory, bool>? dealbreakers,
  Set<VibeCategory>? defaultCategories,
  Map<VibeCategory, VibeImportance>? importance,
}) {
  final prefs = <VibeCategory, VibePreference>{};
  for (final category in VibeCategory.values) {
    final isDefault = defaultCategories?.contains(category) ?? false;
    prefs[category] = VibePreference(
      value: values?[category] ?? (isDefault ? 3 : 4),
      dealbreaker: dealbreakers?[category] ?? false,
      threshold: thresholds?[category] ?? VibePreference.defaultThreshold,
      isDefault: isDefault,
    );
  }
  final importanceMap = importance ??
      {
        for (final category in VibeCategory.values)
          category: VibeImportance.normal,
      };
  return VibeProfile(
    prefs: prefs,
    importance: importanceMap,
    importanceVersion: 1,
  );
}

void main() {
  test('top differences prioritize strictness and weight over raw distance', () {
    final mine = _buildProfile(
      values: {
        for (final c in VibeCategory.values) c: 3,
        VibeCategory.pace: 0,
        VibeCategory.music: 2,
      },
      thresholds: {
        VibeCategory.pace: 1,
        VibeCategory.music: 0,
      },
      dealbreakers: {
        VibeCategory.pace: true,
      },
      importance: {
        for (final category in VibeCategory.values)
          category: VibeImportance.normal,
        VibeCategory.pace: VibeImportance.top,
        VibeCategory.music: VibeImportance.bottom,
      },
    );
    final theirs = _buildProfile(
      values: {
        for (final c in VibeCategory.values) c: 3,
        VibeCategory.pace: 4,
        VibeCategory.music: 5,
      },
      thresholds: {
        VibeCategory.pace: 1,
        VibeCategory.music: 0,
      },
      importance: {
        for (final category in VibeCategory.values)
          category: VibeImportance.normal,
        VibeCategory.pace: VibeImportance.top,
        VibeCategory.music: VibeImportance.bottom,
      },
    );

    final match = VibeMatcher.score(mine, theirs);
    final explanation = buildMatchExplanation(
      matchResult: match,
      a: mine,
      b: theirs,
    );

    expect(explanation.topDifferencesThatMatter, isNotEmpty);
    expect(
      explanation.topDifferencesThatMatter.first.categoryKey,
      VibeCategory.pace,
    );
  });

  test('defaults dampen impact in top differences ranking', () {
    final mine = _buildProfile(
      values: {
        for (final c in VibeCategory.values) c: 3,
        VibeCategory.pace: 1,
        VibeCategory.money: 0,
      },
      thresholds: {
        VibeCategory.pace: 1,
        VibeCategory.money: 1,
      },
      defaultCategories: {
        VibeCategory.pace,
      },
    );
    final theirs = _buildProfile(
      values: {
        for (final c in VibeCategory.values) c: 3,
        VibeCategory.pace: 3,
        VibeCategory.money: 5,
      },
      thresholds: {
        VibeCategory.pace: 1,
        VibeCategory.money: 1,
      },
      defaultCategories: {
        VibeCategory.pace,
      },
    );

    final match = VibeMatcher.score(mine, theirs);
    final explanation = buildMatchExplanation(
      matchResult: match,
      a: mine,
      b: theirs,
    );

    expect(explanation.topDifferencesThatMatter, isNotEmpty);
    expect(
      explanation.topDifferencesThatMatter.first.categoryKey,
      VibeCategory.money,
    );
  });

  test('confidence low when defaults are heavy', () {
    final defaults = {
      VibeCategory.chat,
      VibeCategory.music,
      VibeCategory.pace,
      VibeCategory.money,
    };
    final mine = _buildProfile(defaultCategories: defaults);
    final theirs = _buildProfile(defaultCategories: defaults);

    final match = VibeMatcher.score(mine, theirs);
    final explanation = buildMatchExplanation(
      matchResult: match,
      a: mine,
      b: theirs,
    );

    expect(explanation.confidenceLevel, VibeConfidence.low);
  });

  test('what helped selects high-weight aligned categories', () {
    final mine = _buildProfile(
      values: {
        for (final c in VibeCategory.values) c: 4,
        VibeCategory.pace: 2,
      },
    );
    final theirs = _buildProfile(
      values: {
        for (final c in VibeCategory.values) c: 4,
        VibeCategory.pace: 2,
      },
    );

    final match = VibeMatcher.score(mine, theirs);
    final explanation = buildMatchExplanation(
      matchResult: match,
      a: mine,
      b: theirs,
    );

    expect(
      explanation.whatHelpedThisMatch
          .any((item) => item.categoryKey == VibeCategory.pace),
      isTrue,
    );
  });

  test('why this match works hides on low confidence', () {
    final defaults = {
      VibeCategory.chat,
      VibeCategory.music,
      VibeCategory.pace,
      VibeCategory.money,
    };
    final mine = _buildProfile(defaultCategories: defaults);
    final theirs = _buildProfile(defaultCategories: defaults);

    final match = VibeMatcher.score(mine, theirs);
    final explanation = buildMatchExplanation(
      matchResult: match,
      a: mine,
      b: theirs,
    );

    expect(explanation.confidenceLevel, VibeConfidence.low);
    expect(explanation.whyThisMatchWorks, isEmpty);
  });

  test('interaction reasons are labeled based on activity', () {
    final mine = _buildProfile(
      values: {
        for (final c in VibeCategory.values) c: 4,
        VibeCategory.drinking: 0,
      },
    );
    final theirs = _buildProfile(
      values: {
        for (final c in VibeCategory.values) c: 4,
        VibeCategory.drinking: 5,
      },
    );

    // Enable interaction layer to get activity-based reasons
    final match = VibeMatcher.score(mine, theirs, enableInteractionLayer: true);
    final explanation = buildMatchExplanation(
      matchResult: match,
      a: mine,
      b: theirs,
    );

    expect(explanation.whyThisMatchWorks, isNotEmpty);
    expect(explanation.whyThisMatchWorks.first.isActivityBased, isTrue);
    expect(
      explanation.whyThisMatchWorks.first.description.contains('activity'),
      isFalse,
    );
  });
}
