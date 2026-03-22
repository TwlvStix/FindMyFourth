import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/utils/app_log.dart';

/// Service for notification CRUD operations in Firestore.
///
/// Handles marking notifications as read/unread and deletion,
/// with proper batch operation handling for Firestore limits.
class NotificationCrudService {
  NotificationCrudService({FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _resolvedFirestore =>
      _firestore ?? FirebaseFirestore.instance;

  /// Streams recent notifications for the signed-in user.
  Stream<QuerySnapshot> streamNotifications({
    required DocumentReference userRef,
    required int limit,
  }) {
    return userRef
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Streams unread notifications for the signed-in user.
  Stream<QuerySnapshot> streamUnreadNotifications(
    DocumentReference userRef,
  ) {
    return userRef
        .collection('notifications')
        .where('read', isEqualTo: false)
        .limit(200)
        .snapshots();
  }

  /// Fetches a page of notifications with cursor-based pagination.
  ///
  /// Returns documents for the page. Use last document as cursor for next page.
  Future<List<QueryDocumentSnapshot>> fetchNotificationsPage({
    required DocumentReference userRef,
    required int pageSize,
    DocumentSnapshot? startAfterDocument,
  }) async {
    try {
      Query query = userRef
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(pageSize);

      if (startAfterDocument != null) {
        query = query.startAfterDocument(startAfterDocument);
      }

      final snapshot = await query.get();
      AppLog.d(
          '📖 NotificationCrudService: Fetched ${snapshot.docs.length} notifications');
      return snapshot.docs;
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ NotificationCrudService.fetchNotificationsPage: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Marks all unread notifications as read for a user.
  ///
  /// Uses batch operations with 400-op limit to stay safely under
  /// Firestore's 500-operation batch limit.
  Future<void> markAllAsRead(DocumentReference userRef) async {
    try {
      final unreadSnapshot = await userRef
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      if (unreadSnapshot.docs.isEmpty) {
        AppLog.d('📖 NotificationCrudService: No unread notifications');
        return;
      }

      var batch = _resolvedFirestore.batch();
      var opCount = 0;

      for (final doc in unreadSnapshot.docs) {
        batch.update(doc.reference, {'read': true});
        opCount += 1;
        if (opCount >= 400) {
          await batch.commit();
          batch = _resolvedFirestore.batch();
          opCount = 0;
        }
      }

      if (opCount > 0) {
        await batch.commit();
      }

      AppLog.d(
          '✅ NotificationCrudService: Marked ${unreadSnapshot.docs.length} as read');
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ NotificationCrudService.markAllAsRead: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Marks a notification as read if not already read.
  Future<void> markReadIfNeeded(
    DocumentReference notificationRef,
    bool isRead,
  ) async {
    if (isRead) {
      return;
    }
    try {
      await notificationRef.update({'read': true});
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ NotificationCrudService.markReadIfNeeded: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Marks a notification as unread.
  Future<void> markAsUnread(DocumentReference notificationRef) async {
    try {
      await notificationRef.update({'read': false});
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ NotificationCrudService.markAsUnread: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Deletes a single notification.
  Future<void> deleteNotification(DocumentReference notificationRef) async {
    try {
      await notificationRef.delete();
      AppLog.d('✅ NotificationCrudService: Deleted ${notificationRef.path}');
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ NotificationCrudService.deleteNotification: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Deletes all notifications for a user.
  ///
  /// Uses batch operations with 500-op limit (Firestore max).
  /// Returns the count of deleted notifications.
  Future<int> deleteAllNotifications(DocumentReference userRef) async {
    try {
      final allSnapshot =
          await userRef.collection('notifications').orderBy('createdAt').limit(200).get();

      if (allSnapshot.docs.isEmpty) {
        AppLog.d('📖 NotificationCrudService: No notifications to delete');
        return 0;
      }

      var batch = _resolvedFirestore.batch();
      var opCount = 0;

      for (final doc in allSnapshot.docs) {
        batch.delete(doc.reference);
        opCount += 1;
        if (opCount >= 500) {
          await batch.commit();
          batch = _resolvedFirestore.batch();
          opCount = 0;
        }
      }

      if (opCount > 0) {
        await batch.commit();
      }

      AppLog.d(
          '✅ NotificationCrudService: Deleted ${allSnapshot.docs.length} notifications');
      return allSnapshot.docs.length;
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ NotificationCrudService.deleteAllNotifications: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Updates the response status on a notification document.
  ///
  /// Used by actionable notifications to persist user's response
  /// (e.g., 'confirmed' or 'cancelled').
  Future<void> updateResponseStatus(
    DocumentReference notificationRef,
    String status,
  ) async {
    try {
      await notificationRef.update({'responseStatus': status});
      AppLog.d(
          '✅ NotificationCrudService: Updated responseStatus=$status on ${notificationRef.path}');
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ NotificationCrudService.updateResponseStatus: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Finds a notification document reference by type and gameId.
  ///
  /// Queries the user's notifications subcollection for a matching document.
  /// Returns null if not found or on error (fail-open for non-critical lookup).
  Future<DocumentReference?> findNotificationRef({
    required String userId,
    required String type,
    required String gameId,
  }) async {
    try {
      final snapshot = await _resolvedFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('type', isEqualTo: type)
          .where('data.gameId', isEqualTo: gameId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.reference;
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ NotificationCrudService.findNotificationRef: ${e.code} - ${e.message}');
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Resolves a game reference from notification payload fields.
  DocumentReference? resolveGameRefFromPayload(Map<String, dynamic> payload) {
    final gameRefPath = payload['gameRef'];
    if (gameRefPath is String && gameRefPath.isNotEmpty) {
      return _resolvedFirestore.doc(gameRefPath);
    }

    final gameId = payload['gameId'] ?? payload['game_id'];
    if (gameId is String && gameId.isNotEmpty) {
      return _resolvedFirestore.collection('games').doc(gameId);
    }

    return null;
  }

  // ── Preference Methods ─────────────────────────────────────────────────────

  /// Loads notification preferences for a user.
  ///
  /// Returns the raw notification_prefs map from the user document,
  /// or null if not found.
  Future<Map<String, dynamic>?> loadPreferences(String uid) async {
    try {
      final userDoc = await _resolvedFirestore.collection('users').doc(uid).get();
      final prefsMap = userDoc.data()?['notification_prefs'];
      if (prefsMap != null && prefsMap is Map) {
        return Map<String, dynamic>.from(prefsMap);
      }
      return null;
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ NotificationCrudService.loadPreferences: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Saves notification preferences for a user.
  ///
  /// Merges the notification_prefs field into the user document.
  Future<void> savePreferences(String uid, Map<String, dynamic> prefs) async {
    try {
      final userRef = _resolvedFirestore.collection('users').doc(uid);
      await userRef.set({
        'notification_prefs': prefs,
      }, SetOptions(merge: true));
      AppLog.d('✅ NotificationCrudService: Saved preferences for $uid');
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ NotificationCrudService.savePreferences: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Checks for backend notification errors (e.g., send failures).
  ///
  /// Returns the last_error map from notification_state, or null if not found.
  Future<Map<String, dynamic>?> checkBackendErrors(String uid) async {
    try {
      final userDoc = await _resolvedFirestore.collection('users').doc(uid).get();
      final errorData = userDoc.data()?['notification_state']?['last_error'];
      if (errorData != null && errorData is Map) {
        return Map<String, dynamic>.from(errorData);
      }
      return null;
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ NotificationCrudService.checkBackendErrors: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // ── Game Blocking ─────────────────────────────────────────────────────────

  /// Returns true when a game should be blocked because it's friends-only and
  /// the current user is not in the host's friend list.
  Future<bool> shouldBlockFriendsOnlyGame({
    required DocumentReference gameRef,
    required DocumentReference currentUserRef,
  }) async {
    Map<String, dynamic>? data;
    try {
      final gameSnap = await gameRef.get();
      data = gameSnap.data() as Map<String, dynamic>?;
    } on FirebaseException catch (error) {
      AppLog.d(
        '❌ NotificationCrudService.shouldBlockFriendsOnlyGame: ${error.code} - ${error.message}',
      );
      // Don't block on permission-denied — let game detail widget handle it.
      // This prevents hosts from being blocked when Firestore rules reject
      // the read (e.g., stale auth token, rules not yet deployed).
      return false;
    } catch (_) {
      return false;
    }

    if (data == null) {
      return false;
    }

    final friendGameValue = (data['friendGame'] as String?) ?? '';
    final isFriendsOnly = friendGameValue == 'friends';
    if (!isFriendsOnly) {
      return false;
    }

    final ownerRef = data['userRef'];
    if (ownerRef is! DocumentReference) {
      return true;
    }

    // Host can always access their own game
    if (ownerRef.id == currentUserRef.id) {
      return false;
    }

    final userSnap = await currentUserRef.get();
    final userData = userSnap.data() as Map<String, dynamic>? ?? {};
    final friends = userData['friends'];
    if (friends is List) {
      return !friends.any((entry) {
        if (entry is DocumentReference) {
          return entry.id == ownerRef.id;
        }
        if (entry is String) {
          if (entry.contains('/')) {
            final parts = entry.split('/');
            return parts.isNotEmpty && parts.last == ownerRef.id;
          }
          return entry == ownerRef.id;
        }
        return false;
      });
    }
    return true;
  }
}
