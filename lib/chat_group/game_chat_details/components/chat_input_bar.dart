import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '/models/chat_message.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_icon.dart';

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
        color: AppColors.navyDark,
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
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
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
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.navyDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppSpacing.verticalXxs,
                        Text(
                          replyToMessage!.text.isNotEmpty
                              ? replyToMessage!.text
                              : 'Image',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: AppIcon(
                      icon: AppPhosphorIcons.close,
                      size: AppIconSize.button,
                      color: AppColors.pure.withValues(alpha: 0.6),
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
                  child: AppIcon(
                    icon: AppPhosphorIcons.image,
                    size: AppIconSize.md,
                    color: (enabled && onAttachImage != null)
                        ? AppColors.navyDark
                        : AppColors.pure.withValues(alpha: 0.4),
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
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: enabled ? placeholder : 'Chat closed',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.slate.withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: AppColors.navy,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.xl),
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
                          : AppColors.navy,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: AppIcon(
                        icon: AppPhosphorIcons.send,
                        size: AppIconSize.md,
                        color: enabled && hasText
                            ? AppColors.pure
                            : AppColors.pure.withValues(alpha: 0.5),
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
