import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/exceptions/app_exceptions.dart';
import '/core/utils/app_log.dart';
import '/models/join_request.dart';

/// Service for managing join request CRUD operations
///
/// Join requests are stored as subcollections under each game:
/// `games/{gameId}/join_requests/{requestId}`
///
/// Follows the established service pattern:
/// - Instance class with optional FirebaseFirestore injection for testability
/// - Handles only Firestore reads/writes
/// - Errors are caught, logged, and rethrown
class JoinRequestService {
  JoinRequestService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Get reference to join_requests subcollection for a game
  CollectionReference<Map<String, dynamic>> _requestsCollection(
          String gameId) =>
      _firestore.collection('games').doc(gameId).collection('join_requests');

  /// Create a new join request
  ///
  /// Returns the created [JoinRequest] with the generated document ID.
  /// Throws [JoinRequestException] if creation fails.
  Future<JoinRequest> createJoinRequest({
    required String gameId,
    required String requesterId,
    required String ownerId,
    required double requesterVibeScore,
    required int vibeFloor,
  }) async {
    try {
      final docRef = _requestsCollection(gameId).doc();
      final request = JoinRequest(
        id: docRef.id,
        gameId: gameId,
        requesterId: requesterId,
        ownerId: ownerId,
        requesterVibeScore: requesterVibeScore,
        vibeFloor: vibeFloor,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await docRef.set(request.toMap());
      AppLog.d('✅ JoinRequestService: Created join request ${docRef.id}');
      return request;
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ JoinRequestService.createJoinRequest error: ${e.code} - ${e.message}');
      throw JoinRequestException(
        'Failed to create join request',
        code: e.code,
        cause: e,
      );
    }
  }

  /// Get all pending join requests for a game
  ///
  /// Requires [ownerId] to satisfy Firestore security rules which mandate
  /// that the query includes ownerId == auth.uid for read access.
  ///
  /// Returns requests sorted by creation time (oldest first).
  Future<List<JoinRequest>> getJoinRequestsForGame(
    String gameId,
    String ownerId,
  ) async {
    try {
      final snapshot = await _requestsCollection(gameId)
          .where('ownerId', isEqualTo: ownerId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: false)
          .get();

      final requests =
          snapshot.docs.map((doc) => JoinRequest.fromDoc(doc)).toList();
      AppLog.d(
          '📖 JoinRequestService: Found ${requests.length} pending requests for game $gameId');
      return requests;
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ JoinRequestService.getJoinRequestsForGame error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Get all pending join requests for a user across all games
  ///
  /// Uses a collection group query on `join_requests` subcollections.
  /// Requires a Firestore composite index on (requesterId, status, createdAt).
  Future<List<JoinRequest>> getJoinRequestsForUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('join_requests')
          .where('requesterId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final requests =
          snapshot.docs.map((doc) => JoinRequest.fromDoc(doc)).toList();
      AppLog.d(
          '📖 JoinRequestService: Found ${requests.length} pending requests for user $userId');
      return requests;
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ JoinRequestService.getJoinRequestsForUser error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Update join request status (approve or deny)
  ///
  /// Sets the status and respondedAt timestamp.
  Future<void> updateRequestStatus(
    String gameId,
    String requestId,
    JoinRequestStatus status,
  ) async {
    try {
      await _requestsCollection(gameId).doc(requestId).update({
        'status': status.key,
        'respondedAt': FieldValue.serverTimestamp(),
      });
      AppLog.d(
          '✅ JoinRequestService: Updated request $requestId to ${status.key}');
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ JoinRequestService.updateRequestStatus error: ${e.code} - ${e.message}');
      throw JoinRequestException(
        'Failed to update join request',
        code: e.code,
        cause: e,
      );
    }
  }

  /// Approve a join request atomically
  ///
  /// This method runs a Firestore transaction to:
  /// 1. Check the game has open spots
  /// 2. Update request status to approved
  /// 3. Add the player to the game's joined_players array
  ///
  /// Throws [GameOperationException] with code 'game-full' if no spots available.
  /// Throws [JoinRequestException] on other failures.
  Future<void> approveRequest({
    required String gameId,
    required String requestId,
    required String requesterId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final gameRef = _firestore.collection('games').doc(gameId);
        final requestRef = _requestsCollection(gameId).doc(requestId);

        // 1. Read game and request documents
        final gameDoc = await transaction.get(gameRef);
        final requestDoc = await transaction.get(requestRef);

        if (!gameDoc.exists) {
          throw GameOperationException(
            'Game not found',
            code: 'game-not-found',
          );
        }
        if (!requestDoc.exists) {
          throw JoinRequestException(
            'Request not found',
            code: 'request-not-found',
          );
        }

        final gameData = gameDoc.data()!;
        final joinedPlayers = (gameData['joined_players'] as List?) ?? [];
        final maxPlayers = gameData['max_players'] as int? ?? 4;

        // 2. Check capacity
        if (joinedPlayers.length >= maxPlayers) {
          throw GameOperationException(
            'Round is full',
            code: 'game-full',
          );
        }

        // 3. Update request status to approved
        transaction.update(requestRef, {
          'status': 'approved',
          'respondedAt': FieldValue.serverTimestamp(),
        });

        // 4. Add player to game
        final userRef = _firestore.collection('users').doc(requesterId);
        transaction.update(gameRef, {
          'joined_players': FieldValue.arrayUnion([userRef]),
        });
      });

      AppLog.d(
          '✅ JoinRequestService: Approved request $requestId, added player $requesterId to game $gameId');
    } on GameOperationException {
      rethrow;
    } on JoinRequestException {
      rethrow;
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ JoinRequestService.approveRequest error: ${e.code} - ${e.message}');
      throw JoinRequestException(
        'Failed to approve join request',
        code: e.code,
        cause: e,
      );
    }
  }

  /// Check if a pending request already exists for this user and game
  ///
  /// Returns the existing request if found, null otherwise.
  Future<JoinRequest?> checkExistingRequest(
      String gameId, String userId) async {
    try {
      final snapshot = await _requestsCollection(gameId)
          .where('requesterId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }
      return JoinRequest.fromDoc(snapshot.docs.first);
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ JoinRequestService.checkExistingRequest error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Get any existing request (pending OR denied) for this user and game
  ///
  /// Unlike [checkExistingRequest], this returns requests in any status,
  /// not just pending. Used to show appropriate button state on the game
  /// detail screen (e.g., "Request pending" or "Request declined").
  ///
  /// Returns the most recent request if found, null otherwise.
  Future<JoinRequest?> getRequestForGame(String gameId, String userId) async {
    try {
      final snapshot = await _requestsCollection(gameId)
          .where('requesterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }
      final request = JoinRequest.fromDoc(snapshot.docs.first);
      AppLog.d(
          '📖 JoinRequestService: Found request for user $userId in game $gameId (status: ${request.status.key})');
      return request;
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ JoinRequestService.getRequestForGame error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Cancel/delete a pending join request
  ///
  /// Used when the requester wants to withdraw their request.
  Future<void> cancelJoinRequest(String gameId, String requestId) async {
    try {
      await _requestsCollection(gameId).doc(requestId).delete();
      AppLog.d('✅ JoinRequestService: Cancelled request $requestId');
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ JoinRequestService.cancelJoinRequest error: ${e.code} - ${e.message}');
      throw JoinRequestException(
        'Failed to cancel join request',
        code: e.code,
        cause: e,
      );
    }
  }

  /// Get a specific join request by ID
  Future<JoinRequest?> getJoinRequest(String gameId, String requestId) async {
    try {
      final doc = await _requestsCollection(gameId).doc(requestId).get();
      if (!doc.exists) return null;
      return JoinRequest.fromDoc(doc);
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ JoinRequestService.getJoinRequest error: ${e.code} - ${e.message}');
      rethrow;
    }
  }
}
