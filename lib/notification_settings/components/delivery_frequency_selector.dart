import 'package:flutter/material.dart';
import '/models/notification_preferences.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';

/// Reusable pill selector for notification delivery frequency.
///
/// Displays three equal-width pills (Instant, Hourly, Daily) with
/// animated selection state and press feedback.
class DeliveryFrequencySelector extends StatelessWidget {
  const DeliveryFrequencySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// Currently selected frequency
  final DeliveryFrequency selected;

  /// Callback when selection changes
  final ValueChanged<DeliveryFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: DeliveryFrequency.values.map((frequency) {
        final isSelected = frequency == selected;
        final isFirst = frequency == DeliveryFrequency.values.first;
        final isLast = frequency == DeliveryFrequency.values.last;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: isFirst ? 0 : 3,
              right: isLast ? 0 : 3,
            ),
            child: _FrequencyPill(
              label: _getLabel(frequency),
              isSelected: isSelected,
              onTap: () => onChanged(frequency),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getLabel(DeliveryFrequency frequency) {
    switch (frequency) {
      case DeliveryFrequency.instant:
        return 'Instant';
      case DeliveryFrequency.hourly:
        return 'Hourly';
      case DeliveryFrequency.daily:
        return 'Daily';
    }
  }
}

/// Individual pill with press animation and selection state.
class _FrequencyPill extends StatefulWidget {
  const _FrequencyPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_FrequencyPill> createState() => _FrequencyPillState();
}

class _FrequencyPillState extends State<_FrequencyPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.green.withValues(alpha: 0.10)
                : AppColors.navyDark,
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.green.withValues(alpha: 0.20)
                  : AppColors.navyLight,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AppTypography.labelSmall.copyWith(
                color: widget.isSelected
                    ? AppColors.greenLight
                    : AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
