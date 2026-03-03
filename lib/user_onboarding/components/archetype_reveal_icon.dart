import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_icon.dart';

/// The icon section of the archetype reveal with animated glow effect.
///
/// Displays an archetype-specific icon inside a bordered container
/// with an ambient glow that pulses based on animation values.
class ArchetypeRevealIcon extends StatelessWidget {
  const ArchetypeRevealIcon({
    super.key,
    required this.accentColor,
    required this.icon,
    required this.glowValue,
    required this.iconValue,
  });

  /// The accent color for the glow and border.
  final Color accentColor;

  /// The archetype's representative icon.
  final PhosphorIconData icon;

  /// Animation value (0.0-1.0) for the glow effect.
  final double glowValue;

  /// Animation value (0.0-1.0) for the icon scale and opacity.
  final double iconValue;

  @override
  Widget build(BuildContext context) {
    final glowOpacity = glowValue * 0.30;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Ambient glow
        Opacity(
          opacity: glowValue,
          child: Transform.scale(
            scale: 0.8 + (glowValue * 0.2),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: glowOpacity),
                    accentColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Icon container with ring
        Semantics(
          label: 'Achievement unlocked',
          child: Transform.scale(
            scale: iconValue,
            child: Opacity(
              opacity: iconValue.clamp(0.0, 1.0),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColorsDark.navyLight,
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: AppIcon(
                    icon: icon,
                    size: AppIconSize.xxl,
                    color: accentColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
