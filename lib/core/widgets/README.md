# Core Widgets

Enhanced, production-grade UI components for the "Find My Fourth" golf app.

## Components

### 🎨 FairwayBackground (NEW)
Atmospheric background component with organic overlays and depth.

**File**: `fairway_background.dart`

**Features**:
- 4 variants (light, dark, sunset, minimal)
- Organic curved overlays (rolling fairway effect)
- Optional subtle texture/grain
- Gradient mesh effects for depth
- Performance optimized (RepaintBoundary)
- Easy drop-in replacement for solid backgrounds

**Quick Start**:
```dart
import 'package:find_my_fourth/core/widgets/fairway_background.dart';

// Light background (most screens)
FairwayBackgroundLight(
  showOrganic: true,
  child: YourScreen(),
)

// Dark background (immersive)
FairwayBackgroundDark(
  showOrganic: true,
  showTexture: true,
  child: GameDetail(),
)

// Sunset background (hero moments)
FairwayBackgroundSunset(
  showOrganic: true,
  child: WelcomeScreen(),
)
```

**Documentation**: See [BACKGROUND_SYSTEM.md](../../../BACKGROUND_SYSTEM.md)

---

### 🏌️ BrandedGolfHeader (NEW)
Premium branded header component with refined topographic pattern and curved bottom edge.

**File**: `branded_golf_header.dart`

**Features**:
- 150px height with elegant curved bottom edge (concave curve)
- Deep forest green gradient background (3-tone)
- Subtle topographic contour pattern overlay (12% opacity)
- Username displayed bottom-left, course name bottom-right
- White text with layered shadows for excellent contrast
- Professional country club aesthetic

**Components Included**:
- `CurvedHeaderClipper`: Custom clipper for elegant curved bottom edge
- `SubtleTopographicPainter`: Atmospheric topographic pattern with elevation bands
- `BrandedGolfHeader`: Main header widget

**Quick Start**:
```dart
import 'package:find_my_fourth/core/widgets/branded_golf_header.dart';

BrandedGolfHeader(
  username: 'Ryan New Test',
  courseName: 'Predator Ridge Golf Resort',
)
```

**Usage in Screens**:
```dart
Column(
  children: [
    Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: BrandedGolfHeader(
        username: gameRecord.nameGame,
        courseName: gameRecord.coursePlay,
      ),
    ),
    // Rest of screen content
  ],
)
```

**Design Notes**:
- Replaces photo headers with consistent branded element
- Curves use quadratic bezier (dips 15px in center)
- Topographic lines mimic golf course elevation maps
- Pattern has multiple elevation bands (upper, middle, lower)
- Very subtle 0.8px stroke width maintains atmosphere
- Text positioned 20px from curved bottom edge

---

### 🎴 AppCard (NEW)
Production-grade card component with variants and micro-interactions.

**File**: `app_card.dart`

**Features**:
- 4 variants (standard, elevated, outlined, gradientAccent)
- Specialized cards (GameCard, StatCard, SectionCard)
- Interactive tap states with scale animation
- Design token integration (spacing, colors, typography)
- Flexible content areas

**Quick Start**:
```dart
import 'package:find_my_fourth/core/widgets/app_card.dart';

// Standard card
AppCard(
  child: Column(
    children: [
      Text('Title', style: AppTypography.headlineMedium),
      Text('Content', style: AppTypography.bodyMedium),
    ],
  ),
)

// Game card (specialized)
GameCard(
  title: 'Pebble Beach Round',
  subtitle: 'Saturday, Jan 6 at 9:00 AM',
  metadata: '3/4 players',
  onTap: () => navigateToGame(),
)

// Stat card (specialized)
StatCard(
  label: 'Games Played',
  value: '24',
  icon: Icons.golf_course,
)
```

**Documentation**: See [CARD_SYSTEM.md](../../../CARD_SYSTEM.md)

---

### ✨ AppButtonEnhanced (NEW)
Enhanced button component with variants, micro-interactions, and polish.

**File**: `app_button_enhanced.dart`

**Features**:
- 4 variants (primary, secondary, ghost, gradient)
- 4 size presets (small, medium, large, xlarge)
- Micro-interactions (scale on press, hover states)
- Loading states, icon support, haptic feedback
- Full accessibility support

**Quick Start**:
```dart
import 'package:find_my_fourth/core/widgets/app_button_enhanced.dart';

// Primary button
AppButtonEnhanced(
  text: 'Join Game',
  variant: AppButtonVariant.primary,
  size: AppButtonSize.large,
  onPressed: () => handleJoin(),
)

// Gradient button with icon
AppButtonEnhanced(
  text: 'Find Players',
  variant: AppButtonVariant.gradient,
  leadingIcon: Icons.search,
  onPressed: () => search(),
)
```

**Documentation**: See [BUTTON_SYSTEM.md](../../../BUTTON_SYSTEM.md)

---

### AppButton (LEGACY)
Original button component - consider migrating to AppButtonEnhanced.

**File**: `app_button.dart`

**Status**: Legacy - use AppButtonEnhanced for new code

---

### AppIconButton
Icon-only button component.

**File**: `app_icon_button.dart`

**Usage**:
```dart
AppIconButton(
  icon: Icon(Icons.edit),
  onPressed: () => edit(),
  borderRadius: 8.0,
  fillColor: AppColors.fairway,
)
```

---

### AppDropDown
Enhanced dropdown with search and multi-select.

**File**: `app_drop_down.dart`

**Features**:
- Single and multi-select modes
- Searchable options
- Custom styling

---

### AppChoiceChips
Chip selection component.

**File**: `app_choice_chips.dart`

**Usage**:
```dart
AppChoiceChips(
  options: [
    ChipData('Stroke Play'),
    ChipData('Match Play'),
    ChipData('Scramble'),
  ],
  controller: FormFieldController([]),
  onChanged: (selected) => handleSelection(selected),
  multiselect: true,
)
```

---

### AppCountController
Number input with increment/decrement controls.

**File**: `app_count_controller.dart`

---

## Migration Guide

### AppButton → AppButtonEnhanced

**Status:** ⚠️ AppButton is DEPRECATED as of Phase 2. Will be removed in Phase 3.

**Why migrate:**
- AppButtonEnhanced uses design tokens (AppBorderRadius, AppElevation, AppTypography)
- Better variant system for different button styles (primary, secondary, ghost, gradient, destructive)
- Consistent sizing with accessibility standards (48px minimum touch target for medium buttons)
- Built-in loading states that maintain button size
- Haptic feedback for better user experience
- Cleaner API - no complex AppButtonOptions configuration object

---

#### Migration Mapping Tables

**Variant Mapping:**

| Old (AppButton) | New (AppButtonEnhanced) | Notes |
|----------------|------------------------|-------|
| Default filled style | `variant: AppButtonVariant.primary` | Filled green button |
| Outlined style | `variant: AppButtonVariant.secondary` | Green border, transparent bg |
| Text-only style | `variant: AppButtonVariant.ghost` | No background, just text |
| Gradient style | `variant: AppButtonVariant.gradient` | Sunset gradient fill |
| Delete/remove actions | `variant: AppButtonVariant.destructive` | **NEW!** Red button for dangerous actions |

**Size Mapping:**

| Old (AppButtonOptions) | New (AppButtonEnhanced) | Touch Target |
|----------------------|------------------------|--------------|
| `height: 36` | `size: AppButtonSize.small` | 36px |
| `height: 48` (default) | `size: AppButtonSize.medium` | 48px (accessible) |
| `height: 56` | `size: AppButtonSize.large` | 56px |
| `height: 64` | `size: AppButtonSize.xlarge` | 64px |

---

#### Migration Examples

**Example 1: Primary filled button**

```dart
// OLD (deprecated) ❌
AppButton(
  text: 'Join Game',
  onPressed: () => joinGame(),
  options: AppButtonOptions(
    color: AppColors.fairwayDark,
    textStyle: AppTypography.button.copyWith(color: AppColors.pure),
    height: 48,
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    borderRadius: BorderRadius.circular(8),
  ),
)

// NEW (preferred) ✅
AppButtonEnhanced(
  text: 'Join Game',
  variant: AppButtonVariant.primary,
  size: AppButtonSize.medium,
  onPressed: () => joinGame(),
)
```

**Example 2: Outlined secondary button**

```dart
// OLD (deprecated) ❌
AppButton(
  text: 'Cancel',
  onPressed: () => cancel(),
  options: AppButtonOptions(
    color: Colors.transparent,
    textStyle: AppTypography.button.copyWith(color: AppColors.fairway),
    height: 48,
    borderSide: BorderSide(color: AppColors.fairway, width: 2),
    borderRadius: BorderRadius.circular(8),
  ),
)

// NEW (preferred) ✅
AppButtonEnhanced(
  text: 'Cancel',
  variant: AppButtonVariant.secondary,
  size: AppButtonSize.medium,
  onPressed: () => cancel(),
)
```

**Example 3: Ghost/text-only button**

```dart
// OLD (deprecated) ❌
AppButton(
  text: 'Skip',
  onPressed: () => skip(),
  options: AppButtonOptions(
    color: Colors.transparent,
    textStyle: AppTypography.button.copyWith(color: AppColors.fairway),
    elevation: 0,
    height: 48,
  ),
)

// NEW (preferred) ✅
AppButtonEnhanced(
  text: 'Skip',
  variant: AppButtonVariant.ghost,
  size: AppButtonSize.medium,
  onPressed: () => skip(),
)
```

**Example 4: Button with icon**

```dart
// OLD (deprecated) ❌
AppButton(
  text: 'Add Player',
  icon: Icon(Icons.add),
  onPressed: () => addPlayer(),
  options: AppButtonOptions(
    color: AppColors.fairwayDark,
    textStyle: AppTypography.button.copyWith(color: AppColors.pure),
    iconColor: AppColors.pure,
    height: 48,
  ),
)

// NEW (preferred) ✅
AppButtonEnhanced(
  text: 'Add Player',
  leadingIcon: Icons.add,
  variant: AppButtonVariant.primary,
  size: AppButtonSize.medium,
  onPressed: () => addPlayer(),
)
```

**Example 5: Destructive action (NEW!)**

```dart
// NEW destructive variant - not available in AppButton ✅
AppButtonEnhanced(
  text: 'Delete Game',
  variant: AppButtonVariant.destructive,
  size: AppButtonSize.medium,
  leadingIcon: Icons.delete,
  onPressed: () => deleteGame(),
)
```

---

#### Key API Differences

| Feature | AppButton (old) | AppButtonEnhanced (new) |
|---------|----------------|------------------------|
| **Configuration** | `AppButtonOptions` object | Direct parameters |
| **Styling** | Manual color/border/etc | `variant` enum |
| **Sizing** | Manual `height` | `size` enum |
| **Icons** | `Widget icon` | `IconData leadingIcon/trailingIcon` |
| **Design tokens** | Manual (must specify) | Automatic (baked in) |
| **Loading state** | `showLoadingIndicator` bool | `isLoading` bool (maintains size) |
| **Haptics** | Not available | Built-in |
| **Destructive actions** | Not available | `destructive` variant |

---

#### Migration Strategy

Existing AppButton usage will continue to work but will show IDE deprecation warnings. Migrate incrementally:

1. **Start with high-visibility screens** (games list, create game, profile)
2. **Replace buttons one screen at a time** - test each screen after migration
3. **Use find/replace carefully** - AppButton parameters don't map 1:1
4. **Test all states** - normal, loading, disabled, hover (web/desktop)
5. **Once all migrated** - AppButton will be removed in Phase 3

---

#### Quick Reference

```dart
// Common patterns with AppButtonEnhanced

// Primary CTA
AppButtonEnhanced(
  text: 'Join Game',
  variant: AppButtonVariant.primary,
  size: AppButtonSize.large,
  onPressed: () => join(),
)

// Cancel/back action
AppButtonEnhanced(
  text: 'Cancel',
  variant: AppButtonVariant.secondary,
  size: AppButtonSize.medium,
  onPressed: () => cancel(),
)

// Tertiary low-priority action
AppButtonEnhanced(
  text: 'Skip',
  variant: AppButtonVariant.ghost,
  size: AppButtonSize.medium,
  onPressed: () => skip(),
)

// Delete/remove action
AppButtonEnhanced(
  text: 'Delete',
  variant: AppButtonVariant.destructive,
  leadingIcon: Icons.delete,
  onPressed: () => delete(),
)

// Full-width button (forms, bottom sheets)
AppButtonEnhanced(
  text: 'Submit',
  variant: AppButtonVariant.primary,
  fullWidth: true,
  onPressed: () => submit(),
)

// With loading state
AppButtonEnhanced(
  text: 'Submitting...',
  variant: AppButtonVariant.primary,
  isLoading: _isLoading,
  onPressed: _isLoading ? null : () => submit(),
)
```

---

**Need help?** Check the AppButtonEnhanced source code at `lib/core/widgets/app_button_enhanced.dart` for full API documentation.

**Benefits of Migration:**
✅ Cleaner API (90% less code)
✅ Automatic design token integration
✅ Built-in variants and sizes
✅ Sophisticated micro-interactions
✅ Better accessibility
✅ Consistent with design system

---

## Design System Integration

All enhanced widgets integrate with the design token system:

### Colors
```dart
import 'package:find_my_fourth/core/design_tokens/colors.dart';

// Use semantic color names
AppColors.fairwayDark    // Primary brand color
AppColors.sunsetGold     // Accent color
AppColors.pure           // Background white
```

### Typography
```dart
import 'package:find_my_fourth/core/design_tokens/typography.dart';

// Use predefined text styles
AppTypography.headlineLarge    // Page titles
AppTypography.bodyMedium       // Body text
AppTypography.button           // Button text
```

---

## Widget Patterns

### Form Actions
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    AppButtonEnhanced(
      text: 'Cancel',
      variant: AppButtonVariant.ghost,
      onPressed: () => cancel(),
    ),
    AppButtonEnhanced(
      text: 'Save',
      variant: AppButtonVariant.primary,
      leadingIcon: Icons.save,
      onPressed: () => save(),
    ),
  ],
)
```

### Loading State
```dart
class SubmitButton extends StatefulWidget {
  @override
  State<SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton> {
  bool _isLoading = false;

  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);
    try {
      await submitData();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButtonEnhanced(
      text: _isLoading ? 'Submitting...' : 'Submit',
      isLoading: _isLoading,
      variant: AppButtonVariant.primary,
      onPressed: _handleSubmit,
    );
  }
}
```

### Bottom Sheet Actions
```dart
Column(
  children: [
    AppButtonEnhanced(
      text: 'Join Game',
      fullWidth: true,
      size: AppButtonSize.large,
      variant: AppButtonVariant.primary,
      onPressed: () => join(),
    ),
    SizedBox(height: 12),
    AppButtonEnhanced(
      text: 'View Details',
      fullWidth: true,
      variant: AppButtonVariant.secondary,
      onPressed: () => viewDetails(),
    ),
  ],
)
```

---

## Best Practices

### 1. Use Semantic Variants
Choose variants based on action priority, not just aesthetics:
- **Primary**: Main action (1 per screen)
- **Secondary**: Alternative actions
- **Ghost**: Tertiary, low-priority
- **Gradient**: Special moments only

### 2. Maintain Visual Hierarchy
```dart
// Good - Clear hierarchy
Column(
  children: [
    AppButtonEnhanced(
      text: 'Join Game',
      variant: AppButtonVariant.primary,    // Main action
      size: AppButtonSize.large,
    ),
    AppButtonEnhanced(
      text: 'View Details',
      variant: AppButtonVariant.secondary,  // Secondary action
    ),
    AppButtonEnhanced(
      text: 'Cancel',
      variant: AppButtonVariant.ghost,      // Tertiary action
    ),
  ],
)
```

### 3. Accessibility
- Minimum 48px touch targets (use `medium` or larger)
- Provide meaningful button text
- Test keyboard navigation
- Use proper loading states

### 4. Performance
- Avoid rebuilding buttons unnecessarily
- Use `const` constructors when possible
- Minimize state changes

---

## Component Checklist

- [x] FairwayBackground - Production ready ✅
- [x] BrandedGolfHeader - Production ready ✅
- [x] AppCard - Production ready ✅
- [x] AppButtonEnhanced - Production ready ✅
- [x] AppIconButton - Legacy, works
- [x] AppDropDown - Legacy, works
- [x] AppChoiceChips - Legacy, works
- [x] AppCountController - Legacy, works
- [ ] AppTextField - To be enhanced
- [ ] AppDialog - To be enhanced
- [ ] AppLoadingIndicator - To be created
- [ ] AppEmptyState - To be created
- [ ] AppErrorState - To be created

**Note**: Example/showcase widgets (AppButtonExamples, AppCardExamples, AppListTileExamples, FairwayBackgroundExamples) have been removed. For usage examples, refer to the component source files or the linked documentation (BUTTON_SYSTEM.md, CARD_SYSTEM.md, etc.).

---

## Resources

- **Background Documentation**: [BACKGROUND_SYSTEM.md](../../../BACKGROUND_SYSTEM.md)
- **Card Documentation**: [CARD_SYSTEM.md](../../../CARD_SYSTEM.md)
- **Button Documentation**: [BUTTON_SYSTEM.md](../../../BUTTON_SYSTEM.md)
- **Spacing Guide**: [SPACING_SYSTEM.md](../../../SPACING_SYSTEM.md)
- **Typography Guide**: [TYPOGRAPHY_SYSTEM.md](../../../TYPOGRAPHY_SYSTEM.md)
- **Color System**: [COLOR_SYSTEM_MIGRATION.md](../../../COLOR_SYSTEM_MIGRATION.md)
- **Design Tokens**: [design_tokens/README.md](../design_tokens/README.md)

---

**Last Updated**: 2026-01-07
**Design System**: Elevated Country Club Modernism
