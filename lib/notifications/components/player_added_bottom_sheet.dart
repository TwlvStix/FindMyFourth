import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_patterns/premium_ui_patterns.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/motion_helpers.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/services/player_added_response_service.dart';

/// Bottom sheet shown when a player is added to a game by the host.
///
/// Presents two actions:
/// - "Got it" - Acknowledges and navigates to game details
/// - "Can't make it" - Declines the spot and notifies the host
class PlayerAddedBottomSheet extends StatefulWidget {
  const PlayerAddedBottomSheet({
    super.key,
    required this.gameId,
    required this.hostName,
    required this.courseName,
    required this.gameDate,
    required this.onGotIt,
    required this.onDeclined,
  });

  /// Game ID for the decline action
  final String gameId;

  /// Host display name for the message
  final String hostName;

  /// Course name for the message
  final String courseName;

  /// Formatted game date/time for the message
  final String gameDate;

  /// Called when user taps "Got it"
  final VoidCallback onGotIt;

  /// Called when user successfully declines the spot
  final VoidCallback onDeclined;

  @override
  State<PlayerAddedBottomSheet> createState() => _PlayerAddedBottomSheetState();
}

class _PlayerAddedBottomSheetState extends State<PlayerAddedBottomSheet> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleDecline() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = PlayerAddedResponseService();
      await service.declineAddedSpot(gameId: widget.gameId);

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onDeclined();
    } catch (e) {
      AppLog.d('❌ PlayerAddedBottomSheet: Failed to decline spot: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  void _handleGotIt() {
    Navigator.of(context).pop();
    widget.onGotIt();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetCard(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: AppSpacing.screen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppIcon(
                      icon: PhosphorIconsRegular.userPlus,
                      size: 24,
                      color: AppColors.green,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      "You've been added to a game",
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.lg),

              // Game details
              Text(
                '${widget.hostName} added you to ${widget.courseName} on ${widget.gameDate}.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              // Error message if any
              if (_errorMessage != null) ...[
                SizedBox(height: AppSpacing.sm),
                Text(
                  _errorMessage!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],

              SizedBox(height: AppSpacing.xl),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: AppButtonEnhanced(
                      text: "Can't make it",
                      variant: AppButtonVariant.destructiveOutlined,
                      onPressed: _isLoading ? null : _handleDecline,
                      isLoading: _isLoading,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButtonEnhanced(
                      text: 'Got it',
                      variant: AppButtonVariant.primary,
                      onPressed: _isLoading ? null : _handleGotIt,
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the player-added bottom sheet and handles navigation.
///
/// Returns the user's action: 'got_it', 'declined', or null if dismissed.
Future<String?> showPlayerAddedBottomSheet({
  required BuildContext context,
  required String gameId,
  required String hostName,
  required String courseName,
  required String gameDate,
  required VoidCallback onGotIt,
  required VoidCallback onDeclined,
}) {
  return showAppBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => PlayerAddedBottomSheet(
      gameId: gameId,
      hostName: hostName,
      courseName: courseName,
      gameDate: gameDate,
      onGotIt: onGotIt,
      onDeclined: onDeclined,
    ),
  );
}
