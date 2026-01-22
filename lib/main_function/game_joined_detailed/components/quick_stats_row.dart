import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/models/game.dart';
import '/utils/app_util.dart';

/// Quick stats row displaying player count, tee time, and available spots
class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({
    super.key,
    required this.game,
  });

  final Game game;

  @override
  Widget build(BuildContext context) {
    final spotsLeft = game.maxPlayers - (game.joinedPlayers.length + game.guestPlayers.length);
    final isFull = spotsLeft <= 0;

    return Row(
      children: [
        // Date Card
        Expanded(
          child: Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.fairway.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.sunsetPeach, AppColors.sunsetRose],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
        // Players Card
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isFull
                ? AppColors.fairwayLight.withValues(alpha: 0.2)
                : AppColors.sunsetGold.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFull
                  ? AppColors.fairwayLight.withValues(alpha: 0.3)
                  : AppColors.sunsetGold.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isFull
                        ? [AppColors.fairwayLight, AppColors.fairway]
                        : [AppColors.sunsetGold, AppColors.sunsetPeach],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isFull ? Icons.groups_rounded : Icons.person_add_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFull ? 'Full' : '$spotsLeft Spots',
                    style: AppTypography.titleSmall.copyWith(
                      color: isFull ? AppColors.fairwayLight : AppColors.sunsetGold,
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
    );
  }
}
