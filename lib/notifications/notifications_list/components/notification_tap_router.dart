import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/navigation/nav_extensions.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/notifications/components/pre_game_confirm_bottom_sheet.dart';
import '/providers/notification_list_provider.dart';
import 'notification_type_helpers.dart';

/// Handles tap navigation for different notification types.
///
/// Routes to the appropriate screen based on notification type:
/// - Game notifications → game detail
/// - Chat messages → chat thread
/// - Trust notifications → trust profile or standing
/// - Friend requests → friends tab
/// - Badge notifications → main profile
class NotificationTapRouter {
  NotificationTapRouter._();

  /// Routes to the appropriate screen for the given notification.
  ///
  /// Returns a [Future] that completes when navigation is done.
  /// [onMarkRead] should be called before navigation to mark the notification read.
  static Future<void> handleTap({
    required BuildContext context,
    required NotificationListItem item,
    required NotificationListProvider provider,
    required DocumentReference? currentUserRef,
    required Future<void> Function() onMarkRead,
  }) async {
    await onMarkRead();

    if (!context.mounted) return;

    final type = item.type;
    final payload = item.data;

    if (NotificationTypeHelpers.isGameNotification(type)) {
      await _handleGameNotification(
        context: context,
        provider: provider,
        payload: payload,
        currentUserRef: currentUserRef,
        notificationType: type,
      );
      return;
    }

    if (type == 'chat_message') {
      final chatId = payload['threadId'] ?? payload['chatId'];
      if (chatId is String && chatId.isNotEmpty) {
        context.pushChatDetails(chatId: chatId);
      }
      return;
    }

    if (type == 'dispute_resolved_upheld') {
      context.pushYourStanding();
      return;
    }

    // Pre-game confirmation (host confirms/cancels partial game)
    if (type == 'host_pre_game_confirm') {
      final gameId = payload['gameId'] ?? payload['game_id'];
      final courseName =
          payload['course_name'] ?? payload['courseName'] ?? 'your course';
      final gameDate =
          payload['game_date'] ?? payload['gameDate'] ?? 'your upcoming round';

      if (gameId is String && gameId.isNotEmpty) {
        await showPreGameConfirmBottomSheet(
          context: context,
          gameId: gameId,
          courseName: courseName.toString(),
          gameDate: gameDate.toString(),
          onConfirmed: () {
            final gameRef = provider.resolveGameRefFromPayload(payload);
            if (gameRef != null) {
              context.pushJoinGameDetailed(gameRef: gameRef);
            }
          },
          onCancelled: () {
            context.pushGamesList();
          },
        );
      }
      return;
    }

    if (NotificationTypeHelpers.isTrustGameNotification(type)) {
      await _handleGameNotification(
        context: context,
        provider: provider,
        payload: payload,
        currentUserRef: currentUserRef,
        notificationType: type,
      );
      return;
    }

    if (NotificationTypeHelpers.isTrustAccountNotification(type)) {
      context.pushYourStanding();
      return;
    }

    if (NotificationTypeHelpers.isBadgeNotification(type)) {
      context.pushMainProfile();
      return;
    }

    if (type == 'friend_request_received') {
      context.pushTabFriends(initialSegment: 'requests');
      return;
    }

    if (type == 'friend_request_accepted') {
      context.pushTabFriends(initialSegment: 'friends');
      return;
    }

    // Join request types
    if (type == 'join_request_new' || type == 'join_request_approved') {
      // Host receiving new request or player approved - show game details
      await _handleGameNotification(
        context: context,
        provider: provider,
        payload: payload,
        currentUserRef: currentUserRef,
        notificationType: type,
      );
      return;
    }

    if (type == 'join_request_declined' ||
        type == 'join_request_round_filled' ||
        type == 'join_request_expired') {
      // Player's request was declined/expired or round filled - show games list
      context.pushGamesList();
      return;
    }

    // Host-add-player types
    if (type == 'player_added_by_host') {
      // Player was added to game - show game details
      await _handleGameNotification(
        context: context,
        provider: provider,
        payload: payload,
        currentUserRef: currentUserRef,
        notificationType: type,
      );
      return;
    }

    if (type == 'player_declined_spot') {
      // Host notified player declined - show game details
      await _handleGameNotification(
        context: context,
        provider: provider,
        payload: payload,
        currentUserRef: currentUserRef,
        notificationType: type,
      );
      return;
    }

    // Streak notifications
    if (NotificationTypeHelpers.isStreakNotification(type)) {
      if (type == 'streak_weekend_nudge') {
        context.pushGamesList();
      } else {
        // Other streak types go to profile
        context.pushMainProfile();
      }
      return;
    }

    // Deferred game alerts
    if (NotificationTypeHelpers.isGameAlertNotification(type)) {
      await _handleGameNotification(
        context: context,
        provider: provider,
        payload: payload,
        currentUserRef: currentUserRef,
        notificationType: type,
      );
      return;
    }
  }

  static Future<void> _handleGameNotification({
    required BuildContext context,
    required NotificationListProvider provider,
    required Map<String, dynamic> payload,
    required DocumentReference? currentUserRef,
    String? notificationType,
  }) async {
    final gameRef = provider.resolveGameRefFromPayload(payload);
    if (gameRef == null) return;

    // Skip friends-only check for host-specific notification types —
    // the host always has access to their own game.
    final isHostNotification = notificationType != null &&
        NotificationTypeHelpers.isHostNotificationType(notificationType);

    if (currentUserRef != null && !isHostNotification) {
      final shouldBlock = await provider.shouldBlockFriendsOnlyGame(
        gameRef,
        currentUserRef,
      );
      if (shouldBlock) {
        if (!context.mounted) return;
        await _showFriendsOnlyDialog(context);
        return;
      }
    }

    if (!context.mounted) return;
    context.pushJoinGameDetailed(
      gameRef: gameRef,
      skipFriendsOnlyCheck: isHostNotification,
    );
  }

  static Future<void> _showFriendsOnlyDialog(BuildContext context) async {
    await showPremiumDialog(
      context: context,
      variant: PremiumDialogVariant.informational,
      icon: PhosphorIconsRegular.lock,
      title: 'Friends Only Game',
      body:
          'This game is visible to friends only. Add the host as a friend to view details.',
      actionLabel: 'Got It',
    );
  }
}
