---
paths: test/**/*.dart
---
# Testing Rules

## Structure
- Test directory mirrors `lib/` structure
- Test files named `*_test.dart`
- Group related tests with `group()` blocks

## Service Tests
- Inject mock `FirebaseFirestore` via constructor
- Test error paths, not just happy paths
- Test Firestore limit edge cases (>10 whereIn items, >500 batch ops)
- No unused local variables — if you declare it, assert on it

## Provider Tests
- Inject mock services via constructor
- Verify `notifyListeners()` is called appropriately
- Test cache invalidation after mutations
- Test dispose cleanup (subscriptions cancelled, timers cancelled)

## Controller Tests
- Controllers extract widget logic — test them the same as providers
- Verify they delegate to services, not call Firebase directly
- Mock the service layer, not Firestore

## Widget Tests
- Use `pumpWidget` with necessary providers injected
- Test user interactions (tap, scroll, text input), not implementation details
- Verify accessibility: `Semantics` labels present on interactive elements

## What Needs Tests
- All service methods (Firestore operations)
- Provider state transitions
- Business logic in models (e.g., `resolveGameStatus()`)
- Vibe scoring algorithm changes
- New features must include tests before merging
