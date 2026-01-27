import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/services/vibe_group_matcher.dart';

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
      expect(result.groupFitScore, closeTo(97.22, 0.01));
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
  });
}
