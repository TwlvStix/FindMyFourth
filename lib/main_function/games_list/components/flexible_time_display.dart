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
        // Week label
        if (showWeekLabel && weekLabel != null) ...[
          Text(
            weekLabel,
            style: compact
                ? AppTypography.labelSmall.copyWith(
                    color: AppColors.green,
                    fontWeight: FontWeight.w600,
                  )
                : AppTypography.bodySmall.copyWith(
                    color: AppColors.green,
                    fontWeight: FontWeight.w600,
                  ),
          ),
          if (dayLabels.isNotEmpty || timeOfDayLabel != null)
            SizedBox(height: compact ? AppSpacing.xxs : AppSpacing.xs),
        ],
        // Day pills
        if (dayLabels.isNotEmpty)
          Wrap(
            spacing: AppSpacing.xxs,
            runSpacing: AppSpacing.xxs,
            children: dayLabels.map((day) => _buildDayPill(day, compact)).toList(),
          ),
        // Time of day
        if (timeOfDayLabel != null) ...[
          if (dayLabels.isNotEmpty)
            SizedBox(height: compact ? AppSpacing.xxs : AppSpacing.xs),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
              vertical: compact ? 2 : AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: AppColors.navy.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  icon: _getTimeOfDayIcon(game.flexibleTimeOfDay),
                  color: Colors.white.withValues(alpha: 0.9),
                  size: AppIconSize.xs,
                ),
                SizedBox(width: 4),
                Text(
                  timeOfDayLabel,
                  style: (compact
                          ? AppTypography.labelMicro
                          : AppTypography.labelSmall)
                      .copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
    if (week == null) return null;
    switch (week) {
      case 'this_week':
        return 'This Week';
      case 'next_week':
        return 'Next Week';
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
    if (timeOfDay == null) return null;
    switch (timeOfDay) {
      case 'morning':
        return 'Morning';
      case 'afternoon':
        return 'Afternoon';
      case 'twilight':
        return 'Twilight';
      default:
        return null;
    }
  }

  PhosphorIconData _getTimeOfDayIcon(String? timeOfDay) {
    switch (timeOfDay) {
      case 'morning':
        return AppPhosphorIcons.morning;
      case 'afternoon':
        return AppPhosphorIcons.afternoon;
      case 'twilight':
        return AppPhosphorIcons.twilight;
      default:
        return AppPhosphorIcons.afternoon;
    }
  }
}
