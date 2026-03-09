import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/motion_helpers.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/services/pre_game_confirmation_service.dart';

/// Bottom sheet shown when a host taps the pre-game confirmation notification.
///
/// Presents two actions:
/// - "Still on" - Confirms the game is happening
/// - "Cancel game" - Cancels the game and notifies all players
class PreGameConfirmBottomSheet extends StatefulWidget {
  const PreGameConfirmBottomSheet({
    super.key,
    required this.gameId,
    required this.courseName,
    required this.gameDate,
    required this.onConfirmed,
    required this.onCancelled,
  });

  /// Game ID for the confirmation action
  final String gameId;

  /// Course name for the message
  final String courseName;

  /// Formatted game date/time for the message
  final String gameDate;

  /// Called when host confirms the game is still on
  final VoidCallback onConfirmed;

  /// Called when host cancels the game
  final VoidCallback onCancelled;

  @override
  State<PreGameConfirmBottomSheet> createState() =>
      _PreGameConfirmBottomSheetState();
}

class _PreGameConfirmBottomSheetState extends State<PreGameConfirmBottomSheet> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleConfirm() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = PreGameConfirmationService();
      await service.submitConfirmation(
        gameId: widget.gameId,
        confirmed: true,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onConfirmed();
    } catch (e) {
      AppLog.d('❌ PreGameConfirmBottomSheet: Failed to confirm game: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _handleCancel() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = PreGameConfirmationService();
      await service.submitConfirmation(
        gameId: widget.gameId,
        confirmed: false,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCancelled();
    } catch (e) {
      AppLog.d('❌ PreGameConfirmBottomSheet: Failed to cancel game: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.xxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
            ),
          ),
          SafeArea(
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
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.card),
                        ),
                        child: AppIcon(
                          icon: PhosphorIconsRegular.flagCheckered,
                          size: AppIconSize.md,
                          color: AppColors.green,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Is your game still on?',
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
                    'Your round at ${widget.courseName} on ${widget.gameDate} '
                    "isn't full yet.",
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
                          text: 'Cancel game',
                          variant: AppButtonVariant.destructiveOutlined,
                          onPressed: _isLoading ? null : _handleCancel,
                          isLoading: _isLoading,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButtonEnhanced(
                          text: 'Still on',
                          variant: AppButtonVariant.primary,
                          onPressed: _isLoading ? null : _handleConfirm,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the pre-game confirmation bottom sheet.
///
/// Returns the user's action or null if dismissed.
Future<String?> showPreGameConfirmBottomSheet({
  required BuildContext context,
  required String gameId,
  required String courseName,
  required String gameDate,
  required VoidCallback onConfirmed,
  required VoidCallback onCancelled,
}) {
  return showAppBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.transparent,
    isScrollControlled: true,
    builder: (context) => PreGameConfirmBottomSheet(
      gameId: gameId,
      courseName: courseName,
      gameDate: gameDate,
      onConfirmed: onConfirmed,
      onCancelled: onCancelled,
    ),
  );
}
