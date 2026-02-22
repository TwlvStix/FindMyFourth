import 'package:flutter/material.dart';
import 'package:find_my_fourth/core/design_tokens/typography.dart';

/// Convenience widget for common text patterns using AppTypography
///
/// Eliminates the need for manual GoogleFonts calls and TextStyle.override patterns.
///
/// Examples:
/// ```dart
/// AppText.screenTitle('Game List')
/// AppText.sectionHeader('Game Details')
/// AppText.body('Description text')
/// AppText.caption('Helper text', color: AppColors.textSecondary)
/// AppText.button('Create Game')
/// ```
class AppText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppText(
    this.text, {
    required this.style,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    Key? key,
  }) : super(key: key);

  // Named constructors for semantic styles

  /// Screen title (24px Fraunces semibold) - use for page headers
  factory AppText.screenTitle(String text, {Color? color, TextAlign? textAlign, Key? key}) {
    return AppText(text, style: AppTypography.screenTitle, color: color, textAlign: textAlign, key: key);
  }

  /// Section header (20px Manrope semibold) - use for content sections
  factory AppText.sectionHeader(String text, {Color? color, TextAlign? textAlign, Key? key}) {
    return AppText(text, style: AppTypography.sectionHeader, color: color, textAlign: textAlign, key: key);
  }

  /// Card title (18px Manrope semibold) - use for card headers
  factory AppText.cardTitle(String text, {Color? color, TextAlign? textAlign, int? maxLines, TextOverflow? overflow, Key? key}) {
    return AppText(text, style: AppTypography.cardTitle, color: color, textAlign: textAlign, maxLines: maxLines, overflow: overflow, key: key);
  }

  /// Card subtitle (14px Manrope regular) - use for card secondary text
  factory AppText.cardSubtitle(String text, {Color? color, TextAlign? textAlign, int? maxLines, TextOverflow? overflow, Key? key}) {
    return AppText(text, style: AppTypography.cardSubtitle, color: color, textAlign: textAlign, maxLines: maxLines, overflow: overflow, key: key);
  }

  /// Body text (16px Manrope regular) - use for paragraphs
  factory AppText.body(String text, {Color? color, TextAlign? textAlign, int? maxLines, TextOverflow? overflow, Key? key}) {
    return AppText(text, style: AppTypography.bodyMedium, color: color, textAlign: textAlign, maxLines: maxLines, overflow: overflow, key: key);
  }

  /// Body large (18px Manrope regular) - use for lead paragraphs
  factory AppText.bodyLarge(String text, {Color? color, TextAlign? textAlign, int? maxLines, TextOverflow? overflow, Key? key}) {
    return AppText(text, style: AppTypography.bodyLarge, color: color, textAlign: textAlign, maxLines: maxLines, overflow: overflow, key: key);
  }

  /// Body small (14px Manrope regular) - use for secondary text
  factory AppText.bodySmall(String text, {Color? color, TextAlign? textAlign, int? maxLines, TextOverflow? overflow, Key? key}) {
    return AppText(text, style: AppTypography.bodySmall, color: color, textAlign: textAlign, maxLines: maxLines, overflow: overflow, key: key);
  }

  /// Caption (12px Manrope regular) - use for helper text, captions
  factory AppText.caption(String text, {Color? color, TextAlign? textAlign, int? maxLines, TextOverflow? overflow, Key? key}) {
    return AppText(text, style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w400, height: 1.5, letterSpacing: 0.0), color: color, textAlign: textAlign, maxLines: maxLines, overflow: overflow, key: key);
  }

  /// Label (14px Manrope semibold) - use for form labels, badges
  factory AppText.label(String text, {Color? color, TextAlign? textAlign, Key? key}) {
    return AppText(text, style: AppTypography.labelMedium, color: color, textAlign: textAlign, key: key);
  }

  /// Label small (12px Manrope semibold) - use for small badges, compact labels
  factory AppText.labelSmall(String text, {Color? color, TextAlign? textAlign, Key? key}) {
    return AppText(text, style: AppTypography.labelSmall, color: color, textAlign: textAlign, key: key);
  }

  /// Button text (16px Manrope semibold) - use for buttons (but prefer AppButtonEnhanced)
  factory AppText.button(String text, {Color? color, Key? key}) {
    return AppText(text, style: AppTypography.labelLarge, color: color, key: key);
  }

  /// Timestamp (12px Manrope regular, secondary color) - use for timestamps
  factory AppText.timestamp(String text, {Color? color, Key? key}) {
    return AppText(text, style: AppTypography.timestamp, color: color, key: key);
  }

  /// Badge text (12px Manrope semibold) - use for badges (but prefer AppBadge component)
  factory AppText.badge(String text, {Color? color, Key? key}) {
    return AppText(text, style: AppTypography.badge, color: color, key: key);
  }

  /// Error text (12px Manrope regular, error color) - use for validation errors
  factory AppText.error(String text, {Key? key}) {
    return AppText(text, style: AppTypography.errorText, key: key);
  }

  /// Helper text (12px Manrope regular, secondary color) - use for form helper text
  factory AppText.helper(String text, {Color? color, Key? key}) {
    return AppText(text, style: AppTypography.helperText, color: color, key: key);
  }

  /// Mono display (64px DM Mono bold) - use for large scores
  factory AppText.monoDisplay(String text, {Color? color, Key? key}) {
    return AppText(text, style: AppTypography.monoDisplay, color: color, key: key);
  }

  /// Mono large (48px DM Mono bold) - use for prominent scores
  factory AppText.monoLarge(String text, {Color? color, Key? key}) {
    return AppText(text, style: AppTypography.monoLarge, color: color, key: key);
  }

  /// Mono medium (20px DM Mono medium) - use for stats, data
  factory AppText.monoMedium(String text, {Color? color, Key? key}) {
    return AppText(text, style: AppTypography.monoMedium, color: color, key: key);
  }

  /// Mono small (14px DM Mono regular) - use for small stats, metadata
  factory AppText.monoSmall(String text, {Color? color, Key? key}) {
    return AppText(text, style: AppTypography.monoSmall, color: color, key: key);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: color != null ? style.copyWith(color: color) : style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
