import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';

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
        color: AppColors.fairway.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? AppColors.sunsetGold.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
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
                  style: TextStyle(fontFamily: 'Outfit',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  description,
                  style: TextStyle(fontFamily: 'Outfit',
                    color: Colors.white.withValues(alpha: 0.7),
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
                        colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                      )
                    : null,
                color: value ? null : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
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
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
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
