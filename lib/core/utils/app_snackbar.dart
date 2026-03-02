import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';

/// Centralized snackbar display utility using design tokens.
class AppSnackbar {
  AppSnackbar._();

  static const Duration _defaultDuration = Duration(milliseconds: 2000);
  static const Duration _successDuration = Duration(milliseconds: 3000);

  /// Shows an error snackbar with red background.
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.error,
      duration: _defaultDuration,
    );
  }

  /// Shows a success snackbar with green background.
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.success,
      duration: _successDuration,
    );
  }

  /// Shows an info snackbar with navy background.
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.navyDark,
      textColor: AppColors.textPrimary,
      duration: _defaultDuration,
    );
  }

  /// Shows a warning snackbar with warning color background.
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.warning,
      textColor: AppColors.navy,
      duration: _defaultDuration,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    Color textColor = AppColors.textPrimary,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodySmall.copyWith(color: textColor),
        ),
        duration: duration,
        backgroundColor: backgroundColor,
      ),
    );
  }
}
