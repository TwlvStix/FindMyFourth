import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_expandable_text.dart';
import '/core/widgets/app_icon.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/models/game.dart';

/// Premium hero section displaying game title, course, date/time with gradient background
class PremiumHeroSection extends StatelessWidget {
  const PremiumHeroSection({
    super.key,
    required this.game,
  });

  final Game game;

  @override
  Widget build(BuildContext context) {
    final isCancelled = game.isCancelledStatus;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navy.withValues(alpha: 0.4),
            AppColors.navyDark.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
        border: Border.all(
          color: AppColors.navyLight,
          width: 1,
        ),
        boxShadow: [AppElevation.xl],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge - shows Cancelled or Joined
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCancelled
                    ? [AppColors.stone, AppColors.stone]
                    : [AppColors.green, AppColors.greenLight],
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  icon: isCancelled ? AppPhosphorIcons.blocked : AppPhosphorIcons.joined,
                  color: AppColors.pure,
                  size: AppIconSize.xs,
                ),
                const SizedBox(width: 4),
                Text(
                  isCancelled ? 'Cancelled' : 'Joined',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          // Course name with golf icon
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.navyLight, AppColors.navy],
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  boxShadow: [AppElevation.md],
                ),
                child: Center(
                  child: AppIcon(
                    icon: AppPhosphorIcons.course,
                    color: AppColors.pure,
                    size: AppIconSize.md,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppExpandableText(
                      text: game.coursePlay,
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                    ),
                    Text(
                      game.nameGame,
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
