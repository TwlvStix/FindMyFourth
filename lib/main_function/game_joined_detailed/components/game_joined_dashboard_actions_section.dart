import '/backend/backend.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/models/game.dart';
import '/providers/chat_provider.dart';
import '/providers/provider_extensions.dart';
import '/screens/trust/cancellation_warning_modal.dart';
import '/utils/app_util.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

const int _cancelledChatArchiveDays = 3;

class GameJoinedDashboardActionsSection extends StatelessWidget {
  const GameJoinedDashboardActionsSection({
    super.key,
    required this.game,
    required this.screenGameRef,
    required this.currentUserRef,
  });

  final Game game;
  final DocumentReference? screenGameRef;
  final DocumentReference? currentUserRef;

  @override
  Widget build(BuildContext context) {
    final isCancelled = game.isCancelledStatus;
    final isOwner = game.userRef == currentUserRef;

    if (isCancelled) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
    // Capture user ref and id before async gap
    final userRef = currentUserRef;
    if (userRef == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signing you in... Please try again in a moment.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    final userId = userRef.id;

    final gameProvider = context.gameProvider;
    final confirmed =
        await CancellationWarningModal.show(context, game: game);
    if (confirmed != true) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    try {
      await gameProvider.leaveGame(
        game.reference.id,
        userId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You left the game'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        context.goGamesJoined();
      }
    } on FirebaseException catch (error) {
      if (!context.mounted) {
        return;
      }
      final message = error.code == 'permission-denied'
          ? 'You do not have permission to leave this game.'
          : 'Unable to leave the game right now. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to leave the game right now. Please try again.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleCancelGame(BuildContext context) async {
    // Capture refs and ids before async gap
    final userRef = currentUserRef;
    final gameRef = screenGameRef;
    if (userRef == null || gameRef == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signing you in... Please try again in a moment.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    final userId = userRef.id;
    final gameId = gameRef.id;
    final gamePath = gameRef.path;

    final gameProvider = context.gameProvider;
    final chatProvider = context.read<ChatProvider>();
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
    if (!confirmDialogResponse) {
      return;
    }

    if (!context.mounted) {
      return;
    }
    final shouldRemove = await showPremiumDialog(
      context: context,
      variant: PremiumDialogVariant.destructive,
      icon: PhosphorIconsRegular.trashSimple,
      title: 'Remove Game Listing',
      body: 'This game will be removed from your list immediately.',
      actionLabel: 'Delete Now',
    );
    if (shouldRemove != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }
    context.read<AppState>().setCancelledGameHandling(
      gamePath,
      'removeNow',
    );

    try {
      await gameProvider.cancelGame(gameId);
      final chatRef = game.chatRef;
      if (chatRef != null) {
        final gameName = game.nameGame;
        final cancelMessage = gameName.trim().isNotEmpty
            ? 'Game "$gameName" has been cancelled.'
            : 'This game has been cancelled.';
        try {
          await chatProvider.sendMessage(
            chatId: chatRef.id,
            senderId: userId,
            text: cancelMessage,
          );
          await chatRef.update({
            'isReadOnly': true,
            'pinnedMessage': cancelMessage,
            'pinnedAt': FieldValue.serverTimestamp(),
            'deletesAt': Timestamp.fromDate(
              getCurrentTimestamp.add(
                Duration(days: _cancelledChatArchiveDays),
              ),
            ),
          });
        } catch (chatError, stackTrace) {
          AppLog.d('CancelGame: chat update failed $chatError');
          AppLog.d('CancelGame stackTrace: $stackTrace');
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Game cancelled successfully'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        gameProvider.invalidateUserGamesCache(userId);
        context.goGamesList();
      }
    } catch (error, stackTrace) {
      AppLog.d('CancelGame failed: $error');
      AppLog.d('CancelGame stackTrace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to cancel the game. Please try again.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
