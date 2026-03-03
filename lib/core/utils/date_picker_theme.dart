import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';

/// Provides a consistent dark theme for date pickers across the app.
class AppDatePickerTheme {
  AppDatePickerTheme._();

  /// Returns a ThemeData configured for our dark date picker style.
  ///
  /// Wrap the child of showDatePicker's builder with this theme.
  static ThemeData build(BuildContext context) {
    return Theme.of(context).copyWith(
      colorScheme: ColorScheme.dark(
        primary: AppColors.green,
        onPrimary: AppColors.textPrimary,
        surface: AppColors.navy,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textPrimary,
        secondary: AppColors.green,
        onSecondary: AppColors.textPrimary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.navy,
      ),
      textTheme: Theme.of(context).textTheme.apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: AppColors.textPrimary),
        hintStyle: TextStyle(color: AppColors.textMuted),
        floatingLabelStyle: TextStyle(color: AppColors.green),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textMuted),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.green),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.navy,
        headerBackgroundColor: AppColors.navy,
        headerForegroundColor: AppColors.textPrimary,
        yearStyle: TextStyle(color: AppColors.textPrimary),
        yearForegroundColor: WidgetStateProperty.all(AppColors.textPrimary),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.green;
          }
          return AppColors.transparent;
        }),
        dayForegroundColor: WidgetStateProperty.all(AppColors.textPrimary),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.green;
          }
          return AppColors.transparent;
        }),
      ),
    );
  }
}
