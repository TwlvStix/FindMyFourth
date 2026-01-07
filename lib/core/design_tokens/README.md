# Design Tokens

Centralized design system tokens for the "Find My Fourth" golf app.

## Contents

### 📐 [typography.dart](typography.dart)
Complete typography system with three distinctive font families:
- **Fraunces**: Sophisticated serif for headers and titles
- **Manrope**: Refined sans-serif for body and UI
- **DM Mono**: Elegant monospace for scores and data

**Usage:**
```dart
import 'package:find_my_fourth/core/design_tokens/typography.dart';

Text('Game Title', style: AppTypography.headlineLarge)
Text('Description', style: AppTypography.bodyMedium)
Text('72', style: AppTypography.monoDisplay)
```

### 🎨 [colors.dart](colors.dart)
"Fairway Sunset" color palette with light and dark themes:
- **Fairway greens**: Deep forest colors for primary branding
- **Sunset accents**: Warm gold, peach, and rose for energy
- **Neutrals**: Crisp whites and refined greys for readability

**Usage:**
```dart
import 'package:find_my_fourth/core/design_tokens/colors.dart';

Container(color: AppColors.fairwayDark)
Container(color: AppColors.sunsetGold)
Container(decoration: BoxDecoration(gradient: AppColors.fairwayGradient))
```

## Design System Philosophy

### "Elevated Country Club Modernism"
The design system blends traditional golf club sophistication with modern athletic energy:

**Traditional Elements:**
- Sophisticated serif typography (Fraunces)
- Deep forest green palette
- Refined spacing and hierarchy

**Modern Elements:**
- Clean geometric sans-serif (Manrope)
- Warm sunset accent colors
- Contemporary monospace for data (DM Mono)
- Gradient effects and visual depth

**Result:** A distinctive, golf-appropriate aesthetic that feels both elegant and energetic.

## Quick Reference

### Typography Hierarchy
```dart
// Page Title
AppTypography.displayLarge          // Fraunces 56px bold

// Section Header
AppTypography.headlineMedium        // Fraunces 24px semibold

// Card Title
AppTypography.titleMedium           // Manrope 18px semibold

// Body Text
AppTypography.bodyMedium            // Manrope 16px regular

// Button Text
AppTypography.button                // Manrope 16px semibold

// Score Display
AppTypography.monoLarge             // DM Mono 48px bold
```

### Color Palette
```dart
// Primary Colors
AppColors.fairwayDark               // #1B3A2F - Headers
AppColors.fairway                   // #2D5F4C - Brand
AppColors.fairwayLight              // #4A8B6F - Accents

// Accent Colors
AppColors.sunsetGold                // #E8B44C - CTAs
AppColors.sunsetPeach               // #E89E71 - Highlights
AppColors.sunsetRose                // #D97D70 - Accents

// Neutrals
AppColors.pure                      // #FFFEFA - Backgrounds
AppColors.sand                      // #F4F1E8 - Surfaces
AppColors.slate                     // #4A4A42 - Text
AppColors.onyx                      // #1C1C16 - Headers
```

## Integration with AppTheme

The design tokens are automatically integrated with Flutter's theme system:

```dart
// Via Theme
Theme.of(context).textTheme.headlineMedium

// Via AppTheme wrapper
AppTheme.of(context).headlineMedium
AppTheme.of(context).primary

// Direct access
AppTypography.bodyLarge
AppColors.fairwayDark
```

## Documentation

See full documentation:
- [TYPOGRAPHY_SYSTEM.md](../../../TYPOGRAPHY_SYSTEM.md) - Complete typography guide
- [COLOR_SYSTEM_MIGRATION.md](../../../COLOR_SYSTEM_MIGRATION.md) - Color system details

## Examples

### Styled Card Component
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.pure,
    borderRadius: BorderRadius.circular(16),
    border: Border(
      left: BorderSide(
        color: AppColors.sunsetGold,
        width: 4,
      ),
    ),
  ),
  padding: EdgeInsets.all(20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Pebble Beach Round',
        style: AppTypography.headlineMedium
            .withColor(AppColors.fairwayDark),
      ),
      SizedBox(height: 8),
      Text(
        'Saturday, Jan 6 at 9:00 AM',
        style: AppTypography.bodyMedium
            .withColor(AppColors.slate),
      ),
      SizedBox(height: 12),
      Text(
        '3/4',
        style: AppTypography.monoMedium
            .withColor(AppColors.stone),
      ),
    ],
  ),
)
```

### Gradient Background
```dart
Container(
  decoration: BoxDecoration(
    gradient: AppColors.fairwayGradient,
  ),
  child: Text(
    'Find My Fourth',
    style: AppTypography.displayLarge
        .withColor(AppColors.pure),
  ),
)
```
