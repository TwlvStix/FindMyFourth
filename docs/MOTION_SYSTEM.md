# Premium Motion System

## Overview

This app uses a standardized premium motion system for consistent, accessible animations throughout the application. All animation durations, curves, and scales are defined in `/lib/core/motion/` for single source of truth enforcement.

---

## Quick Reference

| Use Case | Duration | Curve | Scale | Notes |
|----------|----------|-------|-------|-------|
| Route push | 200ms enter, 170ms exit | easeOutCubic/easeInCubic | 0.985→1.0 (optional) | Fade only, no slides |
| Route pop | 170ms | easeInCubic | None | Faster than push for snappiness |
| Dialog | 200ms enter, 170ms exit | easeOutCubic/easeInCubic | 0.97→1.0 | Fade + scale for depth |
| Bottom sheet | 260ms enter, 220ms exit | easeOutCubic/easeInCubic | None | Slide up only |
| Backdrop | 160ms | easeOutCubic | None | Behind dialogs/sheets |
| Content reveal | 160ms | easeOutCubic | None | In-page fades |
| Micro-interaction | 100ms | easeOutCubic | Varies | Buttons, toggles, cards |
| Stagger delay | +24ms per item | - | - | Max 8 items, first load only |
| Bottom nav tabs | Instant | - | None | No animation |
| Tab content | Instant | - | None | No crossfade |

---

## Usage

### Routes

Use `TransitionStandards` constants for all navigation:

```dart
// Modal-like screens (create, edit, add)
context.pushNamed(
  'create_game',
  extra: {'kTransitionInfoKey': TransitionStandards.modalTransition},
);

// Detail views (drilling deeper)
context.pushNamed(
  'game_details',
  extra: {'kTransitionInfoKey': TransitionStandards.detailTransition},
);

// Success/dismissal screens
context.pushNamed(
  'success_page',
  extra: {'kTransitionInfoKey': TransitionStandards.dismissalTransition},
);

// Tab-level navigation
context.goNamed(
  'profile_tab',
  extra: {'kTransitionInfoKey': TransitionStandards.tabTransition},
);

// No animation (deep links, auth redirects)
context.goNamed(
  'games_list',
  extra: {'kTransitionInfoKey': TransitionStandards.noTransition},
);
```

Or use convenience extension methods:

```dart
context.pushModal('create_game');
context.pushDetail('game_details');
```

### Dialogs

**ALWAYS use `showAppDialog()` instead of `showDialog()`:**

```dart
import '/core/motion/motion_helpers.dart';

final result = await showAppDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Confirm'),
    content: Text('Are you sure?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text('Cancel'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text('Confirm'),
      ),
    ],
  ),
);
```

**Benefits:**
- Enforced 200ms enter, 170ms exit
- Enforced scale 0.97→1.0
- Enforced backdrop fade 160ms
- Automatic reduced motion support

### Bottom Sheets

**ALWAYS use `showAppBottomSheet()` instead of `showModalBottomSheet()`:**

```dart
import '/core/motion/motion_helpers.dart';

final filters = await showAppBottomSheet<FriendFilters>(
  context: context,
  isScrollControlled: true,
  builder: (context) => FriendFilterBottomSheet(),
);
```

**Benefits:**
- Enforced 260ms enter, 220ms exit
- Automatic reduced motion support
- Consistent slide-up animation

### Micro-Interactions (Buttons, Toggles, Cards)

```dart
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';

// Animation controller
AnimationController(
  duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
  vsync: this,
);

// Curved animation
CurvedAnimation(
  parent: controller,
  curve: MotionTokens.curveEnter,
  reverseCurve: MotionTokens.curveExit, // For reversible animations
);

// AnimatedContainer
AnimatedContainer(
  duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
  curve: MotionTokens.curveEnter,
  // ... other properties
);
```

### Content Reveal (In-Page Animations)

```dart
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';

AnimationController(
  duration: ReducedMotionService.adjust(MotionTokens.contentReveal),
  vsync: this,
);
```

### Stagger Animations

**Rules:**
- ONLY on first appearance of a screen/list
- NO stagger on scroll/pagination/filter/sort updates
- Max 8 items staggered
- 24ms delay between items

```dart
import 'dart:math';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';

// Setup stagger controller
_fadeController = AnimationController(
  duration: ReducedMotionService.adjust(
    MotionTokens.contentReveal + (MotionTokens.staggerDelay * min(items.length, MotionTokens.staggerMaxItems)),
  ),
  vsync: this,
);

// Create staggered animations (if reduced motion allows)
_fadeAnimations = ReducedMotionService.shouldStagger
    ? List.generate(
        min(items.length, MotionTokens.staggerMaxItems),
        (index) {
          final totalMs = _fadeController.duration!.inMilliseconds.toDouble();
          final staggerMs = MotionTokens.staggerDelay.inMilliseconds.toDouble();
          final revealMs = MotionTokens.contentReveal.inMilliseconds.toDouble();

          return Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _fadeController,
              curve: Interval(
                (index * staggerMs) / totalMs,
                (revealMs + (index * staggerMs)) / totalMs,
                curve: MotionTokens.curveEnter,
              ),
            ),
          );
        },
      )
    : List.generate(
        items.length,
        // No stagger in reduced motion - all fade in together
        (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _fadeController, curve: MotionTokens.curveEnter),
        ),
      );

// For lists with >8 items: first 8 stagger, rest appear together
if (items.length > MotionTokens.staggerMaxItems) {
  // Items 0-7 get stagger animations (created above)
  // Items 8+ use the last animation (item 7's timing)
}
```

---

## Reduced Motion Support

### Platform Detection

The app automatically respects the platform's reduced motion setting:
- **iOS:** Settings > Accessibility > Motion > Reduce Motion
- **Android:** Settings > Accessibility > Remove animations

### Adjustments Applied

When reduced motion is enabled:
- All durations reduced by ~35% (faster completion)
- All scale animations disabled (routes, dialogs)
- All stagger animations disabled (instant fade-in)
- Fades still work (essential for UI readability)

### Testing

**iOS Simulator:**
1. Settings > Accessibility > Motion
2. Enable "Reduce Motion"
3. Restart app
4. Verify: Faster animations, no scale, no stagger

**Android Emulator:**
1. Settings > Accessibility
2. Enable "Remove animations"
3. Restart app
4. Verify: Faster animations, no scale, no stagger

**Widget Tests:**
```dart
testWidgets('respects reduced motion', (tester) async {
  tester.platformDispatcher.accessibilityFeatures =
    FakeAccessibilityFeatures(reduceMotion: true);

  await tester.pumpWidget(MyApp());
  await tester.tap(find.byType(AppButtonEnhanced));
  await tester.pump(Duration(milliseconds: 65)); // 100ms * 0.65

  expect(animationComplete, isTrue);
});
```

---

## Anti-Patterns

### ❌ Hardcoded Durations

```dart
// WRONG
Duration(milliseconds: 200)
const Duration(milliseconds: 150)

// CORRECT
MotionTokens.routeEnter
ReducedMotionService.adjust(MotionTokens.microInteraction)
```

### ❌ Wrong Curves

```dart
// WRONG
Curves.easeOut
Curves.easeInOut
Curves.linear

// CORRECT
MotionTokens.curveEnter  // For appearing content
MotionTokens.curveExit   // For disappearing content
```

### ❌ Direct Flutter Functions

```dart
// WRONG
showDialog(context: context, builder: ...)
showModalBottomSheet(context: context, builder: ...)

// CORRECT
showAppDialog(context: context, builder: ...)
showAppBottomSheet(context: context, builder: ...)
```

### ❌ Stagger on Scroll/Filter

```dart
// WRONG - Stagger animates on every filter change
if (filteredList.isNotEmpty) {
  _startStaggerAnimation(); // Don't do this!
}

// CORRECT - Stagger only on initial load
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _fadeController.forward(); // One-time stagger
  });
}
```

### ❌ Slide Transitions for Routes

```dart
// WRONG
PageTransitionType.bottomToTop
PageTransitionType.topToBottom
PageTransitionType.leftToRight

// CORRECT
PageTransitionType.fade  // All routes use fade
```

---

## PR Review Checklist

Before approving code with animations/transitions:

- [ ] **All durations** reference `MotionTokens` (no hardcoded milliseconds)
- [ ] **All curves** use `MotionTokens.curveEnter` or `MotionTokens.curveExit`
- [ ] **Route transitions** use `TransitionStandards` constants
- [ ] **Dialogs** use `showAppDialog()`, not `showDialog()`
- [ ] **Bottom sheets** use `showAppBottomSheet()`, not `showModalBottomSheet()`
- [ ] **Stagger limited** to 8 items max, only on first appearance
- [ ] **Reduced motion tested** (enable in simulator/emulator settings)
- [ ] **No slide transitions** for routes (only fade allowed)
- [ ] **Micro-interactions** are 100ms (not 150ms or 200ms)

---

## Architecture

### Files

```
lib/core/motion/
├── motion_tokens.dart          # Single source of truth (durations, curves, scales)
├── reduced_motion.dart         # Platform detection + adjustments
└── motion_helpers.dart         # showAppDialog(), showAppBottomSheet()

lib/core/navigation/
├── app_router.dart             # TransitionInfo class (enter/exit durations)
└── transition_standards.dart   # Semantic transition constants
```

### Motion Tokens

All motion values are defined as constants in `MotionTokens`:

- **Durations:** routeEnter, routeExit, dialogEnter, dialogExit, bottomSheetEnter, bottomSheetExit, backdropFade, contentReveal, microInteraction
- **Curves:** curveEnter (easeOutCubic), curveExit (easeInCubic)
- **Scales:** pageScaleStart (0.985), pageScaleEnd (1.0), dialogScaleStart (0.97), dialogScaleEnd (1.0)
- **Stagger:** staggerDelay (24ms), staggerMaxItems (8)
- **Reduced Motion:** reducedMotionDurationScale (0.65)

### Reduced Motion Service

Static utility class that:
- Detects platform reduced motion preference via `AccessibilityFeatures`
- Applies 35% duration reduction when enabled
- Provides `shouldStagger` and `shouldScale` flags
- Zero boilerplate - works everywhere without DI

### Motion Helpers

Wrapper functions that enforce standards:
- `showAppDialog()`: Fade + scale 0.97→1.0, 200ms/170ms, backdrop 160ms
- `showAppBottomSheet()`: Slide up 260ms/220ms
- Impossible to bypass motion standards when using these helpers

---

## Benefits

✅ **Consistency:** All animations use same durations and curves
✅ **Accessibility:** Automatic reduced motion support
✅ **Performance:** Zero runtime overhead (all const values)
✅ **Type Safety:** Compile-time checking prevents errors
✅ **Maintainability:** Single source of truth prevents drift
✅ **Premium Feel:** Snappier micro-interactions, smooth transitions
✅ **Enforcement:** Helper functions make bypassing standards difficult

---

## Migration from Old System

### Before

```dart
// Hardcoded values everywhere
AnimationController(duration: Duration(milliseconds: 150), vsync: this);
AnimatedContainer(duration: Duration(milliseconds: 200), curve: Curves.easeOut);
showDialog(context: context, builder: ...);
```

### After

```dart
// Single source of truth
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/motion/motion_helpers.dart';

AnimationController(
  duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
  vsync: this,
);
AnimatedContainer(
  duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
  curve: MotionTokens.curveEnter,
);
showAppDialog(context: context, builder: ...);
```

---

## Key Changes from Previous System

- **Routes:** Slide → Fade (bottomToTop/topToBottom → fade)
- **Durations:** 220ms/250ms → 200ms enter, 170ms exit (split)
- **Bottom Nav:** 500ms → Instant (Duration.zero)
- **Tab Content:** Platform crossfade → Instant (Duration.zero)
- **Stagger:** 800ms → 232ms (3x faster)
- **Micro-interactions:** 150-200ms → 100ms (1.5-2x faster)
- **Curves:** Mixed (easeOut/easeInOut) → Consistent (easeOutCubic/easeInCubic)
- **Dialogs/Sheets:** Direct Flutter → Enforced helpers
- **Reduced Motion:** None → Full support

The app now feels **snappier, more consistent, and more premium** while maintaining full accessibility support.
