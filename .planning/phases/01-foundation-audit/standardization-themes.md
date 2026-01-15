# Standardization Themes

**Created:** 2026-01-15
**Purpose:** Group audit findings into actionable standardization themes
**Source:** Plans 01-01 and 01-02 audit documentation

## Overview

This document synthesizes findings from the foundation audit into 10 major standardization themes. Each theme groups related issues, defines current vs desired state, provides complexity estimates, and maps to affected screens.

---

## Theme 1: Missing Token Systems (Border Radius, Elevation, Opacity)

### Issues Addressed
- **Border Radius Tokens:** No standardized radius scale
  - Files: `design-system-gaps.md` lines 27-75
  - Current: 8 different hardcoded values (2px, 4px, 8px, 12px, 16px, 20px, 24px)
  - Examples: `create_game_widget.dart`, `game_joined_detailed_widget.dart`

- **Elevation/Shadow Tokens:** No shadow scale
  - Files: `design-system-gaps.md` lines 77-175
  - Current: Inconsistent BoxShadow definitions (opacity 0.04-0.4, blur 4-32)
  - Examples: `profile_card_section.dart`, `app_card.dart`

- **Opacity Tokens:** No semantic opacity scale
  - Files: `design-system-gaps.md` lines 177-229, `color-theming-inconsistencies.md` lines 65-138
  - Current: 11 different opacity values (0.1, 0.12, 0.15, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9)
  - Examples: All screens with shadows/overlays

### Affected Screens/Features
- All components using cards, buttons, modals
- All screens with shadows/glows: `game_joined_detailed`, `profile_user_firebase`, `edit_profile`
- Premium card pattern (30+ instances across screens)

### Current State vs Desired State
**Current:**
- Border radius: Hardcoded values everywhere, visual inconsistency
- Elevation: Inline BoxShadow definitions, can't update globally
- Opacity: Arbitrary values with no semantic meaning

**Desired:**
- AppBorderRadius tokens (xxs: 2, xs: 4, sm: 8, md: 12, lg: 16, xl: 20, xxl: 24, full: 9999)
- AppElevation presets (elevationNone through elevationXl + elevationLayered)
- AppOpacity semantic scale (subtle: 0.05, light: 0.1, medium: 0.2, strong: 0.4, prominent: 0.6, heavy: 0.8)

### Complexity Estimate
**Moderate** - Create token files (simple), migrate usage (moderate scale ~200+ instances)

---

## Theme 2: Typography Token Adoption (50% → 85%+)

### Issues Addressed
- **Hardcoded Font Sizes:** 60-70% of text uses custom fontSize values
  - Files: `typography-inconsistencies.md` lines 14-57
  - Current: 15+ different hardcoded sizes (10-32px range)
  - Examples: `create_profile_widget.dart` (16+ instances), `create_game_widget.dart` (13+ instances)

- **Manual GoogleFonts Calls:** Direct GoogleFonts.outfit() instead of AppTypography
  - Files: `typography-inconsistencies.md` lines 59-91, `component-library-inventory.md` line 349
  - Current: Nearly all screens use manual GoogleFonts
  - Problem: Outfit not in design system (should be Fraunces/Manrope/DM Mono)

- **AppTheme.override Anti-Pattern:** Defeats design system purpose
  - Files: `typography-inconsistencies.md` lines 189-227
  - Current: Verbose, overrides design system completely
  - Examples: Throughout older screens

### Affected Screens/Features
- Worst offenders: `create_profile_widget.dart` (15% compliant), `sign_up_account_widget.dart` (20%), `game_chat_details_widget.dart` (25%)
- Screen titles: Sizes vary 22-32px across screens
- Body text: Mix of 14px, 15px, 16px for same content
- Labels/captions: Mix of 10-14px

### Current State vs Desired State
**Current:**
- 50% AppTypography adoption, 50% hardcoded
- Inconsistent heading hierarchy (14-32px for screen titles)
- Missing font family distinctiveness (all Outfit instead of Fraunces/Manrope)

**Desired:**
- 85%+ AppTypography adoption
- Consistent hierarchy: headlineMedium (24px) for screen titles, titleLarge/Medium (18-20px) for sections
- Proper font families: Fraunces displays, Manrope body, DM Mono data

### Complexity Estimate
**Complex** - Large scale migration (~800 text instances), automated refactor script needed

---

## Theme 3: Color System Cleanup (Hardcoded Hex → AppColors)

### Issues Addressed
- **Hardcoded Hex Colors:** Direct Color(0xFFXXXXXX) values
  - Files: `color-theming-inconsistencies.md` lines 19-61
  - Current: 21+ hardcoded color instances
  - Critical: `player_list_widget.dart` has 13 custom colors (entire custom palette!)

- **Colors.white/black with Varying Opacity:** Should use semantic neutrals
  - Files: `color-theming-inconsistencies.md` lines 63-99
  - Current: Same purpose uses different opacity (0.1, 0.12, 0.15, 0.2 for overlays)
  - Examples: `newsfeed_widget.dart` (14+ instances), `profile_user_firebase_widget.dart` (10+ instances)

- **AppTheme vs AppColors Confusion:** Two overlapping color systems
  - Files: `color-theming-inconsistencies.md` lines 141-194, `design-system-gaps.md` lines 358-395
  - Current: Some screens use AppTheme, some AppColors, some mix both
  - Examples: `blog_create/edit_widget.dart` (16+ AppTheme calls)

### Affected Screens/Features
- `player_list_widget.dart` - entire custom green/grey palette (CRITICAL for dark mode)
- Auth screens: `sign_up_account_widget.dart`, `sign_in_widget.dart`
- Newsfeed screens: Heavy AppTheme vs AppColors mixing

### Current State vs Desired State
**Current:**
- 80% AppColors adoption, but 21 hardcoded hex colors remain
- player_list has custom palette breaking visual consistency
- AppTheme and AppColors coexist, creating confusion

**Desired:**
- 95%+ AppColors adoption, zero hardcoded hex
- player_list uses AppColors fairway/neutral families
- AppTheme deprecated or wrapped by AppColors (single system)

### Complexity Estimate
**Moderate** - Find/replace for most (simple), player_list refactor (moderate), AppTheme decision (complex)

---

## Theme 4: Spacing Token Migration (40-50% → 90%+)

### Issues Addressed
- **Hardcoded SizedBox Heights:** Direct pixel values instead of AppSpacing
  - Files: `spacing-inconsistencies.md` lines 13-35
  - Current: ~80 instances of SizedBox(height: 2), ~40 of height: 4, ~25 of height: 12
  - Examples: Most screens have 2px gaps

- **EdgeInsetsDirectional.fromSTEB Overuse:** Verbose manual padding
  - Files: `spacing-inconsistencies.md` lines 37-69
  - Current: 21+ instances in `sign_up_account_widget.dart` alone
  - Problem: Mixes hardcoded values, some off-grid (10px, 15px)

- **Off-Grid Spacing Values:** Values not aligned with 4px/8px grid
  - Files: `spacing-inconsistencies.md` lines 95-110
  - Current: 2px, 6px, 10px, 15px values breaking grid system
  - Impact: Breaks visual alignment

### Affected Screens/Features
- Worst offenders: `sign_up_account_widget.dart` (21+ fromSTEB calls), `game_chat_details_widget.dart`
- All screens have some hardcoded spacing
- Game screens: `create_game_widget.dart`, `game_joined_detailed_widget.dart`

### Current State vs Desired State
**Current:**
- 50-60% AppSpacing adoption
- ~500 spacing instances examined, ~250 hardcoded
- Off-grid values create visual discord

**Desired:**
- 90%+ AppSpacing adoption
- All spacing on-grid (4px base)
- Replace fromSTEB with AppSpacing shortcuts

### Complexity Estimate
**Moderate** - Bulk find/replace (simple), off-grid rounding decisions (moderate judgment calls)

---

## Theme 5: Component Duplication Extraction (Premium Cards, Loading States)

### Issues Addressed
- **Premium Card Pattern:** Duplicated 30+ times
  - Files: `component-duplication-analysis.md` lines 19-80
  - Current: 50 lines × 30 instances = 1,500 lines of duplicate code
  - Examples: `game_joined_detailed`, `profile_user_firebase`, `games_list`
  - Problem: AppCard exists but not adopted! Missing "premium" variant

- **Loading State Pattern:** SpinKitWanderingCubes duplicated 22 times
  - Files: `component-duplication-analysis.md` lines 125-185
  - Current: 30 lines × 22 instances = 660 lines of duplicate code
  - Examples: All game/social screens

- **Player/User List Item:** Duplicated 30+ times
  - Files: `component-duplication-analysis.md` lines 398-474
  - Current: 60 lines × 30 instances = 1,800 lines
  - Examples: `game_joined_detailed`, `tab_friends`, `golfers`, `player_list`

### Affected Screens/Features
- Premium cards: `game_joined_detailed`, `join_game_detailed`, `profile_user_firebase`, `games_list`
- Loading states: All 18+ screens with StreamBuilder
- User list items: `game_joined_detailed`, `tab_friends`, `golfers`, `player_list`, `become_friends`

### Current State vs Desired State
**Current:**
- 5,385 lines of duplicated UI code across patterns
- AppCard exists but 60+ inline cards reimplemented
- No centralized loading/empty states

**Desired:**
- AppCard enhanced with premium/glass variants (60+ cards migrate)
- AppLoadingState component (replace 22 duplications)
- AppUserListItem component (replace 30+ duplications)
- Net savings: ~4,885 lines (90% reduction)

### Complexity Estimate
**Moderate to Complex** - Enhance AppCard (simple), create new components (moderate), refactor usage (moderate to complex depending on variations)

---

## Theme 6: Missing Core Components (AppListTile, AppTextField, AppAvatar)

### Issues Addressed
- **AppListTile (HIGHEST PRIORITY):** Lists everywhere, all custom-built
  - Files: `design-system-gaps.md` lines 361-418, `component-library-inventory.md` lines 619-624
  - Current: 50+ screens with custom list items
  - Examples: `player_list`, `tab_friends`, `community`, chat lists

- **AppTextField:** Forms/inputs all custom
  - Files: `design-system-gaps.md` lines 420-462
  - Current: 20+ screens with custom inputs
  - Examples: `chat_widget.dart` (message input), `create_game` (form fields)

- **AppAvatar:** User displays inconsistent
  - Files: `design-system-gaps.md` lines 464-510
  - Current: 30+ screens with custom avatars
  - Examples: Profile screens, list items everywhere

- **AppBadge:** Status indicators repeated
  - Files: `design-system-gaps.md` lines 512-560
  - Current: 15+ screens
  - Examples: `game_joined_detailed` (status indicators)

### Affected Screens/Features
- AppListTile: Every list in app (players, friends, games, community posts, chat messages)
- AppTextField: Every form, search bar, chat input
- AppAvatar: Every user reference (profile, lists, comments)
- AppBadge: Status indicators, notification counts

### Current State vs Desired State
**Current:**
- Missing components force custom implementation every time
- Inconsistent list items (different layouts, sizes, interactions)
- Inconsistent input fields (styling, validation, error states)
- Inconsistent avatars (sizes, borders, fallbacks)

**Desired:**
- AppListTile with variants (standard, compact, card, highlighted)
- AppTextField with variants (outlined, filled, underlined, search)
- AppAvatar with sizes (xs→xxl) and shapes (circle, square, rounded)
- AppBadge with semantic variants (default, primary, success, warning, error)

### Complexity Estimate
**Moderate** - Components themselves straightforward, but high usage means significant refactoring effort

---

## Theme 7: Legacy Component Deprecation (AppButton → AppButtonEnhanced)

### Issues Addressed
- **Two Button Systems:** AppButton (legacy) and AppButtonEnhanced (modern)
  - Files: `component-library-inventory.md` lines 13-93, `design-system-gaps.md` lines 638-664
  - Current: Both coexist, developer confusion
  - AppButton: 20+ options, no tokens, manual everything
  - AppButtonEnhanced: 11 props, tokens, semantic variants, 40% adoption

- **AppIconButton (Legacy):** No design tokens
  - Files: `component-library-inventory.md` lines 95-115
  - Current: 4/10 sampled files use it
  - Problem: 15 config props, no token integration

- **AppDropDown Complexity:** 25+ props, too complex
  - Files: `component-library-inventory.md` lines 167-191, `design-system-gaps.md` lines 680-698
  - Current: Used in 2/10 files
  - Problem: Extremely complex API, no tokens

### Affected Screens/Features
- AppButton: Unknown usage (needs codebase-wide grep)
- AppIconButton: `create_game`, `game_joined_detailed`, `main_profile`, `chat`
- AppDropDown: `create_game`, `player_list`

### Current State vs Desired State
**Current:**
- AppButton and AppButtonEnhanced coexist
- No deprecation warnings
- New code might use wrong component
- Legacy components have no token integration

**Desired:**
- AppButton marked @Deprecated with migration guide
- AppIconButton enhanced or deprecated (decide based on AppButtonEnhanced icon mode)
- AppDropDown kept for advanced use, but simplified AppSelect created for 90% use case
- All legacy components have clear migration path

### Complexity Estimate
**Simple to Moderate** - Add deprecation (simple), create migration guides (moderate), refactor usages (moderate)

---

## Theme 8: StreamBuilder and State Management Boilerplate

### Issues Addressed
- **StreamBuilder Boilerplate:** Identical loading/error handling repeated 30 times
  - Files: `component-duplication-analysis.md` lines 250-300
  - Current: 100+ lines per screen for StreamBuilder wrapper
  - Examples: All game detail screens, profile screens, friends screens, chat screens

- **Empty State Pattern:** Duplicated 15+ times
  - Files: `component-duplication-analysis.md` lines 187-248
  - Current: 20 lines × 15 instances = 300 lines
  - Examples: `games_list`, `tab_friends`, `golfers`, `notifications`, `newsfeed`

### Affected Screens/Features
- StreamBuilder: 18+ files with StreamBuilder
- Empty states: Every list needs empty state (games, friends, players, notifications, posts)

### Current State vs Desired State
**Current:**
- 30 StreamBuilder instances with identical loading/error patterns
- No standardized empty state UI
- Repetitive boilerplate (100+ lines per screen)

**Desired:**
- AppStreamBuilder<T> wrapper handles loading/errors/parsing
- AppEmptyState component with icon, title, message, optional action
- Reduce boilerplate from 100 lines to ~10 lines

### Complexity Estimate
**Moderate** - Components simple to create, but refactoring 30 StreamBuilder instances requires careful testing

---

## Theme 9: Specialized Components Generalization

### Issues Addressed
- **Icon Badge Pattern:** Duplicated 25+ times
  - Files: `component-duplication-analysis.md` lines 302-349
  - Current: 15 lines × 25 instances = 375 lines
  - Examples: `game_joined_detailed`, `profile_user_firebase`

- **Section Header Pattern:** Duplicated 20+ times
  - Files: `component-duplication-analysis.md` lines 351-396
  - Current: 15 lines × 20 instances = 300 lines
  - Examples: `game_joined_detailed`, `profile` screens

- **Info Grid Pattern:** Duplicated 15+ times
  - Files: `component-duplication-analysis.md` lines 477-520
  - Current: 30 lines × 15 instances = 450 lines
  - Examples: `game_joined_detailed`, `join_game_detailed`, `games_list`

- **ProfileCardSection → SectionCard:** Specific to profile, but pattern needed elsewhere
  - Files: `design-system-gaps.md` lines 700-718
  - Current: ProfileCardSection exists, SectionCard also exists (confusion!)
  - Need: Audit if they overlap or serve different purposes

### Affected Screens/Features
- Icon badges: Game screens (8+ per screen), profile screens (10+ per screen)
- Section headers: All screens with sections (`game_joined_detailed`, profiles, game creation)
- Info grids: Game detail screens, profile stats

### Current State vs Desired State
**Current:**
- Inline implementations everywhere
- ~1,125 lines of duplicate code across these patterns
- Inconsistent sizing/styling

**Desired:**
- AppIconBadge component with sizes and gradient support
- AppSectionHeader with variants (withAccent, plain, numbered)
- AppInfoGrid component with flexible item configuration
- Clear distinction between ProfileCardSection and SectionCard (or merge)

### Complexity Estimate
**Simple to Moderate** - Components straightforward, refactoring moderate scale

---

## Theme 10: Shadow/Glow and Gradient Standardization

### Issues Addressed
- **Inconsistent Shadow/Glow Colors:** No standard elevation system
  - Files: `color-theming-inconsistencies.md` lines 256-307
  - Current: Gold glow uses 0.15 or 0.3 opacity, blur radius varies (8, 12, 20)
  - Examples: Premium cards throughout app

- **Inline Gradient Definitions:** Not using design system gradients
  - Files: `color-theming-inconsistencies.md` lines 309-341, `component-duplication-analysis.md` line 615
  - Current: 69 LinearGradient instances
  - Problem: AppColors.fairwayGradient and sunsetGradient exist but underutilized

### Affected Screens/Features
- Shadows: All cards, buttons, modals (166+ BoxDecoration instances)
- Gradients: Premium cards, backgrounds, icon badges (69 instances)

### Current State vs Desired State
**Current:**
- Inline BoxShadow definitions with inconsistent values
- Inline LinearGradient definitions instead of design system
- Can't update shadows/gradients globally

**Desired:**
- AppElevation system with predefined shadows (elevationXs through elevationXl, glowGold, glowGreen)
- All gradients use AppColors.fairwayGradient, sunsetGradient, subtleOverlay
- Elevation/gradient changes propagate globally

### Complexity Estimate
**Moderate** - Create elevation system (simple), migrate usage (moderate, ~230 instances)

---

## Summary Statistics

### Total Issues Identified
- Missing token systems: 3 token categories (border radius, elevation, opacity)
- Typography problems: 800+ text instances need migration
- Color problems: 21 hardcoded hex colors, 11 opacity variations
- Spacing problems: 250+ hardcoded spacing values
- Component duplication: 5,385 lines of duplicate code
- Missing components: 6 core components needed
- Legacy components: 3 components need deprecation
- Boilerplate: 30 StreamBuilder instances, 15 empty states
- Specialized patterns: 60+ instances of icon badges/section headers/info grids
- Shadows/gradients: 230+ instances to standardize

### Themes by Priority
**Critical (Blocks standardization):**
1. Theme 6: Missing Core Components (AppListTile blocking 50+ screens)
2. Theme 1: Missing Token Systems (affects all components)

**High (Major inconsistencies):**
3. Theme 2: Typography Token Adoption
4. Theme 5: Component Duplication Extraction
5. Theme 3: Color System Cleanup
6. Theme 4: Spacing Token Migration

**Medium (Polish and completeness):**
7. Theme 10: Shadow/Glow and Gradient Standardization
8. Theme 9: Specialized Components Generalization
9. Theme 7: Legacy Component Deprecation
10. Theme 8: StreamBuilder and State Management Boilerplate

### Estimated Total Impact
- **Code reduction:** ~5,000+ lines of duplicate code → ~500 lines in components (90% reduction)
- **Token adoption:** Spacing 100% (already), Colors 80%→95%, Typography 50%→85%
- **Component usage:** 40%→65% average
- **Consistency:** Dramatic improvement across all screens
- **Maintainability:** Centralized components, easier to update
- **Dark mode readiness:** Fixing hardcoded colors enables dark mode support
