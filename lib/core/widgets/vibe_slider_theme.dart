import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';

/// Custom slider theme for vibe preference sliders
///
/// Features:
/// - Thinner track (3px vs Flutter's default)
/// - Green active track, navy inactive track
/// - Gold thumb with subtle glow effect
/// - No value indicator (relies on external badge)
/// - Tick marks at intermediate positions (1-4)
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
        trackShape: TickedSliderTrackShape(
          tickColor: AppColorsDark.textMuted.withValues(alpha: 0.4),
        ),
      );
}

/// Custom track shape that draws tick marks at intermediate positions (1-4)
///
/// Tick marks appear at positions 1, 2, 3, and 4 on a 0-5 scale,
/// helping users identify discrete value positions.
class TickedSliderTrackShape extends RoundedRectSliderTrackShape {
  const TickedSliderTrackShape({
    required this.tickColor,
    this.tickWidth = 1.5,
    this.tickHeight = 8.0,
  });

  /// Color of the tick marks
  final Color tickColor;

  /// Width of each tick mark
  final double tickWidth;

  /// Height of each tick mark
  final double tickHeight;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
    double additionalActiveTrackHeight = 2,
  }) {
    // Paint the base track first
    super.paint(
      context,
      offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      thumbCenter: thumbCenter,
      secondaryOffset: secondaryOffset,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
      textDirection: textDirection,
      additionalActiveTrackHeight: additionalActiveTrackHeight,
    );

    // Now paint tick marks at positions 1, 2, 3, 4 (on a 0-5 scale)
    final canvas = context.canvas;
    final trackHeight = sliderTheme.trackHeight ?? 4;

    // Calculate track bounds (accounting for thumb radius)
    final thumbRadius = sliderTheme.thumbShape?.getPreferredSize(true, isDiscrete).width ?? 20;
    final trackLeft = offset.dx + thumbRadius / 2;
    final trackRight = parentBox.size.width - thumbRadius / 2;
    final trackWidth = trackRight - trackLeft;

    // Track vertical center
    final trackCenterY = offset.dy + parentBox.size.height / 2;

    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = tickWidth
      ..strokeCap = StrokeCap.round;

    // Draw ticks at positions 1, 2, 3, 4 (skip 0 and 5 endpoints)
    const divisions = 5; // 0-5 scale has 5 divisions
    for (int i = 1; i <= 4; i++) {
      final tickX = trackLeft + (trackWidth * i / divisions);
      final tickTop = trackCenterY - (tickHeight / 2) + (trackHeight / 2);
      final tickBottom = tickTop + tickHeight;

      canvas.drawLine(
        Offset(tickX, tickTop),
        Offset(tickX, tickBottom),
        tickPaint,
      );
    }
  }
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
