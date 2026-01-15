# Find My Fourth - UI/UX Polish

## What This Is

A comprehensive UI/UX cleanup initiative for Find My Fourth, a Flutter golf app that helps golfers find players and create/join games. This work focuses on achieving visual consistency, refining component patterns, improving spacing/typography systems, and ensuring smooth screen flows across all features.

## Core Value

**Component consistency** — every button, card, input, and UI element looks and behaves the same way everywhere, creating a cohesive, professional experience that feels like one unified app.

## Requirements

### Validated

- ✓ Flutter mobile app (iOS 15.0+, Android SDK 35) — existing
- ✓ Firebase backend (Firestore, Auth, Storage, Messaging) — existing
- ✓ Provider state management with real-time streams — existing
- ✓ GoRouter navigation with 5-tab bottom nav (Games, Joined, Golfers, Community, Profile) — existing
- ✓ Core features: game creation/joining, chat, friend management, vibe matching — existing
- ✓ Design tokens foundation (`lib/core/design_tokens/`) with colors, typography, spacing — existing
- ✓ Reusable component library (`lib/core/widgets/`) with buttons, cards, inputs — existing

### Active

- [ ] Unified component library with consistent variants (primary/secondary buttons, card styles, input types)
- [ ] Systematic spacing using design tokens throughout all screens
- [ ] Typography hierarchy applied consistently (headings, body, labels, captions)
- [ ] Smooth, predictable navigation and screen transitions
- [ ] Refactored large widgets (2000+ lines) into composable components
- [ ] Removed deprecated OLD widget files
- [ ] Polish for key user flows: game creation, joining games, chat, profile editing

### Out of Scope

- Backend or data model changes — UI-only work, no API/Firestore modifications
- Major redesign or rebrand — keep current visual identity, make it consistent
- New features beyond consistency improvements — focus is polish, not expansion
- Performance optimization unrelated to UI — separate concern

## Context

**Current State:**
- 136 Dart files with 7 large widgets exceeding 1300 lines
- Design tokens exist (`lib/core/design_tokens/`) but inconsistently applied
- Component library exists (`lib/core/widgets/`) but needs standardization
- Multiple widget files have inconsistent spacing, typography, and component usage
- Tech debt: deprecated OLD files (4K lines), large monolithic widgets

**Key Screens:**
- Game flows: `games_list`, `games_joined`, `create_game`, `game_joined_detailed`, `join_game_detailed`
- Social: `golfers`, `community`, `tab_friends`, `chat`, `game_chat_details`
- Profile: `main_profile`, `edit_profile`, `create_profile`, `profile_user_firebase`
- Auth: `sign_in`, `sign_up_account`, `user_onboarding`

**Existing Design System:**
- Colors: `lib/core/design_tokens/colors.dart` (AppThemeColors)
- Typography: `lib/core/design_tokens/typography.dart` (AppTypography)
- Spacing: `lib/core/design_tokens/spacing.dart`
- Components: `lib/core/widgets/` (AppButton, AppCard, AppDropDown, etc.)

## Constraints

None — free to refactor components, reorganize widgets, and update design token usage as needed to achieve consistency.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Component consistency as core priority | Biggest visual impact, enables all other improvements | — Pending |
| Allow minor copy/functional tweaks | Consistency sometimes requires small UX adjustments | — Pending |
| Keep current visual identity | Not a rebrand, just polish and consistency | — Pending |

---
*Last updated: 2026-01-14 after initialization*
