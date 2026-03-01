import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

class ChatTypingIndicator extends StatelessWidget {
  const ChatTypingIndicator({
    super.key,
    required this.typingText,
  });

  final String? typingText;

  @override
  Widget build(BuildContext context) {
    final hasTyping = typingText != null && typingText!.trim().isNotEmpty;

    return ClipRect(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: !hasTyping
            ? const SizedBox(height: 0)
            : Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.glassTextSecondary,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      typingText!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.glassTextSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
