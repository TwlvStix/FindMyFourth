Widget Decomposition Plan: games_list_widget.dart

 Target File

 lib/main_function/games_list/games_list_widget.dart
 - Current: 1,245 lines
 - Target: ~400 lines
 - Existing components: 9 files in components/

 Current State

 Already extracted (9 components):
 - premium_game_card.dart - Individual game card
 - flexible_games_shelf.dart - Horizontal shelf
 - flexible_games_bottom_sheet.dart - All flexible games sheet
 - game_list_filter_bottom_sheet.dart - Filter dialog
 - flexible_game_compact_card.dart - Compact card
 - flexible_game_expanded_card.dart - Expanded card
 - flexible_game_info_accordion.dart - Accordion details
 - flexible_availability_summary.dart - Availability text
 - flexible_badge.dart - Badge component

 What remains in main widget (causing bloat):
 1. Helper functions for game canonicalization (~90 lines)
 2. Helper functions for game filtering/matching (~70 lines)
 3. Cancelled game visibility logic (~60 lines)
 4. AppBar with notification badge (~100 lines)
 5. Empty state section (~40 lines)
 6. Fixed games section header (~80 lines)
 7. Friends-only games section with header (~150 lines)

 ---
 Extraction Plan

 1. Create utils/ directory with helper functions

 File: lib/main_function/games_list/utils/game_canonicalization.dart (~80 lines)
 Extract from lines 295-382:
 - canonicalGameType(String rawValue) - Normalize game type strings
 - canonicalVibe(String rawValue) - Normalize vibe strings
 - canonicalStakes(String rawValue) - Normalize stakes strings
 - canonicalHandicap(String rawValue) - Normalize handicap strings
 - gameTypeForFilters(Game game) - Wrapper using canonicalGameType
 - vibeForFilters(Game game) - Wrapper using canonicalVibe
 - stakesForFilters(Game game) - Wrapper using canonicalStakes
 - handicapForFilters(Game game) - Wrapper using canonicalHandicap

 File: lib/main_function/games_list/utils/game_filtering.dart (~70 lines)
 Extract from lines 384-454:
 - isSameDay(DateTime a, DateTime b) - Date comparison helper
 - matchesDateRange(DateTime? gameDate, GameDateRange range) - Date filter logic
 - isPublicGame(Game game) - Check if game is public
 - isFriendsOnlyGame(Game game) - Check if game is friends-only
 - friendIdsFromRecord(UsersRecord? record) - Extract friend IDs as Set
 - isUserGame(Game game, DocumentReference? currentUserRef) - Check user participation
 - isJoinableGame(Game game, DocumentReference? currentUserRef, Set<String> friendIds) - Full eligibility check

 File: lib/main_function/games_list/utils/cancelled_game_handler.dart (~80 lines)
 Extract from lines 188-290:
 - CancelledGameHandling enum (keep here or in main file)
 - parseCancelledHandling(String? value) - Parse stored value
 - getCancelledHandling(Game game, Map cache, AppState appState) - Get handling with cache
 - shouldHideCancelledGame(Game game, Map cache, AppState appState) - Visibility logic
 - isCancelledGameExpired(Game game) - Check expiration by schedule type

 Note: GameFilterMeta class (lines 45-105) stays in main widget - it's a data class used only here.

 2. Extract remaining UI components

 File: lib/main_function/games_list/components/games_list_empty_state.dart (~50 lines)
 Extract from lines 960-998:
 - Empty state with icon, message, and CTA

 File: lib/main_function/games_list/components/fixed_games_section.dart (~100 lines)
 Extract from lines 1002-1079:
 - Section header with count badge
 - Game list rendering with PremiumGameCard

 File: lib/main_function/games_list/components/friends_only_games_section.dart (~150 lines)
 Extract from lines 1083-1231:
 - Header with show/hide toggle
 - Conditional game list
 - Empty state for friends-only

 3. Extract AppBar to reusable core widget

 File: lib/core/widgets/app_bar_with_badge.dart (~80 lines)
 Extract from lines 663-759:
 - Reusable AppBar with notification badge
 - StreamBuilder for unread count
 - Filter button slot

 ---
 Implementation Steps

 1. Create utils directory and extract helper functions
   - Create lib/main_function/games_list/utils/ directory
   - Create 3 utility files with extracted functions
   - Update imports in main widget
 2. Extract UI components to existing components directory
   - Create games_list_empty_state.dart
   - Create fixed_games_section.dart
   - Create friends_only_games_section.dart
   - Update imports in main widget
 3. Extract reusable AppBar to core widgets
   - Create lib/core/widgets/app_bar_with_badge.dart
   - Update import in main widget
 4. Clean up main widget
   - Remove extracted code
   - Verify line count is ~400
   - Run flutter analyze
 5. Test
   - Run flutter test
   - Manual smoke test of games list screen

 ---
 Expected Result

 Main widget: ~400 lines (down from 1,245)
 New files: 7 (3 utils + 3 components + 1 core widget)
 Total components: 12 (existing 9 + new 3)

 ---
 Verification

 # Check line count
 wc -l lib/main_function/games_list/games_list_widget.dart

 # Run analysis
 flutter analyze

 # Run tests
 flutter test

 ---
 Future Phases (After games_list_widget.dart)

 Phase 2: game_chat_details_widget.dart (1,611 → ~350 lines)

 Location: lib/chat_group/game_chat_details/
 Existing components: 4 files (chat_date_divider, chat_header_title, chat_input_bar, chat_message_bubble)

 Extract to components/:
 ┌─────────────────────────────────┬───────┬──────────────────────────────────────────────┐
 │            Component            │ Lines │                 Description                  │
 ├─────────────────────────────────┼───────┼──────────────────────────────────────────────┤
 │ chat_message_list.dart          │ ~180  │ ListView builder with grouping/divider logic │
 ├─────────────────────────────────┼───────┼──────────────────────────────────────────────┤
 │ chat_reaction_picker.dart       │ ~100  │ Emoji reaction bottom sheet                  │
 ├─────────────────────────────────┼───────┼──────────────────────────────────────────────┤
 │ chat_image_viewer.dart          │ ~80   │ Full-screen image dialog                     │
 ├─────────────────────────────────┼───────┼──────────────────────────────────────────────┤
 │ chat_pending_upload_bubble.dart │ ~50   │ Upload progress indicator                    │
 ├─────────────────────────────────┼───────┼──────────────────────────────────────────────┤
 │ chat_info_banner.dart           │ ~60   │ Read-only/archived/pinned banner             │
 ├─────────────────────────────────┼───────┼──────────────────────────────────────────────┤
 │ chat_typing_indicator.dart      │ ~80   │ "Someone is typing..." display               │
 ├─────────────────────────────────┼───────┼──────────────────────────────────────────────┤
 │ chat_scroll_fab.dart            │ ~50   │ Scroll-to-bottom FAB                         │
 └─────────────────────────────────┴───────┴──────────────────────────────────────────────┘
 Extract to controller:

 - chat_details_controller.dart (~150 lines): Message merging, pagination state, read receipts batching

 ---
 Phase 3: player_list_widget.dart (1,584 → ~300 lines) ⚠️ HIGH COMPLEXITY

 Location: lib/main_function/player_list/
 Existing components: None

 ⚠️ Extra Testing Required: This is the trickiest decomposition — 7 new components from scratch plus a controller. The search modal
  with 6 UI states (guest, min-char threshold, loading, no results, actual results, load-more) has many edge cases.

 Create components/ directory with:
 ┌────────────────────────────┬───────┬────────────────────────────────────────────────────────────────────────┐
 │         Component          │ Lines │                              Description                               │
 ├────────────────────────────┼───────┼────────────────────────────────────────────────────────────────────────┤
 │ add_player_modal.dart      │ ~180  │ Search modal with results                                              │
 ├────────────────────────────┼───────┼────────────────────────────────────────────────────────────────────────┤
 │ player_search_results.dart │ ~150  │ 6 UI states (guest, min-char, loading, no results, results, load-more) │
 ├────────────────────────────┼───────┼────────────────────────────────────────────────────────────────────────┤
 │ player_option_card.dart    │ ~140  │ Search result item with avatar/name/action                             │
 ├────────────────────────────┼───────┼────────────────────────────────────────────────────────────────────────┤
 │ player_slot_card.dart      │ ~180  │ Empty or filled player slot                                            │
 ├────────────────────────────┼───────┼────────────────────────────────────────────────────────────────────────┤
 │ current_user_card.dart     │ ~140  │ Game creator card                                                      │
 ├────────────────────────────┼───────┼────────────────────────────────────────────────────────────────────────┤
 │ game_summary_card.dart     │ ~70   │ Read-only game info                                                    │
 ├────────────────────────────┼───────┼────────────────────────────────────────────────────────────────────────┤
 │ player_submit_button.dart  │ ~200  │ Validation + submission (complex, keep larger)                         │
 └────────────────────────────┴───────┴────────────────────────────────────────────────────────────────────────┘
 Extract to controller:

 - player_list_controller.dart (~120 lines): Search state, token management, eligibility checks

 Extra Smoke Testing Checklist:

 - Search with <2 chars shows min-char message
 - Search with no results shows empty state
 - Guest option always appears at top
 - Load more pagination works
 - Gender eligibility filtering works
 - Duplicate player detection works
 - Token cancellation on rapid searches works

 ---
 Phase 4: profile_user_firebase_widget.dart (1,403 → ~350 lines)

 Location: lib/profile/profile_user/
 Existing components: 1 inline class (MutualFriendsSheet)

 Create components/ directory with:
 ┌─────────────────────────────────┬───────┬───────────────────────────────────────────┐
 │            Component            │ Lines │                Description                │
 ├─────────────────────────────────┼───────┼───────────────────────────────────────────┤
 │ profile_hero_section.dart       │ ~140  │ Avatar with rotating ring + name/metadata │
 ├─────────────────────────────────┼───────┼───────────────────────────────────────────┤
 │ profile_avatar_friend_fab.dart  │ ~110  │ Friend action FAB state machine           │
 ├─────────────────────────────────┼───────┼───────────────────────────────────────────┤
 │ profile_stats_section.dart      │ ~110  │ Handicap + vibe fit + home course         │
 ├─────────────────────────────────┼───────┼───────────────────────────────────────────┤
 │ profile_quick_actions_grid.dart │ ~80   │ Message + Mutual Friends row              │
 ├─────────────────────────────────┼───────┼───────────────────────────────────────────┤
 │ quick_action_card.dart          │ ~80   │ Reusable action card                      │
 ├─────────────────────────────────┼───────┼───────────────────────────────────────────┤
 │ mutual_friends_action_card.dart │ ~70   │ Mutual friends with avatars               │
 ├─────────────────────────────────┼───────┼───────────────────────────────────────────┤
 │ overlapping_avatars.dart        │ ~60   │ Stacked avatar display (reusable)         │
 ├─────────────────────────────────┼───────┼───────────────────────────────────────────┤
 │ golf_info_section.dart          │ ~60   │ Golf Canada #, email, phone               │
 ├─────────────────────────────────┼───────┼───────────────────────────────────────────┤
 │ mutual_friends_sheet.dart       │ ~180  │ Bottom sheet (extract from inline)        │
 └─────────────────────────────────┴───────┴───────────────────────────────────────────┘
 Extract to controller:

 - profile_user_controller.dart (~100 lines): Vibe matching, mutual friends fetching

 ---
 Phase 5: app_router.dart (865 → ~400 lines)

 Location: lib/core/navigation/

 Extract to separate files:
 ┌───────────────────────────┬───────┬──────────────────────────────────────┐
 │           File            │ Lines │             Description              │
 ├───────────────────────────┼───────┼──────────────────────────────────────┤
 │ route_definitions.dart    │ ~300  │ Route registry using builder pattern │
 ├───────────────────────────┼───────┼──────────────────────────────────────┤
 │ nav_bar_page_builder.dart │ ~50   │ Helper for NavBarPage wrapping       │
 ├───────────────────────────┼───────┼──────────────────────────────────────┤
 │ route_param_utils.dart    │ ~80   │ Parameter extraction utilities       │
 └───────────────────────────┴───────┴──────────────────────────────────────┘
 Keep in app_router.dart:

 - AppStateNotifier class (~60 lines)
 - createRouter() function calling route registry (~80 lines)
 - Transition logic (_buildPageWithTransition) (~60 lines)

 Future Consideration:

 route_definitions.dart at ~300 lines is acceptable for now. If routes keep growing, consider splitting by feature area:
 - routes/auth_routes.dart - SignIn, SignUp, RecoverPassword, Onboarding
 - routes/game_routes.dart - Games list, Create, Join, Joined, Confirmation flows
 - routes/profile_routes.dart - Main, Edit, Vibes, Trust
 - routes/social_routes.dart - Chat, Golfers, Friends, Notifications

 This is a future concern — current extraction is sufficient.

 ---
 Verification Plan

 After each phase:
 1. Run flutter analyze - ensure no new warnings
 2. Run flutter test - ensure no regressions
 3. Verify line counts: wc -l <file> for main widget, each component
 4. Manual smoke test of the screen functionality

 ---
 File Count Summary
 ┌───────┬──────────────────────────────┬──────────────┬────────────────┬─────────────────────────┐
 │ Phase │             File             │ Target Lines │ New Components │  New Utils/Controllers  │
 ├───────┼──────────────────────────────┼──────────────┼────────────────┼─────────────────────────┤
 │ 1     │ games_list_widget            │ ~400         │ 3              │ 3 utils + 1 core widget │
 ├───────┼──────────────────────────────┼──────────────┼────────────────┼─────────────────────────┤
 │ 2     │ game_chat_details_widget     │ ~350         │ 7              │ 1 controller            │
 ├───────┼──────────────────────────────┼──────────────┼────────────────┼─────────────────────────┤
 │ 3     │ player_list_widget ⚠️        │ ~300         │ 7              │ 1 controller            │
 ├───────┼──────────────────────────────┼──────────────┼────────────────┼─────────────────────────┤
 │ 4     │ profile_user_firebase_widget │ ~350         │ 9              │ 1 controller            │
 ├───────┼──────────────────────────────┼──────────────┼────────────────┼─────────────────────────┤
 │ 5     │ app_router                   │ ~400         │ 0              │ 3 utils                 │
 └───────┴──────────────────────────────┴──────────────┴────────────────┴─────────────────────────┘
 Total new files: 26 components + 10 utilities/controllers = 36 files
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌