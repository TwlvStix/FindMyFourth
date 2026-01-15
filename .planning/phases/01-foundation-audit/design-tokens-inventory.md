# Design Tokens Inventory

**Created:** 2026-01-15
**Source Files:**
- `lib/core/design_tokens/colors.dart`
- `lib/core/design_tokens/typography.dart`
- `lib/core/design_tokens/spacing.dart`

## Overview

The Find My Fourth app has a comprehensive design token system with a golf-inspired aesthetic called "Fairway Sunset" (colors) and "Elevated Country Club Modernism" (typography/spacing). The system is well-documented and follows design system best practices.

## Color Tokens

### Theme: "Fairway Sunset"
Golf-inspired palette blending deep forest greens with warm sunset accents.

#### Primary Palette - Deep Forest Greens (Golf Fairways)
| Token | Value | Usage |
|-------|-------|-------|
| `AppColors.fairwayDark` | `#1B3A2F` | Primary dark color for headers and emphasis |
| `AppColors.fairway` | `#2D5F4C` | Main brand color |
| `AppColors.fairwayLight` | `#4A8B6F` | Hover states and accents |

#### Accent - Sunset Glow (Golden Hour on the Course)
| Token | Value | Usage |
|-------|-------|-------|
| `AppColors.sunsetGold` | `#E8B44C` | Primary accent for CTAs and highlights |
| `AppColors.sunsetPeach` | `#E89E71` | Secondary accent |
| `AppColors.sunsetRose` | `#D97D70` | Tertiary accent |

#### Neutrals - Crisp & Clean (Golf Ball White + Sand Traps)
| Token | Value | Usage |
|-------|-------|-------|
| `AppColors.pure` | `#FFFEEFA` | Off-white, warmer for backgrounds |
| `AppColors.sand` | `#F4F1E8` | Warm neutral, subtle background variation |
| `AppColors.cloud` | `#E5E3DA` | Light grey for borders and dividers |
| `AppColors.stone` | `#9B9A91` | Mid grey for secondary text |
| `AppColors.slate` | `#4A4A42` | Dark grey for primary text on light backgrounds |
| `AppColors.onyx` | `#1C1C16` | Near black for headings and important text |

#### Semantic Colors
| Token | Value | Usage |
|-------|-------|-------|
| `AppColors.success` | `#3FA876` | Birdies, successful actions |
| `AppColors.warning` | `#E8B44C` | Same as sunset gold for consistency |
| `AppColors.error` | `#D64545` | Hazards, failed actions |
| `AppColors.info` | `#5B8DBE` | Water hazards, informational messages |

#### Gradients
| Token | Description | Colors |
|-------|-------------|--------|
| `AppColors.fairwayGradient` | Dark to light green | fairwayDark → fairway → fairwayLight |
| `AppColors.sunsetGradient` | Warm accent colors | sunsetGold → sunsetPeach → sunsetRose |
| `AppColors.subtleOverlay` | Background overlay | Transparent to 10% black |

#### Dark Theme Support
Complete dark theme variant exists in `AppColorsDark` class with:
- Darker variants of primary palette
- Slightly muted accents for dark backgrounds
- Inverted neutrals (pure becomes dark, onyx becomes light)
- Adjusted semantic colors for dark background visibility

**Observations:**
- ✓ Comprehensive color system with clear naming
- ✓ Strong thematic consistency (golf-inspired)
- ✓ Complete dark theme support
- ✓ Well-documented usage guidelines
- ✓ Semantic colors for common UI states

## Typography Tokens

### Theme: "Elevated Country Club Modernism"

#### Font Families
| Token | Font | Usage |
|-------|------|-------|
| `AppTypography.displayFamily` | Fraunces | Display font for headers and titles (sophisticated serif) |
| `AppTypography.bodyFamily` | Manrope | Body font for UI and paragraphs (geometric sans) |
| `AppTypography.monoFamily` | DM Mono | Monospace for scores and data (elegant tabular) |

**Font Philosophy:**
- Display (Fraunces): Traditional golf club elegance with modern character
- Body (Manrope): Clean, professional, polished readability
- Mono (DM Mono): Precision and clarity for numerical data

#### Type Scale (Major Third - 1.250 ratio)
| Token | Size | Usage |
|-------|------|-------|
| `size10` | 10px | Minimum size |
| `size12` | 12px | Small labels, captions |
| `size14` | 14px | Small body text |
| `size16` | 16px | Base size - standard body |
| `size18` | 18px | Large body |
| `size20` | 20px | Small headings |
| `size24` | 24px | Medium headings |
| `size28` | 28px | Large headings |
| `size32` | 32px | Display small |
| `size40` | 40px | Display medium |
| `size48` | 48px | Display/Mono large |
| `size56` | 56px | Display large |
| `size64` | 64px | Display XL / Mono display |
| `size72` | 72px | Display XL hero |

#### Font Weights
Complete range available: thin (100), extraLight (200), light (300), regular (400), medium (500), semiBold (600), bold (700), extraBold (800), black (900)

#### Line Heights
| Token | Value | Usage |
|-------|-------|-------|
| `lineHeightTight` | 1.1 | Headlines |
| `lineHeightSnug` | 1.2 | Subheadings |
| `lineHeightNormal` | 1.5 | Body text |
| `lineHeightRelaxed` | 1.6 | Large body text |
| `lineHeightLoose` | 1.8 | Special cases |

#### Letter Spacing
| Token | Value | Usage |
|-------|-------|-------|
| `letterSpacingTight` | -1.5 | Large headlines |
| `letterSpacingSnug` | -0.5 | Display text |
| `letterSpacingNormal` | 0.0 | Default |
| `letterSpacingWide` | 0.5 | Labels |
| `letterSpacingWider` | 1.0 | Buttons |
| `letterSpacingWidest` | 2.0 | Overlines, uppercase |

#### Text Style Inventory

**Display Styles** (Fraunces - Largest headers):
- `displayXL` - 72px, black weight (Hero headlines)
- `displayLarge` - 56px, bold (Primary headlines)
- `displayMedium` - 40px, bold (Section headers)
- `displaySmall` - 32px, semiBold (Subsection headers)

**Headline Styles** (Fraunces - Major headings):
- `headlineLarge` - 28px, semiBold
- `headlineMedium` - 24px, semiBold
- `headlineSmall` - 20px, medium

**Title Styles** (Manrope - UI headings):
- `titleLarge` - 20px, semiBold
- `titleMedium` - 18px, semiBold
- `titleSmall` - 16px, semiBold

**Body Styles** (Manrope - Reading text):
- `bodyLarge` - 18px, regular (Lead paragraphs)
- `bodyMedium` - 16px, regular (Standard body - base size)
- `bodySmall` - 14px, regular (Secondary descriptions)

**Label Styles** (Manrope - UI labels, buttons):
- `labelLarge` - 16px, semiBold (Large buttons)
- `labelMedium` - 14px, semiBold (Standard buttons)
- `labelSmall` - 12px, semiBold (Small buttons)

**Mono Styles** (DM Mono - Scores, data):
- `monoDisplay` - 64px, bold (Big scores, hero numbers)
- `monoLarge` - 48px, bold (Prominent scores/stats)
- `monoMedium` - 20px, medium (Standard data)
- `monoSmall` - 14px, regular (Compact data)

**Specialized Styles**:
- `button` - 16px, semiBold (Optimized for buttons)
- `buttonLarge` - 18px, bold (Large buttons)
- `overline` - 12px, bold (Small caps labels)
- `caption` - 12px, regular (Fine print)

#### Utility Features
- ✓ `createTextTheme()` - Flutter TextTheme integration
- ✓ Utility methods: `withColor()`, `withWeight()`, `withSize()`, `uppercase()`
- ✓ BuildContext extension for easy access: `context.typo.displayLarge`
- ✓ TextStyle extensions for chaining: `.bold`, `.semiBold`, `.spacing()`, etc.
- ✓ Font features: Tabular figures for monospace (proper number alignment)

**Observations:**
- ✓ Sophisticated three-font system (display, body, mono)
- ✓ Mathematical type scale (Major Third ratio)
- ✓ Complete hierarchy from 10px to 72px
- ✓ All Flutter TextTheme styles mapped
- ✓ Rich utility extensions for flexibility
- ✓ Strong golf/country club thematic consistency
- ✓ Professional typography with clear usage guidelines

## Spacing Tokens

### System: 8-point grid with 4px increments

#### Base Spacing Scale
| Token | Value | Usage |
|-------|-------|-------|
| `AppSpacing.xxs` | 4px | Minimum unit, icon padding, micro adjustments |
| `AppSpacing.xs` | 8px | Tight spacing between related elements |
| `AppSpacing.sm` | 12px | Compact lists, chip gaps, small padding |
| `AppSpacing.md` | 16px | Default spacing, comfortable separation |
| `AppSpacing.lg` | 20px | Medium-large spacing, breathing room |
| `AppSpacing.xl` | 24px | Section spacing, card padding, list items |
| `AppSpacing.xxl` | 32px | Major section separation, screen margins |
| `AppSpacing.xxxl` | 48px | Large section breaks, hero padding |
| `AppSpacing.xxxxl` | 64px | Hero sections, full-screen padding |

#### Semantic Spacing (Named Patterns)
| Token | Value | Usage |
|-------|-------|-------|
| `listItemGap` | 16px (md) | Spacing between list items |
| `listItemPadding` | 12px (sm) | Spacing within a list item |
| `cardPadding` | 20px (lg) | Padding inside cards |
| `cardGap` | 16px (md) | Gap between cards |
| `buttonPadding` | 16px (md) | Button internal spacing |
| `buttonGap` | 12px (sm) | Gap between buttons |
| `screenPadding` | 20px (lg) | Default screen edge padding |
| `sectionHeaderGap` | 16px (md) | Section header bottom margin |
| `formFieldGap` | 16px (md) | Spacing between form fields |
| `formFieldPadding` | 12px (sm) | Padding inside form fields |
| `modalPadding` | 24px (xl) | Spacing around modals/dialogs |
| `iconTextGap` | 8px (xs) | Gap between icon and text |
| `chipGap` | 8px (xs) | Chip spacing in groups |

#### EdgeInsets Shortcuts
Pre-built EdgeInsets constants for common patterns:
- `allXxs` through `allXxxl` - All sides (4px to 48px)
- `horizontalMd`, `horizontalLg`, `horizontalXl` - Horizontal only
- `verticalXs` through `verticalXl` - Vertical only
- `screen` - 20px horizontal + vertical
- `screenHorizontal` / `screenVertical` - Screen padding (20px)
- `card` - Card padding (20px all sides)
- `modal` - Modal padding (24px all sides)

#### SizedBox Shortcuts
Pre-built spacing widgets for Column/Row:
- Vertical: `verticalXxs` (4px) through `verticalXxxlBox` (48px)
- Horizontal: `horizontalXxs` (4px) through `horizontalXxlBox` (32px)

#### Utility Methods
- `symmetric()` - Create custom symmetric EdgeInsets
- `only()` - Create EdgeInsets with only specified sides
- `vertical(height)` - Custom vertical spacing widget
- `horizontal(width)` - Custom horizontal spacing widget

#### Extension Methods
List extension for adding spacing:
- `.withSpacing(double)` - Add spacing between items (both axes)
- `.withVerticalSpacing(double)` - Add vertical spacing only
- `.withHorizontalSpacing(double)` - Add horizontal spacing only

**Observations:**
- ✓ Consistent 8-point grid system (4px base unit)
- ✓ Clear semantic naming for common patterns
- ✓ Rich collection of pre-built EdgeInsets shortcuts
- ✓ Convenient SizedBox shortcuts for layout
- ✓ Powerful utility methods and extensions
- ✓ Mathematical progression for visual harmony
- ✓ Covers all common spacing needs

## Token Organization Analysis

### Strengths
1. **Thematic Consistency**: Strong golf/country club theme across all tokens
2. **Comprehensive Coverage**: Colors, typography, and spacing all thoroughly defined
3. **Documentation**: Excellent inline comments explaining usage and philosophy
4. **Dark Theme**: Complete dark mode support in color system
5. **Mathematical Foundation**: Type scale uses Major Third ratio, spacing uses 8pt grid
6. **Developer Experience**: Rich utilities, extensions, and shortcuts for easy usage
7. **Semantic Tokens**: Named patterns (cardPadding, buttonGap, etc.) improve readability
8. **Flutter Integration**: Native TextTheme support, BuildContext extensions

### Naming Consistency
- ✓ Colors: Descriptive names tied to theme (fairway, sunset, natural elements)
- ✓ Typography: Standard Flutter naming (displayLarge, bodyMedium, labelSmall)
- ✓ Spacing: Size-based scale (xxs through xxxxl) + semantic names
- ✓ Consistent pattern across all three token types

### Missing or Incomplete Categories

**Elevation/Shadow Tokens**:
- No dedicated shadow/elevation tokens
- Buttons, cards, modals likely use inline/hardcoded shadows
- Need: Elevation scale (0-5) with box shadows or Material elevation values

**Border Radius Tokens**:
- No dedicated border radius scale
- Inconsistent rounding likely across buttons, cards, inputs
- Need: Radius scale (xs, sm, md, lg, xl, full) for corners

**Animation/Duration Tokens**:
- No animation duration constants
- Transitions likely use magic numbers (200ms, 300ms, etc.)
- Need: Duration scale (fast, normal, slow) and easing curves

**Opacity/Alpha Tokens**:
- Some opacity in gradients (subtleOverlay uses 0x1A = 10% alpha)
- No dedicated opacity scale for hover states, disabled states, overlays
- Need: Opacity scale (5%, 10%, 20%, 40%, 60%, 80%)

**Breakpoint Tokens** (if responsive):
- No screen size breakpoints defined
- May not be needed if mobile-only, but unclear
- Consider: Mobile, tablet, desktop breakpoints if adaptive design needed

**Icon Size Tokens**:
- No dedicated icon size scale
- Likely using inline sizes or spacing tokens as proxy
- Need: Icon scale (xs, sm, md, lg, xl) - 16px, 20px, 24px, 32px, 40px

**Z-Index/Layer Tokens**:
- No z-index layering constants
- Modal, drawer, tooltip, dropdown stacking likely inconsistent
- Need: Layer scale (base, dropdown, sticky, modal, popover, tooltip)

### Hardcoded Values to Watch For
Based on common patterns in Flutter apps, likely hardcoded areas:
- Shadow definitions (BoxShadow properties)
- Border radius values (BorderRadius.circular)
- Animation durations (Duration milliseconds)
- Icon sizes (Icon size parameter)
- Opacity values (Color.withOpacity)
- Z-index/elevation for stacked components

## Recommendations for Phase 2

### High Priority
1. **Create elevation/shadow tokens** - Essential for visual depth consistency
2. **Create border radius tokens** - High impact on visual consistency
3. **Create opacity tokens** - Common in hover/disabled states

### Medium Priority
4. **Create animation duration tokens** - Improves motion consistency
5. **Create icon size tokens** - Small but visible inconsistency

### Lower Priority (Assess Need First)
6. **Breakpoint tokens** - Only if adaptive layouts needed
7. **Z-index tokens** - Only if stacking issues found in audit

### Next Steps
1. Continue to task 01-01-02: Audit component library
2. During component audit, note which missing tokens are causing inconsistencies
3. Use findings to prioritize token additions in Phase 2
