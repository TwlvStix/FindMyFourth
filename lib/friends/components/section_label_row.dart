import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

/// Section label row showing context (e.g., "RECOMMENDED FOR YOU") and item count.
class SectionLabelRow extends StatelessWidget {
  final String label;
  final int count;
  final String countLabel;

  const SectionLabelRow({
    super.key,
    required this.label,
    required this.count,
    this.countLabel = 'golfers',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xxs,
        right: AppSpacing.xxs,
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              fontSize: 11,
              letterSpacing: 0.8,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            '$count $countLabel',
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
