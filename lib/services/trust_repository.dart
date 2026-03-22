import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cloud_functions/cloud_functions.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/backend/schema/player_standing.dart';
import '/backend/schema/trust_profile.dart';
import '/backend/schema/util/firestore_util.dart';
import '/core/exceptions/app_exceptions.dart';
import '/core/utils/app_log.dart';

/// TrustRepository — data access layer for trust system.
///
/// Does NOT extend FirestoreRepository (no pagination needed).
/// Public trust data is read from UsersRecord in Firestore.
/// Private standing data is fetched via the getMyStanding cloud function.
class TrustRepository {
  const TrustRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      (_firestore ?? FirebaseFirestore.instance).collection('users');

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetch the public trust profile for [userId].
  ///
  /// Reads from the users/{userId} document and maps the trust fields
  /// to a [TrustProfile] value object.
  Future<TrustProfile?> getTrustProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return null;
      final data = mapFromFirestore(doc.data() ?? const <String, dynamic>{});
      return TrustProfile.fromMap(data);
    } on FirebaseException catch (e) {
      AppLog.d('❌ TrustRepository.getTrustProfile error for $userId: ${e.code} - ${e.message}');
      return null;
    }
  }

  /// Batch fetch trust profiles for multiple users.
  ///
  /// Uses Firestore whereIn with 10-item chunking.
  /// Returns `Map<userId, TrustProfile?>` - null for users without trust data.
  Future<Map<String, TrustProfile?>> batchGetTrustProfiles(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};

    final uniqueIds = userIds.toSet().toList();
    final result = <String, TrustProfile?>{};

    // Chunk by 10 (Firestore whereIn limit)
    for (var i = 0; i < uniqueIds.length; i += 10) {
      final end = (i + 10) > uniqueIds.length ? uniqueIds.length : i + 10;
      final batch = uniqueIds.sublist(i, end);

      try {
        final snapshot = await _usersCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          final data = mapFromFirestore(doc.data());
          result[doc.id] = TrustProfile.fromMap(data);
        }

        // Add null entries for users not found
        for (final userId in batch) {
          if (!result.containsKey(userId)) {
            result[userId] = null;
          }
        }
      } on FirebaseException catch (e) {
        AppLog.d(
            '❌ TrustRepository.batchGetTrustProfiles error for chunk ${i ~/ 10 + 1}: ${e.code} - ${e.message}');
        // Add null entries for failed batch
        for (final userId in batch) {
          result[userId] = null;
        }
      }
    }

    return result;
  }

  /// Fetch the current user's private player standing.
  ///
  /// Calls the getMyStanding cloud function which returns the full
  /// standing data including strikes, rates, badge progress, and restriction.
  Future<PlayerStanding?> getPlayerStanding() async {
    final uid = currentUserUid;
    if (uid.isEmpty) return null;
    try {
      final result = await makeCloudCall('getMyStanding', {'userId': uid});
      AppLog.d('📖 TrustRepository.getPlayerStanding: '
          'result keys=${result.keys.toList()}, '
          'activeStrikes=${result['activeStrikeCount']}');
      if (result.isEmpty) return null;
      return PlayerStanding.fromMap(result);
      // Non-critical: makeCloudCall handles Firebase errors internally; this catches
      // response parsing failures. Fire-and-forget with safe fallback per services.md:28.
    } catch (e) {
      AppLog.d('❌ TrustRepository.getPlayerStanding error: $e');
      return null;
    }
  }

  /// Submit host attendance check-in for [gameId].
  ///
  /// [attendance] maps each participant's id to whether they attended.
  Future<bool> submitHostCheckIn(
      String gameId, Map<String, bool> attendance) async {
    try {
      final result = await makeCloudCall('submitHostCheckIn', {
        'gameId': gameId,
        'attendance': attendance,
      });
      return result['ok'] == true || result.isNotEmpty;
      // Non-critical: makeCloudCall handles Firebase errors internally; this catches
      // response parsing failures. Fire-and-forget with safe fallback per services.md:28.
    } catch (e) {
      AppLog.d('TrustRepository.submitHostCheckIn error: $e');
      return false;
    }
  }

  /// Submit peer ratings for [gameId].
  ///
  /// [ratings] maps each co-player's uid to whether the current user
  /// would play with them again.
  Future<bool> submitPeerRatings(
      String gameId, Map<String, bool> ratings) async {
    try {
      final result = await makeCloudCall('submitPeerRatings', {
        'gameId': gameId,
        'ratings': ratings,
      });
      return result['success'] == true;
    } on FirebaseFunctionsException catch (e) {
      AppLog.d('❌ TrustRepository.submitPeerRatings error: ${e.code} - ${e.message}');
      if (e.code == 'failed-precondition') {
        throw AppException(
          'Unable to verify this device. Please restart the app and try again.',
          code: 'app-check-failed',
          cause: e,
        );
      }
      return false;
    } catch (e) {
      AppLog.d('❌ TrustRepository.submitPeerRatings error: $e');
      return false;
    }
  }

  /// Fetch players for a host check-in (all participants including guests).
  Future<Map<String, dynamic>> getHostCheckInData(String gameId) async {
    try {
      final result = await makeCloudCall('getHostCheckInData', {
        'gameId': gameId,
      });
      return result;
      // Non-critical: makeCloudCall handles Firebase errors internally; this catches
      // response parsing failures. Fire-and-forget with safe fallback per services.md:28.
    } catch (e) {
      AppLog.d('TrustRepository.getHostCheckInData error: $e');
      return {};
    }
  }

  /// Record a day-of cancellation for trust/strike tracking.
  ///
  /// Calls the recordCancellation cloud function which determines the
  /// cancellation tier and issues a strike if appropriate.
  /// Fire-and-forget safe — returns empty map on failure.
  Future<Map<String, dynamic>> recordCancellation(
      String gameId, String userId) async {
    try {
      final result = await makeCloudCall('recordCancellation', {
        'gameId': gameId,
        'userId': userId,
      });
      AppLog.d('📖 TrustRepository.recordCancellation: gameId=$gameId, '
          'tier=${result['tier']}, strikeIssued=${result['strikeIssued']}');
      return result;
      // Non-critical: makeCloudCall handles Firebase errors internally; this catches
      // response parsing failures. Fire-and-forget with safe fallback per services.md:28.
    } catch (e) {
      AppLog.d('❌ TrustRepository.recordCancellation error: $e');
      return {};
    }
  }

  /// Fetch ratable co-players for a post-round peer rating (app users only).
  Future<Map<String, dynamic>> getPeerRatingData(String gameId) async {
    try {
      final result = await makeCloudCall('getPeerRatingData', {
        'gameId': gameId,
      });
      return result;
      // Non-critical: makeCloudCall handles Firebase errors internally; this catches
      // response parsing failures. Fire-and-forget with safe fallback per services.md:28.
    } catch (e) {
      AppLog.d('TrustRepository.getPeerRatingData error: $e');
      return {};
    }
  }
}
