import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';

/// Custom slider theme for vibe preference sliders
///
/// Features:
/// - Thinner track (3px vs Flutter's default)
/// - Green active track, navy inactive track
/// - Gold thumb with subtle glow effect
/// - No value indicator (relies on external badge)
///
/// Usage:
/// ```dart
/// SliderTheme(
///   data: VibeSliderTheme.darkTheme,
///   child: Slider(...),
/// )
/// ```
class VibeSliderTheme {
  /// Dark theme slider configuration for FairwayBackgroundDark screens
  static SliderThemeData get darkTheme => SliderThemeData(
        activeTrackColor: AppColorsDark.green,
        inactiveTrackColor: AppColorsDark.navyLight,
        thumbColor: AppColorsDark.green,
        overlayColor: AppColorsDark.green.withValues(alpha: 0.15),
        trackHeight: 3,
        showValueIndicator: ShowValueIndicator.never,
        thumbShape: const _GlowingThumbShape(
          enabledThumbRadius: 10,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      );
}

/// Custom thumb shape with subtle glow effect
class _GlowingThumbShape extends SliderComponentShape {
  const _GlowingThumbShape({
    required this.enabledThumbRadius,
  });

  final double enabledThumbRadius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final thumbColor = sliderTheme.thumbColor ?? AppColorsDark.green;

    // Subtle glow shadow
    final glowPaint = Paint()
      ..color = thumbColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, enabledThumbRadius + 2, glowPaint);

    // Main thumb
    final thumbPaint = Paint()..color = thumbColor;
    canvas.drawCircle(center, enabledThumbRadius, thumbPaint);

    // Inner highlight for depth
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(
      center.translate(-1, -1),
      enabledThumbRadius - 2,
      highlightPaint,
    );
  }
}
