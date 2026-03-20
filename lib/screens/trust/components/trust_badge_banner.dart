import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_icon.dart';
import 'badge_info.dart';

class TrustBadgeBanner extends StatelessWidget {
  const TrustBadgeBanner({
    super.key,
    required this.badgeLevel,
    required this.joinedYear,
  });

  final String badgeLevel;
  final String joinedYear;

  @override
  Widget build(BuildContext context) {
    final info = badgeInfo(badgeLevel);

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            info.gradientStart,
            info.gradientEnd,
            info.gradientEnd.withValues(alpha: 0.93),
          ],
          stops: [0.0, 0.6, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppBorderRadius.xl),
          topRight: Radius.circular(AppBorderRadius.xl),
        ),
      ),
      child: Stack(
        children: [
          // Shine overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppBorderRadius.xl),
                  topRight: Radius.circular(AppBorderRadius.xl),
                ),
                gradient: LinearGradient(
                  colors: [
                    AppColors.glassSurface,
                    AppColors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  border: Border.all(
                    color: AppColors.glassTextTertiary,
                    width: 1.5,
                  ),
                ),
                child: AppIcon(
                  icon: info.icon,
                  color: AppColors.pure,
                  size: AppIconSize.md,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.label,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.pure,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      info.description,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.glassTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Joined year badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(
                    color: AppColors.glassSurface,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      joinedYear,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.pure,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'JOINED',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.glassTextSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
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
