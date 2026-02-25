import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';

/// Expandable row card for filter categories (Game Vibe, Stakes, Format, Handicap).
///
/// Features:
/// - 40x40 icon container with category icon
/// - Title and subtitle with green status dot
/// - Animated chevron that rotates 90 degrees when expanded
/// - AnimatedSize expansion for expanded content (chip selectors)
/// - Accordion behavior controlled by parent
class AlertFilterCard extends StatelessWidget {
  const AlertFilterCard({
    super.key,
    required this.title,
    required this.icon,
    required this.selectedValues,
    required this.isExpanded,
    required this.onTap,
    required this.expandedContent,
  });

  /// Category title (e.g., "Game Vibe", "Stakes")
  final String title;

  /// Icon for the category
  final PhosphorIconData icon;

  /// Currently selected filter values (for subtitle generation)
  final List<String> selectedValues;

  /// Whether the card is expanded
  final bool isExpanded;

  /// Callback when card header is tapped
  final VoidCallback onTap;

  /// Content to show when expanded (typically AlertFilterChips)
  final Widget expandedContent;

  /// Generate subtitle text from selected values
  String get _subtitle {
    if (selectedValues.isEmpty) {
      return 'None selected';
    }
    if (selectedValues.length == 1) {
      return selectedValues.first;
    }
    if (selectedValues.length == 2) {
      return '${selectedValues[0]} + ${selectedValues[1]}';
    }
    return '${selectedValues.length} selected';
  }

  /// Whether any values are selected (for dot color)
  bool get _hasSelection => selectedValues.isNotEmpty;

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
                          color: _hasSelection
                              ? AppColors.green
                              : AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      // Subtitle text
                      Expanded(
                        child: Text(
                          _subtitle,
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
      child: isExpanded
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(
                  color: AppColors.navyLight.withValues(alpha: 0.3),
                  height: 1,
                  thickness: 1,
                ),
                Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: expandedContent,
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}
