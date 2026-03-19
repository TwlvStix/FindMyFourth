# Architecture

**Analysis Date:** 2026-03-19

## Pattern Overview

**Overall:** Three-layer Provider-Service pattern with reactive Firestore streams and ChangeNotifier state management.

**Key Characteristics:**
- Layered data flow: Widget → Provider → Service → Firestore (no shortcuts)
- Reactive state via Provider package with `ChangeNotifier` and debounced notifications
- Request managers for stream caching with 5-minute TTL and `BehaviorSubject` pooling
- Domain models with shared business logic; legacy `*Record` classes for Firestore schema
- Custom exceptions for error propagation and UI error handling
- Design token-driven UI (colors, typography, spacing, border radius, icons)

## Layers

**Widget Layer:**
- Purpose: Render UI and handle user interactions; display data from providers and call provider methods
- Location: `lib/main_function/`, `lib/chat_group/`, `lib/profile/`, `lib/user_auth/`, `lib/notifications/`, `lib/settings/`, `lib/vibe/`, `lib/friends/`, `lib/screens/`, `lib/user_onboarding/`, `lib/challenge_board/`
- Contains: Feature widgets (suffixed `Widget`), component sub-widgets (feature-prefixed), controllers/view models for stateful logic
- Depends on: Providers (via `context.read<>`, `context.watch<>`, extensions in `provider_extensions.dart`), design tokens, navigation
- Used by: GoRouter for page transitions and navigation

**Provider Layer (State Management):**
- Purpose: Manage global application state with caching, reactivity, and mutation orchestration
- Location: `lib/providers/` (one file per domain: `game_provider.dart`, `chat_provider.dart`, `user_provider.dart`, `trust_provider.dart`, `profile_provider.dart`, `notification_provider.dart`, `notification_list_provider.dart`, `geo_filter_provider.dart`, `join_request_provider.dart`, `group_vibe_provider.dart`, `challenge_provider.dart`, `leaderboard_provider.dart`, `block_provider.dart`, `streak_provider.dart`)
- Contains: `ChangeNotifier` subclasses that wrap services with caching, debounced `notifyListeners()`, cache invalidation on mutations
- Depends on: Services (injected via constructor), `StreamRequestManager`/`FutureRequestManager` for caching, `AppLog` for logging
- Used by: Widgets via extensions (`context.gameProvider`, etc.) or `Provider.of<>`, `Consumer<>`, `Selector<>`

**Service Layer (Business Logic & Firestore):**
- Purpose: Encapsulate Firestore operations, data transformations, and business logic
- Location: `lib/services/` (one file per domain: `game_service.dart`, `chat_service.dart`, `user_profile_service.dart`, `friend_service.dart`, `trust_service.dart`, `notification_*_service.dart`, etc.)
- Contains: Instance classes (injected with `FirebaseFirestore?` for testing), stream/future methods for Firestore reads, mutation methods for writes, batching logic for 10-item `whereIn` limits and 500-operation batch limits, error handling with `FirebaseException` catch
- Depends on: Firestore, Firebase Auth, `rxdart` for stream composition, domain models, custom exceptions
- Used by: Providers (called from provider methods, returned data cached by provider)

**Model Layer (Domain Objects):**
- Purpose: Represent business entities with minimal business logic
- Location: `lib/models/` (domain models: `game.dart`, `chat.dart`, `user_profile.dart`, `vibe_profile.dart`, `trust_profile.dart`, etc.)
- Contains: Classes with `fromDoc()` factory (for `DocumentSnapshot`), `fromRecord()` factory (for `*Record` classes), shared static business logic methods
- Depends on: `lib/backend/schema/*_record.dart` (legacy Firestore schema classes), cloud_firestore for `DocumentReference`
- Used by: Services (return domain models), providers (cache and expose domain models to widgets), widgets (display domain models)

**Schema Layer (Firestore Records):**
- Purpose: Represent raw Firestore document structure (legacy from FlutterFlow migration)
- Location: `lib/backend/schema/` (`users_record.dart`, `games_record.dart`, `chats_record.dart`, etc.)
- Contains: Classes extending `FirestoreRecord`, `_initializeFields()` methods, `hasX()` helper methods
- Used by: Services (map Firestore snapshots to records), converted to domain models by `fromRecord()` factories
- Note: Cannot be removed — deeply embedded in 25+ files. Only update when adding new Firestore fields.

**Core Infrastructure:**
- Navigation: `lib/core/navigation/` (`app_router.dart`, `route_definitions.dart`, `nav_bar_page.dart`, `transition_standards.dart`)
- Design tokens: `lib/core/design_tokens/` (`colors.dart`, `typography.dart`, `spacing.dart`, `border_radius.dart`, `elevation.dart`, `opacity.dart`, `icon_size.dart`, `app_phosphor_icons.dart`)
- Widgets: `lib/core/widgets/` (`app_button_enhanced.dart`, `app_card.dart`, `app_text_field.dart`, `app_icon.dart`, `app_avatar.dart`, reusable components)
- Utilities: `lib/core/utils/` (`app_log.dart`, `firebase_error_utils.dart`, `error_messages.dart`, `app_util.dart`, `input_sanitizer.dart`)
- Exceptions: `lib/core/exceptions/app_exceptions.dart` (custom exception hierarchy)
- Request managers: `lib/core/request_manager.dart` (`StreamRequestManager<T>` for streams, `FutureRequestManager<T>` for futures)
- Bootstrap: `lib/core/bootstrap/app_bootstrap_coordinator.dart` (startup coordination)

## Data Flow

**Read Flow (Firestore → Widget):**

1. Widget calls `context.watch<GameProvider>()` or `context.read<GameProvider>()`
2. Provider has public getter/method that returns cached data or initiates stream
3. If cache miss, provider calls service method: `_service.queryAvailableGames()`
4. Service creates Firestore query and returns `Stream<List<GamesRecord>>`
5. Service applies business logic (filtering, composing streams with `rxdart`)
6. Provider wraps stream in `StreamRequestManager` (caches with `BehaviorSubject`)
7. Provider maps stream to domain models: `GamesRecord` → `Game` via `Game.fromRecord()`
8. Provider stores results in cache with timestamp, debounces `notifyListeners()`
9. Widget receives domain model, renders it
10. On stream emission, provider updates cache and notifies subscribers (debounced 50ms)

**Write Flow (Widget → Firestore → Cache Invalidation):**

1. Widget calls provider mutation method: `await context.read<GameProvider>().joinGame(gameRef)`
2. Provider delegates to service: `_service.joinGame(gameRef, userId)`
3. Service performs Firestore write (transaction for concurrent-safe operations like reactions)
4. Service catches `FirebaseException`, logs with `AppLog.d()` including error code, rethrows
5. Provider receives returned data (or void), invalidates relevant caches
6. Provider calls `_scheduleNotify()` (50ms debounce timer) to signal UI change
7. Timer callback calls `notifyListeners()` only if not disposed
8. Widget listeners receive notification, rebuild with fresh data from provider
9. UI reflects change

**Error Flow:**

1. Service catches `FirebaseException` specifically: `on FirebaseException catch (e) { AppLog.d('...error: ${e.code}...'); rethrow; }`
2. Provider catches error from service, logs again, rethrows to caller
3. Widget awaits provider method call, catches exception
4. Widget displays error via `ScaffoldMessenger.showSnackBar()` or error dialog using `error_messages.dart` mapping

**State Management:**

- **AuthState:** Managed by `AppState` (legacy, holds SharedPreferences-backed cancelled game state). Auth status tracked via `AppStateNotifier` (singleton, refreshListenable for GoRouter)
- **Providers:** Each domain provider manages its own state (game list, chat messages, user profiles, notification settings)
- **Cache:** TTL-based (5 minutes) with `Map<String, DateTime>` timestamps. Stream caches use `StreamRequestManager` which pools `BehaviorSubject` instances
- **Notifications:** Debounced at 50ms via `_scheduleNotify()` timer (prevents UI jank from rapid Firestore updates)

## Key Abstractions

**ChangeNotifier-based Providers:**
- Purpose: Wrap services with stateful caching and reactive notifications
- Pattern: Constructor accepts service + optional DI for testing, implements `_disposed` flag, uses `_scheduleNotify()` for debounce, implements cache validation with TTL
- Examples: `GameProvider`, `ChatProvider`, `UserProvider`, `TrustProvider`, `ProfileProvider`, `NotificationProvider`

**StreamRequestManager<T>:**
- Purpose: Pool Firestore stream subscriptions and cache their latest values via `BehaviorSubject`
- Pattern: `performRequest()` checks if stream already cached; if so, returns cached stream; otherwise subscribes and stores both subscription and subject
- Usage: Prevents duplicate listeners on same Firestore query; automatic replay of latest value to new subscribers
- Files: `lib/core/request_manager.dart`

**FutureRequestManager<T>:**
- Purpose: Cache Future results (one-time queries) with configurable limit
- Pattern: `performRequest()` checks if future already cached; if so, returns cached future; otherwise executes and stores
- Usage: For non-reactive queries (single fetch vs. streaming)

**Custom Exceptions:**
- Purpose: Provide semantic error types for domain-specific failures
- Hierarchy: `AppException` (base) → `GameOperationException`, `ChatOperationException`, `FriendOperationException`, `PermissionException`, `NetworkException`, `JoinRequestException`, `BlockOperationException`
- Usage: Caught in UI layer and mapped to user messages via `error_messages.dart`
- File: `lib/core/exceptions/app_exceptions.dart`

**Domain Models with Factory Constructors:**
- Purpose: Transform Firestore records/snapshots into business objects with shared logic
- Pattern: `fromDoc(DocumentSnapshot)`, `fromRecord(RecordClass)`, static business logic methods for shared logic
- Example: `Game.resolveGameStatus()` called by both `fromDoc()` and `fromRecord()` to avoid duplication
- Files: `lib/models/game.dart`, `lib/models/chat.dart`, `lib/models/user_profile.dart`, etc.

**AppState (Legacy):**
- Purpose: Holds transient UI state (e.g., which games user cancelled today) persisted to SharedPreferences
- Pattern: Single `ChangeNotifierProvider` in main.dart, accessed via `context.read<AppState>()` or `context.select<AppState, T>()`
- Note: Being phased out — new features should use domain-specific providers

**AppIcon & AppPhosphorIcons:**
- Purpose: Centralized icon system using Phosphor Icons library
- Pattern: Always use `AppIcon(icon: AppPhosphorIcons.xxx, size: AppIconSize.md, color: AppColors.textSecondary)` with design tokens
- File: `lib/core/widgets/app_icon.dart`, `lib/core/design_tokens/app_phosphor_icons.dart`

**Design Token System:**
- Purpose: Single source of truth for visual design (colors, typography, spacing, elevation, border radius, opacity, icon sizes)
- Pattern: Dart constants in `lib/core/design_tokens/` (never hardcode `Color()`, `fontSize`, `SizedBox(height: 16)`, etc.)
- Files: `colors.dart` ("The Clubhouse" palette with green/navy/gold roles), `typography.dart` (Fraunces/Manrope/DM Mono), `spacing.dart` (8-point grid), `border_radius.dart`, `elevation.dart`, `opacity.dart`, `icon_size.dart`

## Entry Points

**Application Startup:**
- Location: `lib/main.dart`
- Triggers: Device launch
- Responsibilities: Initialize Firebase, set up error handlers, load persisted app state, create provider tree, start `AppBootstrapCoordinator`, remove native splash, navigate based on auth state

**Bootstrap Coordinator:**
- Location: `lib/core/bootstrap/app_bootstrap_coordinator.dart`
- Triggers: After `main()` creates root widget
- Responsibilities: Listen to auth state changes, update `AppStateNotifier`, trigger notification orchestration on user change, coordinate splash screen removal, navigate from startup based on login state

**Routes & Navigation:**
- Location: `lib/core/navigation/app_router.dart`, `lib/core/navigation/route_definitions.dart`
- Triggers: GoRouter imperative navigation (`context.push()`, `context.go()`) or auth state changes
- Responsibilities: Build route tree, apply auth redirects, manage transition animations, pass parameters via `state.extra`

**Feature Screens:**
- Location: `lib/{feature}/{feature}_widget.dart` (e.g., `lib/main_function/games_list/games_list_widget.dart`)
- Triggers: Navigation to route
- Responsibilities: Initialize providers, set up streams, handle user interactions, delegate state mutations to providers

## Error Handling

**Strategy:** Explicit error propagation with semantic custom exceptions and user-friendly error messages

**Patterns:**

1. **Service Layer:**
   - Catch `FirebaseException` specifically (not generic)
   - Log with `AppLog.d('❌ ServiceName.method error: ${e.code} - ${e.message}')`
   - Rethrow to provider

2. **Provider Layer:**
   - Catch errors from service calls
   - Log with `AppLog.d('❌ Error calling service: $error')`
   - Rethrow to caller (widget) — let UI decide how to handle
   - For stream errors, log and continue (don't fail entire provider)

3. **Widget Layer:**
   - Catch exceptions from `await provider.method()`
   - Map exception to user message via `error_messages.dart` or custom handling
   - Display via `ScaffoldMessenger.showSnackBar()` or dialog
   - Never swallow errors silently

4. **Special Case — Non-Critical Async Operations:**
   - For operations that shouldn't fail the parent flow (e.g., typing status updates after chat join), catch generically and log: `catch (e) { AppLog.d('⚠️ Non-critical op failed: $e'); }`
   - Don't rethrow; parent operation continues

**Error Utilities:**
- `lib/core/utils/firebase_error_utils.dart` — Map Firebase error codes to user-friendly messages
- `lib/core/utils/error_messages.dart` — App-wide error message constants

## Cross-Cutting Concerns

**Logging:**
- Framework: `AppLog.d()` (custom wrapper around `debugPrint`)
- Never use `print()` or `debugPrint()` directly
- Emoji prefixes for readability: ✅ success, ❌ error, 📖 info, 📱 chat, 🔵 stream, 💬 chat UI, 🔥 cache, 🆕 fetches, ⚠️ warnings
- Example: `AppLog.d('✅ Game joined: $gameId')`
- File: `lib/core/utils/app_log.dart`

**Validation:**
- Input sanitization via `lib/core/utils/input_sanitizer.dart` (e.g., trim strings, validate email format)
- Performed in both widget (pre-send) and service (on receipt) for defense in depth
- Custom validation logic in domain models (e.g., `Game.resolveGameStatus()` validates date/schedule logic)

**Authentication:**
- Handled by FirebaseAuth with custom `BaseAuthUser` and `FindMyFourthFirebaseUser` wrapper
- Auth state piped through `AppStateNotifier` (singleton) to GoRouter's `refreshListenable`
- Unauthenticated users redirected to `/signIn` via `buildRedirect()` in `app_router.dart`
- JWT token stream monitored for token refresh

**Performance:**
- Debounced `notifyListeners()` at 50ms per provider (prevents UI jank from rapid Firestore updates)
- Request managers with configurable cache limits (default 10 entries)
- Firestore batch limits enforced: 10-item max for `whereIn`, 500-operation max for batch writes
- Chunk pattern in `ChatService.getChatListStream()` breaks large queries into 10-item batches
- Caching TTL set to 5 minutes (configurable per provider)

**Feature Flags:**
- Remote Config via `RemoteConfigService` (defaults set before `runApp()`, network fetch deferred post-frame)
- Build flags via `lib/core/config/build_flags.dart` (APP_ENV, USE_FIREBASE_EMULATOR, ENABLE_DEV_UI, CRASHLYTICS_ENABLED)
- Determined at compile time via `--dart-define` flags

**Crash Reporting:**
- Firebase Crashlytics (enabled in release mode)
- Errors logged with context via `FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: '...')`
- Sync errors routed through `runZonedGuarded` in `main.dart`

---

*Architecture analysis: 2026-03-19*
