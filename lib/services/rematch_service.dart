import '/main_function/create_game/models/create_game_form_data.dart';
import '/models/game.dart';
import '/models/player_eligibility.dart';

/// Builds pre-filled CreateGameFormData from a completed game for rematch flows.
///
/// Pure Dart class with no Firebase dependency.
class RematchService {
  /// Creates a rematch form pre-filled with all game settings.
  ///
  /// Sets `createdVia: 'rematch'` and `sourceGameId` to the original game ID.
  CreateGameFormData buildRematchForm(Game game) {
    return _buildForm(game, createdVia: 'rematch', keepCourse: true);
  }

  /// Creates a rematch form with course cleared for the user to pick a new one.
  ///
  /// Sets `createdVia: 'switch_course'` and `sourceGameId` to the original game ID.
  CreateGameFormData buildSwitchCourseForm(Game game) {
    return _buildForm(game, createdVia: 'switch_course', keepCourse: false);
  }

  CreateGameFormData _buildForm(
    Game game, {
    required String createdVia,
    required bool keepCourse,
  }) {
    return CreateGameFormData(
      gameTypeValue: game.gameType.isNotEmpty ? game.gameType : null,
      styleGameValue: game.styleGame.isNotEmpty ? game.styleGame : null,
      rulesSetValue: game.rulesSetting.isNotEmpty ? game.rulesSetting : null,
      scoringValue: game.scoring.isNotEmpty ? game.scoring : null,
      friendsValue: game.friendGame.isNotEmpty ? game.friendGame : null,
      memberValue: game.memberDiscount == 'Yes' ? 'Yes' : 'No',
      memberDiscount: game.memberDiscount == 'Yes',
      is2v2: game.is2v2,
      isJustForFun: game.isFunGame,
      playerEligibility: game.playerEligibility.toFirestoreValue(),
      selectedGames:
          game.sideGameTags.isNotEmpty ? game.sideGameTags.toSet() : {},
      courseValue: keepCourse && game.coursePlay.isNotEmpty
          ? game.coursePlay
          : null,
      selectedCourseRefPath: keepCourse ? game.courseRef?.path : null,
      scheduleType: 'confirmed',
      datePicked: null,
      sourceGameId: game.reference.id,
      createdVia: createdVia,
    );
  }
}
