import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/services/vibe_matcher.dart';

/// Vibe match percentage badge for friend cards.
class FriendCardVibeBadge extends StatelessWidget {
  const FriendCardVibeBadge({
    super.key,
    required this.vibeMatch,
  });

  final VibeMatchResult vibeMatch;

  @override
  Widget build(BuildContext context) {
    final score = vibeMatch.myFitPercent.round();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.navyLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.xs),
        border: Border.all(
          color: AppColors.navyLight.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            icon: AppPhosphorIcons.heartFill,
            size: 10,
            color: AppColors.textMuted,
          ),
          AppSpacing.horizontalXxs,
          Text(
            '$score%',
            style: AppTypography.labelMicro.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Handicap badge for friend cards.
class FriendCardHandicapBadge extends StatelessWidget {
  const FriendCardHandicapBadge({
    super.key,
    required this.handicap,
  });

  final int handicap;

  @override
  Widget build(BuildContext context) {
    final handicapText = handicap < 0 ? '+${handicap.abs()}' : '$handicap';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.navyLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppBorderRadius.xs),
        border: Border.all(
          color: AppColors.navyLight,
          width: 1,
        ),
      ),
      child: Text(
        'HCP $handicapText',
        style: AppTypography.labelMicro.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
