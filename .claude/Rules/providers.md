---
paths: lib/providers/**/*.dart
---
# Provider Rules

## Structure (every provider follows this pattern)
- Extend `ChangeNotifier`
- Accept service via constructor with default: `FeatureProvider({FeatureService? service}) : _service = service ?? FeatureService();`
- Implement `_disposed` flag, check before `notifyListeners()`
- Use `_scheduleNotify()` debounce (50ms timer), never call `notifyListeners()` directly

**Known debt**: `UserProvider` is missing the `_disposed` flag — fix when next modified.

## Size Limit
Provider files should stay under 500 lines. If approaching this limit, split by sub-domain (e.g., separate read-heavy stream logic from mutation methods). ChatProvider (732 lines) is tracked as tech debt.

## Caching
- Cache data with TTL (typically 5 minutes) using `Map<String, DateTime>` timestamps
- Use `StreamRequestManager` for reactive Firestore streams with `BehaviorSubject`
- Mutations: delegate writes to service, then invalidate relevant caches

## Disposal & Cleanup
- Cancel ALL `StreamSubscription` instances in `dispose()`
- Close all `StreamController` and `BehaviorSubject` instances in `dispose()`
- Cancel any pending `Timer` instances (including the `_scheduleNotify` timer) in `dispose()`
- Set `_disposed = true` at the start of `dispose()`

## Error Handling
- Catch errors from services, log with `AppLog.d()`, rethrow to UI layer
- Never swallow errors — the UI needs to know about failures

## Access Pattern
- Widgets access providers via extensions: `context.gameProvider`, `context.userProvider`
- See `lib/providers/provider_extensions.dart`

## Logging
- Use `AppLog.d()` with emoji prefixes, never `print()` or `debugPrint()`
