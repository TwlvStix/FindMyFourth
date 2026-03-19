# Codebase Structure

**Analysis Date:** 2026-03-19

## Directory Layout

```
find_my_fourth/
├── lib/                           # Application source code
│   ├── main.dart                  # Entry point: Firebase init, provider tree, app state
│   ├── app_state.dart             # Legacy: SharedPreferences-backed transient UI state
│   │
│   ├── core/                      # Cross-cutting infrastructure
│   │   ├── app_theme.dart         # Legacy ThemeExtension bridge (migrate to tokens)
│   │   ├── bootstrap/
│   │   │   └── app_bootstrap_coordinator.dart  # Startup orchestration (auth, notifications, splash)
│   │   ├── config/
│   │   │   └── build_flags.dart   # Compile-time constants (APP_ENV, EMULATOR, DEV_UI, CRASHLYTICS)
│   │   ├── content/
│   │   │   └── app_copy.dart      # Microcopy constants & voice guidelines
│   │   ├── design_patterns/
│   │   │   └── premium_ui_patterns.dart  # Reusable premium components (GlassCard, etc.)
│   │   ├── design_tokens/         # Source of truth for visual design (NEVER hardcode colors, sizes, fonts)
│   │   │   ├── colors.dart        # "The Clubhouse" palette (green/navy/gold roles, trust tiers, semantic colors)
│   │   │   ├── typography.dart    # Fraunces/Manrope/DM Mono text styles
│   │   │   ├── spacing.dart       # 8-point grid (8px, 12px, 16px, 20px, 24px, 32px, etc.)
│   │   │   ├── border_radius.dart # Semantic radius tokens (button=8, card=12, modal=16, avatar=999, etc.)
│   │   │   ├── elevation.dart     # Shadow presets (xs/sm/md/lg/xl + semantic aliases)
│   │   │   ├── opacity.dart       # Opacity scale (disabled=0.20, overlay=0.40, glass=0.10, etc.)
│   │   │   ├── icon_size.dart     # Icon size tokens (xs/sm/md/lg/xl + semantic nav/button/listItem/section)
│   │   │   ├── app_phosphor_icons.dart  # Phosphor Icon library integration
│   │   │   ├── archetype_colors.dart    # Vibe archetype color mapping
│   │   │   └── README.md          # Design system reference
│   │   ├── exceptions/
│   │   │   └── app_exceptions.dart  # Custom exception hierarchy (GameOperationException, ChatOperationException, etc.)
│   │   ├── motion/
│   │   │   ├── motion_tokens.dart # Animation durations, curves, scale factors
│   │   │   └── reduced_motion.dart # Accessibility support for reduced motion
│   │   ├── navigation/
│   │   │   ├── app_router.dart    # GoRouter setup, AppStateNotifier, route building
│   │   │   ├── route_definitions.dart  # List of all routes with redirects and transitions
│   │   │   ├── nav_bar_page.dart  # Tab navigation wrapper
│   │   │   ├── nav_extensions.dart # Navigation helper extensions
│   │   │   ├── transition_standards.dart  # Preset transitions (modal, detail, dismissal, tab)
│   │   │   └── route_param_utils.dart    # Parameter passing helpers
│   │   ├── request_manager.dart   # StreamRequestManager<T>, FutureRequestManager<T> (caching)
│   │   ├── utils/
│   │   │   ├── app_log.dart       # AppLog.d() logging (never print or debugPrint)
│   │   │   ├── firebase_error_utils.dart  # Firebase error code to message mapping
│   │   │   ├── error_messages.dart # App-wide error message constants
│   │   │   ├── input_sanitizer.dart # String validation, email validation, etc.
│   │   │   ├── app_util.dart      # Utility functions and extensions
│   │   │   └── state_update.dart  # State update helpers
│   │   └── widgets/               # Reusable core components (prefixed 'app_')
│   │       ├── app_button_enhanced.dart  # Button variants (primary, secondary, ghost, destructive, etc.)
│   │       ├── app_card.dart      # Card component
│   │       ├── app_text_field.dart # Input component
│   │       ├── app_text.dart      # Text wrapper
│   │       ├── app_badge.dart     # Badge component
│   │       ├── app_avatar.dart    # Avatar with image/fallback
│   │       ├── app_icon.dart      # Icon wrapper (Phosphor + legacy SVG support)
│   │       ├── app_icon_badge.dart # Icon with colored badge
│   │       ├── app_section_header.dart   # Section title
│   │       ├── app_empty_state.dart     # Empty state UI
│   │       ├── app_loading_state.dart   # Loading spinner
│   │       ├── app_list_tile.dart      # List item
│   │       ├── app_choice_chips.dart    # Choice chip group
│   │       ├── app_info_grid.dart      # Info display grid
│   │       ├── fairway_background.dart # Golf course background pattern
│   │       ├── profile_hero_section.dart # Profile header
│   │       ├── profile_card_section.dart # Profile card wrapper
│   │       ├── vibe_slider_card.dart    # Vibe preference slider
│   │       ├── premium_back_button.dart # Premium-styled back button
│   │       ├── trust/            # Trust-specific widgets
│   │       ├── vibe/             # Vibe-specific widgets
│   │       └── streak/           # Streak-specific widgets
│   │
│   ├── providers/                # State management layer (each domain has one provider)
│   │   ├── user_provider.dart
│   │   ├── game_provider.dart
│   │   ├── chat_provider.dart
│   │   ├── profile_provider.dart
│   │   ├── notification_provider.dart
│   │   ├── notification_list_provider.dart
│   │   ├── trust_provider.dart
│   │   ├── geo_filter_provider.dart
│   │   ├── join_request_provider.dart
│   │   ├── group_vibe_provider.dart
│   │   ├── challenge_provider.dart
│   │   ├── leaderboard_provider.dart
│   │   ├── block_provider.dart
│   │   ├── streak_provider.dart
│   │   ├── vibe_provider.dart
│   │   ├── provider_extensions.dart  # Extensions for convenient provider access (context.gameProvider, etc.)
│   │   ├── chat_view_model_manager.dart  # Extracted chat stream composition logic
│   │   └── chat_view_model_helpers.dart  # Helper functions for chat view models
│   │
│   ├── services/                # Business logic & Firestore access (one per domain)
│   │   ├── game_service.dart
│   │   ├── chat_service.dart
│   │   ├── profile_service.dart
│   │   ├── user_profile_service.dart
│   │   ├── friend_service.dart
│   │   ├── trust_service.dart
│   │   ├── trust_repository.dart
│   │   ├── notification_crud_service.dart
│   │   ├── notification_service.dart
│   │   ├── notification_audit_service.dart
│   │   ├── notification_orchestration_service.dart
│   │   ├── notification_permission_service.dart
│   │   ├── block_service.dart
│   │   ├── join_request_service.dart
│   │   ├── challenge_service.dart
│   │   ├── leaderboard_service.dart
│   │   ├── create_game_service.dart
│   │   ├── create_game_draft_service.dart
│   │   ├── game_eligibility_service.dart
│   │   ├── cancellation_service.dart
│   │   ├── alert_subscription_service.dart
│   │   ├── player_search_service.dart
│   │   ├── firestore_repository.dart
│   │   ├── geo_location_service.dart
│   │   ├── course_service.dart
│   │   ├── vibe_matcher.dart      # Core vibe matching algorithm
│   │   ├── vibe_group_matcher.dart # Group compatibility matching
│   │   ├── vibe_floor_service.dart # Vibe eligibility floor calculations
│   │   ├── vibe_provider.dart      # (Misplaced service, should be in providers/)
│   │   ├── remote_config_service.dart  # Feature flags via Firebase Remote Config
│   │   ├── app_badge_service.dart  # OS-level app badge management
│   │   ├── local_notifications_service.dart  # Local notification scheduling
│   │   ├── fcm_notification_service.dart    # FCM token and payload handling
│   │   ├── notification_test_service.dart   # Test notification simulation
│   │   └── fake_notification_service.dart   # Mock for testing
│   │
│   ├── models/                  # Domain model classes with business logic
│   │   ├── game.dart            # Game domain model (status resolution, eligibility)
│   │   ├── chat.dart            # Chat domain model
│   │   ├── chat_message.dart    # Chat message domain model
│   │   ├── user_profile.dart    # User profile domain model
│   │   ├── vibe_profile.dart    # Vibe preference domain model
│   │   ├── player_eligibility.dart  # Game join eligibility rules
│   │   ├── join_game_result.dart    # Result object for join game mutation
│   │   ├── challenge.dart       # Challenge domain model
│   │   ├── challenge_progress.dart
│   │   ├── leaderboard_entry.dart
│   │   ├── streak_profile.dart
│   │   ├── cancellation_record.dart
│   │   ├── join_request.dart
│   │   ├── alert_subscription.dart
│   │   ├── course.dart
│   │   ├── place.dart
│   │   ├── notification_preferences.dart
│   │   ├── notification_receipt_event.dart
│   │   ├── lat_lng.dart
│   │   ├── uploaded_file.dart
│   │   ├── vibe_labels.dart     # Vibe archetype and label mappings
│   │   └── chat_message_view_model.dart
│   │
│   ├── backend/                 # Firebase configuration & schema
│   │   ├── firebase/
│   │   │   ├── firebase_config.dart  # Firebase initialization, emulator config
│   │   │   └── backend.dart     # Export barrel for all Firestore records
│   │   ├── schema/              # Firestore record classes (legacy from FlutterFlow)
│   │   │   ├── users_record.dart
│   │   │   ├── games_record.dart
│   │   │   ├── chats_record.dart
│   │   │   ├── chat_messages_record.dart
│   │   │   ├── course_record.dart
│   │   │   ├── game_participants_record.dart
│   │   │   ├── pair_ratings_record.dart
│   │   │   ├── round_records_record.dart
│   │   │   ├── cancellation_records_record.dart
│   │   │   ├── trust_profile.dart
│   │   │   ├── player_standing.dart
│   │   │   ├── post_round.dart
│   │   │   ├── hometown_record.dart
│   │   │   ├── util/            # Firestore utility classes
│   │   │   └── index.dart       # Export barrel
│   │   ├── cloud_functions/     # Cloud Functions SDK integration
│   │   ├── firebase_storage/    # Storage bucket operations
│   │   └── push_notifications/
│   │       ├── push_notifications_handler.dart  # FCM message routing
│   │       └── local_notification_helper.dart
│   │
│   ├── auth/                    # Authentication layer
│   │   ├── base_auth_user_provider.dart  # Base auth user interface
│   │   └── firebase_auth/
│   │       ├── firebase_user_provider.dart  # Firebase Auth wrapper
│   │       ├── auth_util.dart   # Auth helpers (currentUser, auth streams)
│   │       └── auth_state_manager.dart
│   │
│   ├── main_function/           # Primary game-related features
│   │   ├── games_list/          # Browse available games
│   │   │   ├── games_list_widget.dart  # Main screen (731 lines — tech debt)
│   │   │   ├── components/      # Sub-widgets
│   │   │   ├── managers/        # Extracted managers (profile warmer, mutual friends, filter handler, action handler)
│   │   │   ├── models/          # Local models (QuickFilter, GameListFilters)
│   │   │   └── utils/           # Utility functions
│   │   ├── create_game/         # Create new game
│   │   │   ├── create_game_widget.dart
│   │   │   ├── components/
│   │   │   ├── controllers/
│   │   │   └── models/          # CreateGameFormData
│   │   ├── join_game_detailed/  # Join game preview & confirmation
│   │   ├── game_joined_detailed/ # Joined game details & participant list
│   │   ├── games_joined/        # List of games user has joined
│   │   ├── player_list/         # Game participant roster
│   │   ├── join_game/           # (Legacy join flow)
│   │   ├── leave_game/          # Leave game confirmation
│   │   ├── success_page/        # Post-action success screen
│   │   ├── success_leave/       # Leave game success
│   │   └── community/           # Community/social feed
│   │
│   ├── chat_group/              # Chat & messaging
│   │   ├── chat/                # Chat list screen
│   │   │   ├── chat_widget.dart
│   │   │   └── components/
│   │   ├── game_chat_details/   # Per-game chat thread
│   │   │   ├── game_chat_details_widget.dart
│   │   │   ├── components/      # Chat bubble, input bar, reactions, attachments
│   │   │   ├── controllers/     # Chat input controller
│   │   │   └── helpers/         # Chat utilities
│   │   └── empty_state_simple/  # Empty chat state
│   │
│   ├── profile/                 # User profile management
│   │   ├── main_profile/        # Current user profile view
│   │   ├── create_profile/      # Profile onboarding
│   │   ├── edit_profile/        # Profile editing
│   │   ├── edit_vibes/          # Vibe preference editing
│   │   ├── edit_vibe_importance/ # Vibe importance weighting
│   │   ├── change_photo/        # Photo upload
│   │   └── profile_user/        # Other user profile view (read-only)
│   │
│   ├── user_onboarding/         # Onboarding flows
│   │   ├── progressive_onboarding_widget.dart  # Main onboarding flow
│   │   ├── cinematic_onboarding_widget.dart   # Splash onboarding
│   │   ├── vibe_onboarding_widget.dart
│   │   ├── vibe_archetype_reveal_widget.dart
│   │   ├── components/
│   │   ├── controllers/
│   │   └── models/
│   │
│   ├── user_auth/               # Authentication screens
│   │   ├── sign_in/
│   │   ├── sign_up_account/
│   │   └── recover_password/
│   │
│   ├── notifications/           # Notification management
│   │   ├── notifications_list/  # Notification center
│   │   ├── game_alerts_page/    # Game alert subscriptions
│   │   └── components/
│   │
│   ├── notification_settings/   # Notification preferences
│   │
│   ├── vibe/                    # Vibe premium features
│   │   └── premium_vibe_page/
│   │       ├── premium_vibe_page_widget.dart
│   │       ├── components/
│   │       └── styles/
│   │
│   ├── friends/                 # Friend management
│   │   ├── tab_friends/         # Friend list tab
│   │   └── components/
│   │       └── premium_friend_card/
│   │
│   ├── challenge_board/         # Challenge/competition features
│   │   └── components/
│   │
│   ├── screens/                 # Modal & specialized screens
│   │   ├── confirmation/        # Game confirmation flows
│   │   │   ├── fallback_confirmation_screen.dart
│   │   │   ├── host_checkin_screen.dart
│   │   │   └── peer_rating_screen.dart
│   │   └── trust/               # Trust system screens
│   │       └── your_standing_screen.dart
│   │
│   ├── settings/                # User settings
│   │   ├── blocked_users/       # Block/unblock users
│   │   └── location_settings/   # Location preferences
│   │
│   ├── debug/                   # Debug-only features (excluded from analysis)
│   │   ├── components/
│   │   └── services/
│   │
│   ├── custom_code/             # Custom code (excluded from analysis)
│   │   └── widgets/
│   │
│   └── utils/                   # App-wide utilities
│       ├── app_util.dart
│       ├── flexible_date_formatter.dart
│       ├── serialization_util.dart
│       └── ...
│
├── firebase/                    # Cloud Functions & Firestore rules
│   ├── functions/
│   │   ├── index.js             # Entry point, exports all functions
│   │   ├── package.json         # Node.js dependencies
│   │   ├── confirmation_flow.js # Game confirmation & round processing
│   │   ├── trust_system.js      # Trust score calculations
│   │   ├── trust_profile.js     # Trust profile management
│   │   ├── game_alerts.js       # Push notification generation
│   │   ├── src/                 # Behavioral dataset modules
│   │   │   ├── booking.js       # Round creation
│   │   │   ├── lifecycle.js     # Game state transitions
│   │   │   ├── matching.js      # Pairwise matching
│   │   │   ├── feedback.js      # Post-round feedback
│   │   │   └── sync.js          # Player sync & BigQuery export
│   │   ├── notifications/       # Notification scheduling
│   │   └── test/                # Jest test suite
│   ├── firestore.rules          # Firestore security rules
│   ├── firestore.indexes.json   # Firestore composite indexes
│   └── .firebaserc              # Firebase project config
│
├── test/                        # Unit & widget tests (mirrors lib/ structure)
│   ├── core/
│   ├── services/
│   ├── providers/
│   ├── models/
│   ├── widgets/
│   ├── vibe_scoring_test.dart   # Vibe matching algorithm tests
│   └── ...
│
├── integration_test/            # E2E tests
│
├── web/                         # Web platform assets
├── ios/                         # iOS platform code
├── android/                     # Android platform code
│
├── pubspec.yaml                 # Flutter dependencies
├── pubspec.lock
├── analysis_options.yaml        # Lint rules
├── .firebase/                   # Emulator cache (local dev)
├── .env*                        # Environment files (gitignored)
│
└── docs/                        # Documentation
    ├── design-system/           # Design system reference
    ├── migrations/              # Schema migration guides
    ├── specs/                   # Feature specifications
    ├── perf_baselines/          # Performance benchmarks
    ├── testing/                 # Testing guides
    └── debug/                   # Debug guides
```

## Directory Purposes

**lib/**
- Root of application source code; code organization follows domain-driven design (games, chat, profile, etc.)

**lib/core/**
- Infrastructure and shared utilities; includes design tokens, navigation, exceptions, and reusable widgets
- No feature-specific logic; pure infrastructure

**lib/providers/**
- State management layer; one provider per domain for consistent caching and reactivity
- Never call Firestore directly; always delegate to services

**lib/services/**
- Business logic and Firestore operations; pure functions, injected dependencies for testability
- Catch `FirebaseException` specifically; log with `AppLog.d()` including error codes; rethrow

**lib/models/**
- Domain objects with business logic; `fromDoc()`/`fromRecord()` factories; shared static methods for logic reuse
- Lightweight — most logic lives in services

**lib/backend/schema/**
- Legacy Firestore record classes from FlutterFlow; cannot be removed; only updated when adding new Firestore fields

**lib/main_function/**
- Games (create, browse, join, detail, list) — primary feature area

**lib/chat_group/**
- Chat and messaging; per-game threads and chat list

**lib/profile/**
- User profile management; CRUD, vibe editing, viewing other users

**lib/user_onboarding/**
- Account creation and preference setup; cinematic and progressive flows

**lib/user_auth/**
- Sign in, sign up, password recovery

**lib/notifications/**
- Notification center, game alert subscriptions, notification routing

**lib/settings/**
- User preferences; block list, location settings

**lib/screens/**
- Modal and specialized screens; confirmation flows, trust standings

**lib/debug/**
- Debug-only features; excluded from CI analysis and lint rules

**lib/custom_code/**
- Custom code (legacy, excluded from analysis)

**firebase/functions/**
- Cloud Functions source; Node.js; modules for confirmation, trust, notifications, booking, matching

**firebase/**
- Firestore rules and composite indexes

**test/**
- Unit and widget tests; mirrors lib/ structure for easy location

## Key File Locations

**Entry Points:**
- `lib/main.dart` — Application startup, Firebase init, provider tree, error handlers
- `lib/core/bootstrap/app_bootstrap_coordinator.dart` — Startup coordination (auth, notifications, splash removal)
- `lib/core/navigation/app_router.dart` — GoRouter setup, auth redirects
- `lib/core/navigation/route_definitions.dart` — Complete route list

**Configuration:**
- `lib/backend/firebase/firebase_config.dart` — Firebase project setup, emulator config
- `lib/core/config/build_flags.dart` — Compile-time flags (APP_ENV, EMULATOR, DEV_UI)
- `pubspec.yaml` — Dependencies and build configuration

**Core Logic:**
- `lib/services/game_service.dart` — Game queries, join/leave logic
- `lib/services/chat_service.dart` — Chat streams, message CRUD, batch optimizations
- `lib/providers/game_provider.dart` — Game state management with caching
- `lib/providers/user_provider.dart` — User state, friend operations, profile queries
- `lib/models/game.dart` — Game domain model with status resolution logic

**Design System:**
- `lib/core/design_tokens/colors.dart` — Color palette ("The Clubhouse" — green/navy/gold)
- `lib/core/design_tokens/typography.dart` — Font families and text styles
- `lib/core/design_tokens/spacing.dart` — 8-point grid system
- `lib/core/design_tokens/app_phosphor_icons.dart` — Icon library

**Widget Components:**
- `lib/core/widgets/app_button_enhanced.dart` — Primary button variants
- `lib/core/widgets/app_card.dart` — Card component
- `lib/core/widgets/app_icon.dart` — Icon wrapper with Phosphor integration

**Testing:**
- `test/vibe_scoring_test.dart` — Vibe matching algorithm tests
- `firebase/functions/test/` — Cloud Functions Jest tests

## Naming Conventions

**Files:**
- Snake case: `games_list_widget.dart`, `game_service.dart`, `create_game_form_data.dart`
- Feature widgets: `{feature}_widget.dart` (e.g., `games_list_widget.dart`, `chat_widget.dart`)
- Services: `{domain}_service.dart` (e.g., `game_service.dart`, `chat_service.dart`)
- Providers: `{domain}_provider.dart` (e.g., `game_provider.dart`, `user_provider.dart`)
- Models: `{entity}.dart` (e.g., `game.dart`, `user_profile.dart`)
- Core widgets: `app_{component}.dart` (e.g., `app_button_enhanced.dart`, `app_card.dart`)
- Component sub-widgets: `{feature}_{component}.dart` (e.g., `games_list_app_bar.dart`, `game_joined_player_card.dart`)
- Controllers: `{feature}_controller.dart` (e.g., `create_game_controller.dart`)
- Managers: `{feature}_manager.dart` (e.g., `filter_handler.dart`)

**Directories:**
- Feature folders use feature name in plural or descriptive form: `main_function/`, `chat_group/`, `profile/`, `notifications/`
- Sub-components live in `components/` subfolder of the feature
- Extracted logic lives in `managers/`, `controllers/`, `helpers/`, `utils/`, or `models/` subfolders

**Classes:**
- PascalCase: `GameService`, `GamesListWidget`, `GameProvider`, `CreateGameFormData`
- Feature components: `{Feature}{Component}` (e.g., `GamesListAppBar`, `GameJoinedPlayerCard`)
- Core components: `App{Component}` (e.g., `AppButtonEnhanced`, `AppCard`)
- Record classes: `{Entity}Record` (e.g., `GamesRecord`, `UsersRecord`)
- Providers: `{Domain}Provider` (e.g., `GameProvider`, `ChatProvider`)
- Services: `{Domain}Service` (e.g., `GameService`, `ChatService`)

## Where to Add New Code

**New Feature (e.g., "Leagues"):**
1. Create directory: `lib/leagues/`
2. Main screen: `lib/leagues/leagues_widget.dart` (with static `routeName`, `routePath`)
3. Components: `lib/leagues/components/{LeaguesComponent}.dart`
4. Model: `lib/models/league.dart` (if new data type)
5. Service: `lib/services/league_service.dart` (Firestore operations)
6. Provider: `lib/providers/league_provider.dart` (wraps service with caching)
7. Firestore schema: `lib/backend/schema/leagues_record.dart` (if new collection)
8. Route: Add entry to `lib/core/navigation/route_definitions.dart` with redirect and transition
9. Tests: `test/leagues/`, `test/services/league_service_test.dart`

**New Component/Module (reusable):**
- If used in one feature: `lib/{feature}/components/{Feature}{Component}.dart`
- If reused across features: `lib/core/widgets/app_{component}.dart` with `App` prefix

**Utilities/Helpers:**
- Shared utilities: `lib/core/utils/{utility}.dart`
- Feature-specific: `lib/{feature}/utils/` or `lib/{feature}/helpers/`

**Services:**
- Domain-specific: `lib/services/{domain}_service.dart` (instance class, DI for testability)
- Register: No central registry; create instance in provider constructor: `FeaturesService? service` with default `FeaturesService()`

**Design Tokens:**
- Never create new token files; add to existing: `colors.dart`, `typography.dart`, `spacing.dart`, etc.
- CI enforces no hardcoded colors/sizes/fonts via `tool/check_hardcoded_colors.sh`

**Tests:**
- Unit tests: `test/{path_matching_lib}/{feature_test}.dart`
- Widget tests: `test/{feature}/{component}_test.dart`
- Service tests: `test/services/{service}_test.dart`

## Special Directories

**lib/backend/schema/**
- Firestore record classes (auto-generated from FlutterFlow, manually maintained)
- Committed to git; cannot be removed
- Updated when adding new Firestore fields (run `flutterflow` CLI or add manually)
- Example: `GamesRecord` is used by 13+ files; removing would break app

**lib/custom_code/**
- Excluded from lint analysis (`analysis_options.yaml` ignores this path)
- Legacy custom code; avoid using for new features

**lib/debug/**
- Debug-only features, excluded from analysis and lint rules
- Includes: notification routing tests, crash test overlay, streak debug screen

**.planning/codebase/**
- This document directory
- Contains analysis documents: `ARCHITECTURE.md`, `STRUCTURE.md`, `CONVENTIONS.md`, `TESTING.md`, `STACK.md`, `INTEGRATIONS.md`, `CONCERNS.md`

---

*Structure analysis: 2026-03-19*
