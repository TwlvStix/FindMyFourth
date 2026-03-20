import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/main_function/games_list/components/flexible_availability_summary.dart';
import '/models/game.dart';
import '/utils/app_util.dart';

/// Date/time section of a [PremiumGameCard]: flexible summary or glass
/// container with calendar icon, date/time text, and player count chip.
class PremiumCardDateTimeSection extends StatelessWidget {
  const PremiumCardDateTimeSection({
    super.key,
    required this.game,
    required this.isUserGame,
    required this.isFull,
  });

  final Game game;
  final bool isUserGame;
  final bool isFull;

  @override
  Widget build(BuildContext context) {
    // Flexible games use the unified summary with built-in icon and spots
    if (game.isFlexible) {
      return Opacity(
        opacity: isUserGame ? 0.65 : 1.0,
        child: FlexibleAvailabilitySummary(game: game),
      );
    }

    // Fixed-time games use the glass container with date/time and player count
    return Opacity(
      opacity: isUserGame ? 0.65 : 1.0,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.navyLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Center(
                child: AppIcon(
                  icon: AppPhosphorIcons.calendarCheck,
                  color: AppColors.textSecondary,
                  size: AppIconSize.xs,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${dateTimeFormat("EEEE", game.date)}, ${dateTimeFormat("MMM d", game.date)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    dateTimeFormat("jm", game.date),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.glassTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Player count indicator
            _buildPlayerCountChip(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCountChip() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isFull
            ? AppColors.error.withValues(alpha: 0.2)
            : AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.chip),
        border: Border.all(
          color: isFull
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.navyLight,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            icon: AppPhosphorIcons.golfers,
            color: isFull ? AppColors.error : AppColors.textSecondary,
            size: AppIconSize.xs,
          ),
          SizedBox(width: 4),
          Text(
            '${game.joinedPlayers.length + game.guestPlayers.length}/${game.maxPlayers}',
            style: AppTypography.labelMicro.copyWith(
              color: isFull ? AppColors.error : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
