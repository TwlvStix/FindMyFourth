import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/core/widgets/app_button_enhanced.dart';
import 'package:find_my_fourth/profile/edit_vibes/vibe_category_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 600, child: child),
        ),
      ),
    );
  }

  VibeCategorySlider buildSlider({
    VibeCategory category = VibeCategory.drinking,
    VibePreference? pref,
  }) {
    return VibeCategorySlider(
      category: category,
      pref: pref ?? VibePreference.defaults(),
      onValueChanged: (_) {},
      onDealbreakerChanged: (_) {},
      onValueCommitted: (_) {},
      debounceDuration: Duration.zero,
    );
  }

  List<MethodCall> installHapticSpy() {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });

    return calls;
  }

  List<MethodCall> hapticCalls(List<MethodCall> calls) {
    return calls
        .where((call) => call.method == 'HapticFeedback.vibrate')
        .toList();
  }

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('does not fire haptic on non-extreme slider changes',
      (tester) async {
    final calls = installHapticSpy();

    await tester.pumpWidget(
      wrap(
        buildSlider(),
      ),
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged?.call(4);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(hapticCalls(calls), isEmpty);
  });

  testWidgets('fires one haptic when dealbreaker prompt appears',
      (tester) async {
    final calls = installHapticSpy();

    await tester.pumpWidget(
      wrap(
        buildSlider(),
      ),
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged?.call(5);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.textContaining('Is this a dealbreaker?'), findsOneWidget);

    final haptics = hapticCalls(calls);
    expect(haptics.length, 1);
    expect(haptics.single.arguments, 'HapticFeedbackType.mediumImpact');
  });

  testWidgets('confirming dealbreaker adds no extra haptic', (tester) async {
    final calls = installHapticSpy();

    await tester.pumpWidget(
      wrap(
        buildSlider(),
      ),
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged?.call(5);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(hapticCalls(calls).length, 1);

    final yesButton = tester.widget<AppButtonEnhanced>(
      find.widgetWithText(AppButtonEnhanced, "Yes, it's a must"),
    );
    yesButton.onPressed?.call();
    await tester.pumpAndSettle();

    expect(find.text('Dealbreaker set'), findsOneWidget);
    expect(hapticCalls(calls).length, 1);
  });
}
