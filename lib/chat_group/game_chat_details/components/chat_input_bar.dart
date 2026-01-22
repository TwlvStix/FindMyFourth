import 'package:flutter/material.dart';
import '/models/chat_message.dart';
import '/core/app_theme.dart';
import '/core/design_tokens/spacing.dart';

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

  const ChatInputBar({
    super.key,
    required this.messageController,
    required this.messageFocusNode,
    this.enabled = true,
    required this.onSendMessage,
    this.replyToMessage,
    this.onCancelReply,
    this.placeholder = 'Message...',
  });

  @override
  Widget build(BuildContext context) {
    final hasText = messageController.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppTheme.of(context).primaryBackground,
        boxShadow: const [
          BoxShadow(
            blurRadius: 6.0,
            color: Color(0x22000000),
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
                color: AppTheme.of(context).secondaryBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: AppTheme.of(context).primary,
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
                          style: AppTheme.of(context).labelSmall.override(
                                color: AppTheme.of(context).primary,
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
                          style: AppTheme.of(context).bodySmall.override(
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
              Expanded(
                child: TextField(
                  controller: messageController,
                  focusNode: messageFocusNode,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 5,
                  enabled: enabled,
                  style: AppTheme.of(context).bodyMedium.override(
                        letterSpacing: 0.0,
                      ),
                  decoration: InputDecoration(
                    hintText: enabled ? placeholder : 'Chat closed',
                    hintStyle: AppTheme.of(context).bodyMedium.override(
                          color: AppTheme.of(context)
                              .secondaryText
                              .withValues(alpha: 0.6),
                          letterSpacing: 0.0,
                        ),
                    filled: true,
                    fillColor: AppTheme.of(context).secondaryBackground,
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
                        color: AppTheme.of(context).primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: enabled && hasText
                      ? AppTheme.of(context).primary
                      : AppTheme.of(context).secondaryBackground,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    color: enabled && hasText
                        ? Colors.white
                        : AppTheme.of(context).secondaryText,
                  ),
                  onPressed: enabled && hasText ? onSendMessage : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
