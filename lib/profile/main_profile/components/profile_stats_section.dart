import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_stat_card.dart';
import '/utils/app_util.dart';

/// Stats section of the main profile page.
///
/// Contains handicap card, friends card, and home course row.
class ProfileStatsSection extends StatelessWidget {
  const ProfileStatsSection({
    super.key,
    this.onFriendsTap,
  });

  /// Called when the user taps the friends card.
  final VoidCallback? onFriendsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Two-card row: Handicap + Friends
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handicap
                Expanded(
                  child: AuthUserStreamWidget(
                    builder: (context) => AppStatCard(
                      variant: AppStatCardVariant.glass,
                      icon: AppPhosphorIcons.handicap,
                      value: formatHandicap(
                        valueOrDefault(currentUserDocument?.handicap, 0),
                      ),
                      label: 'Handicap',
                      iconGradient: [AppColors.gold, AppColors.goldLight],
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),

                // Friends count
                Expanded(
                  child: AuthUserStreamWidget(
                    builder: (context) {
                      final friendsCount =
                          currentUserDocument?.friends.length ?? 0;
                      return AppStatCard(
                        variant: AppStatCardVariant.glass,
                        icon: AppPhosphorIcons.friends,
                        value: friendsCount.toString(),
                        label: 'Friends',
                        iconGradient: [AppColors.gold, AppColors.goldLight],
                        onTap: onFriendsTap,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppSpacing.md),

        // Home course text row
        AuthUserStreamWidget(
          builder: (context) {
            final course =
                valueOrDefault(currentUserDocument?.homeCourse, 'Not Set');
            return Row(
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
                    course,
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
            );
          },
        ),
      ],
    );
  }
}
