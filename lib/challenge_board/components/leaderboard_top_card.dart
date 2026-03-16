import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_avatar.dart';
import '/models/leaderboard_entry.dart';

/// Prominent card for a top-5 leaderboard entry.
///
/// Shows rank badge (gold/silver/bronze for #1-3), avatar, name, and rounds.
/// Current user's row gets a green left border accent.
class LeaderboardTopCard extends StatelessWidget {
  const LeaderboardTopCard({
    super.key,
    required this.entry,
  });

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(
          color: entry.isCurrentUser ? AppColors.green : AppColors.navyLight,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          _RankBadge(rank: entry.rank),
          SizedBox(width: AppSpacing.sm),

          // Avatar
          AppAvatar(
            imageUrl: entry.photoUrl,
            initials: entry.displayName.isNotEmpty
                ? entry.displayName[0].toUpperCase()
                : '?',
            size: AppAvatarSize.small,
          ),
          SizedBox(width: AppSpacing.sm),

          // Name
          Expanded(
            child: Text(
              entry.displayName,
              style: AppTypography.titleSmall.copyWith(
                color: entry.isCurrentUser
                    ? AppColors.green
                    : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Rounds count
          Text(
            '${entry.roundsPlayed}',
            style: AppTypography.monoSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: AppSpacing.xxs),
          Text(
            entry.roundsPlayed == 1 ? 'rd' : 'rds',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular rank badge with gold/silver/bronze colors for top 3.
class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  Color get _badgeColor {
    switch (rank) {
      case 1:
        return AppColors.trustGoldFg;
      case 2:
        return AppColors.trustSilverFg;
      case 3:
        return AppColors.trustBronzeFg;
      default:
        return AppColors.navyLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _badgeColor.withValues(alpha: rank <= 3 ? 0.2 : 0.1),
        border: Border.all(
          color: _badgeColor.withValues(alpha: rank <= 3 ? 0.6 : 0.3),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: AppTypography.labelSmall.copyWith(
          color: rank <= 3 ? _badgeColor : AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
