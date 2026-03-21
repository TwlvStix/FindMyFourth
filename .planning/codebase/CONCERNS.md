# Codebase Concerns

**Analysis Date:** 2026-03-19

## Tech Debt

**Widget Size Violations - Legacy Component Decomposition Debt:**
- Issue: Multiple screen-level widgets exceed the 300-line limit, creating tight coupling between concerns and making changes risky
- Files affected:
  - `lib/main_function/games_list/games_list_widget.dart` (731 lines) — game listing, filtering, caching, mutual friend logic all in one file
  - `lib/chat_group/game_chat_details/game_chat_details_widget.dart` (727 lines) — chat rendering, message handling, reactions, image uploads mixed together
  - `lib/services/chat_service.dart` (985 lines) — chat CRUD, message queries, user cache, batch composition all in single service
  - `lib/user_auth/sign_up_account/sign_up_account_widget.dart` (801 lines) — auth, form validation, provider registration in one widget
  - `lib/screens/trust/your_standing_screen.dart` (909 lines) — trust display, filtering, section rendering mixed
  - `lib/providers/notification_list_provider.dart` (707 lines) — notification caching, filtering, stream management without sub-domain split
  - `lib/core/design_patterns/premium_ui_patterns.dart` (840 lines) — 14+ premium components in single file creating tight cohesion
- Impact: High risk of regression when modifying, difficult code review, increased cognitive load, harder to test individual features
- Fix approach: Extract logical sub-components to `components/` subfolders; split large service classes by domain (e.g., separate user cache logic from message composition); consider ViewModelManager pattern (see `ChatProvider` → `ChatViewModelManager`)

**Dual Data Representation Layer:**
- Issue: App maintains both `*Record` classes (Firestore schema layer) and `*Model` classes (domain layer) — conversion happens ad-hoc, increasing duplication risk
- Files:
  - `lib/backend/schema/users_record.dart`, `lib/backend/schema/games_record.dart` (deeply embedded — 29+ and 13+ file dependencies)
  - `lib/models/game.dart`, `lib/models/vibe_profile.dart`, `lib/models/chat.dart` (standalone domain models)
- Impact: Business logic (e.g., `Game.resolveGameStatus()`) must exist in both layers to stay in sync; changing schema requires updates in multiple places; unclear which layer is source-of-truth
- Fix approach: Consolidate on domain models for UI consumption; keep `*Record` for schema definition only; enforce conversion at service layer boundaries; add automated tests to catch divergence

**Incomplete Reply-To Chat Feature:**
- Issue: Message reply support is stubbed but not fully implemented
- Location: `lib/chat_group/game_chat_details/game_chat_details_widget.dart:539` contains TODO: "In a full implementation, we would store the replyTo message ID"
- Impact: Reply-to messages render but don't persist to Firestore; users may create/edit replies that don't save; chat context is lost on reload
- Fix approach: Implement `replyToId` field in `ChatMessage` model; update `ChatService.sendMessage()` to accept optional `replyToId`; add UI affordance to display parent message context; add tests for reply persistence

**Legacy AppTheme Bridge Still in Use:**
- Issue: `AppTheme` is a legacy-era adapter still referenced by some widgets; maintains parallel mapping to `AppColors` tokens
- Location: `lib/core/app_theme.dart` (ThemeExtension); no active usage found, but bridge exists
- Impact: Creates two sources-of-truth for design; users may reference outdated `AppTheme.of(context)` in new code; cleanup blocked by unknown dependencies
- Fix approach: Audit and remove all remaining `AppTheme.of(context)` references; remove bridge entirely; update CI lint to forbid new `AppTheme` usage

**Deprecated SVG Icon System Not Fully Migrated:**
- Issue: `AppIcons` (SVG-based) marked deprecated in favor of `AppPhosphorIcons` (Phosphor), but migration incomplete
- Location: `lib/core/design_tokens/app_phosphor_icons.dart` includes legacy SVG fallbacks
- Impact: Asset bloat; inconsistent icon rendering across app; harder to maintain design system consistency
- Fix approach: Complete migration to Phosphor only; remove SVG assets; add lint rule to catch `AppIcons` usage

**Deprecated Caption Typography Token Still in Use:**
- Issue: `caption` token marked deprecated; ~10 files still use it instead of `labelSmall` or `labelMicro`
- Location: `lib/core/design_tokens/typography.dart:422-426` (marked @Deprecated)
- Impact: Text hierarchy inconsistency; future cleanup will require touching multiple files
- Fix approach: Audit all usages; replace with `labelSmall.copyWith(fontSize: 10)` or `labelMicro`; add lint to forbid `caption`

**Deprecated StatCard Components:**
- Issue: `StatCard` in `premium_ui_patterns.dart` and `app_card.dart` marked deprecated; `AppStatCard` is the replacement, but old variant still exists
- Location: `lib/core/design_patterns/premium_ui_patterns.dart:341` and `lib/core/widgets/app_card.dart:422`
- Impact: Duplicate component; users may choose wrong variant; harder to maintain consistent stat card styling
- Fix approach: Audit and replace all `StatCard` usages with `AppStatCard`; remove deprecated classes

**Hardcoded Font Sizes in Intentional Locations:**
- Issue: Some files use hardcoded `fontSize` values for legitimate reasons (screenshot export, onboarding animations), but they're scattered and documented differently
- Files: `archetype_share_card.dart` (intentional), `cinematic_*.dart` (onboarding), `cancellation_warning_modal.dart` (trust), `chat_reaction_picker.dart` (emoji), `main.dart:476` (debug)
- Impact: Hard to distinguish intentional from accidental hardcoding; future refactors may over-correct; inconsistent documentation
- Fix approach: Create `lib/core/design_tokens/intentional_hardcoded_sizes.dart` with documented exceptions; link from token definitions; CI allowlist updates

## Known Bugs

**Chat Message Emoji Reaction Display Issue (Potential Race Condition):**
- Symptoms: Emoji reaction counts may appear out of sync when multiple users react simultaneously; reactions from other users sometimes don't appear until next message
- Location: `lib/chat_group/game_chat_details/components/chat_bubble_reactions.dart` (new file, untested)
- Trigger: Multiple rapid reactions on same message from different clients within same millisecond window
- Root cause: Reaction updates via Firestore listener may not coalesce properly; transaction handling in cloud functions not guaranteeing order
- Workaround: Refresh chat list manually (pull-to-refresh)
- Fix approach: Add transaction-level consistency checks in `FirestoreService.recordReaction()`; add integration test for concurrent reactions

**Chat Image Attachment Upload Not Validated:**
- Symptoms: Large image uploads may timeout or fail silently; user is left unsure if image was sent
- Location: `lib/chat_group/game_chat_details/components/chat_bubble_image_attachment.dart` (new file, untested) + `ChatImageUploadController`
- Trigger: Images >5MB on slow networks; poor connectivity during upload
- Root cause: No file size pre-validation; upload progress feedback not implemented; error state unclear
- Workaround: Retry upload manually
- Fix approach: Validate file size before upload (max 5MB); add progress indicator; surface error messages clearly; add tests for upload failures

**Mutual Friends Detection May Miss Recently-Accepted Requests:**
- Symptoms: Friend list shows "Friend" but mutual games list doesn't include them; inconsistency in mutual detection
- Location: `lib/main_function/games_list/managers/mutual_friends_manager.dart` + `UserProvider.getMutualFriends()`
- Trigger: Accept friend request, immediately load games list
- Root cause: Caching in `UserProvider` (5-minute TTL) may not invalidate after friend accept; stream updates may lag
- Workaround: Wait 5 minutes or refresh manually
- Fix approach: Invalidate mutual friends cache immediately after friend accept in `UserProvider`; add cache invalidation hook to friend mutation flow

## Security Considerations

**Cloud Function Authorization Checks Incomplete:**
- Risk: Some Cloud Functions lack explicit user ownership verification before mutations
- Files: `firebase/functions/confirmation_flow.js`, `firebase/functions/trust_system.js`
- Current mitigation: Firestore rules enforce some restrictions; Cloud Functions rely on SDK Auth token validation
- Recommendations:
  - Add explicit `if (uid !== data.userId) throw new Error('Unauthorized')` checks in all write functions
  - Audit all `admin.firestore()` calls for direct collection access without security checks
  - Add integration tests that attempt unauthorized mutations

**Chat Message Sanitization Incomplete:**
- Risk: Chat messages are trimmed but not validated for malicious content (XSS, excessive length in URLs)
- Location: `lib/core/utils/input_sanitizer.dart` (trims and truncates, but no XSS check)
- Current mitigation: Max 2000 character limit; Flutter renders as plain text (no HTML parsing)
- Recommendations:
  - Scan chat messages for suspicious patterns (repeated special chars, long URLs)
  - Add server-side validation in Cloud Function before storing
  - Consider rate-limiting per user to prevent spam

**Firebase App Check Not Enabled:**
- Risk: Anyone with reverse-engineered Firebase config can call backend services
- Location: `lib/backend/firebase/firebase_config.dart:80` contains TODO about web App Check setup
- Current mitigation: Firestore rules provide some protection; limited attack surface on web
- Recommendations:
  - Implement App Check for iOS and Android (already configured for app; web pending)
  - Add enforcement in Firestore rules: `resource.app.check.token.verified == true`
  - Test with custom token bypass to verify enforcement

**Notification Preferences Not Validated on Cloud Function Side:**
- Risk: Users may manually modify notification preference documents in Firestore; Cloud Functions don't re-validate
- Location: `firebase/functions/game_alerts.js` reads from `alertSubs` without validation
- Impact: Malformed preferences could trigger unintended notifications or cause function errors
- Recommendations:
  - Add schema validation in Cloud Function before processing alert subscriptions
  - Enforce quiet hours and opt-out via validated rules, not just client logic

## Performance Bottlenecks

**Games List Loading Multiple Streams in Parallel:**
- Problem: `GamesListWidget` loads games stream + vibe scores + mutual friends + profile warming all concurrently
- Files: `lib/main_function/games_list/games_list_widget.dart` (line 40+) manages 4+ overlapping stream subscriptions
- Cause: No request batching; profile warmer performs sequential fetches instead of batch-fetching all at once
- Impact: High memory usage on large game lists; potential OOM on low-end devices; Firestore quota exhaustion
- Improvement path: Batch profile fetches to chunks of 20; lazy-load vibe scores (compute on-demand for visible items only); implement pagination with 20-item windows instead of loading all games

**Chat Service User Cache Not Bounded:**
- Problem: `ChatService._userCache` grows unbounded as users chat with more people; no eviction policy
- Files: `lib/services/chat_service.dart:19` (Map<String, dynamic> with no size limit)
- Impact: Memory leak over app lifetime; especially bad for power users with 100+ chats
- Improvement path: Implement LRU cache with max 100 entries; add cache.clear() on logout; add memory profiling test

**Vibe Matching Algorithm O(N²) on Group Size:**
- Problem: `VibeGroupMatcher` computes all pairwise compatibility scores when filtering groups
- Files: `lib/services/vibe_group_matcher.dart`
- Impact: Slow filtering when game has 20+ candidates; laggy UI during vibe filter application
- Improvement path: Pre-compute compatibility matrix once; use cached results; implement early termination if match score drops below threshold

**Firestore Query Batching Missing Optimization:**
- Problem: `ChatService.getChatListStream()` batches 10 chats per query, but creates N/10 listeners that each re-emit on every change
- Files: `lib/services/chat_service.dart:45-73` (batched but not optimized)
- Impact: Excessive listener churn on large chat lists; every message from any chat re-triggers all batch listeners
- Improvement path: Replace with single listener on `users/{uid}/chatRefs` metadata; fetch full chat data on-demand per displayed item; use pagination

## Fragile Areas

**Game Status Resolution Logic Duplicated Across Layers:**
- Files: `lib/models/game.dart` + `lib/backend/schema/games_record.dart` (both compute active/expired/cancelled)
- Why fragile: Changes to expiry logic must be updated in two places; divergence risk is high; hard to test
- Safe modification: Add integration test that verifies `Game.fromRecord()` and `Game.fromDoc()` produce identical status; refactor to single shared method
- Test coverage: `test/models/game_test.dart` exists but doesn't verify both code paths

**Provider Mutation Side Effects Not Atomic:**
- Files: All providers (e.g., `GameProvider.joinGame()`, `UserProvider.addFriend()`) — mutation → service write → cache invalidation
- Why fragile: If cache invalidation fails, stale data serves next query; if listener hasn't fired yet, UI shows old data
- Safe modification: Wrap mutation flow in try-catch; explicitly reset all related caches; add debug logging for cache state
- Test coverage: Mock test coverage exists but no end-to-end tests verifying cache consistency after write

**Stream Subscription Cleanup Pattern Inconsistent Across Providers:**
- Files:
  - `GameProvider` has `_disposed` flag + cancel `_notifyTimer` — safe
  - `ChatProvider` delegates stream management to `ChatViewModelManager` — safe
  - `NotificationListProvider` checks `_disposed` before notifying — safe
  - Some older providers may miss cleanup in edge cases
- Why fragile: If a provider is disposed before stream completes, listener memory leaks; `notifyListeners()` after dispose causes exceptions
- Safe modification: Ensure ALL providers follow the pattern: (1) set `_disposed = true` first, (2) cancel all subscriptions, (3) close all controllers, (4) cancel timers. Add unit test that calls dispose() and verifies no further notifyListeners calls
- Test coverage: No comprehensive test of all providers' dispose methods

**Mutual Friends Cache Invalidation Timing:**
- Files: `UserProvider.getMutualFriends()` + `GamesListWidget._mutualFriendsManager`
- Why fragile: Cache TTL is 5 minutes; accepting a friend request doesn't invalidate immediately; user sees inconsistent data
- Safe modification: Add explicit cache invalidation hook to friend mutation completion; trigger from friend request accept handler
- Test coverage: No test of cache timing after accept

**AppState Singleton Access in Production Code:**
- Files: `lib/main_function/games_list/utils/cancelled_game_handler.dart:47` uses `AppState()` directly instead of Provider
- Why fragile: Singleton pattern bypasses Provider dependency injection; makes testing difficult; state changes don't trigger listener notifications
- Safe modification: Replace with `context.read<AppState>()` or pass AppState via constructor; add lint rule to forbid `AppState()` constructor outside of main.dart
- Test coverage: Mock-unfriendly; tests cannot inject fake AppState

## Scaling Limits

**Firestore Listener Saturation on High-Activity Games:**
- Current capacity: Single game with 50+ participants
- Limit: Firestore has per-listener throughput limits; each game participant listener adds load; high message volume degrades real-time latency
- Scaling path: Implement pagination in `GameChatDetailsWidget` (fetch last 50 messages, load older on scroll); use message cursors instead of time-based ordering; consider message batching in Cloud Functions

**Cloud Functions Concurrent Execution Limits:**
- Current capacity: Project default is 1000 concurrent executions
- Limit: Heavy load during game creation (notifications) or confirmation flow (20+ participants) may exceed limit
- Scaling path: Add retries with exponential backoff in client; implement Cloud Tasks queue for non-urgent notifications; increase concurrency quota

**Player Search Autocomplete Latency:**
- Current capacity: Search across 10,000 users with reasonable latency (< 200ms)
- Limit: Linear search without indexes; scales poorly beyond 50k users
- Scaling path: Add composite Firestore indexes for (displayName, uid); implement search term tokenization; consider Algolia or similar for full-text search

## Dependencies at Risk

**Deprecated `sign_in_with_apple` Package:**
- Risk: Package marked as non-null-safe in some versions; Apple may deprecate APIs
- Current version: 7.0.1 (last update Jan 2024, potential maintenance lag)
- Impact: Critical for iOS auth; breaking changes could block releases
- Migration plan: Monitor package releases; prepare to switch to `flutter_appauth` if needed; add test for Apple sign-in flow monthly

**Long-Running `cloud_firestore` Major Version Lag:**
- Risk: Currently on 6.1.1; newer versions (7+) are available with breaking changes
- Impact: Security patches may be back-ported; new Firestore features unavailable
- Migration plan: Audit breaking changes in v7; plan migration for next major app version; check compatibility with other Firebase packages first

**`firebase_messaging` Notification Delivery Uncertainty:**
- Risk: FCM delivery not guaranteed; quiet hours and notification suppression may cause user confusion
- Current capability: Delivers via Cloud Functions + Cloud Tasks; quiet hours enforced client-side only
- Impact: Users may miss critical game notifications
- Mitigation: Implement fallback polling mechanism; add visual indicator in app when notifications are quieted

## Missing Critical Features

**E2E Tests for Vibe Matching Flow:**
- Problem: Vibe scoring algorithm is complex; no end-to-end test verifies match quality
- Blocks: Confidence in vibe system; hard to validate algorithm tuning
- Test coverage: Unit tests exist (see `test/vibe_scoring_test.dart`), but no end-to-end test that creates two users, sets vibes, and verifies match score
- Priority: High — vibe matching is core product; bugs affect UX

**Integration Tests for Friend Request State Machine:**
- Problem: Friend request flow has multiple states (pending, accepted, rejected, cancelled); state transitions not comprehensively tested
- Blocks: Confidence in friend operations; regressions go undetected
- Test coverage: Manual testing only; no automated test for full state machine
- Priority: High — friend requests are critical social feature

**Load Testing for Notification Delivery at Scale:**
- Problem: Game alert system not tested under realistic load (100+ concurrent new game notifications)
- Blocks: Confidence in notification delivery; unknown failure mode at scale
- Test coverage: Unit tests exist; no load test
- Priority: Medium — catch scaling issues early

**Concurrent Reaction Handling Integration Test:**
- Problem: New reaction features not tested for race conditions under concurrent usage
- Blocks: Confidence in reaction consistency; may have lost reactions or duplicate counts
- Test coverage: No test; unit tests only
- Priority: Medium

## Test Coverage Gaps

**Chat Image Attachment Upload Path Untested:**
- What's not tested: Happy path upload, timeout handling, cancellation, image validation
- Files: `lib/chat_group/game_chat_details/components/chat_bubble_image_attachment.dart` + `ChatImageUploadController`
- Risk: Users may not realize upload failed; no visibility into errors
- Gap: 0% coverage (new feature)
- Recommendation: Add integration test for image upload with mocked Cloud Storage; test timeout and error scenarios

**Emoji Reaction Concurrency Not Tested:**
- What's not tested: Two users reacting to same message at same time; reaction count consistency
- Files: `lib/chat_group/game_chat_details/components/chat_bubble_reactions.dart` + Cloud Functions reaction handler
- Risk: Lost reactions, duplicate counts, inconsistent state across clients
- Gap: New feature, no tests
- Recommendation: Add integration test with two simultaneous reactions; verify final count matches

**Notification Quiet Hours Edge Cases:**
- What's not tested: Quiet hours boundary (11pm → 8am transition); time zone handling; DST transitions
- Files: `firebase/functions/game_alerts.js:51-80` (timezone calculation), `lib/notification_settings` (quiet hours UI)
- Risk: Notifications sent during quiet hours; users woken at night
- Gap: No test of timezone-aware quiet hours calculation
- Recommendation: Add test cases for DST transitions and timezone boundaries

**Player Search Results Accuracy:**
- What's not tested: Search result ranking; relevance of results when multiple users share names
- Files: `lib/services/player_search_service.dart`
- Risk: User finds wrong player; hard to search for common names
- Gap: No test of ranking algorithm
- Recommendation: Add test cases for common name collisions; verify alphabetical ordering

**Vibe Dealbreaker Logic Edge Cases:**
- What's not tested: Asymmetric dealbreakers (A has dealbreaker on B, but not vice versa); edge case scoring
- Files: `lib/services/vibe_matcher.dart`, `test/vibe_scoring_test.dart`
- Risk: Incorrect match filtering; dealbreaker conflicts missed
- Gap: Test coverage partial; some asymmetric cases may be untested
- Recommendation: Audit test cases in `vibe_scoring_test.dart`; add asymmetric dealbreaker scenarios

**Game Status Transitions Under Concurrent Modifications:**
- What's not tested: Game transitions from active → cancelled → completed while user is viewing
- Files: `lib/models/game.dart` (status resolution), `GameProvider.watchGame()`
- Risk: Stale status displayed; state confusion
- Gap: No test of concurrent game state changes
- Recommendation: Add integration test that modifies game status while widget watches it

---

*Concerns audit: 2026-03-19*
