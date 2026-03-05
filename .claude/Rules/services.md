---
paths:
  - lib/services/**/*.dart
  - lib/**/controllers/**/*.dart
  - lib/providers/**/*.dart
---
# Service Layer Rules

## ⛔ No Direct Firebase Calls Outside Services

Firebase SDK calls are only permitted in `lib/services/`, `lib/backend/schema/` (legacy records), and `lib/backend/firebase/` (init). **Controllers and providers must never import or call Firebase directly.**

This applies to:
- `FirebaseAuth.instance` / `FirebaseAuth.instance.currentUser`
- `FirebaseFirestore.instance.collection(...)` / `.doc(...)`
- Any direct Firestore query, snapshot, or stream

**If the service method you need doesn't exist yet — create it first, then call it.**

```dart
// ❌ Never in a controller or provider
final uid = FirebaseAuth.instance.currentUser?.uid;
final snap = await FirebaseFirestore.instance.collection('users').get();

// ✅ Add to the relevant service, then call it
// In ProfileService:
Future<String?> getCurrentUserId() => FirebaseAuth.instance.currentUser?.uid;
// In controller:
final uid = await _profileService.getCurrentUserId();
```

The data flow is: **Widget → Controller → Provider → Service → Firebase**. Each layer only talks to the layer below it.

## Class Structure
- Services are instance classes, not static-only
- Accept `FirebaseFirestore?` via constructor for testability:
  ```dart
  class FeatureService {
    final FirebaseFirestore _firestore;
    FeatureService({FirebaseFirestore? firestore})
        : _firestore = firestore ?? FirebaseFirestore.instance;
  }
  ```

## Size Limit
Service files should stay under 500 lines. If approaching this limit, split by sub-domain (e.g., `ChatService` → `ChatService` + `ChatMembershipService`). Large services accumulate mixed responsibilities — keep them focused.

## Error Handling
- NEVER use generic `catch (e)`. Always catch specific exceptions:
  ```dart
  on FirebaseException catch (e) {
    AppLog.d('❌ ServiceName.method error: ${e.code} - ${e.message}');
    rethrow;
  }
  ```
- Non-critical operations (chat membership sync, typing status): generic catch is acceptable but MUST log
- Never swallow errors silently — always log, then rethrow or return typed failure

## Firestore Limits
- `whereIn` queries: max 10 items. Use chunk pattern for larger sets.
- Batch writes: max 500 operations per batch
- Use transactions for concurrent-safe operations (reactions, joins, chat creation)

## Streams & Subscriptions
- Use `rxdart` (`switchMap`, `combineLatestList`) for composing complex Firestore streams
- Use `StreamRequestManager` with `BehaviorSubject` caching for reactive data
- Any `StreamSubscription` created in a service MUST have a corresponding cancel mechanism

## Documentation
- Document public methods with `///` doc comments explaining what Firestore operations they perform
- Include parameter expectations and return types in the doc comment
- Complex query logic should have inline comments explaining the Firestore query strategy

## Logging
- Use `AppLog.d()` with emoji prefixes: ✅ success, ❌ error, 📖 info, 🔥 cache, 🆕 new fetch
- Never use `print()` or `debugPrint()`

## Location
- All new services go in `lib/services/`
- Do NOT create service logic in `lib/backend/api_requests/` (legacy location)
