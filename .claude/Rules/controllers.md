---
paths: lib/**/controllers/**/*.dart
---
# Controller Rules

Controllers extract complex logic from widgets (form handling, multi-step flows, async coordination). They are NOT a replacement for services — they sit between widgets and providers.

## Separation of Concerns
- NEVER call Firestore, Firebase Auth, or any backend service directly from a controller
- Data flow is: Controller → Provider → Service → Firestore
- Controllers coordinate UI logic (validation, step management, form state) — not data operations

**Known debt**: `create_game_controller.dart` and `join_game_detailed_controller.dart` have direct Firebase calls. Fix when next modified.

## Structure
- Controllers are plain Dart classes (not ChangeNotifiers — use providers for reactive state)
- Accept providers or services via constructor for testability
- Keep controllers focused — one controller per screen or flow, not shared across features

## Logging
- Use `AppLog.d()` with emoji prefixes, never `print()` or `debugPrint()`

## Design Tokens
- Controllers that build widgets or return widget configuration should use design tokens
- Never hardcode colors, spacing, or typography values in controllers

## Size Limit
- Controllers should stay under 300 lines, same as widgets
- If a controller grows too large, split by responsibility (e.g., validation logic vs flow coordination)
