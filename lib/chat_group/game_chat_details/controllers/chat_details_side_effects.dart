import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/colors.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/core/motion/motion_helpers.dart';
import '/providers/chat_provider.dart';

class ChatDetailsSideEffects {
  static Future<void> markChatSeen({
    required ChatProvider chatProvider,
    required String chatId,
    required String uid,
    required DateTime? visibleAfter,
    required bool Function() isMounted,
  }) async {
    try {
      if (kDebugMode) {
        AppLog.d('📖 UI: _markChatSeen called for chatId=$chatId');
      }

      await chatProvider.markChatRead(chatId: chatId, uid: uid);
      if (!isMounted()) return;

      final stats = await chatProvider.markMessagesAsReadBatch(
        chatId: chatId,
        uid: uid,
        limit: 100,
        visibleAfter: visibleAfter,
      );
      if (!isMounted()) return;

      chatProvider
          .markChatNotificationsAsRead(chatId: chatId, uid: uid)
          .catchError(
        (Object error, StackTrace stackTrace) {
          if (!isMounted()) return;
          chatProvider.logError(
            'markChatNotificationsAsRead failed',
            error,
            stackTrace,
          );
        },
      );

      if (kDebugMode) {
        AppLog.d(
          '✅ UI: _markChatSeen complete - ${stats['unreadCount']} unread messages, '
          '${stats['updatedCount']} updated in ${stats['batchCount']} batch(es)',
        );
      }
    } catch (error, stackTrace) {
      if (!isMounted()) return;
      chatProvider.logError('markChatRead failed', error, stackTrace);
    }
  }

  static Future<void> showDeleteConfirmation({
    required BuildContext context,
    required String chatId,
    required String uid,
    required ChatProvider chatProvider,
  }) async {
    final confirmed = await showPremiumDialog(
      context: context,
      variant: PremiumDialogVariant.destructive,
      icon: PhosphorIconsRegular.trash,
      title: 'Delete Chat',
      body:
          'This will permanently delete all messages in this chat. This action cannot be undone.',
      actionLabel: 'Delete',
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      await _deleteChat(
        context: context,
        chatId: chatId,
        uid: uid,
        chatProvider: chatProvider,
      );
    }
  }

  /// Show confirmation dialog for leaving a chat.
  ///
  /// Checks if the user is the last member and shows appropriate warning.
  /// If confirmed, leaves the chat (or deletes it if last member).
  ///
  /// [onLeaveStarted] is called just before the leave operation begins.
  /// [onLeaveFailed] is called if the leave operation fails.
  static Future<void> showLeaveConfirmation({
    required BuildContext context,
    required String chatId,
    required String uid,
    required ChatProvider chatProvider,
    VoidCallback? onLeaveStarted,
    VoidCallback? onLeaveFailed,
  }) async {
    // Check if user is the last member
    final isLast = await chatProvider.isLastMember(chatId: chatId, uid: uid);

    if (!context.mounted) return;

    final bool confirmed;
    if (isLast) {
      // Show special warning for last member
      confirmed = await showPremiumDialog(
        context: context,
        variant: PremiumDialogVariant.destructive,
        icon: PhosphorIconsRegular.signOut,
        title: "You're the last person in this chat",
        body:
            'Leaving will permanently delete the chat and all messages. This cannot be undone.',
        actionLabel: 'Leave & Delete',
      ) ?? false;
    } else {
      // Standard leave confirmation
      confirmed = await showPremiumDialog(
        context: context,
        variant: PremiumDialogVariant.destructive,
        icon: PhosphorIconsRegular.signOut,
        title: 'Leave Chat',
        body:
            'You will no longer receive messages from this chat. You can rejoin later if invited.',
        actionLabel: 'Leave',
      ) ?? false;
    }

    if (confirmed) {
      if (!context.mounted) return;
      await _leaveChat(
        context: context,
        chatId: chatId,
        uid: uid,
        chatProvider: chatProvider,
        wasLastMember: isLast,
        onLeaveStarted: onLeaveStarted,
        onLeaveFailed: onLeaveFailed,
      );
    }
  }

  static Future<void> _leaveChat({
    required BuildContext context,
    required String chatId,
    required String uid,
    required ChatProvider chatProvider,
    required bool wasLastMember,
    VoidCallback? onLeaveStarted,
    VoidCallback? onLeaveFailed,
  }) async {
    AppLog.d('🔵 UI: Leave chat button pressed');
    AppLog.d('🔵 UI: chatId=$chatId, userId=$uid, wasLastMember=$wasLastMember');

    if (!context.mounted) return;
    showAppDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            color: AppColors.navyDark,
          ),
        );
      },
    );

    // Set guard flag before leave operation
    onLeaveStarted?.call();

    try {
      await chatProvider.leaveChat(chatId: chatId, uid: uid);
      AppLog.d('✅ UI: Left chat successfully');

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Dismiss loading
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Go back from chat

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasLastMember ? 'Chat deleted' : 'Left chat'),
          backgroundColor: AppColors.navyDark,
        ),
      );
    } catch (error, stackTrace) {
      // Reset guard flag on failure
      onLeaveFailed?.call();

      AppLog.d('❌ UI: Failed to leave chat: $error');
      chatProvider.logError('leaveChat failed', error, stackTrace);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Dismiss loading
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to leave chat: ${error.toString().length > 50 ? error.toString().substring(0, 50) : error.toString()}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  static Future<void> _deleteChat({
    required BuildContext context,
    required String chatId,
    required String uid,
    required ChatProvider chatProvider,
  }) async {
    AppLog.d('🔵 UI: Delete chat button pressed');
    AppLog.d('🔵 UI: chatId=$chatId, userId=$uid');

    if (!context.mounted) return;
    showAppDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            color: AppColors.navyDark,
          ),
        );
      },
    );

    try {
      await chatProvider.deleteChat(chatId: chatId, uid: uid);
      AppLog.d('✅ UI: Chat deleted successfully');

      if (!context.mounted) return;
      Navigator.of(context).pop();
      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Chat deleted successfully'),
          backgroundColor: AppColors.navyDark,
        ),
      );
    } catch (error, stackTrace) {
      AppLog.d('❌ UI: Failed to delete chat: $error');
      chatProvider.logError('deleteChat failed', error, stackTrace);

      if (!context.mounted) return;
      Navigator.of(context).pop();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete chat: ${error.toString().length > 50 ? error.toString().substring(0, 50) : error.toString()}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
