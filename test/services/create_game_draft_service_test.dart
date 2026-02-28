import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:find_my_fourth/main_function/create_game/models/create_game_form_data.dart';
import 'package:find_my_fourth/services/create_game_draft_service.dart';

void main() {
  group('CreateGameDraftService', () {
    late CreateGameDraftService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = CreateGameDraftService();
    });

    test('saveDraft + loadDraft round-trips form fields', () async {
      final original = CreateGameFormData(
        gameName: 'Test Game',
        friendsValue: 'Public',
        scheduleType: 'flexible',
        flexibleWeek: 'next_week',
        selectedDays: {1, 3, 5},
        flexibleTimesOfDay: {'morning', 'afternoon'},
        memberDiscount: true,
        courseValue: 'Pebble Beach',
        selectedCourseRefPath: 'course/pebble',
      );

      await service.saveDraft(original);
      final restored = await service.loadDraft();

      expect(restored, isNotNull);
      expect(restored!.gameName, 'Test Game');
      expect(restored.friendsValue, 'Public');
      expect(restored.scheduleType, 'flexible');
      expect(restored.flexibleWeek, 'next_week');
      expect(restored.selectedDays, {1, 3, 5});
      expect(restored.memberDiscount, isTrue);
      expect(restored.memberValue, 'Yes');
      expect(restored.selectedCourseRefPath, 'course/pebble');
    });

    test('clearDraft removes stored state', () async {
      await service.saveDraft(CreateGameFormData(gameName: 'To Clear'));
      expect(await service.hasDraft(), isTrue);

      await service.clearDraft();

      expect(await service.hasDraft(), isFalse);
      expect(await service.loadDraft(), isNull);
    });
  });
}
