# Testing

## Overview

| Area | Framework | Command | Location |
|------|-----------|---------|----------|
| Flutter app | `package:test` / `flutter_test` | `flutter test` | `test/` |
| Cloud Functions | Jest 29.0.0 | `npm test` | `firebase/functions/test/` |

---

## Flutter Tests

### Directory Structure
```
test/
├── vibe_scoring_test.dart              # Core vibe algorithm
├── vibe_golden_pairs_test.dart         # Golden pair validation
├── vibe_scoring_additional_test.dart   # Extended scoring
├── vibe_floor_simulation_test.dart     # Floor threshold sim
├── widget_test.dart                    # Basic widget test
│
├── services/                           # Service layer tests (17+)
│   ├── alert_matcher_test.dart
│   ├── friend_service_test.dart
│   ├── game_eligibility_test.dart
│   ├── create_game_service_test.dart
│   ├── vibe_floor_service_test.dart
│   ├── fcm_suppression_test.dart
│   └── ...
│
├── providers/                          # Provider tests
│   ├── geo_filter_provider_test.dart
│   ├── vibe_provider_test.dart
│   ├── group_vibe_provider_test.dart
│   └── trust_provider_batch_test.dart
│
├── auth/                               # Auth tests
├── backend/                            # Backend tests
├── chat_group/                         # Chat tests
├── main_function/                      # Game feature tests
├── profile/                            # Profile tests
├── utils/                              # Utility tests
├── widgets/                            # Widget tests (7+ subdirs)
└── vibe/                               # Vibe system tests
```

### Commands
```bash
flutter test                                          # All tests
flutter test test/services/vibe_scoring_test.dart     # Single file
flutter test --grep="pattern"                         # Filter by name
```

---

## Cloud Functions Tests

### Directory Structure
```
firebase/functions/test/
├── confirmation_flow.test.js     # 119KB - comprehensive
├── game_alerts.test.js           # 34KB
├── hooks.test.js                 # 35KB
├── integration.test.js           # 40KB
├── router.test.js                # 47KB
├── scheduler.test.js             # 23KB
├── event-registry.test.js        # 23KB
├── notification-load.test.js     # 31KB
├── behavioral_dataset_test.js    # 13KB
├── challenge_progress.test.js    # 24KB
├── chat_debounce.test.js         # 20KB
├── fcm-sender.test.js
├── friend-callable.test.js
├── onboarding-callable.test.js
├── preferences-service.test.js
├── signup-email.test.js
├── streaks.test.js
├── sync_game_chat.test.js
├── template-engine.test.js
├── test-harness.test.js
├── word_filter.test.js
├── workers.test.js
│
├── load-test.js                  # Load testing
├── LOAD_TEST_README.md
└── LOAD_TEST_QUICK_START.md
```

### Commands
```bash
npm test                                          # All tests
npx jest test/game_alerts.test.js --verbose      # Single test
npx jest test/confirmation_flow.test.js          # Confirmation tests
npm run notif-load-test                          # Notification load test
npm run notif-load-test:small                    # Small load test
npm run load-test                                # Full load test
npm run load-test:small                          # Small load test
npm run load-test:cleanup                        # Cleanup test data
npm run lint                                     # ESLint (max 30 warnings)
```

---

## Mocking Patterns

### Flutter Service Mocks

**Manual mock implementing interface:**
```dart
class MockVibeRepository implements VibeRepository {
  VibeProfile? profileToReturn;
  bool shouldFailOnUpdate = false;
  int updateCategoryCallCount = 0;

  @override
  Future<VibeProfile> getMyVibes() async {
    if (shouldFailOnLoad) {
      throw FirebaseException(plugin: 'firestore', code: 'unavailable');
    }
    return profileToReturn ?? VibeProfile.defaults();
  }
}

// Usage in test setup
setUp(() {
  mockRepo = MockVibeRepository();
  provider = VibeProvider(repository: mockRepo);
});
```

**Fake DocumentReference:**
```dart
class _FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this.path, {this.onSet});
  @override
  final String path;
  final Future<void> Function(Map<String, dynamic>)? onSet;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (onSet != null) await onSet!(data);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

**Dependencies:**
- `fake_cloud_firestore` ^4.0.1 — Firestore mocking
- `firebase_auth_mocks` ^0.15.1 — Auth mocking

### JavaScript Mocks

**Module-level mock state** (before `jest.mock()`):
```javascript
let mockSharedDb;
let mockFcmSend;
let mockCreateTask;

jest.mock('firebase-admin', () => ({
  firestore: () => mockSharedDb,
  messaging: () => ({ send: (...args) => mockFcmSend(...args) }),
}));
```

**Mock infrastructure classes:**
```javascript
class MockTimestamp {
  constructor(ms) { this._ms = ms; }
  toMillis() { return this._ms; }
  static now() { return new MockTimestamp(Date.now()); }
}

class MockDocRef {
  constructor(db, collectionName, id) {
    this._db = db;
    this._collection = collectionName;
    this.id = id;
    this.path = `${collectionName}/${id}`;
  }
}
```

**Setup/teardown:**
```javascript
beforeEach(() => {
  mockSharedDb = new MockFirestore();
  mockFcmSend = jest.fn().mockResolvedValue({ name: 'projects/x/messages/msg1' });
});

afterEach(() => {
  jest.useRealTimers();
  jest.clearAllMocks();
});
```

---

## Test Structure Pattern

### Flutter
```dart
void main() {
  group('FeatureService', () {
    late FeatureService service;
    late MockFirebaseFirestore mockFirestore;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      service = FeatureService(firestore: mockFirestore);
    });

    tearDown(() {
      // Dispose if needed
    });

    group('methodName', () {
      test('happy path description', () {
        // Arrange, Act, Assert
        expect(result, equals(expected));
      });

      test('error path description', () {
        expect(() => service.method(), throwsA(isA<FirebaseException>()));
      });
    });
  });
}
```

### JavaScript
```javascript
describe('FeatureModule', () => {
  beforeEach(() => { /* setup */ });
  afterEach(() => { jest.clearAllMocks(); });

  describe('functionName', () => {
    it('should handle happy path', async () => {
      const result = await functionName(input);
      expect(result).toBeDefined();
      expect(mockFn).toHaveBeenCalledWith(expected);
    });

    it('should handle error case', async () => {
      await expect(functionName(bad)).rejects.toThrow();
    });
  });
});
```

---

## What Gets Tested

### Required Coverage
- All service methods (Firestore operations)
- Provider state transitions and cache invalidation
- Business logic in models (e.g., `Game.resolveGameStatus()`)
- Vibe scoring algorithm changes
- Error paths, not just happy paths
- Firestore limit edge cases (>10 whereIn, >500 batch ops)

### Test Strategies
| Layer | Strategy |
|-------|----------|
| **Services** | Inject mock Firestore, test error handling, test limits |
| **Providers** | Inject mock services, verify notifyListeners, test cache |
| **Controllers** | Verify delegation to services |
| **Widgets** | `pumpWidget` with providers, test interactions |
| **Vibe system** | Comprehensive scoring with various category combinations |

---

## Coverage Gaps (Known)

### Flutter
- No integration tests for auth flows
- No widget tests for large screens (games_list, game_joined_detailed)
- No tests for `ChatService` (985 lines, critical)
- Widget tests sparse overall
- Single integration test: `integration_test/friend_notifications_test.dart`

### Cloud Functions
- Good coverage overall (28+ test files)
- Load testing infrastructure in place
- Behavioral dataset tests exist

---

## CI Integration

```bash
# Flutter
flutter test
flutter analyze

# Cloud Functions
cd firebase/functions
npm test
npm run lint    # ESLint, max 30 warnings

# Hardcoded color check
tool/check_hardcoded_colors.sh
```
