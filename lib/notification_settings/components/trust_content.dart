import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/providers/provider_extensions.dart';
import '/notification_settings/components/notification_toggle.dart';

/// Expanded content for the Trust and Reliability notification category card.
///
/// Shows:
/// - Two sub-toggle rows with dividers:
///   - Account standing
///   - Badge progress
///
/// NOTE: Post-round check-ins toggle is intentionally hidden (see commented
/// code in build()). Post-round check-ins are a core system feature and cannot
/// be disabled by users.
///
/// Delivery frequency selector hidden until backend digest logic is complete.
/// To re-enable: add ExpandSectionLabel + DeliveryFrequencySelector with
/// trust.deliveryFrequency
class TrustContent extends StatelessWidget {
  const TrustContent({super.key});

  @override
  Widget build(BuildContext context) {
    final trust = context.selectNotification(
      (p) => p.preferences.trustCategories,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ================================================================
        // POST-ROUND CHECK-INS TOGGLE (HIDDEN)
        // ----------------------------------------------------------------
        // This toggle allowed users to turn off post-round check-in
        // notifications. It has been hidden because post-round check-ins
        // are a core part of our trust system and should always be enabled.
        // The underlying preference value (trust.postRound) remains in the
        // data model but should always be true.
        //
        // Original code:
        // _buildToggleRow(
        //   context: context,
        //   label: 'Post-round check-ins',
        //   hint: 'Reminders after your rounds',
        //   value: trust.postRound,
        //   onChanged: (val) {
        //     context.notificationProvider.updateTrustCategories(postRound: val);
        //   },
        // ),
        // _buildDivider(),
        // ================================================================

        // Row 1: Account standing
        _buildToggleRow(
          context: context,
          label: 'Account standing',
          hint: 'Strikes, cooldowns, restrictions',
          value: trust.trustAlerts,
          onChanged: (val) {
            context.notificationProvider
                .updateTrustCategories(trustAlerts: val);
          },
        ),
        _buildDivider(),

        // Row 2: Badge progress (no trailing divider)
        _buildToggleRow(
          context: context,
          label: 'Badge progress',
          hint: 'Milestones and updates',
          value: trust.badges,
          onChanged: (val) {
            context.notificationProvider.updateTrustCategories(badges: val);
          },
        ),

        // Delivery frequency selector hidden until backend digest logic is complete.
        // To re-enable: add ExpandSectionLabel + DeliveryFrequencySelector here.
      ],
    );
  }

  Widget _buildToggleRow({
    required BuildContext context,
    required String label,
    required String hint,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  hint,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          NotificationToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: AppColors.navyLight.withValues(alpha: 0.15),
      height: 1,
      thickness: 1,
    );
  }
}
