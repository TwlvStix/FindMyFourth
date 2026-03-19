# Architecture

## Overall Pattern

Find My Fourth follows a **layered architecture** with strict separation of concerns:

```
Widget Layer (UI)
    ↓
Provider Layer (State Management)
    ↓
Service Layer (Business Logic & Firestore Access)
    ↓
Backend/Firebase (Firestore, Auth, Cloud Functions)
```

**Core rule**: Widget → Provider → Service → Firestore. No layer-skipping. Providers never access Firebase directly; services handle all Firestore operations.

---

## Layer Responsibilities

### Widget Layer (`lib/` feature folders)
- UI presentation only
- No Firebase calls, no service instantiation
- Access state via Provider extensions: `context.gameProvider`, `context.watchGameProvider`
- Navigation via GoRouter with `go_router` 17.1.0
- Routes defined as static `routeName`/`routePath` constants on widgets

### Provider Layer (`lib/providers/`)
- State management via `ChangeNotifier`
- Wraps services with caching (5-minute TTL) and debouncing (50ms `_scheduleNotify()`)
- Uses `StreamRequestManager` for reactive Firestore streams with `BehaviorSubject`
- Checks `_disposed` flag before all `notifyListeners()` calls
- Catches errors from services, logs, and rethrows to UI layer
- Access: typed extensions in `lib/providers/provider_extensions.dart`

### Service Layer (`lib/services/`)
- Instance classes with optional `FirebaseFirestore` DI for testability
- Pure Firestore operations (queries, mutations, streams)
- Business logic (eligibility, vibe matching, trust calculations)
- Catches `FirebaseException` specifically, logs with `AppLog.d()`, rethrows
- Respects Firestore limits: 500-op batches, 10-item `whereIn` (chunking)

### Backend/Firebase
- **Firestore**: Main database (34+ collections)
- **Firebase Auth**: 7 auth providers
- **Cloud Functions**: Node.js 22, confirmation/notification/trust logic
- **Cloud Storage**: Avatar and image uploads
- **FCM**: Push notification delivery

---

## Key Providers

| Provider | File | Responsibility |
|----------|------|---------------|
| **UserProvider** | `lib/providers/user_provider.dart` | Current user, auth, friends |
| **GameProvider** | `lib/providers/game_provider.dart` | Game listings, joins, mutations |
| **ChatProvider** | `lib/providers/chat_provider.dart` | Real-time chat, messages, reactions |
| **ProfileProvider** | `lib/providers/profile_provider.dart` | User profiles, search, batch fetch |
| **NotificationProvider** | `lib/providers/notification_provider.dart` | Push notification state, FCM tokens |
| **NotificationListProvider** | `lib/providers/notification_list_provider.dart` | Notification history, filtering |
| **TrustProvider** | `lib/providers/trust_provider.dart` | Trust scores, profiles, flow state |
| **JoinRequestProvider** | `lib/providers/join_request_provider.dart` | Join requests (sent/received) |
| **GroupVibeProvider** | `lib/providers/group_vibe_provider.dart` | Group vibe compatibility |
| **GeoFilterProvider** | `lib/providers/geo_filter_provider.dart` | Geographic filtering |
| **StreakProvider** | `lib/providers/streak_provider.dart` | Streak tracking, leaderboard |
| **ChallengeProvider** | `lib/providers/challenge_provider.dart` | Challenge progress |
| **LeaderboardProvider** | `lib/providers/leaderboard_provider.dart` | Leaderboard data |
| **BlockProvider** | `lib/providers/block_provider.dart` | Blocked users |

---

## Key Services

| Service | File | Responsibility |
|---------|------|---------------|
| **GameService** | `lib/services/game_service.dart` | Game CRUD, queries, join/leave, eligibility |
| **ChatService** | `lib/services/chat_service.dart` | Message CRUD, typing, reactions, streams |
| **FriendService** | `lib/services/friend_service.dart` | Friend add/remove, requests |
| **ProfileService** | `lib/services/profile_service.dart` | Profile data fetching, batch ops |
| **VibeMatcher** | `lib/services/vibe_matcher.dart` | Core vibe compatibility algorithm |
| **VibeGroupMatcher** | `lib/services/vibe_group_matcher.dart` | Group compatibility |
| **TrustFlowService** | `lib/services/trust_flow_service.dart` | Trust rating flows |
| **TrustRepository** | `lib/services/trust_repository.dart` | Trust score queries, caching |
| **JoinRequestService** | `lib/services/join_request_service.dart` | Join request lifecycle |
| **AlertSubscriptionService** | `lib/services/alert_subscription_service.dart` | Game alert subscriptions |
| **NotificationOrchestrationService** | `lib/services/notification_orchestration_service.dart` | Notification scheduling |
| **FcmNotificationService** | `lib/services/fcm_notification_service.dart` | FCM token management |
| **LocalNotificationsService** | `lib/services/local_notifications_service.dart` | Local push display |
| **StreakService** | `lib/services/streak_service.dart` | Streak calculation |
| **ChallengeService** | `lib/services/challenge_service.dart` | Challenge progress |
| **BlockService** | `lib/services/block_service.dart` | Block/unblock operations |
| **PlayerSearchService** | `lib/services/player_search_service.dart` | Player name search |
| **RebookService** | `lib/services/rebook_service.dart` | Game rebook/reschedule |
| **RemoteConfigService** | `lib/services/remote_config_service.dart` | Feature flags |
| **CreateGameService** | `lib/services/create_game_service.dart` | Game creation |
| **GameEligibilityService** | `lib/services/game_eligibility_service.dart` | Join eligibility checks |

---

## Data Models

### Domain Models (`lib/models/`)
| Model | Purpose |
|-------|---------|
| **Game** | Game with status resolution (active/expired/cancelled) |
| **Chat** | Chat thread metadata |
| **ChatMessage** | Individual message with reactions |
| **UserProfile** | Minimal user representation |
| **VibeProfile** | Vibe preferences and scores |
| **JoinRequest** | Join request with status tracking |
| **AlertSubscription** | Game alert preferences |
| **Challenge** / **ChallengeProgress** | Challenge definitions and tracking |
| **LeaderboardEntry** | Rankings data |
| **StreakProfile** | Current/historical streak data |
| **CancellationRecord** | Cancellation with reason |
| **NotificationPreferences** | User notification settings |
| **Course** | Golf course info |
| **PlayerEligibility** | Join eligibility result |

### Backend Schema Records (`lib/backend/schema/`)
Firestore record classes extending `FirestoreRecord` (FlutterFlow legacy, deeply embedded):

| Record | Collection |
|--------|-----------|
| **UsersRecord** | `users/` (29+ file references) |
| **GamesRecord** | `games/` (13+ file references) |
| **GameParticipantsRecord** | `games/{id}/game_participants/` |
| **ChatsRecord** | `chats/` |
| **ChatMessagesRecord** | `chats/{id}/messages/` |
| **CancellationRecordsRecord** | `cancellation_records/` |
| **RoundRecordsRecord** | `round_records/` |

**Conversion**: `Game.fromRecord(gamesRecord)` bridges schema records to domain models.

---

## Entry Points & Bootstrap

### `lib/main.dart` — App Entry
```
main()
├─ WidgetsFlutterBinding.ensureInitialized()
├─ initFirebase()
│  ├─ Firebase.initializeApp()
│  ├─ _initAppCheck()
│  └─ Emulator setup (if debug + flag)
├─ _setupErrorHandlers() → Crashlytics
├─ AppState.initializePersistedState() (SharedPreferences)
├─ RemoteConfigService.instance.ensureDefaults() (blocking, <1ms)
├─ runApp(MultiProvider([all providers]))
└─ addPostFrameCallback:
   ├─ _initializeNonCriticalServices()
   │  ├─ _configureCrashlyticsMetadata()
   │  └─ RemoteConfigService.instance.initialize() (async fetch)
   └─ AppBootstrapCoordinator.start()
      ├─ Listen to auth state stream
      ├─ Update AppStateNotifier
      ├─ Initialize NotificationOrchestrationService
      └─ Remove native splash when auth ready
```

### `lib/core/navigation/app_router.dart` — Navigation
- `AppStateNotifier`: Singleton managing auth state and redirects
- `createRouter()`: GoRouter with auth-aware guards via `buildRedirect()`
- Route definitions centralized in `lib/core/navigation/route_definitions.dart`
- Transitions via `TransitionStandards` presets (modal, detail, dismissal, tab)

### `lib/core/bootstrap/app_bootstrap_coordinator.dart` — Auth Stream
- Listens to Firebase auth state changes
- Updates `AppStateNotifier` to trigger app refresh
- Removes native splash when auth ready
- Initializes notification service on user change

---

## Error Handling Strategy

### Exception Hierarchy (`lib/core/exceptions/app_exceptions.dart`)
```
AppException (base: message, code?, cause?)
├─ GameOperationException
├─ FriendOperationException
├─ ChatOperationException
├─ PermissionException
├─ NetworkException
├─ JoinRequestException
└─ BlockOperationException
```

### Pattern by Layer
- **Services**: `on FirebaseException catch (e)` → log with `AppLog.d()` → rethrow
- **Providers**: catch from services → log → rethrow to UI
- **UI**: catch from providers → display via `AppSnackbar`
- **Non-critical ops** (typing, membership sync): generic `catch` → log silently

### Error Utilities
- `lib/core/utils/error_messages.dart` — Firebase code → user message mapping
- `lib/core/utils/firebase_error_utils.dart` — Firebase error helpers

---

## Cross-Cutting Concerns

### Logging (`lib/core/utils/app_log.dart`)
- `AppLog.d()` only — never `print()`/`debugPrint()`
- Debug-mode only (assertion-based), redacts sensitive data
- Emoji prefixes: ✅ success, ❌ error, 📖 info, 📱 chat ops, 🔵 streams, 💬 chat UI, 🔥 cache, 🆕 fetches

### Design System (`lib/core/design_tokens/`)
- Three color roles: Green (CTAs), Navy (structure), Gold (accent)
- Three font families: Fraunces (serif), Manrope (sans), DM Mono (mono)
- 8-point spacing grid with semantic tokens
- Phosphor Icons primary, SVG deprecated
- Motion tokens with reduced motion support

### Notification System
- FCM setup → Permission management → Orchestration → Local display → Audit trail
- Quiet hours via Cloud Functions scheduling
- Cloud Tasks for deferred delivery with OIDC verification
