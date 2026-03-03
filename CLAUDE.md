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
- `services/` - Service and repository classes for Firestore/domain access
- `core/` - Design system, widgets, utilities, navigation

### Design System

**Philosophy: "The Clubhouse"** — A trust-first golf matchmaking aesthetic built on three color roles: Green (darker, richer "fairway at dusk" — every interactive element), Deep Teal-Navy (structural surfaces with green undertones), Gold (demoted to accent-only — trust, achievements, premium). Typography blends traditional golf club sophistication with modern athletic energy.

**For new code: always use design tokens directly.** Import from `lib/core/design_tokens/` and use `AppColors`, `AppTypography`, `AppSpacing`, etc. Do not hardcode colors, font sizes, or spacing values. Do not introduce new `AppTheme.of(context)` usage (see legacy note below).

#### Design Tokens (`lib/core/design_tokens/`)

The token system is the source of truth for all visual design. **Always read the token source files for exact values** — use `AppColors`, `AppTypography`, `AppSpacing`, `AppElevation`, `AppBorderRadius`, `AppOpacity`, `AppIconSize` directly. Never hardcode colors, sizes, or spacing.

**Three Color Roles** (`colors.dart` — "The Clubhouse" palette):
- **Green** (`AppColors.green`) — all interactive elements (CTAs, active nav, links). Each has `Dark`/`Light`/`Hovered`/`Pressed` variants.
- **Navy** (`AppColors.navy`) — structural surfaces (cards, headers, nav). Variants: `navyDark` (app bar, primary bg), `navyLight` (borders, hover).
- **Gold** (`AppColors.gold`) — accent only, never dominant. Trust badges, achievements, premium. Use sparingly.
- Text hierarchy: `textPrimary`, `textSecondary`, `textMuted` (avoid pure white)
- Semantic: `success`, `warning`, `error`, `info` with interaction variants
- Trust tiers: `trustPlatinum/Gold/Silver/Bronze/Copper` each with `Fg`/`Bg`
- Pre-computed: glass/overlay presets, gradients, input field tokens
- Utility: `AppColorStates.pressed(color)` / `.hovered(color)` for arbitrary colors

**Typography** (`typography.dart`) — Three font families:
- **Fraunces**: Serif for display/headline (`displaySmall`, `headlineMedium`, `headlineSmall`)
- **Manrope**: Sans-serif for body/title/label + sans headline variants (`headlineMediumSans`, etc.)
- **DM Mono**: Monospace for scores/data (`monoLarge`, `monoDisplay`)
- Mapping: Screen titles → `headlineMediumSans`, sections → `titleLarge`, buttons → `labelLarge`, captions → `labelSmall`, badges → `labelMicro`

**Other Token Files** — Read source files for exact scales/values:
- `spacing.dart` — 8-point grid. Semantic: `screenPadding`, `cardPadding`, `cardGap`. Shortcuts: `AppSpacing.card`, `.screen`, `.verticalMdBox`
- `elevation.dart` — Scale xs→xl + semantic aliases (`card`, `modal`) + accent glows
- `border_radius.dart` — Scale xxs→full + semantic (`button`=8, `card`=12, `modal`=16, `avatar`=999). Don't introduce off-grid values.
- `opacity.dart` — Scale + semantic (`disabled`=0.20, `overlay`=0.40, `glass`=0.10)
- `icon_size.dart` — Scale xs→xxl + semantic (`nav`=24, `button`=20, `listItem`=24, `section`=32)

**Icons** — Phosphor Icons (`app_phosphor_icons.dart`) is the primary system:
- `PhosphorIconsRegular` everywhere; `PhosphorIconsFill` only for active nav
- Usage: `AppIcon(icon: AppPhosphorIcons.games, size: AppIconSize.md, color: AppColors.textSecondary)`
- Color rules: informational→`textSecondary`, active→`green`, trust→`gold`, nav inactive→`textMuted`
- Legacy SVG system (`AppIcons`/`app_icons.dart`) is deprecated — don't use for new code

#### Visual Patterns

Guiding principle: **color is earned, not sprinkled**. Premium feel comes from typography contrast, generous spacing, motion choreography, and quiet surfaces — not more color. Check these drivers before reaching for color.

**Icon color decision tree**: disabled→`textMuted`+opacity, error/warning→semantic color, on colored bg→`textPrimary`, interactive/active→`green`, trust/achievement→`gold`, nav inactive→`textMuted`, default→`textSecondary`.

**Icon badges** (`AppIconBox`): Only for trust/achievement, feature highlight (empty states), or prominent CTA (FAB). Do NOT wrap informational icons in colored containers.

**Card variants** (all share navy bg, `navyLight` border, `AppBorderRadius.card`, `AppSpacing.cardPadding`):
- **Info Card**: Icon + label/value, compact, no elevation (game details, profile attributes)
- **Stat Card**: Large centered value + label, optional `glowGold` (hero metrics)
- **Action Card**: Title + chevron, hover/press states, slight elevation (settings, navigation)

**Color guardrail**: Most screens need 1-2 green elements (primary CTA + active state) and 0-1 gold (trust badge). Color must be justified by function, not decoration.

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

Reusable premium components built on design tokens: `GlassCard`, `GradientIconBox`, `AnimatedAvatarRing`, `QuickActionCard`, `InfoRow`, `NotificationBadge`, `BottomSheetCard`, `UsernamePill`. Note: `StatCard` here is deprecated — use `AppStatCard` from `app_stat_card.dart`. Gradient names (`sunsetGold`, etc.) are stale and should be updated to match The Clubhouse naming when next touched.

#### Reusable Core Widgets (`lib/core/widgets/`)

Prefixed with `app_` and built on design tokens. Key widgets: `app_button_enhanced.dart` (variants: `primary`, `secondary`, `ghost`, `premium`, `destructive`, `destructiveOutlined`, `navyFilled`, `google`), `app_card.dart`, `app_text_field.dart`, `app_text.dart`, `app_badge.dart`, `app_avatar.dart`, `app_section_header.dart`, `app_empty_state.dart`, `app_loading_state.dart`, `app_list_tile.dart`, `app_choice_chips.dart`, `app_icon.dart` (supports Phosphor icons + legacy SVGs; includes `AppNavIcon` and `AppIconBox`), `app_icon_badge.dart`, `app_info_grid.dart`, `premium_back_button.dart`, `fairway_background.dart`, `profile_hero_section.dart`, `profile_card_section.dart`, `vibe_slider_card.dart`. Trust-specific widgets in `trust/` subfolder.

#### Button Variant Usage

| Scenario | Variant | Example |
|----------|---------|---------|
| Main CTA per screen | `primary` | "Join Game", "Save Changes" |
| Secondary prominent (auth flows) | `navyFilled` | Alt sign-in options |
| Secondary action | `secondary` | "Back", non-destructive cancel |
| Destructive (not final) | `destructiveOutlined` | "Leave Game", "Delete Account" |
| Final destructive confirmation | `destructive` | Modal "Confirm Delete" |
| Tertiary/dismiss | `ghost` | "Maybe later", inline links |
| Onboarding completion ONLY | `premium` | "Build Your Profile" |

**Rule**: Most screens need 1 green CTA, 0-1 gold elements. Gold (`premium`) is earned, not sprinkled — use only for onboarding completion or premium upsells.

#### Quick Reference
```dart
// Typography: AppTypography.headlineMediumSans, .titleLarge, .bodyMedium, .labelLarge, .labelMicro, .monoDisplay
// Colors: AppColors.green (CTAs), .navy (structure), .gold (accent), .textPrimary/.textSecondary/.textMuted
// Input: AppColors.inputBackground, .inputBorderIdle, .inputBorderFocused
// States: AppColors.greenPressed, AppColorStates.pressed(color)
// Trust: AppColors.trustGoldFg/Bg, trustPlatinumFg/Bg, etc.
// Glass: AppColors.glassSurface, .glassBorder
// Spacing: AppSpacing.card (20px all), .md (16px), .sm (12px); widgets.withVerticalSpacing(AppSpacing.sm)
// Elevation: AppElevation.card, .modal; .glowGold, .glowGreen
// Radius: BorderRadius.circular(AppBorderRadius.card) // 12px
// Icons: AppIcon(icon: AppPhosphorIcons.games, size: AppIconSize.md, color: AppColors.textSecondary)
// Nav: AppNavIcon(icon: AppPhosphorIcons.games, iconFill: AppPhosphorIcons.gamesFill, isActive: true)
// Motion: MotionTokens.microInteraction (100ms), .curveEnter (easeOutCubic)
```

#### AppTheme Bridge (Legacy — `lib/core/app_theme.dart`)

`AppTheme` is a `ThemeExtension` that maps design tokens to Flutter's theme system using FlutterFlow-era naming. It exists because some widget files still reference `AppTheme.of(context)`. The current mapping:
- `AppTheme.of(context).primary` → `AppColors.navyDark` (#0E1C26)
- `AppTheme.of(context).secondary` → `AppColors.navy` (#142A36)
- `AppTheme.of(context).accent1` → `AppColors.gold` (#C9A24D approximately)
- `AppTheme.of(context).primaryText` → `AppColors.onyx` (#141A24)

**Do not add new `AppTheme.of(context)` usage.** For new code, use tokens directly. `AppTheme` is scheduled for cleanup.

#### Known Design Debt

- SVG icon system (`AppIcons`) deprecated → use `AppPhosphorIcons`; remove SVGs after full migration
- `StatCard` in `premium_ui_patterns.dart` deprecated → use `AppStatCard`
- Replace remaining `withOpacity()` calls with `Color.withValues(alpha:)` or pre-computed constants
- Some files still use `AppTheme.of(context)` — migrate to direct tokens
- `caption` token used in ~10 files — consolidate to `labelSmall`
- ~5 flutter analyze issues remaining (unnecessary imports)

#### Microcopy & Content Guidelines (`lib/core/content/app_copy.dart`)

**Voice**: Quiet confidence — clear, composed, trustworthy. Not playful, loud, or pretentious. Semi-formal, no slang, no corporate buzzwords.

**Rules**: No emoji in system messages/errors/trust flows. No exclamation marks in system flows. No ALL CAPS. Sentence case. Button labels: max 4 words, clear action verbs ("Request spot", not "Let's play"). Use constants from `app_copy.dart` for common messages.

**Tone examples**: "You're confirmed for this round." not "Awesome! You're in 🎉". "We couldn't load this round." not "Uh oh! Something went wrong."

**Trust-sensitive areas** (ratings, vibe scoring, cancellations): Neutral, procedural tone. Never imply blame.

**Empty states**: Calm, competent, forward-looking. No emoji, no "Uh oh", no humor, no golf clichés. Patterns range from pure informational ("No new notifications.") to procedural ("Profile review in progress. This usually takes up to 24 hours."). See `app_copy.dart` for full patterns.

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
- **Lint rules**: `flutter_lints` 6.0.0 with strict rules enabled (strict-casts, strict-raw-types, use_build_context_synchronously, cancel_subscriptions). See `analysis_options.yaml`. `lib/custom_code/**` is excluded from analysis.
- **Widget structure**: Each screen lives in a feature folder with a main `*_widget.dart` file and a `components/` subfolder for sub-widgets. Screens are suffixed `Widget` (e.g., `GamesListWidget`, `CreateGameWidget`)
- **Reusable widgets**: Live in `lib/core/widgets/` and are prefixed with `app_` (e.g., `app_button.dart`, `app_card.dart`, `app_text_field.dart`)
- **Naming**: Files use `snake_case`. Classes use `PascalCase`. Route names match widget class names.
- **Logging**: Use `AppLog.d()` from `lib/core/utils/app_log.dart` for all logging in services AND providers. Do not use `print()` or `debugPrint()`.
- **Emoji in logs**: Use emoji prefixes for log readability: ✅ success, ❌ error, 📖 info, 📱 chat operations, 🔵 stream events, 💬 chat UI, 🔥 cache warming, 🆕 new fetches
- **Icons**: Always use `AppIcon` with `AppPhosphorIcons` and `AppIconSize` tokens. For new code, use `AppIcon(icon: AppPhosphorIcons.xxx)`. Do not use raw `Icon()` or `PhosphorIcon()` with hardcoded sizes. For navigation with active/inactive states, use `AppNavIcon` with both `icon` and `iconFill` variants. See `docs/icon-size-mapping-reference.md` for which token to use in which context.

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
- **Icons**: `phosphor_flutter` (Phosphor Icons — primary icon system)
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

- **Don't bypass the service layer** — widgets never write to Firestore directly; providers delegate to services
- **Don't duplicate business logic** across `fromDoc()` and `fromRecord()` — use shared methods (e.g., `Game.resolveGameStatus()`)
- **Don't use static-only service classes** — use instance classes with `FirebaseFirestore?` constructor injection
- **Don't forget Firestore limits** — 10-item `whereIn` (use chunk pattern), 500-operation batch limit
- **Don't call `notifyListeners()` directly** — use `_scheduleNotify()` debounce pattern; check `_disposed` flag
- **Don't add packages without discussion** — check existing packages first
- **Don't put business logic in widgets** — keep it in services
- **Don't use `debugPrint()` or `print()`** — use `AppLog.d()` everywhere
- **Don't catch generic exceptions in services** — catch `FirebaseException` specifically
- **Don't hardcode design values** — use design tokens for colors, typography, spacing, border radius, shadows, icon sizes. Use `AppIcon` with `AppPhosphorIcons`, not raw `Icon()`. Use `AppBorderRadius`, not `BorderRadius.circular(12)`. Use `AppSpacing` tokens, not literal `EdgeInsets`.
- **Don't hardcode colors** — never use `Colors.*`, `Color(0x...)`, `Color.fromARGB()`, or `Color.fromRGBO()` in `lib/`. Use `AppColors` tokens. CI enforces this via `tool/check_hardcoded_colors.sh`. Exceptions (brand colors, token definitions) go in `tool/hardcoded_color_allowlist.txt`.
- **Don't create widgets over 300 lines** — decompose into sub-widgets in a `components/` subfolder
- **Don't use `setState` after `await` without a mounted check** — always add `if (!mounted) return;`
- **Don't use empty `setState(() {})`** — use targeted state updates via Provider
- **Don't forget to cancel `StreamSubscription`** — every subscription declared in a widget or provider must be cancelled in `dispose()`
- **Don't put direct Firebase calls in controllers** — controllers extract logic from widgets but still delegate to services via providers
- **`lib/custom_code/`** is excluded from analysis — avoid depending on it for new features
- **`lib/app_state.dart`** is legacy — only holds SharedPreferences-backed cancelled game state; use domain providers instead

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
