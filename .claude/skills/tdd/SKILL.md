# TDD Skill — Flutter / Firebase

Use when implementing any feature or bugfix, before writing implementation code.

---

## The Rule

No production code without a preceding, failing test. Violating the letter of this rule is violating the spirit of this rule.

Write code before a test? Delete it. Start over.

## Red Flags — STOP and Start Over

- Code before test
- "I already ran it in the simulator"
- "Tests after achieve the same purpose"
- "This is different because it's UI"
- "Widget tests are too slow, I'll add them later"
- "It's about the spirit, not the ritual"
- "I'll just write a quick integration test at the end"

All of these mean: delete code. Start over with TDD.

---

## Before Writing Anything — The Planning Phase

Answer these questions with the user before touching any code:

1. **What interface changes are needed?** What classes, methods, providers, or Cloud Functions are being added or modified?
2. **Which behaviors matter most?** You can't test everything. Prioritize critical paths and complex logic over edge cases.
3. **Can we design for deep modules?** A deep module has a small public interface but handles complex logic internally. Prefer one well-tested service class over five scattered helpers.
4. **Can we design for testability?** Functions should accept dependencies rather than create them. Return results instead of producing side effects. If a widget needs a Firestore reference, pass it in — don't hardcode `FirebaseFirestore.instance` inside the widget.

Do not proceed until these are answered.

---

## The Cycle: Red → Green → Refactor

### RED — Write ONE failing test

- Just one. Not a batch. One test that describes a single behavior.
- Run it. Watch it fail. Confirm it fails for the right reason (missing method, wrong return value — not a syntax error or import issue).

### GREEN — Write minimal code to pass

- Only enough code to make that one test go green. Nothing speculative. No "while I'm here" additions.
- Run all tests. Everything green? Move on.

### REFACTOR — Clean up with confidence

- Remove duplication. Simplify. Extract if it helps readability.
- Run all tests again. Still green? Next cycle.

Repeat until the feature is complete.

---

## Flutter-Specific Testing Layers

Know which layer you're testing and stay in that lane:

### Unit Tests (`flutter_test`)
Use for: services, providers, models, utility functions, Cloud Function logic, Firestore transaction ordering, data transformations.

```dart
// GOOD: Tests the service through its public interface
test('createGame returns a Game with status pending', () async {
  final service = GameService(firestore: fakeFirestore);
  final game = await service.createGame(hostId: 'user123', courseId: 'course456');
  expect(game.status, GameStatus.pending);
});
```

### Widget Tests (`flutter_test` with `WidgetTester`)
Use for: verifying a widget renders correctly, responds to taps, shows the right state. Widget tests are NOT slow — they run without a device. Use them.

```dart
// GOOD: Tests observable UI behavior
testWidgets('Join button is hidden when game is cancelled', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: GameDetailPage(game: cancelledGame)),
  );
  expect(find.text('Join'), findsNothing);
  expect(find.text('Cancelled'), findsOneWidget);
});
```

### Integration Tests (`integration_test`)
Use sparingly. These run on a device/emulator and are slow. Reserve for critical user flows that span multiple screens (e.g., onboarding → first game creation). Do not use integration tests as a substitute for missing unit or widget tests.

---

## What Makes a Good Test (Flutter Edition)

Good tests exercise real code paths through public interfaces. They describe WHAT the system does, not HOW it does it.

```dart
// GOOD: Tests observable behavior
test('vibe score below 30 triggers host approval requirement', () {
  final result = calculateVibeCompatibility(hostVibes, guestVibes);
  expect(result.requiresApproval, isTrue);
});

// BAD: Tests implementation detail
test('calculateVibeCompatibility calls _weightedBlend internally', () {
  // This breaks when you refactor, even if behavior is unchanged
});
```

**The refactor test:** If you rename a private method and your test breaks, that test was bad.

---

## Mocking in Flutter / Firebase

### Use `fake_cloud_firestore` for Firestore
Don't mock Firestore method-by-method. Use `FakeFirebaseFirestore()` which gives you an in-memory Firestore that behaves like the real thing.

### Use simple fakes over complex mocks
If a service depends on `AuthService`, write a `FakeAuthService` that returns predictable values. Avoid `mocktail` or `mockito` for things you can fake simply. Reserve mocking frameworks for when you genuinely need to verify interactions (e.g., confirming a Cloud Function was called).

### Never mock what you own at the boundary
If you wrote `GameService`, don't mock it in the widget test. Give the widget a real `GameService` backed by `FakeFirebaseFirestore`. Mock at the edges (HTTP clients, platform channels), not in the middle.

---

## Testing Cloud Functions

Cloud Functions (especially Firestore triggers and callable functions) should be tested as unit tests using the Firebase Functions Test SDK or by extracting the business logic into pure Dart functions that can be tested without the Firebase wrapper.

```dart
// Extract logic from the Cloud Function handler
Map<String, dynamic> computeLeaderboardUpdate(
  Map<String, dynamic> roundData,
  Map<String, dynamic> existingStandings,
) {
  // Pure logic, no Firebase dependency
}

// Test the pure function
test('leaderboard update adds round score to season total', () {
  final result = computeLeaderboardUpdate(
    {'playerId': 'p1', 'score': 78},
    {'p1': {'totalScore': 312, 'roundsPlayed': 4}},
  );
  expect(result['p1']['totalScore'], 390);
  expect(result['p1']['roundsPlayed'], 5);
});
```

---

## Dealing with Large Widgets (300+ lines)

When TDD reveals a widget is hard to test, that's a signal — not a reason to skip testing.

1. Extract the business logic into a service or provider. Test that with unit tests.
2. Extract sub-widgets into smaller, focused widgets. Test those with widget tests.
3. The parent widget becomes a composition layer — it wires things together but contains little logic of its own.

If you can't write a clear test for a widget, the widget is doing too much.

---

## Running Tests

```bash
# Run all unit and widget tests
flutter test

# Run a specific test file
flutter test test/services/game_service_test.dart

# Run with coverage
flutter test --coverage

# Run integration tests (requires device/emulator)
flutter test integration_test/
```

Always run `flutter test` after every green and refactor step. No exceptions.
