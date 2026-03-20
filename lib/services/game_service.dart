import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import '/backend/backend.dart';
import '/core/utils/app_log.dart';
import '/core/exceptions/app_exceptions.dart';
import '/models/player_eligibility.dart';
import '/services/game_eligibility_service.dart';

/// Result of a paginated game query.
class GamesPage {
  final List<GamesRecord> games;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  const GamesPage({required this.games, this.lastDocument, required this.hasMore});
}

/// GameService provides stateless, centralized access to game data in Firestore
///
/// This service follows the established service pattern:
/// - Static methods only (no instance state)
/// - Pure functions without UI dependencies
/// - Firestore error handling with try-catch, AppLog.d(), and rethrow
/// - No business logic (filtering, vibe matching) - that stays in providers
///
/// Usage:
/// - Create instance: final service = GameService();
/// - Or inject for testing: GameService(firestore: mockFirestore)
/// - Wrap with GameProvider for caching and state management
class GameService {
  GameService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Query available games to join (open, public games)
  ///
  /// Filters:
  /// - courseFilter: filter by course name
  /// - styleFilter: filter by game style
  /// - dateFilter: filter by games on or after this date
  ///
  /// Returns `Stream<List<GamesRecord>>` for reactive updates
  Stream<List<GamesRecord>> queryAvailableGames({
    String? courseFilter,
    String? styleFilter,
    DateTime? dateFilter,
    int? limit,
  }) {
    try {
      Query baseQuery = _firestore.collection('games');

      if (courseFilter != null && courseFilter.isNotEmpty) {
        baseQuery = baseQuery.where('course', isEqualTo: courseFilter);
      }
      if (styleFilter != null && styleFilter.isNotEmpty) {
        baseQuery = baseQuery.where('style_game', isEqualTo: styleFilter);
      }
      if (dateFilter != null) {
        baseQuery = baseQuery.where('date', isGreaterThanOrEqualTo: dateFilter);
      }

      Stream<List<GamesRecord>> streamFromQuery(Query query) {
        Query ordered = query.orderBy('date');
        if (limit != null) {
          ordered = ordered.limit(limit);
        }
        return ordered.snapshots().map((snapshot) =>
            snapshot.docs.map((doc) => GamesRecord.fromSnapshot(doc)).toList());
      }

      Stream<List<GamesRecord>> publicOnlyStream() {
        final publicQuery = baseQuery.where(
          'friend_game',
          isEqualTo: 'public',
        );
        return streamFromQuery(publicQuery);
      }

      return FirebaseAuth.instance.authStateChanges().switchMap((user) {
        if (user == null) {
          return publicOnlyStream();
        }
        return streamFromQuery(baseQuery);
      });
    } on FirebaseException catch (e) {
      AppLog.d(
          'GameService.queryAvailableGames error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Query a page of available games (one-time fetch for pagination).
  ///
  /// Uses the same query construction as [queryAvailableGames] but with
  /// `.get()` instead of `.snapshots()` for pages beyond the first.
  Future<GamesPage> queryAvailableGamesPage({
    String? courseFilter,
    String? styleFilter,
    DateTime? dateFilter,
    int pageSize = 50,
    DocumentSnapshot? startAfterDocument,
  }) async {
    try {
      Query baseQuery = _firestore.collection('games');

      if (courseFilter != null && courseFilter.isNotEmpty) {
        baseQuery = baseQuery.where('course', isEqualTo: courseFilter);
      }
      if (styleFilter != null && styleFilter.isNotEmpty) {
        baseQuery = baseQuery.where('style_game', isEqualTo: styleFilter);
      }
      if (dateFilter != null) {
        baseQuery = baseQuery.where('date', isGreaterThanOrEqualTo: dateFilter);
      }

      Query query = baseQuery.orderBy('date').limit(pageSize);

      if (startAfterDocument != null) {
        query = query.startAfterDocument(startAfterDocument);
      }

      final snapshot = await query.get();
      final games = snapshot.docs
          .map((doc) => GamesRecord.fromSnapshot(doc))
          .toList();

      return GamesPage(
        games: games,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length >= pageSize,
      );
    } on FirebaseException catch (e) {
      AppLog.d(
          'GameService.queryAvailableGamesPage error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Query public games for guest (unauthenticated) browsing.
  ///
  /// Uses only a single-field filter on [friend_game] to avoid requiring
  /// a composite index. Filtering for future dates and sorting by date
  /// is handled client-side by the caller.
  Stream<List<GamesRecord>> queryPublicGames() {
    return _firestore
        .collection('games')
        .where('friend_game', isEqualTo: 'public')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GamesRecord.fromSnapshot(doc)).toList());
  }

  /// Query all games the user has joined
  ///
  /// Returns games where userId is in joined_players array
  /// Ordered by date descending (most recent first)
  Stream<List<GamesRecord>> queryUserGames(String userId) {
    try {
      final normalizedUserId = userId.trim();
      if (normalizedUserId.isEmpty) {
        AppLog.d('GameService.queryUserGames: Empty userId, returning empty stream');
        return Stream.value(<GamesRecord>[]);
      }
      final userRef =
          _firestore.collection('users').doc(normalizedUserId);
      return FirebaseAuth.instance.authStateChanges().switchMap((user) {
        if (user == null || user.uid != normalizedUserId) {
          return Stream.value(<GamesRecord>[]);
        }
        return _firestore
            .collection('games')
            .where('joined_players', arrayContains: userRef)
            .orderBy('date', descending: true)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => GamesRecord.fromSnapshot(doc))
                .toList());
      });
    } on FirebaseException catch (e) {
      AppLog.d('GameService.queryUserGames error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Get a single game by ID
  ///
  /// Returns null if game doesn't exist
  Future<GamesRecord?> getGameById(String gameId) async {
    try {
      final doc = await _firestore
          .collection('games')
          .doc(gameId)
          .get();
      return doc.exists ? GamesRecord.fromSnapshot(doc) : null;
    } on FirebaseException catch (e) {
      AppLog.d('GameService.getGameById error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Stream a single game by ID for reactive updates
  ///
  /// Returns `Stream<GamesRecord?>` that emits null if game doesn't exist
  Stream<GamesRecord?> watchGameById(String gameId) {
    try {
      return _firestore
          .collection('games')
          .doc(gameId)
          .snapshots()
          .map((doc) => doc.exists ? GamesRecord.fromSnapshot(doc) : null);
    } on FirebaseException catch (e) {
      AppLog.d('GameService.watchGameById error: ${e.code} - ${e.message}');
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
  Future<void> joinGame(String gameId, String userId, {String? userGender}) async {
    try {
      // Check if user previously cancelled this game day-of (struck from game)
      final userRef = _firestore.collection('users').doc(userId);
      final gameRef = _firestore.collection('games').doc(gameId);
      final cancelQuery = await _firestore
          .collection('cancellation_records')
          .where('player_ref', isEqualTo: userRef)
          .where('game_ref', isEqualTo: gameRef)
          .where('tier', isEqualTo: 'day_of')
          .limit(1)
          .get();
      if (cancelQuery.docs.isNotEmpty) {
        throw GameOperationException(
          'You cannot rejoin a game you cancelled from on the day of play',
          code: 'struck-from-game',
        );
      }

      await _firestore.runTransaction((transaction) async {
        // 1. Read game document
        final gameRef =
            _firestore.collection('games').doc(gameId);
        final gameDoc = await transaction.get(gameRef);

        if (!gameDoc.exists) {
          throw GameOperationException('Game not found',
              code: 'game-not-found');
        }

        final game = GamesRecord.fromSnapshot(gameDoc);

        // Check if game is cancelled
        if (game.isCancelled == true) {
          throw GameOperationException(
            'This game has been cancelled',
            code: 'game-cancelled',
          );
        }

        final currentPlayers = game.joinedPlayers.length;
        final maxPlayers = game.maxPlayers;

        // 2. Check capacity atomically
        if (currentPlayers >= maxPlayers) {
          throw GameOperationException('Game is full', code: 'game-full');
        }

        // 2b. Check player eligibility
        final playerEligibility = PlayerEligibilityExtension.fromFirestoreValue(
          gameDoc.data()?['player_eligibility'] as String?,
        );
        final eligibilityResult = checkPlayerEligibility(
          eligibility: playerEligibility,
          userGender: userGender,
        );
        if (!eligibilityResult.allowed) {
          final restrictionType = playerEligibility == PlayerEligibility.womenOnly
              ? 'women'
              : 'men';
          throw GameOperationException(
            'This round is restricted to $restrictionType only',
            code: 'gender-restricted',
          );
        }

        // 3. Check not already joined
        final userRef =
            _firestore.collection('users').doc(userId);
        final rawJoinedPlayers =
            (gameDoc.data())?['joined_players'];
        final alreadyJoined = rawJoinedPlayers is List &&
            rawJoinedPlayers
                .any((entry) => entry == userRef || entry == userId);
        if (alreadyJoined) {
          throw GameOperationException('Already joined this game',
              code: 'already-joined');
        }

        // 4. Atomic update - only if checks pass
        transaction.update(gameRef, {
          'joined_players': FieldValue.arrayUnion([userRef]),
        });
      });

      // Create game_participants doc for the joining player
      // (reuse userRef/gameRef declared above the transaction)
      await _createParticipantDoc(
        gameRef: gameRef,
        userRef: userRef,
        role: 'player',
      );

      AppLog.d('GameService.joinGame: User $userId joined game $gameId');
    } on GameOperationException {
      // Re-throw our custom exceptions as-is
      rethrow;
    } on FirebaseException catch (e) {
      AppLog.d('GameService.joinGame error: ${e.code} - ${e.message}');
      if (e.code == 'aborted') {
        throw GameOperationException('Game capacity changed, please try again',
            code: 'transaction-conflict');
      }
      rethrow;
    }
  }

  /// Leave a game (remove user from joined_players array)
  ///
  /// Updates:
  /// - joined_players: removes userId DocumentReference
  /// - updated_at: server timestamp
  Future<void> leaveGame(String gameId, String userId) async {
    try {
      final userRef =
          _firestore.collection('users').doc(userId);

      final gameRef = _firestore.collection('games').doc(gameId);

      await gameRef.update({
        'joined_players': FieldValue.arrayRemove([userRef, userId]),
      });

      // Mark the game_participants doc as cancelled
      await _cancelParticipantDoc(gameRef: gameRef, userRef: userRef);
    } on FirebaseException catch (e) {
      AppLog.d('GameService.leaveGame error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Update game details (partial update)
  ///
  /// Automatically adds updated_at timestamp to updates
  Future<void> updateGameDetails(
      String gameId, Map<String, dynamic> updates) async {
    try {
      final updateData = Map<String, dynamic>.from(updates);
      updateData['updated_at'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('games')
          .doc(gameId)
          .update(updateData);
    } on FirebaseException catch (e) {
      AppLog.d('GameService.updateGameDetails error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Create a new game
  ///
  /// Returns DocumentReference to the created game
  Future<DocumentReference> createGame(
      Map<String, dynamic> gameData) async {
    try {
      final gameRef = _firestore.collection('games').doc();

      final createData = Map<String, dynamic>.from(gameData);
      createData['created_at'] = FieldValue.serverTimestamp();
      createData['updated_at'] = FieldValue.serverTimestamp();

      // Set defaults if not provided
      createData['isCancelled'] ??= false;
      createData['status'] ??= 'open';

      await gameRef.set(createData);

      // Create game_participants doc for the host
      final hostRef = createData['userRef'] as DocumentReference?;
      if (hostRef != null) {
        await _createParticipantDoc(
          gameRef: gameRef,
          userRef: hostRef,
          role: 'host',
        );
      }

      return gameRef;
    } on FirebaseException catch (e) {
      AppLog.d('GameService.createGame error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Cancel a game (soft delete)
  ///
  /// Updates:
  /// - isCancelled: true
  /// - status: 'cancelled'
  /// - cancelled_at: server timestamp (for deletion scheduling)
  /// - updated_at: server timestamp
  Future<void> cancelGame(String gameId) async {
    try {
      await _firestore.collection('games').doc(gameId).update({
        'isCancelled': true,
        'status': 'cancelled',
        'cancelled_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      AppLog.d('GameService.cancelGame error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Create a game_participants document for a player or host.
  Future<void> _createParticipantDoc({
    required DocumentReference gameRef,
    required DocumentReference userRef,
    required String role,
  }) async {
    try {
      await _firestore.collection('game_participants').add({
        'game_ref': gameRef,
        'user_ref': userRef,
        'role': role,
        'status': 'joined',
        'joined_at': FieldValue.serverTimestamp(),
      });
      AppLog.d('✅ GameService._createParticipantDoc: Created $role doc for ${userRef.id} in game ${gameRef.id}');
    } on FirebaseException catch (e) {
      AppLog.d('❌ GameService._createParticipantDoc error: ${e.code} - ${e.message}');
      // Non-critical: don't fail the parent operation
    }
  }

  /// Update game_participants status to cancelled when a player leaves.
  Future<void> _cancelParticipantDoc({
    required DocumentReference gameRef,
    required DocumentReference userRef,
  }) async {
    try {
      final query = await _firestore
          .collection('game_participants')
          .where('game_ref', isEqualTo: gameRef)
          .where('user_ref', isEqualTo: userRef)
          .where('status', isEqualTo: 'joined')
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'status': 'cancelled',
          'cancelled_at': FieldValue.serverTimestamp(),
        });
        AppLog.d('✅ GameService._cancelParticipantDoc: Cancelled participant ${userRef.id} in game ${gameRef.id}');
      }
    } on FirebaseException catch (e) {
      AppLog.d('❌ GameService._cancelParticipantDoc error: ${e.code} - ${e.message}');
      // Non-critical: don't fail the parent operation
    }
  }

  /// Remove a player from a game (owner action)
  ///
  /// For registered players: removes from joined_players array
  /// For guest players: removes from guest_players array
  ///
  /// Throws GameOperationException if game not found
  Future<void> removePlayer(
    String gameId, {
    String? playerId,
    String? guestName,
    required bool isGuest,
  }) async {
    final normalizedPlayerId = playerId?.trim();
    final normalizedGuestName = guestName?.trim();
    if (isGuest) {
      if (normalizedGuestName == null || normalizedGuestName.isEmpty) {
        throw GameOperationException(
          'Guest name is required when removing a guest player.',
          code: 'invalid-argument',
        );
      }
    } else {
      if (normalizedPlayerId == null || normalizedPlayerId.isEmpty) {
        throw GameOperationException(
          'Player ID is required when removing a registered player.',
          code: 'invalid-argument',
        );
      }
    }

    try {
      final gameRef = _firestore.collection('games').doc(gameId);

      if (isGuest) {
        await gameRef.update({
          'guest_players': FieldValue.arrayRemove([normalizedGuestName]),
        });
        AppLog.d(
          'GameService.removePlayer: Removed guest "$normalizedGuestName" from game $gameId',
        );
      } else {
        final playerRef = _firestore.collection('users').doc(normalizedPlayerId);
        await gameRef.update({
          'joined_players': FieldValue.arrayRemove([playerRef]),
        });
        AppLog.d(
          'GameService.removePlayer: Removed player $normalizedPlayerId from game $gameId',
        );
      }
    } on FirebaseException catch (e) {
      AppLog.d('GameService.removePlayer error: ${e.code} - ${e.message}');
      rethrow;
    }
  }
}
