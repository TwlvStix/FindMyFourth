God Widget Refactoring Plan

 Issue #6: God Widgets Mix UI, State, and Data/Service Orchestration

 Problem Summary

 4 widgets violate separation of concerns by mixing UI, state management, and direct Firestore/service calls:
 ┌──────────────────────────────────┬───────┬─────────────────────────────────────────────────────────────────┐
 │              Widget              │ Lines │                           Key Issues                            │
 ├──────────────────────────────────┼───────┼─────────────────────────────────────────────────────────────────┤
 │ game_joined_detailed_widget.dart │ 2,174 │ Vibe matching, pending requests, 300+ lines duplicate code      │
 ├──────────────────────────────────┼───────┼─────────────────────────────────────────────────────────────────┤
 │ join_game_detailed_widget.dart   │ 1,522 │ Identical vibe matching code (duplicate), join flow logic       │
 ├──────────────────────────────────┼───────┼─────────────────────────────────────────────────────────────────┤
 │ create_game_widget.dart          │ 2,164 │ 20+ form state vars, direct Firestore writes, draft persistence │
 ├──────────────────────────────────┼───────┼─────────────────────────────────────────────────────────────────┤
 │ main.dart                        │ 753   │ Auth orchestration, notification init, nav bar                  │
 └──────────────────────────────────┴───────┴─────────────────────────────────────────────────────────────────┘
 Critical finding: game_joined_detailed and join_game_detailed share 300+ lines of duplicate vibe matching code.

 ---
 Success Criteria (Primary KPIs)

 1. Zero direct FirebaseFirestore.instance calls in target widgets
 2. Reduced rebuild scope - no unnecessary setState() calls
 3. Test coverage for critical flows (join, joined, create)
 4. Bug rate - no regressions in existing behavior
 5. Line count reduction (secondary metric)

 ---
 Global Definition of Done (Per Phase)

 Each phase is complete when:
 - No direct FirebaseFirestore.instance in target widgets
 - flutter analyze clean
 - Characterization/behavior tests pass for affected flows
 - Logging and error handling preserved (AppLog.d patterns)
 - PR is small and reviewable (max 400-500 lines changed)

 ---
 Phase 0: Baseline Tests & Snapshots

 Status: ✅ COMPLETE (lightweight retrospective)

 Deliverables Completed

 1. Provider regression scaffolding:
   - test/providers/group_vibe_provider_test.dart - Expanded with invalidation coverage
   - invalidateCacheKey forces reload
   - invalidateGame clears only targeted game keys
 2. Summary interaction coverage:
   - test/widgets/group_vibe_summary_interaction_test.dart - Breakdown trigger path
 3. Screen wiring contract tests:
   - test/refactor_contracts/phase0_group_vibe_wiring_contract_test.dart
   - Verifies provider + summary + breakdown hookup in both screens
 4. Baseline snapshot doc:
   - docs/perf_baselines/phase0_lightweight_baseline_2026-02-28.md
   - LoC, builder/setState pressure proxies, targeted suite runtime

 Verification ✅

 - All Phase 0 tests pass
 - flutter analyze clean on new test files
 - Baseline metrics documented for before/after comparison

 ---
 Phase 1: Extract Shared Vibe Matching (Highest Impact)

 Status: ✅ COMPLETE

 Goal: Eliminate 300+ lines of duplicate code between the two detailed game widgets.

 PR Strategy: Split into 2-3 small PRs:
 - PR 1.1: Create GroupVibeProvider with tests
 - PR 1.2: Create GroupVibeBreakdownSheet component
 - PR 1.3: Wire up both widgets to use new provider/component

 Files to Create

 1. lib/providers/group_vibe_provider.dart
   - New provider wrapping VibeRepository + GroupVibeMatcher
   - Caches GroupVibeMatchResult by game key
   - Manages loading state and member match maps
   - Follows existing provider patterns (_disposed, _scheduleNotify)

 Cache Invalidation Triggers (not just TTL):
   - invalidateForGame(gameId) - called when roster changes
   - invalidateForPlayer(playerId) - called when player joins/leaves
   - invalidateOnRequestAction(gameId) - called on approve/reject
   - Auto-invalidate when underlying game document updates
 2. lib/core/widgets/vibe/group_vibe_breakdown_sheet.dart
   - Extracted from _openGroupVibeBreakdown() (120+ lines each widget)
   - Stateless bottom sheet taking GroupVibeMatchResult as input
   - Static show() method for easy invocation

 Files to Modify

 - lib/main.dart - Add GroupVibeProvider to MultiProvider
 - lib/providers/provider_extensions.dart - Add groupVibeProvider extension
 - lib/main_function/game_joined_detailed/game_joined_detailed_widget.dart - Replace inline vibe code with provider
 - lib/main_function/join_game_detailed/join_game_detailed_widget.dart - Replace inline vibe code with provider

 Code to Delete from Both Widgets

 // DELETE these duplicate methods/state from both widgets:
 final VibeRepository _vibeRepository = VibeRepository();
 GroupVibeMatchResult? _groupVibeMatch;
 Map<String, GroupVibeMemberResult> _memberMatchesById = {};
 bool _isGroupVibeLoading = false;
 String _groupVibeKey = '';

 _ensureGroupVibeMatch()
 _loadGroupVibeMatch()
 _groupMemberRefs()
 _openGroupVibeBreakdown()  // 120+ lines each
 _buildGroupMatchRow()
 _sortedMemberResults()
 _compareMemberIds()

 Verification ✅

 - flutter test passes for new tests
 - Group vibe loads correctly on both screens
 - Breakdown modal opens from both screens
 - No duplicate code remains (_loadGroupVibeMatch, _openGroupVibeBreakdown, etc. removed)
 - Provider registered in main.dart:84-85
 - Extension added to provider_extensions.dart:40

 ---
 Phase 2: Refactor game_joined_detailed_widget.dart

 Status: ✅ COMPLETE

 Goal: Move Firestore operations to providers, extract meaningful components.

 Deliverables Completed

 1. lib/main_function/game_joined_detailed/components/player_list_section.dart (391 lines)
   - Batch profile + trust data loading (no N+1 per-card futures)
   - Player cards with trust badges and vibe match chips
   - Guest player cards
   - Remove player callbacks for game owner
   - Staggered animations
   - Reusable: Ready for join_game_detailed
 2. lib/main_function/game_joined_detailed/components/pending_requests_section.dart (262 lines)
   - Batch requester profile + vibe profile loading
   - Accordion-style expand/collapse
   - Vibe match calculation against owner
   - Approve/decline callbacks
 3. lib/backend/api_requests/game_service.dart
   - Added removePlayer() method with strict input validation
   - Throws GameOperationException(code: 'invalid-argument') on invalid args
 4. lib/providers/game_provider.dart
   - Added removePlayer() method with cache invalidation
   - Updated leaveGame() to accept optional chatId for chat removal
 5. Contract test updated
   - test/refactor_contracts/phase0_group_vibe_wiring_contract_test.dart
   - Now verifies PlayerListSection uses provider for sorting

 Metrics
 ┌────────────────────────┬──────────┬───────┐
 │         Metric         │  Before  │ After │
 ├────────────────────────┼──────────┼───────┤
 │ Widget line count      │ 2,174    │ 1,491 │
 ├────────────────────────┼──────────┼───────┤
 │ Direct Firestore calls │ Multiple │ 0     │
 ├────────────────────────┼──────────┼───────┤
 │ N+1 FutureBuilders     │ Per-card │ Batch │
 └────────────────────────┴──────────┴───────┘
 Verification ✅

 - flutter analyze clean (no errors)
 - Contract tests pass
 - Widget uses providers for all mutations
 - Extracted components use batch data loading

 ---
 Phase 3: Refactor join_game_detailed_widget.dart

 Status: ✅ 

 Goal: Reduce from 1,512 to ~900 lines by reusing Phase 2 components and extracting shared utilities.

 Current Analysis (from exploration):
 - Widget is 1,512 lines
 - Already uses providers correctly for join flow (GameProvider.joinGame())
 - Has inline player list rendering (lines 701-1006) that duplicates PlayerListSection
 - Has identical utility methods (_buildAnimatedSection, _getPlayerCount)
 - Only 3 minor direct Firestore reads (owner reference checks)

 PR Strategy: 2 small PRs

 PR 3.1: Reuse PlayerListSection
 - Replace inline player rendering (lines 701-1006) with PlayerListSection component
 - Import from ../game_joined_detailed/components/player_list_section.dart
 - Pass isOwner: false (viewer is not owner in join view)
 - Pass onRemovePlayer: null (no remove capability in join view)

 PR 3.2: Extract shared utilities
 - Extract _buildAnimatedSection() to shared utility
 - Extract _getPlayerCount() to Game model extension

 Files to Modify

 1. lib/main_function/join_game_detailed/join_game_detailed_widget.dart
   - Replace inline player list (lines 701-1006) with PlayerListSection
   - Remove duplicate _buildAnimatedSection() method
   - Remove duplicate _getPlayerCount() method
   - Use shared utilities instead
 2. lib/models/game.dart (optional utility extraction)
   - Add playerCount getter to Game model
   - Consolidates _getPlayerCount() logic
 3. lib/core/motion/animation_helpers.dart (optional utility extraction)
   - Extract buildAnimatedSection() as reusable function
   - Takes child, hasAnimated, delay parameters

 Code to Delete from Widget

 // DELETE these sections (replaced by PlayerListSection):
 // Lines 701-1006: Inline player rendering with guest cards

 // DELETE these duplicate methods (use shared utilities):
 _buildAnimatedSection()  // Lines 1493-1510
 _getPlayerCount()        // Lines 184-193

 Code Changes Summary
 ┌─────────────────────────┬───────────────────────┬────────────────────────────────┐
 │         Section         │         Lines         │             Action             │
 ├─────────────────────────┼───────────────────────┼────────────────────────────────┤
 │ Inline player rendering │ 701-1006 (~300 lines) │ Replace with PlayerListSection │
 ├─────────────────────────┼───────────────────────┼────────────────────────────────┤
 │ _buildAnimatedSection() │ 1493-1510             │ Delete, use shared utility     │
 ├─────────────────────────┼───────────────────────┼────────────────────────────────┤
 │ _getPlayerCount()       │ 184-193               │ Delete, use Game model getter  │
 ├─────────────────────────┼───────────────────────┼────────────────────────────────┤
 │ Estimated reduction     │ ~320 lines            │                                │
 └─────────────────────────┴───────────────────────┴────────────────────────────────┘
 Verification Checklist

 - Widget line count < 1,200 (target ~900)
 - Uses PlayerListSection instead of inline rendering
 - Join flow works (both instant and approval-required)
 - Existing request checking still works
 - Vibe floor modal still shows correctly
 - flutter analyze clean
 - Contract tests pass

 ---
 Phase 4: Refactor create_game_widget.dart
 
 Status: NEXT

 Goal: Extract Firestore operations and form data model; keep form state local.

 PR Strategy: 3 small PRs:
 - PR 4.1: Create CreateGameFormData model + CreateGameService
 - PR 4.2: Create CreateGameDraftService + validators
 - PR 4.3: Wire up widget to use services (form state stays local)

 Consolidation Guidance (avoid over-fragmentation):
 - Form state (20+ vars) stays local to widget - it's ephemeral, not global app state
 - UI sections already have components (section_header, card_grid, etc.) - don't re-extract
 - Focus on extracting services (Firestore writes, draft persistence)
 - schedule_section and game_style_section are optional - only extract if >150 lines each

 Files to Create

 1. lib/main_function/create_game/create_game_form_data.dart
   - Data class for all 20+ form fields
   - toDraft() / fromDraft() for persistence
   - toFirestore() for game creation
   - Single source of truth for form shape
 2. lib/services/create_game_service.dart
   - createGame(CreateGameFormData) - Firestore write
   - Moves raw gamesRecordReference.set() out of widget
   - Follows existing service patterns (FirebaseFirestore DI)
 3. lib/services/create_game_draft_service.dart
   - loadDraft() / saveDraft() / clearDraft()
   - SharedPreferences-based persistence
 4. lib/main_function/create_game/create_game_validators.dart
   - Static validation methods
   - isFormComplete() check

 Verification

 - Widget line count < 1000
 - Draft save/load works
 - Game creation succeeds with all field combinations
 - No direct Firestore calls in widget

 ---
 Phase 5: Clean Up main.dart

 Goal: Extract notification orchestration with clear lifecycle semantics.

 PR Strategy: 2 small PRs:
 - PR 5.1: Extract NotificationOrchestrationService with lifecycle tests
 - PR 5.2: Extract NavBarPage to separate file

 Files to Create

 1. lib/services/notification_orchestration_service.dart
   - Extracts notification init from _userStreamSub callback

 Lifecycle Semantics:
   - initialize(String uid) - starts notification services for user
   - shutdown() - cleans up on logout
   - onUserChanged(String newUid) - handles account switch
   - UID-change idempotency: Guards against stale callbacks binding to wrong user
   - Startup/shutdown symmetry: Every init has matching cleanup

 Tests Required:
   - test/services/notification_orchestration_test.dart
   - Covers: init, shutdown, user switch, rapid login/logout
 2. lib/core/navigation/nav_bar_page.dart
   - Move NavBarPage class (~175 lines)
   - Simple extraction, no logic changes

 Verification

 - main.dart line count < 450
 - App starts correctly
 - Auth flow works (login, logout, account switch)
 - Notifications register correctly on login
 - Notifications unregister on logout
 - No stale UID binding after account switch
 - Bottom navigation works

 ---
 Execution Order & Dependencies

 Phase 0 ✅ COMPLETE (lightweight retrospective)
     ↓
 Phase 1 ✅ COMPLETE
     ↓
 Phase 2 ✅ COMPLETE
     ↓
 Phase 3 ✅ Complete
     ↓
 Phase 4 (independent, can run parallel, 3 PRs)
     ↓
 Phase 5 (independent, lowest priority, 2 PRs)

 Current state: Phases 0-2 complete. Ready for Phase 3.

 Recommended next step: Phase 3 (refactor join_game_detailed_widget.dart to reuse PlayerListSection)

 ---
 Summary
 ┌───────┬──────────────────────────────┬─────┬─────────────────────────────┬─────────────┐
 │ Phase │         Primary KPI          │ PRs │          New Files          │   Status    │
 ├───────┼──────────────────────────────┼─────┼─────────────────────────────┼─────────────┤
 │ 0     │ Test coverage baseline       │ 1   │ 4 test files + baseline doc │ ✅ COMPLETE │
 ├───────┼──────────────────────────────┼─────┼─────────────────────────────┼─────────────┤
 │ 1     │ Zero duplicate vibe code     │ 2-3 │ 2                           │ ✅ COMPLETE │
 ├───────┼──────────────────────────────┼─────┼─────────────────────────────┼─────────────┤
 │ 2     │ Zero Firestore in widget     │ 2-3 │ 2                           │ ✅ COMPLETE │
 ├───────┼──────────────────────────────┼─────┼─────────────────────────────┼─────────────┤
 │ 3     │ Reuses Phase 1-2 extractions │ 2   │ 0-2 (utilities)             │ ✅ COMPLETE │
 ├───────┼──────────────────────────────┼─────┼─────────────────────────────┼─────────────┤
 │ 4     │ Zero Firestore in widget     │ 3   │ 4                           │ 🔄 NEXT    │
 ├───────┼──────────────────────────────┼─────┼─────────────────────────────┼─────────────┤
 │ 5     │ Clear lifecycle semantics    │ 2   │ 2                           │ Pending     │
 └───────┴──────────────────────────────┴─────┴─────────────────────────────┴─────────────┘
 ---
 Critical Files Reference

 - Pattern to follow: lib/providers/game_provider.dart
 - Vibe algorithm: lib/services/vibe_group_matcher.dart
 - Reusable component: lib/main_function/game_joined_detailed/components/player_list_section.dart
 - Target widget: lib/main_function/join_game_detailed/join_game_detailed_widget.dart (1,512 lines)
