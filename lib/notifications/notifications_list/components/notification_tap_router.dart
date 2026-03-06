import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/navigation/nav_extensions.dart';
import '/core/widgets/app_premium_dialog.dart';
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

    if (NotificationTypeHelpers.isTrustGameNotification(type)) {
      await _handleGameNotification(
        context: context,
        provider: provider,
        payload: payload,
        currentUserRef: currentUserRef,
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
  }

  static Future<void> _handleGameNotification({
    required BuildContext context,
    required NotificationListProvider provider,
    required Map<String, dynamic> payload,
    required DocumentReference? currentUserRef,
  }) async {
    final gameRef = provider.resolveGameRefFromPayload(payload);
    if (gameRef == null) return;

    if (currentUserRef != null) {
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
    context.pushJoinGameDetailed(gameRef: gameRef);
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
