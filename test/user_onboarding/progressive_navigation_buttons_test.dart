import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/user_onboarding/components/progressive_navigation_buttons.dart';
import 'package:find_my_fourth/core/widgets/app_button_enhanced.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // BUTTON VARIANT TESTS
  // ═══════════════════════════════════════════════════════════════════════════

  group('ProgressiveNavigationButtons button variants', () {
    testWidgets('shows primary variant for Next button on step 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressiveNavigationButtons(
              currentStep: 0,
              totalSteps: 4,
              isLoading: false,
              onNext: () {},
              onPrevious: () {},
            ),
          ),
        ),
      );

      // Find the Next button
      final nextButton = find.widgetWithText(AppButtonEnhanced, 'Next');
      expect(nextButton, findsOneWidget);

      // Verify it's using primary variant (not premium)
      final buttonWidget = tester.widget<AppButtonEnhanced>(nextButton);
      expect(buttonWidget.variant, AppButtonVariant.primary);
    });

    testWidgets('shows primary variant for Next button on step 1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressiveNavigationButtons(
              currentStep: 1,
              totalSteps: 4,
              isLoading: false,
              onNext: () {},
              onPrevious: () {},
            ),
          ),
        ),
      );

      final nextButton = find.widgetWithText(AppButtonEnhanced, 'Next');
      expect(nextButton, findsOneWidget);

      final buttonWidget = tester.widget<AppButtonEnhanced>(nextButton);
      expect(buttonWidget.variant, AppButtonVariant.primary);
    });

    testWidgets('shows primary variant for Next button on step 2', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressiveNavigationButtons(
              currentStep: 2,
              totalSteps: 4,
              isLoading: false,
              onNext: () {},
              onPrevious: () {},
            ),
          ),
        ),
      );

      final nextButton = find.widgetWithText(AppButtonEnhanced, 'Next');
      expect(nextButton, findsOneWidget);

      final buttonWidget = tester.widget<AppButtonEnhanced>(nextButton);
      expect(buttonWidget.variant, AppButtonVariant.primary);
    });

    testWidgets('shows premium variant for Complete button on final step',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressiveNavigationButtons(
              currentStep: 3,
              totalSteps: 4,
              isLoading: false,
              onNext: () {},
              onPrevious: () {},
            ),
          ),
        ),
      );

      // Find the Complete button (not Next)
      final completeButton = find.widgetWithText(AppButtonEnhanced, 'Complete');
      expect(completeButton, findsOneWidget);

      final buttonWidget = tester.widget<AppButtonEnhanced>(completeButton);
      expect(buttonWidget.variant, AppButtonVariant.premium);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // BUTTON TEXT TESTS
  // ═══════════════════════════════════════════════════════════════════════════

  group('ProgressiveNavigationButtons button text', () {
    testWidgets('shows "Next" on non-final steps', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressiveNavigationButtons(
              currentStep: 0,
              totalSteps: 4,
              isLoading: false,
              onNext: () {},
              onPrevious: () {},
            ),
          ),
        ),
      );

      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Complete'), findsNothing);
    });

    testWidgets('shows "Complete" on final step', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressiveNavigationButtons(
              currentStep: 3,
              totalSteps: 4,
              isLoading: false,
              onNext: () {},
              onPrevious: () {},
            ),
          ),
        ),
      );

      expect(find.text('Complete'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // BACK BUTTON VISIBILITY TESTS
  // ═══════════════════════════════════════════════════════════════════════════

  group('ProgressiveNavigationButtons Back button visibility', () {
    testWidgets('hides Back button on step 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressiveNavigationButtons(
              currentStep: 0,
              totalSteps: 4,
              isLoading: false,
              onNext: () {},
              onPrevious: () {},
            ),
          ),
        ),
      );

      expect(find.text('Back'), findsNothing);
    });

    testWidgets('shows Back button on step 1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressiveNavigationButtons(
              currentStep: 1,
              totalSteps: 4,
              isLoading: false,
              onNext: () {},
              onPrevious: () {},
            ),
          ),
        ),
      );

      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('shows Back button on final step', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressiveNavigationButtons(
              currentStep: 3,
              totalSteps: 4,
              isLoading: false,
              onNext: () {},
              onPrevious: () {},
            ),
          ),
        ),
      );

      expect(find.text('Back'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // LOADING STATE TESTS
  // ═══════════════════════════════════════════════════════════════════════════

  group('ProgressiveNavigationButtons loading state', () {
    testWidgets('disables buttons when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressiveNavigationButtons(
              currentStep: 1,
              totalSteps: 4,
              isLoading: true,
              onNext: () {},
              onPrevious: () {},
            ),
          ),
        ),
      );

      // Find all AppButtonEnhanced widgets
      final buttons = tester.widgetList<AppButtonEnhanced>(
        find.byType(AppButtonEnhanced),
      ).toList();

      expect(buttons.length, 2);

      // Both buttons should have onPressed as null when loading
      for (final button in buttons) {
        expect(button.onPressed, isNull);
      }
    });

    testWidgets('sets isLoading on forward button when loading',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressiveNavigationButtons(
              currentStep: 1,
              totalSteps: 4,
              isLoading: true,
              onNext: () {},
              onPrevious: () {},
            ),
          ),
        ),
      );

      // Find all AppButtonEnhanced widgets
      final buttons = tester.widgetList<AppButtonEnhanced>(
        find.byType(AppButtonEnhanced),
      ).toList();

      // The second button (Next) should have isLoading true
      // First button is Back, second is Next
      expect(buttons[1].isLoading, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // CALLBACK TESTS
  // ═══════════════════════════════════════════════════════════════════════════

  group('ProgressiveNavigationButtons callbacks', () {
    testWidgets('calls onNext when Next tapped', (tester) async {
      bool nextCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressiveNavigationButtons(
              currentStep: 0,
              totalSteps: 4,
              isLoading: false,
              onNext: () => nextCalled = true,
              onPrevious: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(nextCalled, isTrue);
    });

    testWidgets('calls onPrevious when Back tapped', (tester) async {
      bool previousCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressiveNavigationButtons(
              currentStep: 1,
              totalSteps: 4,
              isLoading: false,
              onNext: () {},
              onPrevious: () => previousCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Back'));
      await tester.pump();

      expect(previousCalled, isTrue);
    });

    testWidgets('does not call callbacks when loading', (tester) async {
      bool nextCalled = false;
      bool previousCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressiveNavigationButtons(
              currentStep: 1,
              totalSteps: 4,
              isLoading: true,
              onNext: () => nextCalled = true,
              onPrevious: () => previousCalled = true,
            ),
          ),
        ),
      );

      // Find buttons by type since the Next button shows spinner when loading
      final buttons = find.byType(AppButtonEnhanced);
      expect(buttons, findsNWidgets(2));

      // Tap both buttons (Back is first, Next/Loading is second)
      await tester.tap(buttons.first);
      await tester.tap(buttons.last);
      await tester.pump();

      expect(nextCalled, isFalse);
      expect(previousCalled, isFalse);
    });
  });
}
