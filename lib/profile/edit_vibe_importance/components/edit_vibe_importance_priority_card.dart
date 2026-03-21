import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/motion_tokens.dart';
import '/core/widgets/app_icon.dart';

class EditVibeImportancePriorityCard extends StatelessWidget {
  const EditVibeImportancePriorityCard({
    required this.title,
    required this.valueLabel,
    required this.isSelected,
    required this.isDealbreaker,
    required this.onTap,
    super.key,
  });

  final String title;
  final String valueLabel;
  final bool isSelected;
  final bool isDealbreaker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionTokens.contentReveal,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.green.withValues(alpha: 0.15)
              : AppColors.navyLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: isSelected ? AppColors.green : AppColors.glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected ? AppColors.pure : AppColors.sand,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                ),
                if (isSelected)
                  AppIcon(
                    icon: AppPhosphorIcons.success,
                    color: AppColors.green,
                    size: AppIconSize.sm,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.green.withValues(alpha: 0.1)
                    : AppColors.navyLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Text(
                valueLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? AppColors.pure : AppColors.stone,
                  letterSpacing: AppTypography.letterSpacingNormal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isDealbreaker) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    icon: AppPhosphorIcons.blocked,
                    color: AppColors.gold,
                    size: AppIconSize.xs,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Dealbreaker',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.gold,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
