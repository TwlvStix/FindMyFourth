import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';
import '/models/game.dart';
import '/utils/app_util.dart';

class GameSummaryCard extends StatelessWidget {
  const GameSummaryCard({
    super.key,
    required this.game,
    required this.currentPlayerCount,
    required this.remainingSlots,
  });

  final Game game;
  final int currentPlayerCount;
  final int remainingSlots;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(
                icon: AppPhosphorIcons.info,
                size: AppIconSize.button,
                color: AppColors.goldLight,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Game Summary',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.goldLight,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          _InfoRow(
            phosphorIcon: AppPhosphorIcons.course,
            text: game.coursePlay,
          ),
          SizedBox(height: AppSpacing.xs),
          _InfoRow(
            phosphorIcon: AppPhosphorIcons.calendarCheck,
            text:
                '${dateTimeFormat("EEEE, MMM d", game.date)} • ${dateTimeFormat("jm", game.date)}',
          ),
          SizedBox(height: AppSpacing.xs),
          _InfoRow(
            phosphorIcon: AppPhosphorIcons.golfers,
            text:
                '$currentPlayerCount confirmed, $remainingSlots ${remainingSlots == 1 ? 'spot' : 'spots'} open',
          ),
          if (game.gameType.isNotEmpty) ...[
            SizedBox(height: AppSpacing.xs),
            _InfoRow(
              phosphorIcon: AppPhosphorIcons.golfCourse,
              text: game.gameType,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.text,
    this.phosphorIcon,
  });

  final PhosphorIconData? phosphorIcon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (phosphorIcon != null)
          AppIcon(
            icon: phosphorIcon!,
            size: AppIconSize.xs,
            color: AppColors.textSecondary,
          ),
        AppSpacing.horizontalXsBox,
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
