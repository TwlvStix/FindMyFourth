import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/providers/provider_extensions.dart';
import '/notification_settings/components/expand_section_label.dart';
import '/notification_settings/components/delivery_frequency_selector.dart';
import '/notification_settings/components/notification_toggle.dart';

/// Expanded content for the Trust and Reliability notification category card.
///
/// Shows:
/// - Three sub-toggle rows with dividers:
///   - Post-round check-ins
///   - Account standing
///   - Badge progress
/// - Delivery frequency selector
class TrustContent extends StatelessWidget {
  const TrustContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watchNotificationProvider;
    final prefs = provider.preferences;
    final trust = prefs.trustCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: Post-round check-ins
        _buildToggleRow(
          context: context,
          label: 'Post-round check-ins',
          hint: 'Reminders after your rounds',
          value: trust.postRound,
          onChanged: (val) {
            context.notificationProvider.updateTrustCategories(postRound: val);
          },
        ),
        _buildDivider(),

        // Row 2: Account standing
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

        // Row 3: Badge progress (no trailing divider)
        _buildToggleRow(
          context: context,
          label: 'Badge progress',
          hint: 'Milestones and updates',
          value: trust.badges,
          onChanged: (val) {
            context.notificationProvider.updateTrustCategories(badges: val);
          },
        ),

        // Delivery section
        const ExpandSectionLabel(text: 'DELIVERY', showDivider: true),
        DeliveryFrequencySelector(
          selected: trust.deliveryFrequency,
          onChanged: (freq) {
            context.notificationProvider.updateTrustCategories(delivery: freq);
          },
        ),
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
