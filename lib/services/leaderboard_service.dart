import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/core/utils/app_log.dart';
import '/models/leaderboard_entry.dart';

/// Service for leaderboard Firestore queries.
///
/// Queries the `users` collection using the composite index
/// `(streak_season_id ASC, season_rounds_played DESC)`.
class LeaderboardService {
  LeaderboardService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _currentSeasonId => DateTime.now().year.toString();

  /// Fetch the top N players for the current season.
  ///
  /// Marks the current user's entry with `isCurrentUser = true`.
  Future<List<LeaderboardEntry>> getTopPlayers({int limit = 10}) async {
    final uid = _auth.currentUser?.uid;

    try {
      final snap = await _firestore
          .collection('users')
          .where('streak_season_id', isEqualTo: _currentSeasonId)
          .orderBy('season_rounds_played', descending: true)
          .limit(limit)
          .get();

      final entries = <LeaderboardEntry>[];
      for (var i = 0; i < snap.docs.length; i++) {
        final doc = snap.docs[i];
        entries.add(LeaderboardEntry.fromDoc(
          doc,
          rank: i + 1,
          isCurrentUser: doc.id == uid,
        ));
      }

      AppLog.d('📖 LeaderboardService.getTopPlayers: ${entries.length} entries');
      return entries;
    } on FirebaseException catch (e) {
      AppLog.d('❌ LeaderboardService.getTopPlayers error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Get the current user's rank by counting users with more rounds.
  ///
  /// Uses Firestore `count()` aggregation to avoid fetching all users.
  /// Returns 0 if user is not authenticated or has no rounds.
  Future<int> getUserRank() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppLog.d('📖 LeaderboardService.getUserRank: no authenticated user');
      return 0;
    }

    try {
      // Read current user's rounds
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return 0;

      final data = userDoc.data();
      final userRounds = (data?['season_rounds_played'] as num?)?.toInt() ?? 0;
      if (userRounds == 0) return 0;

      // Count users with more rounds in the same season
      final countSnap = await _firestore
          .collection('users')
          .where('streak_season_id', isEqualTo: _currentSeasonId)
          .where('season_rounds_played', isGreaterThan: userRounds)
          .count()
          .get();

      final rank = (countSnap.count ?? 0) + 1;
      AppLog.d('📖 LeaderboardService.getUserRank: #$rank ($userRounds rounds)');
      return rank;
    } on FirebaseException catch (e) {
      AppLog.d('❌ LeaderboardService.getUserRank error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Check if the leaderboard should be visible (>= 50 active users).
  ///
  /// Reads the `metadata/season_stats` doc for the `active_user_count` field.
  Future<bool> isLeaderboardVisible() async {
    try {
      final doc = await _firestore
          .collection('metadata')
          .doc('season_stats')
          .get();

      if (!doc.exists) return false;

      final data = doc.data();
      final count = (data?['active_user_count'] as num?)?.toInt() ?? 0;
      AppLog.d('📖 LeaderboardService.isLeaderboardVisible: $count active users');
      return count >= 50;
    } on FirebaseException catch (e) {
      AppLog.d('❌ LeaderboardService.isLeaderboardVisible error: ${e.code} - ${e.message}');
      rethrow;
    }
  }
}
