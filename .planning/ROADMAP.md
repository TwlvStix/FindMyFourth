# Roadmap: Find My Fourth UI/UX Polish

## Overview

Transforming Find My Fourth from functional to polished through systematic UI/UX improvements. Starting with foundation audit to understand current inconsistencies, then progressively standardizing components, typography, spacing, and screen flows. Concludes with refactoring large widgets and cleaning up technical debt to ensure maintainability.

## Domain Expertise

None

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation Audit** - Assess current design system and catalog inconsistencies
- [ ] **Phase 2: Component Library Standardization** - Unify all UI components with consistent variants
- [x] **Phase 3: Typography System** - Apply text hierarchy consistently across all screens
- [x] **Phase 4: Spacing System** - Systematize layout using design tokens
- [x] **Phase 5: Screen Flow Polish** - Smooth transitions and navigation consistency
- [ ] **Phase 6: Large Widget Refactoring** - Break down monolithic widgets into composable components
- [ ] **Phase 7: Tech Debt Cleanup** - Remove deprecated files and final polish pass

## Phase Details

### Phase 1: Foundation Audit
**Goal**: Understand current design system state and create comprehensive inventory of inconsistencies across components, typography, spacing, and screen flows
**Depends on**: Nothing (first phase)
**Research**: Unlikely (internal codebase audit, established patterns)
**Plans**: 3 plans

Plans:
- [x] 01-01: Audit existing design tokens and component library
- [x] 01-02: Document inconsistencies across key screens
- [x] 01-03: Create standardization roadmap with priority areas

### Phase 2: Component Library Standardization
**Goal**: Establish unified component library with consistent variants for buttons, cards, inputs, and all reusable UI elements
**Depends on**: Phase 1
**Research**: Unlikely (Flutter Material Design patterns, existing components)
**Plans**: 4 plans

Plans:
- [x] 02-01: Foundation design tokens (border radius, elevation, opacity, icon size, animation)
- [x] 02-02: Card standardization + component creation (AppCard variants, AppIconBadge, AppSectionHeader)
- [x] 02-03: Input components (AppTextField, AppBadge)
- [ ] 02-04: Missing core components Part 2 + state management

### Phase 3: Typography System
**Goal**: Apply consistent text hierarchy throughout the app for optimal readability and visual hierarchy
**Depends on**: Phase 2
**Research**: Unlikely (design tokens application, no external dependencies)
**Plans**: 3 plans

Plans:
- [x] 03-01: Typography foundation enhancement (semantic styles + AppText widget)
- [x] 03-02: Screen migrations batch 1 (create_profile, sign_up_account, game_chat_details, edit_profile)
- [x] 03-03: Screen migrations batch 2 (chat, recover_password, edit_vibes, social screens, game lists)

### Phase 4: Spacing System
**Goal**: Implement systematic spacing using design tokens for harmonious layouts across all screens
**Depends on**: Phase 3
**Research**: Unlikely (design tokens already exist in lib/core/design_tokens/)
**Plans**: 3 plans

Plans:
- [x] 04-01: Audit and refine spacing token scale
- [x] 04-02: Apply spacing tokens to game and social screens
- [x] 04-03: Apply spacing tokens to profile and auth screens

### Phase 5: Screen Flow Polish
**Goal**: Ensure smooth, predictable navigation with consistent transitions across all user journeys
**Depends on**: Phase 4
**Research**: Unlikely (GoRouter transitions, internal navigation patterns)
**Plans**: 3 plans
**Status**: ✅ COMPLETE (2026-01-21)

Plans:
- [x] 05-01: Audit and standardize page transitions
- [x] 05-02: Polish game creation and joining flows
- [x] 05-03: Polish chat, profile, and friend management flows

### Phase 6: Large Widget Refactoring
**Goal**: Break down 7 large widgets (1300-2183 lines) into maintainable, composable components
**Depends on**: Phase 5
**Research**: Unlikely (refactoring existing code with established patterns)
**Plans**: 4 plans

Plans:
- [ ] 06-01: Refactor game_joined_detailed and join_game_detailed widgets
- [ ] 06-02: Refactor create_game widget
- [ ] 06-03: Refactor game_chat_details widget
- [ ] 06-04: Refactor tab_friends, golfers, and profile_user_firebase widgets

### Phase 7: Tech Debt Cleanup
**Goal**: Remove deprecated files, verify consistency across all screens, and complete final polish pass
**Depends on**: Phase 6
**Research**: Unlikely (cleanup work, no new patterns)
**Plans**: 2 plans

Plans:
- [ ] 07-01: Remove deprecated OLD widget files and cleanup debug logging
- [ ] 07-02: Final consistency pass and polish verification

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation Audit | 3/3 | ✓ Complete | 2026-01-15 |
| 2. Component Library Standardization | 4/4 | ✓ Complete | 2026-01-16 |
| 3. Typography System | 3/3 | ✓ Complete | 2026-01-20 |
| 4. Spacing System | 3/3 | ✓ Complete | 2026-01-21 |
| 5. Screen Flow Polish | 3/3 | ✓ Complete | 2026-01-21 |
| 6. Large Widget Refactoring | 0/4 | Not started | - |
| 7. Tech Debt Cleanup | 0/2 | Not started | - |
