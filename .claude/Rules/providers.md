---
paths: lib/providers/**/*.dart
---
# Provider Rules

## Structure (every provider follows this pattern)
- Extend `ChangeNotifier`
- Accept service via constructor with default: `FeatureProvider({FeatureService? service}) : _service = service ?? FeatureService();`
- Implement `_disposed` flag, check before `notifyListeners()`
- Use `_scheduleNotify()` debounce (50ms timer), never call `notifyListeners()` directly

**Known debt**: `ChatProvider` (793 lines) exceeds the 500-line limit — split when next modified.

## Setter Guards
When a setter calls `notifyListeners()` (or `_scheduleNotify()`), always guard against no-op updates:

```dart
set myValue(bool value) {
  if (_myValue == value) return;  // no-op guard
  _myValue = value;
  _scheduleNotify();
}

void setMapValue(String key, String value) {
  if (_map[key] == value) return;  // no-op guard
  _map[key] = value;
  _scheduleNotify();
}
```

This prevents unnecessary rebuilds when the same value is set twice.

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

## Notification Scoping Policy

**Hard rule**: Only call `_scheduleNotify()` when UI needs to react.

### When to notify:
- **Mutations** (create, update, delete) — UI typically needs to reflect the change
- **Cache invalidation** — if UI watches the provider for refresh triggers
- **Error/loading state changes** — UI displays spinners or error messages

### When NOT to notify:
- **Stream callbacks** — the stream delivers data directly to subscribers; notifying causes redundant rebuilds
- **Future completions** — the caller awaits the result directly; no need to trigger provider listeners
- **Internal cache updates** — caching data for later use doesn't require a UI rebuild

### Consumer vs Selector

Prefer **selectors** over `Consumer<Provider>` when watching specific fields:

```dart
// BAD: Rebuilds entire widget tree on ANY UserProvider change
Consumer<UserProvider>(
  builder: (context, userProvider, _) {
    final pending = userProvider.hasPendingOutgoingRequest(hostRef.id);
    return MyWidget(hasPending: pending);
  },
)

// GOOD: Rebuilds only when this specific value changes
final pending = context.hasPendingOutgoing(hostRef.id);
return MyWidget(hasPending: pending);
```

### Available selector extensions (in `provider_extensions.dart`):
- `context.selectUser((p) => p.someField)`
- `context.selectGame((p) => p.someField)`
- `context.selectChat((p) => p.someField)`
- `context.selectTrust((p) => p.someField)`
- `context.selectProfile((p) => p.someField)`
- `context.selectNotification((p) => p.someField)`
- `context.hasPendingOutgoing(uid)` — convenience for friend request checks
