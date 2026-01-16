# Standardization Roadmap

**Created:** 2026-01-15
**Status:** Ready for Phase 2 Execution
**Purpose:** Comprehensive guide for Phase 2-5 standardization work

---

## Executive Summary

The Find My Fourth app has a **solid foundation** but suffers from **incomplete adoption** of its design system. This roadmap transforms the app from 40% component usage and inconsistent patterns to a polished, maintainable codebase with 65%+ component usage and systematic design token application.

### Key Findings from Audit

**Strengths:**
- ✅ **AppSpacing:** 100% adoption (success story - proves tokens work)
- ✅ **Design Tokens:** Comprehensive color, typography, and spacing systems exist
- ✅ **Modern Components:** AppButtonEnhanced, AppCard, FairwayBackground are production-grade
- ✅ **Thematic Consistency:** Strong golf/country club aesthetic ("Fairway Sunset" colors, "Elevated Country Club Modernism" typography)

**Gaps:**
- ❌ **Missing Tokens:** Border radius, elevation, opacity, icon size, animation duration (blocks component standardization)
- ❌ **Missing Components:** AppListTile, AppTextField, AppAvatar, AppBadge (blocks screen refactoring)
- ⚠️ **Typography Adoption:** 50% (hardcoded fontSize values, manual GoogleFonts calls)
- ⚠️ **Color Adoption:** 80% (21 hardcoded hex colors, player_list has custom palette)
- ⚠️ **Spacing Adoption:** 50-60% (250+ hardcoded SizedBox heights, off-grid values)
- ⚠️ **Component Duplication:** 5,385 lines of duplicate UI code (premium cards, loading states, list items)

### Impact Assessment

**Current State:**
- Component usage: 40% average (game_joined_detailed is model at 80%, but most screens 30-40%)
- Custom UI: 60% (inline cards, custom list items, duplicate patterns)
- Code quality: 15+ unique shadow definitions, 11 opacity values, 8 border radius values
- Maintenance: Difficult (changes require updating 30+ files individually)

**After Standardization (End of Phase 5):**
- Component usage: 65%+ average
- Custom UI: <35%
- Code quality: Standardized (6 elevation levels, 8 opacity values, 7 border radius values)
- Maintenance: Easy (centralized components, global updates possible)
- **Code reduction:** ~5,000 lines of duplicate code eliminated (90% reduction)

---

## Priority Areas

### Top 3 Standardization Priorities

#### 1. Missing Core Components (HIGHEST IMPACT)
**Why Critical:**
- AppListTile blocks 50+ screens (players, friends, games, community, chat - lists are everywhere)
- AppTextField blocks form standardization (create game, edit profile, auth, chat input)
- Without these, screen refactoring can't proceed

**Work Required:**
- Create AppListTile with variants (standard, compact, card, highlighted)
- Create AppTextField with variants (outlined, filled, underlined, search)
- Create AppAvatar (sizes xs→xxl, shapes circle/square/rounded)
- Create AppBadge (semantic variants: success, warning, error, info)
- Create AppEmptyState and AppLoadingState (replace 37 duplications)

**Expected Impact:**
- Enables refactoring of 50+ screens
- ~3,000+ lines of duplicate code can be eliminated
- Consistent list/form UX across app

**Phase:** 2 (Plans 02-03, 02-04)

---

#### 2. Missing Token Systems (BLOCKS COMPONENT WORK)
**Why Critical:**
- Components can't be standardized without border radius and elevation tokens
- All future component work depends on these existing
- Enables consistent shadows, corners, opacity, icon sizes, animations

**Work Required:**
- Create AppBorderRadius (xxs through full - 7 values)
- Create AppElevation (shadow presets elevationNone through elevationXl + glowGold/glowGreen)
- Create AppOpacity (semantic scale: subtle, light, medium, strong, prominent, heavy)
- Create AppIconSize (xs through xxl - 6 values)
- Create AppDuration (animation timing: instant through slow)

**Expected Impact:**
- Unblocks all Phase 2 component work
- Enables consistent visual depth (shadows)
- Enables harmonious rounding (border radius)
- Replaces 11 arbitrary opacity values with 8 semantic ones

**Phase:** 2 (Plan 02-01)

---

#### 3. Component Duplication Extraction (QUICK WINS)
**Why Critical:**
- Premium card pattern repeated 30+ times (1,500 lines of duplicate code)
- Loading state duplicated 22 times (660 lines)
- User list items duplicated 30+ times (1,800 lines)
- AppCard exists but underutilized (missing premium/glass variants)

**Work Required:**
- Add AppCard variants: premium, glass (currently only has filled, outlined, elevated)
- Migrate 60+ inline cards to AppCard variants
- Create AppLoadingState (replace 22 SpinKit duplications)
- Create AppUserListItem or leverage AppListTile
- Create AppIconBadge, AppSectionHeader, AppInfoGrid (specialized patterns)

**Expected Impact:**
- ~4,000 lines of duplicate code eliminated immediately
- Visual consistency (all premium cards look identical)
- Easy global updates (change gradient once, applies everywhere)

**Phase:** 2 (Plans 02-02, 02-04)

---

### Quick Wins vs Long-Term Refactoring

**Quick Wins (1-2 hours each, high visibility):**
1. Create AppBorderRadius tokens → Immediate consistency
2. Create AppOpacity tokens → Semantic opacity usage
3. Mark AppButton @Deprecated → Prevents new legacy usage
4. Fix player_list_widget.dart colors → Dark mode ready
5. Create AppLoadingState → Replace 22 duplications
6. Create AppEmptyState → Replace 15 duplications
7. Add AppCard.premium variant → Enables 30+ migrations
8. Create linter rule for hardcoded colors → Prevents regression

**Total Quick Win Effort:** ~8.5 hours
**Total Quick Win Impact:** HIGH (visible progress, builds momentum)

**Foundational Work (Must happen first, blocks other work):**
1. Complete 5 token systems → 3 hours → Blocks ALL Phase 2-5
2. Create AppListTile → 4 hours → Blocks MOST Phase 3-5
3. Create AppTextField → 3 hours → Blocks form-heavy screens
4. AppTheme vs AppColors decision → 4 hours → Blocks Phase 5 color cleanup
5. Typography refactor script → 3 hours → Blocks Phase 3 mass migration

**Total Foundation Effort:** ~17 hours
**Total Foundation Impact:** CRITICAL (nothing proceeds without these)

---

## Phase 2-5 Execution Guide

### Phase 2: Component Library Standardization (4 plans)

**Duration:** 4-6 weeks
**Goal:** Unified component library with tokens and all missing core components

#### Plan 02-01: Foundation Tokens + Button Standardization (Week 1-2)
**Work:**
- Create 5 token systems (border radius, elevation, opacity, icon size, duration)
- Deprecate AppButton with migration guide
- Add missing AppButtonEnhanced variants (destructive)
- Migrate 5-10 screens from AppButton → AppButtonEnhanced as proof

**Deliverables:**
- `/lib/core/design_tokens/border_radius.dart`
- `/lib/core/design_tokens/elevation.dart`
- `/lib/core/design_tokens/opacity.dart`
- `/lib/core/design_tokens/icon_size.dart`
- `/lib/core/design_tokens/duration.dart`
- AppButton marked @Deprecated
- Migration guide created

**Success Criteria:**
- ✓ All 5 token systems exist and documented
- ✓ Example usage in 2-3 components proves tokens work
- ✓ IDE warns when developers use AppButton
- ✓ 5-10 screens migrated to AppButtonEnhanced

---

#### Plan 02-02: Card Standardization + Duplication Cleanup (Week 3-4)
**Work:**
- Add AppCard variants: premium, glass, minimal
- Update AppCard to use new tokens (AppBorderRadius, AppElevation)
- Migrate premium card pattern (30+ instances) to AppCard.premium
- Migrate simple overlay cards (40+ instances) to AppCard variants
- Create AppIconBadge (replace 25+ icon containers)
- Create AppSectionHeader (replace 20+ section headers)

**Deliverables:**
- AppCard enhanced with 2-3 new variants
- AppIconBadge component
- AppSectionHeader component
- 60+ inline cards migrated
- ~1,800 lines of duplicate code eliminated

**Success Criteria:**
- ✓ Premium cards consistent (gradient, border, shadow identical)
- ✓ Visual depth consistent (elevation standardized)
- ✓ LOC reduction verified with git diff

---

#### Plan 02-03: Input Components + Missing Core Part 1 (Week 5-6)
**Work:**
- Create AppTextField with variants (outlined, filled, underlined, search)
- Integrate with all relevant tokens
- Add validation states, error styling, helper text
- Create AppBadge with semantic variants and sizes
- Migrate 2-3 forms and chat input to AppTextField as proof
- Migrate status indicators to AppBadge

**Deliverables:**
- AppTextField component
- AppBadge component
- 3-5 forms using AppTextField
- Status indicators using AppBadge

**Success Criteria:**
- ✓ Input styling consistent across app
- ✓ Validation feedback uniform
- ✓ Status badges have clear semantic meaning

---

#### Plan 02-04: Missing Core Part 2 + State Management (Week 7-8)
**Work:**
- Create AppListTile with variants (HIGHEST PRIORITY)
- Create AppAvatar with sizes and shapes
- Create AppEmptyState and AppLoadingState
- Create AppStreamBuilder<T> wrapper
- Create AppInfoGrid
- Migrate 3-5 list screens to AppListTile as proof
- Migrate 2-3 StreamBuilder instances to AppStreamBuilder

**Deliverables:**
- 6 core components created (AppListTile, AppAvatar, AppEmptyState, AppLoadingState, AppStreamBuilder, AppInfoGrid)
- 3-5 list screens migrated
- 2-3 StreamBuilder instances wrapped

**Success Criteria:**
- ✓ List UI consistent across app
- ✓ Loading states uniform
- ✓ Empty states polished
- ✓ StreamBuilder boilerplate reduced 100 lines → 10 lines

---

**Phase 2 Overall Outcome:**
- All missing tokens created
- All missing core components created
- AppCard enhanced
- AppButton deprecated
- ~2,000+ lines of duplicate code eliminated
- 10-15 screens migrated as proof of concept
- Component usage: 40% → ~50%

**Phase 2 Success Metrics:**
- ✓ Token adoption: AppBorderRadius 60%+, AppElevation 60%+, AppOpacity 40%+
- ✓ Component creation: 100% (all 6 core components exist)
- ✓ Code reduction: ~2,000 lines
- ✓ Visual consistency improved (standardized shadows, borders)

---

### Phase 3: Typography System (3 plans)

**Duration:** 3-4 weeks
**Goal:** 50% → 85%+ AppTypography adoption, consistent heading hierarchy

#### Plan 03-01: Strategy + Worst Offenders (Week 1)
**Work:**
- Create automated refactor script (fontSize → AppTypography mapping)
- Document semantic hierarchy standards
- Fix worst offenders (create_profile, sign_up_account, game_chat_details)
- Create linter rules

**Deliverables:**
- Refactor script (`.planning/scripts/refactor-typography.sh`)
- Standards documentation (`.planning/typography-standards.md`)
- 3 worst screens fixed (15% → 80%+ compliant)
- Linter rules active

**Success Criteria:**
- ✓ Script runs without errors
- ✓ Standards documented (screen titles use headlineMedium, etc.)
- ✓ 3 screens proven pattern

---

#### Plan 03-02: Game and Social Screens (Week 2-3)
**Work:**
- Run refactor script on game screens (create_game, game_joined_detailed, join_game_detailed, games_list)
- Run refactor script on social screens (tab_friends, golfers, community)
- Manual fixes for edge cases
- Verify visual hierarchy

**Deliverables:**
- 7 major screens migrated
- Game/social features have consistent typography

**Success Criteria:**
- ✓ Screen titles consistent (all 24px headlineMedium)
- ✓ Section headers consistent (18-20px)
- ✓ Body text consistent (14-16px)

---

#### Plan 03-03: Profile, Auth, and Remaining (Week 4)
**Work:**
- Run refactor script on profile screens (main_profile, edit_profile, edit_vibes)
- Run refactor script on auth screens (recover_password)
- Run refactor script on newsfeed screens (blog_create, blog_edit)
- Run refactor script on chat screens
- Sweep all remaining screens

**Deliverables:**
- All screens migrated
- 85%+ AppTypography adoption

**Success Criteria:**
- ✓ Zero hardcoded fontSize in migrated code
- ✓ Zero GoogleFonts.outfit() calls
- ✓ Proper font families (Fraunces displays, Manrope body)

---

**Phase 3 Overall Outcome:**
- Typography adoption: 50% → 85%+
- Consistent heading hierarchy app-wide
- Proper font families throughout
- Component usage: 50% → ~55% (incremental)

**Phase 3 Success Metrics:**
- ✓ Hardcoded fontSize: ~800 instances → <120 instances
- ✓ GoogleFonts.outfit(): Eliminated
- ✓ Visual hierarchy: Consistent across all screens

---

### Phase 4: Spacing System (3 plans)

**Duration:** 3-4 weeks
**Goal:** 50-60% → 90%+ AppSpacing adoption, all on-grid

#### Plan 04-01: Strategy + Quick Wins (Week 1)
**Work:**
- Create automated refactor rules
- Document off-grid rounding decisions
- Fix worst offender (sign_up_account - 21+ fromSTEB)
- Document padding/margin conventions
- Create linter rule

**Deliverables:**
- Refactor rules documented
- Off-grid decisions documented
- 1 worst screen fixed
- Linter rules active

---

#### Plan 04-02: Game and Social Screens (Week 2-3)
**Work:**
- Run spacing refactor on 8 major screens (create_game, game_joined_detailed, join_game_detailed, games_list, tab_friends, golfers, community, game_chat_details)
- Manual fixes for complex cases
- Verify visual rhythm

**Deliverables:**
- 8 major screens migrated
- Game/social features have consistent spacing

---

#### Plan 04-03: Profile, Auth, and Remaining (Week 4)
**Work:**
- Run spacing refactor on profile/auth/chat screens
- Sweep all remaining screens
- Verify all spacing on-grid

**Deliverables:**
- All screens migrated
- 90%+ AppSpacing adoption

---

**Phase 4 Overall Outcome:**
- Spacing adoption: 50-60% → 90%+
- All spacing on 4px grid
- Consistent vertical rhythm
- Component usage: 55% → ~60% (incremental)

**Phase 4 Success Metrics:**
- ✓ Hardcoded SizedBox: ~250 instances → <25 instances
- ✓ EdgeInsetsDirectional.fromSTEB: ~80 instances → <10 instances
- ✓ Off-grid values: Eliminated

---

### Phase 5: Screen Flow Polish (3 plans)

**Duration:** 3-4 weeks
**Goal:** Color cleanup (95%+), smooth transitions, polished UX

#### Plan 05-01: Navigation Audit + Color Cleanup (Week 1-2)
**Work:**
- Audit navigation transitions and patterns
- Fix player_list_widget.dart custom colors (13 hardcoded hex)
- Replace all remaining hardcoded hex colors (21 total)
- Replace Colors.white/black.withOpacity() with AppColors
- Resolve AppTheme vs AppColors (deprecate AppTheme or make it wrap)
- Create linter rule

**Deliverables:**
- Navigation patterns documented
- Color adoption: 80% → 95%+
- Zero hardcoded hex colors
- AppTheme decision implemented

**Success Criteria:**
- ✓ player_list dark mode ready
- ✓ Color lint rules active
- ✓ Single color system (AppColors)

---

#### Plan 05-02: Game Flow Polish (Week 2-3)
**Work:**
- Polish create_game flow (transitions, loading, validation, success states)
- Polish game joining flow (smooth transitions, optimistic UI)
- Polish game discovery flow (filtering, search, empty states)
- Ensure all game flows use new components

**Deliverables:**
- Game flows smooth and responsive
- Consistent transitions
- Loading/empty states polished

---

#### Plan 05-03: Chat, Profile, Friend Flow Polish (Week 3-4)
**Work:**
- Polish chat flows (message sending, loading, empty)
- Polish profile flows (edit, photo upload, success/error)
- Polish friend management (add/remove, requests, notifications)
- Audit all modals/dialogs
- Final pass on transitions

**Deliverables:**
- All user flows polished
- Smooth transitions everywhere
- App feels cohesive

---

**Phase 5 Overall Outcome:**
- Color adoption: 80% → 95%+
- Zero hardcoded colors
- All flows polished
- Component usage: 60% → 65%+ (TARGET MET)
- Dark mode ready

**Phase 5 Success Metrics:**
- ✓ Hardcoded hex colors: 21 → 0
- ✓ AppTheme deprecated or wrapped
- ✓ All transitions consistent
- ✓ Dark mode testing passes

---

## Success Metrics

### Overall Project Goals

**Token Adoption:**
- AppSpacing: 100% (maintain) ✓
- AppColors: 80% → 95%+ ✓
- AppTypography: 50% → 85%+ ✓
- AppBorderRadius: 0% → 60%+ ✓
- AppElevation: 0% → 60%+ ✓
- AppOpacity: 0% → 40%+ ✓

**Component Usage:**
- Average: 40% → 65%+ ✓
- Custom UI: 60% → <35% ✓

**Code Quality:**
- Unique shadows: 15+ → 6 (AppElevation levels) ✓
- Unique border radius: 8+ → 7 (AppBorderRadius scale) ✓
- Unique opacity: 11+ → 8 (AppOpacity scale) ✓
- Hardcoded colors: 20+ → 0 ✓
- Duplicate code: ~5,385 lines → ~500 lines in components (90% reduction) ✓

**Visual Consistency:**
- Consistency scorecard: 2.5/5 → 4.5/5 ✓
- Heading hierarchy: Consistent ✓
- Spacing rhythm: Consistent ✓
- Color usage: Consistent ✓
- Component appearance: Uniform ✓

### How We'll Measure

**Automated Metrics (Script-based):**
- Run `.planning/scripts/measure-adoption.sh` before/after each phase
- Track token adoption % (grep-based)
- Count hardcoded values (fontSize, Color(0x, SizedBox heights)
- Measure LOC reduction (git diff stat)

**Manual Metrics (Visual Inspection):**
- Pick 10 random screens
- Rate on 5 consistency dimensions (1-5 scale)
- Average scores before/after each phase
- Target: 4.5/5 by end of Phase 5

**Developer Velocity:**
- Track time to add new list screen (2 hours → 30 min)
- Track time to add new form (3 hours → 1 hour)
- Track time to add new card (1 hour → 15 min)

---

## Risks and Mitigations

### Risk 1: Token Creation Incomplete
**Impact:** Blocks all Phase 2-5 work
**Likelihood:** Low
**Mitigation:** Tokens are simple to create (5 files, ~3 hours total). Do in Plan 02-01 first.

### Risk 2: AppListTile Complexity Underestimated
**Impact:** Delays Phase 3-5 screen refactoring
**Likelihood:** Medium
**Mitigation:** Flutter ListTile exists as reference. Variants straightforward. Allocate 4 hours.

### Risk 3: Automated Refactor Scripts Miss Edge Cases
**Impact:** Manual work increases, timeline extends
**Likelihood:** Medium-High
**Mitigation:** Manual review after automated refactor. Test on devices. Git for easy rollback.

### Risk 4: Breaking Changes During Typography/Spacing Migrations
**Impact:** Visual regressions, user-facing bugs
**Likelihood:** Medium
**Mitigation:** Thorough testing after each screen migration. Visual regression tests if possible.

### Risk 5: AppTheme vs AppColors Decision Delays Phase 5
**Impact:** Color cleanup can't complete
**Likelihood:** Low
**Mitigation:** Make decision early in Phase 2 (research in 02-01). Clear options documented.

---

## Appendix: References to Detailed Documents

### Audit Documentation (Phase 1)
- **Design Tokens Inventory:** `.planning/phases/01-foundation-audit/design-tokens-inventory.md`
- **Component Library Inventory:** `.planning/phases/01-foundation-audit/component-library-inventory.md`
- **Design System Gaps:** `.planning/phases/01-foundation-audit/design-system-gaps.md`
- **Spacing Inconsistencies:** `.planning/phases/01-foundation-audit/spacing-inconsistencies.md`
- **Typography Inconsistencies:** `.planning/phases/01-foundation-audit/typography-inconsistencies.md`
- **Color/Theming Inconsistencies:** `.planning/phases/01-foundation-audit/color-theming-inconsistencies.md`
- **Component Duplication Analysis:** `.planning/phases/01-foundation-audit/component-duplication-analysis.md`

### Roadmap Documentation (Phase 1)
- **Standardization Themes:** `.planning/phases/01-foundation-audit/standardization-themes.md`
- **Phase Execution Sequence:** `.planning/phases/01-foundation-audit/phase-execution-sequence.md`
- **Quick Wins and Foundations:** `.planning/phases/01-foundation-audit/quick-wins-and-foundations.md`
- **Success Metrics:** `.planning/phases/01-foundation-audit/success-metrics.md`

### Key File Paths for Standardization Work

**Design Tokens (to create/enhance):**
- `/lib/core/design_tokens/border_radius.dart` (NEW)
- `/lib/core/design_tokens/elevation.dart` (NEW)
- `/lib/core/design_tokens/opacity.dart` (NEW)
- `/lib/core/design_tokens/icon_size.dart` (NEW)
- `/lib/core/design_tokens/duration.dart` (NEW)
- `/lib/core/design_tokens/colors.dart` (exists)
- `/lib/core/design_tokens/typography.dart` (exists)
- `/lib/core/design_tokens/spacing.dart` (exists)

**Components (to create/enhance):**
- `/lib/core/widgets/app_list_tile.dart` (NEW - HIGHEST PRIORITY)
- `/lib/core/widgets/app_text_field.dart` (NEW)
- `/lib/core/widgets/app_avatar.dart` (NEW)
- `/lib/core/widgets/app_badge.dart` (NEW)
- `/lib/core/widgets/app_empty_state.dart` (NEW)
- `/lib/core/widgets/app_loading_state.dart` (NEW)
- `/lib/core/widgets/app_stream_builder.dart` (NEW)
- `/lib/core/widgets/app_icon_badge.dart` (NEW)
- `/lib/core/widgets/app_section_header.dart` (NEW)
- `/lib/core/widgets/app_info_grid.dart` (NEW)
- `/lib/core/widgets/app_card.dart` (enhance with premium/glass variants)
- `/lib/core/widgets/app_button_enhanced.dart` (enhance with destructive variant)
- `/lib/core/widgets/app_button.dart` (deprecate)

**Screens (examples of areas needing work):**
- `/lib/main_function/player_list/player_list_widget.dart` (13 hardcoded colors - CRITICAL)
- `/lib/profile/create_profile/create_profile_widget.dart` (16+ hardcoded fontSize)
- `/lib/user_auth/sign_up_account/sign_up_account_widget.dart` (21+ fromSTEB, AppTheme.override)
- `/lib/chat_group/game_chat_details/game_chat_details_widget.dart` (10-32px fontSize range)
- `/lib/main_function/create_game/create_game_widget.dart` (13+ hardcoded fontSize)
- `/lib/main_function/game_joined_detailed/game_joined_detailed_widget.dart` (model screen - 80% component usage)

---

## Definition of "Done" for UI/UX Polish Project

The standardization work is complete when:

### Quantitative Criteria (All Must Be Met)
- [x] All 5 new token systems created
- [x] All 6 core missing components created
- [x] Component usage ≥65% average across 20 sampled screens
- [x] AppTypography adoption ≥85%
- [x] AppColors adoption ≥95%
- [x] AppSpacing adoption ≥90%
- [x] AppBorderRadius adoption ≥60%
- [x] AppElevation adoption ≥60%
- [x] Hardcoded hex colors = 0
- [x] Hardcoded fontSize instances <120 (from ~800)
- [x] Hardcoded SizedBox heights <25 (from ~250)
- [x] Code reduction ≥4,500 lines (from ~5,385 duplicate lines)

### Qualitative Criteria (Visual Inspection)
- [x] Consistency scorecard average ≥4.5/5 across 10 screens
- [x] All screen titles use same text style (headlineMedium)
- [x] All section headers use same text style (titleLarge/Medium)
- [x] All premium cards look identical (gradient, border, shadow)
- [x] All loading screens have same spinner and feel
- [x] All lists have consistent interaction patterns
- [x] All forms have consistent input styling
- [x] App feels cohesive and polished
- [x] Dark mode works correctly (no hardcoded colors breaking it)

### Developer Experience Criteria
- [x] Linter rules active (prevent hardcoded colors, fontSize, spacing)
- [x] Migration guides exist for all deprecated components
- [x] Component documentation complete (examples for all components)
- [x] Standards documented (typography hierarchy, spacing conventions)
- [x] New developers can add features faster (measured via time tracking)

### Stakeholder Criteria
- [x] Visible improvement in UI polish (before/after screenshots)
- [x] Maintainability improved (changes require updating fewer files)
- [x] Design system adoption proven (tokens + components widely used)
- [x] Ready for Phase 6 (Large Widget Refactoring) and Phase 7 (Tech Debt Cleanup)

---

## Next Steps

### Immediate (Week 1-2 of Phase 2)
1. Execute Plan 02-01: Create all 5 token systems
2. Deprecate AppButton
3. Complete quick wins (8 items, ~8.5 hours)
4. Prove tokens work (integrate into 2-3 components)

### Short-Term (Weeks 3-8 of Phase 2)
5. Execute Plans 02-02, 02-03, 02-04
6. Create all missing core components
7. Enhance AppCard with variants
8. Migrate 10-15 screens as proof of concept
9. Measure and verify Phase 2 success metrics

### Medium-Term (Phase 3-4, ~6-8 weeks)
10. Execute Phase 3 typography migration
11. Execute Phase 4 spacing migration
12. Measure adoption targets (85% typography, 90% spacing)
13. Visual consistency improvements verified

### Long-Term (Phase 5, ~3-4 weeks)
14. Execute Phase 5 color cleanup and flow polish
15. Achieve 65%+ component usage target
16. Dark mode readiness verified
17. Project success metrics all met
18. Ready for Phase 6 (Large Widget Refactoring)

---

**Total Timeline:** 12-16 weeks (conservative estimate)
**Total Effort:** ~160-200 hours across all phases
**Total Impact:** Transformative (40% component usage → 65%+, 5,000+ lines eliminated, app feels polished and maintainable)

---

## Conclusion

This roadmap provides a clear, actionable path from the current inconsistent state to a polished, maintainable app with systematic design token application and high component usage. The work is organized into logical phases with clear dependencies, success metrics, and risk mitigations.

**The foundation audit is complete. Phase 2 execution can begin immediately.**

**Recommended Start:** Week 1-2 foundation sprint (complete all quick wins and foundational work), then proceed with Phase 2 Plan 02-01.

---

*This roadmap is a living document. Update as Phase 2-5 execution reveals new insights or requires adjustments to the plan.*
