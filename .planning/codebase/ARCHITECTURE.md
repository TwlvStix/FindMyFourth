# Architecture

**Analysis Date:** 2026-01-14

## Pattern Overview

**Overall:** Feature-layered Clean Architecture with reactive state management

**Key Characteristics:**
- Flutter mobile app with Provider state management pattern
- Firebase Firestore backend with real-time streams
- Multi-layer architecture: UI, State, Services, Data
- Reactive data flow using streams and StreamBuilder
- Authentication via Firebase Auth with JWT tokens

## Layers

**Entry Point & App Setup:**
- Purpose: App initialization and configuration
- Contains: Firebase setup, Provider configuration, routing
- Location: `lib/main.dart`, `lib/core/navigation/app_router.dart`
- Depends on: Firebase SDK, Provider, GoRouter
- Used by: Platform launcher (Android/iOS)

**State Management Layer (Providers):**
- Purpose: Global app state and cached data
- Contains: Provider classes wrapping services
- Location: `lib/providers/user_provider.dart`, `lib/providers/chat_provider.dart`
- Depends on: Services layer, Firebase streams
- Used by: UI widgets via Provider.of() or context.watch()
- Pattern: Provider + ChangeNotifier + StreamRequestManager for caching

**Service Layer (Business Logic):**
- Purpose: Core business logic and Firestore operations
- Contains: ChatService, VibeMatcher, VibeGroupMatcher, VibeRepository
- Location: `lib/services/chat_service.dart`, `lib/services/vibe_matcher.dart`, `lib/services/vibe_group_matcher.dart`, `lib/services/vibe_repository.dart`
- Depends on: Backend/Data layer, Firebase SDK
- Used by: Providers, occasionally widgets directly
- Pattern: Service classes with transaction-based Firestore operations

**Data Access Layer (Backend):**
- Purpose: Firestore query functions and schema definitions
- Contains: Query builders, Record classes, Firebase config
- Location: `lib/backend/backend.dart`, `lib/backend/schema/*.dart`, `lib/backend/firebase/firebase_config.dart`
- Depends on: Firebase SDK only
- Used by: Services layer
- Pattern: Auto-generated Record classes with serialization

**Authentication Layer:**
- Purpose: User authentication and session management
- Contains: Firebase Auth operations, social auth providers
- Location: `lib/auth/firebase_auth/firebase_auth_manager.dart`, `lib/auth/firebase_auth/google_auth.dart`, `lib/auth/firebase_auth/apple_auth.dart`
- Depends on: Firebase Auth SDK
- Used by: AppStateNotifier for routing decisions
- Pattern: Singleton auth manager with provider-specific implementations

**UI Layer (Widgets/Screens):**
- Purpose: User interface and interaction
- Contains: Screens, widgets, forms
- Location: `lib/main_function/*`, `lib/profile/*`, `lib/chat_group/*`, `lib/user_auth/*`
- Depends on: Providers, theme, navigation
- Used by: User interactions
- Pattern: StatefulWidget with State classes, StreamBuilder for real-time updates

**Core/Shared Components:**
- Purpose: Reusable UI and utilities
- Contains: Custom widgets, design tokens, theme config
- Location: `lib/core/widgets/*`, `lib/core/design_tokens/*`, `lib/core/app_theme.dart`
- Depends on: Flutter Material only
- Used by: UI layer
- Pattern: Reusable component library with consistent styling

## Data Flow

**Authentication Flow:**
1. User starts app → `lib/main.dart` initializes Firebase and AppStateNotifier
2. AppStateNotifier listens to `findMyFourthFirebaseUserStream()`
3. Stream emits user changes → notifier updates and triggers navigation
4. JWT token refreshed hourly via `jwtTokenStream`
5. Auth state determines routing to sign-in or home screen

**Game Query Flow:**
1. Widget calls `UserProvider.getMyGames()` or `getAvailableGames()`
2. Provider wraps request in `StreamRequestManager` for caching
3. Manager executes query from `lib/backend/backend.dart` (queryGamesRecord)
4. Query builder applies filters (joined_players, isCancelled, date)
5. Firestore returns DocumentSnapshot stream
6. GamesRecord converts docs to Game model objects
7. Provider caches results, notifies listeners
8. Widget rebuilds with new data

**Chat Message Flow:**
1. Widget calls `ChatProvider.sendMessage()`
2. ChatProvider delegates to `ChatService.sendMessage()`
3. Service writes to Firestore: `/chats/{chatId}/messages/{messageId}`
4. Service updates parent chat's `lastMessage` and `lastMessageAt`
5. Other users' ChatProvider streams emit updated messages
6. Widgets rebuild via StreamBuilder listening to messagesStream

**Vibe Matching Flow:**
1. User sets vibe preferences in profile
2. `VibeProfile` model stores preferences with thresholds and dealbreaker flags
3. `VibeMatcher.matchScore()` compares user vibes with candidates
4. `VibeGroupMatcher` checks group compatibility for games
5. Matching scores inform recommendations and filters

**State Management:**
- Stream-based: Real-time Firestore data via Firebase streams
- Cached: StreamRequestManager and FutureRequestManager for performance
- Each Provider manages cache invalidation via `refresh*()` methods
- All state updates trigger `notifyListeners()` to rebuild UI

## Key Abstractions

**Request Manager Pattern:**
- Purpose: Cache stream queries with TTL
- Examples: `StreamRequestManager<T>`, `FutureRequestManager<T>` in `lib/core/request_manager.dart`
- Pattern: Wrapper around Firebase queries with manual cache invalidation
- Used in: UserProvider to cache games, friends, courses

**Record/Model Pattern:**
- Purpose: Type-safe Firestore document representation
- Examples: `UsersRecord`, `GamesRecord`, `ChatsRecord` in `lib/backend/schema/`
- Pattern: Auto-generated classes with fromFirestore/toFirestore serialization
- Separation: Backend Record classes vs domain Model classes (`lib/models/`)

**Provider-as-Wrapper Pattern:**
- Purpose: Expose only necessary methods to UI
- Examples: `ChatProvider` wraps `ChatService`, `UserProvider` wraps backend queries
- Pattern: ChangeNotifier providers delegate to service implementations
- Benefit: Testing and service substitution

**Stream-Based Reactivity:**
- Purpose: Real-time updates without polling
- Examples: Most Firestore queries return `Stream<T>` not `Future<T>`
- Pattern: StreamBuilder widgets rebuild on new data
- RxDart: Used for combining streams (e.g., chunking large friend lists)

**Model Conversion:**
- Purpose: Separate Firestore schema from business domain
- Examples: `Game.fromRecord()`, `Chat.fromDoc()` in `lib/models/`
- Pattern: Factory constructors convert Record → Model

## Entry Points

**Main Entry:**
- Location: `lib/main.dart`
- Triggers: Platform launcher (Android/iOS/Web)
- Responsibilities: Initialize Firebase, create MultiProvider, configure theme/routing

**Critical State Holders:**
- `AppStateNotifier` (in `lib/core/navigation/app_router.dart`) - Singleton for auth state and navigation
- `UserProvider` - Global user data and friend/game caches
- `ChatProvider` - Chat-related state

**Navigation Entry:**
- `GoRouter` created in `_MyAppState.initState()`
- Routes defined in `createRouter(AppStateNotifier)` in `lib/core/navigation/app_router.dart`
- Auth state determines initial route (/gamesList or /signIn)

## Error Handling

**Strategy:** Try-catch with rethrow, FirebaseException handling

**Patterns:**
- Services throw errors with context
- Providers catch and rethrow with additional context
- Widgets catch and display user-friendly messages
- Firebase-specific: FirebaseAuthException, FirebaseException with error codes

## Cross-Cutting Concerns

**Logging:**
- Development: debugPrint() with emoji prefixes (💬, 📨, 🔧, ✅, ❌)
- Production: debugPrint() automatically removed by Flutter
- Example: `debugPrint('💬 ChatService: getChatListStream called');`

**Validation:**
- Form validation via GlobalKey<FormState>
- Model validation in domain objects (VibeProfile)
- Firestore security rules for server-side validation

**Authentication:**
- Firebase Auth with JWT tokens
- Multi-provider support (Google, Apple, GitHub, Email, Anonymous)
- AppStateNotifier manages auth-based routing

**Navigation:**
- GoRouter with auth-aware redirect logic
- Named routes with type-safe parameters
- Bottom nav bar (NavBarPage) with 5 tabs

---

*Architecture analysis: 2026-01-14*
*Update when major patterns change*
