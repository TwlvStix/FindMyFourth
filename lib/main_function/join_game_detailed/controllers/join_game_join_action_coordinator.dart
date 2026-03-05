import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '/backend/backend.dart';
import '/core/motion/motion_helpers.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/core/widgets/vibe_floor_bottom_sheet.dart';
import '/models/game.dart';
import '/models/join_request.dart';
import '/models/player_eligibility.dart';
import '/providers/chat_provider.dart';
import '/providers/game_provider.dart';
import '/providers/profile_provider.dart';
import '/providers/user_provider.dart';
import 'join_game_detailed_controller.dart';

/// Result of a join action attempt.
sealed class JoinActionResult {
  const JoinActionResult();
}

/// Join succeeded - navigate to joined game screen.
class JoinActionSuccess extends JoinActionResult {
  const JoinActionSuccess({required this.gameRef});
  final DocumentReference gameRef;
}

/// Join requires approval - request was submitted.
class JoinActionRequestSubmitted extends JoinActionResult {
  const JoinActionRequestSubmitted({required this.request});
  final JoinRequest request;
}

/// Join was cancelled or dismissed by user.
class JoinActionDismissed extends JoinActionResult {
  const JoinActionDismissed();
}

/// Join failed with error.
class JoinActionError extends JoinActionResult {
  const JoinActionError({this.message});
  final String? message;
}

/// Coordinates join game actions including dialogs and navigation.
///
/// Handles the UI flow after a join attempt, showing appropriate dialogs
/// and returning the result for the widget to update state.
class JoinGameJoinActionCoordinator {
  const JoinGameJoinActionCoordinator({
    required this.controller,
  });

  final JoinGameDetailedController controller;

  /// Attempts to join a game and handles the result flow.
  ///
  /// Returns a [JoinActionResult] indicating what action the widget should take.
  Future<JoinActionResult> executeJoinAction({
    required BuildContext context,
    required Game game,
    required DocumentReference? currentUserRef,
    required bool isCreatorFriend,
    required String? userGender,
  }) async {
    final joinResult = await controller.attemptJoin(
      game: game,
      currentUserRef: currentUserRef,
      isCreatorFriend: isCreatorFriend,
      userGender: userGender,
      gameProvider: context.read<GameProvider>(),
      chatProvider: context.read<ChatProvider>(),
      userProvider: context.read<UserProvider>(),
      profileProvider: context.read<ProfileProvider>(),
    );

    if (joinResult.status == JoinGameAttemptStatus.requiresApproval) {
      if (!context.mounted) return const JoinActionDismissed();
      return _handleApprovalRequired(
        context: context,
        game: game,
        payload: joinResult.approvalPayload,
      );
    }

    if (joinResult.status == JoinGameAttemptStatus.genderRestricted) {
      if (!context.mounted) return const JoinActionDismissed();
      await _showGenderRestrictedDialog(context: context, game: game);
      return const JoinActionDismissed();
    }

    if (joinResult.status != JoinGameAttemptStatus.success) {
      return JoinActionError(message: joinResult.message);
    }

    return JoinActionSuccess(gameRef: game.reference);
  }

  Future<JoinActionResult> _handleApprovalRequired({
    required BuildContext context,
    required Game game,
    required JoinGameApprovalPayload? payload,
  }) async {
    if (payload == null) {
      return const JoinActionError(
        message: 'Unable to submit request right now. Please try again.',
      );
    }

    final eligibility = payload.eligibilityData;

    // Validate required vibe data is present
    if (eligibility.matchResult == null ||
        eligibility.ownerProfile == null ||
        eligibility.playerProfile == null ||
        eligibility.vibeScore == null ||
        eligibility.vibeFloor == null) {
      return const JoinActionError(
        message: 'Vibe profiles unavailable. Please complete your profile first.',
      );
    }

    final submittedRequest = await showAppBottomSheet<JoinRequest?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => VibeFloorBottomSheet(
        ownerFirstName: payload.ownerFirstName,
        playerName: payload.playerName,
        matchResult: eligibility.matchResult!,
        ownerProfile: eligibility.ownerProfile!,
        playerProfile: eligibility.playerProfile!,
        gameId: game.reference.id,
        playerId: payload.currentUserId,
        ownerId: payload.ownerId,
        vibeScore: eligibility.vibeScore!,
        vibeFloor: eligibility.vibeFloor!,
      ),
    );

    if (submittedRequest != null) {
      return JoinActionRequestSubmitted(request: submittedRequest);
    }

    return const JoinActionDismissed();
  }

  Future<void> _showGenderRestrictedDialog({
    required BuildContext context,
    required Game game,
  }) async {
    final restrictionLabel =
        game.playerEligibility == PlayerEligibility.womenOnly
            ? 'women'
            : 'men';
    await showPremiumDialog(
      context: context,
      variant: PremiumDialogVariant.informational,
      icon: PhosphorIconsRegular.prohibit,
      title: 'Unable to Join',
      body: 'This game is restricted to $restrictionLabel only.',
      actionLabel: 'OK',
    );
  }
}
