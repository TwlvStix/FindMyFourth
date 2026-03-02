import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';

/// A styled bubble for system messages in chat.
///
/// System messages are centered, use muted styling, and have no avatar.
/// They're used for lifecycle notifications like:
/// - Game cancellation
/// - Chat deletion warnings
/// - Member join/leave events
class ChatSystemMessageBubble extends StatelessWidget {
  const ChatSystemMessageBubble({
    super.key,
    required this.text,
    this.timestamp,
  });

  final String text;
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(
              color: AppColors.navyLight.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}
