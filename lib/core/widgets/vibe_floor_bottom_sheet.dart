import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/content/app_copy.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/opacity.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/motion/motion_tokens.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/vibe_gap_indicator.dart';
import '/models/join_request.dart';
import '/models/vibe_profile.dart';
import '/providers/join_request_provider.dart';
import '/services/vibe_matcher.dart';

/// Bottom sheet for vibe floor join request flow.
///
/// Has two states:
/// 1. Mismatch explanation - shows gap indicator and "Request to join" button
/// 2. Request sent confirmation - shows checkmark and "Done" button
///
/// Transitions between states with a crossfade animation.
class VibeFloorBottomSheet extends StatefulWidget {
  const VibeFloorBottomSheet({
    super.key,
    required this.ownerFirstName,
    required this.playerName,
    required this.matchResult,
    required this.ownerProfile,
    required this.playerProfile,
    required this.gameId,
    required this.playerId,
    required this.ownerId,
    required this.vibeScore,
    required this.vibeFloor,
  });

  /// The game owner's first name for personalized copy
  final String ownerFirstName;

  /// The requesting player's display name (for notification copy)
  final String playerName;

  /// The full match result with per-category scores
  final VibeMatchResult matchResult;

  /// The game owner's vibe profile
  final VibeProfile ownerProfile;

  /// The requesting player's vibe profile
  final VibeProfile playerProfile;

  /// The game ID for submitting the request
  final String gameId;

  /// The requesting player's user ID
  final String playerId;

  /// The game owner's user ID
  final String ownerId;

  /// The vibe score at time of evaluation
  final double vibeScore;

  /// The vibe floor threshold at time of evaluation
  final int vibeFloor;

  @override
  State<VibeFloorBottomSheet> createState() => _VibeFloorBottomSheetState();
}

class _VibeFloorBottomSheetState extends State<VibeFloorBottomSheet> {
  bool _requestSent = false;
  bool _isSubmitting = false;
  JoinRequest? _submittedRequest;

  Future<void> _submitRequest() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      _submittedRequest =
          await context.read<JoinRequestProvider>().submitJoinRequest(
                gameId: widget.gameId,
                playerId: widget.playerId,
                ownerId: widget.ownerId,
                vibeScore: widget.vibeScore,
                vibeFloor: widget.vibeFloor,
                playerName: widget.playerName,
              );

      if (mounted) {
        AppLog.d(
            '🚪 VibeFloorBottomSheet: Request submitted for game ${widget.gameId}');
        setState(() {
          _requestSent = true;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      AppLog.d('❌ VibeFloorBottomSheet: Failed to submit request: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We couldn\'t send your request. Please try again.'),
          ),
        );
      }
    }
  }

  void _dismiss({bool submitted = false}) {
    Navigator.of(context).pop(submitted ? _submittedRequest : null);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.navyDark,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppBorderRadius.modal),
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.navyLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),

              // Animated content switcher
              AnimatedSwitcher(
                duration: MotionTokens.contentReveal,
                switchInCurve: MotionTokens.curveEnter,
                switchOutCurve: MotionTokens.curveExit,
                child: _requestSent
                    ? _buildConfirmationState()
                    : _buildMismatchState(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMismatchState() {
    return Column(
      key: const ValueKey('mismatch'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Text(
          AppVibeFloorCopy.mismatchTitle,
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.sm),

        // Body text
        Text(
          AppVibeFloorCopy.mismatchBody(widget.ownerFirstName),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.lg),

        // Gap indicator showing top 2-3 mismatched dimensions
        VibeGapIndicator(
          matchResult: widget.matchResult,
          ownerProfile: widget.ownerProfile,
          playerProfile: widget.playerProfile,
          maxDimensions: 2,
        ),
        SizedBox(height: AppSpacing.lg),

        // Request to join button
        AppButtonEnhanced(
          text: AppVibeFloorCopy.requestToJoinButton,
          variant: AppButtonVariant.primary,
          size: AppButtonSize.large,
          fullWidth: true,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submitRequest,
        ),
        SizedBox(height: AppSpacing.sm),

        // Not now button
        AppButtonEnhanced(
          text: AppVibeFloorCopy.notNowButton,
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.large,
          fullWidth: true,
          onPressed: () => _dismiss(submitted: false),
        ),
      ],
    );
  }

  Widget _buildConfirmationState() {
    return Column(
      key: const ValueKey('confirmation'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Checkmark icon in circular container
        Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: AppOpacity.glass),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppIcon(
                icon: AppPhosphorIcons.check,
                size: AppIconSize.lg,
                color: AppColors.green,
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.md),

        // Header
        Text(
          AppVibeFloorCopy.requestSentTitle,
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.sm),

        // Body text
        Text(
          AppVibeFloorCopy.requestSentBody(widget.ownerFirstName),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.lg),

        // Done button
        AppButtonEnhanced(
          text: AppVibeFloorCopy.doneButton,
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.large,
          fullWidth: true,
          onPressed: () => _dismiss(submitted: true),
        ),
      ],
    );
  }
}
