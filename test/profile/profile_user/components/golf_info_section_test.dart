import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/profile/profile_user/components/golf_info_section.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('hides email and phone when not provided', (tester) async {
    await tester.pumpWidget(
      wrap(
        const GolfInfoSection(
          golfCanadaNumber: '12345',
        ),
      ),
    );

    expect(find.text('Golf Canada #'), findsOneWidget);
    expect(find.text('12345'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
    expect(find.text('Phone'), findsNothing);
  });

  testWidgets('renders email and phone when provided', (tester) async {
    await tester.pumpWidget(
      wrap(
        const GolfInfoSection(
          golfCanadaNumber: '12345',
          email: 'player@example.com',
          phone: '555-1234',
        ),
      ),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('player@example.com'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('555-1234'), findsOneWidget);
  });
}
