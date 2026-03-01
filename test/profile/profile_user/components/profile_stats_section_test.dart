import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/profile/profile_user/components/profile_stats_section.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows Friends card for own profile', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ProfileStatsSection(
          handicap: '8',
          homeCourse: 'Augusta',
          friendsCount: 12,
          isSelf: true,
          vibeMatchResult: null,
          onOpenVibe: _noop,
        ),
      ),
    );

    expect(find.text('Friends'), findsOneWidget);
    expect(find.text('Your Fit'), findsNothing);
    expect(find.text('Augusta'), findsOneWidget);
  });

  testWidgets('shows Your Fit card for public profile', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ProfileStatsSection(
          handicap: '8',
          homeCourse: 'Pebble Beach',
          friendsCount: 12,
          isSelf: false,
          vibeMatchResult: null,
          onOpenVibe: _noop,
        ),
      ),
    );

    expect(find.text('Your Fit'), findsOneWidget);
    expect(find.text('Friends'), findsNothing);
    expect(find.text('Pebble Beach'), findsOneWidget);
  });
}

void _noop() {}
