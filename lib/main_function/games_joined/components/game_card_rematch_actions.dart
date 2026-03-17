import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/motion/motion_helpers.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/models/game.dart';
import 'rebook_change_course_sheet.dart';
import 'rebook_play_again_sheet.dart';

/// "Play Again" and "Change Course" action buttons for completed game cards.
class GameCardRematchActions extends StatelessWidget {
  const GameCardRematchActions({
    super.key,
    required this.game,
  });

  final Game game;

  void _onPlayAgain(BuildContext context) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => RebookPlayAgainSheet(
        sourceGame: game,
        onGameCreated: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Game created. Players have been invited.'),
            ),
          );
        },
      ),
    );
  }

  void _onChangeCourse(BuildContext context) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => RebookChangeCourseSheet(
        sourceGame: game,
        onGameCreated: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Game created. Players have been invited.'),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(
          color: AppColors.navyLight,
          height: 1,
        ),
        Padding(
          padding: EdgeInsets.only(
            top: AppSpacing.sm,
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: AppButtonEnhanced(
                  text: 'Play Again',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.small,
                  leadingPhosphorIcon: AppPhosphorIcons.refresh,
                  onPressed: () => _onPlayAgain(context),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButtonEnhanced(
                  text: 'Change Course',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.small,
                  leadingPhosphorIcon: AppPhosphorIcons.course,
                  onPressed: () => _onChangeCourse(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
