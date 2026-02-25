import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';

/// Custom 48x28 toggle switch for notification settings.
///
/// Features:
/// - Track: 48w x 28h, 14px border radius
/// - Knob: 22px diameter, white with subtle shadow
/// - ON: greenDark track, knob right
/// - OFF: navyLight track, knob left
/// - Animation: 100ms with easeOutCubic curve
/// - Haptic feedback on tap
class NotificationToggle extends StatelessWidget {
  const NotificationToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// Current toggle state
  final bool value;

  /// Callback when toggle state changes
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
        curve: MotionTokens.curveEnter,
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          color: value ? AppColors.greenDark : AppColors.navyLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
          curve: MotionTokens.curveEnter,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [AppElevation.xs],
            ),
          ),
        ),
      ),
    );
  }
}
