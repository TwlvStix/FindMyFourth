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
