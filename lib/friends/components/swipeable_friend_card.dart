import 'package:flutter/material.dart';
import '/core/utils/state_update.dart';
import 'package:flutter/services.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/typography.dart';

/// Swipeable wrapper for friend cards with quick actions
/// Swipe right: Primary action (Accept/Message)
/// Swipe left: Secondary action (Deny/Remove)
class SwipeableFriendCard extends StatefulWidget {
  final Widget child;
  final String friendId;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeLeft;
  final String? swipeRightLabel;
  final String? swipeLeftLabel;
  final IconData? swipeRightIcon;
  final IconData? swipeLeftIcon;
  final Color swipeRightColor;
  final Color swipeLeftColor;

  const SwipeableFriendCard({
    super.key,
    required this.child,
    required this.friendId,
    this.onSwipeRight,
    this.onSwipeLeft,
    this.swipeRightLabel,
    this.swipeLeftLabel,
    this.swipeRightIcon,
    this.swipeLeftIcon,
    this.swipeRightColor = AppColors.navy,
    this.swipeLeftColor = AppColors.stone,
  });

  @override
  State<SwipeableFriendCard> createState() => _SwipeableFriendCardState();
}

class _SwipeableFriendCardState extends State<SwipeableFriendCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;
  bool _dragUnderway = false;

  static const double _kSwipeThreshold = 0.4;
  static const double _kMaxSwipeDistance = 100.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _dragUnderway = true;
    if (mounted) {
      updateState(this, () {});
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragUnderway) return;

    final delta = details.primaryDelta ?? 0;
    final oldDragExtent = _dragExtent;
    _dragExtent += delta;

    // Limit drag distance
    if (_dragExtent.abs() > _kMaxSwipeDistance) {
      _dragExtent = _dragExtent.sign * _kMaxSwipeDistance;
    }

    if (oldDragExtent.sign != _dragExtent.sign) {
      if (mounted) {
        updateState(this, () {});
      }
    }

    if (_dragExtent != oldDragExtent && mounted) {
      updateState(this, () {});
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragUnderway) return;
    _dragUnderway = false;

    final velocity = details.primaryVelocity ?? 0;
    final shouldTrigger = _dragExtent.abs() / _kMaxSwipeDistance > _kSwipeThreshold ||
        velocity.abs() > 300;

    if (shouldTrigger) {
      // Trigger swipe action
      if (_dragExtent > 0 && widget.onSwipeRight != null) {
        HapticFeedback.mediumImpact();
        widget.onSwipeRight!();
      } else if (_dragExtent < 0 && widget.onSwipeLeft != null) {
        HapticFeedback.mediumImpact();
        widget.onSwipeLeft!();
      }
    }

    // Reset
    _dragExtent = 0;
    if (mounted) {
      updateState(this, () {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final swipeProgress = (_dragExtent / _kMaxSwipeDistance).clamp(-1.0, 1.0);

    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        children: [
          // Background actions
          if (_dragExtent != 0) _buildBackground(swipeProgress),

          // Card content
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(double progress) {
    final isSwipingRight = progress > 0;
    final color = isSwipingRight ? widget.swipeRightColor : widget.swipeLeftColor;
    final icon = isSwipingRight ? widget.swipeRightIcon : widget.swipeLeftIcon;
    final label = isSwipingRight ? widget.swipeRightLabel : widget.swipeLeftLabel;
    final opacity = progress.abs().clamp(0.0, 1.0);

    return Positioned.fill(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha:opacity * 0.15),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: color.withValues(alpha:opacity * 0.3),
            width: 1.5,
          ),
        ),
        child: Align(
          alignment: isSwipingRight ? Alignment.centerLeft : Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Icon(
                    icon,
                    color: color.withValues(alpha:opacity),
                    size: AppIconSize.md,
                  ),
                if (icon != null && label != null) SizedBox(width: AppSpacing.xs),
                if (label != null)
                  Text(
                    label,
                    style: AppTypography.bodySmall.copyWith(
                      color: color.withValues(alpha:opacity),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
