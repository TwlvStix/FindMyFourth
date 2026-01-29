import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/services/vibe_group_matcher.dart';
import 'package:find_my_fourth/services/vibe_matcher.dart';
import 'package:find_my_fourth/vibe/vibe_match_types.dart';

VibeProfile _profileWithValues(Map<VibeCategory, int> values) {
  final prefs = <VibeCategory, VibePreference>{
    for (final category in VibeCategory.values)
      category: VibePreference(
        value: 4,
        dealbreaker: false,
        threshold: VibePreference.defaultThreshold,
        isDefault: false,
      ),
  };
  values.forEach((category, value) {
    prefs[category] = prefs[category]!.copyWith(
      value: value,
      isDefault: false,
    );
  });
  return VibeProfile(prefs: prefs);
}

VibeProfile _profileWithOverrides({
  Map<VibeCategory, int>? values,
  Map<VibeCategory, bool>? dealbreakers,
  Map<VibeCategory, int>? thresholds,
}) {
  final prefs = <VibeCategory, VibePreference>{
    for (final category in VibeCategory.values)
      category: VibePreference(
        value: 4,
        dealbreaker: false,
        threshold: VibePreference.defaultThreshold,
        isDefault: false,
      ),
  };
  for (final category in VibeCategory.values) {
    if (values != null && values.containsKey(category)) {
      prefs[category] = prefs[category]!.copyWith(value: values[category]!);
    }
    if (dealbreakers != null && dealbreakers.containsKey(category)) {
      prefs[category] =
          prefs[category]!.copyWith(dealbreaker: dealbreakers[category]!);
    }
    if (thresholds != null && thresholds.containsKey(category)) {
      prefs[category] =
          prefs[category]!.copyWith(threshold: thresholds[category]!);
    }
  }
  return VibeProfile(prefs: prefs);
}

void main() {
  group('GroupVibeMatcher', () {
    test('computes group average and weighted fit', () {
      final mine = _profileWithValues({
        for (final category in VibeCategory.values) category: 4,
        VibeCategory.pace: 5,
      });
      final otherA = _profileWithValues({
        for (final category in VibeCategory.values) category: 4,
        VibeCategory.pace: 1,
      });
      final otherB = _profileWithValues({
        for (final category in VibeCategory.values) category: 4,
        VibeCategory.pace: 3,
      });

      final result = GroupVibeMatcher.scoreGroup(
        mine: mine,
        others: [
          GroupVibeMember(id: 'a', name: 'A', profile: otherA),
          GroupVibeMember(id: 'b', name: 'B', profile: otherB),
        ],
      );

      expect(result.groupAverages[VibeCategory.pace], closeTo(2.0, 0.01));
      final pairABase = VibeMatcher.score(mine, otherA).baseScorePercent;
      final pairBBase = VibeMatcher.score(mine, otherB).baseScorePercent;
      final pairCBase = VibeMatcher.score(otherA, otherB).baseScorePercent;
      final expectedBase = (pairABase + pairBBase + pairCBase) / 3;
      final pairAPenalty = VibeMatcher.score(mine, otherA).softRiskPenalty01;
      final pairBPenalty = VibeMatcher.score(mine, otherB).softRiskPenalty01;
      final pairCPenalty = VibeMatcher.score(otherA, otherB).softRiskPenalty01;
      final expectedPenalty = (pairAPenalty + pairBPenalty + pairCPenalty) / 3;
      final expectedFinal = expectedBase * (1 - expectedPenalty);
      expect(result.baseScorePercent, closeTo(expectedBase, 0.01));
      expect(result.finalScorePercent, closeTo(expectedFinal, 0.01));
      expect(result.groupFitScore, closeTo(result.finalScorePercent, 0.01));
    });

    test('lowest match uses the smallest 1:1 score', () {
      final mine = _profileWithValues({
        for (final category in VibeCategory.values) category: 4,
      });
      final lowMatch = _profileWithValues({
        for (final category in VibeCategory.values) category: 0,
      });
      final highMatch = _profileWithValues({
        for (final category in VibeCategory.values) category: 4,
      });

      final result = GroupVibeMatcher.scoreGroup(
        mine: mine,
        others: [
          GroupVibeMember(id: 'low', name: 'Low', profile: lowMatch),
          GroupVibeMember(id: 'high', name: 'High', profile: highMatch),
        ],
      );

      expect(result.lowestMatch, isNotNull);
      expect(result.lowestMatch!.member.id, 'low');
    });

    test('group not recommended when any pair hard blocks', () {
      final mine = _profileWithOverrides();
      final otherA = _profileWithOverrides(
        values: {VibeCategory.pace: 0},
        dealbreakers: {VibeCategory.pace: true},
        thresholds: {VibeCategory.pace: 1},
      );
      final otherB = _profileWithOverrides(
        values: {VibeCategory.pace: 5},
        thresholds: {VibeCategory.pace: 1},
      );
      final otherC = _profileWithOverrides();

      final result = GroupVibeMatcher.scoreGroup(
        mine: mine,
        others: [
          GroupVibeMember(id: 'a', name: 'A', profile: otherA),
          GroupVibeMember(id: 'b', name: 'B', profile: otherB),
          GroupVibeMember(id: 'c', name: 'C', profile: otherC),
        ],
      );

      expect(result.recommendation, VibeRecommendation.notRecommended);
      expect(result.conflicts, isNotEmpty);
      expect(result.finalScorePercent, greaterThanOrEqualTo(0));
    });

    test('higher tolerance reduces group soft risk penalty', () {
      final strict = GroupVibeMatcher.scoreGroup(
        mine: _profileWithOverrides(values: {VibeCategory.pace: 1}, thresholds: {VibeCategory.pace: 1}),
        others: [
          GroupVibeMember(
            id: 'a',
            name: 'A',
            profile:
                _profileWithOverrides(values: {VibeCategory.pace: 4}, thresholds: {VibeCategory.pace: 1}),
          ),
          GroupVibeMember(
            id: 'b',
            name: 'B',
            profile:
                _profileWithOverrides(values: {VibeCategory.pace: 4}, thresholds: {VibeCategory.pace: 1}),
          ),
        ],
      );
      final lenient = GroupVibeMatcher.scoreGroup(
        mine: _profileWithOverrides(values: {VibeCategory.pace: 1}, thresholds: {VibeCategory.pace: 3}),
        others: [
          GroupVibeMember(
            id: 'a',
            name: 'A',
            profile:
                _profileWithOverrides(values: {VibeCategory.pace: 4}, thresholds: {VibeCategory.pace: 3}),
          ),
          GroupVibeMember(
            id: 'b',
            name: 'B',
            profile:
                _profileWithOverrides(values: {VibeCategory.pace: 4}, thresholds: {VibeCategory.pace: 3}),
          ),
        ],
      );

      expect(lenient.softRiskPenalty01, lessThan(strict.softRiskPenalty01));
    });
  });
}
