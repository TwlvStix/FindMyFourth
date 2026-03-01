import 'package:flutter/material.dart';

import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/models/chat_message.dart';
import '/models/chat_message_view_model.dart';
import 'chat_date_divider.dart';
import 'chat_message_bubble.dart';

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    super.key,
    required this.scrollController,
    required this.messageVMs,
    required this.hasMoreOlder,
    required this.isLoadingOlder,
    required this.currentUserId,
    required this.isGroupChat,
    required this.totalMembers,
    required this.onLoadOlderMessages,
    required this.onMessageLongPress,
    required this.onReplySwipe,
    required this.onImageTap,
    required this.onReactionTap,
    required this.showDateDivider,
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });

  final ScrollController scrollController;
  final List<ChatMessageViewModel> messageVMs;
  final bool hasMoreOlder;
  final bool isLoadingOlder;
  final String? currentUserId;
  final bool isGroupChat;
  final int totalMembers;
  final Future<void> Function() onLoadOlderMessages;
  final void Function(ChatMessage message) onMessageLongPress;
  final void Function(ChatMessage message) onReplySwipe;
  final void Function(String imageUrl) onImageTap;
  final Future<void> Function(
    ChatMessage message,
    String emoji,
    bool hasReacted,
  ) onReactionTap;
  final bool Function({
    required ChatMessageViewModel current,
    ChatMessageViewModel? previous,
  }) showDateDivider;
  final bool Function({
    required ChatMessageViewModel current,
    ChatMessageViewModel? previous,
  }) isFirstInGroup;
  final bool Function({
    required ChatMessageViewModel current,
    ChatMessageViewModel? next,
  }) isLastInGroup;

  @override
  Widget build(BuildContext context) {
    final itemCount = messageVMs.length + (hasMoreOlder ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      reverse: true,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (hasMoreOlder && index == messageVMs.length) {
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.md,
            ),
            child: Center(
              child: AppButtonEnhanced(
                text: 'Load earlier messages',
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.small,
                isLoading: isLoadingOlder,
                onPressed: onLoadOlderMessages,
              ),
            ),
          );
        }

        final vm = messageVMs[index];
        final message = vm.message;
        final isMe = message.senderId == currentUserId;
        final previous =
            index < messageVMs.length - 1 ? messageVMs[index + 1] : null;
        final next = index > 0 ? messageVMs[index - 1] : null;
        final shouldShowDateDivider =
            showDateDivider(current: vm, previous: previous);
        final firstInGroup = isFirstInGroup(current: vm, previous: previous);
        final lastInGroup = isLastInGroup(current: vm, next: next);
        final senderName = isMe
            ? null
            : vm.senderDisplayName.trim().isNotEmpty
                ? vm.senderDisplayName
                : 'Golfer';
        final senderPhotoUrl = isMe ? null : vm.senderPhotoUrl;

        return Column(
          children: [
            ChatMessageBubble(
              isSentByCurrentUser: isMe,
              messageText: message.text,
              imageUrl: message.imageUrl,
              imageWidth: message.imageWidth,
              imageHeight: message.imageHeight,
              timestamp: message.createdAt,
              isFirstInGroup: firstInGroup,
              isLastInGroup: lastInGroup,
              senderId: message.senderId,
              senderName: senderName,
              senderPhotoUrl: senderPhotoUrl,
              isGroupChat: isGroupChat,
              message: message,
              totalMembers: totalMembers,
              currentUserId: currentUserId,
              onLongPress: () => onMessageLongPress(message),
              onReplySwipe: () => onReplySwipe(message),
              onImageTap: message.imageUrl.isNotEmpty
                  ? () => onImageTap(message.imageUrl)
                  : null,
              onReactionTap: (emoji, hasReacted) =>
                  onReactionTap(message, emoji, hasReacted),
            ),
            if (shouldShowDateDivider && message.createdAt != null)
              ChatDateDivider(date: message.createdAt!),
          ],
        );
      },
    );
  }
}
