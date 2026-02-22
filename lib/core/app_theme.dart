import 'package:flutter/material.dart';
import 'design_tokens/colors.dart';

/// ThemeExtension for Flutter's theme system.
///
/// This class maps design tokens to Flutter's ThemeData via the extensions API.
/// Used only in main.dart to register colors with MaterialApp's theme.
///
/// For direct color usage in widgets, import and use AppColors directly:
/// ```dart
/// import '/core/design_tokens/colors.dart';
/// Container(color: AppColors.navyDark)
/// ```
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.alternate,
    required this.primaryText,
    required this.secondaryText,
    required this.primaryBackground,
    required this.secondaryBackground,
    required this.accent1,
    required this.accent2,
    required this.accent3,
    required this.accent4,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.primaryBtnText,
    required this.lineColor,
    required this.noColor,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color alternate;
  final Color primaryText;
  final Color secondaryText;
  final Color primaryBackground;
  final Color secondaryBackground;
  final Color accent1;
  final Color accent2;
  final Color accent3;
  final Color accent4;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color primaryBtnText;
  final Color lineColor;
  final Color noColor;

  static const light = AppThemeColors(
    primary: AppColors.navyDark,
    secondary: AppColors.navy,
    tertiary: AppColors.stone,
    alternate: AppColors.cloud,
    primaryText: AppColors.onyx,
    secondaryText: AppColors.slate,
    primaryBackground: AppColors.sand,
    secondaryBackground: AppColors.pure,
    accent1: AppColors.gold,
    accent2: AppColors.goldLight,
    accent3: AppColors.error,
    accent4: AppColors.greenLight,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    primaryBtnText: AppColors.pure,
    lineColor: AppColors.cloud,
    noColor: Color(0x00FFFFFF),
  );

  static const dark = AppThemeColors(
    primary: AppColorsDark.greenLight,
    secondary: AppColorsDark.navy,
    tertiary: AppColorsDark.stone,
    alternate: AppColorsDark.cloud,
    primaryText: AppColorsDark.onyx,
    secondaryText: AppColorsDark.slate,
    primaryBackground: AppColorsDark.sand,
    secondaryBackground: AppColorsDark.pure,
    accent1: AppColorsDark.gold,
    accent2: AppColorsDark.goldLight,
    accent3: AppColorsDark.error,
    accent4: AppColorsDark.greenLight,
    success: AppColorsDark.success,
    warning: AppColorsDark.warning,
    error: AppColorsDark.error,
    info: AppColorsDark.info,
    primaryBtnText: AppColorsDark.pure,
    lineColor: AppColorsDark.cloud,
    noColor: Color(0x00FFFFFF),
  );

  @override
  AppThemeColors copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? alternate,
    Color? primaryText,
    Color? secondaryText,
    Color? primaryBackground,
    Color? secondaryBackground,
    Color? accent1,
    Color? accent2,
    Color? accent3,
    Color? accent4,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? primaryBtnText,
    Color? lineColor,
    Color? noColor,
  }) {
    return AppThemeColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      alternate: alternate ?? this.alternate,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      primaryBackground: primaryBackground ?? this.primaryBackground,
      secondaryBackground: secondaryBackground ?? this.secondaryBackground,
      accent1: accent1 ?? this.accent1,
      accent2: accent2 ?? this.accent2,
      accent3: accent3 ?? this.accent3,
      accent4: accent4 ?? this.accent4,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      primaryBtnText: primaryBtnText ?? this.primaryBtnText,
      lineColor: lineColor ?? this.lineColor,
      noColor: noColor ?? this.noColor,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }
    return AppThemeColors(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      alternate: Color.lerp(alternate, other.alternate, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      primaryBackground:
          Color.lerp(primaryBackground, other.primaryBackground, t)!,
      secondaryBackground:
          Color.lerp(secondaryBackground, other.secondaryBackground, t)!,
      accent1: Color.lerp(accent1, other.accent1, t)!,
      accent2: Color.lerp(accent2, other.accent2, t)!,
      accent3: Color.lerp(accent3, other.accent3, t)!,
      accent4: Color.lerp(accent4, other.accent4, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      primaryBtnText: Color.lerp(primaryBtnText, other.primaryBtnText, t)!,
      lineColor: Color.lerp(lineColor, other.lineColor, t)!,
      noColor: Color.lerp(noColor, other.noColor, t)!,
    );
  }
}
