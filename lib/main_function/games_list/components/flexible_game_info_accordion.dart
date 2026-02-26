import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/models/game.dart';
import '/utils/availability_text_helper.dart';
import '/utils/flexible_date_formatter.dart';

/// Accordion widget for displaying flexible game scheduling information.
///
/// Collapsed state (optimized for scanning): single line with week hint, time, and spots.
/// Example: "Next Week · Afternoon · 3 spots open"
///
/// Expanded state (full details): 4-column grid with DATES, DAYS, TIME, and GROUP.
/// This reveals specifics intentionally withheld from the collapsed view.
class FlexibleGameInfoAccordion extends StatefulWidget {
  const FlexibleGameInfoAccordion({
    super.key,
    required this.game,
  });

  final Game game;

  @override
  State<FlexibleGameInfoAccordion> createState() =>
      _FlexibleGameInfoAccordionState();
}

class _FlexibleGameInfoAccordionState extends State<FlexibleGameInfoAccordion> {
  bool _isExpanded = false;

  // Collapsed state getters (context only)
  String get _weekHintOnly => getWeekHintOnly(widget.game);

  String get _timeSummary =>
      formatTimeOfDay(widget.game.flexibleTimeOfDay, joiner: ' & ') ??
      'Anytime';

  int get _spotsLeft =>
      widget.game.maxPlayers -
      (widget.game.joinedPlayers.length + widget.game.guestPlayers.length);

  String get _spotsLabel => _spotsLeft <= 0 ? 'Full' : '$_spotsLeft spots open';

  // Expanded state getters (full details)
  String get _dateRangeValue {
    if (widget.game.flexibleStartDate != null &&
        widget.game.flexibleEndDate != null) {
      return FlexibleDateFormatter.formatDateRange(
        widget.game.flexibleStartDate!,
        widget.game.flexibleEndDate!,
      );
    }
    return '—';
  }

  /// Returns expanded day list (individual days, not collapsed)
  String get _daysDetailValue {
    final days = widget.game.flexibleDays;
    if (days == null || days.isEmpty) return 'Any Day';
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final sorted = days.toList()..sort();
    return sorted.map((d) => dayNames[d]).join(', ');
  }

  String get _timeDetailValue =>
      formatTimeOfDay(widget.game.flexibleTimeOfDay) ?? 'Anytime';

  int get _playersJoined =>
      widget.game.joinedPlayers.length + widget.game.guestPlayers.length;

  String get _groupValue => '$_playersJoined of ${widget.game.maxPlayers}';

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.game.isFlexible) {
      return const SizedBox.shrink();
    }

    return Semantics(
      button: true,
      expanded: _isExpanded,
      label:
          'Flexible scheduling: $_weekHintOnly, $_timeSummary, $_spotsLabel',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.navy.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: GestureDetector(
          onTap: _toggleExpanded,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCollapsedContent(),
                _buildExpandedContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent() {
    return Row(
      children: [
        AppIcon(
          icon: AppPhosphorIcons.calendarCheck,
          color: AppColors.textSecondary,
          size: AppIconSize.listItem,
        ),
        SizedBox(width: AppSpacing.sm),
        // Single line summary: Week · Time · Spots
        Expanded(
          child: Text(
            '$_weekHintOnly · $_timeSummary · $_spotsLabel',
            style: AppTypography.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.xs),
        // Animated chevron
        AnimatedRotation(
          duration: ReducedMotionService.adjust(MotionTokens.routeEnter),
          curve: MotionTokens.curveEnter,
          turns: _isExpanded ? 0.5 : 0.0,
          child: AppIcon(
            icon: AppPhosphorIcons.chevronDown,
            size: AppIconSize.sm,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return AnimatedSize(
      duration: ReducedMotionService.adjust(MotionTokens.routeEnter),
      curve: MotionTokens.curveEnter,
      child: _isExpanded
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: AppSpacing.sm),
                Divider(
                  color: AppColors.navyLight.withValues(alpha: 0.3),
                  height: 1,
                  thickness: 1,
                ),
                SizedBox(height: AppSpacing.sm),
                _buildDetailGrid(),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildDetailGrid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailColumn('DATES', _dateRangeValue),
        _buildDetailColumn('DAYS', _daysDetailValue),
        _buildDetailColumn('TIME', _timeDetailValue),
        _buildDetailColumn('GROUP', '$_groupValue\njoined'),
      ],
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelMicro.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
