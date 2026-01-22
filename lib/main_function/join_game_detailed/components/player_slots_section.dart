import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

/// Player slots section header showing total player count
class PlayerSlotsSectionHeader extends StatelessWidget {
  const PlayerSlotsSectionHeader({
    super.key,
    required this.currentCount,
    required this.maxCount,
  });

  final int currentCount;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          'Players',
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: AppColors.sunsetGold.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$currentCount/$maxCount',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.sunsetGold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
