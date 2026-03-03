import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';

class CinematicFoursomeToast extends StatelessWidget {
  const CinematicFoursomeToast({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: AppSpacing.symmetric(horizontal: 14, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDark.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkmark icon
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.pure,
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                icon: AppPhosphorIcons.check,
                size: AppIconSize.button,
                color: AppColors.navy,
              ),
            ),
            AppSpacing.horizontal(10),
            // Text column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Foursome Complete!',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pure,
                  ),
                ),
                AppSpacing.vertical(1),
                Text(
                  'Ryan\'s group is ready to go',
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.glassTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
