---
paths: lib/**/*_widget.dart
---
# Widget Rules

## Size Limit
Widget files MUST stay under 300 lines. If a widget is approaching this limit, decompose it:
- Extract logical sections into sub-widgets in a `components/` subfolder
- Extract form state and async logic into a ViewModel/Controller class
- The screen-level widget should compose smaller widgets, not contain all logic

**Legacy exception**: Some existing widgets (onboarding, profile) exceed 300 lines. These are tracked as tech debt. Do NOT increase their size further — only refactor to reduce.

## Separation of Concerns
- NEVER call Firestore, Firebase Auth, or any backend service directly from a widget
- Data flow is: Widget → Provider → Service → Firestore. No shortcuts.
- Access providers via extensions: `context.gameProvider`, `context.userProvider`

## State Management
- NEVER use empty `setState(() {})`. This rebuilds the entire widget for nothing.
- ALWAYS add `if (!mounted) return;` before any `setState` that follows an `await`
- Prefer Provider/ChangeNotifier for state over local setState when state is shared
- Use `context.select<T, R>()` or `Selector` to minimize rebuild scope

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

## Logging
- Use `AppLog.d()` with emoji prefixes, never `print()` or `debugPrint()`

## Accessibility
- All interactive elements MUST have `Semantics` widgets or semantic labels
- Minimum touch target: 48x48 (use `SizedBox` wrapper if needed)
- Images must have `semanticLabel` parameter

## Design Tokens
- Use `AppSpacing` tokens — no `SizedBox(height: 16)` or `EdgeInsets.all(12)`
- Use `AppColors` — no `Color(0xFF...)` or `Colors.white`
- Use `AppTypography` — no `TextStyle(fontSize: 14)`
- Use `AppBorderRadius` — no `BorderRadius.circular(12)`
- Use `AppIcon` with `AppPhosphorIcons` — no raw `Icon()` or legacy `AppIcons`

## Constructors
- Use `const` constructors wherever possible
- Add `const` to child widgets that don't depend on runtime values
- Prefer `const SizedBox.shrink()` over `Container()` for empty placeholders
