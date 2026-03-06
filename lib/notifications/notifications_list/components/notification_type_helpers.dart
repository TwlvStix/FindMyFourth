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

  /// Returns true for trust system game-related notification types.
  static bool isTrustGameNotification(String type) {
    return const {
      'host_checkin_due',
      'player_rate_due',
      'host_checkin_fallback',
      'player_fallback_confirm',
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
    return const {'friend_request_received', 'friend_request_accepted'}
        .contains(type);
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
        type == 'player_fallback_confirm') {
      return AppPhosphorIcons.calendarCheck;
    }
    if (type == 'player_rate_due') return AppPhosphorIcons.star;
    if (type == 'game_spot_opened' || type == 'game_cancelled') {
      return AppPhosphorIcons.games;
    }
    if (isTrustAccountNotification(type)) {
      return type == 'dispute_resolved' || type == 'restriction_ended'
          ? AppPhosphorIcons.trust
          : AppPhosphorIcons.warning;
    }
    if (isBadgeNotification(type)) return AppPhosphorIcons.badge;
    if (type == 'friend_request_received') return AppPhosphorIcons.addPlayer;
    if (type == 'friend_request_accepted') return AppPhosphorIcons.golfers;
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
    return 'Notification';
  }
}
