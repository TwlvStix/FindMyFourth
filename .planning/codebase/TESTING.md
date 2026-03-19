# Testing Patterns

**Analysis Date:** 2026-03-19

## Test Framework

**Dart/Flutter Tests:**
- Runner: `test` package 1.24.0
- Assertion library: Built-in `expect()` from `test` package
- Mocking: Manual mock classes implementing interfaces (no external mocking library)
- Config: None (uses default test runner)

**Cloud Functions Tests (JavaScript):**
- Runner: Jest 29.0.0
- Assertion library: Jest built-in matchers (`expect()`)
- Mocking: Jest `jest.mock()` and `jest.fn()`
- Config: Default Jest config (defined via package.json scripts)

**Run Commands:**
```bash
# Dart/Flutter tests
flutter test                              # Run all tests
flutter test test/vibe_scoring_test.dart  # Run single test file
flutter test --watch                      # Watch mode

# Cloud Functions tests
cd firebase/functions
npm test                                  # Run all tests matching test/
npx jest test/hooks.test.js               # Run single test file
npm run lint                              # ESLint validation

# Load testing (Firebase)
npm run load-test                         # Full load test
npm run load-test:small                   # Small load test
npm run notif-load-test                   # Notification load test
```

## Test File Organization

**Location:**
- Co-located with source code: `test/` directory mirrors `lib/` structure
- Test files in same relative path as source: `test/providers/game_provider_test.dart` tests `lib/providers/game_provider.dart`
- Firebase Functions: `firebase/functions/test/*.test.js`

**Naming:**
- Pattern: `*_test.dart` or `*.test.js`
- Examples: `vibe_scoring_test.dart`, `game_provider_test.dart`, `hooks.test.js`, `preferences-service.test.js`

**Structure:**
```
test/
├── auth/
│   └── firebase_auth_manager_test.dart
├── core/
│   ├── firebase_error_utils_test.dart
│   ├── navigation/
│   │   └── nav_extensions_test.dart
│   └── utils/
│       └── input_sanitizer_test.dart
├── providers/
│   ├── geo_filter_provider_test.dart
│   ├── group_vibe_provider_test.dart
│   ├── trust_provider_batch_test.dart
│   └── vibe_provider_test.dart
├── main_function/
│   ├── create_game/
│   │   ├── components/
│   │   │   └── flexible_time_section_test.dart
│   │   ├── create_game_validator_test.dart
│   │   └── models/
│   │       └── create_game_form_data_test.dart
│   └── games_list/
│       ├── components/
│       │   └── quick_filter_chips_test.dart
│       └── models/
│           └── quick_filter_test.dart
├── vibe_scoring_test.dart
├── vibe_floor_simulation_test.dart
└── utils/
    ├── availability_text_helper_test.dart
    └── game_tag_helper_test.dart
```

## Test Structure (Dart)

**Suite Organization:**
```dart
import 'package:test/test.dart';
import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/vibe/vibe_scoring.dart';

void main() {
  test('simple test case', () {
    final result = calculateScore(a, b);
    expect(result, closeTo(expectedValue, 0.01));
  });

  group('grouped tests', () {
    test('case 1', () {
      expect(value, isTrue);
    });

    test('case 2', () {
      expect(value, isFalse);
    });
  });
}
```

**Patterns:**
- Setup: `setUp()` block before `group()` for fixture initialization
- Teardown: `tearDown()` block to clean up (dispose providers, clear mocks)
- Grouping: `group()` to organize related tests and run shared setup/teardown
- Skipping: `skip` suffix on test name (rarely used)

**Example Provider Test:**
```dart
void main() {
  group('GeoFilterProvider', () {
    late GeoFilterProvider provider;
    late MockGeoLocationService mockService;
    bool skipTearDownDispose = false;

    setUp(() {
      mockService = MockGeoLocationService();
      provider = GeoFilterProvider(service: mockService);
      skipTearDownDispose = false;
    });

    tearDown(() {
      if (!skipTearDownDispose) {
        provider.dispose();
      }
    });

    group('initial state', () {
      test('starts with filter disabled', () {
        expect(provider.isEnabled, isFalse);
      });

      test('starts with default radius of 40 km', () {
        expect(provider.radiusKm, equals(40.0));
      });
    });

    group('permission handling', () {
      test('requests permission on demand', () async {
        await provider.requestLocationPermission();
        expect(mockService.requestPermissionCallCount, equals(1));
      });
    });
  });
}
```

## Test Structure (JavaScript)

**Suite Organization (Jest):**
```javascript
'use strict';

// Mock dependencies first
jest.mock('firebase-admin');
jest.mock('../notifications/trust/scheduler');

// Import module under test
const { onGameConfirmed } = require('../notifications/trust/hooks');

// Constants
const TEE_TIME_ISO = '2026-03-15T14:00:00.000Z';
const HOST = 'user_host';

// Shared setup
beforeEach(() => {
  jest.clearAllMocks();
});

afterEach(() => {
  jest.useRealTimers();
});

// Test suite
describe('onGameConfirmed', () => {
  test('2-player game schedules exactly 4 jobs', async () => {
    const { scheduleJob } = require('../notifications/trust/scheduler');
    await onGameConfirmed(GAME_ID, TEE_TIME_ISO, HOST, [HOST, PLAYER_1], COURSE_NAME, GAME_DATE);
    expect(scheduleJob).toHaveBeenCalledTimes(4);
  });

  test('schedules host_checkin_due with correct timing', async () => {
    const { scheduleJob } = require('../notifications/trust/scheduler');
    await onGameConfirmed(GAME_ID, TEE_TIME_ISO, HOST, [HOST, PLAYER_1], COURSE_NAME, GAME_DATE);

    const calls = scheduleJob.mock.calls.map((c) => c[0]);
    const initial = calls.find((e) => e.eventType === 'host_checkin_due' && e.conditionCheck === 'always');

    expect(initial).toBeDefined();
    expect(initial.recipientUserId).toBe(HOST);
    expect(new Date(initial.scheduleTime).getTime()).toBe(TEE_TIME_MS + 5 * MS_IN_HOUR);
  });
});
```

**Patterns:**
- Clear mocks between tests: `jest.clearAllMocks()` in `beforeEach()`
- Reset timers: `jest.useRealTimers()` in `afterEach()`
- Setup mock implementations with `mockImplementation()` or `mockResolvedValue()`
- Use `describe()` for test suites, `test()` for individual cases

## Mocking

**Dart - Manual Mock Classes:**
- Implement the service interface: `class MockVibeRepository implements VibeRepository`
- Track call counts: `int updateCategoryCallCount = 0;`
- Track last arguments: `VibeCategory? lastUpdatedCategory;`
- Support failure injection: `bool shouldFailOnUpdate = false;` then throw in the method
- Provide pre-configured return values: `VibeProfile? profileToReturn;` used by `getMyVibesCached()`

**Example:**
```dart
class MockVibeRepository implements VibeRepository {
  MockVibeRepository({
    this.profileToReturn,
    this.shouldFailOnUpdate = false,
  });

  VibeProfile? profileToReturn;
  bool shouldFailOnUpdate;
  int updateCategoryCallCount = 0;
  VibeCategory? lastUpdatedCategory;
  int? lastUpdatedValue;

  @override
  Future<VibeProfile> getMyVibesCached({bool forceRefresh = false}) async {
    return profileToReturn ?? VibeProfile.defaults();
  }

  @override
  Future<void> updateCategory(VibeCategory category, int value) async {
    updateCategoryCallCount++;
    lastUpdatedCategory = category;
    lastUpdatedValue = value;
    if (shouldFailOnUpdate) {
      throw FirebaseException(plugin: 'firestore', code: 'permission-denied');
    }
  }
}
```

**JavaScript - Jest Mocks:**
- Mock at module level with `jest.mock(path)`
- Inline mock implementation in `beforeEach()` with `jest.fn()`
- Setup return values with `mockResolvedValue()`, `mockRejectedValue()`, `mockImplementation()`
- Inspect calls with `.mock.calls`, `.toHaveBeenCalledTimes()`, `.toHaveBeenCalledWith()`

**Example:**
```javascript
jest.mock('crypto', () => ({
  randomUUID: jest.fn(),
}));

jest.mock('../notifications/trust/scheduler', () => ({
  scheduleJob: jest.fn(),
  cancelGameJobs: jest.fn(),
}));

beforeEach(() => {
  const { randomUUID } = require('crypto');
  randomUUID.mockImplementation(() => `uuid-${++counter}`);

  const { scheduleJob } = require('../notifications/trust/scheduler');
  scheduleJob.mockImplementation(async () => `job_${++jobNum}`);
  scheduleJob.mockResolvedValue({ success: true });
});
```

**What to Mock:**
- External services (Firestore, Firebase, APIs) - use `FirebaseException` for error injection
- Dependencies passed to constructors for isolation
- Time-based operations (use `jest.useFakeTimers()` in JavaScript)

**What NOT to Mock:**
- Business logic being tested (model methods, scoring algorithms, validation)
- Utility functions (helpers, formatters)
- Domain models that represent data

## Fixtures and Factories

**Test Data (Dart):**
- Create test doubles directly inline: `const VibePref(value: 3, tolerance: 2, weight: 10)`
- Use model defaults for convenience: `VibeProfile.defaults()`
- Pre-configured mock returns: `MockVibeRepository(profileToReturn: testProfile)`

**Example:**
```dart
final base = VibePref(value: 3, tolerance: 2, weight: 10);
final defaultPref = VibePref(
  value: 3,
  tolerance: 2,
  weight: 10,
  isDefault: true,
);

final baseWeight = categoryEffectiveWeight(base, base);
final oneDefault = categoryEffectiveWeight(base, defaultPref);
```

**Test Data (JavaScript):**
- Define constants at module level: `const TEE_TIME_ISO = '2026-03-15T14:00:00.000Z';`
- Use in multiple tests via closure: Tests reference constants defined in outer scope
- Create composite objects inline: `const calls = scheduleJob.mock.calls.map((c) => c[0]);`

**Location:**
- Dart: Inline in test files or in mock class definitions
- JavaScript: Constants at top of test file, mock objects constructed during test

## Coverage

**Requirements:**
- No enforced coverage threshold (not measured by CI)
- Manual decision per feature: new features should include tests before merging
- Focus on critical paths: service layer (Firestore operations), provider state transitions, business logic

**View Coverage (JavaScript):**
```bash
cd firebase/functions
npm test -- --coverage
```

## Test Types

**Unit Tests:**
- Scope: Single function/method in isolation with mocked dependencies
- Approach: Test with `FakeCloudFirestore` for services, mock service for providers
- Examples: `vibe_scoring_test.dart` (pure scoring algorithms), `firebase_auth_manager_test.dart` (retry logic)

**Service Tests (Dart):**
- Inject mock `FirebaseFirestore` via constructor
- Test happy path and error paths
- Test Firestore limit edge cases: >10 items in `whereIn` (use chunking), >500 operations in batch
- No unused local variables - if declared, it must be asserted

**Provider Tests (Dart):**
- Inject mock service via constructor
- Verify `notifyListeners()` called appropriately (not for every stream callback)
- Test cache invalidation after mutations
- Test `dispose()` cleanup: subscriptions cancelled, timers cancelled, `_disposed` flag set
- Use `setUp()`/`tearDown()` for consistent initialization and cleanup

**Integration Tests:**
- Not currently used in this codebase
- Integration test file exists: `integration_test/friend_notifications_test.dart` (not actively maintained)

**E2E Tests:**
- Not used (Flutter app, would require device/emulator)
- Firebase rules testing done via `firebase/rules-tests/` (separate from unit tests)

## Common Patterns

**Async Testing (Dart):**
```dart
test('loads vibe profile on initialization', () async {
  final mock = MockVibeRepository(
    profileToReturn: VibeProfile.defaults(),
  );
  final provider = VibeProvider(repository: mock);

  await provider.loadMyVibes();

  expect(provider.myProfile, isNotNull);
  expect(mock.loadProfileCallCount, equals(1));
});
```

**Error Testing (Dart):**
```dart
test('propagates Firestore errors', () async {
  final mock = MockVibeRepository(shouldFailOnUpdate: true);
  final provider = VibeProvider(repository: mock);

  expect(
    () => provider.updateCategory(VibeCategory.drinking, 5),
    throwsA(isA<FirebaseException>()),
  );
});
```

**Mocking Streams (Dart):**
```dart
test('reacts to stream updates', () async {
  final controller = StreamController<VibeProfile>();
  // Set up stream in mock and verify listeners react
  controller.add(testProfile);
  // Assert state changes
});
```

**Time-based Testing (JavaScript):**
```javascript
test('schedules job at correct time', async () => {
  jest.useFakeTimers();
  const futureDate = new Date(Date.now() + 5 * 60 * 60 * 1000); // +5h

  await scheduleJob({ scheduleTime: futureDate.toISOString() });

  expect(new Date(scheduled.scheduleTime).getTime()).toBe(futureDate.getTime());
  jest.useRealTimers();
});
```

**Assertion Helpers (Dart):**
- `expect(value, isTrue)` / `expect(value, isFalse)`
- `expect(value, equals(expected))`
- `expect(value, closeTo(expected, tolerance))` — for floating point comparisons
- `expect(value, inInclusiveRange(min, max))`
- `expect(value, greaterThan(x))` / `expect(value, lessThan(x))`
- `expect(value, isNull)` / `expect(value, isNotNull)`
- `expect(value, isEmpty)` / `expect(value, isNotEmpty)`
- `expect(list, contains(item))`
- `expect(() => fn(), throwsA(isA<ExceptionType>()))`
- `expectLater(() => fn(), throwsA(isA<ExceptionType>()))` — for async

## What Needs Tests

**Required:**
- All service methods (Firestore CRUD operations)
- Provider state transitions and cache management
- Business logic in models: `Game.resolveGameStatus()`, vibe scoring algorithms
- Vibe matching and eligibility logic
- Error handling paths (Firebase exceptions, permission errors)
- New features before merging

**Nice to Have:**
- Widget integration tests (requires emulator setup)
- Widget accessibility validation (Semantics presence)
- Cloud Functions load testing (via `npm run load-test`)

**Legacy/Deferred:**
- Full E2E coverage (complex to set up with emulator)
- Performance benchmarks (not currently automated)

---

*Testing analysis: 2026-03-19*
