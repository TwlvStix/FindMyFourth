import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

/// Badge showing spots left with urgency animation.
///
/// Displays "{n} spot(s) left" with a pulsing dot indicator when
/// only 1 spot remains (urgent state).
class GameCardSpotsBadge extends StatelessWidget {
  const GameCardSpotsBadge({
    super.key,
    required this.spotsLeft,
  });

  /// Number of spots remaining in the game
  final int spotsLeft;

  @override
  Widget build(BuildContext context) {
    if (spotsLeft <= 0) {
      return _buildFullBadge();
    }

    final isUrgent = spotsLeft == 1;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: isUrgent
            ? AppColors.warning.withValues(alpha: 0.15)
            : AppColors.glassSurface,
        borderRadius: BorderRadius.circular(AppBorderRadius.chip),
        border: Border.all(
          color: isUrgent
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.glassBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing dot (only for urgent state)
          if (isUrgent)
            Padding(
              padding: EdgeInsets.only(right: 4),
              child: _PulsingDot(),
            ),
          // Spot count
          if (!isUrgent)
            Padding(
              padding: EdgeInsets.only(right: 4),
              child: _StaticDot(color: AppColors.green),
            ),
          Text(
            '$spotsLeft spot${spotsLeft == 1 ? '' : 's'} left',
            style: AppTypography.labelSmall.copyWith(
              color: isUrgent ? AppColors.warning : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.02,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppBorderRadius.chip),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        'Full',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StaticDot extends StatelessWidget {
  const _StaticDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.warning.withValues(alpha: _animation.value * 0.6),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
