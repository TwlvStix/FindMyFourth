import 'package:flutter_test/flutter_test.dart';
import 'package:find_my_fourth/utils/availability_text_helper.dart';

void main() {
  group('formatAvailabilityFromRaw', () {
    group('day collapsing', () {
      test('all 7 days returns "Any Day"', () {
        final result = formatAvailabilityFromRaw(
          flexibleDays: [0, 1, 2, 3, 4, 5, 6],
        );
        expect(result, equals('Any Day'));
      });

      test('all weekdays (Mon-Fri) returns "Weekdays"', () {
        final result = formatAvailabilityFromRaw(
          flexibleDays: [1, 2, 3, 4, 5],
        );
        expect(result, equals('Weekdays'));
      });

      test('weekdays in any order returns "Weekdays"', () {
        final result = formatAvailabilityFromRaw(
          flexibleDays: [5, 3, 1, 4, 2],
        );
        expect(result, equals('Weekdays'));
      });

      test('Sat+Sun returns "Weekend"', () {
        final result = formatAvailabilityFromRaw(
          flexibleDays: [0, 6],
        );
        expect(result, equals('Weekend'));
      });

      test('Sun+Sat in any order returns "Weekend"', () {
        final result = formatAvailabilityFromRaw(
          flexibleDays: [6, 0],
        );
        expect(result, equals('Weekend'));
      });

      test('3+ contiguous days returns range format', () {
        // Tue, Wed, Thu (2, 3, 4)
        final result = formatAvailabilityFromRaw(
          flexibleDays: [2, 3, 4],
        );
        expect(result, equals('Tue–Thu'));
      });

      test('4 contiguous days returns range format', () {
        // Mon, Tue, Wed, Thu (1, 2, 3, 4)
        final result = formatAvailabilityFromRaw(
          flexibleDays: [1, 2, 3, 4],
        );
        expect(result, equals('Mon–Thu'));
      });

      test('2 contiguous days lists them', () {
        // Mon, Tue (1, 2)
        final result = formatAvailabilityFromRaw(
          flexibleDays: [1, 2],
        );
        expect(result, equals('Mon, Tue'));
      });

      test('3 non-contiguous days lists them', () {
        // Mon, Wed, Fri (1, 3, 5)
        final result = formatAvailabilityFromRaw(
          flexibleDays: [1, 3, 5],
        );
        expect(result, equals('Mon, Wed, Fri'));
      });

      test('single day shows that day', () {
        final result = formatAvailabilityFromRaw(
          flexibleDays: [3],
        );
        expect(result, equals('Wed'));
      });
    });

    group('week prefix', () {
      test('this_week adds "This Week" prefix', () {
        final result = formatAvailabilityFromRaw(
          flexibleWeek: 'this_week',
          flexibleDays: [1, 2, 3, 4, 5],
        );
        expect(result, equals('This Week · Weekdays'));
      });

      test('next_week adds "Next Week" prefix', () {
        final result = formatAvailabilityFromRaw(
          flexibleWeek: 'next_week',
          flexibleDays: [2, 3, 4],
        );
        expect(result, equals('Next Week · Tue–Thu'));
      });

      test('flexible (30-day window) shows no week prefix', () {
        final result = formatAvailabilityFromRaw(
          flexibleWeek: 'flexible',
          flexibleDays: [0, 6],
        );
        expect(result, equals('Weekend'));
      });
    });

    group('time of day', () {
      test('morning appends "Morning"', () {
        final result = formatAvailabilityFromRaw(
          flexibleDays: [1, 2, 3, 4, 5],
          flexibleTimeOfDay: 'morning',
        );
        expect(result, equals('Weekdays · Morning'));
      });

      test('afternoon appends "Afternoon"', () {
        final result = formatAvailabilityFromRaw(
          flexibleDays: [0, 6],
          flexibleTimeOfDay: 'afternoon',
        );
        expect(result, equals('Weekend · Afternoon'));
      });

      test('twilight appends "Twilight"', () {
        final result = formatAvailabilityFromRaw(
          flexibleDays: [1, 3, 5],
          flexibleTimeOfDay: 'twilight',
        );
        expect(result, equals('Mon, Wed, Fri · Twilight'));
      });

      test('time only (no days) shows just time', () {
        final result = formatAvailabilityFromRaw(
          flexibleTimeOfDay: 'afternoon',
        );
        expect(result, equals('Afternoon'));
      });
    });

    group('combined', () {
      test('week + days + time combines all parts', () {
        final result = formatAvailabilityFromRaw(
          flexibleWeek: 'next_week',
          flexibleDays: [1, 2, 3, 4, 5],
          flexibleTimeOfDay: 'afternoon',
        );
        expect(result, equals('Next Week · Weekdays · Afternoon'));
      });

      test('week + time (no days) combines correctly', () {
        final result = formatAvailabilityFromRaw(
          flexibleWeek: 'this_week',
          flexibleTimeOfDay: 'morning',
        );
        expect(result, equals('This Week · Morning'));
      });
    });

    group('fallback', () {
      test('no data returns "Flexible"', () {
        final result = formatAvailabilityFromRaw();
        expect(result, equals('Flexible'));
      });

      test('null days returns "Flexible" if no other data', () {
        final result = formatAvailabilityFromRaw(
          flexibleDays: null,
          flexibleTimeOfDay: null,
          flexibleWeek: null,
        );
        expect(result, equals('Flexible'));
      });

      test('empty days list returns "Flexible" if no other data', () {
        final result = formatAvailabilityFromRaw(
          flexibleDays: [],
        );
        expect(result, equals('Flexible'));
      });

      test('flexible week alone returns "Flexible"', () {
        // "flexible" week doesn't add a prefix, so with no other data
        // it should return "Flexible"
        final result = formatAvailabilityFromRaw(
          flexibleWeek: 'flexible',
        );
        expect(result, equals('Flexible'));
      });
    });
  });
}
