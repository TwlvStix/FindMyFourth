# Transition Migration Guide

## Overview

This guide provides the systematic plan for migrating all navigation transitions to use the new `TransitionStandards` constants, eliminating the 8 navigation inconsistencies identified in the discovery phase.

## Identified Inconsistencies

Comprehensive navigation audit identified 8 major issues:

1. **Missing Transitions**: Many navigations (games_list, chat, notifications, profiles) don't specify transitions
2. **Duration Variations**: 200ms, 220ms, 250ms, 300ms across different flows
3. **Modal Return Navigation**: Edit profile uses `pushNamed` to return instead of pop/goNamed
4. **Chat Navigation**: No transitions specified anywhere in chat flow
5. **Onboarding Transitions**: Create profile has transition, subsequent steps don't
6. **Detail View Inconsistency**: Game/chat details lack transitions while modals have them
7. **Platform Inconsistency**: Unspecified transitions use platform defaults (iOS slide, Android fade)
8. **Direct Router Call**: Player list uses `router.go()` instead of `goNamed`

## Standardization Goals

- **95%+ transition coverage**: All key navigation flows use explicit transitions
- **Zero duration variations**: Only 200ms (tabs) and 220ms (modal/detail/dismissal) allowed
- **Semantic consistency**: Modal-like screens use modalTransition, details use detailTransition
- **Eliminate anti-patterns**: No pushNamed for returns, no router.go(), no platform defaults

## Transition Standards Reference

### TransitionStandards.modalTransition
**Type**: Bottom-to-top slide (220ms)
**Use for**: Creating or editing content (create_game, edit_profile, add_players)
**Pattern**: `context.pushNamed('route', extra: {'kTransitionInfoKey': TransitionStandards.modalTransition})`

### TransitionStandards.detailTransition
**Type**: Bottom-to-top slide (220ms)
**Use for**: Drilling into details (game_details, chat_details, user_profile)
**Pattern**: `context.pushNamed('route', extra: {'kTransitionInfoKey': TransitionStandards.detailTransition})`

### TransitionStandards.dismissalTransition
**Type**: Top-to-bottom slide (220ms)
**Use for**: Success screens, confirmation overlays (success_page, success_leave)
**Pattern**: `context.pushNamed('route', extra: {'kTransitionInfoKey': TransitionStandards.dismissalTransition})`

### TransitionStandards.tabTransition
**Type**: Fade (200ms)
**Use for**: Tab-level navigation, sibling screens at same hierarchy
**Pattern**: `context.goNamed('route', extra: {'kTransitionInfoKey': TransitionStandards.tabTransition})`

### TransitionStandards.noTransition
**Type**: Instant (no animation)
**Use for**: Deep links, auth redirects, programmatic navigation
**Pattern**: `context.goNamed('route', extra: {'kTransitionInfoKey': TransitionStandards.noTransition})`

## Before/After Examples

### Example 1: Missing transitions (games_list → game_details)

**Before** (Platform default - inconsistent):
```dart
context.pushNamed(
  GameJoinedDetailedWidget.routeName,
  queryParameters: {
    'gameRef': serializeParam(gameRef, ParamType.DocumentReference),
  },
);
```

**After** (Explicit detailTransition):
```dart
context.pushNamed(
  GameJoinedDetailedWidget.routeName,
  queryParameters: {
    'gameRef': serializeParam(gameRef, ParamType.DocumentReference),
  },
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionStandards.detailTransition,
  },
);
```

### Example 2: Modal navigation (create_game)

**Before** (Already has transition, but ensure consistency):
```dart
context.pushNamed(
  'success_page',
  extra: <String, dynamic>{
    'gameRef': gamesRecordReference,
    kTransitionInfoKey: TransitionInfo(
      hasTransition: true,
      transitionType: PageTransitionType.bottomToTop,
      duration: Duration(milliseconds: 220),
    ),
  },
);
```

**After** (Use standard constant):
```dart
context.pushNamed(
  'success_page',
  extra: <String, dynamic>{
    'gameRef': gamesRecordReference,
    kTransitionInfoKey: TransitionStandards.modalTransition,
  },
);
```

### Example 3: Success screen dismissal

**Before** (Already correct, but verify):
```dart
context.pushNamed(
  'success_page',
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionInfo(
      hasTransition: true,
      transitionType: PageTransitionType.topToBottom,
      duration: Duration(milliseconds: 220),
    ),
  },
);
```

**After** (Use standard constant):
```dart
context.pushNamed(
  'success_page',
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionStandards.dismissalTransition,
  },
);
```

### Example 4: Tab navigation

**Before** (Already using fade, but ensure 200ms):
```dart
context.goNamed(
  'profile_tab',
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionInfo(
      hasTransition: true,
      transitionType: PageTransitionType.fade,
      duration: Duration(milliseconds: 200),
    ),
  },
);
```

**After** (Use standard constant):
```dart
context.goNamed(
  'profile_tab',
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionStandards.tabTransition,
  },
);
```

### Example 5: Post-action navigation with goNamed (edit_profile return fix)

**Before** (ANTI-PATTERN - using pushNamed to return):
```dart
context.pushNamed(
  'main_profile',
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionInfo(
      hasTransition: true,
      transitionType: PageTransitionType.bottomToTop,
      duration: Duration(milliseconds: 220),
    ),
  },
);
```

**After** (Use goNamed or pop instead):
```dart
// Option 1: Use pop if just going back
context.pop();

// Option 2: Use goNamed if replacing navigation stack
context.goNamed(
  'main_profile',
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionStandards.tabTransition, // Fade for lateral move
  },
);
```

## File-by-File Migration Checklist

### Plan 05-02: Game & Auth Flows (7 screens)

#### games_list_widget.dart
- [ ] **Line ~XX**: Add `detailTransition` to game card tap navigation
  ```dart
  // Navigate to game_joined_detailed
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionStandards.detailTransition,
  }
  ```
- [ ] **Line ~XX**: Add `detailTransition` to available game tap navigation
  ```dart
  // Navigate to join_game_detailed
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionStandards.detailTransition,
  }
  ```

#### create_game_widget.dart
- [ ] **Line ~491**: Replace inline `TransitionInfo` with `TransitionStandards.modalTransition`
  ```dart
  // Navigation to success_page after game creation
  kTransitionInfoKey: TransitionStandards.modalTransition,
  ```
- [ ] **Line ~XX**: Verify return navigation uses `pop()` or `goNamed()`, not `pushNamed()`

#### join_game_detailed_widget.dart
- [ ] **Line ~XX**: Add `detailTransition` to player profile navigation
  ```dart
  // Navigate to profile_user when tapping player
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionStandards.detailTransition,
  }
  ```

#### game_joined_detailed_widget.dart
- [ ] **Line ~XX**: Add `detailTransition` to chat navigation
  ```dart
  // Navigate to chat screen
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionStandards.detailTransition,
  }
  ```
- [ ] **Line ~XX**: Add `detailTransition` to player profile navigation (2 instances)
  ```dart
  // Navigate to profile_user for organizer and players
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionStandards.detailTransition,
  }
  ```

#### recover_password_widget.dart
- [ ] **Line ~XX**: Add transition to sign_in navigation
  ```dart
  // Navigate back to sign_in after password reset
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionStandards.modalTransition, // or tabTransition
  }
  ```

#### vibe_onboarding_widget.dart
- [ ] **Line ~XX**: Add transition to post-onboarding navigation (2 instances)
  ```dart
  // Navigate after vibe selection
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionStandards.modalTransition,
  }
  ```

#### progressive_onboarding_widget.dart
- [ ] **Line ~XX**: Add transitions to onboarding step navigation (2 instances)
  ```dart
  // Navigate between onboarding steps
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionStandards.modalTransition,
  }
  ```

### Plan 05-03: Chat & Profile Flows (5 screens)

#### chat_widget.dart
- [ ] **Line ~XX**: Add `detailTransition` to chat_details navigation
  ```dart
  // Navigate to game_chat_details
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionStandards.detailTransition,
  }
  ```

#### golfers_widget.dart
- [ ] **Line ~XX**: Add `detailTransition` to chat navigation
  ```dart
  // Navigate to chat from golfer tap
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionStandards.detailTransition,
  }
  ```
- [ ] **Line ~XX**: Add `detailTransition` to profile navigation
  ```dart
  // Navigate to profile_user from golfer tap
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionStandards.detailTransition,
  }
  ```

#### profile_user_firebase_widget.dart
- [ ] **Line ~XX**: Add `detailTransition` to chat navigation
  ```dart
  // Navigate to chat from profile
  extra: <String, dynamic>{
    kTransitionInfoKey: TransitionStandards.detailTransition,
  }
  ```

#### edit_profile_widget.dart
- [ ] **Line ~XX**: Fix return navigation (ANTI-PATTERN)
  ```dart
  // BEFORE: context.pushNamed('main_profile', ...)
  // AFTER: context.pop() or context.goNamed('main_profile', extra: {kTransitionInfoKey: TransitionStandards.tabTransition})
  ```
- [ ] **Line ~XX**: Ensure modal entry uses `modalTransition` if pushed from profile

#### main_profile_widget.dart
- [ ] **Line ~XX**: Verify fade transitions are consistent with `tabTransition`
  ```dart
  // Tab switching between profile sections
  kTransitionInfoKey: TransitionStandards.tabTransition,
  ```

## Anti-Patterns to Fix

### ❌ Anti-Pattern 1: Navigation without transition
```dart
// BAD
context.pushNamed('game_details');

// GOOD
context.pushNamed('game_details', extra: {kTransitionInfoKey: TransitionStandards.detailTransition});
```

### ❌ Anti-Pattern 2: Inline TransitionInfo with varying durations
```dart
// BAD
kTransitionInfoKey: TransitionInfo(
  hasTransition: true,
  transitionType: PageTransitionType.bottomToTop,
  duration: Duration(milliseconds: 250), // Non-standard duration
)

// GOOD
kTransitionInfoKey: TransitionStandards.modalTransition // 220ms standard
```

### ❌ Anti-Pattern 3: Using pushNamed to return from modals
```dart
// BAD
context.pushNamed('main_profile', ...); // Creates navigation stack bloat

// GOOD
context.pop(); // Returns to previous screen
// OR
context.goNamed('main_profile', ...); // Replaces current route
```

### ❌ Anti-Pattern 4: router.go() instead of context.goNamed
```dart
// BAD
router.go('/game_details'); // Bypasses transition system

// GOOD
context.goNamed('game_details', extra: {kTransitionInfoKey: TransitionStandards.detailTransition});
```

### ❌ Anti-Pattern 5: Mixing transition durations
```dart
// BAD - Multiple different durations in same flow
Screen 1: Duration(milliseconds: 200)
Screen 2: Duration(milliseconds: 220)
Screen 3: Duration(milliseconds: 300)

// GOOD - Consistent durations by semantic type
Modal screens: 220ms (modalTransition)
Detail views: 220ms (detailTransition)
Tab navigation: 200ms (tabTransition)
```

## Verification Commands

### Count transition usages by type
```bash
# Count modal transitions
grep -r "TransitionStandards.modalTransition" lib --include="*.dart" | wc -l

# Count detail transitions
grep -r "TransitionStandards.detailTransition" lib --include="*.dart" | wc -l

# Count dismissal transitions
grep -r "TransitionStandards.dismissalTransition" lib --include="*.dart" | wc -l

# Count tab transitions
grep -r "TransitionStandards.tabTransition" lib --include="*.dart" | wc -l
```

### Find remaining unspecified transitions
```bash
# Find pushNamed/goNamed without kTransitionInfoKey
grep -r "context.pushNamed\|context.goNamed" lib --include="*.dart" -A 5 | grep -v "kTransitionInfoKey" | wc -l
```

### Find inline TransitionInfo instances (should be replaced with standards)
```bash
# Find inline TransitionInfo constructors
grep -r "TransitionInfo(" lib --include="*.dart" | grep -v "TransitionStandards" | wc -l
```

### Find duration variations
```bash
# Find non-standard durations (should only be 200ms or 220ms)
grep -r "Duration(milliseconds:" lib --include="*.dart" | grep -E "milliseconds: ((?!200|220)\d+)"
```

### Find router.go() anti-pattern
```bash
# Find direct router.go() calls (should use context.goNamed)
grep -r "router.go(" lib --include="*.dart" | wc -l
```

### Find pushNamed in screens that should use pop/goNamed
```bash
# Check edit_profile for pushNamed to main_profile (anti-pattern)
grep -n "pushNamed.*main_profile" lib/profile/edit_profile/edit_profile_widget.dart
```

## Success Metrics

### Quantitative Goals
- **95%+ transition coverage**: 19+ of 20 key navigation flows use explicit transitions
- **Zero duration variations**: Only 200ms and 220ms durations in codebase
- **100% modal consistency**: All create/edit screens use modalTransition
- **100% detail consistency**: All detail views use detailTransition
- **Zero anti-patterns**: No pushNamed returns, no router.go(), no platform defaults

### Baseline (Before Migration)
- `bottomToTop`: 19 occurrences (most common)
- `topToBottom`: 2 occurrences (success screens)
- `fade`: 4 occurrences (profile tabs)
- No transition: Many instances (platform default)
- Duration variations: 200ms, 220ms, 250ms, 300ms

### Target (After Plans 05-02 and 05-03)
- `TransitionStandards.modalTransition`: 15+ usages
- `TransitionStandards.detailTransition`: 20+ usages
- `TransitionStandards.dismissalTransition`: 2+ usages
- `TransitionStandards.tabTransition`: 4+ usages
- Inline `TransitionInfo(...)`: 0 usages
- Duration variations: 0 (only 200ms/220ms via standards)
- Platform default navigations in key flows: 0

## Migration Strategy

### Phase 1: Plan 05-01 (Foundation) ✅
- Create `TransitionStandards` constants
- Export from `app_router.dart`
- Document usage patterns and anti-patterns

### Phase 2: Plan 05-02 (Game & Auth Flows)
- Migrate 7 screens: games_list, create_game, join_game_detailed, game_joined_detailed, recover_password, vibe_onboarding, progressive_onboarding
- Fix anti-patterns in game creation and auth flows
- Verify 100% coverage in game navigation

### Phase 3: Plan 05-03 (Chat & Profile Flows)
- Migrate 5 screens: chat, golfers, profile_user_firebase, edit_profile, main_profile
- Fix edit_profile pushNamed anti-pattern
- Verify 100% coverage in chat and profile navigation

### Phase 4: Verification
- Run all verification commands
- Confirm zero anti-patterns remain
- Measure success metrics vs targets

## Common Pitfalls

1. **Forgetting to wrap extra data**: If navigation already has `extra` data (like `gameRef`), merge it with `kTransitionInfoKey`:
   ```dart
   extra: <String, dynamic>{
     'gameRef': gameRef,
     kTransitionInfoKey: TransitionStandards.detailTransition,
   }
   ```

2. **Wrong transition type**: Modal-like screens (create/edit) use `modalTransition`, detail views use `detailTransition`. Don't confuse them.

3. **Using pushNamed after save**: Edit screens should use `pop()` or `goNamed()`, not `pushNamed()` to return.

4. **Forgetting imports**: Screens need to import `app_router.dart` to access `TransitionStandards`:
   ```dart
   import '/core/navigation/app_router.dart';
   ```

5. **Breaking existing transitions**: Some screens already have correct transitions. Replace inline `TransitionInfo(...)` with standards, don't remove transitions entirely.

## Testing Checklist

After migration, manually verify:
- [ ] All game list → game detail navigations animate smoothly (bottom-to-top)
- [ ] Create game flow animates consistently (bottom-to-top modal feel)
- [ ] Success screens dismiss with top-to-bottom animation
- [ ] Profile tab switches use fade transition
- [ ] Chat navigations animate smoothly (bottom-to-top detail feel)
- [ ] Edit profile returns to profile (no duplicate screens in stack)
- [ ] Auth flows animate consistently (bottom-to-top modal feel)
- [ ] No jarring platform-specific defaults (iOS slide vs Android fade)

## Notes

- Plans 05-02 and 05-03 will execute these migrations systematically
- Each file should be migrated atomically with verification
- Commit each screen migration individually for easy rollback
- Run `dart analyze` after each file to catch errors early
- Manually test navigation flows after migration to verify UX
