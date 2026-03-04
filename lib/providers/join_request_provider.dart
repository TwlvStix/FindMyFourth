import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '/core/exceptions/app_exceptions.dart';
import '/core/utils/app_log.dart';
import '/models/join_request.dart';
import '/services/join_request_service.dart';

/// JoinRequestProvider manages join request state and provides cached access
///
/// Follows the established provider pattern:
/// - Extends ChangeNotifier
/// - Accepts service via constructor with default
/// - _disposed flag checked before notifyListeners()
/// - Cache with TTL
/// - Debounced notifyListeners() via _scheduleNotify()
class JoinRequestProvider extends ChangeNotifier {
  JoinRequestProvider({
    JoinRequestService? service,
  }) : _service = service ?? JoinRequestService();

  final JoinRequestService _service;

  // Track disposal state for safe async operations
  bool _disposed = false;

  // Debounce timer for notifyListeners
  Timer? _notifyTimer;

  // Cache TTL duration (5 minutes)
  final Duration _cacheTTL = const Duration(minutes: 5);

  // Cache for pending requests by game ID
  final Map<String, List<JoinRequest>> _gameRequestsCache = {};
  final Map<String, DateTime> _gameRequestsCacheTimestamps = {};

  // Cache for pending requests by user ID
  final Map<String, List<JoinRequest>> _userRequestsCache = {};
  final Map<String, DateTime> _userRequestsCacheTimestamps = {};

  // ========================================
  // CACHE GETTERS
  // ========================================

  /// Get cached pending requests for a game
  List<JoinRequest>? getCachedRequestsForGame(String gameId) {
    final timestamp = _gameRequestsCacheTimestamps[gameId];
    if (timestamp == null) return null;
    if (DateTime.now().difference(timestamp) >= _cacheTTL) return null;
    return _gameRequestsCache[gameId];
  }

  /// Get cached pending requests for a user
  List<JoinRequest>? getCachedRequestsForUser(String userId) {
    final timestamp = _userRequestsCacheTimestamps[userId];
    if (timestamp == null) return null;
    if (DateTime.now().difference(timestamp) >= _cacheTTL) return null;
    return _userRequestsCache[userId];
  }

  // ========================================
  // QUERY METHODS
  // ========================================

  /// Get pending join requests for a game (owner view)
  ///
  /// Requires [ownerId] to satisfy Firestore security rules.
  /// Returns cached value if valid, otherwise fetches from Firestore.
  Future<List<JoinRequest>> getPendingRequestsForGame(
    String gameId,
    String ownerId,
  ) async {
    // Return cached if valid
    final cached = getCachedRequestsForGame(gameId);
    if (cached != null) {
      return cached;
    }

    try {
      final requests = await _service.getJoinRequestsForGame(gameId, ownerId);
      _gameRequestsCache[gameId] = requests;
      _gameRequestsCacheTimestamps[gameId] = DateTime.now();
      _scheduleNotify();
      return requests;
    } catch (e) {
      AppLog.d('❌ JoinRequestProvider.getPendingRequestsForGame error: $e');
      rethrow;
    }
  }

  /// Get pending join requests for a user (player view)
  ///
  /// Returns cached value if valid, otherwise fetches from Firestore
  Future<List<JoinRequest>> getMyPendingRequests(String userId) async {
    // Return cached if valid
    final cached = getCachedRequestsForUser(userId);
    if (cached != null) {
      return cached;
    }

    try {
      final requests = await _service.getJoinRequestsForUser(userId);
      _userRequestsCache[userId] = requests;
      _userRequestsCacheTimestamps[userId] = DateTime.now();
      _scheduleNotify();
      return requests;
    } catch (e) {
      AppLog.d('❌ JoinRequestProvider.getMyPendingRequests error: $e');
      rethrow;
    }
  }

  /// Get any existing request (pending or denied) for this user and game
  ///
  /// Unlike [getMyPendingRequests], this returns requests in any status.
  /// Used to determine the join button state on game detail screen:
  /// - pending → "Request pending" (disabled)
  /// - denied → "Request declined" (disabled)
  /// - null → normal "Join round" button
  ///
  /// Not cached since this is a one-off check on screen load.
  Future<JoinRequest?> getExistingRequestForGame(
    String gameId,
    String userId,
  ) async {
    try {
      return await _service.getRequestForGame(gameId, userId);
    } catch (e) {
      AppLog.d('❌ JoinRequestProvider.getExistingRequestForGame error: $e');
      rethrow;
    }
  }

  // ========================================
  // MUTATION METHODS
  // ========================================

  /// Submit a join request for a game
  ///
  /// Creates a new pending request document in Firestore.
  /// Invalidates relevant caches after creation and notifies the owner.
  Future<JoinRequest> submitJoinRequest({
    required String gameId,
    required String playerId,
    required String ownerId,
    required double vibeScore,
    required int vibeFloor,
    String? playerName,
  }) async {
    try {
      final request = await _service.createJoinRequest(
        gameId: gameId,
        requesterId: playerId,
        ownerId: ownerId,
        requesterVibeScore: vibeScore,
        vibeFloor: vibeFloor,
      );
      // Invalidate caches
      _invalidateGameCache(gameId);
      _invalidateUserCache(playerId);

      // Notify owner about new request (fire and forget)
      _notifyNewJoinRequest(gameId, ownerId, playerName ?? 'A player');

      AppLog.d('✅ JoinRequestProvider: Submitted join request ${request.id}');
      return request;
    } catch (e) {
      AppLog.d('❌ JoinRequestProvider.submitJoinRequest error: $e');
      rethrow;
    }
  }

  /// Cancel a pending join request (player withdraws)
  ///
  /// Deletes the request document from Firestore.
  Future<void> cancelJoinRequest({
    required String gameId,
    required String requestId,
    required String userId,
  }) async {
    try {
      await _service.cancelJoinRequest(gameId, requestId);
      // Invalidate caches
      _invalidateGameCache(gameId);
      _invalidateUserCache(userId);
      AppLog.d('✅ JoinRequestProvider: Cancelled request $requestId');
    } catch (e) {
      AppLog.d('❌ JoinRequestProvider.cancelJoinRequest error: $e');
      rethrow;
    }
  }

  /// Respond to a join request (owner approves or denies)
  ///
  /// Updates the request status and respondedAt timestamp.
  Future<void> respondToJoinRequest({
    required String gameId,
    required String requestId,
    required bool approved,
    required String requesterId,
  }) async {
    try {
      final status =
          approved ? JoinRequestStatus.approved : JoinRequestStatus.denied;
      await _service.updateRequestStatus(gameId, requestId, status);
      // Invalidate caches
      _invalidateGameCache(gameId);
      _invalidateUserCache(requesterId);
      AppLog.d(
          '✅ JoinRequestProvider: ${approved ? "Approved" : "Denied"} request $requestId');
    } catch (e) {
      AppLog.d('❌ JoinRequestProvider.respondToJoinRequest error: $e');
      rethrow;
    }
  }

  /// Approve a join request and add the player to the game
  ///
  /// This is a transactional operation that:
  /// 1. Checks for available spots
  /// 2. Updates request status to approved
  /// 3. Adds player to game's joined_players
  /// 4. Chat membership is synced automatically by syncGameChatMembers trigger
  /// 5. Triggers notification to player
  ///
  /// Throws [GameOperationException] with code 'game-full' if no spots available.
  Future<void> approveJoinRequest({
    required String gameId,
    required String requestId,
    required String requesterId,
  }) async {
    try {
      // 1. Atomic approve + add to game
      // Note: Chat membership is synced automatically by syncGameChatMembers trigger
      await _service.approveRequest(
        gameId: gameId,
        requestId: requestId,
        requesterId: requesterId,
      );

      // 2. Invalidate caches
      _invalidateGameCache(gameId);
      _invalidateUserCache(requesterId);

      // 3. Trigger notification (fire and forget)
      _notifyRequestApproved(gameId, requesterId);

      AppLog.d('✅ JoinRequestProvider: Approved request $requestId');
    } on GameOperationException {
      rethrow;
    } catch (e) {
      AppLog.d('❌ JoinRequestProvider.approveJoinRequest error: $e');
      rethrow;
    }
  }

  /// Decline a join request
  ///
  /// Updates the request status to denied and triggers notification.
  Future<void> declineJoinRequest({
    required String gameId,
    required String requestId,
    required String requesterId,
  }) async {
    try {
      await _service.updateRequestStatus(
        gameId,
        requestId,
        JoinRequestStatus.denied,
      );

      // Invalidate caches
      _invalidateGameCache(gameId);
      _invalidateUserCache(requesterId);

      // Trigger notification (fire and forget)
      _notifyRequestDeclined(gameId, requesterId);

      AppLog.d('✅ JoinRequestProvider: Declined request $requestId');
    } catch (e) {
      AppLog.d('❌ JoinRequestProvider.declineJoinRequest error: $e');
      rethrow;
    }
  }

  // ========================================
  // NOTIFICATION HELPERS
  // ========================================

  /// Notify owner about a new join request (fire and forget)
  void _notifyNewJoinRequest(String gameId, String ownerId, String requesterName) {
    FirebaseFunctions.instanceFor(region: 'us-west2')
        .httpsCallable('notifyNewJoinRequest')
        .call({
          'gameId': gameId,
          'ownerId': ownerId,
          'requesterName': requesterName,
        })
        .then((_) => AppLog.d('🔔 JoinRequestProvider: Sent new request notification to owner'))
        .catchError((e) => AppLog.d('❌ JoinRequestProvider: New request notification failed: $e'));
  }

  /// Notify player their request was approved (fire and forget)
  void _notifyRequestApproved(String gameId, String playerId) {
    FirebaseFunctions.instanceFor(region: 'us-west2')
        .httpsCallable('notifyJoinRequestApproved')
        .call({
          'gameId': gameId,
          'playerId': playerId,
        })
        .then((_) => AppLog.d('🔔 JoinRequestProvider: Sent approval notification'))
        .catchError((e) => AppLog.d('❌ JoinRequestProvider: Approval notification failed: $e'));
  }

  /// Notify player their request was declined (fire and forget)
  void _notifyRequestDeclined(String gameId, String playerId) {
    FirebaseFunctions.instanceFor(region: 'us-west2')
        .httpsCallable('notifyJoinRequestDeclined')
        .call({
          'gameId': gameId,
          'playerId': playerId,
        })
        .then((_) => AppLog.d('🔔 JoinRequestProvider: Sent decline notification'))
        .catchError((e) => AppLog.d('❌ JoinRequestProvider: Decline notification failed: $e'));
  }

  /// Notify player the round filled before approval (fire and forget)
  void notifyRoundFilledBeforeApproval(String gameId, String playerId) {
    FirebaseFunctions.instanceFor(region: 'us-west2')
        .httpsCallable('notifyRoundFilledBeforeApproval')
        .call({
          'gameId': gameId,
          'playerId': playerId,
        })
        .then((_) => AppLog.d('🔔 JoinRequestProvider: Sent round-filled notification'))
        .catchError((e) => AppLog.d('❌ JoinRequestProvider: Round-filled notification failed: $e'));
  }

  // ========================================
  // CACHE INVALIDATION
  // ========================================

  void _invalidateGameCache(String gameId) {
    _gameRequestsCache.remove(gameId);
    _gameRequestsCacheTimestamps.remove(gameId);
    _scheduleNotify();
  }

  void _invalidateUserCache(String userId) {
    _userRequestsCache.remove(userId);
    _userRequestsCacheTimestamps.remove(userId);
    _scheduleNotify();
  }

  /// Invalidate all caches
  void invalidateAllCaches() {
    _gameRequestsCache.clear();
    _gameRequestsCacheTimestamps.clear();
    _userRequestsCache.clear();
    _userRequestsCacheTimestamps.clear();
    _scheduleNotify();
  }

  // ========================================
  // INTERNAL HELPERS
  // ========================================

  /// Debounced notifyListeners to avoid excessive rebuilds
  void _scheduleNotify() {
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 50), () {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  // ========================================
  // DISPOSE CLEANUP
  // ========================================

  @override
  void dispose() {
    _disposed = true;
    _notifyTimer?.cancel();
    _gameRequestsCache.clear();
    _gameRequestsCacheTimestamps.clear();
    _userRequestsCache.clear();
    _userRequestsCacheTimestamps.clear();
    super.dispose();
  }
}
