import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/motion/motion_helpers.dart';
import '/core/widgets/app_button_enhanced.dart';

/// Inline cancellation warning icon for public profiles.
///
/// Only renders when the cancellation warning is active. Shows a subtle
/// amber icon (NOT error red — this is informational) that reveals a
/// bottom sheet with details on tap.
class CancellationWarningIcon extends StatelessWidget {
  const CancellationWarningIcon({
    super.key,
    required this.warningCount,
    required this.detail,
  });

  /// Number of recent cancellations (for screen reader accessibility)
  final int warningCount;

  /// Human-readable detail string, e.g. "2 late cancellations in the last 90 days"
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cancellation warning: $warningCount recent cancellations. Tap for details.',
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _showDetailSheet(context);
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: AppSpacing.allXxs,
          child: PhosphorIcon(
            AppPhosphorIcons.warning,
            size: AppIconSize.sm,
            // Intentionally goldLight, NOT error — this is informational
            color: AppColors.goldLight,
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => _CancellationWarningSheet(
        warningCount: warningCount,
        detail: detail,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CancellationWarningSheet extends StatelessWidget {
  const _CancellationWarningSheet({
    required this.warningCount,
    required this.detail,
  });

  final int warningCount;
  final String detail;

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

          // Title
          Text(
            'Recent Cancellations',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onyx,
            ),
          ),
          SizedBox(height: AppSpacing.sm),

          // Detail
          Text(
            detail,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.slate),
          ),
          SizedBox(height: AppSpacing.xs),

          // Sub-note
          Text(
            'This clears automatically over time.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.stone),
          ),
          SizedBox(height: AppSpacing.lg),

          // Dismiss button
          AppButtonEnhanced(
            text: 'Got it',
            variant: AppButtonVariant.ghost,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
