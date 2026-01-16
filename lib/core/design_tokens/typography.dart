import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Elevated Country Club Modernism" Typography System
///
/// Font Philosophy:
/// - DISPLAY (Fraunces): Sophisticated serif for headers - traditional golf club elegance with modern character
/// - BODY (Manrope): Refined geometric sans for readability - clean, professional, polished
/// - MONO (DM Mono): Elegant monospace for scores/data - precision and clarity
///
/// This combination creates a memorable, golf-appropriate aesthetic that feels
/// both athletic and refined - avoiding generic fonts while maintaining professionalism.

class AppTypography {
  // ============================================================================
  // FONT FAMILIES
  // ============================================================================

  /// Display font for headers, titles, and impactful text
  /// Fraunces: Sophisticated variable serif with character
  /// Perfect for golf's traditional elegance with modern twist
  static const String displayFamily = 'Fraunces';

  /// Body font for UI, paragraphs, and general text
  /// Manrope: Clean geometric sans-serif, highly readable
  /// Modern and refined without being generic
  static const String bodyFamily = 'Manrope';

  /// Monospace font for scores, stats, and precise data
  /// DM Mono: Elegant monospace with tabular figures
  /// Professional precision for numerical data
  static const String monoFamily = 'DM Mono';

  // ============================================================================
  // FONT SIZES (Type Scale)
  // ============================================================================

  /// Type scale following 1.250 (Major Third) ratio for harmony
  static const double size10 = 10.0;
  static const double size12 = 12.0;
  static const double size14 = 14.0;
  static const double size16 = 16.0;  // Base size
  static const double size18 = 18.0;
  static const double size20 = 20.0;
  static const double size24 = 24.0;
  static const double size28 = 28.0;
  static const double size32 = 32.0;
  static const double size40 = 40.0;
  static const double size48 = 48.0;
  static const double size56 = 56.0;
  static const double size64 = 64.0;
  static const double size72 = 72.0;

  // ============================================================================
  // FONT WEIGHTS
  // ============================================================================

  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;

  // ============================================================================
  // LINE HEIGHTS
  // ============================================================================

  /// Tight line height for headlines
  static const double lineHeightTight = 1.1;

  /// Snug line height for subheadings
  static const double lineHeightSnug = 1.2;

  /// Normal line height for body text
  static const double lineHeightNormal = 1.5;

  /// Relaxed line height for large body text
  static const double lineHeightRelaxed = 1.6;

  /// Loose line height for special cases
  static const double lineHeightLoose = 1.8;

  // ============================================================================
  // LETTER SPACING
  // ============================================================================

  /// Tight letter spacing for large headlines
  static const double letterSpacingTight = -1.5;
  static const double letterSpacingSnug = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;
  static const double letterSpacingWider = 1.0;
  static const double letterSpacingWidest = 2.0;

  // ============================================================================
  // DISPLAY STYLES (Headers, Titles - Fraunces)
  // ============================================================================

  /// Display Extra Large - Hero headlines
  /// Usage: Landing page hero, major section headers
  static TextStyle get displayXL => GoogleFonts.fraunces(
        fontSize: size72,
        fontWeight: black,
        height: lineHeightTight,
        letterSpacing: letterSpacingTight,
      );

  /// Display Large - Primary headlines
  /// Usage: Page titles, major headers
  static TextStyle get displayLarge => GoogleFonts.fraunces(
        fontSize: size56,
        fontWeight: bold,
        height: lineHeightTight,
        letterSpacing: letterSpacingTight,
      );

  /// Display Medium - Section headers
  /// Usage: Section titles, card headers
  static TextStyle get displayMedium => GoogleFonts.fraunces(
        fontSize: size40,
        fontWeight: bold,
        height: lineHeightSnug,
        letterSpacing: letterSpacingSnug,
      );

  /// Display Small - Subsection headers
  /// Usage: Subsection titles, prominent labels
  static TextStyle get displaySmall => GoogleFonts.fraunces(
        fontSize: size32,
        fontWeight: semiBold,
        height: lineHeightSnug,
        letterSpacing: letterSpacingSnug,
      );

  // ============================================================================
  // HEADLINE STYLES (Fraunces - Smaller display uses)
  // ============================================================================

  /// Headline Large - Major headings
  static TextStyle get headlineLarge => GoogleFonts.fraunces(
        fontSize: size28,
        fontWeight: semiBold,
        height: lineHeightSnug,
        letterSpacing: letterSpacingNormal,
      );

  /// Headline Medium - Standard headings
  static TextStyle get headlineMedium => GoogleFonts.fraunces(
        fontSize: size24,
        fontWeight: semiBold,
        height: lineHeightSnug,
        letterSpacing: letterSpacingNormal,
      );

  /// Headline Small - Minor headings
  static TextStyle get headlineSmall => GoogleFonts.fraunces(
        fontSize: size20,
        fontWeight: medium,
        height: lineHeightNormal,
        letterSpacing: letterSpacingNormal,
      );

  // ============================================================================
  // TITLE STYLES (Manrope - UI headings)
  // ============================================================================

  /// Title Large - Large UI headings
  static TextStyle get titleLarge => GoogleFonts.manrope(
        fontSize: size20,
        fontWeight: semiBold,
        height: lineHeightNormal,
        letterSpacing: letterSpacingNormal,
      );

  /// Title Medium - Standard UI headings
  static TextStyle get titleMedium => GoogleFonts.manrope(
        fontSize: size18,
        fontWeight: semiBold,
        height: lineHeightNormal,
        letterSpacing: letterSpacingWide,
      );

  /// Title Small - Small UI headings
  static TextStyle get titleSmall => GoogleFonts.manrope(
        fontSize: size16,
        fontWeight: semiBold,
        height: lineHeightNormal,
        letterSpacing: letterSpacingWide,
      );

  // ============================================================================
  // BODY STYLES (Manrope - Reading text)
  // ============================================================================

  /// Body Large - Large body text
  /// Usage: Lead paragraphs, important content
  static TextStyle get bodyLarge => GoogleFonts.manrope(
        fontSize: size18,
        fontWeight: regular,
        height: lineHeightRelaxed,
        letterSpacing: letterSpacingNormal,
      );

  /// Body Medium - Standard body text (base size)
  /// Usage: Most paragraph text, descriptions
  static TextStyle get bodyMedium => GoogleFonts.manrope(
        fontSize: size16,
        fontWeight: regular,
        height: lineHeightNormal,
        letterSpacing: letterSpacingNormal,
      );

  /// Body Small - Small body text
  /// Usage: Secondary descriptions, helper text
  static TextStyle get bodySmall => GoogleFonts.manrope(
        fontSize: size14,
        fontWeight: regular,
        height: lineHeightNormal,
        letterSpacing: letterSpacingNormal,
      );

  // ============================================================================
  // LABEL STYLES (Manrope - UI labels, buttons)
  // ============================================================================

  /// Label Large - Large buttons, prominent labels
  static TextStyle get labelLarge => GoogleFonts.manrope(
        fontSize: size16,
        fontWeight: semiBold,
        height: 1.0,
        letterSpacing: letterSpacingWider,
      );

  /// Label Medium - Standard buttons, labels
  static TextStyle get labelMedium => GoogleFonts.manrope(
        fontSize: size14,
        fontWeight: semiBold,
        height: 1.0,
        letterSpacing: letterSpacingWide,
      );

  /// Label Small - Small buttons, compact labels
  static TextStyle get labelSmall => GoogleFonts.manrope(
        fontSize: size12,
        fontWeight: semiBold,
        height: 1.0,
        letterSpacing: letterSpacingWide,
      );

  // ============================================================================
  // MONO STYLES (DM Mono - Scores, data, code)
  // ============================================================================

  /// Mono Display - Large scores, hero numbers
  /// Usage: Big score displays, countdown timers
  static TextStyle get monoDisplay => GoogleFonts.dmMono(
        fontSize: size64,
        fontWeight: bold,
        height: 1.0,
        letterSpacing: letterSpacingTight,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  /// Mono Large - Prominent scores/stats
  /// Usage: Game scores, important statistics
  static TextStyle get monoLarge => GoogleFonts.dmMono(
        fontSize: size48,
        fontWeight: bold,
        height: 1.0,
        letterSpacing: letterSpacingSnug,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  /// Mono Medium - Standard data display
  /// Usage: Stats, numerical data, timestamps
  static TextStyle get monoMedium => GoogleFonts.dmMono(
        fontSize: size20,
        fontWeight: medium,
        height: 1.2,
        letterSpacing: letterSpacingNormal,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  /// Mono Small - Compact data, code
  /// Usage: Small stats, metadata, technical info
  static TextStyle get monoSmall => GoogleFonts.dmMono(
        fontSize: size14,
        fontWeight: regular,
        height: 1.4,
        letterSpacing: letterSpacingNormal,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  // ============================================================================
  // SPECIALIZED STYLES
  // ============================================================================

  /// Button Text - Optimized for buttons
  static TextStyle get button => GoogleFonts.manrope(
        fontSize: size16,
        fontWeight: semiBold,
        height: 1.0,
        letterSpacing: letterSpacingWider,
      );

  /// Button Large - Large button text
  static TextStyle get buttonLarge => GoogleFonts.manrope(
        fontSize: size18,
        fontWeight: bold,
        height: 1.0,
        letterSpacing: letterSpacingWider,
      );

  /// Overline - Small caps labels
  /// Usage: Category labels, section markers
  static TextStyle get overline => GoogleFonts.manrope(
        fontSize: size12,
        fontWeight: bold,
        height: 1.0,
        letterSpacing: letterSpacingWidest,
      );

  /// Caption - Fine print
  /// Usage: Image captions, footnotes, legal text
  static TextStyle get caption => GoogleFonts.manrope(
        fontSize: size12,
        fontWeight: regular,
        height: lineHeightNormal,
        letterSpacing: letterSpacingNormal,
      );

  // ============================================================================
  // SEMANTIC STYLES
  // ============================================================================
  //
  // These semantic getters provide meaningful names for common UI patterns.
  // Always prefer semantic styles over raw sizes for better code clarity.
  //
  // Examples:
  //   ✓ AppTypography.screenTitle instead of headlineMedium
  //   ✓ AppTypography.cardSubtitle instead of bodySmall
  //   ✓ AppTypography.errorText instead of caption with color override
  //
  // Migration helpers (size10-size22) exist for gradual migration but are
  // deprecated for new code. Use semantic styles instead.
  //
  // ============================================================================

  // Screen-level semantics

  /// Screen title - Standard for all screen page headers (24px Fraunces semibold)
  /// Usage: Top-level screen titles like "Create Game", "Game List"
  static TextStyle get screenTitle => headlineMedium;

  /// Section header - For content section headers (20px Manrope semibold)
  /// Usage: Dividing screen sections like "Game Details", "Player Stats"
  static TextStyle get sectionHeader => titleLarge;

  // Card semantics

  /// Card title - For card headers (18px Manrope semibold)
  /// Usage: Title text in cards, list items
  static TextStyle get cardTitle => titleMedium;

  /// Card subtitle - For card secondary text (14px Manrope regular, secondary color)
  /// Usage: Subtitle or description text in cards
  static TextStyle get cardSubtitle => bodySmall;

  // Form/UI semantics

  /// Helper text - Form field helper text (12px Manrope regular, secondary color)
  /// Usage: Helper text below form fields
  static TextStyle get helperText => caption;

  /// Error text - Validation error messages (12px Manrope regular, error color)
  /// Usage: Form field error messages
  static TextStyle get errorText => caption;

  // Time/metadata semantics

  /// Timestamp - For timestamps and time-based metadata (12px Manrope regular, secondary color)
  /// Usage: "2 hours ago", "Updated at 3:45 PM"
  static TextStyle get timestamp => caption;

  // Badge semantics

  /// Badge text - For badge labels (12px Manrope semibold)
  /// Usage: Status badges, count badges (but prefer AppBadge component)
  static TextStyle get badge => labelSmall;

  // Button semantics (convenience getters - prefer AppButtonEnhanced component)

  /// Button primary text - Primary button style
  /// Usage: Primary action buttons (but prefer AppButtonEnhanced)
  static TextStyle get buttonPrimary => button;

  /// Button secondary text - Secondary button style
  /// Usage: Secondary action buttons (but prefer AppButtonEnhanced)
  static TextStyle get buttonSecondary => button;

  // ============================================================================
  // MIGRATION HELPERS (DEPRECATED)
  // ============================================================================
  //
  // These helpers exist for gradual migration from hardcoded sizes.
  // DO NOT use in new code - use semantic styles instead.
  //
  // Example migration:
  //   Before: TextStyle(fontSize: 13)
  //   Transition: AppTypography.text13
  //   Final: AppTypography.bodySmall or appropriate semantic style
  //
  // ============================================================================

  // DEPRECATED - use semantic styles instead
  // For badges that genuinely need smaller text than caption
  static TextStyle get text10 => caption.copyWith(fontSize: 10);

  // DEPRECATED - use AppTypography.timestamp instead
  // For chat timestamps
  static TextStyle get text11 => caption.copyWith(fontSize: 11);

  // DEPRECATED - use AppTypography.bodySmall or AppTypography.labelSmall instead
  // Transition helper for 13px text
  static TextStyle get text13 => labelSmall.copyWith(fontSize: 13);

  // DEPRECATED - use AppTypography.bodySmall instead
  // Transition helper for 15px text
  static TextStyle get text15 => bodySmall.copyWith(fontSize: 15);

  // DEPRECATED - use AppTypography.screenTitle instead
  // Transition helper for 22px text
  static TextStyle get text22 => headlineMedium.copyWith(fontSize: 22);

  // ============================================================================
  // FLUTTER TEXTTHEME INTEGRATION
  // ============================================================================

  /// Creates a complete Material TextTheme using our typography system
  /// Use this to integrate with Flutter's theme system
  static TextTheme createTextTheme() {
    return TextTheme(
      // Display styles (largest)
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,

      // Headline styles
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,

      // Title styles
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,

      // Body styles
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,

      // Label styles
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    );
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Apply color to any text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply custom weight to any text style
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Apply custom size to any text style
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  /// Make text uppercase with proper letter spacing
  static TextStyle uppercase(TextStyle style) {
    return style.copyWith(letterSpacing: letterSpacingWidest);
  }
}

// ============================================================================
// EXTENSION HELPERS
// ============================================================================

/// Extension on BuildContext for easy typography access
extension TypographyExtension on BuildContext {
  /// Quick access to typography styles
  /// Usage: context.typo.displayLarge
  AppTypography get typo => AppTypography();
}

/// Extension on TextStyle for common modifications
extension TextStyleExtensions on TextStyle {
  /// Apply color
  TextStyle withColor(Color color) => copyWith(color: color);

  /// Apply weight
  TextStyle withWeight(FontWeight weight) => copyWith(fontWeight: weight);

  /// Apply size
  TextStyle withSize(double size) => copyWith(fontSize: size);

  /// Make bold
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);

  /// Make semi-bold
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);

  /// Make medium
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  /// Make light
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);

  /// Add letter spacing
  TextStyle spacing(double spacing) => copyWith(letterSpacing: spacing);

  /// Uppercase with proper spacing
  TextStyle get uppercase =>
      copyWith(letterSpacing: AppTypography.letterSpacingWidest);
}
