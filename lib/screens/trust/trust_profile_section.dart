import 'package:flutter/material.dart';

import '/backend/schema/users_record.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/elevation.dart';
import '/core/widgets/app_icon.dart';
import 'components/trust_badge_banner.dart';
import 'components/trust_stat_tile.dart';
import 'components/journey_progress_bar.dart';
import 'components/show_up_rate_card.dart';
import 'components/cancellation_warning_card.dart';

/// TrustProfileSection
///
/// Displays the public-facing trust profile for a user: badge, stats,
/// show-up rate, and cancellation warning. Used on both the own profile
/// screen (MainProfile) and the other-user profile screen (ProfileUser).
///
/// Parameters:
///   user         - the UsersRecord to display
///   isOwnProfile - when true, warning detail uses more personal wording
class TrustProfileSection extends StatelessWidget {
  const TrustProfileSection({
    super.key,
    required this.user,
    this.isOwnProfile = false,
  });

  final UsersRecord user;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final isNewMember = user.badgeLevel == 'new' || user.badgeLevel.isEmpty;
    final joinYear =
        user.createdTime != null ? '${user.createdTime!.year}' : '\u2014';

    return Padding(
      padding:
          EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          SizedBox(height: AppSpacing.md),
          // Unified trust card (badge + progress bar + stats)
          Container(
            decoration: BoxDecoration(
              color: AppColors.navyDark,
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              border: Border.all(color: AppColors.navyLight),
              boxShadow: [AppElevation.md],
            ),
            child: Column(
              children: [
                TrustBadgeBanner(
                  badgeLevel: user.badgeLevel,
                  joinedYear: joinYear,
                ),
                if (isNewMember)
                  JourneyProgressBar(
                    verifiedRoundCount: user.verifiedRoundCount,
                  ),
                Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: TrustStatTile(
                          icon: AppPhosphorIcons.success,
                          value: '${user.verifiedRoundCount}',
                          label: 'ROUNDS',
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: TrustStatTile(
                          icon: AppPhosphorIcons.users,
                          value: '${user.uniqueCoPlayers.length}',
                          label: 'NEW PLAYERS',
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: TrustStatTile(
                          icon: AppPhosphorIcons.golf,
                          value: '${user.gamesHosted}',
                          label: 'HOSTED',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (user.showUpRate != null) ...[
            SizedBox(height: AppSpacing.sm),
            ShowUpRateCard(
              rate: user.showUpRate!,
              denominator: user.showUpRateDenominator,
            ),
          ],
          if (user.cancellationWarning) ...[
            SizedBox(height: AppSpacing.sm),
            CancellationWarningCard(
              warningCount: user.cancellationWarningCount,
              isOwnProfile: isOwnProfile,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.navy, AppColors.navyDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: AppIcon(
            icon: AppPhosphorIcons.shield,
            color: AppColors.pure,
            size: AppIconSize.xs,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          'Trust Profile',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
