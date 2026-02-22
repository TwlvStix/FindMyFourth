import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';

/// Segment options for the Golfers page.
enum GolferSegment { discover, requests, friends }

/// Unified segmented control for switching between Discover, Requests, and Friends views.
class GolferSegmentedControl extends StatelessWidget {
  final GolferSegment selectedSegment;
  final ValueChanged<GolferSegment> onSegmentChanged;
  final int requestsBadgeCount;

  const GolferSegmentedControl({
    super.key,
    required this.selectedSegment,
    required this.onSegmentChanged,
    this.requestsBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: EdgeInsets.all(AppSpacing.xs - 2),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: Border.all(
          color: AppColors.navyLight.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildSegment(
            label: 'Discover',
            segment: GolferSegment.discover,
            isSelected: selectedSegment == GolferSegment.discover,
          ),
          _buildSegment(
            label: 'Requests',
            segment: GolferSegment.requests,
            isSelected: selectedSegment == GolferSegment.requests,
            badgeCount: requestsBadgeCount,
          ),
          _buildSegment(
            label: 'Friends',
            segment: GolferSegment.friends,
            isSelected: selectedSegment == GolferSegment.friends,
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required String label,
    required GolferSegment segment,
    required bool isSelected,
    int badgeCount = 0,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            HapticFeedback.lightImpact();
            onSegmentChanged(segment);
          }
        },
        child: AnimatedContainer(
          duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
          curve: MotionTokens.curveEnter,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.navyLight.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedDefaultTextStyle(
                  duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.2,
                  ),
                  child: Text(label),
                ),
                if (badgeCount > 0) ...[
                  SizedBox(width: AppSpacing.xs - 2),
                  _buildBadge(badgeCount),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs - 2, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: AppTypography.labelSmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.navyDark,
          height: 1.2,
        ),
      ),
    );
  }
}
