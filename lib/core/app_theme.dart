import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    primary: Color(0xFF253551),
    secondary: Color(0xFF265240),
    tertiary: Color(0xFFA9A9A9),
    alternate: Color(0xFFE0E0DB),
    primaryText: Color(0xFF14181B),
    secondaryText: Color(0xFF57636C),
    primaryBackground: Color(0xFFF1F4F8),
    secondaryBackground: Color(0xFFFFFFFF),
    accent1: Color(0x4C4B39EF),
    accent2: Color(0x4D39D2C0),
    accent3: Color(0xFF402550),
    accent4: Color(0xCCFFFFFF),
    success: Color(0xFF249689),
    warning: Color(0xFFF9CF58),
    error: Color(0xFFFF5963),
    info: Color(0xFFFFFFFF),
    primaryBtnText: Color(0xFFFFFFFF),
    lineColor: Color(0xFFE0E3E7),
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

class AppTheme {
  AppTheme(this.theme)
      : colors =
            theme.extension<AppThemeColors>() ?? AppThemeColors.light;

  final ThemeData theme;
  final AppThemeColors colors;

  static AppTheme of(BuildContext context) {
    return AppTheme(Theme.of(context));
  }

  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  Color get primary => colors.primary;
  Color get secondary => colors.secondary;
  Color get tertiary => colors.tertiary;
  Color get alternate => colors.alternate;
  Color get primaryText => colors.primaryText;
  Color get secondaryText => colors.secondaryText;
  Color get primaryBackground => colors.primaryBackground;
  Color get secondaryBackground => colors.secondaryBackground;
  Color get accent1 => colors.accent1;
  Color get accent2 => colors.accent2;
  Color get accent3 => colors.accent3;
  Color get accent4 => colors.accent4;
  Color get success => colors.success;
  Color get warning => colors.warning;
  Color get error => colors.error;
  Color get info => colors.info;
  Color get primaryBtnText => colors.primaryBtnText;
  Color get lineColor => colors.lineColor;
  Color get noColor => colors.noColor;

  @Deprecated('Use displaySmallFamily instead')
  String get title1Family => displaySmallFamily;
  @Deprecated('Use displaySmall instead')
  TextStyle get title1 => displaySmall;
  @Deprecated('Use headlineMediumFamily instead')
  String get title2Family => headlineMediumFamily;
  @Deprecated('Use headlineMedium instead')
  TextStyle get title2 => headlineMedium;
  @Deprecated('Use headlineSmallFamily instead')
  String get title3Family => headlineSmallFamily;
  @Deprecated('Use headlineSmall instead')
  TextStyle get title3 => headlineSmall;
  @Deprecated('Use titleMediumFamily instead')
  String get subtitle1Family => titleMediumFamily;
  @Deprecated('Use titleMedium instead')
  TextStyle get subtitle1 => titleMedium;
  @Deprecated('Use titleSmallFamily instead')
  String get subtitle2Family => titleSmallFamily;
  @Deprecated('Use titleSmall instead')
  TextStyle get subtitle2 => titleSmall;
  @Deprecated('Use bodyMediumFamily instead')
  String get bodyText1Family => bodyMediumFamily;
  @Deprecated('Use bodyMedium instead')
  TextStyle get bodyText1 => bodyMedium;
  @Deprecated('Use bodySmallFamily instead')
  String get bodyText2Family => bodySmallFamily;
  @Deprecated('Use bodySmall instead')
  TextStyle get bodyText2 => bodySmall;

  String get displayLargeFamily => displayLarge.fontFamily ?? '';
  bool get displayLargeIsCustom => displayLarge.fontFamily != null;
  TextStyle get displayLarge =>
      theme.textTheme.displayLarge ?? const TextStyle();
  String get displayMediumFamily => displayMedium.fontFamily ?? '';
  bool get displayMediumIsCustom => displayMedium.fontFamily != null;
  TextStyle get displayMedium =>
      theme.textTheme.displayMedium ?? const TextStyle();
  String get displaySmallFamily => displaySmall.fontFamily ?? '';
  bool get displaySmallIsCustom => displaySmall.fontFamily != null;
  TextStyle get displaySmall =>
      theme.textTheme.displaySmall ?? const TextStyle();
  String get headlineLargeFamily => headlineLarge.fontFamily ?? '';
  bool get headlineLargeIsCustom => headlineLarge.fontFamily != null;
  TextStyle get headlineLarge =>
      theme.textTheme.headlineLarge ?? const TextStyle();
  String get headlineMediumFamily => headlineMedium.fontFamily ?? '';
  bool get headlineMediumIsCustom => headlineMedium.fontFamily != null;
  TextStyle get headlineMedium =>
      theme.textTheme.headlineMedium ?? const TextStyle();
  String get headlineSmallFamily => headlineSmall.fontFamily ?? '';
  bool get headlineSmallIsCustom => headlineSmall.fontFamily != null;
  TextStyle get headlineSmall =>
      theme.textTheme.headlineSmall ?? const TextStyle();
  String get titleLargeFamily => titleLarge.fontFamily ?? '';
  bool get titleLargeIsCustom => titleLarge.fontFamily != null;
  TextStyle get titleLarge => theme.textTheme.titleLarge ?? const TextStyle();
  String get titleMediumFamily => titleMedium.fontFamily ?? '';
  bool get titleMediumIsCustom => titleMedium.fontFamily != null;
  TextStyle get titleMedium => theme.textTheme.titleMedium ?? const TextStyle();
  String get titleSmallFamily => titleSmall.fontFamily ?? '';
  bool get titleSmallIsCustom => titleSmall.fontFamily != null;
  TextStyle get titleSmall => theme.textTheme.titleSmall ?? const TextStyle();
  String get labelLargeFamily => labelLarge.fontFamily ?? '';
  bool get labelLargeIsCustom => labelLarge.fontFamily != null;
  TextStyle get labelLarge => theme.textTheme.labelLarge ?? const TextStyle();
  String get labelMediumFamily => labelMedium.fontFamily ?? '';
  bool get labelMediumIsCustom => labelMedium.fontFamily != null;
  TextStyle get labelMedium => theme.textTheme.labelMedium ?? const TextStyle();
  String get labelSmallFamily => labelSmall.fontFamily ?? '';
  bool get labelSmallIsCustom => labelSmall.fontFamily != null;
  TextStyle get labelSmall => theme.textTheme.labelSmall ?? const TextStyle();
  String get bodyLargeFamily => bodyLarge.fontFamily ?? '';
  bool get bodyLargeIsCustom => bodyLarge.fontFamily != null;
  TextStyle get bodyLarge => theme.textTheme.bodyLarge ?? const TextStyle();
  String get bodyMediumFamily => bodyMedium.fontFamily ?? '';
  bool get bodyMediumIsCustom => bodyMedium.fontFamily != null;
  TextStyle get bodyMedium => theme.textTheme.bodyMedium ?? const TextStyle();
  String get bodySmallFamily => bodySmall.fontFamily ?? '';
  bool get bodySmallIsCustom => bodySmall.fontFamily != null;
  TextStyle get bodySmall => theme.textTheme.bodySmall ?? const TextStyle();
}

extension TextStyleHelper on TextStyle {
  TextStyle override({
    TextStyle? font,
    String? fontFamily,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    FontStyle? fontStyle,
    bool useGoogleFonts = false,
    TextDecoration? decoration,
    double? lineHeight,
    List<Shadow>? shadows,
    String? package,
  }) {
    if (useGoogleFonts && fontFamily != null) {
      font = GoogleFonts.getFont(fontFamily,
          fontWeight: fontWeight ?? this.fontWeight,
          fontStyle: fontStyle ?? this.fontStyle);
    }

    return font != null
        ? font.copyWith(
            color: color ?? this.color,
            fontSize: fontSize ?? this.fontSize,
            letterSpacing: letterSpacing ?? this.letterSpacing,
            fontWeight: fontWeight ?? this.fontWeight,
            fontStyle: fontStyle ?? this.fontStyle,
            decoration: decoration,
            height: lineHeight,
            shadows: shadows,
          )
        : copyWith(
            fontFamily: fontFamily,
            package: package,
            color: color,
            fontSize: fontSize,
            letterSpacing: letterSpacing,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
            decoration: decoration,
            height: lineHeight,
            shadows: shadows,
          );
  }
}
