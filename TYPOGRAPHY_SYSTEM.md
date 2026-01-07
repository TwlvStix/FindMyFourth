# Typography System - "Elevated Country Club Modernism"

## Overview

A distinctive three-font typography system designed specifically for the "Find My Fourth" golf app, creating an athletic yet refined aesthetic that embodies traditional golf club elegance with modern energy.

## Font Philosophy

### 🎯 Design Goals
- **Memorable**: Avoid generic fonts (Inter, Roboto, Outfit)
- **Golf-Appropriate**: Blend traditional sophistication with athletic energy
- **Hierarchical**: Clear visual hierarchy from headlines to body text
- **Precise**: Elegant display of scores and numerical data
- **Refined**: Professional polish without being boring

### 🎨 "Elevated Country Club Modernism" Aesthetic
The typography system supports our brand positioning: the perfect intersection of golf's traditional elegance and modern athletic performance.

---

## Font Pairings

### 1. **Display/Headers - Fraunces**
**Purpose**: Headlines, titles, impactful text

**Character**: Sophisticated variable serif with personality
- Traditional golf club gravitas
- Modern character and warmth
- Variable weights for flexibility
- Perfect for brand differentiation

**Usage**:
- Page titles
- Section headers
- Game names
- Feature callouts

**Why Fraunces?**
- Not overused like Playfair Display or Merriweather
- Has the sophistication golf demands
- Variable font with optical sizing
- Memorable and distinctive

---

### 2. **Body/UI - Manrope**
**Purpose**: Reading text, UI elements, general content

**Character**: Clean geometric sans-serif
- Highly readable at all sizes
- Modern and polished
- Professional without being generic
- Excellent weight range (200-800)

**Usage**:
- Paragraph text
- Button labels
- Form inputs
- Navigation
- Descriptions

**Why Manrope?**
- Superior readability for body text
- Refined geometric aesthetic
- Pairs beautifully with Fraunces
- Not the usual Inter/Roboto choice

---

### 3. **Mono/Scores - DM Mono**
**Purpose**: Scores, statistics, precise data

**Character**: Elegant monospaced font
- Built-in tabular figures
- Clear numerical differentiation
- Professional precision
- More refined than Roboto Mono

**Usage**:
- Golf scores
- Game statistics
- Timestamps
- Player counts
- Technical data

**Why DM Mono?**
- Tabular figures align perfectly
- Elegant appearance
- Excellent for data visualization
- Appropriate precision for golf scores

---

## Type Scale

### Size System (Major Third Ratio: 1.250)

```dart
size10  = 10.0   // Tiny labels
size12  = 12.0   // Captions, overlines
size14  = 14.0   // Small body, compact UI
size16  = 16.0   // Base body size ← Default
size18  = 18.0   // Large body, prominent text
size20  = 20.0   // Small headlines
size24  = 24.0   // Medium headlines
size28  = 28.0   // Large headlines
size32  = 32.0   // Small display
size40  = 40.0   // Medium display
size48  = 48.0   // Large scores
size56  = 56.0   // Display large
size64  = 64.0   // Score display
size72  = 72.0   // Hero headlines
```

---

## Text Styles Reference

### Display Styles (Fraunces - Impact)

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `displayXL` | 72px | Black (900) | Hero headlines, landing pages |
| `displayLarge` | 56px | Bold (700) | Page titles, major headers |
| `displayMedium` | 40px | Bold (700) | Section headers, card titles |
| `displaySmall` | 32px | SemiBold (600) | Subsection titles |

### Headline Styles (Fraunces - Headers)

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `headlineLarge` | 28px | SemiBold (600) | Major headings |
| `headlineMedium` | 24px | SemiBold (600) | Standard headings |
| `headlineSmall` | 20px | Medium (500) | Minor headings |

### Title Styles (Manrope - UI Headers)

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `titleLarge` | 20px | SemiBold (600) | Large UI headings |
| `titleMedium` | 18px | SemiBold (600) | Standard UI headings |
| `titleSmall` | 16px | SemiBold (600) | Small UI headings |

### Body Styles (Manrope - Reading)

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `bodyLarge` | 18px | Regular (400) | Lead paragraphs, important content |
| `bodyMedium` | 16px | Regular (400) | Most text, descriptions |
| `bodySmall` | 14px | Regular (400) | Secondary text, helper text |

### Label Styles (Manrope - Buttons/Labels)

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `labelLarge` | 16px | SemiBold (600) | Large buttons, prominent labels |
| `labelMedium` | 14px | SemiBold (600) | Standard buttons, labels |
| `labelSmall` | 12px | SemiBold (600) | Small buttons, compact labels |

### Mono Styles (DM Mono - Data)

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `monoDisplay` | 64px | Bold (700) | Hero scores, big numbers |
| `monoLarge` | 48px | Bold (700) | Game scores, important stats |
| `monoMedium` | 20px | Medium (500) | Stats, timestamps |
| `monoSmall` | 14px | Regular (400) | Small data, metadata |

### Specialized Styles

| Style | Font | Size | Usage |
|-------|------|------|-------|
| `button` | Manrope | 16px | Button text |
| `buttonLarge` | Manrope | 18px | Large button text |
| `overline` | Manrope | 12px | Category labels, section markers |
| `caption` | Manrope | 12px | Image captions, footnotes |

---

## Usage Examples

### Basic Usage

```dart
import 'package:find_my_fourth/core/design_tokens/typography.dart';

// Display text
Text(
  'Find My Fourth',
  style: AppTypography.displayLarge,
)

// Body text
Text(
  'Join golfers looking for their fourth player',
  style: AppTypography.bodyMedium,
)

// Score display
Text(
  '72',
  style: AppTypography.monoDisplay,
)
```

### With Colors

```dart
import 'package:find_my_fourth/core/design_tokens/colors.dart';
import 'package:find_my_fourth/core/design_tokens/typography.dart';

Text(
  'Create Game',
  style: AppTypography.headlineMedium.withColor(AppColors.fairwayDark),
)
```

### Using Extensions

```dart
// Apply modifications easily
Text(
  'Join Game',
  style: AppTypography.bodyLarge.bold.withColor(AppColors.sunsetGold),
)

// Chain modifications
Text(
  'FEATURED',
  style: AppTypography.labelSmall.uppercase.withColor(AppColors.stone),
)
```

### With Theme Integration

```dart
// Access via Theme
Text(
  'Game Title',
  style: Theme.of(context).textTheme.headlineMedium,
)

// Access via AppTheme wrapper
Text(
  'Game Title',
  style: AppTheme.of(context).headlineMedium,
)
```

### Context Extension

```dart
// Quick access via context
Text(
  'Score: 72',
  style: context.typo.monoLarge,
)
```

---

## Best Practices

### 1. **Hierarchy is Key**
Always maintain clear visual hierarchy:
- Page title: `displayLarge` or `headlineLarge`
- Section headers: `headlineMedium`
- Card titles: `titleMedium`
- Body content: `bodyMedium`
- Supporting text: `bodySmall`

### 2. **Font Pairing Rules**
- **Headers**: Use Fraunces (display/headline styles)
- **UI Text**: Use Manrope (title/body/label styles)
- **Data**: Use DM Mono (mono styles)

### 3. **Avoid Mixing**
Don't use Fraunces for body text or Manrope for major headlines. Each font has its purpose.

### 4. **Scores Always Use Mono**
Golf scores, stats, and numerical data should always use `monoDisplay`, `monoLarge`, or `monoMedium` for clarity and tabular alignment.

### 5. **Button Text Standards**
- Primary buttons: `AppTypography.button`
- Large CTAs: `AppTypography.buttonLarge`
- Compact buttons: `AppTypography.labelSmall`

### 6. **Color Pairing**
Pair typography with semantic colors:
```dart
// Headers with brand colors
style: AppTypography.headlineLarge.withColor(AppColors.fairwayDark)

// CTAs with accent colors
style: AppTypography.button.withColor(AppColors.sunsetGold)

// Body with neutral colors
style: AppTypography.bodyMedium.withColor(AppColors.slate)
```

---

## Migration from Old System

### Old (Outfit)
```dart
// Before
GoogleFonts.outfit(
  fontSize: 24,
  fontWeight: FontWeight.w600,
)
```

### New (Fraunces/Manrope)
```dart
// After - Headers
AppTypography.headlineMedium

// After - UI Text
AppTypography.titleMedium
```

### Common Replacements

| Old Outfit Usage | New Replacement |
|-----------------|-----------------|
| Page titles (Outfit 32px bold) | `AppTypography.displaySmall` |
| Headers (Outfit 24px semibold) | `AppTypography.headlineMedium` |
| Body (Outfit 16px regular) | `AppTypography.bodyMedium` |
| Buttons (Outfit 16px semibold) | `AppTypography.button` |
| Small text (Outfit 14px) | `AppTypography.bodySmall` |

---

## Visual Hierarchy Example

```dart
// Game Card Example
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Game Name - Fraunces display
    Text(
      'Pebble Beach Round',
      style: AppTypography.headlineMedium
          .withColor(AppColors.fairwayDark),
    ),

    SizedBox(height: 8),

    // Meta info - Manrope body
    Text(
      'Saturday, Jan 6 at 9:00 AM',
      style: AppTypography.bodyMedium
          .withColor(AppColors.slate),
    ),

    SizedBox(height: 4),

    // Players count - DM Mono
    Text(
      '3/4 Players',
      style: AppTypography.monoSmall
          .withColor(AppColors.stone),
    ),
  ],
)
```

---

## Technical Details

### Font Loading
Fonts are loaded automatically via `google_fonts` package (already in dependencies). No manual font file management needed.

### Performance
- Google Fonts caches fonts locally after first load
- Minimal performance impact
- Variable fonts (Fraunces) reduce file size

### Accessibility
- All text sizes meet WCAG minimum standards
- Clear size differentiation for hierarchy
- Readable font choices at all sizes
- Support for dynamic type scaling

---

## Quick Reference Card

### Common Patterns

```dart
// Page Title
AppTypography.displayLarge

// Section Header
AppTypography.headlineMedium

// Card Title
AppTypography.titleMedium

// Paragraph Text
AppTypography.bodyMedium

// Button Label
AppTypography.button

// Golf Score
AppTypography.monoLarge

// Small Metadata
AppTypography.caption
```

---

## Implementation Checklist

- [x] Typography system created (`typography.dart`)
- [x] Font families selected (Fraunces, Manrope, DM Mono)
- [x] Type scale defined (1.250 ratio)
- [x] Text styles implemented
- [x] Flutter TextTheme integration
- [x] Utility methods and extensions
- [x] Main.dart updated to use new typography
- [x] Google Fonts dependency confirmed
- [ ] Update existing widgets to use new styles
- [ ] Test on all screen sizes
- [ ] Verify accessibility
- [ ] Document component-specific usage

---

**Generated:** 2026-01-06
**Design System:** Elevated Country Club Modernism
**Fonts:** Fraunces (Display), Manrope (Body), DM Mono (Data)
