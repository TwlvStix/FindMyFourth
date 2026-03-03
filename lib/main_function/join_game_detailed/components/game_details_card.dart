import 'package:flutter/material.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_expandable_text.dart';
import '/core/widgets/app_icon.dart';
import '/models/game.dart';

/// Game details card displaying course name and game title with golf icon
class GameDetailsCard extends StatelessWidget {
  const GameDetailsCard({
    super.key,
    required this.game,
  });

  final Game game;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navyLight, AppColors.navy],
            ),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            boxShadow: [AppElevation.md],
          ),
          child: const Center(
            child: AppIcon(
              icon: AppPhosphorIcons.course,
              color: AppColors.pure,
              size: AppIconSize.md,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppExpandableText(
                text: game.coursePlay,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.pure,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
              ),
              Text(
                game.nameGame,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.glassTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
