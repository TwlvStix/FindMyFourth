import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/motion_tokens.dart';
import '/core/navigation/nav_extensions.dart';
import '/core/navigation/transition_standards.dart';
import '/main_function/create_game/controllers/create_game_controller.dart';

void scrollToFormErrors(GlobalKey<FormState> formKey) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final formContext = formKey.currentContext;
    if (formContext != null) {
      Scrollable.ensureVisible(
        formContext,
        duration: const Duration(milliseconds: 300),
        curve: MotionTokens.curveEnter,
      );
    }
  });
}

void handleCreateGameSubmitResult(
  BuildContext context, {
  required CreateGameSubmitResult result,
  required VoidCallback onDraftCleared,
}) {
  if (!result.success) {
    final message = result.message;
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(milliseconds: 4000),
          backgroundColor: AppColors.error,
        ),
      );
    }
    return;
  }

  final gameRef = result.gameRef;
  final nextRoute = result.nextRoute;
  if (gameRef == null || nextRoute == null) return;

  onDraftCleared();

  final messenger = ScaffoldMessenger.of(context);

  if (nextRoute == CreateGameNextRoute.gamesList) {
    context.pushGamesList(
      transition: TransitionStandards.modalTransition,
    );
  } else {
    context.pushPlayerList(gameRef: gameRef);
  }

  messenger.showSnackBar(
    SnackBar(
      content: Text(
        'You have created a game!',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.pure,
          fontWeight: FontWeight.w500,
        ),
      ),
      duration: Duration(milliseconds: 4000),
      backgroundColor: AppColors.success,
    ),
  );
}
