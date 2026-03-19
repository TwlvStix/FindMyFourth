# Directory Structure

## lib/ (2 Levels Deep)

```
lib/
├─ main.dart                           # App entry point
├─ app_state.dart                      # Legacy (SharedPreferences only)
│
├─ auth/                               # Authentication layer
│  └─ firebase_auth/                   # Auth managers per provider
│
├─ backend/                            # Firebase config & Firestore records
│  ├─ firebase/                        # Firebase init, emulator setup
│  ├─ push_notifications/              # Push notification handlers
│  ├─ cloud_functions/                 # Cloud function callables
│  ├─ firebase_storage/                # Storage operations
│  └─ schema/                          # Firestore record classes (*Record)
│
├─ core/                               # Cross-cutting concerns
│  ├─ bootstrap/                       # Startup coordination
│  ├─ config/                          # Build flags (APP_ENV, etc.)
│  ├─ content/                         # Microcopy constants (app_copy.dart)
│  ├─ design_tokens/                   # Design system source of truth
│  ├─ design_patterns/                 # Reusable premium UI patterns
│  ├─ exceptions/                      # Custom exception hierarchy
│  ├─ motion/                          # Animation curves & durations
│  ├─ navigation/                      # GoRouter, routes, transitions
│  ├─ utils/                           # Logging, errors, formatting
│  └─ widgets/                         # Reusable components (app_* prefixed)
│     ├─ trust/                        # Trust-specific widgets
│     ├─ vibe/                         # Vibe-specific widgets
│     └─ streak/                       # Streak-specific widgets
│
├─ models/                             # Domain models with business logic
├─ providers/                          # State management (ChangeNotifiers)
├─ services/                           # Business logic & Firestore access
├─ utils/                              # App-wide utilities
│
├─ user_auth/                          # Auth UI screens
│  ├─ sign_in/
│  ├─ sign_up_account/
│  └─ recover_password/
│
├─ user_onboarding/                    # Onboarding flows
│  ├─ components/
│  ├─ controllers/
│  └─ models/
│
├─ main_function/                      # Core game features
│  ├─ games_list/                      # Game discovery
│  │  ├─ components/
│  │  ├─ managers/
│  │  ├─ models/
│  │  └─ utils/
│  ├─ create_game/                     # Game creation
│  │  ├─ components/
│  │  └─ models/
│  ├─ join_game/                       # Quick join
│  ├─ join_game_detailed/              # Detailed game view (pre-join)
│  ├─ games_joined/                    # Joined games list
│  ├─ game_joined_detailed/            # Detailed joined game view
│  ├─ player_list/                     # Player roster
│  ├─ leave_game/                      # Leave game flow
│  ├─ success_page/                    # Join success
│  ├─ success_leave/                   # Leave success
│  └─ community/                       # Community features
│
├─ profile/                            # User profile features
│  ├─ main_profile/                    # Profile view
│  ├─ create_profile/                  # New profile
│  ├─ edit_profile/                    # Edit profile
│  ├─ profile_user/                    # Other user's profile
│  ├─ edit_vibes/                      # Vibe preferences
│  ├─ edit_vibe_importance/            # Vibe importance weights
│  └─ change_photo/                    # Photo management
│
├─ chat_group/                         # Chat features
│  ├─ chat/                            # Chat list
│  ├─ game_chat_details/               # Chat thread view
│  │  └─ components/                   # Bubble, reactions, attachments
│  └─ empty_state_simple/
│
├─ friends/                            # Social features
│  ├─ tab_friends/
│  └─ components/
│
├─ notifications/                      # Notification UI
│  ├─ notifications_list/
│  ├─ game_alerts_page/
│  └─ components/
│
├─ notification_settings/              # Notification preferences
├─ settings/                           # App settings
│  ├─ blocked_users/
│  └─ location_settings/
│
├─ vibe/                               # Vibe system
│  └─ premium_vibe_page/
│
├─ challenge_board/                    # Challenges & leaderboard
│  └─ components/
│
├─ screens/                            # Utility screens
│  └─ confirmation/                    # Game confirmation flows
│
├─ debug/                              # Debug screens
│
└─ custom_code/                        # FlutterFlow legacy (excluded)
```

## firebase/functions/

```
firebase/functions/
├─ package.json                        # Node.js 22 dependencies
├─ .eslintrc.js
├─ index.js                            # Entry point, exports all functions
│
├─ [Main Modules]
├─ confirmation_flow.js                # Game confirmation & round jobs
├─ trust_system.js                     # Trust score calculations
├─ trust_profile.js                    # Trust profile management
├─ game_alerts.js                      # Push notifications for new games
├─ streaks.js                          # Streak management
├─ challenge_progress.js               # Challenge progress updates
├─ challenge_definitions.js            # Challenge rules
├─ host_add_notifications.js           # Host add notifications
├─ join_request_notifications.js       # Join request notifications
├─ avatar-generator.js                 # Initials avatar generation
├─ season_reset.js                     # Seasonal resets
├─ cleanup.js                          # Data cleanup
├─ api_manager.js                      # API utilities
│
├─ src/                                # Behavioral dataset
│  ├─ booking.js                       # Round creation
│  ├─ lifecycle.js                     # Confirm/decline/cancel/checkin
│  ├─ matching.js                      # Pairwise match generation
│  ├─ feedback.js                      # Post-round feedback
│  ├─ sync.js                          # Player round sync & BigQuery
│  └─ utils.js                         # Shared utilities
│
├─ notifications/                      # Notification subsystem
│  ├─ chat_debounce.js                 # Chat notification debouncing
│  ├─ flexible_nudge.js                # Flexible nudge scheduling
│  └─ trust/                           # Trust-related notifications
│
├─ utils/                              # Helper utilities
│  ├─ notification-helpers.js
│  ├─ avatar-utils.js
│  ├─ error_classification.js
│  └─ search-tokens.js
│
├─ moderation/                         # Content moderation
│
├─ test/                               # Jest test suite (28+ files)
│  ├─ confirmation_flow.test.js
│  ├─ game_alerts.test.js
│  ├─ integration.test.js
│  ├─ notification-load.test.js
│  └─ ...
│
└─ scripts/                            # Build & deployment
```

---

## Key File Locations by Domain

### Game Management
- Widget: `lib/main_function/games_list/games_list_widget.dart`
- Provider: `lib/providers/game_provider.dart`
- Service: `lib/services/game_service.dart`
- Model: `lib/models/game.dart`
- Schema: `lib/backend/schema/games_record.dart`
- Cloud Function: `firebase/functions/confirmation_flow.js`

### Chat & Messaging
- Widget: `lib/chat_group/game_chat_details/game_chat_details_widget.dart`
- Provider: `lib/providers/chat_provider.dart`
- Service: `lib/services/chat_service.dart`
- Model: `lib/models/chat.dart`, `lib/models/chat_message.dart`
- Cloud Function: `firebase/functions/notifications/chat_debounce.js`

### User Profiles & Onboarding
- Widget: `lib/profile/main_profile/main_profile_widget.dart`
- Provider: `lib/providers/profile_provider.dart`
- Service: `lib/services/profile_service.dart`
- Model: `lib/models/user_profile.dart`
- Schema: `lib/backend/schema/users_record.dart`
- Onboarding: `lib/user_onboarding/` (cinematic, progressive, vibe)

### Vibe Matching System
- Algorithm: `lib/services/vibe_matcher.dart`
- Group: `lib/services/vibe_group_matcher.dart`
- Model: `lib/models/vibe_profile.dart`
- Tests: `test/services/vibe_scoring_test.dart`

### Trust System
- Provider: `lib/providers/trust_provider.dart`
- Service: `lib/services/trust_flow_service.dart`
- Repository: `lib/services/trust_repository.dart`
- Cloud Functions: `firebase/functions/trust_system.js`, `firebase/functions/trust_profile.js`

### Notifications
- Provider: `lib/providers/notification_provider.dart`
- List Provider: `lib/providers/notification_list_provider.dart`
- Services: `lib/services/notification_orchestration_service.dart`, `lib/services/fcm_notification_service.dart`, `lib/services/local_notifications_service.dart`
- Cloud Functions: `firebase/functions/game_alerts.js`, `firebase/functions/notifications/`

### Design System
- Tokens: `lib/core/design_tokens/` (colors, typography, spacing, elevation, border_radius, icon_size, opacity)
- Icons: `lib/core/design_tokens/app_phosphor_icons.dart`
- Motion: `lib/core/motion/motion_tokens.dart`
- Widgets: `lib/core/widgets/` (all `app_` prefixed)

### Navigation
- Router: `lib/core/navigation/app_router.dart`
- Routes: `lib/core/navigation/route_definitions.dart`
- Transitions: `lib/core/navigation/transition_standards.dart`
- Bootstrap: `lib/core/bootstrap/app_bootstrap_coordinator.dart`

---

## Feature Folder Pattern

```
lib/feature_name/
├─ feature_widget.dart              # Main screen (max 300 lines)
├─ components/                      # Sub-widgets
├─ controllers/                     # Logic extraction (optional)
├─ models/                          # Feature-specific models (optional)
├─ managers/                        # Business logic helpers (optional)
└─ utils/                           # Feature utilities (optional)
```

---

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Files | `snake_case` | `game_service.dart` |
| Classes | `PascalCase` | `GameService` |
| Widgets | `PascalCase` + `Widget` suffix | `GamesListWidget` |
| Core widgets | `app_` prefix | `app_button_enhanced.dart` |
| Providers | `PascalCase` + `Provider` suffix | `GameProvider` |
| Services | `PascalCase` + `Service` suffix | `GameService` |
| Models | Direct name | `Game`, `Chat` |
| Schema records | `PascalCase` + `Record` suffix | `GamesRecord` |
| Routes | Static `routeName` + `routePath` | `CreateGameWidget.routeName` |
| Feature dirs | `snake_case` | `games_list/`, `create_game/` |

---

## Where to Add New Features

### New Screen
1. Create: `lib/[domain]/[feature]/[feature]_widget.dart`
2. Components: `lib/[domain]/[feature]/components/`
3. Route: Add to `lib/core/navigation/route_definitions.dart`
4. Use `TransitionStandards` for transition type

### New Service
1. Create: `lib/services/[name]_service.dart` (instance class with `FirebaseFirestore?` DI)
2. Error handling: `on FirebaseException catch (e)` → log → rethrow

### New Provider
1. Create: `lib/providers/[name]_provider.dart` (extend `ChangeNotifier`)
2. Accept service via constructor with default
3. Register in `lib/main.dart` `MultiProvider`
4. Add extensions in `lib/providers/provider_extensions.dart`

### New Model
1. Create: `lib/models/[name].dart`
2. Add `fromDoc()`/`fromRecord()` factory if needed

### New Cloud Function
1. Create: `firebase/functions/[feature].js`
2. Export from `firebase/functions/index.js`
3. Tests: `firebase/functions/test/[feature].test.js`

### New Core Widget
1. Create: `lib/core/widgets/app_[name].dart`
2. Use design tokens directly — no hardcoded values
