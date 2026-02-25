import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/opacity.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/notification_settings/components/notification_toggle.dart';

/// A collapsible card for notification category settings.
///
/// Features:
/// - 40x40 icon container with category icon
/// - Title and summary text with status dot indicator
/// - Custom toggle switch (48x28)
/// - Animated chevron that rotates 90 degrees when expanded
/// - AnimatedSize expansion for expandedContent
/// - Disabled state with reduced opacity when toggle is off
class NotificationCategoryCard extends StatelessWidget {
  const NotificationCategoryCard({
    super.key,
    required this.title,
    required this.summary,
    required this.icon,
    required this.isEnabled,
    required this.isExpanded,
    required this.onToggle,
    required this.onTap,
    this.expandedContent,
  });

  /// Category title displayed in header
  final String title;

  /// Summary text showing current state (e.g., "Instant", "Off", "10:00 PM - 7:00 AM")
  final String summary;

  /// Icon for the category
  final PhosphorIconData icon;

  /// Whether notifications for this category are enabled
  final bool isEnabled;

  /// Whether the card is expanded to show detailed settings
  final bool isExpanded;

  /// Callback when toggle is tapped
  final VoidCallback onToggle;

  /// Callback when card body is tapped (expand/collapse)
  final VoidCallback onTap;

  /// Content to show when expanded (null for collapsed-only cards)
  final Widget? expandedContent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(
          color: AppColors.navyLight.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          _buildHeader(),

          // Expansion content
          _buildExpansion(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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

            // Title and summary
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
                          color: isEnabled
                              ? AppColors.green
                              : AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      // Summary text
                      Expanded(
                        child: Text(
                          summary,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: AppSpacing.sm),

            // Toggle (separate tap target)
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: NotificationToggle(
                value: isEnabled,
                onChanged: (_) => onToggle(),
              ),
            ),

            SizedBox(width: AppSpacing.xs),

            // Chevron with rotation animation
            AnimatedRotation(
              duration: ReducedMotionService.adjust(MotionTokens.routeEnter),
              curve: MotionTokens.curveEnter,
              turns: isExpanded ? 0.25 : 0.0,
              child: AppIcon(
                icon: AppPhosphorIcons.chevronRight,
                size: AppIconSize.sm,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansion() {
    return AnimatedSize(
      duration: ReducedMotionService.adjust(MotionTokens.routeEnter),
      curve: MotionTokens.curveEnter,
      child: isExpanded && expandedContent != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(
                  color: AppColors.navyLight.withValues(alpha: 0.3),
                  height: 1,
                  thickness: 1,
                ),
                _buildDisabledWrapper(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: expandedContent!,
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildDisabledWrapper({required Widget child}) {
    if (isEnabled) return child;

    return AnimatedOpacity(
      duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
      opacity: AppOpacity.disabled,
      child: IgnorePointer(
        child: child,
      ),
    );
  }
}
