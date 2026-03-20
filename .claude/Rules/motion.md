# Motion Rules

## Reusable Animation Widgets

New stagger-entrance and press-to-scale animations MUST use the reusable widgets in `lib/core/motion/`:

### `AnimatedEntrance` (`animated_entrance.dart`)
Use for fade + slide-from-bottom entrance animations. Checks `ReducedMotionService` internally.

```dart
AnimatedEntrance(
  animationIndex: i,  // stagger position (clamped to staggerMaxItems)
  child: MyWidget(),
)
```

**Do NOT** create manual `AnimationController` + `FadeTransition` + `SlideTransition` patterns for entrance animations. Use `AnimatedEntrance` instead.

### `AnimatedScaleTap` (`animated_scale_tap.dart`)
Use for press-to-scale feedback. Checks `ReducedMotionService.shouldScale` internally.

```dart
AnimatedScaleTap(
  onTap: () => handleTap(),
  scaleFactor: MotionTokens.pressScaleSubtle,  // 0.982 for cards
  child: MyCard(),
)
```

**Do NOT** create manual `_isPressed` + `setState` + `Matrix4` + `AnimatedContainer` patterns for press feedback. Use `AnimatedScaleTap` instead.

### Scale Tokens
- `MotionTokens.pressScale` (0.96) - standard interactive elements
- `MotionTokens.pressScaleSubtle` (0.982) - larger card-level elements

## Reduced Motion

All animations must respect `ReducedMotionService`:
- `AnimatedEntrance` and `AnimatedScaleTap` handle this automatically
- For custom animations: check `ReducedMotionService.isEnabled`, `.shouldScale`, `.shouldStagger`
- Use `ReducedMotionService.adjust(duration)` to scale durations
- `buildAnimatedSection()` in `animation_helpers.dart` already handles reduced motion

## Known Debt (Not Yet Migrated)

These files still use manual animation patterns and should be migrated when next touched:
- `join_game_detailed_widget.dart` - manual stagger entrance
- `cinematic_foursome_toast.dart` - custom animation (intentional)
- `cinematic_notification_banner.dart` - custom animation (intentional)
