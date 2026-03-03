import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/models/game.dart';

import '../components/edit_game_details_bottom_sheet.dart';
import 'game_joined_detailed_controller.dart';

/// Handles game editing flows including validation, sheet launch, and updates.
///
/// Delegates business logic to [GameJoinedDetailedController], handles UI
/// feedback (dialogs, progress indicators, snackbars).
class GameJoinedEditActions {
  GameJoinedEditActions({
    required this.controller,
  });

  final GameJoinedDetailedController controller;

  /// Handles the edit game details flow.
  ///
  /// 1. Validates tee time is not within 2 hours (shows info dialog if locked)
  /// 2. Shows edit bottom sheet
  /// 3. If user submits, shows progress dialog and updates game
  /// 4. Shows success/error feedback
  Future<void> handleEditGameDetails({
    required BuildContext context,
    required State state,
    required Game gameRecord,
    required String? currentUserUid,
  }) async {
    // Tee-time lockout check
    final teeTime = gameRecord.date;
    if (teeTime != null) {
      final hoursUntilTeeTime = teeTime.difference(DateTime.now()).inHours;
      if (hoursUntilTeeTime < 2) {
        await showPremiumDialog(
          context: context,
          variant: PremiumDialogVariant.informational,
          icon: PhosphorIconsRegular.info,
          title: 'Cannot Edit',
          body:
              'Tee time is less than 2 hours away. Consider cancelling this game and creating a new one instead.',
          actionLabel: 'Got It',
        );
        return;
      }
    }

    // Show edit bottom sheet
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => EditGameDetailsBottomSheet(
        gameRef: gameRecord.reference,
        initialDate: gameRecord.date ?? DateTime.now(),
        initialCourse: gameRecord.coursePlay,
        initialCourseRef: gameRecord.courseRef,
      ),
    );

    if (result != null && context.mounted) {
      await _updateGameDetails(
        context: context,
        state: state,
        gameRecord: gameRecord,
        updateData: result,
        currentUserUid: currentUserUid,
      );
    }
  }

  Future<void> _updateGameDetails({
    required BuildContext context,
    required State state,
    required Game gameRecord,
    required Map<String, dynamic> updateData,
    required String? currentUserUid,
  }) async {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          margin: EdgeInsets.all(AppSpacing.xl),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.green),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Updating game details...',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final actionResult = await controller.updateGameDetails(
      gameRecord: gameRecord,
      date: updateData['date'] as DateTime,
      course: updateData['course'] as String,
      courseRef: updateData['courseRef'] is DocumentReference
          ? updateData['courseRef'] as DocumentReference
          : null,
      currentUserUid: currentUserUid,
    );

    if (!context.mounted) return;
    if (!state.mounted) return;

    // Dismiss progress dialog
    Navigator.pop(context);

    if (actionResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Game details updated!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      AppLog.d('Edit Game Details failed: ${actionResult.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(actionResult.message ?? 'Failed to update game.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
