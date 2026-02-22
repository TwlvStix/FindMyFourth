import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '/models/chat_message.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';

/// Chat input bar component with message field and send button.
///
/// Features:
/// - Text input field with multiline support
/// - Send button (disabled when empty)
/// - Reply-to preview (optional)
/// - Handles keyboard and focus
///
/// Generic for any chat context - not game-specific.
class ChatInputBar extends StatelessWidget {
  final TextEditingController messageController;
  final FocusNode messageFocusNode;
  final bool enabled;
  final VoidCallback onSendMessage;
  final ChatMessage? replyToMessage;
  final VoidCallback? onCancelReply;
  final String placeholder;
  final VoidCallback? onAttachImage;

  const ChatInputBar({
    super.key,
    required this.messageController,
    required this.messageFocusNode,
    this.enabled = true,
    required this.onSendMessage,
    this.replyToMessage,
    this.onCancelReply,
    this.placeholder = 'Message...',
    this.onAttachImage,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint(
        '🧩 UI: ChatInputBar build enabled=$enabled '
        'ctrl=${messageController.hashCode} '
        'focus=${messageFocusNode.hashCode}',
      );
    }
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.navyDarkBackground,
        boxShadow: [
          BoxShadow(
            blurRadius: 6.0,
            color: AppColors.overlayDark,
            offset: Offset(0.0, -2.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply preview
          if (replyToMessage != null)
            Container(
              margin: EdgeInsets.only(bottom: AppSpacing.sm),
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.navyBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: AppColors.navyDark,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replying to',
                          style: AppTypography.labelSmall.override(
                                color: AppColors.navyDark,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.0,
                              ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          replyToMessage!.text.isNotEmpty
                              ? replyToMessage!.text
                              : 'Image',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.override(
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: 0.0,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    onPressed: onCancelReply,
                  ),
                ],
              ),
            ),
          // Input row
          Row(
            children: [
              // Image attachment button
              GestureDetector(
                onTap: (enabled && onAttachImage != null) ? onAttachImage : null,
                child: Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm),
                  child: Icon(
                    Icons.image_rounded,
                    size: 26,
                    color: (enabled && onAttachImage != null)
                        ? AppColors.navyDark
                        : AppColors.navyText.withValues(alpha: 0.4),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: messageController,
                  focusNode: messageFocusNode,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 5,
                  enabled: enabled,
                  onChanged: (value) {
                    if (kDebugMode) {
                      debugPrint(
                        '✍️ UI: ChatInputBar onChanged len=${value.length}',
                      );
                    }
                  },
                  style: AppTypography.bodyMedium.override(
                        letterSpacing: 0.0,
                      ),
                  decoration: InputDecoration(
                    hintText: enabled ? placeholder : 'Chat closed',
                    hintStyle: AppTypography.bodyMedium.override(
                          color: AppColors.slate
                              .withValues(alpha: 0.6),
                          letterSpacing: 0.0,
                        ),
                    filled: true,
                    fillColor: AppColors.navyBackground,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide(
                        color: AppColors.navyDark.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: messageController,
                builder: (context, value, child) {
                  final hasText = value.text.trim().isNotEmpty;
                  return Container(
                    decoration: BoxDecoration(
                      color: enabled && hasText
                          ? AppColors.navyDark
                          : AppColors.navyBackground,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        color: enabled && hasText
                            ? Colors.white
                            : AppColors.navyText,
                      ),
                      onPressed: enabled && hasText ? onSendMessage : null,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
