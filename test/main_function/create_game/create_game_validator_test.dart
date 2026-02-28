import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/main_function/create_game/create_game_validator.dart';
import 'package:find_my_fourth/main_function/create_game/models/create_game_form_data.dart';

void main() {
  group('CreateGameValidator', () {
    test('requires course only for confirmed schedule', () {
      final confirmed = CreateGameFormData(
        scheduleType: 'confirmed',
        friendsValue: 'Public',
        datePicked: DateTime(2026, 1, 1, 9),
        isJustForFun: true,
      );

      final flexible = CreateGameFormData(
        scheduleType: 'flexible',
        flexibleWeek: 'next_week',
        friendsValue: 'Public',
        isJustForFun: true,
      );

      expect(CreateGameValidator.validateCourse(confirmed), isNotNull);
      expect(CreateGameValidator.validateCourse(flexible), isNull);
    });

    test('requires team style when 2v2 is enabled', () {
      final data = CreateGameFormData(
        scheduleType: 'confirmed',
        datePicked: DateTime(2026, 1, 1, 9),
        friendsValue: 'Friends',
        courseValue: 'Pebble Beach',
        is2v2: true,
        isJustForFun: false,
        rulesSetValue: 'Competitive',
        styleGameValue: 'Friendly',
        gameTypeValue: 'Stroke Play',
      );

      expect(CreateGameValidator.validateTeamSetup(data), isNotNull);

      data.teamStyle = 'Best Ball';
      expect(CreateGameValidator.validateTeamSetup(data), isNull);
    });

    test('requires other game description when Other is selected', () {
      final data = CreateGameFormData(
        scheduleType: 'confirmed',
        datePicked: DateTime(2026, 1, 1, 9),
        friendsValue: 'Public',
        courseValue: 'Pebble Beach',
        isJustForFun: false,
        rulesSetValue: 'Competitive',
        styleGameValue: 'Friendly',
        gameTypeValue: 'Stroke Play',
        selectedGames: {'Other'},
      );

      expect(CreateGameValidator.validateGamesSelection(data), isNotNull);

      data.otherGameText = 'Nassau';
      expect(CreateGameValidator.validateGamesSelection(data), isNull);
    });

    test('full validation passes for valid flexible just-for-fun submission',
        () {
      final data = CreateGameFormData(
        scheduleType: 'flexible',
        flexibleWeek: 'next_week',
        friendsValue: 'Public',
        isJustForFun: true,
      );

      expect(CreateGameValidator.validateForSubmission(data), isNull);
    });
  });
}
