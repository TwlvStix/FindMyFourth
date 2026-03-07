import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/main_function/games_list/models/quick_filter.dart';
import 'package:find_my_fourth/models/game.dart';

void main() {
  group('QuickFilter', () {
    test('exposes only supported top-row filter pills', () {
      expect(
        QuickFilter.values,
        equals([
          QuickFilter.all,
          QuickFilter.flexible,
          QuickFilter.thisWeekend,
          QuickFilter.nearMe,
        ]),
      );
    });

    test('uses emoji only for flexible filter', () {
      expect(QuickFilter.flexible.displayLabel, equals('⚡ Flexible'));
      expect(QuickFilter.all.displayLabel, equals('All Games'));
      expect(QuickFilter.thisWeekend.displayLabel, equals('This Weekend'));
      expect(QuickFilter.nearMe.displayLabel, equals('Near Me'));
    });

    test('marks only near me as sort-oriented quick filter', () {
      expect(QuickFilter.nearMe.isSortFilter, isTrue);
      expect(QuickFilter.all.isSortFilter, isFalse);
      expect(QuickFilter.flexible.isSortFilter, isFalse);
      expect(QuickFilter.thisWeekend.isSortFilter, isFalse);
    });

    test('applies all quick filters without throwing', () {
      final games = <Game>[];

      for (final filter in QuickFilter.values) {
        expect(filter.apply(games), isA<List<Game>>());
      }
    });
  });
}
