import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_icon_button.dart';
import '/models/game.dart';
import '/utils/app_util.dart';
import '/main_function/games_list/components/flexible_game_info_accordion.dart';

/// Quick stats row displaying player count, tee time, and available spots.
///
/// For flexible games: Shows accordion widget with expandable scheduling info.
/// For fixed games: Shows two-card layout (Date Card + Players Card).
class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({
    super.key,
    required this.game,
    required this.isOwner,
    this.onEditPressed,
  });

  final Game game;
  final bool isOwner;
  final VoidCallback? onEditPressed;

  @override
  Widget build(BuildContext context) {
    // Flexible games get single accordion widget (includes spots info)
    if (game.isFlexible) {
      return FlexibleGameInfoAccordion(game: game);
    }

    // Fixed games keep the existing two-card layout
    return _buildFixedGameLayout();
  }

  Widget _buildFixedGameLayout() {
    final spotsLeft = game.maxPlayers - (game.joinedPlayers.length + game.guestPlayers.length);
    final isFull = spotsLeft <= 0;

    return Row(
      children: [
        // Date Card
        Expanded(
          child: Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.navyLight, AppColors.navy],
                    ),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: Center(
                    child: AppIcon(icon: AppPhosphorIcons.calendarCheck, color: AppColors.pure, size: AppIconSize.button),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateTimeFormat("MMM d", game.date),
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        dateTimeFormat("jm", game.date),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner && onEditPressed != null) ...[
                  SizedBox(width: AppSpacing.xs),
                  AppIconButton(
                    icon: AppIcon(
                      icon: AppPhosphorIcons.edit,
                      color: AppColors.textSecondary,
                      size: AppIconSize.button,
                    ),
                    borderRadius: 8.0,
                    buttonSize: 32.0,
                    fillColor: AppColors.navy.withValues(alpha: 0.3),
                    onPressed: onEditPressed,
                    tooltip: 'Edit game details',
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        // Players Card
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: [
              // Icon - plain neutral, green only for 1 spot urgency
              isFull
                  ? AppIcon(icon: AppPhosphorIcons.groups, color: AppColors.textSecondary, size: AppIconSize.listItem)
                  : spotsLeft == 1
                      ? Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.green, AppColors.greenLight],
                            ),
                            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                          ),
                          child: Center(
                            child: AppIcon(icon: AppPhosphorIcons.addPlayer, color: AppColors.pure, size: AppIconSize.button),
                          ),
                        )
                      : AppIcon(icon: AppPhosphorIcons.addPlayer, color: AppColors.textSecondary, size: AppIconSize.listItem),
              SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFull ? 'Full' : '$spotsLeft Spots',
                    style: AppTypography.titleSmall.copyWith(
                      color: spotsLeft == 1 ? AppColors.green : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${game.joinedPlayers.length + game.guestPlayers.length}/${game.maxPlayers}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
