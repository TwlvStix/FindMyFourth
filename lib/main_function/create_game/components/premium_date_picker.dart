import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';
import '/utils/app_util.dart';

/// Premium date picker with calendar bottom sheet
/// Defaults to tomorrow since most tee times are booked at least a day ahead
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

  void _showCalendarBottomSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
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
                        color: AppColors.pure,
                      ),
                    ),
                    IconButton(
                      icon: AppIcon(icon: AppPhosphorIcons.close, color: AppColors.pure, size: AppIconSize.md),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),

                // Calendar - defaults to tomorrow
                Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: AppColors.green,
                      onPrimary: AppColors.pure,
                      surface: AppColors.navyDark,
                      onSurface: AppColors.pure,
                      onSurfaceVariant: AppColors.pure,
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: selectedDate != null && !selectedDate!.isBefore(_today)
                        ? selectedDate!
                        : _tomorrow,
                    firstDate: _today,
                    lastDate: DateTime(2050),
                    onDateChanged: (date) {
                      HapticFeedback.selectionClick();
                      // Preserve time if already set, otherwise default to 9 AM
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
                              9, // Default to 9 AM
                              0,
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

  @override
  Widget build(BuildContext context) {
    final hasDate = selectedDate != null;

    return InkWell(
      onTap: () => _showCalendarBottomSheet(context),
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: hasDate
                ? AppColors.green.withValues(alpha: 0.5)
                : AppColors.greenLight.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            AppIcon(
              icon: AppPhosphorIcons.calendar,
              color: AppColors.pure,
              size: AppIconSize.button,
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                hasDate
                    ? dateTimeFormat("EEEE, MMM d", selectedDate)
                    : 'Pick a Date',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.pure,
                  fontWeight: hasDate ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (hasDate)
              AppIcon(
                icon: AppPhosphorIcons.edit,
                color: AppColors.textSecondary,
                size: AppIconSize.sm,
              ),
          ],
        ),
      ),
    );
  }
}
