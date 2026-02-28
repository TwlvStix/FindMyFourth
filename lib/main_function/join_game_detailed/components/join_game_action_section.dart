import 'package:flutter/material.dart';

import '/core/content/app_copy.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/models/game.dart';
import '/models/join_request.dart';
import '/models/player_eligibility.dart';
import '/services/game_eligibility_service.dart';

/// State for join button display.
class JoinGameActionState {
  /// The game being joined
  final Game game;

  /// Existing request if one exists (pending/denied/expired)
  final JoinRequest? existingRequest;

  /// Whether we're still checking for existing request
  final bool isCheckingRequest;

  /// Whether user is restricted from joining
  final bool isRestricted;

  /// User's gender for eligibility checking
  final String? userGender;

  const JoinGameActionState({
    required this.game,
    required this.existingRequest,
    required this.isCheckingRequest,
    required this.isRestricted,
    required this.userGender,
  });

  /// Get button text based on existing request status
  String get buttonText {
    if (existingRequest?.isPending == true) {
      return AppVibeFloorCopy.requestPendingButton;
    }
    if (existingRequest?.isDenied == true) {
      return AppVibeFloorCopy.requestDeclinedButton;
    }
    if (existingRequest?.isExpired == true) {
      return AppVibeFloorCopy.requestExpiredButton;
    }
    return AppVibeFloorCopy.joinRoundButton;
  }

  /// Get button variant based on existing request status
  AppButtonVariant get buttonVariant {
    if (existingRequest != null) return AppButtonVariant.secondary;
    return AppButtonVariant.primary;
  }

  /// Check player eligibility result
  EligibilityResult get eligibilityResult {
    return checkPlayerEligibility(
      eligibility: game.playerEligibility,
      userGender: userGender,
    );
  }

  /// Whether player is ineligible due to gender restriction
  bool get isIneligible => !eligibilityResult.allowed;

  /// Whether button should be enabled
  bool get isButtonEnabled {
    final hasNoRequest = existingRequest == null;
    final notChecking = !isCheckingRequest;
    final notDisabled = !isRestricted && !isIneligible;
    return hasNoRequest && notChecking && notDisabled;
  }

  /// Eligibility explanation text if ineligible
  String? get eligibilityText {
    if (!isIneligible) return null;
    return game.playerEligibility == PlayerEligibility.womenOnly
        ? 'This game is open to women only'
        : 'This game is open to men only';
  }

  /// Whether to show declined subtitle
  bool get showDeclinedSubtitle => existingRequest?.isDenied == true;
}

/// Join button section with eligibility display.
///
/// Pure presentation component - receives state and callbacks.
class JoinGameActionSection extends StatelessWidget {
  final JoinGameActionState state;
  final VoidCallback onJoinPressed;

  const JoinGameActionSection({
    super.key,
    required this.state,
    required this.onJoinPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButtonEnhanced(
            text: state.buttonText,
            variant: state.buttonVariant,
            size: AppButtonSize.large,
            fullWidth: true,
            enabled: state.isButtonEnabled,
            onPressed: state.isButtonEnabled ? onJoinPressed : null,
          ),
          // Eligibility explanation text
          if (state.eligibilityText != null) ...[
            SizedBox(height: AppSpacing.xs),
            Text(
              state.eligibilityText!,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          // Request declined subtitle
          if (state.showDeclinedSubtitle) ...[
            SizedBox(height: AppSpacing.xs),
            Text(
              AppVibeFloorCopy.requestDeclinedSubtitle,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
