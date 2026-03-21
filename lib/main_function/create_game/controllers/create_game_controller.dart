import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/utils/app_log.dart';
import '/main_function/create_game/create_game_constants.dart';
import '/main_function/create_game/create_game_validator.dart';
import '/main_function/create_game/models/create_game_form_data.dart';
import '/services/create_game_draft_service.dart';
import '/services/create_game_service.dart';

enum CreateGameSubmitFailure {
  invalidForm,
  validation,
  unauthenticated,
  chatCreation,
  saveFailed,
  unknown,
}

enum CreateGameNextRoute {
  gamesList,
  playerList,
}

class CreateGameSubmitResult {
  const CreateGameSubmitResult._({
    required this.success,
    this.failure,
    this.message,
    this.gameRef,
    this.nextRoute,
  });

  final bool success;
  final CreateGameSubmitFailure? failure;
  final String? message;
  final DocumentReference? gameRef;
  final CreateGameNextRoute? nextRoute;

  factory CreateGameSubmitResult.success({
    required DocumentReference gameRef,
    required CreateGameNextRoute nextRoute,
  }) {
    return CreateGameSubmitResult._(
      success: true,
      gameRef: gameRef,
      nextRoute: nextRoute,
    );
  }

  factory CreateGameSubmitResult.failure(
    CreateGameSubmitFailure failure, {
    String? message,
  }) {
    return CreateGameSubmitResult._(
      success: false,
      failure: failure,
      message: message,
    );
  }
}

typedef CreateGameChatCreator = Future<DocumentReference> Function({
  required String createdByUid,
  required String gameId,
  required String gameName,
});

class CreateGameController {
  CreateGameController({
    CreateGameDraftService? draftService,
    CreateGameService? gameService,
  })  : _draftService = draftService ?? CreateGameDraftService(),
        _gameService = gameService ?? CreateGameService();

  final CreateGameDraftService _draftService;
  final CreateGameService _gameService;

  Future<CreateGameFormData?> loadDraft() => _draftService.loadDraft();

  Future<void> saveDraft(CreateGameFormData formData) async {
    formData.reconcileDerivedFields();
    await _draftService.saveDraft(formData);
  }

  Future<void> clearDraft() => _draftService.clearDraft();

  Future<CreateGameSubmitResult> submitGame({
    required CreateGameFormData formData,
    required bool isFormValid,
    required DocumentReference? currentUserRef,
    required CreateGameChatCreator createGameChat,
    required void Function() invalidateAvailableGamesCache,
    required void Function(String userId) invalidateUserGamesCache,
    required String userIdForCache,
  }) async {
    AppLog.d('🎮 CREATE GAME: Submit triggered');

    if (!isFormValid) {
      return CreateGameSubmitResult.failure(
          CreateGameSubmitFailure.invalidForm);
    }

    final validationError = CreateGameValidator.validateForSubmission(formData);
    if (validationError != null) {
      return CreateGameSubmitResult.failure(
        CreateGameSubmitFailure.validation,
        message: validationError,
      );
    }

    final currentUserId = _gameService.getCurrentUserId();
    if (currentUserId == null) {
      return CreateGameSubmitResult.failure(
        CreateGameSubmitFailure.unauthenticated,
        message: 'Please sign in to create a game.',
      );
    }

    final userRef =
        currentUserRef ?? _gameService.userRefForUid(currentUserId);
    final gameName = formData.ensureGameName();
    final gameRef = _gameService.generateGameRef();

    DocumentReference chatRef;
    try {
      chatRef = await createGameChat(
        createdByUid: currentUserId,
        gameId: gameRef.id,
        gameName: gameName,
      );
    } catch (error, stackTrace) {
      AppLog.d('❌ CREATE GAME: Chat creation failed: $error');
      AppLog.d('❌ CREATE GAME: Stack trace: $stackTrace');
      return CreateGameSubmitResult.failure(
        CreateGameSubmitFailure.chatCreation,
        message: 'Unable to create game chat. Please try again.',
      );
    }

    try {
      await _gameService.createGameWithRef(
        gameRef: gameRef,
        formData: formData,
        uid: currentUserId,
        userRef: userRef,
        chatRef: chatRef,
      );
      await clearDraft();
      invalidateAvailableGamesCache();
      invalidateUserGamesCache(userIdForCache);
    } on FirebaseException catch (error, stackTrace) {
      AppLog.d('❌ CREATE GAME: Save failed: ${error.code}');
      AppLog.d('❌ CREATE GAME: Stack trace: $stackTrace');
      return CreateGameSubmitResult.failure(
        CreateGameSubmitFailure.saveFailed,
        message: 'Failed to save game. Please try again.',
      );
    } catch (error, stackTrace) {
      AppLog.d('❌ CREATE GAME: Unexpected failure: $error');
      AppLog.d('❌ CREATE GAME: Stack trace: $stackTrace');
      return CreateGameSubmitResult.failure(
        CreateGameSubmitFailure.unknown,
        message: 'Failed to create game. Please try again.',
      );
    }

    final numExistingFriends = 4 - formData.numPlayers - 1;
    final nextRoute = numExistingFriends <= 0
        ? CreateGameNextRoute.gamesList
        : CreateGameNextRoute.playerList;

    return CreateGameSubmitResult.success(
      gameRef: gameRef,
      nextRoute: nextRoute,
    );
  }

  // -- Pure business logic (no widget dependencies) --

  static const List<int> _mondayFirstDayOrder = [1, 2, 3, 4, 5, 6, 0];

  void ensureValidEligibility(
      CreateGameFormData formData, String? userGender) {
    final validValues = getFilteredEligibilityOptions(userGender)
        .map((o) => o['value'])
        .toSet();
    if (!validValues.contains(formData.playerEligibility)) {
      formData.playerEligibility = 'open_to_all';
    }
  }

  List<Map<String, dynamic>> getFilteredEligibilityOptions(
      String? userGender) {
    if (userGender == 'Male') {
      return kCreateGameEligibilityOptions
          .where((opt) => opt['value'] != 'women_only')
          .toList();
    } else if (userGender == 'Female') {
      return kCreateGameEligibilityOptions
          .where((opt) => opt['value'] != 'men_only')
          .toList();
    } else {
      return kCreateGameEligibilityOptions
          .where((opt) => opt['value'] == 'open_to_all')
          .toList();
    }
  }

  List<int> getAvailableDays(CreateGameFormData formData) {
    final now = DateTime.now();
    switch (formData.flexibleWeek) {
      case 'this_week':
        final todayDayIndex = now.weekday == DateTime.sunday ? 0 : now.weekday;
        final todayPosition = _mondayFirstDayOrder.indexOf(todayDayIndex);
        return _mondayFirstDayOrder.sublist(todayPosition);
      case 'this_weekend':
        return [6, 0];
      case 'next_week':
      case 'next_2_weeks':
      default:
        return [0, 1, 2, 3, 4, 5, 6];
    }
  }
}
