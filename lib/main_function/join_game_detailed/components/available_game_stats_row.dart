import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/models/game.dart';
import '/utils/app_util.dart';
import '/main_function/games_list/components/flexible_time_display.dart';

/// Quick stats row for Available Game page with matched card heights
class AvailableGameStatsRow extends StatelessWidget {
  const AvailableGameStatsRow({
    super.key,
    required this.game,
  });

  final Game game;

  @override
  Widget build(BuildContext context) {
    final spotsLeft = game.maxPlayers - (game.joinedPlayers.length + game.guestPlayers.length);
    final isFull = spotsLeft <= 0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date Card - Expanded to take remaining space
          Expanded(
            child: Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.green, AppColors.greenLight],
                      ),
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Center(
                      child: AppIcon(icon: AppPhosphorIcons.calendarCheck, color: AppColors.pure, size: AppIconSize.button),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: game.isFlexible
                        ? FlexibleTimeDisplay(
                            game: game,
                            showWeekLabel: true,
                            compact: false,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dateTimeFormat("MMM d", game.date),
                                style: AppTypography.titleSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                dateTimeFormat("jm", game.date),
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          // Players Card - sizes to content
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
                // All cases use 36x36 container for consistent card height
                isFull
                    ? SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(
                          child: AppIcon(icon: AppPhosphorIcons.groups, color: AppColors.textSecondary, size: AppIconSize.listItem),
                        ),
                      )
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
                        : SizedBox(
                            width: 36,
                            height: 36,
                            child: Center(
                              child: AppIcon(icon: AppPhosphorIcons.addPlayer, color: AppColors.textSecondary, size: AppIconSize.listItem),
                            ),
                          ),
                SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
