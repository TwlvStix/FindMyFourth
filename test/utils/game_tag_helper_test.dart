import 'package:flutter_test/flutter_test.dart';
import 'package:find_my_fourth/utils/game_tag_helper.dart';

void main() {
  group('getRow3TagsFromRaw', () {
    group('stakes tags', () {
      test('high stakes returns highStakes tag', () {
        final tags = getRow3TagsFromRaw(
          styleGame: 'High Stakes',
          gameType: 'stroke',
        );

        expect(tags.length, equals(1));
        expect(tags.first.label, equals('HIGH STAKES'));
        expect(tags.first.stakesLevel, equals(StakesLevel.highStakes));
        expect(tags.first.isStakesTag, isTrue);
        expect(tags.first.isFormatFallback, isFalse);
      });

      test('highstakes (no space) returns highStakes tag', () {
        final tags = getRow3TagsFromRaw(
          styleGame: 'highstakes',
          gameType: 'stroke',
        );

        expect(tags.length, equals(1));
        expect(tags.first.stakesLevel, equals(StakesLevel.highStakes));
      });

      test('low stakes returns lowStakes tag', () {
        final tags = getRow3TagsFromRaw(
          styleGame: 'Low Stakes',
          gameType: 'stroke',
        );

        expect(tags.length, equals(1));
        expect(tags.first.label, equals('LOW STAKES'));
        expect(tags.first.stakesLevel, equals(StakesLevel.lowStakes));
        expect(tags.first.isStakesTag, isTrue);
      });

      test('lowstakes (no space) returns lowStakes tag', () {
        final tags = getRow3TagsFromRaw(
          styleGame: 'lowstakes',
          gameType: 'stroke',
        );

        expect(tags.length, equals(1));
        expect(tags.first.stakesLevel, equals(StakesLevel.lowStakes));
      });

      test('no money returns noMoney tag', () {
        final tags = getRow3TagsFromRaw(
          styleGame: 'No Money',
          gameType: 'stroke',
        );

        expect(tags.length, equals(1));
        expect(tags.first.label, equals('NO MONEY'));
        expect(tags.first.stakesLevel, equals(StakesLevel.noMoney));
        expect(tags.first.isStakesTag, isTrue);
      });

      test('nomoney (no space) returns noMoney tag', () {
        final tags = getRow3TagsFromRaw(
          styleGame: 'nomoney',
          gameType: 'stroke',
        );

        expect(tags.length, equals(1));
        expect(tags.first.stakesLevel, equals(StakesLevel.noMoney));
      });

      test('money game maps to highStakes', () {
        final tags = getRow3TagsFromRaw(
          styleGame: 'Money Game',
          gameType: 'stroke',
        );

        expect(tags.length, equals(1));
        expect(tags.first.label, equals('HIGH STAKES'));
        expect(tags.first.stakesLevel, equals(StakesLevel.highStakes));
      });

      test('handles case insensitivity', () {
        final tags = getRow3TagsFromRaw(
          styleGame: 'HIGH STAKES',
          gameType: 'stroke',
        );

        expect(tags.first.stakesLevel, equals(StakesLevel.highStakes));
      });

      test('handles whitespace', () {
        final tags = getRow3TagsFromRaw(
          styleGame: '  Low Stakes  ',
          gameType: 'stroke',
        );

        expect(tags.first.stakesLevel, equals(StakesLevel.lowStakes));
      });
    });

    group('format fallback', () {
      test('empty styleGame returns format tag', () {
        final tags = getRow3TagsFromRaw(
          styleGame: '',
          gameType: 'stroke',
        );

        expect(tags.length, equals(1));
        expect(tags.first.label, equals('STROKE PLAY'));
        expect(tags.first.isFormatFallback, isTrue);
        expect(tags.first.isStakesTag, isFalse);
        expect(tags.first.stakesLevel, isNull);
      });

      test('unknown styleGame returns format tag', () {
        final tags = getRow3TagsFromRaw(
          styleGame: 'some unknown value',
          gameType: 'match_play',
        );

        expect(tags.length, equals(1));
        expect(tags.first.label, equals('MATCH PLAY'));
        expect(tags.first.isFormatFallback, isTrue);
      });

      test('formats game types correctly', () {
        final testCases = {
          'stroke': 'STROKE PLAY',
          'match_play': 'MATCH PLAY',
          'stableford': 'STABLEFORD',
          'scramble': 'SCRAMBLE',
          'best_ball': 'BEST BALL',
          'skins': 'SKINS',
        };

        testCases.forEach((input, expected) {
          final tags = getRow3TagsFromRaw(
            styleGame: '',
            gameType: input,
          );

          expect(tags.first.label, equals(expected),
              reason: 'Expected $input to format as $expected');
        });
      });

      test('unknown game type passes through', () {
        final tags = getRow3TagsFromRaw(
          styleGame: '',
          gameType: 'custom_format',
        );

        expect(tags.first.label, equals('CUSTOM_FORMAT'));
      });
    });

    group('priority', () {
      test('stakes takes priority over format', () {
        final tags = getRow3TagsFromRaw(
          styleGame: 'High Stakes',
          gameType: 'stroke',
        );

        expect(tags.length, equals(1));
        expect(tags.first.isStakesTag, isTrue);
        expect(tags.first.label, equals('HIGH STAKES'));
      });
    });

    group('empty data', () {
      test('empty styleGame and gameType returns empty list', () {
        final tags = getRow3TagsFromRaw(
          styleGame: '',
          gameType: '',
        );

        expect(tags, isEmpty);
      });

      test('whitespace-only values return empty list', () {
        final tags = getRow3TagsFromRaw(
          styleGame: '   ',
          gameType: '   ',
        );

        expect(tags, isEmpty);
      });
    });
  });
}
