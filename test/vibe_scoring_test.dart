import 'package:test/test.dart';

import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/vibe/vibe_scoring.dart';
import 'package:find_my_fourth/vibe/vibe_tuning.dart';

void main() {
  test('same values score near perfect', () {
    final a = VibePref(value: 3, tolerance: 2, weight: 10);
    final b = VibePref(value: 3, tolerance: 2, weight: 10);

    final score = categoryScoreSymmetric(a, b) * 100;

    expect(score, closeTo(VibeTuning.nearPerfect, 0.01));
  });

  test('within tolerance scores near perfect', () {
    final a = VibePref(value: 1, tolerance: 2, weight: 10);
    final b = VibePref(value: 3, tolerance: 2, weight: 10);

    final score = categoryScoreSymmetric(a, b) * 100;

    expect(score, closeTo(VibeTuning.nearPerfect, 0.01));
  });

  test('one tolerant one strict yields asymmetric one-way scores', () {
    final tolerant = VibePref(value: 4, tolerance: 4, weight: 10);
    final strict = VibePref(value: 0, tolerance: 0, weight: 10);

    final oneWayTolerant = categoryScoreOneWay(tolerant, strict);
    final oneWayStrict = categoryScoreOneWay(strict, tolerant);
    final symmetric = categoryScoreSymmetric(tolerant, strict);

    expect(oneWayTolerant, greaterThan(oneWayStrict));
    expect(symmetric, inInclusiveRange(oneWayStrict, oneWayTolerant));
    expect(symmetric, lessThan(1.0));
  });

  test('aggregate score does not cap on dealbreakers', () {
    final result = aggregateVibeScore([
      const VibeWeightedScore(
        scorePercent: 92,
        weight: 100,
        dealbreakerTriggered: true,
      ),
    ]);

    expect(result.cappedScore, isNull);
    expect(result.isCapped, isFalse);
  });

  test('default multiplier reduces effective weight', () {
    final base = VibePref(value: 3, tolerance: 2, weight: 10);
    final defaultPref = VibePref(
      value: 3,
      tolerance: 2,
      weight: 10,
      isDefault: true,
    );

    final baseWeight = categoryEffectiveWeight(base, base);
    final oneDefault = categoryEffectiveWeight(base, defaultPref);
    final bothDefault = categoryEffectiveWeight(defaultPref, defaultPref);

    expect(oneDefault, lessThan(baseWeight));
    expect(bothDefault, lessThan(oneDefault));
  });

  test('defaults reduce impact on total score', () {
    final aligned = VibeWeightedScore(
      scorePercent: 100,
      weight: 50,
      dealbreakerTriggered: false,
    );
    final mismatch = VibeWeightedScore(
      scorePercent: 0,
      weight: 50,
      dealbreakerTriggered: false,
    );
    final baseline = aggregateVibeScore([aligned, mismatch]);

    final defaultWeight = categoryEffectiveWeight(
      const VibePref(value: 3, tolerance: 2, weight: 50, isDefault: true),
      const VibePref(value: 3, tolerance: 2, weight: 50, isDefault: true),
    );
    final dampened = aggregateVibeScore([
      aligned,
      VibeWeightedScore(
        scorePercent: 0,
        weight: defaultWeight,
        dealbreakerTriggered: false,
      ),
    ]);

    expect(dampened.totalScore, greaterThan(baseline.totalScore));
  });

  group('dealbreakerTriggered', () {
    test('dealbreaker triggers on boundary violation', () {
      final a = VibePref(
        value: 0,
        tolerance: 2,
        weight: 10,
        dealbreaker: true,
        isDefault: false,
      );
      final b = VibePref(
        value: 4,
        tolerance: 2,
        weight: 10,
        dealbreaker: false,
        isDefault: false,
      );

      final triggered = dealbreakerTriggered(VibeCategory.drinking, a, b);

      expect(triggered, isTrue);
    });

    test('dealbreaker does not trigger within boundary', () {
      final a = VibePref(
        value: 0,
        tolerance: 2,
        weight: 10,
        dealbreaker: true,
        isDefault: false,
      );
      final b = VibePref(
        value: 2,
        tolerance: 2,
        weight: 10,
        dealbreaker: false,
        isDefault: false,
      );

      final triggered = dealbreakerTriggered(VibeCategory.drinking, a, b);

      expect(triggered, isFalse);
    });

    test('dealbreaker does not trigger when either side is default', () {
      final a = VibePref(
        value: 0,
        tolerance: 2,
        weight: 10,
        dealbreaker: true,
        isDefault: false,
      );
      final b = VibePref(
        value: VibePreference.defaultValue,
        tolerance: 2,
        weight: 10,
        dealbreaker: false,
        isDefault: true,
      );

      final triggered = dealbreakerTriggered(VibeCategory.drinking, a, b);

      expect(triggered, isFalse);
    });

    test('no dealbreakers never triggers', () {
      final a = VibePref(
        value: 0,
        tolerance: 2,
        weight: 10,
        dealbreaker: false,
        isDefault: false,
      );
      final b = VibePref(
        value: 5,
        tolerance: 2,
        weight: 10,
        dealbreaker: false,
        isDefault: false,
      );

      final triggered = dealbreakerTriggered(VibeCategory.drinking, a, b);

      expect(triggered, isFalse);
    });
  });
}
