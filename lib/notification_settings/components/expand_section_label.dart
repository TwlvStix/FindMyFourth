import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';

/// Tiny section label for expanded notification card areas.
///
/// Displays uppercase text with optional top divider,
/// used for "DELIVERY", "ACTIVE DAYS" etc. labels.
class ExpandSectionLabel extends StatelessWidget {
  const ExpandSectionLabel({
    super.key,
    required this.text,
    this.showDivider = false,
  });

  /// Label text (will be uppercased automatically)
  final String text;

  /// Whether to show a subtle top divider
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDivider) ...[
          Divider(
            color: AppColors.navyLight.withValues(alpha: 0.3),
            height: 1,
            thickness: 1,
          ),
        ],
        Padding(
          padding: EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            text.toUpperCase(),
            style: AppTypography.labelMicro.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}
