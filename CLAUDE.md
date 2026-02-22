# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Find My Fourth is a Flutter mobile app for golfers to find playing partners. The app uses Firebase backend services including Firestore, Cloud Functions, and FCM for push notifications.

## Build & Development Commands

### Flutter (Mobile App)
```bash
# Run the app
flutter run

# Run on specific device
flutter run -d <device_id>

# Build for iOS
flutter build ios

# Build for Android
flutter build apk

# Run tests
flutter test

# Run single test file
flutter test test/services/vibe_scoring_test.dart

# Analyze code
flutter analyze
```

### Firebase Cloud Functions
```bash
cd firebase/functions

# Install dependencies
npm install

# Run tests
npm test

# Run specific test
npx jest test/confirmation_flow.test.js

# Lint
npm run lint

# Start local emulator
npm run serve

# View logs
npm run logs

# Deploy functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:sendGameCreatedNotifications
```

### Firebase General
```bash
cd firebase

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Firestore indexes
firebase deploy --only firestore:indexes

# Deploy everything
firebase deploy
```

## Architecture

### Flutter App (`lib/`)

**State Management**: Provider pattern with domain-specific providers:
- `UserProvider` - Current user state, authentication, and friend operations
- `GameProvider` - Game listings, joined games, and all game mutations
- `ChatProvider` - Real-time chat functionality
- `ProfileProvider` - User profiles and search
- `NotificationProvider` - Push notification state
- `TrustProvider` - Trust score system

**Service Layer**: Each domain has a dedicated service for Firestore operations:
- `GameService` - Game CRUD, join/leave, queries
- `ChatService` - Chat/message CRUD, typing, reactions
- `ProfileService` - Profile CRUD, search, batch fetching
- `FriendService` - Friend add/remove, requests send/accept/reject/cancel
- `AlertSubscriptionService`, `CancellationService`, etc.

**Data Flow**: Widget → Provider → Service → Firestore. Providers handle caching and state; services handle Firestore reads/writes. Do not bypass this flow.

**Key Directories**:
- `models/` - Domain models with business logic (Game, Chat, UserProfile, VibeProfile)
- `services/` - Firestore operations and business logic
- `providers/` - State management with ChangeNotifiers
- `backend/schema/` - Legacy FlutterFlow Firestore record classes (UsersRecord, GamesRecord, etc.)
- `backend/api_requests/` - Service classes for Firestore access
- `core/` - Design system, widgets, utilities, navigation

### Design System

**Philosophy: "The Clubhouse"** — A trust-first golf matchmaking aesthetic built on three color roles: Green (darker, richer "fairway at dusk" — every interactive element), Deep Teal-Navy (structural surfaces with green undertones), Gold (demoted to accent-only — trust, achievements, premium). Typography blends traditional golf club sophistication with modern athletic energy.

**For new code: always use design tokens directly.** Import from `lib/core/design_tokens/` and use `AppColors`, `AppTypography`, `AppSpacing`, etc. Do not hardcode colors, font sizes, or spacing values. Do not introduce new `AppTheme.of(context)` usage (see legacy note below).

#### Design Tokens (`lib/core/design_tokens/`)

The token system is the source of truth for all visual design.

**Colors** (`colors.dart`) — "The Clubhouse" premium palette with three color roles:

*Primary Accent — Fairway Green (all interactive elements):*
Darker, richer greens — "fairway at dusk, not neon grass"
- `green` (#1F6B4E) — primary CTAs, Join Game, active nav, links
- `greenDark` (#18543E) — pressed states, deep accents
- `greenLight` (#2E8B68) — hover highlights, score accents
- Interaction states: `greenHovered`, `greenPressed`

*Structural — Deep Teal-Navy (headers, cards, navigation):*
Navy with green undertones — masculine, athletic, grounded
- `navy` (#142A36) — card headers, secondary buttons, structural fills
- `navyDark` (#0E1C26) — app bar backgrounds, deep gradients, primary background
- `navyLight` (#1A2F3A) — hover accents on navy, borders
- Interaction states: `navyHovered`, `navyPressed`

*Secondary Accent — Prestige Gold (trust, achievements, premium):*
Deeper gold — accent only, never dominant. Use sparingly for icons, divider accents, trust badges.
- `gold` (#C9A24D) — trust badges, upgrade CTAs, star ratings
- `goldDark` (#9A7E2A) — pressed states
- `goldLight` (#D4B060) — hover highlights
- Interaction states: `goldHovered`, `goldPressed`

*Input Field Tokens (premium contrast for forms):*
- `inputBackground` (#1A2F3A) — input field fill
- `inputBorderIdle` (#274453) — input border default state
- `inputBorderFocused` (#2E8B68) — input border focused (ties to green accent)

*Text Hierarchy Tokens (premium polish — avoid pure white):*
- `textPrimary` (#F2F6F8) — primary text on dark backgrounds
- `textSecondary` (#A7BCC9) — secondary text on dark backgrounds
- `textMuted` (#7F98A6) — helper/muted text on dark backgrounds

*Neutrals (cool-tinted):*
- `pure` (#FFFFFF), `sand` (#F8FAFB), `cloud` (#F2F5F7), `mist` (#D5DCE1), `stone` (#7F98A6), `slate` (#556275), `onyx` (#141A24)

*Semantic:* `success` (= green), `warning` (= gold), `error` (#D64545), `info` (#5B8DBE) — each with `Hovered` and `Pressed` variants

*Trust Tier Palette:* Each tier has foreground + background colors:
- `trustPlatinumFg/Bg` — cool blue-silver (highest trust)
- `trustGoldFg/Bg` — warm gold
- `trustSilverFg/Bg` — neutral grey
- `trustBronzeFg/Bg` — rich warm brown
- `trustCopperFg/Bg` — reddish-rust (new/unverified)

*Glass / Overlay Presets (pre-computed for performance):*
- `glassBorder` — white at 20%, `glassSurface` — white at 10%
- `glassTextSecondary` — white at 70%, `glassTextTertiary` — white at 50%
- `overlayDark` — black at 40%, `scrim` — black at 60%

*Gradients:* `navyGradient`, `greenGradient`, `goldGradient`, `subtleOverlay`, `backgroundGradient` (primary screen background with depth and dark anchor at bottom)

*Dark theme:* `AppColorsDark` provides full dark variants of all colors, interaction states, trust tiers, input fields, text hierarchy, and glass presets with teal-navy-tinted dark surfaces.

*Design principles for gold usage:* Gold should be accent only, never dominant. Use for icons, divider accents, one social button max. Social auth buttons should be neutral (Google = `secondary` (outlined), Apple = `navyFilled`). Visual hierarchy should always point to the primary CTA (Sign In), not social auth.

*Utility:* `AppColorStates.pressed(color)` and `AppColorStates.hovered(color)` for computing interaction states on arbitrary colors.

**Typography** (`typography.dart`) — Three font families:
- **Fraunces**: Sophisticated serif for display/headline tokens (`AppTypography.displaySmall`, `headlineMedium`, `headlineSmall`)
- **Manrope**: Refined sans-serif for body, title, label tokens and sans headline variants (`AppTypography.bodyMedium`, `labelLarge`, `headlineMediumSans`)
- **DM Mono**: Elegant monospace for scores and data (`AppTypography.monoLarge`, `monoDisplay`)

Sans-serif headline tokens exist for contexts where Manrope is needed at headline sizes (dialog titles, onboarding headings, bottom sheet headers): `displaySmallSans`, `headlineMediumSans`, `headlineSmallSans`.

`labelMicro` (11px) is available for badges, compact metadata, and dense UI elements.

**Canonical token-to-pattern mapping:**
- Screen titles / page headers → `headlineMediumSans`
- Section headers → `titleLarge`
- Button labels → `labelLarge`
- Captions / metadata → `labelSmall`

**Deprecated tokens** (still in codebase but annotated `@Deprecated`): `text10`, `text11`, `text13`. Use `labelMicro`, `labelSmall`, or `bodySmall` with `.copyWith()` instead.

**Spacing** (`spacing.dart`) — 8-point grid with 4px increments:
- **Scale**: `xxs` (4px), `xs` (8px), `sm` (12px), `md` (16px), `lg` (20px), `xl` (24px), `xxl` (32px), `xxxl` (48px)
- **Semantic**: `screenPadding` (20px), `cardPadding` (20px), `cardGap` (16px), `buttonGap` (12px), `formFieldGap` (16px)
- **Shortcuts**: `AppSpacing.card` (EdgeInsets.all(20)), `AppSpacing.screen`, `AppSpacing.verticalMdBox` (SizedBox)
- **Extensions**: `widgets.withVerticalSpacing(AppSpacing.sm)` for list spacing

**Elevation** (`elevation.dart`) — Shadow system:
- **Scale**: `AppElevation.xs` (hover), `sm` (cards), `md` (panels), `lg` (dropdowns), `xl` (modals)
- **Accent glows**: `glowGold` (premium/VIP features), `glowGreen` (success/active states)
- **Semantic**: `AppElevation.card`, `button`, `modal`, `dropdown`, `tooltip`

**Border Radius** (`border_radius.dart`):
- **Scale**: `xxs` (2px), `xs` (4px), `sm` (8px), `md` (12px), `lg` (16px), `xl` (20px), `xxl` (24px), `full` (999px)
- **Semantic**: `AppBorderRadius.button` (8px), `card` (12px), `modal` (16px), `avatar` (999px), `chip` (999px)
- **Consolidation rules**: 6→xs, 9/10→sm, 11/12.5→md, 14→lg, 32→xxl. Do not introduce off-grid radius values.

**Opacity** (`opacity.dart`):
- **Scale**: `subtle` (0.05), `light` (0.10), `medium` (0.20), `strong` (0.40), `prominent` (0.60), `heavy` (0.80)
- **Semantic**: `AppOpacity.disabled` (0.20), `overlay` (0.40), `hover` (0.05), `glass` (0.10)

**Icon Size** (`icon_size.dart`):
- **Scale**: `xs` (16px), `sm` (20px), `md` (24px), `lg` (32px), `xl` (40px), `xxl` (48px)
- **Semantic**: `AppIconSize.nav` (24px), `button` (20px), `listItem` (24px), `section` (32px), `feature` (40px), `avatar` (48px)

**App Icons** (`app_icons.dart`) — SVG icon asset paths:
- Unified icon system using custom SVGs with 1.75px stroke weight, round caps/joins, 24x24 grid
- Usage: `AppIcon(assetPath: AppIcons.games, size: AppIconSize.md, color: AppColors.navy)`
- All icons use `currentColor` for dynamic theming via `colorFilter`

#### Motion System (`lib/core/motion/motion_tokens.dart`)

- **Curves**: Enter = `Curves.easeOutCubic` (starts fast, ends slow). Exit = `Curves.easeInCubic` (starts slow, ends fast).
- **Route transitions**: enter 200ms / exit 170ms (exit 15% faster for snappiness)
- **Bottom sheets**: enter 260ms / exit 220ms
- **Dialogs**: enter 200ms / exit 170ms
- **Micro-interactions**: 100ms (button presses, toggles, hover)
- **Content reveal**: 160ms (staggered fades, scroll reveals)
- **Scale**: Page push 0.985 → 1.0 (subtle). Dialog 0.97 → 1.0 (noticeable).
- **Stagger**: 24ms between items, max 8 items
- **Reduced motion**: All durations × 0.65, no scale, no stagger

#### Premium UI Patterns (`lib/core/design_patterns/premium_ui_patterns.dart`)

Reusable premium components built on design tokens (note: file comments still reference old "Fairway Sunset" naming but code uses current tokens):
- `AppGradients` — preset gradients: `sunsetGold`, `sunsetRose`, `fairway`, `fairwayDark`, `sunsetSweep` (animated rings). **Note: these gradient names are stale and reference the old palette — they should be updated to match The Clubhouse naming (`goldGradient`, `greenGradient`, etc.) when this file is next touched.**
- `GlassCard` — semi-transparent card for dark backgrounds
- `GradientIconBox` — gradient-filled icon container with optional shadow
- `AnimatedAvatarRing` — rotating gradient ring around avatar (8s rotation)
- `StatCard` — compact metric display on glass background
- `QuickActionCard` — tappable action card with gradient icon
- `InfoRow` — labeled info row with colored icon badge
- `NotificationBadge` — gradient badge with glow effect
- `BottomSheetCard` — rounded top corners with drag handle
- `UsernamePill` — pill-shaped badge for @username display

#### Reusable Core Widgets (`lib/core/widgets/`)

Prefixed with `app_` and built on design tokens:
- `app_button_enhanced.dart` — Button variants: `primary`, `secondary` (outlined), `ghost` (transparent/text), `gradient` (gold-filled), `destructive`, `navyFilled` (solid dark fill)
- `app_card.dart` — Standard card with token-based elevation and border radius
- `app_text_field.dart` — Form input with token-based styling
- `app_text.dart` — Text component wrapping `AppTypography`
- `app_badge.dart` — Status badges
- `app_avatar.dart` — User avatar with fallback
- `app_section_header.dart` — Section header pattern
- `app_empty_state.dart` — Empty state placeholder
- `app_loading_state.dart` — Loading state pattern
- `app_list_tile.dart` — Consistent list item
- `app_choice_chips.dart` — Chip group selection
- `app_icon.dart` — Icon wrapper with `AppIconSize` and SVG support
- `app_icon_badge.dart` — Icon with notification badge
- `app_info_grid.dart` — Grid layout for info display
- `premium_back_button.dart` — Styled back navigation
- `fairway_background.dart` — Gradient background wrapper
- `profile_hero_section.dart`, `profile_card_section.dart` — Profile layout components
- `vibe_slider_card.dart` — Vibe preference slider
- `trust/` subfolder — Trust-specific widgets (luxury_player_card, trust_badge_chip, restriction_banner, cancellation_warning_icon)

#### Quick Reference
```dart
// Typography
Text('Screen Title', style: AppTypography.headlineMediumSans)
Text('Section', style: AppTypography.titleLarge)
Text('Body', style: AppTypography.bodyMedium)
Text('Button', style: AppTypography.labelLarge)
Text('Badge', style: AppTypography.labelMicro)
Text('72', style: AppTypography.monoDisplay)

// Colors — use the three roles
Container(color: AppColors.green)         // Primary accent (CTAs) — #1F6B4E
Container(color: AppColors.navy)          // Structural (headers/cards) — #142A36
Container(color: AppColors.gold)          // Secondary accent (trust/premium) — #C9A24D

// Input fields (premium contrast)
decoration: BoxDecoration(
  color: AppColors.inputBackground,
  border: Border.all(color: isFocused ? AppColors.inputBorderFocused : AppColors.inputBorderIdle),
)

// Text hierarchy on dark backgrounds (avoid pure white)
Text('Heading', style: TextStyle(color: AppColors.textPrimary))    // #F2F6F8
Text('Subtext', style: TextStyle(color: AppColors.textSecondary))  // #A7BCC9
Text('Helper', style: TextStyle(color: AppColors.textMuted))       // #7F98A6

// Interaction states
color: isPressed ? AppColors.greenPressed : AppColors.green
// Or for arbitrary colors:
color: AppColorStates.pressed(someColor)

// Trust tiers
Container(color: AppColors.trustGoldBg)
Text('Gold', style: TextStyle(color: AppColors.trustGoldFg))

// Glass presets (no more manual withOpacity)
Container(
  decoration: BoxDecoration(
    color: AppColors.glassSurface,
    border: Border.all(color: AppColors.glassBorder),
  ),
)

// Gradients
Container(decoration: BoxDecoration(gradient: AppColors.navyGradient))
Container(decoration: BoxDecoration(gradient: AppColors.greenGradient))

// Spacing
Padding(padding: AppSpacing.card)   // 20px all sides
SizedBox(height: AppSpacing.md)     // 16px
Column(children: widgets.withVerticalSpacing(AppSpacing.sm))

// Elevation
Container(decoration: BoxDecoration(boxShadow: [AppElevation.card]))

// Border radius
Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppBorderRadius.card)))

// Icons (SVG)
AppIcon(assetPath: AppIcons.games, size: AppIconSize.md, color: AppColors.navy)

// Motion
AnimatedContainer(duration: MotionTokens.microInteraction, curve: MotionTokens.curveEnter)
```

#### AppTheme Bridge (Legacy — `lib/core/app_theme.dart`)

`AppTheme` is a `ThemeExtension` that maps design tokens to Flutter's theme system using FlutterFlow-era naming. It exists because some widget files still reference `AppTheme.of(context)`. The current mapping:
- `AppTheme.of(context).primary` → `AppColors.navyDark` (#0E1C26)
- `AppTheme.of(context).secondary` → `AppColors.navy` (#142A36)
- `AppTheme.of(context).accent1` → `AppColors.gold` (#C9A24D approximately)
- `AppTheme.of(context).primaryText` → `AppColors.onyx` (#141A24)

**Do not add new `AppTheme.of(context)` usage.** For new code, use tokens directly. `AppTheme` is scheduled for cleanup.

#### Known Design Debt

- **`premium_ui_patterns.dart`** has stale naming — `AppGradients` references old "Fairway Sunset" names (`sunsetGold`, `fairway`) instead of The Clubhouse vocabulary. Comments in the file also reference the old design language. Update when next modifying this file.
- **Remaining `withOpacity()` deprecation warnings** — use `Color.withValues(alpha: ...)` or the pre-computed glass/overlay constants in `AppColors` instead.
- **Some files still use `AppTheme.of(context)`** with FlutterFlow naming instead of direct tokens.
- **Deprecated typography helpers** (`text10`, `text11`, `text13`) still referenced in ~11 files — migrate to semantic tokens when touching these files.
- **`caption` token** still used in ~10 files alongside the standard `labelSmall` — consolidate to `labelSmall` when touching these files.
- **54 hardcoded BoxShadow instances** remain (intentionally — upward shadows, animated glows, dynamic colors that don't map to tokens).
- **Flutter analyze: ~55 remaining issues** (non-blocking: unused imports, deprecated API usage).

### Data Models: Record Classes vs Model Classes

The app has two layers of data representation (legacy from FlutterFlow migration):

- **`backend/schema/*_record.dart`** (e.g., `GamesRecord`, `UsersRecord`) — Firestore record classes. These extend `FirestoreRecord`, use `_initializeFields()` and `hasX()` patterns. They are the primary Firestore data layer used by services and providers. **Do not remove these** — they are deeply embedded (UsersRecord: 29+ files, GamesRecord: 13+ files).

- **`models/*.dart`** (e.g., `Game`, `Chat`, `UserProfile`) — Domain model classes with business logic. `Game` adds status resolution (active/expired/cancelled). `Chat` and `UserProfile` are standalone models with `fromDoc()` factory methods.

**When to use which:**
- Services return `*Record` types from Firestore queries
- `Game.fromRecord(gamesRecord)` converts to the domain model for UI consumption
- Widgets should use domain models (`Game`, `Chat`) when business logic is needed
- When adding new Firestore fields, update the `*Record` class. If the field needs business logic, also update the corresponding model.

**Shared business logic:** Game status resolution (active/expired/cancelled) lives in `Game.resolveGameStatus()` — a single static method called by both `Game.fromDoc()` and `Game.fromRecord()`. Do not duplicate this logic.

### Cloud Functions (`firebase/functions/`)

**Main Modules**:
- `index.js` - Entry point, exports all functions
- `confirmation_flow.js` - Game confirmation and round job processing
- `trust_system.js` - Trust score calculations
- `trust_profile.js` - Trust profile management
- `game_alerts.js` - Push notifications for new games

**Behavioral Dataset** (`src/`):
- `booking.js` - Round creation and participant management
- `lifecycle.js` - Confirm, decline, cancel, check-in, complete flows
- `matching.js` - Pairwise match generation
- `feedback.js` - Post-round feedback collection
- `sync.js` - Player round sync and BigQuery export

**Notification System** (`notifications/`):
- Trust-based notification scheduling with Cloud Tasks
- Quiet hours support
- FCM token management

### Firestore Collections

Key collections:
- `users/` - User profiles and preferences
- `games/` - Posted golf games
- `games/{id}/game_participants/` - Players in each game
- `chats/` - Chat threads
- `alertSubs/` - Game alert subscriptions
- `round_jobs/` - Confirmation flow job queue

## Code Style & Conventions

### Dart/Flutter
- **Imports**: Use absolute imports with leading slash (e.g., `import '/models/game.dart'`), not `package:` imports for project files
- **Lint rules**: Minimal — `flutter_lints` 4.0.0 with default rules. `lib/custom_code/**` is excluded from analysis. Do not add stricter lint rules without discussion.
- **Widget structure**: Each screen lives in a feature folder with a main `*_widget.dart` file and a `components/` subfolder for sub-widgets. Screens are suffixed `Widget` (e.g., `GamesListWidget`, `CreateGameWidget`)
- **Reusable widgets**: Live in `lib/core/widgets/` and are prefixed with `app_` (e.g., `app_button.dart`, `app_card.dart`, `app_text_field.dart`)
- **Naming**: Files use `snake_case`. Classes use `PascalCase`. Route names match widget class names.
- **Logging**: Use `AppLog.d()` from `lib/core/utils/app_log.dart` for all logging in services AND providers. Do not use `print()` or `debugPrint()`.
- **Emoji in logs**: Use emoji prefixes for log readability: ✅ success, ❌ error, 📖 info, 📱 chat operations, 🔵 stream events, 💬 chat UI, 🔥 cache warming, 🆕 new fetches
- **Icons**: Always use `AppIcon` with `AppIconSize` tokens. Do not use raw `Icon()` with hardcoded sizes. When no SVG equivalent exists in `AppIcons`, use `Icon()` but always pair with `AppIconSize` for the size parameter. See `docs/icon-size-mapping-reference.md` for which token to use in which context.

### Provider Pattern
Providers follow a consistent structure:
- Extend `ChangeNotifier`
- Accept their service via constructor with default: `GameProvider({GameService? service}) : _service = service ?? GameService();`
- Use a `_disposed` flag checked before `notifyListeners()`
- Cache data with TTL (typically 5 minutes) using `Map<String, DateTime>` timestamps
- Use `StreamRequestManager` for reactive Firestore streams with `BehaviorSubject` caching
- Debounce `notifyListeners()` with a 50ms timer via `_scheduleNotify()` to prevent UI jank
- Mutations delegate Firestore writes to the service, then invalidate relevant caches
- Errors are caught, logged with `AppLog.d()`, and rethrown — let the UI layer handle display
- Access via extensions: `context.userProvider`, `context.gameProvider` (see `lib/providers/provider_extensions.dart`)

### Service Pattern
Services handle direct Firestore/Firebase interactions:
- Instance classes with optional `FirebaseFirestore` injection for testability (e.g., `GameService({FirebaseFirestore? firestore})`)
- Use internal caching where appropriate (e.g., user profile cache in ChatService)
- Batch Firestore operations respecting the 500-operation batch limit and 10-item `whereIn` limit
- Use `rxdart` (`switchMap`, `combineLatestList`) for composing complex Firestore streams
- Catch `FirebaseException` specifically (not generic `catch`) to log error codes: `on FirebaseException catch (e) { AppLog.d('❌ ServiceName.method error: ${e.code} - ${e.message}'); rethrow; }`
- Transactions used for concurrent-safe operations (reactions, chat creation, game join)

## Error Handling

### Custom Exceptions (`lib/core/exceptions/app_exceptions.dart`)
All custom exceptions extend `AppException` which has `message`, `code`, and `cause` fields:
- `GameOperationException` — game join/leave/create failures
- `FriendOperationException` — friend/social failures
- `ChatOperationException` — chat failures
- `PermissionException` — authorization failures
- `NetworkException` — connectivity failures

### Error Handling Pattern
- **Services**: Catch `FirebaseException` specifically, log with `AppLog.d()` including `e.code` and `e.message`, rethrow. Do not swallow errors.
- **Providers**: Catch errors from services, log with `AppLog.d()`, rethrow to UI layer.
- **Non-critical operations** (e.g., chat membership sync after join, typing status updates): Catch with generic `catch` and log silently — do not fail the parent operation.
- **Firebase error utilities**: `lib/core/utils/firebase_error_utils.dart` and `lib/core/utils/error_messages.dart` provide user-friendly error message mapping.

## Navigation

### GoRouter (`lib/core/navigation/app_router.dart`)
- Uses `go_router` 17.0.1 with `AppStateNotifier` as `refreshListenable` for auth-reactive routing
- Each widget defines static `routeName` and `routePath` constants
- Route parameters passed via `state.extra` (typically `DocumentReference` for game/user refs)
- Auth redirect handled via `_buildRedirect()` — unauthenticated users redirect to `/signIn`
- Custom page transitions via `TransitionInfo` with support for reduced motion (`ReducedMotionService`)
- Transition presets in `lib/core/navigation/transition_standards.dart`: modal, detail, dismissal, tab
- Tab-level screens wrap content in `NavBarPage(initialPage: 'TabName')`

### Adding a New Screen
1. Create feature folder: `lib/feature_name/feature_widget.dart`
2. Add `routeName` and `routePath` static constants to the widget
3. Add `GoRoute` entry in `app_router.dart` with `_buildRedirect` and `_buildPageWithTransition`
4. Use `TransitionStandards` constant for the appropriate transition type
5. Add component widgets in a `components/` subfolder

## Environment & Firebase Config

### Firebase Setup (`lib/backend/firebase/firebase_config.dart`)
- **Project ID**: `find-my-fourth`
- **Region**: `us-west2`
- **Environments**: `dev`, `staging`, `prod` — controlled via `APP_ENV` build flag from `lib/core/config/build_flags.dart`
- **Emulator support**: Enabled in debug mode when `USE_FIREBASE_EMULATOR` flag is true. Configures Auth (9099), Firestore (8080), Functions (5001), Storage (9199) emulators.
- **Safety checks**: Release builds enforce `APP_ENV=prod` and `USE_FIREBASE_EMULATOR=false`
- **Platform**: Uses `Firebase.initializeApp()` natively (iOS/Android config from `GoogleService-Info.plist` / `google-services.json`). Web uses inline `FirebaseOptions`.

### No `.env` files
Environment configuration is handled via Dart compile-time constants (`--dart-define`), not `.env` files.

## Key Dependencies & Versions

- **Flutter SDK**: >=3.0.0 <4.0.0
- **State management**: `provider` 6.1.5
- **Navigation**: `go_router` 17.0.1
- **Firebase**: Auth 6.1.3, Firestore 6.1.1, Functions 6.0.5, Messaging 16.1.0, Storage 13.0.5, Crashlytics, Analytics, Performance
- **Auth providers**: `google_sign_in` 7.2.0, `sign_in_with_apple` 7.0.1
- **Reactive streams**: `rxdart` 0.28.0, `stream_transform` 2.1.1
- **UI**: `flutter_animate` 4.5.2, `flutter_spinkit` 5.2.2, `cached_network_image` 3.4.1, `auto_size_text` 3.0.0
- **Cloud Functions runtime**: Node.js 20

## File Creation Conventions

When adding a new feature, the typical file set is:
- `lib/feature_name/feature_widget.dart` — main screen widget
- `lib/feature_name/components/*.dart` — sub-widgets for that screen
- `lib/models/feature_model.dart` — data model (if new data type)
- `lib/services/feature_service.dart` — Firestore/business logic (instance class with DI)
- `lib/providers/feature_provider.dart` — state management (accepts service via constructor)
- `lib/backend/schema/feature_record.dart` — Firestore record class (if using the schema pattern)

## Common Pitfalls & Things to Avoid

- **Don't bypass the service layer for Firestore writes** — providers delegate writes to services; widgets never write to Firestore directly
- **Don't duplicate business logic across `fromDoc()` and `fromRecord()`** — use a shared method (see `Game.resolveGameStatus()`)
- **Don't use static-only service classes** — use instance classes with `FirebaseFirestore?` constructor injection for testability
- **Don't forget the 10-item `whereIn` limit** — batch Firestore queries using the chunk pattern (see `ChatService._chunkList`)
- **Don't forget the 500-operation batch limit** — loop in chunks of 500 for batch writes
- **Don't use `notifyListeners()` directly in providers** — use the `_scheduleNotify()` debounce pattern to avoid UI jank from rapid updates
- **Don't call `notifyListeners()` after dispose** — always check `_disposed` flag
- **Don't add packages without discussion** — the dependency list is intentional; check existing packages before adding new ones
- **Don't put business logic in widgets** — keep it in services; widgets consume providers
- **Don't use `debugPrint()` or `print()`** — use `AppLog.d()` everywhere
- **Don't catch generic exceptions in services** — catch `FirebaseException` specifically to preserve error codes
- **`lib/custom_code/`** is excluded from analysis and contains legacy/generated code — avoid modifying or depending on it for new features
- **`lib/app_state.dart`** is legacy — it only holds SharedPreferences-backed cancelled game state. Do not add new state here; use the appropriate domain provider instead.
- **Don't use hardcoded icon sizes** — use `AppIconSize` tokens (e.g., `AppIconSize.button`, `AppIconSize.listItem`). Literal pixel values on icons bypass the design system and create visual inconsistency.
- **Don't use raw `Icon()` when an `AppIcons` SVG exists** — use `AppIcon(assetPath: AppIcons.xxx)` to stay within the unified icon system. Check `app_icons.dart` before reaching for Material Icons.
- **Don't hardcode `fontFamily`, `fontSize`, or `fontWeight`** — use `AppTypography` tokens. If no token matches exactly, use the closest token with `.copyWith()`. Never use raw `TextStyle(fontFamily: 'Manrope', ...)`.
- **Don't hardcode `BorderRadius.circular()` values** — use `AppBorderRadius` tokens. Map to nearest token: 8→sm, 12→md, 16→lg, 20→xl, 24→xxl, 999→full.
- **Don't hardcode spacing values** — use `AppSpacing` tokens and shortcuts. Use `AppSpacing.allMd` instead of `EdgeInsets.all(16)`, and `AppSpacing.verticalSmBox` instead of `SizedBox(height: 12)`.
- **Don't hardcode `BoxShadow()`** — use `AppElevation` tokens. Use semantic aliases when context matches (e.g., `AppElevation.card` for cards, `AppElevation.modal` for modals).
- **Don't use `AppSpacing` tokens for `BorderRadius`** — spacing and radius are separate token systems. Use `AppBorderRadius` for border radius values.

## Vibe System

The "vibe" matching system connects compatible golfers based on play style preferences. Key files:
- `lib/models/vibe_profile.dart` - Profile data model
- `lib/services/vibe_matcher.dart` - Core matching algorithm
- `lib/services/vibe_group_matcher.dart` - Group compatibility
- `test/vibe_scoring_test.dart` - Scoring test cases

## Testing

**Flutter tests**: `test/` directory with subdirectories mirroring `lib/`

**Cloud Functions tests**: `firebase/functions/test/`
- Jest-based tests
- Load testing: `npm run load-test` or `npm run load-test:small`

## Firebase Project

- Project ID: `find-my-fourth`
- Region: `us-west2`
- Node.js version: 20 (for Cloud Functions)
