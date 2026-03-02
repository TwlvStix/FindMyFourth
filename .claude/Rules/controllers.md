---
paths: lib/**/controllers/**/*.dart
---
# Controller Rules

Controllers extract complex logic from widgets (form handling, multi-step flows, async coordination). They are NOT a replacement for services — they sit between widgets and providers.

## Separation of Concerns
- NEVER call Firestore, Firebase Auth, or any backend service directly from a controller
- Data flow is: Controller → Provider → Service → Firestore
- Controllers coordinate UI logic (validation, step management, form state) — not data operations

**Known debt**: `create_game_controller.dart` has direct Firebase calls. Fix when next modified.

## Structure
- Controllers are plain Dart classes (not ChangeNotifiers — use providers for reactive state)
- Accept providers or services via constructor for testability
- **Include AppState** if the controller needs to mutate persisted preferences (pass via `context.read<AppState>()` at instantiation)
- Keep controllers focused — one controller per screen or flow, not shared across features

```dart
// Example: Controller that needs AppState
class MyController {
  MyController({
    required GameProvider gameProvider,
    required AppState appState,  // Pass from widget via context.read<AppState>()
  }) : _gameProvider = gameProvider,
       _appState = appState;

  final GameProvider _gameProvider;
  final AppState _appState;
}
```

## Logging
- Use `AppLog.d()` with emoji prefixes, never `print()` or `debugPrint()`

## Design Tokens
- Controllers that build widgets or return widget configuration should use design tokens
- Never hardcode colors, spacing, or typography values in controllers

## Size Limit
- Controllers should stay under 300 lines, same as widgets
- If a controller grows too large, split by responsibility (e.g., validation logic vs flow coordination)

## Mounted Checks in Widget Callbacks

Controllers don't have `mounted`, but when a controller method returns a Future that the widget awaits, the widget must still check `mounted` before using the result:

```dart
// In widget — controller doesn't know about widget lifecycle
final result = await _controller.processData();
if (!mounted) return;
setState(() => _data = result);
```
