import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';

/// Section header for grouped friend lists
class FriendSectionHeader extends StatefulWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color color;
  final bool isCollapsed;
  final VoidCallback? onTap;

  const FriendSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.count,
    this.color = AppColors.fairway,
    this.isCollapsed = false,
    this.onTap,
  });

  @override
  State<FriendSectionHeader> createState() => _FriendSectionHeaderState();
}

class _FriendSectionHeaderState extends State<FriendSectionHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: MotionTokens.curveEnter),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      HapticFeedback.lightImpact();
      widget.onTap!();
    }
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          margin: EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.color.withOpacity(_isPressed ? 0.2 : 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon with gradient background
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color.withOpacity(0.2),
                      widget.color.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.15),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: widget.color,
                ),
              ),

              SizedBox(width: AppSpacing.md),

              // Title and count
              Expanded(
                child: Row(
                  children: [
                    Text(
                      widget.title.toUpperCase(),
                      style: AppTypography.labelMedium.copyWith(
                        color: widget.color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.color.withOpacity(0.25),
                            widget.color.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.count}',
                        style: AppTypography.labelSmall.copyWith(
                          color: widget.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Collapse indicator with rotation animation
              if (widget.onTap != null)
                AnimatedRotation(
                  turns: widget.isCollapsed ? 0 : 0.5,
                  duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
                  curve: MotionTokens.curveEnter,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: widget.color,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
