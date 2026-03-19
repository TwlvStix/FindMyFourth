import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/core/utils/app_log.dart';
import '/models/course.dart';
import '/models/game.dart';
import '/services/chat_lifecycle_service.dart';
import '/services/create_game_service.dart';
import '/services/player_search_service.dart';
import '/services/rematch_service.dart';

/// Result of a rebook operation.
class RebookResult {
  const RebookResult._({
    required this.success,
    this.gameRef,
    this.errorMessage,
  });

  factory RebookResult.succeeded(DocumentReference gameRef) =>
      RebookResult._(success: true, gameRef: gameRef);

  factory RebookResult.failed(String message) =>
      RebookResult._(success: false, errorMessage: message);

  final bool success;
  final DocumentReference? gameRef;
  final String? errorMessage;
}

/// Orchestrates the full rebook flow: build form data, create chat,
/// create game, and add original players.
class RebookService {
  RebookService({
    CreateGameService? createGameService,
    PlayerSearchService? playerSearchService,
    ChatLifecycleService? chatService,
    RematchService? rematchService,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _createGameService = createGameService ?? CreateGameService(),
        _playerSearchService = playerSearchService ?? PlayerSearchService(),
        _chatService = chatService ?? ChatLifecycleService(),
        _rematchService = rematchService ?? RematchService(),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final CreateGameService _createGameService;
  final PlayerSearchService _playerSearchService;
  final ChatLifecycleService _chatService;
  final RematchService _rematchService;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Rebooks a completed game with the same settings and players.
  ///
  /// If [overrideCourse] is provided, replaces the course from the source game.
  /// Returns [RebookResult] with the new game reference on success.
  Future<RebookResult> rebookGame(
    Game sourceGame,
    DateTime selectedDate, {
    Course? overrideCourse,
  }) async {
    try {
      // Build form data from source game
      final formData = overrideCourse != null
          ? _rematchService.buildSwitchCourseForm(sourceGame)
          : _rematchService.buildRematchForm(sourceGame);

      // Set the selected date
      formData.datePicked = selectedDate;

      // Override course if provided
      if (overrideCourse != null) {
        formData.setSelectedCourse(overrideCourse);
      }

      // Get current user
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        return RebookResult.failed('Not signed in.');
      }
      final userRef = _firestore.collection('users').doc(uid);

      // Collect original players (excluding the current user / new host)
      final nonHostPlayerUids = sourceGame.joinedPlayers
          .where((ref) => ref.id != uid)
          .map((ref) => ref.id)
          .toList();

      // Validate each player still exists (max 3 to check)
      final validPlayerUids = <String>[];
      for (final playerUid in nonHostPlayerUids) {
        try {
          final doc = await _firestore
              .collection('users')
              .doc(playerUid)
              .get();
          if (doc.exists) {
            validPlayerUids.add(playerUid);
          } else {
            AppLog.d('📖 RebookService: Skipping deleted player $playerUid');
          }
        } catch (e) {
          AppLog.d('📖 RebookService: Skipping unreachable player $playerUid');
        }
      }

      // Set pre-added players on form data so they're included in the
      // initial game document write (atomic creation avoids duplicate
      // notifications from separate onCreate/onUpdate triggers).
      formData.preAddedPlayerUids = validPlayerUids;
      formData.preAddedPlayerRefs = validPlayerUids
          .map((pUid) => _firestore.collection('users').doc(pUid))
          .toList();
      formData.preAddedGuestNames = sourceGame.guestPlayers;

      // Generate game ref first (chat needs the game ID)
      final gameRef = _createGameService.generateGameRef();

      // Create game chat
      final gameName = formData.courseValue ?? 'Game';
      final chatRef = await _chatService.createGameChat(
        createdByUid: uid,
        gameId: gameRef.id,
        gameName: gameName,
      );

      // Create game document (includes pre-added players atomically)
      await _createGameService.createGameWithRef(
        gameRef: gameRef,
        formData: formData,
        uid: uid,
        userRef: userRef,
        chatRef: chatRef,
      );

      // Create participant docs for pre-added players (non-critical)
      await _playerSearchService.createParticipantDocs(
        gameRef: gameRef,
        joinedPlayerUids: validPlayerUids,
        guestPlayers: sourceGame.guestPlayers,
      );

      AppLog.d('✅ RebookService: Game rebooked ${gameRef.id} '
          'with ${validPlayerUids.length} players '
          'and ${sourceGame.guestPlayers.length} guests');

      return RebookResult.succeeded(gameRef);
    } on FirebaseException catch (e) {
      AppLog.d('❌ RebookService.rebookGame: ${e.code} - ${e.message}');
      return RebookResult.failed('Could not create game. Please try again.');
    }
  }
}
