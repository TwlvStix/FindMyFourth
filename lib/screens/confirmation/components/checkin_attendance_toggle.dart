import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/motion_tokens.dart';

/// Compact segmented toggle pair: [Present | No-show]
/// Reads as a single binary control, right-aligned in the row.
class CheckinAttendanceToggle extends StatelessWidget {
  const CheckinAttendanceToggle({
    super.key,
    required this.isPresent,
    required this.onToggle,
  });

  final bool isPresent;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(
          color: AppColors.navyLight,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToggleSegment(
              label: 'Present',
              selected: isPresent,
              selectedColor: AppColors.green,
              onTap: () => onToggle(true),
            ),
            _ToggleSegment(
              label: 'No-show',
              selected: !isPresent,
              selectedColor: AppColors.error,
              onTap: () => onToggle(false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual segment within the toggle pair.
class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionTokens.microInteraction,
        curve: MotionTokens.curveEnter,
        height: 32,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? selectedColor : AppColors.navyLight,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
