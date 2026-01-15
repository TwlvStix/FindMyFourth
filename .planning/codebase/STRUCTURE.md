# Codebase Structure

**Analysis Date:** 2026-01-14

## Directory Layout

```
lib/
├── auth/                          # Authentication & user management
├── backend/                       # Firebase & data access
├── core/                          # Shared UI & theme
├── models/                        # Business domain models
├── providers/                     # State management
├── services/                      # Business logic & Firestore ops
├── main_function/                 # Core feature screens
├── profile/                       # User profile screens
├── chat_group/                    # Chat UI
├── user_auth/                     # Authentication screens
├── user_onboarding/               # Onboarding flow
├── notifications/                 # Notification UI
├── friends/                       # Friend management
├── newsfeed/                      # Newsfeed feature
├── components/                    # Standalone UI components
├── custom_code/                   # Custom extensions
├── utils/                         # Utilities
└── main.dart                      # App entry point

firebase/
├── firestore.rules                # Security rules
├── firestore.indexes.json         # Query indexes
├── firebase.json                  # Firebase config
└── functions/                     # Cloud Functions
    ├── index.js                   # Function implementations
    └── package.json               # Node.js dependencies

android/                           # Android platform code
ios/                               # iOS platform code
test/                              # Test files
```

## Directory Purposes

**lib/auth/** (11 files)
- Purpose: Authentication & user management
- Contains: Firebase Auth operations, social auth providers
- Key files: `firebase_auth_manager.dart`, `firebase_user_provider.dart`, `google_auth.dart`, `apple_auth.dart`
- Subdirectories: `firebase_auth/` with provider-specific implementations

**lib/backend/** (20 files)
- Purpose: Firebase & data access layer
- Contains: Firestore queries, schema classes, Firebase config
- Key files: `backend.dart` (main query functions), `firebase_config.dart`
- Subdirectories: `schema/` (auto-generated Record classes), `firebase_storage/`, `cloud_functions/`, `push_notifications/`

**lib/core/** (33 files)
- Purpose: Shared UI components and theme configuration
- Contains: Reusable widgets, design tokens, navigation setup
- Key files: `app_theme.dart`, `app_router.dart` (navigation + AppStateNotifier)
- Subdirectories: `widgets/` (reusable components), `design_tokens/` (colors, typography), `navigation/`

**lib/models/** (10 files)
- Purpose: Business domain models
- Contains: Game, Chat, ChatMessage, VibeProfile, UserProfile models
- Key files: `game.dart`, `vibe_profile.dart`, `chat.dart`, `chat_message.dart`
- Pattern: Separate from backend Record classes, with conversion methods

**lib/providers/** (3 files)
- Purpose: State management
- Contains: Provider classes wrapping services
- Key files: `user_provider.dart` (global user state + cached queries), `chat_provider.dart`
- Pattern: ChangeNotifier providers with request caching

**lib/services/** (6 files)
- Purpose: Business logic and Firestore operations
- Contains: ChatService, VibeMatcher, VibeGroupMatcher, VibeRepository
- Key files: `chat_service.dart`, `vibe_matcher.dart`, `vibe_group_matcher.dart`
- Pattern: Service classes with transaction-based operations

**lib/main_function/** (13 files)
- Purpose: Core feature screens
- Contains: Games list, games joined, golfers directory, community, create game
- Key files: `games_list_widget.dart` (1st nav tab), `games_joined_widget.dart` (2nd tab), `golfers_widget.dart` (3rd tab), `community_widget.dart` (4th tab), `create_game_widget.dart` (FAB route)
- Subdirectories: One per feature with `*_widget.dart` pattern

**lib/profile/** (9 files)
- Purpose: User profile screens
- Contains: Profile viewing, editing, vibe preferences
- Key files: `main_profile_widget.dart` (5th nav tab), `edit_profile_widget.dart`, `edit_vibes_widget.dart`, `profile_user_firebase_widget.dart`
- Pattern: Separate widgets for own profile vs viewing others

**lib/chat_group/** (3 files)
- Purpose: Chat UI
- Contains: Chat message view, chat details
- Key files: `chat_widget.dart`, `game_chat_details_widget.dart`
- Pattern: Real-time message streaming with pagination

**lib/user_auth/** (3 files)
- Purpose: Authentication screens
- Contains: Sign-in, sign-up, password recovery
- Key files: `sign_in_widget.dart`, `sign_up_account_widget.dart`, `recover_password_widget.dart`

**lib/user_onboarding/** (3 files)
- Purpose: Onboarding flow
- Contains: User onboarding, vibe setup
- Key files: `user_onboarding_widget.dart`, `vibe_onboarding_widget.dart`, `progressive_onboarding_widget.dart`

**lib/notifications/** (2 files)
- Purpose: Notification UI
- Contains: Notification page, notifications list
- Key files: `notification_page_widget.dart`, `notifications_list_widget.dart`

**lib/friends/** (7 files)
- Purpose: Friend management
- Contains: Friend list, friend requests
- Key files: `tab_friends_widget.dart`
- Subdirectories: `components/` with friend-related components

**lib/utils/** (3 files)
- Purpose: Utility functions
- Contains: App utilities, serialization helpers
- Key files: `app_util.dart`, `serialization_util.dart`

## Key File Locations

**Entry Points:**
- `lib/main.dart` - App initialization, Firebase setup, Provider configuration

**Configuration:**
- `lib/backend/firebase/firebase_config.dart` - Firebase initialization
- `firebase/firestore.rules` - Firestore security rules
- `firebase/firestore.indexes.json` - Query optimization indexes
- `firebase/firebase.json` - Firebase project config
- `pubspec.yaml` - Dart dependencies and SDK configuration
- `android/app/google-services.json` - Android Firebase config
- `ios/Podfile` - iOS CocoaPods dependencies

**Core Logic:**
- `lib/backend/backend.dart` - Firestore query functions for all collections
- `lib/services/chat_service.dart` - Chat operations
- `lib/providers/user_provider.dart` - Global user state
- `lib/core/navigation/app_router.dart` - Navigation configuration

**Testing:**
- `test/` - Root test directory
- `test/services/` - Service logic tests
- `test/models/` - Model tests
- `test/auth/` - Authentication tests

**Documentation:**
- `README.md` - Basic project info
- `docs/README.md` - Additional documentation
- `.claude/README.md` - Claude Code integration docs

## Naming Conventions

**Files:**
- Widgets: `{feature_name}_widget.dart` (e.g., `games_list_widget.dart`)
- Services: `{domain}_service.dart` (e.g., `chat_service.dart`)
- Models: `snake_case.dart` (e.g., `vibe_profile.dart`)
- Providers: `{entity}_provider.dart` (e.g., `user_provider.dart`)
- Records: `{entity}_record.dart` (e.g., `users_record.dart`)

**Directories:**
- All lowercase with underscores: `main_function/`, `user_auth/`
- Feature-based organization: `profile/`, `chat_group/`
- Plural for collections: `providers/`, `services/`, `models/`

**Special Patterns:**
- `index.dart` for barrel exports (custom_code)
- `_OLD.dart` suffix for deprecated files (should be removed)

## Where to Add New Code

**New Feature:**
- Primary code: `lib/main_function/{feature_name}/`
- Models: `lib/models/{feature_name}.dart`
- Services: `lib/services/{feature_name}_service.dart`
- Provider (if needed): `lib/providers/{feature_name}_provider.dart`
- Tests: `test/services/{feature_name}_service_test.dart`

**New Widget/Component:**
- Reusable widget: `lib/core/widgets/{widget_name}.dart`
- Feature-specific: `lib/{feature_area}/{widget_name}_widget.dart`
- Tests: `test/{feature_area}/{widget_name}_test.dart`

**New Service:**
- Implementation: `lib/services/{domain}_service.dart`
- Tests: `test/services/{domain}_service_test.dart`

**New Model:**
- Domain model: `lib/models/{model_name}.dart`
- Firestore record: `lib/backend/schema/{model_name}_record.dart` (auto-generated)
- Tests: `test/models/{model_name}_test.dart`

**Utilities:**
- Shared helpers: `lib/utils/` (app_util.dart, serialization_util.dart)
- Core utilities: `lib/core/` (form helpers, request managers)

## Special Directories

**lib/backend/schema/**
- Purpose: Auto-generated Firestore record classes
- Source: Firestore schema definitions
- Committed: Yes
- Pattern: {collection}_record.dart with serialization methods

**lib/custom_code/**
- Purpose: Custom Flutter code extensions
- Source: Manual implementations
- Committed: Yes
- Subdirectories: `actions/`, `widgets/`

**firebase/functions/**
- Purpose: Node.js Cloud Functions
- Source: Server-side business logic
- Committed: Yes
- Runtime: Node.js 20

**android/**, **ios/**
- Purpose: Platform-specific code
- Source: Native Android (Kotlin/Java) and iOS (Swift/Objective-C)
- Committed: Yes (except build artifacts)

---

*Structure analysis: 2026-01-14*
*Update when directory structure changes*
