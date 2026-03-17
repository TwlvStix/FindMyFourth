import 'dart:math';

import 'package:flutter/material.dart';

import '/core/design_patterns/premium_ui_patterns.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

/// Header for the Challenge Board page showing a premium progress ring.
///
/// Displays a gradient gold progress ring inside a GlassCard with
/// completed/total count and an uppercase label.
class ChallengeBoardHeader extends StatelessWidget {
  const ChallengeBoardHeader({
    super.key,
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progressValue = total > 0 ? completed / total : 0.0;
    final hasProgress = completed > 0;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.screenPadding,
      ),
      child: GlassCard(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Container(
              decoration: hasProgress
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          blurRadius: 40,
                        ),
                      ],
                    )
                  : null,
              child: SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _ProgressRingPainter(
                    progress: progressValue,
                    hasProgress: hasProgress,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$completed',
                          style: AppTypography.monoDisplay.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '/ $total',
                          style: AppTypography.monoSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'CHALLENGES COMPLETED',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.hasProgress,
  });

  final double progress;
  final bool hasProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const strokeWidth = 8.0;

    // Background track
    final trackPaint = Paint()
      ..color = AppColors.navyLight.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Progress arc with gold gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + 2 * pi * progress,
        colors: const [AppColors.goldDark, AppColors.goldLight],
        transform: const GradientRotation(-pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.hasProgress != hasProgress;
}
