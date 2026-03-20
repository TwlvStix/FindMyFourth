import 'dart:math' as math;
import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/services/vibe_group_matcher.dart';

/// Group vibe match visualization with ring progress indicator
class GroupVibeSummary extends StatelessWidget {
  const GroupVibeSummary({
    super.key,
    required this.groupVibeMatch,
    required this.onViewBreakdown,
  });

  final GroupVibeMatchResult? groupVibeMatch;
  final VoidCallback onViewBreakdown;

  @override
  Widget build(BuildContext context) {
    final result = groupVibeMatch;
    final groupScore = result?.groupFitScore.round() ?? 0;
    final hasResult = result != null;

    return Semantics(
      label: hasResult
          ? 'Group vibe match: $groupScore percent'
          : 'Group vibe match: calculating',
      child: Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navy.withValues(alpha: 0.4),
            AppColors.navyDark.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Vibe ring with brain icon
              _buildVibeRing(groupScore, hasResult),
              SizedBox(width: AppSpacing.md),
              // Score and labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Large percentage
                    hasResult
                        ? Text(
                            '$groupScore%',
                            style: AppTypography.headlineMedium.copyWith(
                              color: _getScoreColor(groupScore),
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textSecondary,
                            ),
                          ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Group Vibe Match',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      hasResult ? 'Your fit with this group' : 'Calculating...',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // DETAILS button
              if (hasResult)
                Semantics(
                  button: true,
                  label: 'View vibe match details',
                  child: GestureDetector(
                  onTap: onViewBreakdown,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.navyLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(
                          icon: AppPhosphorIcons.insights,
                          color: AppColors.gold,
                          size: AppIconSize.md,
                        ),
                        SizedBox(height: AppSpacing.xxs),
                        Text(
                          'DETAILS',
                          style: AppTypography.labelMicro.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
            ],
          ),
          // Cohesion warning banner
          if (hasResult &&
              result.hasCohesionIssue &&
              result.cohesionWarning != null) ...[
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  AppIcon(
                    icon: AppPhosphorIcons.info,
                    color: AppColors.pure,
                    size: AppIconSize.button,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      result.cohesionWarning!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildVibeRing(int score, bool hasResult) {
    const ringSize = 72.0;
    const strokeWidth = 6.0;

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          CustomPaint(
            size: const Size(ringSize, ringSize),
            painter: _VibeRingPainter(
              progress: 1.0,
              color: AppColors.navyLight.withValues(alpha: 0.3),
              strokeWidth: strokeWidth,
            ),
          ),
          // Progress ring
          if (hasResult)
            CustomPaint(
              size: const Size(ringSize, ringSize),
              painter: _VibeRingPainter(
                progress: score / 100,
                color: _getScoreColor(score),
                strokeWidth: strokeWidth,
              ),
            ),
          // Brain icon in center
          Container(
            width: ringSize - strokeWidth * 2 - 8,
            height: ringSize - strokeWidth * 2 - 8,
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: hasResult
                  ? AppIcon(
                      icon: AppPhosphorIcons.brain,
                      color: AppColors.textSecondary,
                      size: AppIconSize.md,
                    )
                  : SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textMuted,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.green;
    if (score >= 40) return AppColors.textPrimary;
    return AppColors.textSecondary;
  }
}

class _VibeRingPainter extends CustomPainter {
  _VibeRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw arc starting from top (-90 degrees)
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _VibeRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
