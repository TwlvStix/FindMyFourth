# Codebase Concerns

## High Priority

### 1. Missing Server-Side Chat Validation
- **File**: `lib/chat_group/game_chat_details/components/chat_input_bar.dart` (line 152)
- **Issue**: Client enforces 154-char `maxLength`, but Firestore security rules don't validate message length
- **Risk**: Malicious client could bypass limit
- **Fix**: Add `data.message.size() <= 154` in `firebase/firestore.rules`

### 2. Unbounded Firestore Query
- **File**: `lib/services/notification_crud_service.dart` (line 159)
- **Issue**: `.orderBy('createdAt').get()` with no `.limit()`
- **Risk**: Could return thousands of documents, causing memory/performance issues
- **Fix**: Add `.limit(N)` to bound the query

### 3. App Check Not Enabled on Web
- **File**: `lib/backend/firebase/firebase_config.dart` (line 80)
- **Issue**: Web App Check intentionally disabled (reCAPTCHA not configured)
- **Risk**: Web surface unprotected from API abuse
- **Status**: Infrastructure setup incomplete (TODO)

---

## Technical Debt

### Legacy Code Areas

#### Backend Schema Records (`lib/backend/schema/`)
- FlutterFlow migration legacy
- `UsersRecord`: 29+ file references, cannot remove
- `GamesRecord`: 13+ file references, cannot remove
- Large files: `GamesRecord` (766 lines), `UsersRecord` (766 lines)
- **Status**: Permanent dependency — coexists with domain models via `Game.fromRecord()`

#### AppState (`lib/app_state.dart`)
- Singleton holding SharedPreferences-backed cancelled game state
- 51 lines, used in `lib/utils/app_util.dart`
- **Status**: Legacy, should use domain providers

#### AppTheme Bridge (`lib/core/app_theme.dart`)
- FlutterFlow-era `ThemeExtension` mapping tokens to theme system
- Mostly removed — only 2 references found
- **Status**: Scheduled for final cleanup

#### SVG Icon System (`lib/core/widgets/app_icons.dart`)
- Deprecated in favor of `AppPhosphorIcons`
- **Status**: Migration in progress, full removal pending

#### StatCard (`lib/core/design_patterns/premium_ui_patterns.dart`, line 840)
- Deprecated in favor of `AppStatCard` from `app_stat_card.dart`
- Still used in 14 files across profile, challenges, notifications, onboarding
- **Status**: Gradual migration needed

### Caption Token Usage
- ~15 files use `caption` token instead of `labelSmall`
- **Status**: Deferred, low priority

### Hardcoded fontSize Values (Intentional/Deferred)
- `archetype_share_card.dart` — screenshot export (intentional fixed sizes)
- `cinematic_foursome_toast.dart`, `cinematic_notification_banner.dart` — onboarding animations
- `cancellation_warning_modal.dart`, `trust_profile_section.dart` — trust screens
- `quiet_hours_content.dart` — settings
- `chat_reaction_picker.dart` — emoji size (intentional)
- `main.dart:476` — debug label

---

## Code Quality Issues

### File Size Violations (Over 300 Lines)
| File | Lines | Area |
|------|-------|------|
| `lib/services/chat_service.dart` | 985 | Chat service |
| `lib/screens/trust/your_standing_screen.dart` | 909 | Trust UI |
| `lib/core/button_tabbar.dart` | 855 | Core widget |
| `lib/core/design_patterns/premium_ui_patterns.dart` | 840 | Design patterns |
| `lib/screens/trust/trust_profile_section.dart` | 809 | Trust UI |
| `lib/user_auth/sign_up_account/sign_up_account_widget.dart` | 801 | Auth UI |
| `lib/debug/notification_routing_test_screen.dart` | 767 | Debug screen |

**Recommendation**: `ChatService` (985 lines) is the most critical — consider splitting into read/write or extracting reactions/typing logic.

### Color Token Violations
- 40+ files contain `Colors.*` or hardcoded hex values
- Many annotated with `// Keep: no X% token` or are brand colors (Google logo)
- CI check: `tool/check_hardcoded_colors.sh` with `tool/hardcoded_color_allowlist.txt`
- **Status**: Most are intentional or mitigated via allowlist

### withOpacity() Migration
- Mostly migrated to `Color.withValues(alpha:)` for Flutter 3.27+
- Remaining instances in `branded_golf_header.dart`, `segmented_control.dart`, and several UI files
- **Status**: Near complete

---

## Performance Concerns

### Query Optimization
- **Pagination**: Properly implemented in `PlayerSearchService`, `NotificationCrudService`, `FirestoreRepository`
- **whereIn batching**: `ChatService._chunkList()` properly chunks into batches of 10
- **Batch operations**: Found in 11 files, no 500-op limit violations

### Stream Subscription Management
- `_disposed` flag: Properly implemented in 6 core providers
- `StreamSubscription` tracking: 13+ files properly manage subscriptions
- `_scheduleNotify()` debouncing: Implemented in core providers

### Cache Effectiveness
- 5-minute TTL with `Map<String, DateTime>` timestamps
- `StreamRequestManager` with `BehaviorSubject` reactive caching
- Generally well-implemented across providers

---

## Security Assessment

### Strengths
- No hardcoded API keys, secrets, or tokens in source
- All auth tokens managed via Firebase SDK
- JWT handled properly via `signInWithCustomToken`
- Comprehensive Firestore security rules (37KB)
- App Check enabled for iOS/Android production
- `AppLog.d()` redacts sensitive data automatically

### Gaps
- Server-side chat message length validation (see High Priority #1)
- Web App Check disabled (see High Priority #3)
- `FirebaseAuth.instance` used directly in 30+ files (acceptable for auth managers)

---

## Test Coverage Gaps

### Flutter
- **ChatService** (985 lines): No dedicated tests for the largest service
- **Large widget screens**: No widget tests for `games_list`, `game_joined_detailed`, etc.
- **Auth flows**: No integration tests
- **Widget tests**: Sparse overall
- Single integration test file: `integration_test/friend_notifications_test.dart`

### Cloud Functions
- Good coverage (28+ test files, including load tests)
- `confirmation_flow.test.js` is comprehensive (119KB)
- Load testing infrastructure operational

---

## Fragile Areas

### Reply-to Messages
- **File**: `lib/chat_group/game_chat_details/game_chat_details_widget.dart` (line 539)
- **Issue**: Reply-to message ID storage not fully implemented
- **Risk**: Partial feature, may cause confusion

### Chat Service Complexity
- 985 lines handling list/fetch/create/update/delete/reactions/typing
- High change risk — many features depend on it
- No dedicated test coverage

### Trust UI Screens
- `your_standing_screen.dart` (909 lines) and `trust_profile_section.dart` (809 lines)
- Both exceed 300-line limit significantly
- Trust is a sensitive, user-facing system

### Payment Integration Stubs
- Stripe, Razorpay, Braintree packages installed but not integrated
- Potential confusion about payment capabilities
- Should be removed if not planned for near-term use

---

## Summary

| Area | Status | Priority |
|------|--------|----------|
| Server-side chat validation | Gap | **High** |
| Unbounded notification query | Bug risk | **High** |
| Web App Check | Disabled | **High** |
| ChatService size/tests | 985 lines, no tests | **Medium** |
| File size violations | 7 files over 300 lines | **Medium** |
| Test coverage gaps | Multiple areas | **Medium** |
| Legacy schema records | Permanent, managed | **Low** |
| Color token violations | 40+ files, mostly mitigated | **Low** |
| StatCard migration | 14 files | **Low** |
| Caption token cleanup | ~15 files | **Low** |
