---
paths: lib/**/*_widget.dart
---
# Widget Rules

## Size Limit
Widget files should target ≤300 lines, with a hard ceiling of 330. Decompose using:
- Extract logical sections into sub-widgets in a `components/` subfolder
- Extract form state and async logic into a ViewModel/Controller class
- The screen-level widget should compose smaller widgets, not contain all logic

**The 300–330 line grace zone:** If a widget lands between 300–330 lines after genuine decomposition (extracting helpers, components, constants), it is compliant — stop there. Do NOT force further reductions.

**Never sacrifice readability to hit the target.** Removing blank lines between logical sections, cramming whitespace, collapsing spacing, or merging unrelated blocks just to shave lines is **prohibited**. The rule targets structural complexity, not formatting. Only pursue further decomposition above 330 lines.

**Legacy exceptions** (tech debt — do NOT increase, only refactor):
- `games_list_widget.dart` (731 lines)
- `join_game_detailed_widget.dart` (678 lines)
- `game_joined_detailed_widget.dart` (654 lines)
- `game_joined_dashboard_content.dart` (647 lines)
- `player_list_section.dart` (470 lines)
- `edit_profile_widget.dart` (366 lines)
- `create_profile_widget.dart` (351 lines)
- `progressive_onboarding_widget.dart` (324 lines)

When modifying these files, either keep line count the same or lower, or extract components to reduce size.

## Component Extraction Naming

When extracting sub-widgets to a `components/` subfolder, use a **feature-specific prefix** to distinguish them from generic reusable widgets:

**Pattern:** `{Feature}{Component}.dart` → `{Feature}{Component}` class

**Examples:**
- `cinematic_onboarding_slide.dart` → `CinematicOnboardingSlide`
- `cinematic_progress_dots.dart` → `CinematicProgressDots`
- `game_joined_player_card.dart` → `GameJoinedPlayerCard`

**Why:** Prevents naming collisions with generic `core/widgets/` components and makes the component's scope immediately clear.

**Contrast with core widgets:** Generic reusable widgets in `lib/core/widgets/` use the `App` prefix:
- `app_button_enhanced.dart` → `AppButtonEnhanced`
- `app_card.dart` → `AppCard`

## Separation of Concerns
- NEVER call Firestore, Firebase Auth, or any backend service directly from a widget
- Data flow is: Widget → Provider → Service → Firestore. No shortcuts.
- Access providers via extensions: `context.gameProvider`, `context.userProvider`

## State Management
- NEVER use empty `setState(() {})`. This rebuilds the entire widget for nothing.
- ALWAYS add `if (!mounted) return;` before any `setState` that follows an `await`
- Prefer Provider/ChangeNotifier for state over local setState when state is shared
- Use `context.select<T, R>()` or `Selector` to minimize rebuild scope

**Multi-await pattern:** When a method has multiple `await` calls, you need a `mounted` check after EACH one that precedes a `setState`:

```dart
// ❌ Wrong — only checks after first await
Future<void> _handleAction() async {
  final result = await _controller.doSomething();
  if (!mounted) return;

  final confirmed = await showAppBottomSheet(...);  // User can dismiss OR widget disposed
  setState(() => _data = confirmed);  // BUG: no mounted check
}

// ✅ Correct — checks after each await
Future<void> _handleAction() async {
  final result = await _controller.doSomething();
  if (!mounted) return;

  final confirmed = await showAppBottomSheet(...);
  if (!mounted) return;  // Check again after second await

  setState(() => _data = confirmed);
}
```

**High-risk awaits** (user can dismiss/navigate during these):
- `showModalBottomSheet` / `showAppBottomSheet`
- `showDialog` / `showPremiumDialog`
- `showDatePicker` / `showTimePicker`
- Any navigation-related future

## AppState Access

AppState is provided via `ChangeNotifierProvider` in main.dart. Access it via Provider, not the singleton:

**Do:**
```dart
// Reading in build (reactive — rebuilds when value changes)
final hideFriends = context.select<AppState, bool>((s) => s.hideFriendsOnlyGames);

// Writing in callbacks (non-reactive read)
context.read<AppState>().hideFriendsOnlyGames = newValue;
```

**Don't:**
```dart
// Singleton access bypasses Provider reactivity
AppState().hideFriendsOnlyGames = newValue;
```

### Toggle Callbacks

When toggling boolean state in a callback, read the fresh current value at tap time — don't use a captured build-time variable:

**Do:**
```dart
onTap: () {
  final appState = context.read<AppState>();
  appState.hideFriendsOnlyGames = !appState.hideFriendsOnlyGames;
},
```

**Don't:**
```dart
// hideFriendsOnly was captured at build time — may be stale if rapid taps occur
onTap: () {
  context.read<AppState>().hideFriendsOnlyGames = !hideFriendsOnly;
},
```

## Build Purity

The `build()` method must be **pure** — it reads state and returns widgets. No side effects.

**NEVER do these in `build()`:**
- Show dialogs or snackbars
- Call provider methods that trigger fetches or mutations
- Schedule `addPostFrameCallback` for side effects
- Write to local state variables

**Instead:** Trigger side effects from stream callbacks, button handlers, or lifecycle methods.

### Object Creation Anti-Pattern

NEVER create disposable objects in `build()` — they leak on every rebuild:

**Don't:**
```dart
@override
Widget build(BuildContext context) {
  return KeyboardListener(
    focusNode: FocusNode()..requestFocus(),  // ❌ New FocusNode every build
    // ...
  );
}
```

**Do:**
```dart
late FocusNode _focusNode;

@override
void initState() {
  super.initState();
  _focusNode = FocusNode();
}

@override
void dispose() {
  _focusNode.dispose();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  return KeyboardListener(
    focusNode: _focusNode,  // ✅ Reused across builds
    // ...
  );
}
```

This applies to: `FocusNode`, `TextEditingController`, `ScrollController`, `AnimationController`, `PageController`, and any other object that requires disposal.

### Stream Subscription Pattern

When a widget needs reactive Firestore data AND must trigger side effects on data changes:

1. **Use subscription, not StreamBuilder** — StreamBuilder re-runs its builder on every emission, making side-effect guards fragile.

2. **Lifecycle:**
   ```dart
   // initState: start subscription
   void initState() {
     super.initState();
     _subscription = provider.watchData(id).listen(
       _onDataReceived,
       onError: _onStreamError,
     );
   }

   // didUpdateWidget: reset and restart if key param changes
   void didUpdateWidget(MyWidget oldWidget) {
     super.didUpdateWidget(oldWidget);
     if (widget.id != oldWidget.id) {
       _subscription?.cancel();
       _resetAllTrackingState();  // Reset ALL flags, not just some
       _initSubscription();
     }
   }

   // dispose: clean up
   void dispose() {
     _subscription?.cancel();
     super.dispose();
   }
   ```

3. **Store data in local state**, render from state in `build()`:
   ```dart
   MyData? _data;
   bool _hasError = false;

   void _onDataReceived(MyData? data) {
     if (!mounted) return;
     setState(() {
       _data = data;
       _hasError = false;
     });
     // Side effects go here, not in build()
     _triggerSideEffectsIfNeeded(data);
   }
   ```

### One-Shot Guards

For actions that should fire only once per widget lifecycle (dialogs, analytics, one-time fetches):

```dart
bool _hasShownDialog = false;

void _onStreamError(Object error) {
  if (!mounted) return;
  if (isPermissionDenied(error) && !_hasShownDialog) {
    _hasShownDialog = true;
    _showDialogAndPop();
  }
}
```

**Reset guards in `didUpdateWidget`** when the relevant widget parameter changes.

### Deferred Callback Gating

When using `addPostFrameCallback` for batched/deferred work, gate with a flag to prevent duplicate scheduling:

```dart
bool _callbackScheduled = false;

void _scheduleWork() {
  if (_callbackScheduled) return;
  _callbackScheduled = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _callbackScheduled = false;
    if (!mounted) return;
    _doWork();
  });
}
```

## Stream & Subscription Cleanup
- Every `StreamSubscription` declared in a widget MUST be cancelled in `dispose()`
- Every `ScrollController`, `TextEditingController`, `FocusNode`, or `AnimationController` MUST be disposed in `dispose()`
- If you create it, you clean it up — no exceptions

## Animation Controller Patterns

When a widget needs multiple similar animation controllers (e.g., one per slide, one per list item):

**Don't:**
```dart
late AnimationController _slide1Controller;
late AnimationController _slide2Controller;
late AnimationController _slide3Controller;
late AnimationController _slide4Controller;

@override
void dispose() {
  _slide1Controller.dispose();
  _slide2Controller.dispose();
  _slide3Controller.dispose();
  _slide4Controller.dispose();
  super.dispose();
}
```

**Do:**
```dart
late List<AnimationController> _slideControllers;

@override
void initState() {
  super.initState();
  _slideControllers = List.generate(
    _totalSlides,
    (_) => AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    ),
  );
}

@override
void dispose() {
  for (final controller in _slideControllers) {
    controller.dispose();
  }
  super.dispose();
}
```

**Benefits:** Easier to add/remove items, cleaner disposal, works with dynamic counts.

## Logging
- Use `AppLog.d()` with emoji prefixes, never `print()` or `debugPrint()`

## Accessibility
- All interactive elements MUST have `Semantics` widgets or semantic labels
- Minimum touch target: 48x48 (use `SizedBox` wrapper if needed)
- Images must have `semanticLabel` parameter

## Design Tokens
- Use `AppSpacing` tokens — no `SizedBox(height: 16)` or `EdgeInsets.all(12)`
- Use `AppColors` — no `Colors.*`, `Color(0x...)`, `Color.fromARGB()`, or `Color.fromRGBO()`. CI blocks PRs with violations. Allowlist: `tool/hardcoded_color_allowlist.txt`
- Use `AppTypography` — no `TextStyle(fontSize: 14)`
- Use `AppBorderRadius` — no `BorderRadius.circular(12)`
- Use `AppIcon` with `AppPhosphorIcons` — no raw `Icon()` or legacy `AppIcons`

## Constructors
- Use `const` constructors wherever possible
- Add `const` to child widgets that don't depend on runtime values
- Prefer `const SizedBox.shrink()` over `Container()` for empty placeholders
