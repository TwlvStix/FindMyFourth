import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/main_function/games_list/components/game_card_status_badge.dart';
import '/models/game.dart';
import '/models/player_eligibility.dart';

/// Top row of a [PremiumGameCard]: friends-only lock, game-type pill,
/// money game, eligibility, member discount, spacer, add-friend or status badge.
class PremiumCardBadgeRow extends StatelessWidget {
  const PremiumCardBadgeRow({
    super.key,
    required this.game,
    required this.isLocked,
    required this.isUserGame,
    required this.isCancelled,
    required this.isExpired,
    required this.isOwner,
    required this.hasPendingFriendRequest,
    this.onAddFriend,
  });

  final Game game;
  final bool isLocked;
  final bool isUserGame;
  final bool isCancelled;
  final bool isExpired;
  final bool isOwner;
  final bool hasPendingFriendRequest;
  final Future<void> Function()? onAddFriend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isLocked) ...[
          _buildFriendsOnlyBadge(),
          SizedBox(width: AppSpacing.xs),
        ],
        // Just for Fun pill
        if (game.isFunGame)
          _buildPill(label: 'Just for Fun')
        else if (game.gameType.isNotEmpty)
          _buildPill(label: game.gameType),
        if (game.styleGame == 'Money Game') ...[
          SizedBox(width: AppSpacing.xs),
          _buildMoneyGameBadge(),
        ],
        // Player eligibility badge
        if (game.playerEligibility == PlayerEligibility.womenOnly) ...[
          SizedBox(width: AppSpacing.xs),
          _buildEligibilityBadge(
            label: 'Women Only',
            color: AppColors.gold,
          ),
        ] else if (game.playerEligibility == PlayerEligibility.menOnly) ...[
          SizedBox(width: AppSpacing.xs),
          _buildEligibilityBadge(
            label: 'Men Only',
            color: AppColors.info,
          ),
        ],
        // Member discount badge
        if (game.memberDiscount == 'Yes') ...[
          SizedBox(width: AppSpacing.xs),
          _buildMemberDiscountBadge(),
        ],
        Spacer(),
        // Add Friend button for locked games (top right)
        if (isLocked && onAddFriend != null) _buildAddFriendButton(),
        // Status badges for non-locked games
        if (!isLocked)
          GameCardStatusBadge(
            isCancelled: isCancelled,
            isExpired: isExpired,
            isOwner: isOwner,
            isUserGame: isUserGame,
          ),
      ],
    );
  }

  Widget _buildFriendsOnlyBadge() {
    return Tooltip(
      message: 'Friends-only game',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon: AppPhosphorIcons.lock,
              size: AppIconSize.xs,
              color: AppColors.textPrimary,
            ),
            SizedBox(width: 4),
            Text(
              'Friends Only',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill({required String label}) {
    return Opacity(
      opacity: isUserGame ? 0.65 : 1.0,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.chip),
          border: Border.all(
            color: AppColors.navyLight,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMoneyGameBadge() {
    return Opacity(
      opacity: isUserGame ? 0.65 : 1.0,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Text(
          '\$\$\$',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.gold,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildEligibilityBadge({
    required String label,
    required Color color,
  }) {
    return Opacity(
      opacity: isUserGame ? 0.65 : 1.0,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMemberDiscountBadge() {
    return Opacity(
      opacity: isUserGame ? 0.65 : 1.0,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: AppIcon(
          icon: AppPhosphorIcons.memberDiscount,
          color: AppColors.green,
          size: AppIconSize.xs,
        ),
      ),
    );
  }

  Widget _buildAddFriendButton() {
    if (hasPendingFriendRequest) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(AppBorderRadius.chip),
          border: Border.all(color: AppColors.navyLight),
        ),
        child: Text(
          'Pending',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onAddFriend,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppBorderRadius.chip),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon: AppPhosphorIcons.addPlayer,
              size: AppIconSize.xs,
              color: AppColors.green,
            ),
            SizedBox(width: 4),
            Text(
              'Add Friend',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
