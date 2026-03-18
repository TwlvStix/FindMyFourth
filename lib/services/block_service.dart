import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/utils/app_log.dart';

/// Handles block/unblock Firestore operations.
///
/// Blocked user IDs are stored as subcollection documents under
/// `users/{uid}/blocked_users/{blockedUid}` for efficient owner-only reads.
class BlockService {
  BlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference _blockedUsersCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('blocked_users');

  /// Block a user. Creates a document in the blocked_users subcollection.
  Future<void> blockUser({
    required String currentUid,
    required String blockedUid,
  }) async {
    try {
      await _blockedUsersCollection(currentUid).doc(blockedUid).set({
        'blockedUid': blockedUid,
        'blockedAt': FieldValue.serverTimestamp(),
      });
      AppLog.d('✅ BlockService.blockUser: $currentUid blocked $blockedUid');
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ BlockService.blockUser error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Unblock a user. Deletes the document from blocked_users subcollection.
  Future<void> unblockUser({
    required String currentUid,
    required String blockedUid,
  }) async {
    try {
      await _blockedUsersCollection(currentUid).doc(blockedUid).delete();
      AppLog.d(
          '✅ BlockService.unblockUser: $currentUid unblocked $blockedUid');
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ BlockService.unblockUser error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Stream of blocked user IDs for real-time updates.
  Stream<Set<String>> streamBlockedUserIds(String uid) {
    return _blockedUsersCollection(uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  /// One-shot fetch of blocked user IDs.
  Future<Set<String>> getBlockedUserIds(String uid) async {
    try {
      final snapshot = await _blockedUsersCollection(uid).get();
      final ids = snapshot.docs.map((doc) => doc.id).toSet();
      AppLog.d(
          '📖 BlockService.getBlockedUserIds: $uid has ${ids.length} blocked users');
      return ids;
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ BlockService.getBlockedUserIds error: ${e.code} - ${e.message}');
      rethrow;
    }
  }
}
