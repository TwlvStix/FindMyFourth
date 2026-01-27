import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/services/vibe_interaction_adjustments.dart';

void main() {
  Map<VibeCategory, double> baseScores() {
    return {
      VibeCategory.pace: 0.9,
      VibeCategory.chat: 0.8,
      VibeCategory.competitive: 0.9,
      VibeCategory.money: 0.8,
      VibeCategory.drinking: 0.4,
      VibeCategory.music: 0.4,
      VibeCategory.weed: 0.4,
    };
  }

  Map<VibeCategory, bool> mismatchFor(VibeCategory category) {
    return {
      for (final value in VibeCategory.values) value: value == category,
    };
  }

  test('rule 1 applies for drinking mismatch with strong pace+chat', () {
    final result = interactionAdjustments(
      baseScores(),
      mismatchFor(VibeCategory.drinking),
    );

    expect(result.bonusTotal, closeTo(0.05, 0.0001));
    expect(result.appliedRules.single.ruleId, 'drinking_pace_chat');
  });

  test('rule 2 applies for music mismatch with focused or quiet play', () {
    final scores = {
      ...baseScores(),
      VibeCategory.competitive: 0.82,
      VibeCategory.chat: 0.5,
    };
    final result = interactionAdjustments(
      scores,
      mismatchFor(VibeCategory.music),
    );

    expect(result.bonusTotal, closeTo(0.04, 0.0001));
    expect(result.appliedRules.single.ruleId, 'music_competitive_or_quiet');
  });

  test('rule 3 applies for weed mismatch with strong pace+money', () {
    final result = interactionAdjustments(
      baseScores(),
      mismatchFor(VibeCategory.weed),
    );

    expect(result.bonusTotal, closeTo(0.05, 0.0001));
    expect(result.appliedRules.single.ruleId, 'weed_pace_money');
  });

  test('rule 4 applies for chat mismatch with casual competitive score', () {
    final scores = {
      ...baseScores(),
      VibeCategory.competitive: 0.4,
      VibeCategory.chat: 0.2,
    };
    final result = interactionAdjustments(
      scores,
      mismatchFor(VibeCategory.chat),
    );

    expect(result.bonusTotal, closeTo(0.04, 0.0001));
    expect(result.appliedRules.single.ruleId, 'chat_casual_competitive');
  });

  test('rule 5 applies for competitive mismatch with pace+money alignment', () {
    final scores = {
      ...baseScores(),
      VibeCategory.competitive: 0.2,
      VibeCategory.money: 0.7,
      VibeCategory.pace: 0.72,
    };
    final result = interactionAdjustments(
      scores,
      mismatchFor(VibeCategory.competitive),
    );

    expect(result.bonusTotal, closeTo(0.04, 0.0001));
    expect(result.appliedRules.single.ruleId, 'competitive_pace_money');
  });

  test('does not apply when mismatch flag is false', () {
    final result = interactionAdjustments(
      baseScores(),
      {for (final value in VibeCategory.values) value: false},
    );

    expect(result.bonusTotal, 0);
    expect(result.appliedRules, isEmpty);
  });

  test('bonus total is capped at 0.12', () {
    final scores = {
      VibeCategory.pace: 0.9,
      VibeCategory.chat: 0.2,
      VibeCategory.competitive: 0.9,
      VibeCategory.money: 0.9,
      VibeCategory.drinking: 0.1,
      VibeCategory.music: 0.1,
      VibeCategory.weed: 0.1,
    };
    final mismatches = {
      for (final value in VibeCategory.values) value: true,
    };

    final result = interactionAdjustments(scores, mismatches);

    expect(result.bonusTotal, closeTo(0.12, 0.0001));
    expect(result.appliedRules.length, 3);
  });

  test('clamp helper keeps values within bounds', () {
    expect(clampDouble(-1, 0, 1), 0);
    expect(clampDouble(2, 0, 1), 1);
  });
}
