import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/motion/motion_tokens.dart';
import '/providers/provider_extensions.dart';
import '/notification_settings/components/expand_section_label.dart';

/// Expanded content for the Quiet Hours notification category card.
///
/// Shows:
/// - Time range picker (FROM / UNTIL boxes)
/// - Active days selector (M T W T F S S pills)
class QuietHoursContent extends StatelessWidget {
  const QuietHoursContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watchNotificationProvider;
    final prefs = provider.preferences;
    final quietHours = prefs.quietHours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Time range picker
        _TimeRangePicker(
          startTime: quietHours.start,
          endTime: quietHours.end,
          onStartChanged: (time) {
            context.notificationProvider.updateQuietHours(start: time);
          },
          onEndChanged: (time) {
            context.notificationProvider.updateQuietHours(end: time);
          },
        ),

        // Active days section
        const ExpandSectionLabel(text: 'ACTIVE DAYS', showDivider: true),
        _ActiveDaysSelector(
          activeDays: quietHours.activeDays,
          onChanged: (days) {
            context.notificationProvider.updateQuietHours(activeDays: days);
          },
        ),
      ],
    );
  }
}

/// Time range picker with FROM and UNTIL boxes.
class _TimeRangePicker extends StatelessWidget {
  const _TimeRangePicker({
    required this.startTime,
    required this.endTime,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final String startTime;
  final String endTime;
  final ValueChanged<String> onStartChanged;
  final ValueChanged<String> onEndChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TimeBox(
            label: 'FROM',
            time: startTime,
            onTap: () => _showTimePicker(context, startTime, onStartChanged),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            '→',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: _TimeBox(
            label: 'UNTIL',
            time: endTime,
            onTap: () => _showTimePicker(context, endTime, onEndChanged),
          ),
        ),
      ],
    );
  }

  Future<void> _showTimePicker(
    BuildContext context,
    String currentTime,
    ValueChanged<String> onChanged,
  ) async {
    final tod = _parseTime(currentTime);

    final result = await showTimePicker(
      context: context,
      initialTime: tod,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.navy,
              hourMinuteColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.green.withValues(alpha: 0.2);
                }
                return AppColors.navyDark;
              }),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.green;
                }
                return AppColors.textPrimary;
              }),
              dialHandColor: AppColors.green,
              dialBackgroundColor: AppColors.navyDark,
              dialTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.textPrimary;
                }
                return AppColors.textSecondary;
              }),
              entryModeIconColor: AppColors.textSecondary,
              confirmButtonStyle: TextButton.styleFrom(
                foregroundColor: AppColors.green,
              ),
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              dayPeriodColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.green.withValues(alpha: 0.2);
                }
                return AppColors.navyDark;
              }),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.green;
                }
                return AppColors.textSecondary;
              }),
              dayPeriodBorderSide: BorderSide(
                color: AppColors.navyLight,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.navyDark,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  borderSide: BorderSide(color: AppColors.navyLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  borderSide: BorderSide(color: AppColors.navyLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  borderSide: BorderSide(color: AppColors.green),
                ),
              ),
            ),
            colorScheme: ColorScheme.dark(
              primary: AppColors.green,
              onPrimary: AppColors.textPrimary,
              surface: AppColors.navy,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      final formatted = _formatTimeToHHMM(result);
      onChanged(formatted);
    }
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 22, minute: 0);

    final hour = int.tryParse(parts[0]) ?? 22;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeToHHMM(TimeOfDay tod) {
    return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
  }
}

/// Individual time box with label and value.
class _TimeBox extends StatelessWidget {
  const _TimeBox({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.navyDark,
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          border: Border.all(
            color: AppColors.navyLight.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTypography.labelMicro.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              _formatTimeForDisplay(time),
              style: AppTypography.monoMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeForDisplay(String time24) {
    final parts = time24.split(':');
    if (parts.length != 2) return time24;

    int hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';

    if (hour > 12) {
      hour -= 12;
    } else if (hour == 0) {
      hour = 12;
    }

    return '$hour:$minute $period';
  }
}

/// Active days selector with 7 day pills.
class _ActiveDaysSelector extends StatelessWidget {
  const _ActiveDaysSelector({
    required this.activeDays,
    required this.onChanged,
  });

  final List<int> activeDays;
  final ValueChanged<List<int>> onChanged;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayNumber = index + 1; // 1=Monday, 7=Sunday
        final isActive = activeDays.contains(dayNumber);

        return _DayPill(
          label: _dayLabels[index],
          isActive: isActive,
          onTap: () {
            final newDays = List<int>.from(activeDays);
            if (isActive) {
              newDays.remove(dayNumber);
            } else {
              newDays.add(dayNumber);
              newDays.sort();
            }
            onChanged(newDays);
          },
        );
      }),
    );
  }
}

/// Individual day pill button.
class _DayPill extends StatefulWidget {
  const _DayPill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_DayPill> createState() => _DayPillState();
}

class _DayPillState extends State<_DayPill> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: MotionTokens.microInteraction,
        curve: MotionTokens.curveEnter,
        child: AnimatedContainer(
          duration: MotionTokens.microInteraction,
          curve: MotionTokens.curveEnter,
          width: 38,
          height: 32,
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.green.withValues(alpha: 0.1)
                : AppColors.navyDark,
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            border: Border.all(
              color: widget.isActive
                  ? AppColors.green.withValues(alpha: 0.2)
                  : AppColors.navyLight.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AppTypography.labelMicro.copyWith(
                fontWeight: FontWeight.w700,
                color: widget.isActive
                    ? AppColors.greenLight
                    : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
