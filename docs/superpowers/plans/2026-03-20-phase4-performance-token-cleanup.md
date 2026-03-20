# Phase 4: Performance + Token Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate raw design literals, unnecessary widget rebuilds, and suboptimal layout patterns across the core flow screens identified in the UX audit.

**Architecture:** Six targeted fixes across existing files. Part A addresses three performance issues (empty setState calls, eager list building, IntrinsicHeight double-pass). Part B addresses three design token compliance issues (hardcoded icon size, raw Colors.white, raw PhosphorIcon calls). No new files created; all changes are in-place edits.

**Tech Stack:** Flutter, Dart, design tokens from `lib/core/design_tokens/`

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `lib/main_function/games_joined/games_joined_widget.dart` | Modify | Remove unnecessary `updateState` rebuilds |
| `lib/main_function/game_joined_detailed/components/game_joined_dashboard_content.dart` | Modify | Convert to `CustomScrollView` + slivers |
| `lib/screens/confirmation/host_checkin_screen.dart` | Modify | Replace `IntrinsicHeight` with `CustomScrollView` + `SliverFillRemaining` |
| `lib/main_function/games_list/components/unified_game_card.dart` | Modify | Replace hardcoded icon size with token |
| `lib/main_function/game_joined_detailed/components/game_joined_state_handler.dart` | Modify | Replace `Colors.white` with `AppColors.pure` + opacity token |
| `lib/screens/confirmation/components/checkin_status_view.dart` | Modify | Replace `PhosphorIcon` with `AppIcon` |
| `lib/screens/confirmation/components/peer_rating_header.dart` | Modify | Replace `PhosphorIcon` with `AppIcon` |
| `lib/screens/confirmation/components/peer_rating_status_views.dart` | Modify | Replace `PhosphorIcon` with `AppIcon` |
| `lib/screens/confirmation/components/fallback_header.dart` | Modify | Replace `PhosphorIcon` with `AppIcon` |
| `lib/screens/confirmation/components/fallback_status_view.dart` | Modify | Replace `PhosphorIcon` with `AppIcon` |
| `lib/screens/confirmation/peer_rating_screen.dart` | Modify | Replace back button `PhosphorIcon` with `AppIcon` |
| `lib/screens/confirmation/fallback_confirmation_screen.dart` | Modify | Replace back button `PhosphorIcon` with `AppIcon` |

---

## Part A -- Performance

### Task 1: Remove unnecessary updateState calls in games_joined_widget.dart

**Context:** `games_joined_widget.dart` uses `AppStreamBuilder` wrapping `GameProvider.userGamesStream()`, which is a live Firestore snapshot listener via `StreamRequestManager` + `BehaviorSubject`. The stream auto-delivers fresh data without manual rebuild triggers. Two `updateState(this, () {})` calls force full widget rebuilds with empty callbacks.

**Files:**
- Modify: `lib/main_function/games_joined/games_joined_widget.dart:106,173-179`

- [ ] **Step 1: Remove the updateState from onRefresh (line 178)**

The `RefreshIndicator.onRefresh` callback currently calls `invalidateUserGamesCache` then `updateState(this, () {})`. The cache invalidation clears the local query result cache. The live Firestore snapshot stream continues delivering current data to the `StreamBuilder` without needing a widget rebuild. Remove the `updateState` call.

Change lines 173-179 from:
```dart
onRefresh: () async {
  context
      .read<GameProvider>()
      .invalidateUserGamesCache(currentUserUid);
  if (mounted) {
    updateState(this, () {});
  }
},
```

To:
```dart
onRefresh: () async {
  context
      .read<GameProvider>()
      .invalidateUserGamesCache(currentUserUid);
},
```

- [ ] **Step 2: Replace the updateState in onRetry (line 106) with stream reset + rebuild**

The `onRetry` callback fires when the stream errors and the user taps "Retry". Recovery from a stream error requires two things: (a) clearing the `StreamRequestManager`'s cached `BehaviorSubject` so the errored subject isn't replayed, and (b) rebuilding so `StreamBuilder` subscribes to a fresh stream.

`invalidateUserGamesCache` only clears the local `_queryResultCache` -- it does NOT clear the `StreamRequestManager`'s internal `_streamSubjects` map. To clear the stream manager cache, call `userGamesStream(userId, overrideCache: true)` which internally calls `clearRequest()` on the `StreamRequestManager`, closing the errored `BehaviorSubject` and cancelling the failed subscription, then creates a fresh Firestore snapshot listener.

Change line 106 from:
```dart
onRetry: () => updateState(this, () {}),
```

To:
```dart
onRetry: () {
  // Clear the errored BehaviorSubject and create a fresh Firestore
  // subscription via StreamRequestManager.clearRequest().
  context.read<GameProvider>().userGamesStream(
        currentUserUid,
        overrideCache: true,
      );
  // Rebuild needed: AppStreamBuilder is stateless, so re-subscribing
  // requires the parent to rebuild and pass the new stream instance
  // to StreamBuilder.
  updateState(this, () {});
},
```

- [ ] **Step 3: Remove unused import if updateState is no longer used elsewhere**

Check if `updateState` is still used in the file (it is -- in onRetry). The import at line 11 (`import '/core/utils/state_update.dart';`) stays.

- [ ] **Step 4: Run flutter analyze**

Run: `flutter analyze lib/main_function/games_joined/games_joined_widget.dart`
Expected: No new warnings or errors.

- [ ] **Step 5: Run tests**

Run: `flutter test`
Expected: All existing tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/main_function/games_joined/games_joined_widget.dart
git commit -m "perf: remove unnecessary updateState in games_joined_widget

Remove empty setState from RefreshIndicator.onRefresh -- the live
Firestore snapshot stream delivers current data without a manual
rebuild. Fix onRetry to clear the errored BehaviorSubject via
overrideCache before rebuilding, preventing stale error replay."
```

---

### Task 2: Convert game_joined_dashboard_content.dart to CustomScrollView + slivers

**Context:** `game_joined_dashboard_content.dart` uses `SingleChildScrollView + Column` which eagerly builds all children even when offscreen. Converting to `CustomScrollView` with slivers lets Flutter skip layout/paint for offscreen sections.

The content has three section components:
- `GameJoinedDashboardOverviewSection` -- game title, time, location
- `GameJoinedDashboardDetailsPlayersSection` -- game details, pending requests, player cards (max 4 players)
- `GameJoinedDashboardActionsSection` -- CTA buttons

**Note on SliverList:** The spec calls for a `SliverList` for the player list. However, `PlayerListSection` is a 470-line StatefulWidget that loads profiles/trust data via FutureBuilder internally, and golf games have a hard cap of 4 players. Extracting individual player cards into a `SliverList.builder` would require a deep refactor of `PlayerListSection` for negligible performance gain (4 items). The pragmatic approach: wrap each section in `SliverToBoxAdapter`. The `CustomScrollView` itself provides the main win -- Flutter skips layout/paint for the entire Overview section once scrolled offscreen.

**Files:**
- Modify: `lib/main_function/game_joined_detailed/components/game_joined_dashboard_content.dart`

- [ ] **Step 1: Replace SingleChildScrollView + Column with CustomScrollView + SliverToBoxAdapter wrappers**

Change the `build` method (lines 78-122) from:

```dart
@override
Widget build(BuildContext context) {
  return SafeArea(
    top: false,
    child: SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 22),
          GameJoinedDashboardOverviewSection(...),
          GameJoinedDashboardDetailsPlayersSection(...),
          GameJoinedDashboardActionsSection(...),
          SizedBox(height: AppSpacing.md),
        ],
      ),
    ),
  );
}
```

To:

```dart
@override
Widget build(BuildContext context) {
  return SafeArea(
    top: false,
    child: CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.top + 22),
        ),
        SliverToBoxAdapter(
          child: GameJoinedDashboardOverviewSection(
            game: game,
            currentUserRef: currentUserRef,
            hasAnimated: hasAnimated,
            groupVibeCacheKey: groupVibeCacheKey,
            onEditGameDetails: onEditGameDetails,
          ),
        ),
        // Player list section: max 4 players + game details, FutureBuilder-driven --
        // SliverToBoxAdapter is appropriate here (SliverList would require deep
        // refactor of PlayerListSection for negligible gain on 4 items).
        SliverToBoxAdapter(
          child: GameJoinedDashboardDetailsPlayersSection(
            game: game,
            screenGameRef: screenGameRef,
            currentUserRef: currentUserRef,
            hasAnimated: hasAnimated,
            groupVibeCacheKey: groupVibeCacheKey,
            pendingRequests: pendingRequests,
            ownerVibeProfile: ownerVibeProfile,
            expandedRequestId: expandedRequestId,
            onApproveRequest: onApproveRequest,
            onDeclineRequest: onDeclineRequest,
            onRemoveRequest: onRemoveRequest,
            onExpandRequest: onExpandRequest,
            onShowRemovePlayerDialog: onShowRemovePlayerDialog,
            onOpenPremiumVibePage: onOpenPremiumVibePage,
          ),
        ),
        SliverToBoxAdapter(
          child: GameJoinedDashboardActionsSection(
            game: game,
            screenGameRef: screenGameRef,
            currentUserRef: currentUserRef,
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.md),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze lib/main_function/game_joined_detailed/components/game_joined_dashboard_content.dart`
Expected: No new warnings or errors.

- [ ] **Step 3: Run tests**

Run: `flutter test`
Expected: All existing tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/main_function/game_joined_detailed/components/game_joined_dashboard_content.dart
git commit -m "perf: convert game_joined_dashboard_content to CustomScrollView

Replace SingleChildScrollView + Column with CustomScrollView + slivers.
Flutter can now skip layout/paint for offscreen sections (e.g. overview
section once scrolled past). Player list stays in SliverToBoxAdapter
since PlayerListSection uses FutureBuilder and max 4 items."
```

---

### Task 3: Replace IntrinsicHeight in host_checkin_screen.dart

**Context:** `host_checkin_screen.dart` lines 209-282 use a `LayoutBuilder > SingleChildScrollView > ConstrainedBox > IntrinsicHeight > Column` pattern with `Spacer` widgets for vertical centering. `IntrinsicHeight` forces a double layout pass. The intent is: center the header + participant list, with the submit button near the bottom, scrollable when content overflows.

The clean Flutter idiom for "fill viewport but scroll if content overflows" is `CustomScrollView` + `SliverFillRemaining(hasScrollBody: false)`. This gives bounded height (enabling `MainAxisAlignment` and `Spacer`) without `IntrinsicHeight`'s double pass, and auto-scrolls on overflow.

**Files:**
- Modify: `lib/screens/confirmation/host_checkin_screen.dart:208-283`

- [ ] **Step 1: Replace the layout pattern**

Change the `body` content (starting at line 208) from:

```dart
body: SafeArea(
  child: LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              children: [
                const Spacer(flex: 1),
                _buildHeader(),
                SizedBox(height: AppSpacing.xxxl),
                Padding(
                  padding: AppSpacing.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  child: Column(
                    children: [
                      for (int i = 0;
                          i < _participants.length;
                          i++) ...[
                        if (i > 0) SizedBox(height: AppSpacing.xxs),
                        _buildParticipantRow(i),
                      ],
                    ],
                  ),
                ),
                const Spacer(flex: 1),
                if (_error != null)
                  Padding(...error section...),
                Padding(...submit button...),
              ],
            ),
          ),
        ),
      );
    },
  ),
),
```

To:

```dart
body: SafeArea(
  child: CustomScrollView(
    slivers: [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Column(
          children: [
            const Spacer(flex: 1),
            _buildHeader(),
            SizedBox(height: AppSpacing.xxxl),
            Padding(
              padding: AppSpacing.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: Column(
                children: [
                  for (int i = 0;
                      i < _participants.length;
                      i++) ...[
                    if (i > 0) SizedBox(height: AppSpacing.xxs),
                    _buildParticipantRow(i),
                  ],
                ],
              ),
            ),
            const Spacer(flex: 1),
            if (_error != null)
              Padding(
                padding: AppSpacing.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm),
                child: Column(
                  children: [
                    Text(
                      _error!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    AppButtonEnhanced(
                      text: 'Try again',
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.small,
                      onPressed: _retryLoad,
                    ),
                  ],
                ),
              ),
            Padding(
              padding: AppSpacing.only(
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                  bottom: AppSpacing.xxl,
                  top: AppSpacing.lg),
              child: AppButtonEnhanced(
                onPressed: _submitting ? null : _submit,
                text: 'Confirm Attendance',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                isLoading: _submitting,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),
```

This eliminates `LayoutBuilder`, `SingleChildScrollView`, `ConstrainedBox`, and `IntrinsicHeight`. The `SliverFillRemaining(hasScrollBody: false)` provides bounded viewport height (so `Spacer` works) and auto-scrolls when content overflows.

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze lib/screens/confirmation/host_checkin_screen.dart`
Expected: No new warnings or errors.

- [ ] **Step 3: Run tests**

Run: `flutter test`
Expected: All existing tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/confirmation/host_checkin_screen.dart
git commit -m "perf: replace IntrinsicHeight with SliverFillRemaining in host_checkin_screen

Remove LayoutBuilder + SingleChildScrollView + ConstrainedBox + IntrinsicHeight
pattern. Use CustomScrollView + SliverFillRemaining(hasScrollBody: false) which
provides bounded height for Spacer without IntrinsicHeight's double layout pass."
```

---

## Part B -- Design Token Compliance

### Task 4: Replace hardcoded icon size in unified_game_card.dart

**Context:** Line 415 has `size: 12` on a calendar icon inside `AppIcon`. The closest token is `AppIconSize.xs` (16px). There is no 12px token, and 12px is below the minimum icon size in the design system. Use `AppIconSize.xs`.

**Visual note:** This is a 12px to 16px increase (33%). The icon sits in a compact date/time row. Visually verify the row layout still looks balanced after the change -- the 4px increase should be fine given `AppIconSize.xs` is the design system floor.

**Files:**
- Modify: `lib/main_function/games_list/components/unified_game_card.dart:415`

- [ ] **Step 1: Replace the hardcoded size**

Change line 415 from:
```dart
size: 12,
```

To:
```dart
size: AppIconSize.xs,
```

Verify the `AppIconSize` import already exists (check top of file for `import '/core/design_tokens/icon_size.dart';`).

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze lib/main_function/games_list/components/unified_game_card.dart`
Expected: No new warnings or errors.

- [ ] **Step 3: Commit**

```bash
git add lib/main_function/games_list/components/unified_game_card.dart
git commit -m "fix: replace hardcoded icon size with AppIconSize.xs in unified_game_card"
```

---

### Task 5: Replace Colors.white with token in game_joined_state_handler.dart

**Context:** Lines 136 and 205 use `Colors.white.withValues(alpha: 0.6)` with a `// Keep: no 60% token` comment. The token combination exists: `AppColors.pure` is white (`0xFFFFFFFF`), and `AppOpacity.prominent` is `0.60`. Replace both instances and remove the stale comments.

**Files:**
- Modify: `lib/main_function/game_joined_detailed/components/game_joined_state_handler.dart:136,205`

- [ ] **Step 1: Replace the first instance (line 136)**

Change:
```dart
color: Colors.white.withValues(alpha: 0.6), // Keep: no 60% token
```

To:
```dart
color: AppColors.pure.withValues(alpha: AppOpacity.prominent),
```

- [ ] **Step 2: Replace the second instance (line 205)**

Change:
```dart
color: Colors.white.withValues(alpha: 0.6), // Keep: no 60% token
```

To:
```dart
color: AppColors.pure.withValues(alpha: AppOpacity.prominent),
```

- [ ] **Step 3: Add opacity import if missing**

Verify the file imports `AppOpacity`. If not, add:
```dart
import '/core/design_tokens/opacity.dart';
```

The file already imports `AppColors` from `'/core/design_tokens/colors.dart'` (line 4). Also remove the `package:flutter/material.dart` `Colors` usage -- verify no other `Colors.*` references remain. (The file uses `AppColors` everywhere else, so the `Colors` import may become unused if Flutter's `Colors` class is no longer referenced; however, `material.dart` is still needed for `Widget`, `BuildContext`, etc.)

- [ ] **Step 4: Run flutter analyze**

Run: `flutter analyze lib/main_function/game_joined_detailed/components/game_joined_state_handler.dart`
Expected: No new warnings or errors.

- [ ] **Step 5: Commit**

```bash
git add lib/main_function/game_joined_detailed/components/game_joined_state_handler.dart
git commit -m "fix: replace Colors.white with AppColors.pure + AppOpacity.prominent

Replace Colors.white.withValues(alpha: 0.6) with token combination
AppColors.pure.withValues(alpha: AppOpacity.prominent) at both
instances. Remove stale 'Keep: no 60% token' comments."
```

---

### Task 6: Replace raw PhosphorIcon calls with AppIcon in confirmation screen components

**Context:** 11 instances of raw `PhosphorIcon(...)` across 7 files in `lib/screens/confirmation/`. All should use `AppIcon(icon: ..., size: ..., color: ...)` per CLAUDE.md rules. `AppIcon` requires `PhosphorIconData` (not generic `IconData`), so components accepting `IconData` parameters need their type changed to `PhosphorIconData`.

**Important:** `AppIcon` renders via `PhosphorIcon` internally but enforces token usage and defaults (size defaults to `AppIconSize.md`, color defaults to `AppColors.textSecondary`). All instances already use `AppPhosphorIcons` constants and `AppIconSize` tokens, so the change is mechanical: swap `PhosphorIcon(` for `AppIcon(icon:` and adjust parameter syntax.

**Files:**
- Modify: `lib/screens/confirmation/components/checkin_status_view.dart`
- Modify: `lib/screens/confirmation/components/fallback_status_view.dart`
- Modify: `lib/screens/confirmation/components/peer_rating_header.dart`
- Modify: `lib/screens/confirmation/components/peer_rating_status_views.dart`
- Modify: `lib/screens/confirmation/components/fallback_header.dart`
- Modify: `lib/screens/confirmation/peer_rating_screen.dart`
- Modify: `lib/screens/confirmation/fallback_confirmation_screen.dart`

#### Step group A: Components with IconData parameters

These components accept `IconData icon` as a constructor parameter. Change to `PhosphorIconData` so they can use `AppIcon`.

- [ ] **Step 1: Update checkin_status_view.dart**

File: `lib/screens/confirmation/components/checkin_status_view.dart`

a) Keep the existing `import 'package:phosphor_flutter/phosphor_flutter.dart';` -- it is needed for the `PhosphorIconData` type in the field declaration. Add the `AppIcon` import:
```dart
import '/core/widgets/app_icon.dart';
```

b) Change the `icon` field type (line 19) from `IconData` to `PhosphorIconData`:
```dart
final PhosphorIconData icon;
```

c) Change line 45 from:
```dart
PhosphorIcon(icon, color: iconColor, size: AppIconSize.hero),
```
To:
```dart
AppIcon(icon: icon, color: iconColor, size: AppIconSize.hero),
```

d) Verify callers: Search for `CheckinStatusView(` in `host_checkin_screen.dart`. Callers pass `AppPhosphorIcons.successFill` and `AppPhosphorIcons.clock` which are `PhosphorIconData` -- the type change is safe.

- [ ] **Step 2: Update fallback_status_view.dart**

File: `lib/screens/confirmation/components/fallback_status_view.dart`

a) Keep the existing `import 'package:phosphor_flutter/phosphor_flutter.dart';` -- it is needed for the `PhosphorIconData` type in the field declaration. Add the `AppIcon` import:
```dart
import '/core/widgets/app_icon.dart';
```

b) Change the `icon` field type (line 21) from `IconData` to `PhosphorIconData`:
```dart
final PhosphorIconData icon;
```

c) Change line 37 from:
```dart
PhosphorIcon(icon, color: iconColor, size: AppIconSize.hero),
```
To:
```dart
AppIcon(icon: icon, color: iconColor, size: AppIconSize.hero),
```

d) Verify callers: Search for `FallbackStatusView(` in `fallback_confirmation_screen.dart`. Callers pass `AppPhosphorIcons.successFill`, `AppPhosphorIcons.clock`, `AppPhosphorIcons.cancelFill` -- all `PhosphorIconData`, safe.

#### Step group B: Components with inline PhosphorIcon usage

- [ ] **Step 3: Update peer_rating_header.dart**

File: `lib/screens/confirmation/components/peer_rating_header.dart`

a) Add import:
```dart
import '/core/widgets/app_icon.dart';
```

b) Change line 30-34 from:
```dart
PhosphorIcon(
  AppPhosphorIcons.thumbsUp,
  color: AppColors.textSecondary,
  size: AppIconSize.xxl,
),
```
To:
```dart
AppIcon(
  icon: AppPhosphorIcons.thumbsUp,
  color: AppColors.textSecondary,
  size: AppIconSize.xxl,
),
```

c) Change line 55-59 from:
```dart
PhosphorIcon(
  AppPhosphorIcons.lock,
  size: AppIconSize.xs,
  color: AppColors.textMuted,
),
```
To:
```dart
AppIcon(
  icon: AppPhosphorIcons.lock,
  size: AppIconSize.xs,
  color: AppColors.textMuted,
),
```

d) Remove `import 'package:phosphor_flutter/phosphor_flutter.dart';` -- after conversion, no `PhosphorIcon`, `PhosphorIconData`, or other `phosphor_flutter` symbols are referenced directly. `AppPhosphorIcons` constants are typed via `app_phosphor_icons.dart` which handles its own import.

- [ ] **Step 4: Update fallback_header.dart**

File: `lib/screens/confirmation/components/fallback_header.dart`

a) Add import:
```dart
import '/core/widgets/app_icon.dart';
```

b) Change line 28-32 from:
```dart
PhosphorIcon(
  AppPhosphorIcons.golfCourse,
  color: AppColors.textSecondary,
  size: AppIconSize.xxl,
),
```
To:
```dart
AppIcon(
  icon: AppPhosphorIcons.golfCourse,
  color: AppColors.textSecondary,
  size: AppIconSize.xxl,
),
```

c) Remove `import 'package:phosphor_flutter/phosphor_flutter.dart';` -- no remaining direct references to `phosphor_flutter` symbols.

- [ ] **Step 5: Update peer_rating_status_views.dart (4 instances)**

File: `lib/screens/confirmation/components/peer_rating_status_views.dart`

a) Add import:
```dart
import '/core/widgets/app_icon.dart';
```

b) Line 76-77 -- change:
```dart
PhosphorIcon(AppPhosphorIcons.thumbsUp,
    color: AppColors.green, size: AppIconSize.hero),
```
To:
```dart
AppIcon(icon: AppPhosphorIcons.thumbsUp,
    color: AppColors.green, size: AppIconSize.hero),
```

c) Line 115-116 -- change:
```dart
PhosphorIcon(AppPhosphorIcons.clock,
    color: AppColors.textMuted, size: AppIconSize.hero),
```
To:
```dart
AppIcon(icon: AppPhosphorIcons.clock,
    color: AppColors.textMuted, size: AppIconSize.hero),
```

d) Line 148-149 -- change:
```dart
PhosphorIcon(AppPhosphorIcons.thumbsUp,
    color: AppColors.green, size: AppIconSize.hero),
```
To:
```dart
AppIcon(icon: AppPhosphorIcons.thumbsUp,
    color: AppColors.green, size: AppIconSize.hero),
```

e) Line 186-187 -- the back button in `_buildEmpty`'s AppBar leading. Change:
```dart
icon: PhosphorIcon(AppPhosphorIcons.back,
    color: AppColors.textPrimary),
```
To:
```dart
icon: AppIcon(icon: AppPhosphorIcons.back,
    color: AppColors.textPrimary, size: AppIconSize.md),
```

Note: This instance was missing an explicit size. `AppIcon` defaults to `AppIconSize.md` (24px) which is correct for AppBar icons, but specifying it explicitly matches the pattern used elsewhere.

f) Remove `import 'package:phosphor_flutter/phosphor_flutter.dart';` -- no remaining direct references to `phosphor_flutter` symbols.

#### Step group C: Main screen back buttons

- [ ] **Step 6: Update peer_rating_screen.dart back button**

File: `lib/screens/confirmation/peer_rating_screen.dart`

Locate the AppBar leading (around line 295-298). Change:
```dart
leading: IconButton(
  icon:
      PhosphorIcon(AppPhosphorIcons.back, color: AppColors.textPrimary),
  onPressed: () => _navigateToMyGames(),
),
```
To:
```dart
leading: IconButton(
  icon: AppIcon(icon: AppPhosphorIcons.back, color: AppColors.textPrimary, size: AppIconSize.md),
  onPressed: () => _navigateToMyGames(),
),
```

Ensure `import '/core/widgets/app_icon.dart';` is present. Remove `import 'package:phosphor_flutter/phosphor_flutter.dart';` if no remaining direct references -- search the file for `PhosphorIcon(` or `PhosphorIconData` to confirm.

- [ ] **Step 7: Update fallback_confirmation_screen.dart back button**

File: `lib/screens/confirmation/fallback_confirmation_screen.dart`

Locate the AppBar leading (around line 202-205). Change:
```dart
leading: IconButton(
  icon: PhosphorIcon(AppPhosphorIcons.back, color: AppColors.textPrimary),
  onPressed: () => Navigator.of(context).pop(),
),
```
To:
```dart
leading: IconButton(
  icon: AppIcon(icon: AppPhosphorIcons.back, color: AppColors.textPrimary, size: AppIconSize.md),
  onPressed: () => Navigator.of(context).pop(),
),
```

Ensure `import '/core/widgets/app_icon.dart';` is present. Remove `import 'package:phosphor_flutter/phosphor_flutter.dart';` if no remaining direct references -- search the file for `PhosphorIcon(` or `PhosphorIconData` to confirm.

#### Step group D: Verify and commit

- [ ] **Step 8: Run flutter analyze on all changed files**

Run: `flutter analyze lib/screens/confirmation/`
Expected: No new warnings or errors. Watch for:
- Unused imports (if `phosphor_flutter` was removed but still needed for type)
- Type mismatches (if any caller passes `IconData` instead of `PhosphorIconData`)

- [ ] **Step 9: Run tests**

Run: `flutter test`
Expected: All existing tests pass.

- [ ] **Step 10: Commit**

```bash
git add lib/screens/confirmation/
git commit -m "fix: replace raw PhosphorIcon with AppIcon in confirmation screens

Replace 11 instances of raw PhosphorIcon() with AppIcon(icon:) across
7 files in the confirmation flow. Update CheckinStatusView and
FallbackStatusView parameter types from IconData to PhosphorIconData.
Add explicit size tokens where missing (back button icons)."
```

---

---

## Follow-up Note (Out of Scope)

`peer_rating_screen.dart` (line 307) and `fallback_confirmation_screen.dart` (line 213) use the identical `LayoutBuilder > SingleChildScrollView > ConstrainedBox > IntrinsicHeight > Column` pattern as `host_checkin_screen.dart`. The spec only targets `host_checkin_screen.dart`, but the same `SliverFillRemaining` fix applies to both. Consider a follow-up pass.

---

## Final Verification

- [ ] **Run full flutter analyze**

Run: `flutter analyze`
Expected: Zero new warnings.

- [ ] **Run full test suite**

Run: `flutter test`
Expected: Zero new failures.

- [ ] **Manual smoke test** (optional but recommended)

1. Open "My Games" tab -- pull to refresh works, retry on error works
2. Tap into a joined game -- dashboard scrolls smoothly
3. Open host check-in screen -- layout centered, button at bottom, scrolls on small screens
4. Game cards in list show calendar icon at correct size
5. Game error/not-found states show correct text color
6. Confirmation flow screens render icons correctly
