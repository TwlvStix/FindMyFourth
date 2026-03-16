import 'package:firebase_analytics/firebase_analytics.dart';

import '/core/utils/app_log.dart';

// Note: FirebaseAnalytics uses PlatformException (Flutter services layer),
// not a Firebase-specific exception type. Generic catch is intentional here
// since analytics is fire-and-forget and shouldn't surface errors to users.

/// Analytics service for challenge board events.
///
/// Tracks key events for the challenge and leaderboard features.
/// All methods are fire-and-forget; errors are logged but not thrown.
class ChallengeAnalyticsService {
  ChallengeAnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  /// Logged when the Challenge Board page is opened.
  Future<void> logChallengeViewed() async {
    try {
      await _analytics.logEvent(name: 'challenge_board_viewed');
      AppLog.d('📊 ChallengeAnalytics: challenge_board_viewed logged');
    } catch (e) {
      AppLog.d('❌ ChallengeAnalytics: challenge_board_viewed failed: $e');
    }
  }

  /// Logged when a new challenge completion is detected.
  ///
  /// Parameters:
  /// - challengeId: the challenge definition ID
  /// - challengeName: the display name of the challenge
  Future<void> logChallengeCompleted({
    required String challengeId,
    required String challengeName,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'challenge_completed',
        parameters: {
          'challenge_id': challengeId,
          'challenge_name': challengeName,
        },
      );
      AppLog.d('📊 ChallengeAnalytics: challenge_completed logged ($challengeId)');
    } catch (e) {
      AppLog.d('❌ ChallengeAnalytics: challenge_completed failed: $e');
    }
  }

  /// Logged when the leaderboard section becomes visible.
  Future<void> logLeaderboardViewed() async {
    try {
      await _analytics.logEvent(name: 'leaderboard_viewed');
      AppLog.d('📊 ChallengeAnalytics: leaderboard_viewed logged');
    } catch (e) {
      AppLog.d('❌ ChallengeAnalytics: leaderboard_viewed failed: $e');
    }
  }

  /// Logged when a user initiates a rematch action.
  ///
  /// Parameters:
  /// - gameId: the game being rematched
  Future<void> logRematchStarted({required String gameId}) async {
    try {
      await _analytics.logEvent(
        name: 'rematch_started',
        parameters: {'game_id': gameId},
      );
      AppLog.d('📊 ChallengeAnalytics: rematch_started logged ($gameId)');
    } catch (e) {
      AppLog.d('❌ ChallengeAnalytics: rematch_started failed: $e');
    }
  }
}
