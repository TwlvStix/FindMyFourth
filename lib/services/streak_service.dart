import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/backend/schema/users_record.dart';
import '/core/utils/app_log.dart';
import '/models/streak_profile.dart';

/// Service for streak-related operations.
///
/// Handles fetching streak profiles from Firestore and calling
/// the deployStreakFreeze Cloud Function.
class StreakService {
  StreakService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-west2'),
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  /// Get streak profile for the current authenticated user.
  ///
  /// Returns null if user is not authenticated or doesn't exist.
  Future<StreakProfile?> getMyStreak() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppLog.d('📖 StreakService.getMyStreak: no authenticated user');
      return null;
    }
    return getStreak(uid);
  }

  /// Get streak profile for a specific user by ID.
  ///
  /// Returns null if user doesn't exist.
  Future<StreakProfile?> getStreak(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        AppLog.d('📖 StreakService.getStreak: user $userId not found');
        return null;
      }
      final record = UsersRecord.fromSnapshot(doc);
      return StreakProfile.fromUserRecord(record);
    } on FirebaseException catch (e) {
      AppLog.d('❌ StreakService.getStreak error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Watch streak profile for the current authenticated user.
  ///
  /// Returns a stream that emits null if user is not authenticated.
  Stream<StreakProfile?> watchMyStreak() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppLog.d('📖 StreakService.watchMyStreak: no authenticated user');
      return Stream.value(null);
    }
    return watchStreak(uid);
  }

  /// Watch streak profile for a specific user by ID.
  ///
  /// Returns a stream that emits null if user doesn't exist.
  Stream<StreakProfile?> watchStreak(String userId) {
    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        final record = UsersRecord.fromSnapshot(doc);
        return StreakProfile.fromUserRecord(record);
      });
    } on FirebaseException catch (e) {
      AppLog.d('❌ StreakService.watchStreak error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Deploy a streak freeze for a specific week.
  ///
  /// The weekKey should be the Monday of the week in YYYY-MM-DD format.
  /// Returns a map with the result status and any error message.
  ///
  /// Possible results:
  /// - {status: 'ok'} - Freeze deployed successfully
  /// - {status: 'error', error: 'not_eligible'} - User hasn't earned freeze
  /// - {status: 'error', error: 'already_used'} - Freeze already used this season
  /// - {status: 'error', error: 'invalid_week'} - Week is not freezable
  Future<Map<String, dynamic>> deployStreakFreeze(String weekKey) async {
    try {
      final callable = _functions.httpsCallable('deployStreakFreeze');
      final result = await callable.call<Map<String, dynamic>>({
        'weekKey': weekKey,
      });
      AppLog.d('✅ StreakService.deployStreakFreeze: ${result.data}');
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      AppLog.d('❌ StreakService.deployStreakFreeze error: ${e.code} - ${e.message}');
      return {
        'status': 'error',
        'error': e.code,
        'message': e.message,
      };
    } on FirebaseException catch (e) {
      AppLog.d('❌ StreakService.deployStreakFreeze error: ${e.code} - ${e.message}');
      rethrow;
    }
  }
}
