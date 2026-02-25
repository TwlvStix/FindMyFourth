import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/models/alert_subscription.dart';
import '/providers/provider_extensions.dart';
import '/services/alert_subscription_service.dart';
import '/notification_settings/components/expand_section_label.dart';
import '/notification_settings/components/delivery_frequency_selector.dart';

/// Expanded content for the Game Alerts notification category card.
///
/// Shows:
/// - Filter summary displaying current filter state (loaded from Firestore)
/// - Configure filters link to navigate to game alerts page
/// - Delivery frequency selector
class GameAlertsContent extends StatefulWidget {
  const GameAlertsContent({super.key});

  @override
  State<GameAlertsContent> createState() => _GameAlertsContentState();
}

class _GameAlertsContentState extends State<GameAlertsContent> {
  AlertSubscription? _subscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final subscription =
          await AlertSubscriptionService.loadSubscription(currentUserUid);
      if (mounted) {
        setState(() {
          _subscription = subscription;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watchNotificationProvider;
    final prefs = provider.preferences;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Filter summary row
        _buildFilterSummary(),

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

  Widget _buildFilterSummary() {
    final summaryText = _isLoading
        ? 'Loading...'
        : (_subscription?.getSummary() ?? 'Watching: All games');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(
          icon: AppPhosphorIcons.filter,
          size: AppIconSize.sm,
          color: AppColors.textSecondary,
        ),
        SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            summaryText,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildConfigureFiltersLink(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Navigate and wait for result
        final result = await context.push<AlertSubscription>('/gameAlertsPage');
        // Reload subscription if we got a result back
        if (result != null && mounted) {
          setState(() {
            _subscription = result;
          });
        } else {
          // Reload from Firestore to get any updates
          _loadSubscription();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            icon: AppPhosphorIcons.settings,
            size: AppIconSize.sm,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            'Configure filters',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
