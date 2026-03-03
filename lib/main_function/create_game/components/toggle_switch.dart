import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';

/// A consistent toggle switch widget with label and description.
///
/// Features:
/// - Animated toggle state with gradient background
/// - Gold gradient when enabled
/// - Label and description text
/// - Haptic feedback on tap
/// - Visual highlight border when active
///
/// Used for: Member discount, other boolean settings
class ToggleSwitch extends StatelessWidget {
  const ToggleSwitch({
    super.key,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: value
              ? AppColors.green.withValues(alpha: 0.5)
              : AppColors.glassSurface,
          width: value ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.pure,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.glassTextSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(!value);
            },
            child: AnimatedContainer(
              duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
              width: 56,
              height: 32,
              decoration: BoxDecoration(
                gradient: value
                    ? LinearGradient(
                        colors: [AppColors.green, AppColors.greenLight],
                      )
                    : null,
                color: value ? null : AppColors.glassBorder,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: AnimatedAlign(
                duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 26,
                  height: 26,
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: AppColors.pure,
                    shape: BoxShape.circle,
                    boxShadow: [AppElevation.sm],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
