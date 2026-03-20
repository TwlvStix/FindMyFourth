import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import 'package:flutter/material.dart';

InputDecoration authInputDecoration({
  required String labelText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: labelText,
    labelStyle: AppTypography.labelMedium.copyWith(
      color: AppColors.textSecondary,
    ),
    alignLabelWithHint: false,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: AppColors.inputBorderIdle,
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: AppColors.inputBorderFocused,
        width: 2.0,
      ),
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: AppColors.error,
        width: 2.0,
      ),
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: AppColors.error,
        width: 2.0,
      ),
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
    ),
    filled: true,
    fillColor: AppColors.inputBackground,
    suffixIcon: suffixIcon,
  );
}
