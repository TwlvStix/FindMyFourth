import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';

/// Static helper methods for notification type classification, icon mapping,
/// and fallback text generation.
class NotificationTypeHelpers {
  NotificationTypeHelpers._();

  /// Returns true for game creation/alert notification types.
  static bool isGameNotification(String type) {
    return type == 'game_created' || type == 'game_alert';
  }

  /// Returns true for post-round confirmation notification types
  /// that route to dedicated confirmation screens.
  static bool isPostRoundNotification(String type) {
    return const {
      'host_checkin_due',
      'player_rate_due',
      'host_checkin_fallback',
      'player_fallback_confirm',
    }.contains(type);
  }

  /// Returns true for trust system game-related notification types
  /// (excludes post-round types which have dedicated screens).
  static bool isTrustGameNotification(String type) {
    return const {
      'game_spot_opened',
      'game_cancelled',
    }.contains(type);
  }

  /// Returns true for trust system account-related notification types.
  static bool isTrustAccountNotification(String type) {
    return const {
      'no_show_flagged',
      'dispute_resolved',
      'strike_issued',
      'cooldown_started',
      'restriction_started',
      'suspension_started',
      'restriction_ended',
    }.contains(type);
  }

  /// Returns true for badge-related notification types.
  static bool isBadgeNotification(String type) {
    return const {'badge_earned', 'badge_progress'}.contains(type);
  }

  /// Returns true for social/friend-related notification types.
  static bool isSocialNotification(String type) {
    return const {
      'friend_request_received',
      'friend_request_accepted',
      'friend_game_created',
    }.contains(type);
  }

  /// Returns true for join request notification types.
  static bool isJoinRequestNotification(String type) {
    return const {
      'join_request_new',
      'join_request_approved',
      'join_request_declined',
      'join_request_round_filled',
      'join_request_expired',
    }.contains(type);
  }

  /// Returns true for host-add-player notification types.
  static bool isHostAddNotification(String type) {
    return const {
      'player_added_by_host',
      'player_declined_spot',
    }.contains(type);
  }

  /// Returns true for streak notification types.
  static bool isStreakNotification(String type) {
    return const {
      'streak_weekend_nudge',
      'streak_freeze_unlocked',
      'streak_freeze_prompt',
      'streak_milestone_reached',
      'streak_broken',
    }.contains(type);
  }

  /// Returns true for notification types sent specifically to the game host.
  ///
  /// Used to skip the friends-only gate — the host always has access to
  /// their own game, so we can bypass the Firestore read check.
  static bool isHostNotificationType(String type) {
    return const {
      'host_checkin_due',
      'host_checkin_fallback',
      'host_pre_game_confirm',
      'player_declined_spot',
      'join_request_new',
    }.contains(type);
  }

  /// Returns true for game alert notification types (deferred alerts).
  static bool isGameAlertNotification(String type) {
    return type == 'game_alert_deferred';
  }

  /// Returns the appropriate Phosphor icon for the notification type.
  static PhosphorIconData iconForType(String type) {
    if (type == 'chat_message') return AppPhosphorIcons.chat;
    if (isGameNotification(type)) return AppPhosphorIcons.games;
    if (type == 'attendance_dispute') return AppPhosphorIcons.info;
    if (type == 'dispute_resolved_cleared') return AppPhosphorIcons.success;
    if (type == 'dispute_resolved_upheld') return AppPhosphorIcons.warning;
    // Trust System types
    if (type == 'host_checkin_due' ||
        type == 'host_checkin_fallback' ||
        type == 'player_fallback_confirm' ||
        type == 'host_pre_game_confirm') {
      return AppPhosphorIcons.calendarCheck;
    }
    if (type == 'player_rate_due') return AppPhosphorIcons.star;
    if (type == 'game_spot_opened' || type == 'game_cancelled') {
      return AppPhosphorIcons.games;
    }
    if (isGameAlertNotification(type)) return AppPhosphorIcons.games;
    if (isTrustAccountNotification(type)) {
      return type == 'dispute_resolved' || type == 'restriction_ended'
          ? AppPhosphorIcons.trust
          : AppPhosphorIcons.warning;
    }
    if (isBadgeNotification(type)) return AppPhosphorIcons.badge;
    if (type == 'friend_game_created') return AppPhosphorIcons.games;
    if (type == 'friend_request_received') return AppPhosphorIcons.addPlayer;
    if (type == 'friend_request_accepted') return AppPhosphorIcons.golfers;
    // Join request types
    if (type == 'join_request_new') return AppPhosphorIcons.addPlayer;
    if (type == 'join_request_approved') return AppPhosphorIcons.success;
    if (type == 'join_request_declined' ||
        type == 'join_request_round_filled' ||
        type == 'join_request_expired') {
      return AppPhosphorIcons.info;
    }
    // Host-add-player types
    if (type == 'player_added_by_host') return AppPhosphorIcons.games;
    if (type == 'player_declined_spot') return AppPhosphorIcons.info;
    // Streak types
    if (isStreakNotification(type)) return AppPhosphorIcons.flame;
    return AppPhosphorIcons.notifications;
  }

  /// Returns the icon background color for the notification type.
  static Color iconBgColorForType(String type) {
    if (type == 'attendance_dispute') return AppColors.info;
    if (type == 'dispute_resolved_cleared') return AppColors.success;
    if (type == 'dispute_resolved_upheld') return AppColors.error;
    if (isTrustAccountNotification(type)) return AppColors.error;
    if (isBadgeNotification(type)) return AppColors.gold;
    if (isSocialNotification(type)) return AppColors.green;
    // Join request types
    if (type == 'join_request_new') return AppColors.green;
    if (type == 'join_request_approved') return AppColors.success;
    if (type == 'join_request_declined' ||
        type == 'join_request_round_filled' ||
        type == 'join_request_expired') {
      return AppColors.info;
    }
    // Host-add-player types
    if (type == 'player_added_by_host') return AppColors.green;
    if (type == 'player_declined_spot') return AppColors.info;
    // Pre-game confirmation
    if (type == 'host_pre_game_confirm') return AppColors.green;
    // Streak types
    if (isStreakNotification(type)) return AppColors.gold;
    // Game alert deferred
    if (isGameAlertNotification(type)) return AppColors.navyDark;
    return AppColors.navyDark;
  }

  /// Returns a fallback title for notifications without a title.
  static String titleFallback(String type) {
    if (type == 'chat_message') {
      return 'New message';
    }
    if (isGameNotification(type)) {
      return 'New game posted';
    }
    if (type == 'attendance_dispute') {
      return 'Attendance Dispute';
    }
    if (type == 'dispute_resolved_cleared') {
      return 'Dispute Resolved';
    }
    if (type == 'dispute_resolved_upheld') {
      return 'Strike Added';
    }
    if (type == 'friend_game_created') {
      return 'A friend posted a game';
    }
    return 'Notification';
  }
}
