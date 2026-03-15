// Notification route resolution — maps notification types to page names.

/// A resolved push notification route with page name and parameter data.
class PushRoute {
  const PushRoute({
    required this.pageName,
    required this.parameterData,
  });

  final String pageName;
  final Map<String, dynamic> parameterData;
}

/// Resolve a notification payload to a route (page name + parameters).
///
/// Returns `null` if the notification type is unknown or missing required data.
PushRoute? resolveRouteFromType(Map<String, dynamic> data) {
  final type = data['type'];
  if (type is! String || type.isEmpty) {
    return null;
  }
  if (type == 'game_created' || type == 'game_alert') {
    final gameId = data['gameId'] ?? data['game_id'];
    if (gameId is String && gameId.isNotEmpty) {
      return PushRoute(
        pageName: 'JoinGameDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }
  if (type == 'friend_game_created') {
    final gameId = data['gameId'] ?? data['game_id'];
    if (gameId is String && gameId.isNotEmpty) {
      return PushRoute(
        pageName: 'JoinGameDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }
  if (type == 'chat_message') {
    final chatId = data['threadId'] ?? data['chatId'];
    if (chatId is String && chatId.isNotEmpty) {
      return PushRoute(
        pageName: 'ChatDetails',
        parameterData: {'chatId': chatId},
      );
    }
  }
  if (type == 'host_checkin') {
    final gameRef = data['gameRef'];
    if (gameRef is String && gameRef.isNotEmpty) {
      return PushRoute(
        pageName: 'HostCheckin',
        parameterData: {'gameRef': gameRef},
      );
    }
  }
  if (type == 'peer_rating') {
    final gameRef = data['gameRef'];
    if (gameRef is String && gameRef.isNotEmpty) {
      return PushRoute(
        pageName: 'PeerRating',
        parameterData: {'gameRef': gameRef},
      );
    }
  }
  if (type == 'fallback_confirmation') {
    final gameRef = data['gameRef'];
    if (gameRef is String && gameRef.isNotEmpty) {
      return PushRoute(
        pageName: 'FallbackConfirmation',
        parameterData: {'gameRef': gameRef},
      );
    }
  }
  // Join request notifications (vibe floor)
  // Host receives new request - route to their game view
  if (type == 'join_request_new') {
    final gameId = data['game_id'] ?? data['gameId'];
    if (gameId is String && gameId.isNotEmpty) {
      return PushRoute(
        pageName: 'GameJoinedDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }
  // User approved - they're now a participant, show their game view
  if (type == 'join_request_approved') {
    final gameId = data['game_id'] ?? data['gameId'];
    if (gameId is String && gameId.isNotEmpty) {
      return PushRoute(
        pageName: 'GameJoinedDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }
  // User declined - show game details with disabled button
  if (type == 'join_request_declined') {
    final gameId = data['game_id'] ?? data['gameId'];
    if (gameId is String && gameId.isNotEmpty) {
      return PushRoute(
        pageName: 'JoinGameDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }
  if (type == 'join_request_round_filled') {
    // Round is full, navigate to games list instead
    return const PushRoute(
      pageName: 'GamesList',
      parameterData: {},
    );
  }
  // Friend request notifications
  if (type == 'friend_request_received') {
    return const PushRoute(
      pageName: 'Tab_Friends',
      parameterData: {'initialSegment': 'requests'},
    );
  }
  if (type == 'friend_request_accepted') {
    return const PushRoute(
      pageName: 'Tab_Friends',
      parameterData: {'initialSegment': 'friends'},
    );
  }
  // Streak notifications
  if (type == 'streak_weekend_nudge') {
    return const PushRoute(
      pageName: 'GamesList',
      parameterData: {},
    );
  }
  if (type == 'streak_freeze_unlocked' ||
      type == 'streak_freeze_prompt' ||
      type == 'streak_milestone_reached' ||
      type == 'streak_broken') {
    return const PushRoute(
      pageName: 'MainProfile',
      parameterData: {},
    );
  }
  // Host-added player notification - route to game details
  // The bottom sheet is shown via handleNotificationNavigation intercept
  if (type == 'player_added_by_host') {
    final gameId = data['game_id'] ?? data['gameId'];
    if (gameId is String && gameId.isNotEmpty) {
      return PushRoute(
        pageName: 'GameJoinedDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }
  // Host notification when player declines - route to their game
  if (type == 'player_declined_spot') {
    final gameId = data['game_id'] ?? data['gameId'];
    if (gameId is String && gameId.isNotEmpty) {
      return PushRoute(
        pageName: 'GameJoinedDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }

  // ===== Trust System Type Aliases =====
  // Map Trust event names to their routing destinations

  // Post-round Trust types (aliases for legacy routes)
  if (type == 'host_checkin_due') {
    final gameRef = data['gameRef'] ?? data['game_ref'];
    final gameId = data['gameId'] ?? data['game_id'];
    final ref = gameRef ?? (gameId != null ? 'games/$gameId' : null);
    if (ref is String && ref.isNotEmpty) {
      return PushRoute(
        pageName: 'HostCheckin',
        parameterData: {'gameRef': ref},
      );
    }
  }
  if (type == 'host_checkin_fallback') {
    final gameRef = data['gameRef'] ?? data['game_ref'];
    final gameId = data['gameId'] ?? data['game_id'];
    final ref = gameRef ?? (gameId != null ? 'games/$gameId' : null);
    if (ref is String && ref.isNotEmpty) {
      return PushRoute(
        pageName: 'FallbackConfirmation',
        parameterData: {'gameRef': ref},
      );
    }
  }
  if (type == 'player_rate_due') {
    final gameRef = data['gameRef'] ?? data['game_ref'];
    final gameId = data['gameId'] ?? data['game_id'];
    final ref = gameRef ?? (gameId != null ? 'games/$gameId' : null);
    if (ref is String && ref.isNotEmpty) {
      return PushRoute(
        pageName: 'PeerRating',
        parameterData: {'gameRef': ref},
      );
    }
  }
  if (type == 'player_fallback_confirm') {
    final gameRef = data['gameRef'] ?? data['game_ref'];
    final gameId = data['gameId'] ?? data['game_id'];
    final ref = gameRef ?? (gameId != null ? 'games/$gameId' : null);
    if (ref is String && ref.isNotEmpty) {
      return PushRoute(
        pageName: 'FallbackConfirmation',
        parameterData: {'gameRef': ref},
      );
    }
  }

  // Game Trust types
  if (type == 'game_spot_opened' || type == 'game_cancelled') {
    final gameId = data['gameId'] ?? data['game_id'];
    if (gameId is String && gameId.isNotEmpty) {
      return PushRoute(
        pageName: 'JoinGameDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }
  if (type == 'game_alert_deferred') {
    final gameId = data['gameId'] ?? data['game_id'];
    if (gameId is String && gameId.isNotEmpty) {
      return PushRoute(
        pageName: 'JoinGameDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }

  // Join request expired
  if (type == 'join_request_expired') {
    return const PushRoute(
      pageName: 'GamesList',
      parameterData: {},
    );
  }

  // Trust account notifications → YourStanding
  if (type == 'no_show_flagged' ||
      type == 'dispute_resolved' ||
      type == 'strike_issued' ||
      type == 'cooldown_started' ||
      type == 'restriction_started' ||
      type == 'suspension_started' ||
      type == 'restriction_ended') {
    return const PushRoute(
      pageName: 'YourStanding',
      parameterData: {},
    );
  }

  // Badge notifications → MainProfile
  if (type == 'badge_earned' || type == 'badge_progress') {
    return const PushRoute(
      pageName: 'MainProfile',
      parameterData: {},
    );
  }

  // Pre-game confirmation (host confirms/cancels partial game)
  if (type == 'host_pre_game_confirm') {
    final gameId = data['gameId'] ?? data['game_id'];
    if (gameId is String && gameId.isNotEmpty) {
      return PushRoute(
        pageName: 'GameJoinedDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }

  return null;
}
