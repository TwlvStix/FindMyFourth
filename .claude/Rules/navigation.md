---
paths: lib/core/navigation/**/*.dart
---
# Navigation Rules

## Route Parameters
- NEVER force-unwrap route params with `!`
- Always provide fallbacks or route to an error state for missing/invalid params:
  ```dart
  final gameRef = state.extra as DocumentReference?;
  if (gameRef == null) return _errorPage(state, 'Missing game reference');
  ```
- Follow the guard pattern already established at app_router.dart:440-448

## Route Definitions
- Each widget defines static `routeName` and `routePath` constants
- Pass parameters via `state.extra` (typically `DocumentReference`)
- All routes include `_buildRedirect` for auth guarding

## Transitions
- Use `TransitionStandards` presets from `transition_standards.dart` (modal, detail, dismissal, tab)
- Use GoRouter's `CustomTransitionPage` for all transitions
- Do NOT use the `page_transition` package (removed)
- Support reduced motion via `ReducedMotionService`

## Navigation from Widgets
- Prefer typed navigation helpers over raw string routes
- Do not scatter imperative `context.push('/path')` calls throughout widgets
- Route logic should be centralized, not owned by individual widgets
