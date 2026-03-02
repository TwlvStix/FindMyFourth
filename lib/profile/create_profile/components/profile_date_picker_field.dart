import 'package:flutter/material.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/utils/date_picker_theme.dart';

/// A styled date picker field for profile forms.
///
/// Displays the selected date or a placeholder, and opens a themed
/// date picker dialog when tapped.
class ProfileDatePickerField extends StatelessWidget {
  const ProfileDatePickerField({
    super.key,
    required this.dateOfBirth,
    required this.onDateSelected,
    this.label = 'Birthday *',
  });

  /// The currently selected date, or null if none selected.
  final DateTime? dateOfBirth;

  /// Callback when a date is selected.
  final ValueChanged<DateTime> onDateSelected;

  /// The placeholder label shown when no date is selected.
  final String label;

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: 'SELECT DATE OF BIRTH',
      builder: (context, child) {
        return Theme(
          data: AppDatePickerTheme.build(context),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDatePicker(context),
      child: Container(
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: AppColors.inputBorderIdle),
        ),
        child: Row(
          children: [
            Icon(
              AppPhosphorIcons.calendar,
              color: AppColors.textMuted,
              size: AppIconSize.md,
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                dateOfBirth != null ? _formatDate(dateOfBirth!) : label,
                style: AppTypography.bodyMedium.copyWith(
                  color: dateOfBirth != null
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
