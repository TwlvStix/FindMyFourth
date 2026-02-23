import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/motion/motion_helpers.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/models/game.dart';
import '/services/cancellation_service.dart';

/// Cancellation warning modal — shown when a player taps "Leave Game" / "Cancel Spot".
///
/// Presents tier-appropriate messaging based on how much time remains until
/// the tee time. Returns `true` if the player confirmed cancellation,
/// or `false` / `null` if they chose to keep their spot.
///
/// Three states:
///   Early (36+ hrs)  → success treatment, ghost cancel button, no penalty
///   Late (12–36 hrs) → goldLight warning, cancellation is tracked
///   Day-of (< 12 hrs) → error treatment, 1 strike will be recorded
///
/// "Keep My Spot" is always the visually primary action.
abstract class CancellationWarningModal {
  CancellationWarningModal._();

  /// Show the cancellation warning modal and await the player's decision.
  ///
  /// [game] — the game the player is leaving
  /// [activeStrikes] — current number of active strikes (shown in day-of state)
  ///
  /// Returns `true` if the player confirmed cancellation, `false` or `null`
  /// if they chose to keep their spot or dismissed the sheet.
  static Future<bool?> show(
    BuildContext context, {
    required Game game,
    int activeStrikes = 0,
  }) async {
    final teeTime = game.date;
    final cancellationType = teeTime != null
        ? getCancellationType(DateTime.now(), teeTime)
        : CancellationType.early;

    return showAppBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => _CancellationWarningSheet(
        game: game,
        cancellationType: cancellationType,
        activeStrikes: activeStrikes,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CancellationWarningSheet extends StatelessWidget {
  const _CancellationWarningSheet({
    required this.game,
    required this.cancellationType,
    required this.activeStrikes,
  });

  final Game game;
  final CancellationType cancellationType;
  final int activeStrikes;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.xl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.modalPadding,
        AppSpacing.md,
        AppSpacing.modalPadding,
        AppSpacing.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cloud,
                borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Header
          Text(
            'Cancel your spot?',
            style: AppTypography.headlineMediumSans.copyWith(
              fontSize: 22,
              color: AppColors.onyx,
            ),
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            '${game.coursePlay} — ${_formatTeeTime(game.date)}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.slate),
          ),
          SizedBox(height: AppSpacing.lg),

          // State-specific content
          _buildStateContent(context),
        ],
      ),
    );
  }

  Widget _buildStateContent(BuildContext context) {
    switch (cancellationType) {
      case CancellationType.early:
        return _EarlyState(onKeep: () => Navigator.of(context).pop(false),
            onCancel: () => Navigator.of(context).pop(true));
      case CancellationType.late:
        return _LateState(onKeep: () => Navigator.of(context).pop(false),
            onCancel: () => Navigator.of(context).pop(true));
      case CancellationType.dayOf:
        return _DayOfState(
          activeStrikes: activeStrikes,
          onKeep: () => Navigator.of(context).pop(false),
          onCancel: () => Navigator.of(context).pop(true),
        );
    }
  }

  static String _formatTeeTime(DateTime? dt) {
    if (dt == null) return 'upcoming game';
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour < 12 ? 'AM' : 'PM';
    return '${months[dt.month]} ${dt.day} at $h:$m $amPm';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State A: Early (36+ hrs) — no penalty
// ─────────────────────────────────────────────────────────────────────────────

class _EarlyState extends StatelessWidget {
  const _EarlyState({required this.onKeep, required this.onCancel});
  final VoidCallback onKeep;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Info box
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha:0.10),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhosphorIcon(AppPhosphorIcons.success,
                  color: AppColors.success, size: AppIconSize.button),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  "No penalty — you're cancelling with plenty of notice.\n"
                  "Your spot will reopen for others.",
                  style: AppTypography.bodySmall.copyWith(
                      color: AppColors.slate),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),

        // Keep My Spot (primary)
        AppButtonEnhanced(
          text: 'Keep My Spot',
          variant: AppButtonVariant.primary,
          fullWidth: true,
          onPressed: onKeep,
        ),
        SizedBox(height: AppSpacing.xs),

        // Cancel Spot (ghost)
        AppButtonEnhanced(
          text: 'Cancel Spot',
          variant: AppButtonVariant.ghost,
          fullWidth: true,
          onPressed: onCancel,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State B: Late (12–36 hrs) — tracked
// ─────────────────────────────────────────────────────────────────────────────

class _LateState extends StatelessWidget {
  const _LateState({required this.onKeep, required this.onCancel});
  final VoidCallback onKeep;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Warning box
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.goldLight.withValues(alpha:0.10),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhosphorIcon(AppPhosphorIcons.warning,
                      color: AppColors.goldLight, size: AppIconSize.button),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'This is a late cancellation. The host has limited time to fill your spot.',
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.slate),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Divider(color: AppColors.cloud, height: 1),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Late cancellations are tracked. 3 within 90 days results in a strike.',
                style: AppTypography.labelSmall.copyWith(
                    color: AppColors.stone),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),

        // Keep My Spot (primary)
        AppButtonEnhanced(
          text: 'Keep My Spot',
          variant: AppButtonVariant.primary,
          fullWidth: true,
          onPressed: onKeep,
        ),
        SizedBox(height: AppSpacing.xs),

        // Cancel Anyway (destructive)
        AppButtonEnhanced(
          text: 'Cancel Anyway',
          variant: AppButtonVariant.destructive,
          fullWidth: true,
          onPressed: onCancel,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State C: Day-of (< 12 hrs) — 1 strike
// ─────────────────────────────────────────────────────────────────────────────

class _DayOfState extends StatelessWidget {
  const _DayOfState({
    required this.activeStrikes,
    required this.onKeep,
    required this.onCancel,
  });
  final int activeStrikes;
  final VoidCallback onKeep;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Danger box
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha:0.08),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhosphorIcon(AppPhosphorIcons.error,
                      color: AppColors.error, size: AppIconSize.button),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'This is a day-of cancellation. The host almost certainly cannot find a replacement.',
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.slate),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Divider(color: AppColors.cloud, height: 1),
              SizedBox(height: AppSpacing.sm),
              Text(
                'This will result in 1 strike on your account.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.xxs),
              Text(
                'You currently have $activeStrikes active strike${activeStrikes != 1 ? 's' : ''}.',
                style: AppTypography.labelSmall.copyWith(
                    color: AppColors.stone),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),

        // Keep My Spot (primary)
        AppButtonEnhanced(
          text: 'Keep My Spot',
          variant: AppButtonVariant.primary,
          fullWidth: true,
          onPressed: onKeep,
        ),
        SizedBox(height: AppSpacing.xs),

        // Cancel Anyway (destructive)
        AppButtonEnhanced(
          text: 'Cancel Anyway',
          variant: AppButtonVariant.destructive,
          fullWidth: true,
          onPressed: onCancel,
        ),
      ],
    );
  }
}
