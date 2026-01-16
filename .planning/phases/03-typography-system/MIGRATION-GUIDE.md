# Typography Migration Guide

## Overview

This guide helps migrate screens from hardcoded font sizes and manual GoogleFonts calls to the AppTypography design system.

## Before vs After Examples

### Example 1: Screen Title
```dart
// BEFORE (Anti-pattern)
Text(
  'Create Game',
  style: AppTheme.of(context).headlineLarge.override(
    font: GoogleFonts.outfit(fontWeight: FontWeight.w500),
    fontSize: 24.0,
    letterSpacing: 0.0,
  ),
)

// AFTER (Correct)
AppText.screenTitle('Create Game')
```

### Example 2: Section Header
```dart
// BEFORE
Text(
  'Game Details',
  style: GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  ),
)

// AFTER
AppText.sectionHeader('Game Details')
```

### Example 3: Body Text
```dart
// BEFORE
Text(
  'Description text',
  style: TextStyle(fontSize: 16),
)

// AFTER
AppText.body('Description text')
```

### Example 4: Caption / Helper Text
```dart
// BEFORE
Text(
  'Helper text',
  style: TextStyle(fontSize: 12, color: Colors.grey),
)

// AFTER
AppText.caption('Helper text', color: AppColors.textSecondary)
// or
AppText.helper('Helper text')
```

## Font Size Mapping

Use this table to convert hardcoded sizes to semantic styles:

| Old Size | New Style | Usage |
|----------|-----------|-------|
| 10px | AppText.labelSmall or AppText.caption | Tiny badges only |
| 11px | AppText.timestamp | Chat timestamps |
| 12px | AppText.caption or AppText.labelSmall | Helper text, captions, small labels |
| 13-14px | AppText.bodySmall or AppText.label | Secondary text, form labels |
| 15-16px | AppText.body | Primary body text |
| 18px | AppText.bodyLarge or AppText.cardTitle | Lead paragraphs, card titles |
| 20px | AppText.sectionHeader | Section headers |
| 22-24px | AppText.screenTitle | Screen titles, page headers |
| 26-28px | AppTypography.headlineLarge | Large headlines (rare) |
| 32px | AppTypography.displaySmall | Hero text (very rare) |
| 48px+ | AppText.monoLarge or AppText.monoDisplay | Large scores, stats |

## Screen Migration Checklist

For each screen:

1. **Find all Text widgets** with hardcoded fontSize
2. **Identify semantic role** (title? header? body? caption?)
3. **Replace with AppText.{semantic}** constructor
4. **Remove color overrides** where possible (use semantic colors)
5. **Test visual appearance** - may need size adjustment
6. **Remove all GoogleFonts.outfit() calls** (not in design system)
7. **Verify compilation** - ensure no errors

## Anti-Patterns to Remove

### Pattern 1: AppTheme.override
```dart
// REMOVE THIS
AppTheme.of(context).titleMedium.override(
  font: GoogleFonts.outfit(...),
  fontSize: 18.0,
  ...
)

// USE THIS
AppText.cardTitle('Title')
```

### Pattern 2: Manual GoogleFonts.outfit
```dart
// REMOVE THIS
GoogleFonts.outfit(
  fontSize: 16,
  fontWeight: FontWeight.w600,
)

// USE THIS
AppText.body('Text')  // or appropriate semantic style
```

### Pattern 3: Hardcoded fontSize in TextStyle
```dart
// REMOVE THIS
TextStyle(fontSize: 14, fontWeight: FontWeight.w500)

// USE THIS
AppTypography.bodySmall.semiBold
// or
AppText.bodySmall('Text')
```

## Priority Screens (High Impact)

Migrate these screens first (worst offenders from audit):

1. **create_profile_widget.dart** - 15% compliant, 16+ hardcoded sizes
2. **sign_up_account_widget.dart** - 20% compliant, heavy override usage
3. **game_chat_details_widget.dart** - 25% compliant, extreme range
4. **edit_profile_widget.dart** - 25% compliant
5. **create_game_widget.dart** - 30% compliant, 13+ hardcoded sizes

## Testing After Migration

1. **Visual regression**: Compare before/after screenshots
2. **Check hierarchy**: Screen title > section header > body text
3. **Verify readability**: No text smaller than 12px (caption)
4. **Test dark mode**: Ensure semantic colors work in both themes
5. **Measure adoption**: Count AppText usage vs manual Text usage

## Target Metrics

- **Before**: 30-35% AppTypography adoption
- **After Phase 3**: 85%+ AppTypography adoption
- **Hardcoded fontSize instances**: Should drop from ~800 to <100
- **GoogleFonts.outfit calls**: Should be eliminated (0 instances)
- **AppTheme.override usage**: Should be eliminated (0 instances)

## Migration Script Ideas

For automated refactoring (future):
- Find/replace fontSize: 24 → AppText.screenTitle (where parent is Text)
- Find/replace fontSize: 16 → AppText.body (with semantic context)
- Flag all GoogleFonts.outfit for manual review
- Flag all AppTheme.override for manual removal
