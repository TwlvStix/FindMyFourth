import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/backend/backend.dart';
import '/core/design_tokens/colors.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/models/game.dart';

import 'game_joined_detailed_controller.dart';

/// Handles player removal flows including confirmation dialog and action.
///
/// Delegates business logic to [GameJoinedDetailedController], handles UI
/// feedback (dialogs, snackbars) and validation.
class GameJoinedPlayerActions {
  GameJoinedPlayerActions({
    required this.controller,
  });

  final GameJoinedDetailedController controller;

  /// Shows confirmation dialog and removes player if confirmed.
  ///
  /// Blocks self-removal with a warning snackbar.
  /// Shows confirmation dialog before proceeding.
  /// On success, shows success snackbar.
  /// On failure, shows error snackbar.
  Future<void> showRemovePlayerDialog({
    required BuildContext context,
    required State state,
    required String playerName,
    required DocumentReference? playerRef,
    required bool isGuest,
    String? guestName,
    required Game gameRecord,
    required DocumentReference? currentUserRef,
    required DocumentReference? gameRef,
  }) async {
    // Self-removal guard
    if (!isGuest && playerRef == currentUserRef) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('You cannot remove yourself. Use "Cancel game" instead.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await showPremiumDialog(
          context: context,
          variant: PremiumDialogVariant.destructive,
          icon: PhosphorIconsRegular.userMinus,
          title: 'Remove Player',
          body: 'This will remove $playerName from the game.',
          actionLabel: 'Remove',
        ) ??
        false;

    if (confirmed) {
      if (!context.mounted) return;
      await _removePlayer(
        context: context,
        state: state,
        playerRef: playerRef,
        isGuest: isGuest,
        guestName: guestName,
        playerName: playerName,
        gameRecord: gameRecord,
        gameRef: gameRef,
      );
    }
  }

  Future<void> _removePlayer({
    required BuildContext context,
    required State state,
    required DocumentReference? playerRef,
    required bool isGuest,
    String? guestName,
    required String playerName,
    required Game gameRecord,
    required DocumentReference? gameRef,
  }) async {
    if (gameRef == null) {
      AppLog.d('Player Management: gameRef is null');
      return;
    }

    final result = await controller.removePlayer(
      gameId: gameRef.id,
      isGuest: isGuest,
      playerRef: playerRef,
      guestName: guestName,
    );

    if (!context.mounted) return;
    if (!state.mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$playerName removed from game'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Failed to remove player.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
