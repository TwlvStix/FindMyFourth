# Testing Patterns

**Analysis Date:** 2026-01-14

## Test Framework

**Runner:**
- flutter_test - Flutter SDK built-in testing framework
- Configuration: Included in pubspec.yaml (flutter_test SDK dependency)

**Assertion Library:**
- Built-in expect() with matchers
- Matchers: `toBe`, `toEqual`, `isNull`, `isTrue`, `isFalse`, `isEmpty`, `closeTo()`, `isNotNull`, `findsOneWidget`

**Run Commands:**
```bash
flutter test                          # Run all tests
flutter test --watch                  # Watch mode
flutter test path/to/file_test.dart   # Single file
flutter test --coverage               # Coverage report
```

## Test File Organization

**Location:**
- Test files in separate `test/` directory (not co-located with source)
- Mirrors lib/ structure: `test/services/`, `test/models/`, `test/auth/`

**Naming:**
- All test files: `{name}_test.dart`
- No distinction between unit/integration in filename

**Structure:**
```
test/
├── auth/
│   └── firebase_auth_manager_test.dart
├── models/
│   └── vibe_profile_test.dart
├── services/
│   ├── vibe_matcher_test.dart
│   └── vibe_group_matcher_test.dart
└── widget_test.dart
```

**Coverage:**
- Only 5 test files for 136 Dart library files
- Critical gaps: `chat_service.dart`, `user_provider.dart`, most widgets

## Test Structure

**Suite Organization:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:find_my_fourth/models/vibe_profile.dart';

void main() {
  group('VibeProfile', () {
    test('defaults apply and are incomplete', () {
      final profile = VibeProfile.defaults();
      expect(profile.confirmedAt, isNull);
      expect(profile.isIncomplete, isTrue);
    });

    test('serialization round-trip', () {
      final original = VibeProfile(...);
      final map = original.toFirestore();
      final restored = VibeProfile.fromFirestore(map);
      expect(restored.confirmedAt, original.confirmedAt);
    });
  });
}
```

**Patterns:**
- Use `group()` to organize related tests
- Use `test()` for individual test cases
- Use `testWidgets()` for widget tests (Flutter standard)
- Helper functions prefixed with underscore (e.g., `_profileWithValues()`)
- Clear, descriptive test names (e.g., `'exact match yields 100'`, `'serialization round-trip'`)

## Mocking

**Framework:**
- No explicit mocking framework detected
- Manual test data creation via helper functions

**Patterns:**
```dart
// Helper function to create test data
VibeProfile _profileWithValues(Map<VibeCategory, int> values) {
  final prefs = <VibeCategory, VibePreference>{
    for (final category in VibeCategory.values)
      category: VibePreference.defaults(),
  };
  values.forEach((category, value) {
    prefs[category] = prefs[category]!.copyWith(
      value: value,
      isDefault: false,
    );
  });
  return VibeProfile(prefs: prefs);
}
```

**What to Mock:**
- Not detected (no Firebase mocking, no mock providers found)

**What NOT to Mock:**
- Business logic classes (tested with real implementations)
- Model objects (use factory helpers instead)

## Fixtures and Factories

**Test Data:**
- Factory functions in test files (e.g., `_profileWithValues()`)
- Inline test data creation in test methods
- No separate fixtures directory

**Location:**
- Factory functions: Defined in test file near usage
- No shared fixtures directory detected

## Coverage

**Requirements:**
- No enforced coverage target detected
- No CI/CD coverage checks found

**Configuration:**
- Built-in Flutter coverage via `--coverage` flag
- No coverage exclusions configured

**View Coverage:**
```bash
flutter test --coverage
# View: open coverage/lcov.info with coverage tools
```

## Test Types

**Unit Tests:**
- Scope: Test single class in isolation
- Mocking: None detected (tests use real implementations)
- Examples: `test/models/vibe_profile_test.dart`, `test/services/vibe_matcher_test.dart`

**Widget Tests:**
- Scope: Test widget rendering
- Framework: `testWidgets()` from flutter_test
- Example: `test/widget_test.dart` (basic smoke test only)

**Integration Tests:**
- Not detected (no integration test directory or files)

**E2E Tests:**
- Not detected (no E2E framework found)

## Common Patterns

**Async Testing:**
```dart
test('async operation', () async {
  final result = await asyncFunction();
  expect(result, expectedValue);
});
```

**Error Testing:**
```dart
test('throws on invalid input', () {
  expect(() => functionCall(), throwsA(isA<Exception>()));
});
```

**Widget Testing:**
```dart
testWidgets('widget renders', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  expect(find.text('Hello'), findsOneWidget);
});
```

**Matcher Usage:**
- `closeTo()` for floating-point comparisons (e.g., vibe matching scores)
- `isNull` / `isNotNull` for nullable values
- `isTrue` / `isFalse` for booleans
- `isEmpty` / `isNotEmpty` for collections

**Snapshot Testing:**
- Not used in this codebase

## Test Coverage Gaps

**Untested Critical Areas:**
- `lib/services/chat_service.dart` - Complex transaction-based operations
- `lib/providers/user_provider.dart` - Cache invalidation and stream handling
- `lib/services/vibe_repository.dart` - Vibe data queries
- Most widget files - Only basic smoke test exists
- `lib/backend/push_notifications/push_notifications_handler.dart` - No notification tests
- `lib/auth/firebase_auth/` - Only 1 basic auth manager test

**Test Priority:**
1. High: ChatService (critical business logic)
2. High: Authentication flows (security critical)
3. Medium: UserProvider (cache management)
4. Medium: Widget rendering (user-facing)
5. Low: Utility functions (low risk)

---

*Testing analysis: 2026-01-14*
*Update when test patterns change*
