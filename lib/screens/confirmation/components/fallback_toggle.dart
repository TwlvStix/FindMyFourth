import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/motion_tokens.dart';

/// Segmented toggle pair for fallback confirmation: [Yes | No]
class FallbackToggle extends StatelessWidget {
  const FallbackToggle({super.key, required this.selection, required this.onSelect});

  final bool selection;
  final ValueChanged<bool> onSelect;

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
            _FallbackSegment(
              label: 'Yes',
              selected: selection == true,
              selectedColor: AppColors.green,
              onTap: () => onSelect(true),
            ),
            _FallbackSegment(
              label: 'No',
              selected: selection == false,
              selectedColor: AppColors.error,
              onTap: () => onSelect(false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual segment within the fallback toggle.
class _FallbackSegment extends StatelessWidget {
  const _FallbackSegment({
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
