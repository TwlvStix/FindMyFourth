import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/design_tokens/colors.dart';
import '/core/motion/motion_helpers.dart';
import '/models/chat.dart';
import '/models/chat_message.dart';
import '/providers/block_provider.dart';
import '/providers/chat_provider.dart';
import '/providers/profile_provider.dart';
import '../components/chat_image_viewer.dart';
import 'chat_details_controller.dart';
import 'chat_details_side_effects.dart';

/// Controller for message interaction callbacks: reactions, replies,
/// sending, loading older messages, and user moderation actions.
///
/// Follows the ChatImageUploadController callback-injection pattern.
class ChatMessageActionsController {
  ChatMessageActionsController({
    required this.chatId,
    required this.getCurrentUserId,
    required this.onStateChanged,
    required this.isMounted,
    required this.getChatUi,
    required this.getLastStreamDoc,
    required this.detailsController,
  });

  final String chatId;
  final String? Function() getCurrentUserId;
  final VoidCallback onStateChanged;
  final bool Function() isMounted;
  final Chat? Function() getChatUi;
  final DocumentSnapshot? Function() getLastStreamDoc;
  final ChatDetailsController<DocumentSnapshot> detailsController;

  // State
  ChatMessage? _replyToMessage;
  bool _isLeavingChat = false;

  ChatMessage? get replyToMessage => _replyToMessage;
  bool get isLeavingChat => _isLeavingChat;

  void setReplyTo(ChatMessage message) {
    _replyToMessage = message;
    onStateChanged();
  }

  void clearReply() {
    _replyToMessage = null;
    onStateChanged();
  }

  // -- Reactions --

  Future<void> handleReaction(
    BuildContext context,
    ChatMessage message,
    String emoji,
    bool hasReacted,
  ) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return;

    if (hasReacted) {
      await context.read<ChatProvider>().removeReaction(
            chatId: chatId,
            messageId: message.id,
            emoji: emoji,
            uid: currentUserId,
          );
    } else {
      await context.read<ChatProvider>().addReaction(
            chatId: chatId,
            messageId: message.id,
            emoji: emoji,
            uid: currentUserId,
          );
    }
  }

  void showReactionPicker(BuildContext context, ChatMessage message) {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return;

    ChatDetailsSideEffects.showReactionPicker(
      context: context,
      outerContext: context,
      message: message,
      currentUserId: currentUserId,
      chatId: chatId,
      onReactionToggled: (msg, emoji, hasReacted) =>
          handleReaction(context, msg, emoji, hasReacted),
    );
  }

  // -- Image fullscreen --

  void showImageFullscreen(BuildContext context, String imageUrl) {
    showAppDialog(
      context: context,
      barrierColor: AppColors.dialogBarrier,
      builder: (BuildContext dialogContext) => ChatImageViewer(
        imageUrl: imageUrl,
        onClose: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  // -- User moderation --

  void showReportUser(BuildContext context) {
    final otherUid = ChatDetailsSideEffects.otherUserIdInDirectChat(
      getChatUi(),
      getCurrentUserId(),
    );
    if (otherUid == null || otherUid.isEmpty) return;
    ChatDetailsSideEffects.showReportUser(
      context: context,
      otherUid: otherUid,
      chatId: chatId,
    );
  }

  Future<void> handleBlockUser(BuildContext context) async {
    final otherUid = ChatDetailsSideEffects.otherUserIdInDirectChat(
      getChatUi(),
      getCurrentUserId(),
    );
    if (otherUid == null || otherUid.isEmpty) return;
    final currentUid = getCurrentUserId();
    if (currentUid == null) return;

    if (!context.mounted) return;
    await ChatDetailsSideEffects.handleBlockUser(
      context: context,
      otherUid: otherUid,
      currentUid: currentUid,
      blockProvider: context.read<BlockProvider>(),
    );
  }

  Future<void> showLeaveConfirmation(BuildContext context) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null || !context.mounted) return;
    await ChatDetailsSideEffects.showLeaveConfirmation(
      context: context,
      chatId: chatId,
      uid: currentUserId,
      chatProvider: context.read<ChatProvider>(),
      onLeaveStarted: () => _isLeavingChat = true,
      onLeaveFailed: () => _isLeavingChat = false,
    );
  }

  // -- Messaging --

  Future<void> sendMessage(
    BuildContext context,
    TextEditingController messageController,
  ) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return;

    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();
    final replyTo = _replyToMessage;
    _replyToMessage = null;
    onStateChanged();

    try {
      await context.read<ChatProvider>().sendMessage(
            chatId: chatId,
            senderId: currentUserId,
            text: text,
          );
      // TODO: In a full implementation, we would store the replyTo message ID
      // in the message document and display it in the message bubble
    } catch (error, stackTrace) {
      if (!context.mounted) return;
      context
          .read<ChatProvider>()
          .logError('sendMessage failed', error, stackTrace);
      if (!context.mounted) return;
      messageController.text = text;
      _replyToMessage = replyTo;
      onStateChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to send message. Please try again.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => sendMessage(context, messageController),
          ),
        ),
      );
    }
  }

  // -- Pagination --

  Future<void> loadOlderMessages(BuildContext context) async {
    final chatProvider = context.read<ChatProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final statusFuture = detailsController.loadOlderMessagesFromProviders(
      startAfterCursor: getLastStreamDoc(),
      chatProvider: chatProvider,
      profileProvider: profileProvider,
    );
    if (!isMounted()) return;
    onStateChanged();

    final status = await statusFuture;
    if (!isMounted()) return;

    if (status.isError) {
      chatProvider.logError(
        'loadOlderMessages failed',
        status.error ?? Exception(status.errorMessage ?? 'Unknown error'),
        status.stackTrace ?? StackTrace.current,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load older messages.'),
        ),
      );
    }

    if (isMounted()) {
      onStateChanged();
    }
  }
}
