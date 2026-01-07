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

### 📋 AppButtonExamples
Showcase of all button variants and states.

**File**: `app_button_examples.dart`

**Usage**:
```dart
// Add to your router for testing/reference
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => AppButtonExamples()),
);
```

Shows all variants, sizes, states, and real-world examples.

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

### From AppButton to AppButtonEnhanced

**Old Code**:
```dart
AppButton(
  text: 'Join Game',
  onPressed: () => join(),
  options: AppButtonOptions(
    color: Color(0xFF253551),
    textStyle: GoogleFonts.outfit(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    elevation: 2.0,
    borderRadius: BorderRadius.circular(8),
  ),
)
```

**New Code**:
```dart
AppButtonEnhanced(
  text: 'Join Game',
  variant: AppButtonVariant.primary,
  size: AppButtonSize.medium,
  onPressed: () => join(),
)
```

**Benefits**:
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

- [x] AppButtonEnhanced - Production ready ✅
- [x] AppButtonExamples - Demo/reference ✅
- [x] AppIconButton - Legacy, works
- [x] AppDropDown - Legacy, works
- [x] AppChoiceChips - Legacy, works
- [x] AppCountController - Legacy, works
- [ ] AppTextField - To be enhanced
- [ ] AppCard - To be created
- [ ] AppDialog - To be enhanced

---

## Resources

- **Button Documentation**: [BUTTON_SYSTEM.md](../../../BUTTON_SYSTEM.md)
- **Typography Guide**: [TYPOGRAPHY_SYSTEM.md](../../../TYPOGRAPHY_SYSTEM.md)
- **Color System**: [COLOR_SYSTEM_MIGRATION.md](../../../COLOR_SYSTEM_MIGRATION.md)
- **Design Tokens**: [design_tokens/README.md](../design_tokens/README.md)

---

**Last Updated**: 2026-01-06
**Design System**: Elevated Country Club Modernism
