import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/utils/app_log.dart';

/// FriendService provides centralized access to friend-related Firestore operations
///
/// Follows the established service pattern:
/// - Instance class with optional FirebaseFirestore injection for testability
/// - Handles only Firestore reads/writes — no business logic or UI state
/// - Errors are caught, logged, and rethrown
class FriendService {
  FriendService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Remove a friend (bidirectional with one-way fallback)
  ///
  /// Attempts bidirectional removal first. If that fails (e.g., permission error
  /// on the friend's document), falls back to one-way removal from current user only.
  Future<void> removeFriend({
    required String currentUserId,
    required DocumentReference friendRef,
  }) async {
    try {
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      final friendPath = friendRef.path;

      try {
        final batch = _firestore.batch();

        batch.update(currentUserRef, {
          'friends': FieldValue.arrayRemove([
            friendRef,
            friendRef.id,
            friendPath,
            '/$friendPath',
          ]),
        });

        batch.update(friendRef, {
          'friends': FieldValue.arrayRemove([
            currentUserRef,
            currentUserRef.id,
          ]),
        });

        await batch.commit();
      } catch (e) {
        AppLog.d('FriendService: Bidirectional removal failed, using one-way fallback: $e');
        await currentUserRef.update({
          'friends': FieldValue.arrayRemove([
            friendRef,
            friendRef.id,
            friendPath,
            '/$friendPath',
          ]),
        });
      }
    } on FirebaseException catch (e, stackTrace) {
      AppLog.d('❌ FriendService.removeFriend error: ${e.code} - ${e.message}');
      AppLog.d('❌ FriendService.removeFriend stackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Send a friend request by adding current user's ID to target's friend_requests array
  ///
  /// Returns true if the request was sent, false if the target user doesn't exist.
  /// Caller (UserProvider) is responsible for duplicate/validation checks.
  Future<bool> sendFriendRequest({
    required String currentUserId,
    required DocumentReference targetUserRef,
  }) async {
    try {
      final targetSnapshot = await targetUserRef.get();
      if (!targetSnapshot.exists) {
        AppLog.d('FriendService: Target user does not exist: ${targetUserRef.id}');
        return false;
      }

      // Initialize friend_requests field if null
      final rawData = targetSnapshot.data() as Map<String, dynamic>?;
      final rawRequests = rawData?['friend_requests'];
      if (rawRequests == null) {
        try {
          await targetUserRef.update({'friend_requests': []});
        } catch (_) {
          // Expected to fail due to security rules — that's fine
        }
      }

      await targetUserRef.update({
        'friend_requests': FieldValue.arrayUnion([currentUserId]),
      });

      AppLog.d('✅ FriendService: Friend request sent from $currentUserId to ${targetUserRef.id}');
      return true;
    } on FirebaseException catch (e, stackTrace) {
      AppLog.d('❌ FriendService.sendFriendRequest error: ${e.code} - ${e.message}');
      AppLog.d('❌ FriendService.sendFriendRequest stackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Accept a friend request
  ///
  /// Removes requester from current user's friend_requests, then adds each to the other's friends list.
  Future<void> acceptFriendRequest({
    required String currentUserId,
    required DocumentReference requesterRef,
  }) async {
    final currentUserRef = _firestore.collection('users').doc(currentUserId);

    // Remove from friend_requests (non-fatal if fails)
    try {
      await currentUserRef.update({
        'friend_requests': FieldValue.arrayRemove([requesterRef, requesterRef.id]),
      });
    } catch (e) {
      AppLog.d('FriendService: Failed to remove from friend_requests: $e');
    }

    // Add to friends lists (both directions)
    try {
      await currentUserRef.update({
        'friends': FieldValue.arrayUnion([requesterRef]),
      });
      await requesterRef.update({
        'friends': FieldValue.arrayUnion([currentUserRef]),
      });
      AppLog.d('✅ FriendService: Friend request accepted between $currentUserId and ${requesterRef.id}');
    } on FirebaseException catch (e, stackTrace) {
      AppLog.d('❌ FriendService.acceptFriendRequest error: ${e.code} - ${e.message}');
      AppLog.d('❌ FriendService.acceptFriendRequest stackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Reject a friend request
  ///
  /// Removes requester from current user's friend_requests array.
  Future<void> rejectFriendRequest({
    required String currentUserId,
    required DocumentReference requesterRef,
  }) async {
    try {
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      await currentUserRef.update({
        'friend_requests': FieldValue.arrayRemove([requesterRef, requesterRef.id]),
      });
      AppLog.d('✅ FriendService: Friend request rejected from ${requesterRef.id}');
    } on FirebaseException catch (e, stackTrace) {
      AppLog.d('❌ FriendService.rejectFriendRequest error: ${e.code} - ${e.message}');
      AppLog.d('❌ FriendService.rejectFriendRequest stackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Cancel a friend request the current user previously sent
  ///
  /// Removes current user from target's friend_requests array.
  Future<void> cancelFriendRequest({
    required String currentUserId,
    required DocumentReference targetUserRef,
  }) async {
    try {
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      await targetUserRef.update({
        'friend_requests': FieldValue.arrayRemove([currentUserRef, currentUserRef.id]),
      });
      AppLog.d('✅ FriendService: Friend request cancelled to ${targetUserRef.id}');
    } on FirebaseException catch (e, stackTrace) {
      AppLog.d('❌ FriendService.cancelFriendRequest error: ${e.code} - ${e.message}');
      AppLog.d('❌ FriendService.cancelFriendRequest stackTrace: $stackTrace');
      rethrow;
    }
  }
}
