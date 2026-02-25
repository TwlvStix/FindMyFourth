import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/models/game.dart';
import '/utils/flexible_date_formatter.dart';

/// Displays flexible time information with week range and selected day pills
class FlexibleTimeDisplay extends StatelessWidget {
  const FlexibleTimeDisplay({
    super.key,
    required this.game,
    this.showWeekLabel = true,
    this.compact = false,
  });

  final Game game;
  final bool showWeekLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!game.isFlexible) {
      return const SizedBox.shrink();
    }

    final weekLabel = _getWeekLabel(game.flexibleWeek);
    final dayLabels = _getDayLabels(game.flexibleDays);
    final timeOfDayLabel = _getTimeOfDayLabel(game.flexibleTimeOfDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: Week label + Day pills (inline for compact height)
        if ((showWeekLabel && weekLabel != null) || dayLabels.isNotEmpty)
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (showWeekLabel && weekLabel != null)
                Text(
                  weekLabel,
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ...dayLabels.map((day) => _buildDayPill(day, compact)),
            ],
          ),
        // Row 2: Time of day (simple icon + text like regular time display)
        if (timeOfDayLabel != null) ...[
          SizedBox(height: compact ? AppSpacing.xxs : AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                icon: _getTimeOfDayIcon(game.flexibleTimeOfDay),
                color: Colors.white.withValues(alpha: 0.6),
                size: AppIconSize.xs,
              ),
              SizedBox(width: 4),
              Text(
                timeOfDayLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDayPill(String day, bool compact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
        vertical: compact ? 2 : AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.green, AppColors.greenLight],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: [AppElevation.xs],
      ),
      child: Text(
        day,
        style: (compact ? AppTypography.labelMicro : AppTypography.labelSmall)
            .copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String? _getWeekLabel(String? week) {
    // Prefer concrete dates when available
    if (game.flexibleStartDate != null && game.flexibleEndDate != null) {
      return FlexibleDateFormatter.formatWithHint(
        game.flexibleStartDate,
        game.flexibleEndDate,
      );
    }

    // Fallback for legacy games without concrete dates
    if (week == null) return null;
    switch (week) {
      case 'this_week':
        return 'This Week';
      case 'this_weekend':
        return 'This Weekend';
      case 'next_week':
        return 'Next Week';
      case 'next_2_weeks':
        return 'Next 2 Weeks';
      case 'flexible':
        return 'Flexible';
      default:
        return null;
    }
  }

  List<String> _getDayLabels(List<int>? days) {
    if (days == null || days.isEmpty) return [];
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final sorted = days.toList()..sort();
    return sorted.map((d) => dayNames[d]).toList();
  }

  String? _getTimeOfDayLabel(String? timeOfDay) {
    if (timeOfDay == null || timeOfDay.isEmpty) return null;

    // Handle comma-separated multi-select values
    final times = timeOfDay.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

    if (times.isEmpty) return null;

    // Single 'anytime' returns Anytime
    if (times.length == 1 && times.first == 'anytime') {
      return 'Anytime';
    }

    // Filter out 'anytime' if present with other values
    final specificTimes = times.where((t) => t != 'anytime').toList();
    if (specificTimes.isEmpty) return 'Anytime';

    // Map each time to its label in order
    final labels = <String>[];
    if (specificTimes.contains('morning')) labels.add('Morning');
    if (specificTimes.contains('afternoon')) labels.add('Afternoon');
    if (specificTimes.contains('twilight')) labels.add('Twilight');

    return labels.isEmpty ? null : labels.join(', ');
  }

  PhosphorIconData _getTimeOfDayIcon(String? timeOfDay) {
    if (timeOfDay == null || timeOfDay.isEmpty) {
      return AppPhosphorIcons.afternoon; // default
    }

    // Handle comma-separated: use first specific time's icon (morning priority)
    final times = timeOfDay.split(',').map((t) => t.trim()).toSet();

    // Priority order: morning > afternoon > twilight
    if (times.contains('morning')) return AppPhosphorIcons.morning;
    if (times.contains('afternoon')) return AppPhosphorIcons.afternoon;
    if (times.contains('twilight')) return AppPhosphorIcons.twilight;

    return AppPhosphorIcons.afternoon; // default for 'anytime' or unknown
  }
}
