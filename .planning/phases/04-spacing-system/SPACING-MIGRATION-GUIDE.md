# Spacing System Migration Guide

**Phase:** 04-spacing-system
**Created:** 2026-01-20
**Purpose:** Comprehensive roadmap for eliminating hardcoded spacing and achieving 90%+ AppSpacing token adoption

## Executive Summary

Current state: **40-50% hardcoded spacing** despite having a mature AppSpacing design token system.
Target state: **<10% hardcoded spacing, 90%+ token adoption**

**Key Findings:**
- 1,017 AppSpacing token usages (current adoption baseline)
- 69 hardcoded SizedBox(height: N) instances
- 37 hardcoded SizedBox(width: N) instances
- 74 EdgeInsetsDirectional.fromSTEB() instances
- 31 off-grid values (2px, 6px, 10px) breaking 4px/8px grid system

**Migration Scope:** 180 total anti-patterns to fix across 40+ files

---

## Part 1: Quantified Anti-Pattern Inventory

### 1.1 Hardcoded SizedBox Heights

**Total instances:** 69
**Distribution by value:**

| Value | Count | Target Replacement | Impact |
|-------|-------|-------------------|--------|
| 2px | 19 | AppSpacing.xxs (4px) | HIGH - Off-grid, most common |
| 4px | 13 | AppSpacing.xxs | MEDIUM - On-grid but hardcoded |
| 16px | 11 | AppSpacing.md | MEDIUM - Common spacing |
| 12px | 8 | AppSpacing.sm | MEDIUM - List spacing |
| 40px | 5 | AppSpacing.xxxl (48px) OR custom | LOW - Large gaps |
| 32px | 4 | AppSpacing.xxl | LOW - Section spacing |
| 8px | 3 | AppSpacing.xs | LOW - Tight spacing |
| 24px | 2 | AppSpacing.xl | LOW - Card spacing |
| 20px | 2 | AppSpacing.lg | LOW - Comfortable spacing |
| 100px | 1 | Custom (context dependent) | LOW - Hero spacing |
| 10px | 1 | AppSpacing.xs (8px) or sm (12px) | CRITICAL - Off-grid |

**High-priority files (most instances):**

1. `lib/core/widgets/app_button_examples.dart` - 17 instances (example file, low priority)
2. `lib/core/widgets/fairway_background_examples.dart` - 15 instances (example file, low priority)
3. `lib/chat_group/game_chat_details/game_chat_details_widget.dart` - 5 instances (CRITICAL)
4. `lib/main_function/join_game_detailed/join_game_detailed_widget.dart` - 4 instances
5. `lib/main_function/game_joined_detailed/game_joined_detailed_widget.dart` - 4 instances
6. `lib/profile/main_profile/main_profile_widget.dart` - 3 instances
7. `lib/main_function/golfers/golfers_widget.dart` - 3 instances
8. `lib/main_function/create_game/create_game_widget.dart` - 3 instances
9. `lib/friends/tab_friends/tab_friends_widget.dart` - 3 instances

### 1.2 Hardcoded SizedBox Widths

**Total instances:** 37
**Distribution by value:**

| Value | Count | Target Replacement | Impact |
|-------|-------|-------------------|--------|
| 4px | 14 | AppSpacing.xxs | MEDIUM - Icon gaps |
| 8px | 10 | AppSpacing.xs | MEDIUM - Text gaps |
| 6px | 6 | AppSpacing.xxs (4px) or xs (8px) | CRITICAL - Off-grid |
| 12px | 6 | AppSpacing.sm | LOW - Button gaps |
| 16px | 1 | AppSpacing.md | LOW - Larger gaps |

**Note:** Width spacing less common but still needs standardization

### 1.3 EdgeInsetsDirectional.fromSTEB() Usage

**Total instances:** 74
**High-priority files:**

1. `lib/main_function/create_game/create_game_widget.dart` - 17 instances (CRITICAL)
2. `lib/user_auth/sign_up_account/sign_up_account_widget.dart` - 13 instances (CRITICAL)
3. `lib/user_auth/sign_in/sign_in_widget.dart` - 13 instances (CRITICAL)
4. `lib/user_auth/recover_password/recover_password_widget.dart` - 7 instances
5. `lib/friends/tab_friends/tab_friends_widget.dart` - 6 instances
6. `lib/main_function/become_friends/become_friends_widget.dart` - 3 instances
7. `lib/components/date_format_widget.dart` - 3 instances
8. `lib/main_function/golfers/golfers_widget.dart` - 2 instances
9. `lib/main_function/community/community_widget.dart` - 2 instances

**Sample off-grid patterns found:**
- `fromSTEB(0.0, 15.0, 0.0, 5.0)` - create_game (15px = off-grid)
- `fromSTEB(0.0, 5.0, 0.0, 0.0)` - create_game (5px = off-grid)
- `fromSTEB(10.0, 0.0, 0.0, 0.0)` - player_list (10px = off-grid)

### 1.4 Off-Grid Values

**Total off-grid violations:** 31 instances

**Breakdown:**
- 2px values: 19 instances (SizedBox height)
- 6px values: 6 instances (SizedBox width)
- 10px values: 2 instances (fromSTEB + SizedBox)
- 5px values: ~4+ instances (fromSTEB patterns in create_game)

**Critical Impact:** These values break visual grid alignment and create subtle layout inconsistencies

### 1.5 Current AppSpacing Adoption Metrics

**Total AppSpacing token usages:** 1,017 instances

**Most popular tokens:**
1. AppSpacing.md (16px) - 332 usages (33%)
2. AppSpacing.sm (12px) - 253 usages (25%)
3. AppSpacing.xs (8px) - 181 usages (18%)
4. AppSpacing.lg (20px) - 117 usages (12%)
5. AppSpacing.xxs (4px) - 62 usages (6%)
6. AppSpacing.xl (24px) - 41 usages (4%)
7. AppSpacing.xxl (32px) - 14 usages (1%)
8. AppSpacing.xxxl (48px) - 11 usages (1%)

**Shortcut usage:**
- AppSpacing.only() - 23 usages
- AppSpacing.symmetric() - 20 usages
- AppSpacing.verticalMdBox - 14 usages
- AppSpacing.verticalSmBox - 10 usages
- AppSpacing.verticalXxs - 9 usages
- AppSpacing.horizontalSmBox - 5 usages
- AppSpacing.allXxs - 4 usages
- AppSpacing.card - 3 usages

**Success story:** AppSpacing.md (332 usages) shows the system works when consistently applied

---

## Part 2: Replacement Patterns

### 2.1 SizedBox Height Replacements

**Common patterns with before/after examples:**

#### Pattern 1: Micro Spacing (2px → 4px)
```dart
// BEFORE (19 instances)
SizedBox(height: 2)

// AFTER - Accept slight increase for grid alignment
SizedBox(height: AppSpacing.xxs)  // 4px
```

**Rationale:** 2px breaks 4px grid. Visual impact of +2px is negligible in most contexts.

**Example files:**
- `lib/profile/main_profile/main_profile_widget.dart` (line 570)
- `lib/friends/tab_friends/tab_friends_widget.dart` (line 808)
- `lib/main_function/golfers/golfers_widget.dart` (line 745)

---

#### Pattern 2: Extra Small Spacing (4px)
```dart
// BEFORE (13 instances)
SizedBox(height: 4)

// AFTER
SizedBox(height: AppSpacing.xxs)  // 4px
```

**Best for:** Icon padding, tight label spacing, chip gaps

**Example files:**
- `lib/friends/tab_friends/tab_friends_widget.dart` (line 1020)
- `lib/main_function/create_game/create_game_widget.dart`

---

#### Pattern 3: Tight Spacing (8px)
```dart
// BEFORE (3 instances)
SizedBox(height: 8)

// AFTER
SizedBox(height: AppSpacing.xs)  // 8px
```

**Best for:** Closely related elements, compact lists

**Example files:**
- `lib/chat_group/game_chat_details/game_chat_details_widget.dart`

---

#### Pattern 4: Small Spacing (12px)
```dart
// BEFORE (8 instances)
SizedBox(height: 12)

// AFTER
SizedBox(height: AppSpacing.sm)  // 12px
```

**Best for:** List items, form field gaps, compact sections

**Example files:**
- `lib/main_function/game_joined_detailed/game_joined_detailed_widget.dart` (line 463)
- `lib/main_function/join_game_detailed/join_game_detailed_widget.dart`

---

#### Pattern 5: Medium Spacing (16px)
```dart
// BEFORE (11 instances)
SizedBox(height: 16)

// AFTER
SizedBox(height: AppSpacing.md)  // 16px
```

**Best for:** Default spacing, comfortable element separation, section headers

**Example files:**
- `lib/chat_group/game_chat_details/game_chat_details_widget.dart`

---

#### Pattern 6: Medium-Large Spacing (20px)
```dart
// BEFORE (2 instances)
SizedBox(height: 20)

// AFTER
SizedBox(height: AppSpacing.lg)  // 20px
```

**Best for:** Comfortable breathing room, screen sections

---

#### Pattern 7: Large Spacing (24px)
```dart
// BEFORE (2 instances)
SizedBox(height: 24)

// AFTER
SizedBox(height: AppSpacing.xl)  // 24px
```

**Best for:** Major sections, card padding

---

#### Pattern 8: Extra Large Spacing (32px)
```dart
// BEFORE (4 instances)
SizedBox(height: 32)

// AFTER
SizedBox(height: AppSpacing.xxl)  // 32px
```

**Best for:** Major section breaks, screen margins

---

#### Pattern 9: Off-Grid Large Spacing (40px → 48px)
```dart
// BEFORE (5 instances)
SizedBox(height: 40)

// AFTER - Round up to nearest grid value
SizedBox(height: AppSpacing.xxxl)  // 48px

// OR if exact size critical (rare)
SizedBox(height: 40)  // Document reason in comment
```

**Rationale:** 40px is off-grid. 48px maintains visual hierarchy better.

---

#### Pattern 10: Hero Spacing (100px)
```dart
// BEFORE (1 instance)
SizedBox(height: 100)

// AFTER - Context dependent
SizedBox(height: AppSpacing.xxxxl)  // 64px if too large
// OR
const double heroSpacing = 100.0;  // If exact size needed
SizedBox(height: heroSpacing)
```

**Note:** Very large custom values may warrant component-specific constants

---

### 2.2 EdgeInsetsDirectional.fromSTEB() Replacements

**Common patterns with before/after examples:**

#### Pattern 1: Horizontal Padding
```dart
// BEFORE (very common)
padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0)

// AFTER - Option 1: EdgeInsets.symmetric
padding: EdgeInsets.symmetric(horizontal: AppSpacing.md)

// AFTER - Option 2: Shortcut (preferred for common cases)
padding: AppSpacing.horizontalMd
```

**Example files:**
- `lib/user_auth/sign_up_account/sign_up_account_widget.dart`
- `lib/user_auth/sign_in/sign_in_widget.dart`

---

#### Pattern 2: Vertical Padding
```dart
// BEFORE
padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 12.0)

// AFTER - Option 1: EdgeInsets.symmetric
padding: EdgeInsets.symmetric(vertical: AppSpacing.sm)

// AFTER - Option 2: Shortcut
padding: AppSpacing.verticalSm
```

---

#### Pattern 3: All Sides Equal
```dart
// BEFORE
padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0)

// AFTER - Option 1: EdgeInsets.all
padding: EdgeInsets.all(AppSpacing.md)

// AFTER - Option 2: Shortcut (preferred)
padding: AppSpacing.allMd
```

---

#### Pattern 4: Single Side Padding
```dart
// BEFORE
padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 0.0, 0.0)

// AFTER - Option 1: EdgeInsets.only
padding: EdgeInsets.only(left: AppSpacing.lg)

// AFTER - Option 2: AppSpacing helper
padding: AppSpacing.only(left: AppSpacing.lg)
```

**Example file:**
- `lib/main_function/player_list/player_list_widget.dart` (line 159)

---

#### Pattern 5: Complex Asymmetric Padding
```dart
// BEFORE
padding: EdgeInsetsDirectional.fromSTEB(20.0, 16.0, 20.0, 24.0)

// AFTER - Use EdgeInsets.only with named parameters
padding: EdgeInsets.only(
  left: AppSpacing.lg,
  top: AppSpacing.md,
  right: AppSpacing.lg,
  bottom: AppSpacing.xl,
)
```

**Note:** Complex patterns are fine if intentional. Avoid if symmetric pattern works.

---

#### Pattern 6: Off-Grid fromSTEB Values
```dart
// BEFORE - create_game line 779
padding: EdgeInsetsDirectional.fromSTEB(0.0, 15.0, 0.0, 5.0)

// AFTER - Round to nearest grid values
padding: EdgeInsets.only(
  top: AppSpacing.md,    // 16px (was 15px)
  bottom: AppSpacing.xxs, // 4px (was 5px)
)
```

**Affected files:**
- `lib/main_function/create_game/create_game_widget.dart` (multiple lines with 5px, 15px)
- `lib/main_function/player_list/player_list_widget.dart` (10px)

---

### 2.3 SizedBox Width Replacements

**Common patterns:**

#### Pattern 1: Icon-Text Gap
```dart
// BEFORE (14 instances)
SizedBox(width: 4)

// AFTER
SizedBox(width: AppSpacing.xxs)
// OR use semantic constant
SizedBox(width: AppSpacing.iconTextGap)  // 8px
```

**Note:** AppSpacing.iconTextGap is 8px, not 4px. Consider if 4px is too tight.

---

#### Pattern 2: Off-Grid Width (6px)
```dart
// BEFORE (6 instances)
SizedBox(width: 6)

// AFTER - Round to nearest grid
SizedBox(width: AppSpacing.xxs)  // 4px
// OR
SizedBox(width: AppSpacing.xs)   // 8px (better for touch targets)
```

---

#### Pattern 3: Button Gap
```dart
// BEFORE
SizedBox(width: 8)

// AFTER
SizedBox(width: AppSpacing.xs)
// OR use semantic constant
SizedBox(width: AppSpacing.buttonGap)  // 12px if spacing between buttons
```

---

### 2.4 Off-Grid Value Decision Matrix

**For values not on 4px grid:**

| Off-Grid Value | Recommended Replacement | Context Notes |
|----------------|------------------------|---------------|
| 2px | AppSpacing.xxs (4px) | Accept +2px for grid alignment |
| 5px | AppSpacing.xxs (4px) | Round down for tight spacing |
| 6px | AppSpacing.xs (8px) | Round up for better touch targets |
| 10px | AppSpacing.xs (8px) or sm (12px) | Context: tight vs comfortable |
| 15px | AppSpacing.md (16px) | Round up for breathing room |
| 18px | AppSpacing.lg (20px) | Round up for section spacing |
| 40px | AppSpacing.xxxl (48px) | Maintain visual hierarchy |

**General rule:** Round to nearest grid value. When in doubt, round up for better readability.

---

## Part 3: Migration Strategy

### 3.1 Target Metrics

**Baseline (Current State):**
- AppSpacing token usage: 1,017 instances
- Hardcoded SizedBox heights: 69 instances
- Hardcoded SizedBox widths: 37 instances
- EdgeInsetsDirectional.fromSTEB: 74 instances
- Off-grid values: 31 instances
- **Total anti-patterns: 180 instances**
- **Token adoption: ~85%** (1,017 / ~1,200 total spacing instances)

**Target Metrics (End of Phase 4):**
- AppSpacing token usage: 1,150+ instances (90%+ adoption)
- Hardcoded SizedBox heights: <10 instances (unavoidable edge cases only)
- Hardcoded SizedBox widths: <5 instances
- EdgeInsetsDirectional.fromSTEB: <10 instances (complex asymmetric only)
- Off-grid values: 0 instances
- **Total anti-patterns: <25 instances**
- **Token adoption: 95%+**

**Success Criteria:**
- ✅ All off-grid values eliminated (0 instances of 2px, 6px, 10px, 15px)
- ✅ 90%+ of vertical spacing uses AppSpacing tokens
- ✅ 90%+ of EdgeInsets uses AppSpacing shortcuts or tokens
- ✅ No new hardcoded spacing introduced during migration
- ✅ Visual verification: layouts maintain or improve consistency

---

### 3.2 Phased Approach (Plans 04-02 and 04-03)

**Wave 2 Parallel Execution:**

#### Plan 04-02: Game & Social Screens (Parallel)
**Scope:** 15 screens
**Estimated anti-patterns:** ~90 instances

**Game Screens (Priority Order):**
1. `create_game_widget.dart` - 17 fromSTEB + 3 SizedBox = 20 anti-patterns (CRITICAL)
2. `game_joined_detailed_widget.dart` - 4 SizedBox + 1 fromSTEB = 5 anti-patterns
3. `join_game_detailed_widget.dart` - 4 SizedBox + 1 fromSTEB = 5 anti-patterns
4. `game_chat_details_widget.dart` - 5 SizedBox + 1 fromSTEB = 6 anti-patterns (CRITICAL)
5. `golfers_widget.dart` - 3 SizedBox + 2 fromSTEB = 5 anti-patterns
6. `games_list_widget.dart` - Mostly compliant, spot check
7. `games_joined_widget.dart` - Spot check
8. `player_list_widget.dart` - 1 fromSTEB (off-grid 10px)
9. `join_game_widget.dart` - Spot check

**Social Screens (Priority Order):**
1. `tab_friends_widget.dart` - 3 SizedBox + 6 fromSTEB = 9 anti-patterns (HIGH)
2. `become_friends_widget.dart` - 3 fromSTEB
3. `community_widget.dart` - 2 fromSTEB
4. `premium_friend_card.dart` - 1 SizedBox
5. `friend_filter_bottom_sheet.dart` - Spot check
6. `grouped_friends_list.dart` - Spot check

---

#### Plan 04-03: Profile & Auth Screens (Parallel)
**Scope:** 12 screens
**Estimated anti-patterns:** ~65 instances

**Auth Screens (Priority Order - CRITICAL):**
1. `sign_up_account_widget.dart` - 13 fromSTEB (many off-grid) (CRITICAL)
2. `sign_in_widget.dart` - 13 fromSTEB (CRITICAL)
3. `recover_password_widget.dart` - 7 fromSTEB

**Profile Screens (Priority Order):**
1. `main_profile_widget.dart` - 3 SizedBox
2. `profile_user_firebase_widget.dart` - 2 SizedBox + 1 fromSTEB
3. `edit_profile_widget.dart` - 1 SizedBox
4. `edit_vibes_widget.dart` - Spot check
5. `create_profile_widget.dart` - Spot check
6. `home_widget.dart` - Spot check
7. `change_photo_widget.dart` - Spot check

**Note:** Auth screens are highest priority due to heavy fromSTEB usage with off-grid values

---

### 3.3 Migration Process (Per Screen)

**Step-by-step approach:**

1. **Audit:** Count anti-patterns in file
   ```bash
   grep -n "SizedBox(height: [0-9]" file.dart
   grep -n "SizedBox(width: [0-9]" file.dart
   grep -n "EdgeInsetsDirectional.fromSTEB" file.dart
   ```

2. **Prioritize:** Fix off-grid values first (2px, 6px, 10px, 15px)

3. **Replace SizedBox heights:**
   - Search for `SizedBox(height: 2)` → Replace with `SizedBox(height: AppSpacing.xxs)`
   - Repeat for 4px, 8px, 12px, 16px, 20px, 24px, 32px

4. **Replace fromSTEB patterns:**
   - Identify symmetric patterns → Use AppSpacing shortcuts
   - Convert horizontal/vertical padding → Use EdgeInsets.symmetric
   - Keep complex asymmetric patterns with EdgeInsets.only + AppSpacing tokens

5. **Replace SizedBox widths:**
   - Similar to heights, map to nearest AppSpacing token

6. **Verify:** Build and visually inspect changes
   - Check layout consistency
   - Ensure no broken spacing
   - Compare before/after screenshots if needed

7. **Commit:** Atomic commit per screen
   ```bash
   git add lib/path/to/screen_widget.dart
   git commit -m "feat(04-02): migrate [screen] to AppSpacing tokens

   - Replace N hardcoded SizedBox heights with AppSpacing tokens
   - Convert M fromSTEB patterns to AppSpacing shortcuts
   - Fix X off-grid values (2px→4px, 10px→12px)

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   ```

---

### 3.4 Anti-Patterns to Avoid During Migration

**❌ DON'T: Batch replace without verification**
```dart
// DON'T blindly replace all "16" with "AppSpacing.md"
// Context matters - some 16s might be widget sizes, not spacing
```

**❌ DON'T: Introduce new hardcoded values**
```dart
// BAD - introduced new hardcoded value during refactor
SizedBox(height: 14)  // Should be AppSpacing.sm or md
```

**❌ DON'T: Skip off-grid normalization**
```dart
// BAD - kept off-grid value
SizedBox(height: 2)  // Must round to 4px (AppSpacing.xxs)
```

**❌ DON'T: Over-optimize complex asymmetric padding**
```dart
// BAD - forced symmetry where asymmetric was intentional
padding: EdgeInsets.symmetric(vertical: AppSpacing.md)  // Was 16/24

// GOOD - preserved asymmetric intention
padding: EdgeInsets.only(
  top: AppSpacing.md,
  bottom: AppSpacing.xl,
)
```

**✅ DO: Document intentional deviations**
```dart
// GOOD - documented reason for hardcoded value
const double customHeroSpacing = 100.0;  // Hero section requires exact 100px
SizedBox(height: customHeroSpacing)
```

**✅ DO: Verify layouts don't break**
- Build and run app after each screen migration
- Check for overflow errors
- Compare visual consistency

**✅ DO: Commit atomically per screen**
- One screen per commit for easy rollback
- Clear commit messages with anti-pattern counts

---

## Part 4: File-by-File Checklists

### 4.1 Plan 04-02: Game & Social Screens

**Game Screens Checklist:**

- [ ] `lib/main_function/create_game/create_game_widget.dart`
  - [ ] Replace 17 fromSTEB instances (priority: off-grid 5px, 15px values)
  - [ ] Replace 3 SizedBox heights
  - [ ] Fix off-grid padding patterns
  - [ ] Verify date picker section layout
  - [ ] **Commit:** "feat(04-02): migrate create_game to AppSpacing tokens"

- [ ] `lib/chat_group/game_chat_details/game_chat_details_widget.dart`
  - [ ] Replace 5 SizedBox heights (8px, 16px)
  - [ ] Replace 1 fromSTEB instance
  - [ ] Verify message list spacing
  - [ ] **Commit:** "feat(04-02): migrate game_chat_details to AppSpacing tokens"

- [ ] `lib/main_function/game_joined_detailed/game_joined_detailed_widget.dart`
  - [ ] Replace 4 SizedBox heights (12px player card gaps)
  - [ ] Replace 1 fromSTEB instance
  - [ ] Verify player card internal spacing
  - [ ] **Commit:** "feat(04-02): migrate game_joined_detailed to AppSpacing tokens"

- [ ] `lib/main_function/join_game_detailed/join_game_detailed_widget.dart`
  - [ ] Replace 4 SizedBox heights
  - [ ] Replace 1 fromSTEB instance
  - [ ] Verify game info grid layout
  - [ ] **Commit:** "feat(04-02): migrate join_game_detailed to AppSpacing tokens"

- [ ] `lib/main_function/golfers/golfers_widget.dart`
  - [ ] Replace 3 SizedBox heights (2px, 4px)
  - [ ] Replace 2 fromSTEB instances
  - [ ] Verify golfer list item spacing
  - [ ] **Commit:** "feat(04-02): migrate golfers to AppSpacing tokens"

- [ ] `lib/main_function/player_list/player_list_widget.dart`
  - [ ] Replace 1 fromSTEB with off-grid 10px → AppSpacing.xs or sm
  - [ ] Verify player list layout
  - [ ] **Commit:** "feat(04-02): migrate player_list to AppSpacing tokens"

- [ ] `lib/main_function/games_list/games_list_widget.dart`
  - [ ] Audit for any remaining hardcoded values
  - [ ] Spot check AppSpacing usage consistency
  - [ ] **Commit:** "feat(04-02): audit games_list spacing (mostly compliant)"

- [ ] `lib/main_function/games_joined/games_joined_widget.dart`
  - [ ] Spot check for hardcoded spacing
  - [ ] **Commit:** (if changes needed) "feat(04-02): migrate games_joined to AppSpacing tokens"

- [ ] `lib/main_function/join_game/join_game_widget.dart`
  - [ ] Spot check for hardcoded spacing
  - [ ] **Commit:** (if changes needed) "feat(04-02): migrate join_game to AppSpacing tokens"

**Social Screens Checklist:**

- [ ] `lib/friends/tab_friends/tab_friends_widget.dart`
  - [ ] Replace 3 SizedBox heights (4px name/subtitle gaps)
  - [ ] Replace 6 fromSTEB instances
  - [ ] Verify friend list item spacing
  - [ ] Verify friend card internal layout
  - [ ] **Commit:** "feat(04-02): migrate tab_friends to AppSpacing tokens"

- [ ] `lib/main_function/become_friends/become_friends_widget.dart`
  - [ ] Replace 3 fromSTEB instances
  - [ ] Verify friend request card layout
  - [ ] **Commit:** "feat(04-02): migrate become_friends to AppSpacing tokens"

- [ ] `lib/main_function/community/community_widget.dart`
  - [ ] Replace 2 fromSTEB instances
  - [ ] Verify community content sections
  - [ ] **Commit:** "feat(04-02): migrate community to AppSpacing tokens"

- [ ] `lib/friends/components/premium_friend_card.dart`
  - [ ] Replace 1 SizedBox height
  - [ ] Verify premium card internal spacing
  - [ ] **Commit:** "feat(04-02): migrate premium_friend_card to AppSpacing tokens"

- [ ] `lib/friends/components/friend_filter_bottom_sheet.dart`
  - [ ] Spot check for hardcoded spacing
  - [ ] **Commit:** (if changes needed) "feat(04-02): migrate friend_filter_bottom_sheet to AppSpacing tokens"

- [ ] `lib/friends/components/grouped_friends_list.dart`
  - [ ] Spot check for hardcoded spacing
  - [ ] **Commit:** (if changes needed) "feat(04-02): migrate grouped_friends_list to AppSpacing tokens"

---

### 4.2 Plan 04-03: Profile & Auth Screens

**Auth Screens Checklist (CRITICAL PRIORITY):**

- [ ] `lib/user_auth/sign_up_account/sign_up_account_widget.dart`
  - [ ] Replace 13 fromSTEB instances (CRITICAL: many off-grid values)
  - [ ] Fix off-grid 10px, 15px padding
  - [ ] Convert horizontal/vertical patterns to AppSpacing shortcuts
  - [ ] Verify form field spacing
  - [ ] Verify button layout
  - [ ] **Commit:** "feat(04-03): migrate sign_up_account to AppSpacing tokens"

- [ ] `lib/user_auth/sign_in/sign_in_widget.dart`
  - [ ] Replace 13 fromSTEB instances (CRITICAL)
  - [ ] Convert horizontal/vertical patterns to AppSpacing shortcuts
  - [ ] Verify form layout consistency with sign_up_account
  - [ ] **Commit:** "feat(04-03): migrate sign_in to AppSpacing tokens"

- [ ] `lib/user_auth/recover_password/recover_password_widget.dart`
  - [ ] Replace 7 fromSTEB instances
  - [ ] Verify form layout consistency with other auth screens
  - [ ] **Commit:** "feat(04-03): migrate recover_password to AppSpacing tokens"

**Profile Screens Checklist:**

- [ ] `lib/profile/main_profile/main_profile_widget.dart`
  - [ ] Replace 3 SizedBox heights (2px bio/stats gaps)
  - [ ] Fix off-grid 2px → 4px (AppSpacing.xxs)
  - [ ] Verify bio section internal spacing
  - [ ] Verify stats cards spacing
  - [ ] **Commit:** "feat(04-03): migrate main_profile to AppSpacing tokens"

- [ ] `lib/profile/profile_user_firebase_widget.dart`
  - [ ] Replace 2 SizedBox heights
  - [ ] Replace 1 fromSTEB instance
  - [ ] Verify user profile card layout
  - [ ] **Commit:** "feat(04-03): migrate profile_user_firebase to AppSpacing tokens"

- [ ] `lib/profile/edit_profile/edit_profile_widget.dart`
  - [ ] Replace 1 SizedBox height (form label gap)
  - [ ] Verify form consistency
  - [ ] **Commit:** "feat(04-03): migrate edit_profile to AppSpacing tokens"

- [ ] `lib/profile/edit_vibes/edit_vibes_widget.dart`
  - [ ] Spot check for hardcoded spacing
  - [ ] **Commit:** (if changes needed) "feat(04-03): migrate edit_vibes to AppSpacing tokens"

- [ ] `lib/profile/create_profile/create_profile_widget.dart`
  - [ ] Spot check for hardcoded spacing
  - [ ] **Commit:** (if changes needed) "feat(04-03): migrate create_profile to AppSpacing tokens"

- [ ] `lib/profile/home/home_widget.dart`
  - [ ] Spot check for hardcoded spacing
  - [ ] **Commit:** (if changes needed) "feat(04-03): migrate home to AppSpacing tokens"

- [ ] `lib/profile/change_photo/change_photo_widget.dart`
  - [ ] Spot check for hardcoded spacing
  - [ ] **Commit:** (if changes needed) "feat(04-03): migrate change_photo to AppSpacing tokens"

---

### 4.3 Non-Screen Files (Lower Priority)

**Example Files (Plan 04-02 or 04-03 as time permits):**

- [ ] `lib/core/widgets/app_button_examples.dart` - 17 SizedBox heights
- [ ] `lib/core/widgets/fairway_background_examples.dart` - 15 SizedBox heights
- [ ] `lib/core/widgets/app_list_tile_examples.dart` - 1 SizedBox height
- [ ] `lib/core/design_patterns/premium_ui_patterns.dart` - 2 SizedBox heights
- [ ] `lib/core/widgets/app_card.dart` - 1 SizedBox height

**Component Files:**

- [ ] `lib/components/date_format_widget.dart` - 3 fromSTEB instances
- [ ] `lib/chat_group/empty_state_simple/empty_state_simple_widget.dart` - 2 fromSTEB
- [ ] `lib/user_onboarding/progressive_onboarding_widget.dart` - 1 fromSTEB

**Utility Files:**

- [ ] `lib/utils/upload_data.dart` - 1 SizedBox height
- [ ] `lib/core/video_player.dart` - 1 SizedBox height

**Note:** Example and utility files are lower priority but should be migrated for completeness

---

## Part 5: Verification & Success Metrics

### 5.1 Pre-Migration Baseline

**Captured 2026-01-20:**

| Metric | Current Value |
|--------|--------------|
| AppSpacing token usage | 1,017 instances |
| Hardcoded SizedBox heights | 69 instances |
| Hardcoded SizedBox widths | 37 instances |
| EdgeInsetsDirectional.fromSTEB | 74 instances |
| Off-grid values (2px, 6px, 10px, etc.) | 31 instances |
| Total anti-patterns | 180 instances |
| Token adoption rate | ~85% |

### 5.2 Post-Migration Targets

**End of Phase 4 (Plans 04-01, 04-02, 04-03):**

| Metric | Target Value | Success Threshold |
|--------|-------------|------------------|
| AppSpacing token usage | 1,150+ instances | 90%+ adoption |
| Hardcoded SizedBox heights | <10 instances | <5% of original |
| Hardcoded SizedBox widths | <5 instances | <14% of original |
| EdgeInsetsDirectional.fromSTEB | <10 instances | <14% of original |
| Off-grid values | 0 instances | 100% eliminated |
| Total anti-patterns | <25 instances | <14% of original |
| Token adoption rate | 95%+ | 10% improvement |

### 5.3 Verification Commands

**Run after each plan to track progress:**

```bash
# Count AppSpacing token usage
grep -r "AppSpacing\." lib/ --include="*.dart" | wc -l

# Count remaining hardcoded SizedBox heights
grep -r "SizedBox(height: [0-9]" lib/ --include="*.dart" | wc -l

# Count remaining hardcoded SizedBox widths
grep -r "SizedBox(width: [0-9]" lib/ --include="*.dart" | wc -l

# Count remaining fromSTEB usage
grep -r "EdgeInsetsDirectional.fromSTEB" lib/ --include="*.dart" | wc -l

# Count off-grid values
grep -rn "SizedBox(height: 2\|SizedBox(height: 6\|SizedBox(height: 10\|SizedBox(height: 14\|SizedBox(height: 18\|SizedBox(width: 2\|SizedBox(width: 6\|SizedBox(width: 10" lib/ --include="*.dart" | wc -l

# Files with most remaining issues
for file in $(grep -rl "SizedBox(height: [0-9]" lib/ --include="*.dart"); do
  echo "$(grep -c "SizedBox(height: [0-9]" "$file") $file";
done | sort -rn | head -10
```

### 5.4 Visual Verification Checklist

**For each migrated screen:**

- [ ] Build succeeds with no errors
- [ ] No overflow/layout errors in debug console
- [ ] Visual spacing looks consistent with pre-migration
- [ ] Vertical rhythm feels harmonious (no jarring gaps)
- [ ] Card padding looks balanced
- [ ] List item spacing feels comfortable
- [ ] Form field gaps are appropriate
- [ ] Button spacing matches design system
- [ ] No broken layouts on different screen sizes

### 5.5 Adoption Metrics Report

**Create after Plans 04-02 and 04-03 complete:**

**ADOPTION-METRICS.md format:**

```markdown
# Phase 4 Spacing System Adoption Metrics

## Summary
- **Baseline:** 85% token adoption, 180 anti-patterns
- **Current:** [X]% token adoption, [Y] anti-patterns
- **Improvement:** +[Z]% adoption, [W] anti-patterns eliminated

## Detailed Metrics
| Metric | Baseline | Current | Change | Target Met? |
|--------|----------|---------|--------|-------------|
| AppSpacing usage | 1,017 | [X] | +[Y] | ✅/❌ |
| Hardcoded SizedBox heights | 69 | [X] | -[Y] | ✅/❌ |
| ... | ... | ... | ... | ... |

## Remaining Issues
[List any remaining anti-patterns with justification]

## Visual Impact
[Screenshot comparisons or notes on layout improvements]
```

---

## Part 6: Reference

### 6.1 AppSpacing Token Quick Reference

| Token | Value | Use Case |
|-------|-------|----------|
| AppSpacing.xxs | 4px | Minimum unit, icon padding, micro gaps |
| AppSpacing.xs | 8px | Tight spacing, icon-text gap, chip spacing |
| AppSpacing.sm | 12px | Compact lists, small component padding, form fields |
| AppSpacing.md | 16px | Default spacing, comfortable separation |
| AppSpacing.lg | 20px | Screen padding, medium-large breathing room |
| AppSpacing.xl | 24px | Section spacing, card padding, list item padding |
| AppSpacing.xxl | 32px | Major section breaks, screen margins |
| AppSpacing.xxxl | 48px | Large section breaks, hero padding |
| AppSpacing.xxxxl | 64px | Hero sections, full-screen padding |

### 6.2 AppSpacing Shortcuts

**EdgeInsets Shortcuts:**
- `AppSpacing.allXxs` → `EdgeInsets.all(4)`
- `AppSpacing.allXs` → `EdgeInsets.all(8)`
- `AppSpacing.allSm` → `EdgeInsets.all(12)`
- `AppSpacing.allMd` → `EdgeInsets.all(16)`
- `AppSpacing.allLg` → `EdgeInsets.all(20)`
- `AppSpacing.allXl` → `EdgeInsets.all(24)`
- `AppSpacing.horizontalMd` → `EdgeInsets.symmetric(horizontal: 16)`
- `AppSpacing.horizontalLg` → `EdgeInsets.symmetric(horizontal: 20)`
- `AppSpacing.verticalXs` → `EdgeInsets.symmetric(vertical: 8)`
- `AppSpacing.verticalSm` → `EdgeInsets.symmetric(vertical: 12)`
- `AppSpacing.verticalMd` → `EdgeInsets.symmetric(vertical: 16)`
- `AppSpacing.screen` → `EdgeInsets.symmetric(horizontal: 20, vertical: 20)`
- `AppSpacing.card` → `EdgeInsets.all(20)`
- `AppSpacing.modal` → `EdgeInsets.all(24)`

**SizedBox Shortcuts:**
- `AppSpacing.verticalXxs` → `SizedBox(height: 4)`
- `AppSpacing.verticalXsBox` → `SizedBox(height: 8)`
- `AppSpacing.verticalSmBox` → `SizedBox(height: 12)`
- `AppSpacing.verticalMdBox` → `SizedBox(height: 16)`
- `AppSpacing.verticalLgBox` → `SizedBox(height: 20)`
- `AppSpacing.verticalXlBox` → `SizedBox(height: 24)`
- `AppSpacing.horizontalXxs` → `SizedBox(width: 4)`
- `AppSpacing.horizontalXsBox` → `SizedBox(width: 8)`
- `AppSpacing.horizontalSmBox` → `SizedBox(width: 12)`
- `AppSpacing.horizontalMdBox` → `SizedBox(width: 16)`

**Semantic Constants:**
- `AppSpacing.iconTextGap` → 8px
- `AppSpacing.buttonGap` → 12px
- `AppSpacing.cardGap` → 16px
- `AppSpacing.listItemGap` → 16px
- `AppSpacing.formFieldGap` → 16px
- `AppSpacing.screenPadding` → 20px

### 6.3 Migration Commands

**Search for anti-patterns:**
```bash
# Find hardcoded SizedBox heights
grep -rn "SizedBox(height: [0-9]" lib/path/to/file.dart

# Find hardcoded SizedBox widths
grep -rn "SizedBox(width: [0-9]" lib/path/to/file.dart

# Find fromSTEB patterns
grep -rn "EdgeInsetsDirectional.fromSTEB" lib/path/to/file.dart

# Find off-grid values
grep -rn "height: 2\|height: 6\|height: 10\|width: 2\|width: 6\|width: 10" lib/path/to/file.dart
```

**Count anti-patterns project-wide:**
```bash
# Total hardcoded heights
grep -r "SizedBox(height: [0-9]" lib/ --include="*.dart" | wc -l

# Total fromSTEB
grep -r "EdgeInsetsDirectional.fromSTEB" lib/ --include="*.dart" | wc -l

# Total AppSpacing usage
grep -r "AppSpacing\." lib/ --include="*.dart" | wc -l
```

**Find highest priority files:**
```bash
# Files with most SizedBox anti-patterns
for file in $(grep -rl "SizedBox(height: [0-9]" lib/ --include="*.dart"); do
  echo "$(grep -c "SizedBox(height: [0-9]" "$file") $file";
done | sort -rn | head -10

# Files with most fromSTEB anti-patterns
for file in $(grep -rl "EdgeInsetsDirectional.fromSTEB" lib/ --include="*.dart"); do
  echo "$(grep -c "EdgeInsetsDirectional.fromSTEB" "$file") $file";
done | sort -rn | head -10
```

---

## Conclusion

This migration guide provides a comprehensive roadmap for achieving 90%+ AppSpacing token adoption. The key to success is:

1. **Systematic approach:** Fix off-grid values first, then common patterns
2. **Atomic commits:** One screen per commit for easy rollback
3. **Visual verification:** Build and test after each migration
4. **Avoid anti-patterns:** Don't introduce new hardcoded values
5. **Track progress:** Use verification commands to measure improvement

**Plans 04-02 and 04-03 have clear execution checklists** with prioritized file lists, anti-pattern counts, and commit message templates. Follow this guide for consistent, high-quality migrations.

**Expected outcome:** Visually consistent spacing across all screens, maintainable codebase with token-based spacing, foundation for future design system enhancements.
