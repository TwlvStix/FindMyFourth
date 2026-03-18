import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_stat_card.dart';
import '/services/vibe_matcher.dart';

class ProfileStatsSection extends StatelessWidget {
  const ProfileStatsSection({
    super.key,
    required this.handicap,
    required this.homeCourse,
    required this.friendsCount,
    required this.isSelf,
    required this.vibeMatchResult,
    required this.onOpenVibe,
  });

  final String handicap;
  final String homeCourse;
  final int friendsCount;
  final bool isSelf;
  final VibeMatchResult? vibeMatchResult;
  final VoidCallback onOpenVibe;

  @override
  Widget build(BuildContext context) {
    final result = !isSelf ? vibeMatchResult : null;
    final vibeScore = result?.myFitPercent.round();
    final canOpenVibe = vibeScore != null;

    Color vibeColor;
    if (vibeScore != null) {
      if (vibeScore >= 80) {
        vibeColor = AppColors.green;
      } else if (vibeScore >= 50) {
        vibeColor = AppColors.gold;
      } else {
        vibeColor = AppColors.textSecondary;
      }
    } else {
      vibeColor = AppColors.textPrimary;
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: AppStatCard(
                    icon: AppPhosphorIcons.golf,
                    value: handicap,
                    label: 'Handicap',
                    variant: AppStatCardVariant.glass,
                    iconGradient: [AppColors.gold, AppColors.goldLight],
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: isSelf
                      ? AppStatCard(
                          icon: AppPhosphorIcons.users,
                          value: friendsCount.toString(),
                          label: 'Friends',
                          variant: AppStatCardVariant.glass,
                          iconGradient: [AppColors.gold, AppColors.goldLight],
                        )
                      : GestureDetector(
                          onTap: canOpenVibe ? onOpenVibe : null,
                          child: Semantics(
                            label: vibeScore != null
                                ? 'Vibe compatibility: $vibeScore%'
                                : 'Vibe compatibility: loading',
                            child: AppStatCard(
                              icon: AppPhosphorIcons.sparkle,
                              value: vibeScore != null ? '$vibeScore%' : '...',
                              label: 'Your Fit',
                              variant: AppStatCardVariant.glass,
                              iconGradient: [AppColors.gold, AppColors.goldLight],
                              valueStyle: AppTypography.monoLarge.copyWith(
                                color: vibeColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppPhosphorIcons.homeCourse,
              color: AppColors.textSecondary,
              size: AppIconSize.sm,
            ),
            SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                homeCourse,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
