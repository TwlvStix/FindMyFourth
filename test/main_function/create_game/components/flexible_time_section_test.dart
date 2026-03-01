import 'package:find_my_fourth/main_function/create_game/components/flexible_time_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 1200, child: child),
        ),
      ),
    );
  }

  FlexibleTimeSection buildSection({
    required String flexibleWeek,
    Set<int>? selectedDays,
    Set<String>? times,
  }) {
    return FlexibleTimeSection(
      data: FlexibleTimeData(
        flexibleWeek: flexibleWeek,
        selectedDays: selectedDays ?? <int>{},
        flexibleTimesOfDay: times ?? {'anytime'},
      ),
      onWeekChanged: (_) {},
      onDaysChanged: (_) {},
      onTimesOfDayChanged: (_) {},
    );
  }

  group('FlexibleTimeSection', () {
    testWidgets('this_week shows remaining days through Sunday',
        (tester) async {
      final now = DateTime.now();
      final expectedDays = _remainingDaysInMondayFirstWeek(now)
          .map((index) => _dayNamesByIndex[index]!)
          .toSet();

      await tester.pumpWidget(
        wrap(
          buildSection(
            flexibleWeek: 'this_week',
          ),
        ),
      );

      for (final entry in _dayNamesByIndex.entries) {
        final finder = find.text(entry.value);
        if (expectedDays.contains(entry.value)) {
          expect(finder, findsOneWidget);
        } else {
          expect(finder, findsNothing);
        }
      }
    });

    testWidgets('day chips render Monday-first order for next_week',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          buildSection(
            flexibleWeek: 'next_week',
          ),
        ),
      );

      final monX = tester.getTopLeft(find.text('Mon')).dx;
      final tueX = tester.getTopLeft(find.text('Tue')).dx;
      final wedX = tester.getTopLeft(find.text('Wed')).dx;
      final thuX = tester.getTopLeft(find.text('Thu')).dx;
      final friX = tester.getTopLeft(find.text('Fri')).dx;
      final satX = tester.getTopLeft(find.text('Sat')).dx;
      final sunX = tester.getTopLeft(find.text('Sun')).dx;

      expect(monX, lessThan(tueX));
      expect(tueX, lessThan(wedX));
      expect(wedX, lessThan(thuX));
      expect(thuX, lessThan(friX));
      expect(friX, lessThan(satX));
      expect(satX, lessThan(sunX));
    });

    testWidgets('summary sorts selected days Monday-first', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildSection(
            flexibleWeek: 'this_week',
            selectedDays: {0, 1, 6},
          ),
        ),
      );

      expect(
        find.text('This Week • Mon, Sat, Sun • Anytime'),
        findsOneWidget,
      );
    });
  });
}

const Map<int, String> _dayNamesByIndex = {
  0: 'Sun',
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
  6: 'Sat',
};

List<int> _remainingDaysInMondayFirstWeek(DateTime now) {
  const mondayFirstOrder = [1, 2, 3, 4, 5, 6, 0];
  final todayDayIndex = now.weekday == DateTime.sunday ? 0 : now.weekday;
  final todayPosition = mondayFirstOrder.indexOf(todayDayIndex);
  return mondayFirstOrder.sublist(todayPosition);
}
