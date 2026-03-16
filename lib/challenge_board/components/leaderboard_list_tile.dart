import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_avatar.dart';
import '/models/leaderboard_entry.dart';

/// Compact row for leaderboard ranks 6+.
///
/// Shows rank number, small avatar, name, and rounds played.
/// Current user gets a subtle green background tint.
class LeaderboardListTile extends StatelessWidget {
  const LeaderboardListTile({
    super.key,
    required this.entry,
  });

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.green.withValues(alpha: 0.08)
            : AppColors.transparent,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: AppSpacing.sm),

          // Small avatar
          AppAvatar(
            imageUrl: entry.photoUrl,
            initials: entry.displayName.isNotEmpty
                ? entry.displayName[0].toUpperCase()
                : '?',
            size: AppAvatarSize.xs,
          ),
          SizedBox(width: AppSpacing.sm),

          // Name
          Expanded(
            child: Text(
              entry.displayName,
              style: AppTypography.bodySmall.copyWith(
                color: entry.isCurrentUser
                    ? AppColors.green
                    : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Rounds
          Text(
            '${entry.roundsPlayed}',
            style: AppTypography.monoSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
