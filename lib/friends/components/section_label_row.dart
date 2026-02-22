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
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              fontSize: 11,
              letterSpacing: 1.5,
              color: AppColors.gold.withValues(alpha: 0.8),
            ),
          ),
          Text(
            '$count $countLabel',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
