import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/models/game.dart';
import '/services/rematch_service.dart';
import '/utils/app_util.dart';

/// "Play Again" and "Switch Course" action buttons for completed game cards.
class GameCardRematchActions extends StatelessWidget {
  const GameCardRematchActions({
    super.key,
    required this.game,
  });

  final Game game;

  static final _rematchService = RematchService();

  void _onPlayAgain(BuildContext context) {
    final formData = _rematchService.buildRematchForm(game);
    context.pushCreateGameRematch(formData: formData);
  }

  void _onSwitchCourse(BuildContext context) {
    final formData = _rematchService.buildSwitchCourseForm(game);
    context.pushCreateGameRematch(formData: formData);
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
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.small,
                  onPressed: () => _onPlayAgain(context),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButtonEnhanced(
                  text: 'Switch Course',
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.small,
                  onPressed: () => _onSwitchCourse(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
