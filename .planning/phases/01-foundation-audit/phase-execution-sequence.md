# Phase 2-5 Execution Sequence

**Created:** 2026-01-15
**Purpose:** Map standardization themes to Phase 2-5 execution with clear sequencing and dependencies
**Source:** `standardization-themes.md` + ROADMAP.md phase goals

## Overview

This document provides the recommended execution order for Phases 2-5, mapping the 10 standardization themes to appropriate phases and sequencing them based on dependencies, impact, and complexity.

---

## Phase 2: Component Library Standardization (4 plans)

**Goal:** Establish unified component library with consistent variants for buttons, cards, inputs, and all reusable UI elements

### Recommended Execution Order

#### Plan 02-01: Foundation Tokens + Button Standardization
**Themes:** Theme 1 (Missing Tokens), Theme 7 (Legacy Button Deprecation)

**Rationale:** Tokens must exist before component migration can succeed. Bundling with button work since buttons are most mature component type.

**Work:**
1. Create AppBorderRadius tokens (xxs through full)
2. Create AppElevation shadow presets (elevationNone through elevationXl, glowGold, glowGreen)
3. Create AppOpacity semantic scale (subtle through opaque)
4. Create AppIconSize scale (xs through xxl)
5. Create AppDuration animation tokens (instant through slow)
6. Mark AppButton as @Deprecated with migration guide
7. Add missing AppButtonEnhanced variants (destructive, danger)
8. Migrate 5-10 screens from AppButton → AppButtonEnhanced as proof

**Dependencies:** None (foundation work)

**Expected Outcome:**
- All 5 token systems exist and documented
- Button standardization complete
- Migration path clear for screens
- 5-10 screens using new tokens

---

#### Plan 02-02: Card Standardization + Component Duplication Cleanup
**Themes:** Theme 5 (Component Duplication), Theme 10 (Shadows/Gradients)

**Rationale:** AppCard exists but underutilized. Adding variants enables massive duplication cleanup (1,500+ lines from premium card pattern alone).

**Work:**
1. Add AppCard variants: premium, glass, minimal (currently only has filled, outlined, elevated)
2. Update AppCard to use new AppBorderRadius and AppElevation tokens
3. Update AppCard to use AppColors gradients (not inline definitions)
4. Migrate premium card pattern (30+ instances) to AppCard.premium
5. Migrate simple overlay cards (40+ instances) to AppCard.outlined or AppCard.glass
6. Create AppIconBadge component (replace 25+ icon container duplications)
7. Create AppSectionHeader component (replace 20+ section header duplications)

**Dependencies:** 02-01 (needs border radius and elevation tokens)

**Expected Outcome:**
- 60+ inline cards migrated to AppCard variants
- ~1,800 lines of duplicate code eliminated
- Consistent card styling across app
- Visual polish improved (consistent shadows, gradients)

---

#### Plan 02-03: Input Components + Missing Core Components Part 1
**Themes:** Theme 6 (Missing Core Components - AppTextField, AppBadge)

**Rationale:** Forms and inputs need standardization before broader screen refactoring. AppTextField is second-highest priority missing component.

**Work:**
1. Create AppTextField component with variants (outlined, filled, underlined, search)
2. Integrate AppTextField with AppBorderRadius, AppElevation, AppTypography, AppColors
3. Add validation states, error styling, helper text support
4. Create AppBadge component with semantic variants (default, primary, success, warning, error, info)
5. Add AppBadge sizes (small, medium, large) and special variants (count, dot)
6. Migrate chat input, search bars, and 3-5 forms to AppTextField as proof
7. Migrate status indicators in game_joined_detailed to AppBadge

**Dependencies:** 02-01 (needs tokens)

**Expected Outcome:**
- AppTextField and AppBadge components created
- 20+ forms/inputs can now use AppTextField
- Consistent input styling
- Status indicators standardized

---

#### Plan 02-04: Missing Core Components Part 2 + State Management
**Themes:** Theme 6 (AppListTile, AppAvatar, AppEmptyState), Theme 8 (StreamBuilder Boilerplate)

**Rationale:** AppListTile is HIGHEST priority (affects 50+ screens). Completing core components unlocks Phase 3-5 screen migrations.

**Work:**
1. Create AppListTile component with variants (standard, compact, card, highlighted)
2. Create AppAvatar component with sizes (xs through xxl) and shapes (circle, square, rounded)
3. Create AppEmptyState component (icon, title, message, optional action)
4. Create AppLoadingState component (replace 22 SpinKit duplications)
5. Create AppStreamBuilder<T> wrapper (handles loading/errors/parsing automatically)
6. Create AppInfoGrid component (replace 15+ info grid duplications)
7. Migrate 3-5 list screens to AppListTile as proof
8. Migrate 2-3 StreamBuilder instances to AppStreamBuilder as proof

**Dependencies:** 02-01 (needs tokens), 02-02 (AppAvatar might need AppCard for some layouts)

**Expected Outcome:**
- All 6 core missing components created
- 50+ list screens can now use AppListTile
- StreamBuilder boilerplate reduced from 100 lines to ~10
- ~3,000+ lines of duplicate code can be eliminated in Phase 3-5

---

### Phase 2 Dependencies Map
```
02-01 (Tokens + Button)
  ↓
  ├─> 02-02 (Cards + Duplication Cleanup)
  ├─> 02-03 (Inputs + Missing Core Part 1)
  └─> 02-04 (Missing Core Part 2 + State)
       ↑
       02-02 (minor dependency for AppAvatar)
```

### Phase 2 Success Criteria
- [ ] All 5 token systems created (border radius, elevation, opacity, icon size, duration)
- [ ] AppCard enhanced with premium/glass variants
- [ ] 6 core missing components created (AppTextField, AppBadge, AppListTile, AppAvatar, AppEmptyState, AppLoadingState)
- [ ] AppStreamBuilder and AppInfoGrid wrappers created
- [ ] AppButton marked deprecated
- [ ] 10-15 screens migrated as proof of concept
- [ ] ~2,000+ lines of duplicate code eliminated

---

## Phase 3: Typography System (3 plans)

**Goal:** Apply consistent text hierarchy throughout the app for optimal readability and visual hierarchy

### Recommended Execution Order

#### Plan 03-01: Typography Migration Strategy + Worst Offenders
**Themes:** Theme 2 (Typography Token Adoption)

**Rationale:** Create systematic approach before mass migration. Fix worst offenders first to establish pattern.

**Work:**
1. Create automated refactor script for common patterns:
   - Hardcoded fontSize → AppTypography mapping
   - GoogleFonts.outfit() → AppTypography styles
   - AppTheme.override anti-pattern → AppTypography with modifiers
2. Document semantic hierarchy standards:
   - Screen titles: headlineMedium (24px)
   - Section headers: titleLarge (20px) or titleMedium (18px)
   - Body text: bodyMedium (16px), bodySmall (14px)
   - Captions/labels: labelSmall/caption (12px)
3. Fix worst offenders (15-25% compliant):
   - create_profile_widget.dart (16+ hardcoded sizes)
   - sign_up_account_widget.dart (heavy AppTheme.override)
   - game_chat_details_widget.dart (10-32px range)
4. Create linter rules to prevent hardcoded fontSize

**Dependencies:** None (can run parallel to Phase 2, but ideally after 02-01 if time allows)

**Expected Outcome:**
- Automated refactor script ready
- Semantic hierarchy documented
- 3 worst screens fixed (15% → 80%+ compliant)
- Linter rules active
- Migration pattern proven

---

#### Plan 03-02: Game and Social Screens Typography Migration
**Themes:** Theme 2 (Typography Token Adoption)

**Rationale:** Game screens are highest visibility, social screens second. Together represent ~50% of user time.

**Work:**
1. Run automated refactor script on:
   - create_game_widget.dart (13+ hardcoded sizes)
   - game_joined_detailed_widget.dart (some legacy)
   - join_game_detailed_widget.dart (similar to game_joined)
   - games_list_widget.dart (70% compliant → 90%)
   - tab_friends_widget.dart (40% compliant)
   - golfers_widget.dart (35% compliant)
   - community_widget.dart (55% compliant)
2. Manual fixes for edge cases
3. Verify visual hierarchy correctness
4. Test on devices for readability

**Dependencies:** 03-01 (needs refactor script and standards)

**Expected Outcome:**
- 7 major screens migrated
- Game/social features have consistent typography
- Adoption jumps from ~50% to ~70% app-wide

---

#### Plan 03-03: Profile, Auth, and Remaining Screens Typography Migration
**Themes:** Theme 2 (Typography Token Adoption)

**Rationale:** Complete typography migration across all remaining screens.

**Work:**
1. Run refactor script on profile screens:
   - main_profile_widget.dart (60% compliant)
   - edit_profile_widget.dart (25% compliant)
   - edit_vibes_widget.dart (30% compliant)
2. Run refactor script on auth screens:
   - recover_password_widget.dart (30% compliant)
3. Run refactor script on newsfeed screens:
   - blog_create_widget.dart (35% compliant, 26px headers)
   - blog_edit_widget.dart (similar)
4. Run refactor script on chat screens:
   - chat_widget.dart (35% compliant)
5. Sweep all remaining screens
6. Verify 85%+ adoption target met

**Dependencies:** 03-02 (sequential migration for pattern consistency)

**Expected Outcome:**
- All screens migrated
- 85%+ AppTypography adoption achieved
- Consistent heading hierarchy app-wide
- Proper font families (Fraunces displays, Manrope body, DM Mono data)

---

### Phase 3 Dependencies Map
```
03-01 (Strategy + Worst Offenders)
  ↓
03-02 (Game/Social Screens)
  ↓
03-03 (Profile/Auth/Remaining)
```

### Phase 3 Success Criteria
- [ ] Typography adoption: 50% → 85%+
- [ ] All hardcoded fontSize values eliminated
- [ ] All GoogleFonts.outfit() calls replaced with AppTypography
- [ ] All AppTheme.override anti-patterns eliminated
- [ ] Consistent heading hierarchy across all screens
- [ ] Linter rules prevent regression
- [ ] Screen titles consistent (headlineMedium)
- [ ] Section headers consistent (titleLarge/titleMedium)

---

## Phase 4: Spacing System (3 plans)

**Goal:** Implement systematic spacing using design tokens for harmonious layouts across all screens

### Recommended Execution Order

#### Plan 04-01: Spacing Migration Strategy + Quick Wins
**Themes:** Theme 4 (Spacing Token Migration)

**Rationale:** Spacing is 50-60% adopted already (AppSpacing exists), but 250+ hardcoded instances remain. Quick wins build momentum.

**Work:**
1. Create automated find/replace rules:
   - SizedBox(height: 2) → SizedBox(height: AppSpacing.xxs) [Note: 2→4px]
   - SizedBox(height: 4) → SizedBox(height: AppSpacing.xxs)
   - SizedBox(height: 8) → SizedBox(height: AppSpacing.xs)
   - SizedBox(height: 12) → SizedBox(height: AppSpacing.sm)
   - SizedBox(height: 16) → SizedBox(height: AppSpacing.md)
   - EdgeInsetsDirectional.fromSTEB(16,0,16,0) → EdgeInsets.symmetric(horizontal: AppSpacing.md)
   - etc.
2. Document off-grid rounding decisions:
   - 2px → 4px (accept slight increase for grid alignment)
   - 6px → 4px or 8px (context dependent)
   - 10px → 8px or 12px (context dependent)
   - 15px → 12px or 16px (context dependent)
3. Fix worst offender (sign_up_account_widget.dart - 21+ fromSTEB instances)
4. Document padding/margin conventions
5. Create linter rule to prevent hardcoded spacing

**Dependencies:** None (can run parallel to Phase 2-3)

**Expected Outcome:**
- Automated refactor rules ready
- Off-grid rounding decisions documented
- 1 worst screen fixed (21+ violations)
- Linter rules active
- Migration pattern proven

---

#### Plan 04-02: Game and Social Screens Spacing Migration
**Themes:** Theme 4 (Spacing Token Migration)

**Rationale:** Same as typography - highest visibility screens first.

**Work:**
1. Run automated spacing refactor on:
   - create_game_widget.dart (hardcoded SizedBox heights, some off-grid)
   - game_joined_detailed_widget.dart (SizedBox(height: 2, 12) throughout)
   - join_game_detailed_widget.dart (similar)
   - games_list_widget.dart (mixed token usage)
   - tab_friends_widget.dart (heavy SizedBox(height: 4) usage)
   - golfers_widget.dart (mixed 2px, 4px)
   - community_widget.dart (better but some hardcoded)
   - game_chat_details_widget.dart (extensive hardcoded: 8, 4, 16px)
2. Manual fixes for complex cases
3. Verify visual rhythm intact
4. Test layouts on different screen sizes

**Dependencies:** 04-01 (needs refactor rules and rounding decisions)

**Expected Outcome:**
- 8 major screens migrated
- Game/social features have consistent spacing
- Adoption jumps from ~50-60% to ~80% app-wide

---

#### Plan 04-03: Profile, Auth, and Remaining Screens Spacing Migration
**Themes:** Theme 4 (Spacing Token Migration)

**Rationale:** Complete spacing migration across all remaining screens.

**Work:**
1. Run spacing refactor on profile screens:
   - main_profile_widget.dart (SizedBox(height: 2) in bio/stats cards)
   - edit_profile_widget.dart (similar)
2. Run spacing refactor on auth screens:
   - recover_password_widget.dart
3. Run spacing refactor on chat screens:
   - chat_widget.dart
4. Sweep all remaining screens
5. Verify 90%+ adoption target met
6. Audit that all spacing is on-grid (no 2px, 6px, 10px, 15px)

**Dependencies:** 04-02 (sequential migration)

**Expected Outcome:**
- All screens migrated
- 90%+ AppSpacing adoption achieved
- All spacing on 4px/8px grid
- Consistent vertical rhythm app-wide
- EdgeInsetsDirectional.fromSTEB minimized

---

### Phase 4 Dependencies Map
```
04-01 (Strategy + Quick Wins)
  ↓
04-02 (Game/Social Screens)
  ↓
04-03 (Profile/Auth/Remaining)
```

### Phase 4 Success Criteria
- [ ] Spacing adoption: 50-60% → 90%+
- [ ] All SizedBox hardcoded heights eliminated
- [ ] EdgeInsetsDirectional.fromSTEB replaced with AppSpacing shortcuts
- [ ] All spacing on-grid (4px base)
- [ ] Linter rules prevent regression
- [ ] Consistent vertical rhythm across all screens
- [ ] Padding/margin conventions documented and followed

---

## Phase 5: Screen Flow Polish (3 plans)

**Goal:** Ensure smooth, predictable navigation with consistent transitions across all user journeys

### Recommended Execution Order

#### Plan 05-01: Navigation Audit + Color System Cleanup
**Themes:** Theme 3 (Color System Cleanup)

**Rationale:** While primarily about nav/transitions, this is opportune time to finish color cleanup since we'll be touching many screens. Color cleanup is prerequisite for dark mode.

**Work:**
1. Audit all navigation transitions (consistent animations?)
2. Audit page route definitions (GoRouter patterns)
3. Fix player_list_widget.dart custom colors (CRITICAL - 13 hardcoded hex):
   - Map custom greens to AppColors.fairway family
   - Map custom greys to AppColors.neutral family
   - Add AppColors.successLight if needed for mint green
4. Replace remaining hardcoded hex colors (21 total):
   - sign_up/sign_in screens
   - notification_page, change_photo, create_game
5. Replace Colors.white/black.withOpacity() with semantic AppColors
6. Resolve AppTheme vs AppColors (deprecate AppTheme or make it wrap AppColors)
7. Create linter rule to prevent hardcoded Color(0xFFXXXXXX)

**Dependencies:** Phase 2-4 (easier to nav audit after components/typography/spacing standardized)

**Expected Outcome:**
- Navigation patterns documented
- Color adoption: 80% → 95%+
- player_list dark-mode ready
- AppTheme decision made
- Zero hardcoded hex colors

---

#### Plan 05-02: Game Creation and Joining Flow Polish
**Themes:** Theme 9 (Specialized Components)

**Rationale:** Game flows are core user journey. Polish here has massive UX impact.

**Work:**
1. Polish create_game flow:
   - Consistent page transitions
   - Loading states standardized (use AppLoadingState)
   - Validation feedback consistent
   - Success/error states polished
2. Polish game joining flow:
   - Smooth join_game_detailed → game_joined_detailed transition
   - Optimistic UI updates
   - Loading states
3. Polish game discovery flow:
   - games_list filtering/search
   - Empty states (use AppEmptyState)
4. Ensure all game flows use new components from Phase 2

**Dependencies:** 05-01 (nav patterns), Phase 2-4 (components/typography/spacing)

**Expected Outcome:**
- Game flows feel smooth and responsive
- Consistent transitions throughout
- Loading/empty states polished
- High user satisfaction

---

#### Plan 05-03: Chat, Profile, and Friend Management Flow Polish
**Themes:** Theme 9 (Specialized Components)

**Rationale:** Complete remaining flows for full app polish.

**Work:**
1. Polish chat flows:
   - Message sending feedback
   - Loading states
   - Empty states for no messages
2. Polish profile flows:
   - Edit profile transitions
   - Photo upload feedback
   - Success/error states
3. Polish friend management flows:
   - Add/remove friend feedback
   - Friend request states
   - Notifications
4. Audit all modals/dialogs for consistency
5. Final pass on all screen transitions

**Dependencies:** 05-02 (sequential for consistency)

**Expected Outcome:**
- All user flows polished
- Consistent feedback throughout
- Smooth transitions everywhere
- App feels cohesive and professional

---

### Phase 5 Dependencies Map
```
Phase 2-4 Complete
  ↓
05-01 (Nav Audit + Color Cleanup)
  ↓
05-02 (Game Flows)
  ↓
05-03 (Chat/Profile/Friend Flows)
```

### Phase 5 Success Criteria
- [ ] Color adoption: 80% → 95%+
- [ ] Zero hardcoded hex colors
- [ ] AppTheme deprecated or wrapped
- [ ] All navigation transitions consistent
- [ ] All loading states use AppLoadingState
- [ ] All empty states use AppEmptyState
- [ ] All user flows feel smooth and polished
- [ ] Dark mode ready (no hardcoded colors blocking)

---

## Cross-Phase Dependencies and Risks

### Critical Path
```
Phase 2 Plan 02-01 (Tokens)
  → Everything else depends on tokens existing
  → MUST complete first

Phase 2 Plan 02-04 (AppListTile + Core Components)
  → Blocks Phase 3-5 screen refactoring
  → High priority completion

Phase 3 Plan 03-01 (Typography Strategy)
  → Blocks Phase 3 completion
  → Can run parallel to Phase 2 if resources allow

Phase 4 Plan 04-01 (Spacing Strategy)
  → Blocks Phase 4 completion
  → Can run parallel to Phase 2-3 if resources allow
```

### Risks and Mitigations

**Risk 1: Token creation incomplete**
- Mitigation: Phase 2 Plan 02-01 is short (just create tokens), high confidence

**Risk 2: AppListTile complexity underestimated**
- Mitigation: Lists are straightforward, Flutter ListTile reference exists, medium confidence

**Risk 3: Automated refactor scripts miss edge cases**
- Mitigation: Manual review after automated refactor, test on devices, medium confidence

**Risk 4: Breaking changes during typography/spacing migrations**
- Mitigation: Thorough testing, visual regression tests if possible, Git for easy rollback

**Risk 5: AppTheme vs AppColors decision delays Phase 5**
- Mitigation: Make decision early in Phase 2 (research in 02-01), implement in 05-01

### Parallelization Opportunities

**Phase 2 and Phase 3 can partially overlap:**
- While 02-02, 02-03, 02-04 run, Phase 3 typography work can begin
- Typography doesn't depend on components, just tokens from 02-01

**Phase 2, Phase 3, and Phase 4 can partially overlap:**
- Spacing work can run parallel to typography
- Both just need tokens from 02-01

**Optimal Schedule (if resources allow):**
```
Week 1-2: Phase 2 Plan 02-01 (Tokens + Button) - SEQUENTIAL
Week 3-4: Phase 2 Plans 02-02, 02-03 - PARALLEL
Week 5-6: Phase 2 Plan 02-04 + Phase 3 Plan 03-01 - PARALLEL
Week 7-8: Phase 3 Plans 03-02, 03-03 + Phase 4 Plan 04-01 - PARALLEL
Week 9-10: Phase 4 Plans 04-02, 04-03 - SEQUENTIAL
Week 11-12: Phase 5 Plans 05-01, 05-02, 05-03 - SEQUENTIAL
```

**Conservative Schedule (sequential):**
```
Week 1-2: Phase 2 Plan 02-01
Week 3-4: Phase 2 Plan 02-02
Week 5-6: Phase 2 Plans 02-03, 02-04 - Can overlap
Week 7-8: Phase 3 Plans 03-01, 03-02
Week 9-10: Phase 3 Plan 03-03 + Phase 4 Plan 04-01
Week 11-12: Phase 4 Plans 04-02, 04-03
Week 13-14: Phase 5 Plans 05-01, 05-02
Week 15-16: Phase 5 Plan 05-03
```

---

## Summary

### Phase 2: Component Library Standardization
- **4 plans:** Foundation tokens, cards, inputs, core components
- **Creates:** 5 token systems, 8 new components, enhances AppCard
- **Impact:** ~2,000+ lines eliminated, 10-15 screens migrated

### Phase 3: Typography System
- **3 plans:** Strategy + worst offenders, game/social, profile/auth/remaining
- **Impact:** 50% → 85%+ adoption, consistent hierarchy, proper fonts

### Phase 4: Spacing System
- **3 plans:** Strategy + quick wins, game/social, profile/auth/remaining
- **Impact:** 50-60% → 90%+ adoption, all on-grid, consistent rhythm

### Phase 5: Screen Flow Polish
- **3 plans:** Nav audit + color cleanup, game flows, chat/profile/friend flows
- **Impact:** 80% → 95%+ color adoption, smooth transitions, polished UX, dark mode ready

### Total Estimated Effort
- **12 plans** across 4 phases
- **12-16 weeks** (conservative schedule)
- **~5,000 lines** of duplicate code eliminated
- **Massive** consistency improvement
- **Ready** for Phase 6 (Large Widget Refactoring) and Phase 7 (Tech Debt Cleanup)
