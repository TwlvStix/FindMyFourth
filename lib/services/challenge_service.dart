import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/core/utils/app_log.dart';
import '/models/challenge_progress.dart';

/// Service for challenge progress operations.
///
/// Reads challenge_progress from user documents in Firestore.
/// Challenge progress is written by Cloud Functions after round verification.
class ChallengeService {
  ChallengeService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Get challenge progress for the current authenticated user.
  ///
  /// Returns null if user is not authenticated or doesn't exist.
  Future<Map<String, ChallengeProgress>?> getMyProgress() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppLog.d('📖 ChallengeService.getMyProgress: no authenticated user');
      return null;
    }
    return getProgress(uid);
  }

  /// Get challenge progress for a specific user by ID.
  ///
  /// Returns null if user doesn't exist.
  Future<Map<String, ChallengeProgress>?> getProgress(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        AppLog.d('📖 ChallengeService.getProgress: user $userId not found');
        return null;
      }
      final data = doc.data();
      final progressMap = data?['challenge_progress'] as Map<String, dynamic>?;
      return ChallengeProgress.fromUserDoc(progressMap);
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ ChallengeService.getProgress error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Watch challenge progress for the current authenticated user.
  ///
  /// Returns a stream that emits null if user is not authenticated.
  Stream<Map<String, ChallengeProgress>?> watchMyProgress() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppLog.d('📖 ChallengeService.watchMyProgress: no authenticated user');
      return Stream.value(null);
    }
    return watchProgress(uid);
  }

  /// Watch challenge progress for a specific user by ID.
  ///
  /// Returns a stream that emits null if user doesn't exist.
  Stream<Map<String, ChallengeProgress>?> watchProgress(String userId) {
    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        final data = doc.data();
        final progressMap =
            data?['challenge_progress'] as Map<String, dynamic>?;
        return ChallengeProgress.fromUserDoc(progressMap);
      });
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ ChallengeService.watchProgress error: ${e.code} - ${e.message}');
      rethrow;
    }
  }
}
