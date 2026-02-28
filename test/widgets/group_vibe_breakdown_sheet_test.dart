import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/core/widgets/vibe/group_vibe_breakdown_sheet.dart';
import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/services/vibe_group_matcher.dart';

VibeProfile _buildProfile({
  int pace = 3,
  int competitive = 3,
  int drinking = 3,
  int chat = 3,
  int money = 3,
  int music = 3,
}) {
  final prefs = <VibeCategory, VibePreference>{
    VibeCategory.pace: VibePreference(
      value: pace,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
    VibeCategory.competitive: VibePreference(
      value: competitive,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
    VibeCategory.drinking: VibePreference(
      value: drinking,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
    VibeCategory.chat: VibePreference(
      value: chat,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
    VibeCategory.money: VibePreference(
      value: money,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
    VibeCategory.music: VibePreference(
      value: music,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
  };

  return VibeProfile(
    prefs: prefs,
    importance: {
      for (final category in VibeCategory.values)
        category: VibeImportance.normal,
    },
    importanceVersion: 1,
    confirmedAt: DateTime.now(),
  );
}

void main() {
  testWidgets('renders score and member names in breakdown sheet', (
    tester,
  ) async {
    final result = GroupVibeMatcher.scoreGroup(
      mine: _buildProfile(pace: 4, chat: 2),
      others: <GroupVibeMember>[
        GroupVibeMember(
          id: 'a',
          name: 'Casey',
          profile: _buildProfile(pace: 1, chat: 5),
        ),
        GroupVibeMember(
          id: 'b',
          name: 'Jordan',
          profile: _buildProfile(pace: 3, chat: 2),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  GroupVibeBreakdownSheet.show(
                    context: context,
                    result: result,
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Group Fit'), findsOneWidget);
    expect(find.text('Player matches'), findsOneWidget);
    expect(find.text('Casey'), findsOneWidget);
    expect(find.text('Jordan'), findsOneWidget);
    expect(find.text('${result.groupFitScore.round()}%'), findsOneWidget);
  });
}
