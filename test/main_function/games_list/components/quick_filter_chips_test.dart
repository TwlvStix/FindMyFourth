import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/main_function/games_list/components/quick_filter_chips.dart';
import 'package:find_my_fourth/main_function/games_list/models/quick_filter.dart';

void main() {
  Widget buildSubject({
    QuickFilter selected = QuickFilter.all,
    ValueChanged<QuickFilter>? onChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: QuickFilterChips(
          selectedFilter: selected,
          onFilterChanged: onChanged ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('renders current quick-filter pills and excludes removed pills',
      (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('All Games'), findsOneWidget);
    expect(find.text('⚡ Flexible'), findsOneWidget);
    expect(find.text('This Weekend'), findsOneWidget);
    expect(find.text('Near Me'), findsNothing);

    expect(find.text('Morning'), findsNothing);
    expect(find.text('🔥 Top VIBE'), findsNothing);
    expect(find.text('Top VIBE'), findsNothing);
  });

  testWidgets('invokes callback when a pill is tapped', (tester) async {
    QuickFilter? selected;

    await tester.pumpWidget(
      buildSubject(
        onChanged: (filter) => selected = filter,
      ),
    );

    await tester.tap(find.text('This Weekend'));
    await tester.pumpAndSettle();

    expect(selected, equals(QuickFilter.thisWeekend));
  });
}
