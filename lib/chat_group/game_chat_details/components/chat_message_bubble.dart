import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '/chat_group/game_chat_details/components/chat_bubble_image_attachment.dart';
import '/chat_group/game_chat_details/components/chat_bubble_reactions.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/utils/formatting_utils.dart';
import '/models/chat_message.dart';

/// A reusable message bubble component for chat interfaces.
///
/// Displays messages with different styling for sent vs received messages:
/// - Sent messages: aligned right, primary color background
/// - Received messages: aligned left, surface variant background
///
/// Features:
/// - Avatar display for received messages
/// - Sender name for group chats
/// - Image attachments
/// - Timestamps
/// - Read receipts for sent messages
/// - Reactions display
/// - Swipe-to-reply gesture
class ChatMessageBubble extends StatelessWidget {
  final bool isSentByCurrentUser;
  final String messageText;
  final String imageUrl;
  final double? imageWidth;
  final double? imageHeight;
  final DateTime? timestamp;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final String senderId;
  final String? senderName;
  final String? senderPhotoUrl;
  final bool isGroupChat;
  final ChatMessage message;
  final int totalMembers;
  final String? currentUserId;
  final VoidCallback? onLongPress;
  final VoidCallback? onReplySwipe;
  final VoidCallback? onImageTap;
  final Function(String emoji, bool hasReacted)? onReactionTap;

  const ChatMessageBubble({
    super.key,
    required this.isSentByCurrentUser,
    required this.messageText,
    this.imageUrl = '',
    this.imageWidth,
    this.imageHeight,
    this.timestamp,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    required this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    this.isGroupChat = false,
    required this.message,
    this.totalMembers = 2,
    this.currentUserId,
    this.onLongPress,
    this.onReplySwipe,
    this.onImageTap,
    this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isSentByCurrentUser
        ? AppColors.navyDark
        : AppColors.navy;
    final textColor = isSentByCurrentUser
        ? AppColors.pure
        : AppColors.pure;

    return Dismissible(
      key: Key('message_${message.id}'),
      direction: isSentByCurrentUser
          ? DismissDirection.endToStart
          : DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        onReplySwipe?.call();
        return false; // Don't actually dismiss
      },
      background: Container(
        alignment: isSentByCurrentUser
            ? Alignment.centerRight
            : Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: AppIcon(
          icon: AppPhosphorIcons.reply,
          color: AppColors.textSecondary,
          size: AppIconSize.md,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: isLastInGroup ? AppSpacing.xs : 2,
          bottom: isFirstInGroup ? AppSpacing.xs : 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: isSentByCurrentUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            // Avatar on left for received messages
            if (!isSentByCurrentUser) ...[
              SizedBox(width: AppSpacing.md),
              Container(
                width: 32,
                height: 32,
                margin: EdgeInsets.only(bottom: AppSpacing.xxs, right: AppSpacing.xs),
                child: isFirstInGroup
                    ? CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.navyDark
                            .withValues(alpha: 0.3),
                        backgroundImage: senderPhotoUrl != null &&
                                senderPhotoUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(senderPhotoUrl!)
                            : null,
                        child: senderPhotoUrl == null || senderPhotoUrl!.isEmpty
                            ? AppIcon(
                                icon: AppPhosphorIcons.profile,
                                size: AppIconSize.button,
                                color: AppColors.textSecondary,
                              )
                            : null,
                      )
                    : SizedBox.shrink(),
              ),
            ],
            // Message bubble
            Flexible(
              child: Column(
                crossAxisAlignment: isSentByCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Sender name for group chats (first message only)
                  if (!isSentByCurrentUser &&
                      isGroupChat &&
                      isFirstInGroup &&
                      senderName != null)
                    Padding(
                      padding: EdgeInsets.only(
                        left: AppSpacing.xs,
                        bottom: AppSpacing.xxs,
                      ),
                      child: Text(
                        senderName!,
                        style: AppTypography.labelMicro.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  // Message content
                  GestureDetector(
                    onLongPress: onLongPress,
                    child: Container(
                      margin: EdgeInsets.only(
                        left: isSentByCurrentUser ? 40 : 0,
                        right: isSentByCurrentUser ? 0 : 40,
                      ),
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                              isSentByCurrentUser || !isFirstInGroup
                                  ? AppBorderRadius.lg
                                  : AppBorderRadius.xs),
                          topRight: Radius.circular(
                              !isSentByCurrentUser || !isFirstInGroup
                                  ? AppBorderRadius.lg
                                  : AppBorderRadius.xs),
                          bottomLeft: Radius.circular(AppBorderRadius.lg),
                          bottomRight: Radius.circular(AppBorderRadius.lg),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: isSentByCurrentUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          // Image attachment
                          if (imageUrl.isNotEmpty)
                            ChatBubbleImageAttachment(
                              imageUrl: imageUrl,
                              imageWidth: imageWidth,
                              imageHeight: imageHeight,
                              messageText: messageText,
                              isSentByCurrentUser: isSentByCurrentUser,
                              textColor: textColor,
                              onImageTap: onImageTap,
                            ),
                          // Message text
                          if (message.isFlagged)
                            Text(
                              'This message was filtered for inappropriate content.',
                              style: AppTypography.bodySmall.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                            )
                          else if (messageText.isNotEmpty)
                            Text(
                              messageText,
                              style: AppTypography.bodyMedium.copyWith(
                                color: textColor,
                              ),
                            ),
                          // Timestamp and read receipts
                          if (timestamp != null && isLastInGroup) ...[
                            AppSpacing.verticalXxs,
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  dateTimeFormat('jm', timestamp!),
                                  style: AppTypography.labelMicro.copyWith(
                                    color: textColor.withValues(alpha: 0.6),
                                  ),
                                ),
                                // Read receipts for sent messages
                                if (isSentByCurrentUser) ...[
                                  AppSpacing.horizontalXxs,
                                  AppIcon(
                                    icon: message.readBy.length > 1
                                        ? AppPhosphorIcons.checks
                                        : AppPhosphorIcons.check,
                                    size: AppIconSize.xs,
                                    color: message.readBy.length > 1
                                        ? AppColors.green
                                        : textColor.withValues(alpha: 0.6),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Reactions
                  if (message.reactions.isNotEmpty) ...[
                    AppSpacing.verticalXxs,
                    ChatBubbleReactions(
                      reactions: message.reactions,
                      currentUserId: currentUserId,
                      isSentByCurrentUser: isSentByCurrentUser,
                      onReactionTap: onReactionTap,
                    ),
                  ],
                ],
              ),
            ),
            // Spacing on right for sent messages
            if (isSentByCurrentUser) SizedBox(width: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
