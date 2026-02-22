import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/typography.dart';
import '/utils/app_util.dart';

/// Premium date picker with quick date chips and calendar bottom sheet
class PremiumDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const PremiumDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  DateTime get _today => DateTime.now();
  DateTime get _tomorrow => DateTime.now().add(const Duration(days: 1));

  DateTime get _thisWeekend {
    final now = DateTime.now();
    // Find next Saturday
    int daysUntilSaturday = DateTime.saturday - now.weekday;
    if (daysUntilSaturday <= 0) {
      daysUntilSaturday += 7; // Next week's Saturday
    }
    return now.add(Duration(days: daysUntilSaturday));
  }

  void _showCalendarBottomSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.navyDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppBorderRadius.xxl)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
                  ),
                ),
                SizedBox(height: AppSpacing.md),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pick a Date',
                      style: AppTypography.headlineMediumSans.copyWith(
                        fontSize: 22,
                        color: AppColors.pure,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.pure, size: AppIconSize.md),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),

                // Calendar
                Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: AppColors.navyDark,
                      onPrimary: AppColors.pure,
                      surface: AppColors.navyDark,
                      onSurface: AppColors.pure,
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: selectedDate ?? _today,
                    firstDate: _today,
                    lastDate: DateTime(2050),
                    onDateChanged: (date) {
                      HapticFeedback.selectionClick();
                      // Preserve time if already set, otherwise use current time
                      final newDate = selectedDate != null
                          ? DateTime(
                              date.year,
                              date.month,
                              date.day,
                              selectedDate!.hour,
                              selectedDate!.minute,
                            )
                          : DateTime(
                              date.year,
                              date.month,
                              date.day,
                              _today.hour,
                              _today.minute,
                            );
                      onDateSelected(newDate);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip({
    required BuildContext context,
    required String label,
    required DateTime date,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          // Preserve time if already set, otherwise use current time
          final newDate = selectedDate != null
              ? DateTime(
                  date.year,
                  date.month,
                  date.day,
                  selectedDate!.hour,
                  selectedDate!.minute,
                )
              : DateTime(
                  date.year,
                  date.month,
                  date.day,
                  _today.hour,
                  _today.minute,
                );
          onDateSelected(newDate);
        },
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.navyDark
                : AppColors.navy,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(
              color: isSelected
                  ? AppColors.navyDark
                  : AppColors.greenLight.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.pure,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                dateTimeFormat("MMM d", date),
                style: AppTypography.caption.copyWith(
                  color: isSelected
                      ? AppColors.pure.withValues(alpha: 0.8)
                      : AppColors.pure,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick date chips
        Row(
          children: [
            _buildDateChip(
              context: context,
              label: 'Today',
              date: _today,
              isSelected: _isSameDay(selectedDate, _today),
            ),
            SizedBox(width: AppSpacing.xs),
            _buildDateChip(
              context: context,
              label: 'Tomorrow',
              date: _tomorrow,
              isSelected: _isSameDay(selectedDate, _tomorrow),
            ),
            SizedBox(width: AppSpacing.xs),
            _buildDateChip(
              context: context,
              label: 'Weekend',
              date: _thisWeekend,
              isSelected: _isSameDay(selectedDate, _thisWeekend),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs),

        // Pick a date button
        InkWell(
          onTap: () => _showCalendarBottomSheet(context),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: AppColors.greenLight.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.navyDark,
                  size: AppIconSize.button,
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  'Pick a Date',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.pure,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
