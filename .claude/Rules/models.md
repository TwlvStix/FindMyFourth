---
paths: lib/models/**/*.dart
---
# Model Rules

## Dual Data Layer
The app has two data representations (legacy from original code generation):

- `backend/schema/*_record.dart` — Firestore record classes. Extend `FirestoreRecord`. These are deeply embedded and must not be removed.
- `models/*.dart` — Domain model classes with business logic and `fromDoc()`/`fromRecord()` factory methods.

## When Adding Fields
- New Firestore fields: update the `*Record` class first
- If the field needs business logic: also update the corresponding domain model
- Never duplicate business logic across `fromDoc()` and `fromRecord()` — use shared static methods (e.g., `Game.resolveGameStatus()`)

## Conventions
- Domain models use `PascalCase` class names matching the entity: `Game`, `Chat`, `UserProfile`, `VibeProfile`
- Factory constructors: `fromDoc(DocumentSnapshot)`, `fromRecord(RecordClass)`
- Use `const` constructors where possible
- Include `copyWith()` for immutable updates
