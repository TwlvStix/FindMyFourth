import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import '/backend/backend.dart';
import '/core/utils/app_log.dart';
import '/core/exceptions/app_exceptions.dart';
import '/models/player_eligibility.dart';
import '/services/game_eligibility_service.dart';

/// GameService provides stateless, centralized access to game data in Firestore
///
/// This service follows the established pattern from ChatService:
/// - Static methods only (no instance state)
/// - Pure functions without UI dependencies
/// - Firestore error handling with try-catch, debugPrint, and rethrow
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
  /// Returns Stream<List<GamesRecord>> for reactive updates
  Stream<List<GamesRecord>> queryAvailableGames({
    String? courseFilter,
    String? styleFilter,
    DateTime? dateFilter,
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
        final ordered = query.orderBy('date');
        return ordered.snapshots().map((snapshot) =>
            snapshot.docs.map((doc) => GamesRecord.fromSnapshot(doc)).toList());
      }

      Stream<List<GamesRecord>> publicOnlyStream() {
        final publicValuesQuery = baseQuery.where(
          'friend_game',
          whereIn: ['Public', 'public'],
        );
        final publicNullQuery = baseQuery.where(
          'friend_game',
          isNull: true,
        );

        return Rx.combineLatest2(
          streamFromQuery(publicValuesQuery),
          streamFromQuery(publicNullQuery),
          (List<GamesRecord> a, List<GamesRecord> b) {
            final merged = <String, GamesRecord>{};
            for (final record in a) {
              merged[record.reference.id] = record;
            }
            for (final record in b) {
              merged[record.reference.id] = record;
            }
            final mergedList = merged.values.toList();
            mergedList.sort((left, right) {
              final leftDate = left.date ?? DateTime(1970);
              final rightDate = right.date ?? DateTime(1970);
              return leftDate.compareTo(rightDate);
            });
            return mergedList;
          },
        );
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
  /// Returns Stream<GamesRecord?> that emits null if game doesn't exist
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

      await _firestore.collection('games').doc(gameId).update({
        'joined_players': FieldValue.arrayRemove([userRef, userId]),
      });
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
}
