import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/border_radius.dart';

/// Custom animated toggle switch for vibe dealbreakers
///
/// Features:
/// - Animated gradient background when ON
/// - Circular white thumb with shadow
/// - Haptic feedback on tap
/// - Subtle border highlight when active
/// - Reduced motion support
///
/// Usage:
/// ```dart
/// VibeToggle(
///   value: isDealbreaker,
///   onChanged: (value) => setState(() => isDealbreaker = value),
///   activeColor: AppColorsDark.gold, // Optional, defaults to green
/// )
/// ```
class VibeToggle extends StatelessWidget {
  const VibeToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  /// Current toggle state
  final bool value;

  /// Callback when toggle state changes
  final ValueChanged<bool> onChanged;

  /// Color for active state gradient (defaults to AppColorsDark.green)
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    // Default to green for interactive elements; gold only passed for dealbreaker
    final color = activeColor ?? AppColorsDark.green;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
        width: 52,
        height: 28,
        decoration: BoxDecoration(
          gradient: value
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [color, color.withValues(alpha: 0.8)],
                )
              : null,
          color: value ? null : AppColorsDark.navyLight,
          borderRadius: BorderRadius.circular(AppBorderRadius.full),
          border: Border.all(
            color: value
                ? color.withValues(alpha: 0.4)
                : AppColorsDark.glassBorder,
            width: value ? 1.5 : 1,
          ),
        ),
        child: AnimatedAlign(
          duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: AppColorsDark.textPrimary,
              shape: BoxShape.circle,
              boxShadow: [AppElevation.sm],
            ),
          ),
        ),
      ),
    );
  }
}
