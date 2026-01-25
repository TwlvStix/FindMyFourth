import 'package:flutter/foundation.dart';

import '/backend/backend.dart';
import '/core/exceptions/app_exceptions.dart';

/// GameService provides stateless, centralized access to game data in Firestore
///
/// This service follows the established pattern from ChatService:
/// - Static methods only (no instance state)
/// - Pure functions without UI dependencies
/// - Firestore error handling with try-catch, debugPrint, and rethrow
/// - No business logic (filtering, vibe matching) - that stays in providers
///
/// Usage:
/// - Call directly: GameService.getGameById(gameId)
/// - Or wrap with GameProvider for caching and state management
class GameService {
  // Private constructor to prevent instantiation (static-only class)
  GameService._();

  /// Query available games to join (open, public games)
  ///
  /// Filters:
  /// - courseFilter: filter by course name
  /// - styleFilter: filter by game style
  /// - dateFilter: filter by games on or after this date
  ///
  /// Returns Stream<List<GamesRecord>> for reactive updates
  static Stream<List<GamesRecord>> queryAvailableGames({
    String? courseFilter,
    String? styleFilter,
    DateTime? dateFilter,
  }) {
    try {
      Query query = FirebaseFirestore.instance
          .collection('games');

      if (courseFilter != null && courseFilter.isNotEmpty) {
        query = query.where('course', isEqualTo: courseFilter);
      }
      if (styleFilter != null && styleFilter.isNotEmpty) {
        query = query.where('style_game', isEqualTo: styleFilter);
      }
      if (dateFilter != null) {
        query = query.where('date', isGreaterThanOrEqualTo: dateFilter);
      }

      // Order by date ascending (soonest games first)
      query = query.orderBy('date');

      return query.snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => GamesRecord.fromSnapshot(doc)).toList());
    } on FirebaseException catch (e) {
      debugPrint(
          'GameService.queryAvailableGames error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Query all games the user has joined
  ///
  /// Returns games where userId is in joined_players array
  /// Ordered by date descending (most recent first)
  static Stream<List<GamesRecord>> queryUserGames(String userId) {
    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      return FirebaseFirestore.instance
          .collection('games')
          .where('joined_players', arrayContains: userRef)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => GamesRecord.fromSnapshot(doc))
              .toList());
    } on FirebaseException catch (e) {
      debugPrint('GameService.queryUserGames error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Get a single game by ID
  ///
  /// Returns null if game doesn't exist
  static Future<GamesRecord?> getGameById(String gameId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('games')
          .doc(gameId)
          .get();
      return doc.exists ? GamesRecord.fromSnapshot(doc) : null;
    } on FirebaseException catch (e) {
      debugPrint('GameService.getGameById error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Stream a single game by ID for reactive updates
  ///
  /// Returns Stream<GamesRecord?> that emits null if game doesn't exist
  static Stream<GamesRecord?> watchGameById(String gameId) {
    try {
      return FirebaseFirestore.instance
          .collection('games')
          .doc(gameId)
          .snapshots()
          .map((doc) => doc.exists ? GamesRecord.fromSnapshot(doc) : null);
    } on FirebaseException catch (e) {
      debugPrint('GameService.watchGameById error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Join a game (add user to joined_players array)
  ///
  /// Uses Firestore transaction to atomically check capacity and duplicate membership
  /// before adding user. This prevents race conditions where multiple users can
  /// join simultaneously and exceed max capacity.
  ///
  /// Throws GameOperationException with specific codes:
  /// - 'game-not-found': Game doesn't exist
  /// - 'game-full': Already at max capacity
  /// - 'already-joined': User already in joined_players
  /// - 'transaction-conflict': Transaction aborted (retry needed)
  ///
  /// Updates:
  /// - joined_players: adds userId DocumentReference
  /// - updated_at: server timestamp
  static Future<void> joinGame(String gameId, String userId) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Read game document
        final gameRef = FirebaseFirestore.instance.collection('games').doc(gameId);
        final gameDoc = await transaction.get(gameRef);

        if (!gameDoc.exists) {
          throw GameOperationException('Game not found', code: 'game-not-found');
        }

        final game = GamesRecord.fromSnapshot(gameDoc);
        final currentPlayers = game.joinedPlayers.length;
        final maxPlayers = game.maxPlayers;

        // 2. Check capacity atomically
        if (currentPlayers >= maxPlayers) {
          throw GameOperationException('Game is full', code: 'game-full');
        }

        // 3. Check not already joined
        final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
        final rawJoinedPlayers = (gameDoc.data() as Map<String, dynamic>?)?['joined_players'];
        final alreadyJoined = rawJoinedPlayers is List &&
            rawJoinedPlayers.any((entry) => entry == userRef || entry == userId);
        if (alreadyJoined) {
          throw GameOperationException('Already joined this game', code: 'already-joined');
        }

        // 4. Atomic update - only if checks pass
        transaction.update(gameRef, {
          'joined_players': FieldValue.arrayUnion([userRef]),
        });
      });

      debugPrint('GameService.joinGame: User $userId joined game $gameId');
    } on GameOperationException {
      // Re-throw our custom exceptions as-is
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('GameService.joinGame error: ${e.code} - ${e.message}');
      if (e.code == 'aborted') {
        throw GameOperationException('Game capacity changed, please try again', code: 'transaction-conflict');
      }
      rethrow;
    }
  }

  /// Leave a game (remove user from joined_players array)
  ///
  /// Updates:
  /// - joined_players: removes userId DocumentReference
  /// - updated_at: server timestamp
  static Future<void> leaveGame(String gameId, String userId) async {
    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      await FirebaseFirestore.instance.collection('games').doc(gameId).update({
        'joined_players': FieldValue.arrayRemove([userRef, userId]),
      });
    } on FirebaseException catch (e) {
      debugPrint('GameService.leaveGame error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Update game details (partial update)
  ///
  /// Automatically adds updated_at timestamp to updates
  static Future<void> updateGameDetails(
      String gameId, Map<String, dynamic> updates) async {
    try {
      final updateData = Map<String, dynamic>.from(updates);
      updateData['updated_at'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('games')
          .doc(gameId)
          .update(updateData);
    } on FirebaseException catch (e) {
      debugPrint(
          'GameService.updateGameDetails error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Create a new game
  ///
  /// Returns DocumentReference to the created game
  static Future<DocumentReference> createGame(
      Map<String, dynamic> gameData) async {
    try {
      final gameRef = FirebaseFirestore.instance.collection('games').doc();

      final createData = Map<String, dynamic>.from(gameData);
      createData['created_at'] = FieldValue.serverTimestamp();
      createData['updated_at'] = FieldValue.serverTimestamp();

      // Set defaults if not provided
      createData['isCancelled'] ??= false;
      createData['status'] ??= 'open';

      await gameRef.set(createData);
      return gameRef;
    } on FirebaseException catch (e) {
      debugPrint('GameService.createGame error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Cancel a game (soft delete)
  ///
  /// Updates:
  /// - isCancelled: true
  /// - status: 'cancelled'
  /// - updated_at: server timestamp
  static Future<void> cancelGame(String gameId) async {
    try {
      await FirebaseFirestore.instance.collection('games').doc(gameId).update({
        'isCancelled': true,
        'status': 'cancelled',
        'updated_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('GameService.cancelGame error: ${e.code} - ${e.message}');
      rethrow;
    }
  }
}
