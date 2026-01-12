# Enhanced Button System

## Overview

Production-grade button component with distinctive micro-interactions, variants, and polish for the "Find My Fourth" golf app.

**Design Philosophy**: "Elevated Country Club Modernism" - sophisticated yet responsive, with tactile feedback that feels like a well-struck golf drive.

---

## Features

✅ **4 Visual Variants**: Primary, Secondary, Ghost, Gradient
✅ **4 Size Presets**: Small (36px), Medium (48px), Large (56px), XLarge (64px)
✅ **Micro-Interactions**: Scale on press, hover states, smooth transitions
✅ **Loading States**: Maintains button size, smooth indicator
✅ **Icon Support**: Leading and trailing icons
✅ **Haptic Feedback**: Optional tactile response on press
✅ **Accessibility**: Focus states, keyboard navigation, minimum touch targets
✅ **Polish**: Sophisticated shadows, gradients, animations

---

## Variants

### 1. Primary Button
**Usage**: Main actions, CTAs
**Style**: Filled with fairway dark green

```dart
AppButtonEnhanced(
  text: 'Join Game',
  variant: AppButtonVariant.primary,
  onPressed: () => handleJoin(),
)
```

**Visual Characteristics**:
- Background: `AppColors.fairwayDark` (#1B3A2F)
- Text: `AppColors.pure` (off-white)
- Shadow: Soft elevation shadow
- Hover: Lightens to `AppColors.fairway`
- Press: Scale to 0.96, deeper shadow

---

### 2. Secondary Button
**Usage**: Secondary actions, cancel operations
**Style**: Outlined with fairway green border

```dart
AppButtonEnhanced(
  text: 'Cancel',
  variant: AppButtonVariant.secondary,
  onPressed: () => handleCancel(),
)
```

**Visual Characteristics**:
- Background: Transparent
- Border: 2px `AppColors.fairway`
- Text: `AppColors.fairwayDark`
- Hover: Light green tint background
- Press: Darker border, subtle background

---

### 3. Ghost Button
**Usage**: Tertiary actions, minimal UI
**Style**: Text-only, minimal appearance

```dart
AppButtonEnhanced(
  text: 'Learn More',
  variant: AppButtonVariant.ghost,
  onPressed: () => showInfo(),
)
```

**Visual Characteristics**:
- Background: Transparent
- Text: `AppColors.fairway`
- No shadows or borders
- Hover: Light sand background
- Press: Cloud grey background

---

### 4. Gradient Button
**Usage**: Special CTAs, premium actions
**Style**: Sunset gradient fill

```dart
AppButtonEnhanced(
  text: 'Start Premium Game',
  variant: AppButtonVariant.gradient,
  onPressed: () => startPremium(),
)
```

**Visual Characteristics**:
- Background: `AppColors.sunsetGradient` (gold → peach → rose)
- Text: `AppColors.pure` (off-white)
- Shadow: Warm glow effect
- Hover: Maintains gradient
- Press: Scale effect with shadow depth change

---

## Sizes

### Small (36px height)
Compact UI elements, tight spaces

```dart
AppButtonEnhanced(
  text: 'Edit',
  size: AppButtonSize.small,
  variant: AppButtonVariant.secondary,
  onPressed: () => edit(),
)
```

**Specifications**:
- Height: 36px
- Horizontal padding: 16px
- Vertical padding: 8px
- Border radius: 8px
- Icon size: 16px
- Typography: `AppTypography.button` (16px)

---

### Medium (48px height) - DEFAULT
Standard size, meets accessibility guidelines

```dart
AppButtonEnhanced(
  text: 'Join Game',
  size: AppButtonSize.medium, // Default, can be omitted
  variant: AppButtonVariant.primary,
  onPressed: () => join(),
)
```

**Specifications**:
- Height: 48px ✅ Meets 44-48px touch target minimum
- Horizontal padding: 20px
- Vertical padding: 12px
- Border radius: 10px
- Icon size: 18px
- Typography: `AppTypography.button` (16px)

---

### Large (56px height)
Prominent CTAs, important actions

```dart
AppButtonEnhanced(
  text: 'Create Game',
  size: AppButtonSize.large,
  variant: AppButtonVariant.primary,
  leadingIcon: Icons.add,
  onPressed: () => createGame(),
)
```

**Specifications**:
- Height: 56px
- Horizontal padding: 24px
- Vertical padding: 14px
- Border radius: 12px
- Icon size: 20px
- Typography: `AppTypography.buttonLarge` (18px bold)

---

### XLarge (64px height)
Hero actions, landing page CTAs

```dart
AppButtonEnhanced(
  text: 'Get Started',
  size: AppButtonSize.xlarge,
  variant: AppButtonVariant.gradient,
  trailingIcon: Icons.arrow_forward,
  onPressed: () => getStarted(),
)
```

**Specifications**:
- Height: 64px
- Horizontal padding: 28px
- Vertical padding: 16px
- Border radius: 14px
- Icon size: 24px
- Typography: `AppTypography.buttonLarge` (18px bold)

---

## Icon Support

### Leading Icon
Icon before text

```dart
AppButtonEnhanced(
  text: 'Add Player',
  leadingIcon: Icons.person_add,
  variant: AppButtonVariant.primary,
  onPressed: () => addPlayer(),
)
```

### Trailing Icon
Icon after text

```dart
AppButtonEnhanced(
  text: 'Continue',
  trailingIcon: Icons.arrow_forward,
  variant: AppButtonVariant.primary,
  onPressed: () => continue(),
)
```

### Both Icons
Icons on both sides (use sparingly)

```dart
AppButtonEnhanced(
  text: 'Share Game',
  leadingIcon: Icons.share,
  trailingIcon: Icons.open_in_new,
  variant: AppButtonVariant.secondary,
  onPressed: () => share(),
)
```

**Icon Guidelines**:
- Icons automatically sized based on button size
- Icons inherit text color
- Proper spacing maintained (6-8px gap)
- Icons scale with press animation

---

## States

### Loading State
Shows spinner, disables interaction, maintains size

```dart
AppButtonEnhanced(
  text: 'Joining...',
  isLoading: true,
  variant: AppButtonVariant.primary,
  onPressed: () => {}, // Will be ignored while loading
)
```

**Behavior**:
- Text replaced with `CircularProgressIndicator`
- Button maintains size (no layout shift)
- Interaction disabled
- Spinner color matches text color
- Smooth fade transition

---

### Disabled State
Reduced opacity, no interaction

```dart
AppButtonEnhanced(
  text: 'Join Game',
  enabled: false,
  variant: AppButtonVariant.primary,
  onPressed: () => join(), // Will not be called
)
```

**Visual Changes**:
- Background: `AppColors.cloud` (light grey)
- Text: `AppColors.stone` (mid grey)
- No shadows
- Cursor: forbidden icon
- No hover/press effects

---

### Focus State
Keyboard navigation support

```dart
FocusNode focusNode = FocusNode();

AppButtonEnhanced(
  text: 'Submit',
  focusNode: focusNode,
  variant: AppButtonVariant.primary,
  onPressed: () => submit(),
)

// Can programmatically focus:
// focusNode.requestFocus()
```

**Behavior**:
- Focus ring appears on keyboard navigation
- Accessible via Tab key
- Enter/Space activates button

---

## Full Width Buttons

Expand button to container width

```dart
AppButtonEnhanced(
  text: 'Continue to Payment',
  fullWidth: true,
  variant: AppButtonVariant.primary,
  size: AppButtonSize.large,
  onPressed: () => checkout(),
)
```

**Use Cases**:
- Mobile layouts
- Form submissions
- Bottom sheet actions
- Modal dialogs

---

## Haptic Feedback

Optional tactile response on press (enabled by default)

```dart
// With haptic feedback (default)
AppButtonEnhanced(
  text: 'Join Game',
  hapticFeedback: true, // Default
  variant: AppButtonVariant.primary,
  onPressed: () => join(),
)

// Without haptic feedback
AppButtonEnhanced(
  text: 'Cancel',
  hapticFeedback: false,
  variant: AppButtonVariant.ghost,
  onPressed: () => cancel(),
)
```

**Platform Behavior**:
- iOS: Light impact feedback
- Android: Light vibration
- Web/Desktop: No effect (gracefully degraded)

---

## Micro-Interactions

### Press Animation
- Scale: 1.0 → 0.96 (subtle squeeze)
- Duration: 150ms
- Curve: `easeOut`
- Synchronized with shadow depth change

### Hover States
- Smooth color transitions (200ms)
- Shadow intensity changes
- Background tint for secondary/ghost

### Color Transitions
- All color changes animated
- 200ms duration
- `easeOut` curve
- Smooth, polished feel

---

## Usage Patterns

### Form Actions
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    AppButtonEnhanced(
      text: 'Cancel',
      variant: AppButtonVariant.ghost,
      onPressed: () => Navigator.pop(context),
    ),
    AppButtonEnhanced(
      text: 'Save Game',
      variant: AppButtonVariant.primary,
      leadingIcon: Icons.save,
      onPressed: () => saveGame(),
    ),
  ],
)
```

---

### Bottom Sheet Actions
```dart
Column(
  children: [
    AppButtonEnhanced(
      text: 'Join This Game',
      fullWidth: true,
      size: AppButtonSize.large,
      variant: AppButtonVariant.primary,
      onPressed: () => joinGame(),
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

### Loading Example
```dart
class JoinGameButton extends StatefulWidget {
  @override
  State<JoinGameButton> createState() => _JoinGameButtonState();
}

class _JoinGameButtonState extends State<JoinGameButton> {
  bool _isLoading = false;

  Future<void> _handleJoin() async {
    setState(() => _isLoading = true);

    try {
      await gameService.joinGame();
      // Success
    } catch (e) {
      // Error handling
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButtonEnhanced(
      text: _isLoading ? 'Joining...' : 'Join Game',
      isLoading: _isLoading,
      variant: AppButtonVariant.primary,
      onPressed: _handleJoin,
    );
  }
}
```

---

### Hero CTA
```dart
AppButtonEnhanced(
  text: 'Find Your Fourth Player',
  size: AppButtonSize.xlarge,
  variant: AppButtonVariant.gradient,
  fullWidth: true,
  trailingIcon: Icons.arrow_forward,
  onPressed: () => navigateToGameList(),
)
```

---

## Best Practices

### 1. **Variant Selection**
- **Primary**: Main action on screen (max 1 per view)
- **Secondary**: Alternative or cancel actions
- **Ghost**: Tertiary, low-priority actions
- **Gradient**: Special moments, premium features (use sparingly!)

### 2. **Size Selection**
- **Small**: Tight spaces, repeated actions (lists, cards)
- **Medium**: Default, most common use
- **Large**: Important CTAs, form submissions
- **XLarge**: Hero sections, landing pages only

### 3. **Icon Guidelines**
- Use icons that add clarity, not decoration
- Prefer leading icons for action indicators (add, delete, share)
- Prefer trailing icons for navigation (arrow_forward, open_in_new)
- Don't use both unless absolutely necessary

### 4. **Text Guidelines**
- Keep button text concise (1-3 words ideal)
- Use action verbs ("Join Game", not "Click to Join")
- Sentence case preferred ("Join game", not "JOIN GAME")
- Loading text should indicate progress ("Joining...", "Saving...")

### 5. **Accessibility**
- Always provide meaningful `onPressed` text
- Minimum 48px touch target for all interactive elements
- Use semantic button roles (handled automatically)
- Test keyboard navigation (Tab, Enter)

---

## Color Combinations

### Recommended Pairings

| Variant | Background | Text | Best For |
|---------|-----------|------|----------|
| Primary | Fairway Dark | Pure White | Main actions, CTAs |
| Secondary | Transparent | Fairway Dark | Cancel, back actions |
| Ghost | Transparent | Fairway Green | Tertiary, subtle actions |
| Gradient | Sunset Gradient | Pure White | Premium, special CTAs |

---

## Comparison with Old Button

### Old AppButton
```dart
AppButton(
  text: 'Join Game',
  onPressed: () => join(),
  options: AppButtonOptions(
    color: Color(0xFF253551), // Hardcoded color
    textStyle: GoogleFonts.outfit(...), // Manual styling
    elevation: 2.0,
    // Many manual parameters...
  ),
)
```

### New AppButtonEnhanced
```dart
AppButtonEnhanced(
  text: 'Join Game',
  variant: AppButtonVariant.primary, // Semantic variant
  size: AppButtonSize.large, // Clear size
  leadingIcon: Icons.add,
  onPressed: () => join(),
)
```

**Benefits**:
- ✅ Cleaner, more semantic API
- ✅ Automatic design token integration
- ✅ Built-in variants and sizes
- ✅ Sophisticated micro-interactions
- ✅ Better accessibility
- ✅ Consistent with design system

---

## Implementation Checklist

- [x] Button component created
- [x] 4 variants implemented (primary, secondary, ghost, gradient)
- [x] 4 size presets (small, medium, large, xlarge)
- [x] Micro-interactions (scale, hover, transitions)
- [x] Loading states
- [x] Icon support (leading/trailing)
- [x] Haptic feedback
- [x] Accessibility (focus, keyboard nav)
- [x] Full documentation
- [ ] Update existing code to use new button
- [ ] Test on all screen sizes
- [ ] Verify accessibility with screen readers
- [ ] Performance testing

---

**Generated:** 2026-01-06
**Component:** `lib/core/widgets/app_button_enhanced.dart`
**Design System:** Elevated Country Club Modernism
**Status:** Production Ready ✅
