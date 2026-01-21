---
phase: 05-screen-flow-polish
plan: 01
subsystem: navigation
tags: [transitions, go_router, page_transition, navigation-standards, ux-consistency]

# Dependency graph
requires:
  - phase: 04-spacing-system
    provides: Design token foundation and migration patterns from Phase 4
provides:
  - TransitionStandards constants for 4 semantic transition types
  - Extension methods for convenient navigation with transitions
  - Comprehensive migration guide for Plans 05-02 and 05-03
affects: [05-02, 05-03, future-navigation-work]

# Tech tracking
tech-stack:
  added: []
  patterns: [semantic-transition-constants, extension-method-wrappers, transition-standards]

key-files:
  created:
    - lib/core/navigation/transition_standards.dart
    - .planning/phases/05-screen-flow-polish/TRANSITION-MIGRATION-GUIDE.md
  modified:
    - lib/core/navigation/app_router.dart

key-decisions:
  - "220ms duration for modal/detail/dismissal transitions (modern feel, slightly faster than Material's 300ms)"
  - "200ms duration for tab transitions (faster lateral navigation feel)"
  - "4 semantic transition types: modal, detail, dismissal, tab (not just visual, but semantic purpose)"
  - "Extension methods on BuildContext for easier usage (pushModal, pushDetail, goWithTransition)"
  - "Export from app_router.dart for universal availability throughout navigation code"

patterns-established:
  - "Semantic transition naming: modalTransition for create/edit, detailTransition for drilling into content"
  - "Consistent durations: Only 200ms (tabs) and 220ms (modal/detail/dismissal) allowed"
  - "Transition standards as const TransitionInfo objects for compile-time safety"
  - "Extension methods for reducing boilerplate in navigation calls"

# Metrics
duration: 35min
completed: 2026-01-21
---

# Plan 05-01: Transition Standards Foundation Summary

**TransitionStandards module with 4 semantic transition constants (220ms modal/detail/dismissal, 200ms tabs), extension methods, and comprehensive migration guide for 12-screen systematic rollout**

## Performance

- **Duration:** 35 min
- **Started:** 2026-01-21
- **Completed:** 2026-01-21
- **Tasks:** 3
- **Files modified:** 2 created, 1 modified

## Accomplishments
- Created TransitionStandards with 4 semantic constants (modal, detail, dismissal, tab)
- Extension methods on BuildContext reduce boilerplate (pushModal, pushDetail, goWithTransition)
- Comprehensive 512-line migration guide with file-by-file checklists for Plans 05-02/05-03
- Zero compilation errors, dart analyze passes cleanly

## Task Commits

Each task was committed atomically:

1. **Task 1: Create transition standards module** - `950524af` (feat)
2. **Task 2: Export transition standards from app_router.dart** - `f1bcb73b` (feat)
3. **Task 3: Create migration guide documentation** - `1e05023a` (docs)

## Files Created/Modified
- `lib/core/navigation/transition_standards.dart` - 250-line module with 4 transition constants, 3 extension methods, comprehensive documentation with usage examples and anti-patterns
- `lib/core/navigation/app_router.dart` - Added export for transition_standards.dart, updated TransitionInfo.appDefault() documentation to reference new standards
- `.planning/phases/05-screen-flow-polish/TRANSITION-MIGRATION-GUIDE.md` - 512-line guide with before/after examples, file-by-file checklists (12 screens), anti-patterns, verification commands, success metrics

## Decisions Made

**1. Semantic transition types over visual-only naming**
- Rationale: "modalTransition" and "detailTransition" both use bottomToTop slide, but different semantic purposes (creating content vs drilling into content). Semantic naming makes intent clearer.

**2. 220ms duration for modal/detail/dismissal (not Material's 300ms)**
- Rationale: Audit showed 220ms already in use for working transitions. Slightly faster than Material's 300ms default for modern, snappy feel without feeling jarring.

**3. 200ms duration for tab transitions (faster than other transitions)**
- Rationale: Tab switching is lateral navigation at same depth level. Users expect near-instant response. 200ms fade provides subtle visual feedback without delay feel.

**4. Extension methods for convenience wrappers**
- Rationale: Reduce boilerplate from 5-line extra map to single pushModal/pushDetail call. Makes correct transitions easier to apply than incorrect ones.

**5. Export from app_router.dart (not standalone import)**
- Rationale: app_router.dart already imported throughout navigation code. Exporting TransitionStandards from it makes standards universally available without additional imports.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

**1. PageTransitionType import resolution**
- Problem: Initial file missing import for PageTransitionType enum (from page_transition package)
- Resolution: Added `import 'package:page_transition/page_transition.dart';` to transition_standards.dart
- Impact: 2 minutes to diagnose and fix, no plan changes needed

**2. Unnecessary go_router import**
- Problem: dart analyze flagged go_router import as unnecessary (already exported by app_router.dart)
- Resolution: Removed redundant import
- Impact: 1 minute cleanup, improved code quality

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Ready for Plans 05-02 and 05-03:**
- TransitionStandards constants accessible throughout app via app_router.dart import
- Extension methods reduce migration friction
- Migration guide provides clear file-by-file checklists for 12 screens
- Verification commands ready for tracking progress

**Target metrics for next plans:**
- 15+ modalTransition usages (create/edit screens)
- 20+ detailTransition usages (detail views)
- 2+ dismissalTransition usages (success screens)
- 4+ tabTransition usages (profile tabs)
- Zero inline TransitionInfo(...) constructors
- Zero duration variations (only 200ms/220ms)

**No blockers:**
- Foundation complete
- All files compile cleanly
- Migration patterns validated

---
*Phase: 05-screen-flow-polish*
*Plan: 05-01*
*Completed: 2026-01-21*
