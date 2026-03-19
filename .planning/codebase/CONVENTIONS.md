# Coding Conventions

**Analysis Date:** 2026-03-19

## Naming Patterns

**Files:**
- Snake case: `game_provider.dart`, `app_button_enhanced.dart`, `vibe_scoring_test.dart`
- Widget screens suffixed with `Widget`: `games_list_widget.dart`, `create_game_widget.dart`
- Reusable core widgets prefixed with `app_`: `app_button_enhanced.dart`, `app_card.dart`, `app_icon.dart`
- Service files: `game_service.dart`, `vibe_repository.dart`, `chat_service.dart`
- Provider files: `game_provider.dart`, `vibe_provider.dart`, `profile_provider.dart`
- Model files: `game.dart`, `vibe_profile.dart`, `user_profile.dart`
- Firestore record files: `games_record.dart`, `users_record.dart` (in `lib/backend/schema/`)
- Test files: `*_test.dart` or `*.test.js` (mirrors `lib/` directory structure)

**Functions:**
- Camel case: `getGame()`, `joinGame()`, `updateCategory()`, `scheduleJob()`
- Private functions start with underscore: `_scheduleNotify()`, `_invalidateCache()`, `_firebaseException()`
- Factory constructors: `fromDoc()`, `fromRecord()`, `fromSnapshot()`
- Async operations use future/stream return types: `Future<Game>`, `Stream<List<GamesRecord>>`

**Variables:**
- Camel case: `gameId`, `playerCount`, `isEnabled`, `hasLocation`
- Private fields start with underscore: `_gameCache`, `_notifyTimer`, `_disposed`, `_service`
- Boolean fields prefixed with `is`, `has`, `should`: `isEnabled`, `hasLocation`, `shouldFailOnLoad`
- Constants: ALL_CAPS with underscores: `const Duration _cacheTTL`, `const String visibilityPublic`

**Types:**
- PascalCase for classes: `GameProvider`, `GamesRecord`, `Game`, `VibeProfile`, `AppException`
- Enums with PascalCase variants: `enum AppButtonVariant { primary, secondary, ghost }`, `enum VibeCategory { drinking, pace, skill }`
- Generic types use angle brackets: `Stream<List<GamesRecord>>`, `Map<String, DateTime>`

**Design Tokens:**
- Constant names follow token scope: `AppColors.green`, `AppColors.navyDark`, `AppSpacing.card`, `AppBorderRadius.button`
- Token constants grouped by category in dedicated files: `lib/core/design_tokens/colors.dart`, `typography.dart`, `spacing.dart`, `elevation.dart`

## Code Style

**Formatting:**
- Dart: Flutter/Dart SDK default conventions
- JavaScript: ESLint with recommended preset (eslint:recommended)
- Line width: Follows Flutter conventions (prefer ~80 chars but not strictly enforced)
- Indentation: 2 spaces (JavaScript), automatic Dart formatting

**Linting:**
- Dart: `flutter_lints` 6.0.0 with strict rules enabled
  - `strict-casts: true`
  - `strict-raw-types: true`
  - `use_build_context_synchronously: warning`
  - `cancel_subscriptions: warning`
  - Excluded: `lib/custom_code/**` (legacy, exempted from analysis)
- JavaScript: ESLint with lax rules (`no-unused-vars: warn`, `no-empty: warn`)

**Dart Type Checking:**
- Strict casts and raw types required
- No bare `dynamic` types without justification
- Explicit generics in collections: `List<String>` not `List`

## Import Organization

**Order (Dart):**
1. Absolute imports from `package:` (Flutter SDK): `import 'package:flutter/foundation.dart';`
2. Absolute imports from `package:` (third-party): `import 'package:provider/provider.dart';`
3. Absolute project imports with leading slash: `import '/services/game_service.dart';`
4. Relative imports only in tests or special cases

**Pattern:**
```dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/backend.dart';
import '/core/utils/app_log.dart';
import '/services/game_service.dart';
```

**Project imports use leading slash, never package paths:**
- CORRECT: `import '/models/game.dart';`
- INCORRECT: `import 'package:find_my_fourth/models/game.dart';`

**Path aliases:**
- None currently defined (project uses absolute paths with `/`)

## Error Handling

**Pattern - Services:**
- Catch `FirebaseException` specifically (not generic `catch`)
- Log with `AppLog.d()` including error code and message
- Always rethrow exceptions (do not swallow)

**Example:**
```dart
try {
  final game = await _firestore.collection('games').doc(gameId).get();
  return GamesRecord.fromSnapshot(game);
} on FirebaseException catch (e) {
  AppLog.d('❌ GameService.getGameById error: ${e.code} - ${e.message}');
  rethrow;
}
```

**Pattern - Providers:**
- Catch errors from services
- Log with `AppLog.d()` with emoji prefix
- Rethrow to UI layer (UI decides how to display)
- Do not suppress errors silently

**Pattern - Non-critical operations:**
- Catch with generic `catch` only for optional side effects (e.g., chat membership sync after join)
- Log silently, do not fail parent operation

**Custom exceptions:**
- Base class: `AppException` (in `lib/core/exceptions/app_exceptions.dart`)
- Domain-specific subclasses: `GameOperationException`, `FriendOperationException`, `ChatOperationException`, `PermissionException`, `NetworkException`, `JoinRequestException`, `BlockOperationException`
- Always include `message`, optional `code` and `cause` fields
- Used for app-level error translation (Firebase errors → app errors)

## Logging

**Framework:**
- Use `AppLog.d()` from `lib/core/utils/app_log.dart` everywhere
- Never use `print()` or `debugPrint()` (AppLog handles debug output)
- Automatic redaction of bearer tokens and query parameters containing `token`, `auth`, `password`

**Patterns:**
- Use emoji prefixes for log readability and filtering:
  - ✅ - success/completion
  - ❌ - error
  - 📖 - info/debug
  - 📱 - chat operations
  - 🔵 - stream events
  - 💬 - chat UI
  - 🔥 - cache warming
  - 🆕 - new fetches
  - 🚦 - conditional logic/status

**Example:**
```dart
AppLog.d('❌ GameProvider.getGame error: $e');
AppLog.d('🚦 GameProvider.joinGame: Player requires approval (score: ${eligibility.vibeScore}, floor: ${eligibility.vibeFloor})');
AppLog.d('✅ Profile updated successfully');
```

## Comments

**When to Comment:**
- Complex business logic or algorithms (e.g., vibe scoring, eligibility checks)
- Non-obvious Firestore field mappings
- Workarounds for limitations (e.g., 10-item `whereIn` limit, 500-operation batch limit)
- Integration points between providers and services
- Do NOT comment obvious code

**JSDoc/TSDoc:**
- Dart: Class and method doc comments with `///` (not currently strict but recommended for public APIs)
- JavaScript: Minimal comments, test coverage preferred
- Example (Dart):
  ```dart
  /// GameProvider manages global game state with caching and reactive streams
  ///
  /// - Caching with 5-minute TTL
  /// - StreamRequestManager for Firestore subscriptions
  /// - Cache invalidation after mutations
  class GameProvider extends ChangeNotifier { }
  ```

## Function Design

**Size:**
- Prefer functions under 50 lines
- Services: ~30 lines average (pure Firestore operations)
- Providers: split if approaching 500 lines (see `ChatProvider` → `ChatViewModelManager` pattern)
- Widgets: decompose into sub-widgets at 300+ lines

**Parameters:**
- Named parameters for optional values: `Future<Game> getGame(String id, {bool forceRefresh = false})`
- Positional parameters for required values: `String getGameStatus(Game game)`
- Use default values to reduce overloads: `GameService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;`

**Return Values:**
- Explicit types (no `dynamic` or bare types)
- Futures for async: `Future<GamesRecord>`, not `Future`
- Streams for reactive: `Stream<List<GamesRecord>>`
- Nullable when absence is valid: `GamesRecord?`, `DateTime?`
- Collections are never null (use empty instead): `List<String>` returns `[]` not `null`

## Module Design

**Exports:**
- Services export nothing (instantiated with constructor injection)
- Providers export their `ChangeNotifier` class (accessed via provider extensions)
- Models export the model class with factory constructors
- Design tokens export constants: `AppColors`, `AppTypography`, `AppSpacing`, etc.

**Barrel Files:**
- Used in `lib/backend/backend.dart` (exports all Firestore record classes)
- Preferred for grouping related record exports
- Not used for service/provider exports (prefer direct imports)

**Example:**
```dart
// lib/backend/backend.dart (barrel)
export '/backend/schema/games_record.dart';
export '/backend/schema/users_record.dart';
export '/backend/schema/chats_record.dart';

// Usage
import '/backend/backend.dart'; // Gets all record classes
```

## No-Op Guards

**Provider setters:**
- Always guard against no-op updates (same value set twice)
- Prevents unnecessary `notifyListeners()` calls and UI rebuilds

**Pattern:**
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

## Design Token Usage

**Critical rule - no hardcoded values:**
- Colors: Use `AppColors` tokens, not `Color(0x...)` or `Colors.blue`
- Typography: Use `AppTypography` tokens, not `fontSize: 14`
- Spacing: Use `AppSpacing` tokens, not `EdgeInsets.all(16)`
- Border radius: Use `AppBorderRadius` tokens, not `BorderRadius.circular(12)`
- Icon sizes: Use `AppIconSize` tokens with `AppIcon`, not raw `Icon(size: 24)`
- Elevation/shadows: Use `AppElevation` tokens, not hardcoded `BoxShadow`
- Opacity: Use `AppOpacity` tokens, not `.withOpacity(0.5)`

**Icons:**
- Primary icon system: `phosphor_flutter` (PhosphorIcons)
- Always use `AppIcon` widget with `AppPhosphorIcons` and `AppIconSize` tokens
- For navigation with active/inactive states, use `AppNavIcon` with `icon` and `iconFill` variants
- Never use raw `Icon()` with hardcoded sizes
- Legacy SVG system (`AppIcons`) deprecated - do not use for new code

**Example (WRONG):**
```dart
// ❌ Hardcoded values
Icon(Icons.check, color: Color(0xFF2E7D32), size: 24)
Text('Hello', style: TextStyle(fontSize: 14, color: Colors.grey[700]))
SizedBox(width: 16)
```

**Example (CORRECT):**
```dart
// ✅ Using tokens
AppIcon(icon: AppPhosphorIcons.checkCircle, color: AppColors.green, size: AppIconSize.md)
AppText('Hello', style: AppTypography.bodyMedium, color: AppColors.textSecondary)
SizedBox(width: AppSpacing.md)
```

---

*Convention analysis: 2026-03-19*
