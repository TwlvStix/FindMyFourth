import 'package:firebase_analytics/firebase_analytics.dart';

import '/core/utils/app_log.dart';

/// Analytics service for vibe floor events
///
/// Tracks key events for the vibe floor feature to enable 90-day review.
/// All methods are fire-and-forget; errors are logged but not thrown.
class VibeAnalyticsService {
  VibeAnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  /// Logged when the vibe floor check runs and determines eligibility
  ///
  /// Parameters:
  /// - result: 'auto_join', 'requires_approval', or 'friend_bypass'
  /// - vibeScore: the owner's compatibility score with the player
  /// - vibeFloor: the current floor threshold
  /// - gameId: the game being joined
  Future<void> logVibeFloorTriggered({
    required String result,
    required double vibeScore,
    required int vibeFloor,
    required String gameId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'vibe_floor_triggered',
        parameters: {
          'result': result,
          'vibe_score': vibeScore.round(),
          'vibe_floor': vibeFloor,
          'game_id': gameId,
          'score_gap': (vibeFloor - vibeScore).round(),
        },
      );
      AppLog.d('📊 VibeAnalytics: vibe_floor_triggered logged (result: $result)');
    } catch (e) {
      AppLog.d('❌ VibeAnalytics: vibe_floor_triggered failed: $e');
    }
  }

  /// Logged when a player submits a join request
  ///
  /// Parameters:
  /// - gameId: the game being requested
  /// - vibeScore: their score with the owner
  /// - vibeFloor: the floor they were below
  Future<void> logJoinRequestSubmitted({
    required String gameId,
    required double vibeScore,
    required int vibeFloor,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'join_request_submitted',
        parameters: {
          'game_id': gameId,
          'vibe_score': vibeScore.round(),
          'vibe_floor': vibeFloor,
          'score_gap': (vibeFloor - vibeScore).round(),
        },
      );
      AppLog.d('📊 VibeAnalytics: join_request_submitted logged');
    } catch (e) {
      AppLog.d('❌ VibeAnalytics: join_request_submitted failed: $e');
    }
  }

  /// Logged when an owner approves or declines a request
  ///
  /// Parameters:
  /// - gameId: the game
  /// - approved: true if approved, false if declined
  /// - vibeScore: the requester's score with the owner
  /// - responseTimeHours: time between request and response (rounded)
  Future<void> logJoinRequestResolved({
    required String gameId,
    required bool approved,
    required double vibeScore,
    required int responseTimeHours,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'join_request_resolved',
        parameters: {
          'game_id': gameId,
          'outcome': approved ? 'approved' : 'declined',
          'vibe_score': vibeScore.round(),
          'response_time_hours': responseTimeHours,
        },
      );
      AppLog.d(
        '📊 VibeAnalytics: join_request_resolved logged '
        '(outcome: ${approved ? 'approved' : 'declined'})',
      );
    } catch (e) {
      AppLog.d('❌ VibeAnalytics: join_request_resolved failed: $e');
    }
  }

  /// Logged when owner toggles the "Require vibe match" setting
  ///
  /// Only log when the owner changes it from the default (on).
  ///
  /// Parameters:
  /// - enabled: the new toggle state
  Future<void> logVibeFloorToggleChanged({
    required bool enabled,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'vibe_floor_toggle_changed',
        parameters: {
          'enabled': enabled,
        },
      );
      AppLog.d(
        '📊 VibeAnalytics: vibe_floor_toggle_changed logged (enabled: $enabled)',
      );
    } catch (e) {
      AppLog.d('❌ VibeAnalytics: vibe_floor_toggle_changed failed: $e');
    }
  }

  /// Logged when player saves a vibe profile edit
  ///
  /// Parameters:
  /// - editNumber: which edit this is (1st, 2nd, etc.)
  /// - wasFirstEdit: true if this was the first edit
  Future<void> logVibeProfileEdited({
    required int editNumber,
    required bool wasFirstEdit,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'vibe_profile_edited',
        parameters: {
          'edit_number': editNumber,
          'was_first_edit': wasFirstEdit,
        },
      );
      AppLog.d(
        '📊 VibeAnalytics: vibe_profile_edited logged (edit #$editNumber)',
      );
    } catch (e) {
      AppLog.d('❌ VibeAnalytics: vibe_profile_edited failed: $e');
    }
  }
}
