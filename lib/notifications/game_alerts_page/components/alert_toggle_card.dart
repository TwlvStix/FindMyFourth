import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_icon.dart';
import '/notification_settings/components/notification_toggle.dart';

/// Toggle row card for Special options (Side Games, 2v2 Teams, Discounted Games).
///
/// Features:
/// - 40x40 icon container with option icon
/// - Title and subtitle with green/gray status dot
/// - NotificationToggle on the right (no chevron)
/// - Matches Notifications page toggle row pattern
class AlertToggleCard extends StatelessWidget {
  const AlertToggleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  /// Option title (e.g., "Side Games", "2v2 (Teams)")
  final String title;

  /// Icon for the option
  final PhosphorIconData icon;

  /// Current toggle state
  final bool value;

  /// Callback when toggle state changes
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(
          color: AppColors.navyLight.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Icon container (40x40)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.navyLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: AppIcon(
                  icon: icon,
                  size: AppIconSize.md,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            SizedBox(width: AppSpacing.sm),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      // Status dot
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: value
                              ? AppColors.green
                              : AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      // Status text
                      Text(
                        value ? 'On' : 'Off',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: AppSpacing.sm),

            // Toggle
            NotificationToggle(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
