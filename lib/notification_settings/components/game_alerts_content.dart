import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/providers/provider_extensions.dart';
import '/notification_settings/components/expand_section_label.dart';
import '/notification_settings/components/delivery_frequency_selector.dart';

/// Expanded content for the Game Alerts notification category card.
///
/// Shows:
/// - Filter tag chip displaying current filter state
/// - Configure filters link to navigate to game alerts page
/// - Delivery frequency selector
class GameAlertsContent extends StatelessWidget {
  const GameAlertsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watchNotificationProvider;
    final prefs = provider.preferences;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Filter tag chip
        _buildFilterTag(),

        SizedBox(height: AppSpacing.sm),

        // Configure filters link
        _buildConfigureFiltersLink(context),

        // Delivery section
        const ExpandSectionLabel(text: 'DELIVERY', showDivider: true),
        DeliveryFrequencySelector(
          selected: prefs.gameAlerts.deliveryFrequency,
          onChanged: (freq) {
            context.notificationProvider.updateGameAlerts(delivery: freq);
          },
        ),
      ],
    );
  }

  Widget _buildFilterTag() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.navyLight.withValues(alpha: 0.3),
        border: Border.all(
          color: AppColors.navyLight.withValues(alpha: 0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            icon: AppPhosphorIcons.filter,
            size: AppIconSize.xs,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            'Watching: All games',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigureFiltersLink(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/gameAlertsPage'),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            icon: AppPhosphorIcons.settings,
            size: AppIconSize.sm,
            color: AppColors.green,
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            'Configure filters',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
