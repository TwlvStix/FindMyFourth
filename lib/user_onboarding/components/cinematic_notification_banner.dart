import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';

class CinematicNotificationBanner extends StatelessWidget {
  const CinematicNotificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.symmetric(horizontal: AppSpacing.sm),
      child: Container(
        margin: AppSpacing.only(top: AppSpacing.xs),
        padding: AppSpacing.allXs,
        decoration: BoxDecoration(
          color: AppColors.pure,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.overlayDark,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // App icon
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.navyDark, AppColors.green],
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Center(
                child: AppIcon(
                  icon: AppPhosphorIcons.golfCourse,
                  color: AppColors.pure,
                  size: AppIconSize.button,
                ),
              ),
            ),
            AppSpacing.horizontal(10),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FIND MY FOURTH',
                    style: AppTypography.overline.copyWith(
                      fontSize: 10,
                      color: AppColors.slate,
                      letterSpacing: 0.4,
                    ),
                  ),
                  AppSpacing.vertical(2),
                  Text(
                    'New Game Match',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 13,
                      color: AppColors.onyx,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.vertical(1),
                  Text(
                    'Match Play · Meadow Creek · Saturday 8:40 AM',
                    style: AppTypography.timestamp.copyWith(
                      fontSize: 11,
                      color: AppColors.slate,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
