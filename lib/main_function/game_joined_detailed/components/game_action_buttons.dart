import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/models/game.dart';
import '/screens/trust/cancellation_warning_modal.dart';

/// Callbacks for game action buttons.
typedef LeaveGameCallback = Future<void> Function({
  required String gameId,
  required String? currentUserId,
  required String? chatId,
});

typedef CancelGameCallback = Future<void> Function({
  required Game gameRecord,
  required String currentUserId,
});

/// Action buttons for game joined detailed screen (Leave/Cancel).
///
/// Shows "Leave game" for non-owners and "Cancel game" for owners.
/// Pure presentation component - receives state and callbacks.
class GameActionButtons extends StatelessWidget {
  final Game game;
  final String? currentUserRefId;
  final bool isOwner;
  final bool isCancelled;
  final LeaveGameCallback onLeaveGame;
  final CancelGameCallback onCancelGame;

  const GameActionButtons({
    super.key,
    required this.game,
    required this.currentUserRefId,
    required this.isOwner,
    required this.isCancelled,
    required this.onLeaveGame,
    required this.onCancelGame,
  });

  @override
  Widget build(BuildContext context) {
    if (isCancelled) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Leave game button (for non-owner)
        if (!isOwner)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppButtonEnhanced(
              text: 'Leave game',
              variant: AppButtonVariant.destructiveOutlined,
              size: AppButtonSize.large,
              fullWidth: true,
              onPressed: () => _handleLeaveGame(context),
            ),
          ),
        // Cancel game button (for owner)
        if (isOwner)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppButtonEnhanced(
              text: 'Cancel game',
              variant: AppButtonVariant.destructiveOutlined,
              size: AppButtonSize.large,
              fullWidth: true,
              onPressed: () => _handleCancelGame(context),
            ),
          ),
      ],
    );
  }

  Future<void> _handleLeaveGame(BuildContext context) async {
    // Show tier-aware cancellation warning
    final confirmed = await CancellationWarningModal.show(
      context,
      game: game,
    );
    if (confirmed != true) return;

    await onLeaveGame(
      gameId: game.reference.id,
      currentUserId: currentUserRefId,
      chatId: game.chatRef?.id,
    );
  }

  Future<void> _handleCancelGame(BuildContext context) async {
    if (currentUserRefId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please sign in to cancel the game.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmDialogResponse = await showPremiumDialog(
          context: context,
          variant: PremiumDialogVariant.destructive,
          icon: PhosphorIconsRegular.xCircle,
          title: 'Cancel Game',
          body: 'This will end the game for all players.',
          actionLabel: 'Cancel Game',
          cancelLabel: 'Keep Game',
        ) ??
        false;

    if (!confirmDialogResponse) return;
    if (!context.mounted) return;

    final shouldRemove = await showPremiumDialog(
      context: context,
      variant: PremiumDialogVariant.destructive,
      icon: PhosphorIconsRegular.trashSimple,
      title: 'Remove Game Listing',
      body: 'This game will be removed from your list immediately.',
      actionLabel: 'Delete Now',
    );

    if (shouldRemove != true) return;

    await onCancelGame(
      gameRecord: game,
      currentUserId: currentUserRefId!,
    );
  }
}
