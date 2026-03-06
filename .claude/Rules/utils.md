---
paths: lib/utils/**/*.dart
---
# Utility File Rules

Utility files provide shared helper functions used across the app. They must NOT become a dumping ground for service-layer logic.

## No Direct Firebase
- NEVER call `FirebaseFirestore.instance`, `FirebaseAuth.instance`, or any Firebase service directly
- If a utility needs Firestore data, accept it as a parameter — let the calling service fetch it
- Utilities transform, format, or compute — they do not read or write to backends

**Known debt** (all have optional DI, acceptable as pure reference builders or utilities):
- `initialize_friend_fields.dart` — One-time migration utility, uses `FirebaseAuth.instance` as fallback
- `app_util.dart` — `toDocRef()` extension, pure reference builder with DI
- `custom_functions.dart` — `returnDocRefFromUID()`, pure reference builder with DI
- `serialization_util.dart` — Calls `.get()` for document fetching; should be refactored to a service when next modified

## Pure Functions Preferred
- Utility methods should be pure functions where possible (same input → same output, no side effects)
- If state is needed, the utility probably belongs in a service or provider instead

## Logging
- Use `AppLog.d()` if logging is needed, never `print()` or `debugPrint()`

## Location
- General-purpose utilities go in `lib/utils/`
- Core framework utilities go in `lib/core/utils/`
- Feature-specific helpers should live in their feature folder, not in a shared utils directory
