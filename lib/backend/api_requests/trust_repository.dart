import 'package:cloud_firestore/cloud_firestore.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/backend/schema/player_standing.dart';
import '/backend/schema/trust_profile.dart';
import '/core/utils/app_log.dart';

/// TrustRepository — data access layer for trust system.
///
/// Does NOT extend FirestoreRepository (no pagination needed).
/// Public trust data is read from UsersRecord in Firestore.
/// Private standing data is fetched via the getMyStanding cloud function.
class TrustRepository {
  const TrustRepository();

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetch the public trust profile for [userId].
  ///
  /// Reads from the users/{userId} document and maps the trust fields
  /// to a [TrustProfile] value object.
  Future<TrustProfile?> getTrustProfile(String userId) async {
    try {
      final doc = await UsersRecord.collection.doc(userId).get();
      if (!doc.exists) return null;
      final data = Map<String, dynamic>.from(doc.data() as Map);
      return TrustProfile.fromMap(data);
    } catch (e) {
      AppLog.d('TrustRepository.getTrustProfile error for $userId: $e');
      return null;
    }
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
      if (result.isEmpty) return null;
      return PlayerStanding.fromMap(result);
    } catch (e) {
      AppLog.d('TrustRepository.getPlayerStanding error: $e');
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
      return result['ok'] == true || result.isNotEmpty;
    } catch (e) {
      AppLog.d('TrustRepository.submitPeerRatings error: $e');
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
    } catch (e) {
      AppLog.d('TrustRepository.getHostCheckInData error: $e');
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
    } catch (e) {
      AppLog.d('TrustRepository.getPeerRatingData error: $e');
      return {};
    }
  }
}
