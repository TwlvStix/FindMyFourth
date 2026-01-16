---
phase: 02-component-library-standardization
plan: 01
subsystem: design-tokens
tags: [tokens, border-radius, elevation, opacity, icon-size, duration, button-deprecation, component-standardization]

# Dependency graph
requires:
  - phase: 01-foundation-audit
    provides: Design token inventory, component audit findings, standardization roadmap
provides:
  - Complete design token foundation (5 new token systems)
  - AppButton deprecation with migration guide
  - AppButtonEnhanced destructive variant
  - Foundation ready for Phase 2-5 component work
affects: [02-02, 02-03, 02-04, all future component work]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Design token pattern for border radius (semantic + component-specific shortcuts)"
    - "Design token pattern for elevation (BoxShadow presets + specialty glows)"
    - "Design token pattern for opacity/icon-size/duration (scale + semantic shortcuts)"
    - "Component deprecation pattern with @Deprecated annotation and migration guide"

key-files:
  created:
    - lib/core/design_tokens/border_radius.dart
    - lib/core/design_tokens/elevation.dart
    - lib/core/design_tokens/opacity.dart
    - lib/core/design_tokens/icon_size.dart
    - lib/core/design_tokens/duration.dart
  modified:
    - lib/core/widgets/app_button.dart
    - lib/core/widgets/app_button_enhanced.dart
    - lib/core/widgets/README.md

key-decisions:
  - "Border radius values: xxs (2px) to full (999px) - 7 semantic values"
  - "Elevation: 6 standard levels + 2 specialty glows (gold, green)"
  - "Opacity: 6 values from subtle (0.05) to heavy (0.80)"
  - "Icon sizes: xs (16px) to xxl (48px) - accessibility-aligned"
  - "Animation durations: instant (50ms) to slow (400ms) - Material Design based"
  - "Destructive variant uses AppColors.error with error-colored shadows"
  - "AppButton deprecated but not removed - gradual migration strategy"

patterns-established:
  - "All token files follow same structure: scale + semantic shortcuts + doc comments"
  - "Design philosophy section explaining golf/country club aesthetic alignment"
  - "Component-specific shortcuts (e.g., AppBorderRadius.button, AppElevation.card)"
  - "Specialty variants for premium features (glowGold, glowGreen)"

# Metrics
duration: 6min
completed: 2026-01-16
---

# Phase 2 Plan 1: Foundation Tokens + Button Standardization Summary

**Complete design token foundation with 5 new token systems and AppButton deprecation strategy**

## Performance

- **Duration:** 6 min
- **Started:** 2026-01-16T05:34:39Z
- **Completed:** 2026-01-16T05:40:37Z
- **Tasks:** 6
- **Files modified:** 8

## Accomplishments

- Created 5 missing token systems (border_radius, elevation, opacity, icon_size, duration) completing design token foundation
- Deprecated AppButton with comprehensive migration guide in README.md
- Added destructive variant to AppButtonEnhanced for delete/remove actions
- Verified no AppButton instances exist to migrate - codebase already using AppButtonEnhanced
- All token systems include semantic shortcuts and golf/country club design philosophy
- Foundation now ready for Phase 2-5 component standardization work

## Task Commits

Each task was committed atomically:

1. **Task 1: Create AppBorderRadius token system** - `1a136dd9` (feat)
   - 7 semantic radius values (xxs 2px to full 999px)
   - Component-specific shortcuts (button, card, modal, etc.)

2. **Task 2: Create AppElevation token system** - `e60f1f38` (feat) + `d77674b2` (fix)
   - 6 standard elevation levels (none to xl)
   - 2 specialty glows (glowGold, glowGreen) for premium accents
   - Fix: Removed unused import

3. **Task 3: Create AppOpacity, AppIconSize, AppDuration tokens** - `603e67d7` (feat)
   - AppOpacity: 6 values (subtle 0.05 to heavy 0.80)
   - AppIconSize: 6 sizes (xs 16px to xxl 48px)
   - AppDuration: 4 durations (instant 50ms to slow 400ms)

4. **Task 4: Deprecate AppButton with migration guide** - `7f37e52a` (feat)
   - @Deprecated annotation added to AppButton class
   - Comprehensive migration guide in README.md with examples
   - Variant mapping, size mapping, and API differences documented

5. **Task 5: Add destructive variant to AppButtonEnhanced** - `4ae33ba1` (feat)
   - New destructive enum value in AppButtonVariant
   - Red error color with error-colored shadows
   - Hover/press states for tactile feedback

6. **Task 6: Verify migration status** - `50add696` (chore)
   - Searched entire codebase for AppButton usage
   - Found zero instances - no migration needed
   - Screens already using AppButtonEnhanced or TextButton

**Plan metadata:** Will be committed after SUMMARY creation

## Files Created/Modified

### Created:
- `lib/core/design_tokens/border_radius.dart` - Border radius token system (7 values)
- `lib/core/design_tokens/elevation.dart` - Elevation/shadow token system (6 levels + 2 glows)
- `lib/core/design_tokens/opacity.dart` - Opacity token system (6 values)
- `lib/core/design_tokens/icon_size.dart` - Icon size token system (6 sizes)
- `lib/core/design_tokens/duration.dart` - Animation duration token system (4 durations)

### Modified:
- `lib/core/widgets/app_button.dart` - Added @Deprecated annotation and doc comments
- `lib/core/widgets/app_button_enhanced.dart` - Added destructive variant with styling
- `lib/core/widgets/README.md` - Enhanced migration guide section with comprehensive examples

## Decisions Made

**Token value selections:**
- **Border radius**: Based on audit findings - consolidated 8 arbitrary values → 7 semantic values (10px→md, 20px→lg, 50px→full)
- **Elevation**: 6 standard BoxShadow presets + 2 specialty glows for premium features
- **Opacity**: 6 values covering full range from subtle backgrounds to heavy overlays
- **Icon sizes**: 16px to 48px range ensuring accessibility (48px meets touch target minimum)
- **Durations**: Material Design timing with bias toward faster (50-400ms) for modern feel

**Destructive variant design:**
- Uses AppColors.error (red) for high-contrast warning signal
- Error-colored shadows for visual consistency
- White text for readability on red background
- Hover/press states darker/lighter red for tactile feedback

**Migration strategy:**
- Deprecate but don't remove AppButton to allow gradual migration
- Comprehensive migration guide with examples prevents confusion
- IDE warnings guide developers to new pattern
- Removal planned for Phase 3 after verification all code migrated

## Deviations from Plan

### Discovery-based adjustment

**1. [Discovery] AppButton not used in codebase**
- **Found during:** Task 6 (Migration task)
- **Discovery:** Searched entire lib/ directory - zero AppButton instances found
- **Analysis:** Codebase never widely adopted AppButton component. Screens use either AppButtonEnhanced (already migrated) or standard Flutter buttons (TextButton, ElevatedButton)
- **Impact:** No migration work needed - task complete by absence of legacy code
- **Action taken:** Verified with comprehensive search, documented findings, committed empty commit for audit trail
- **Verification:** Searched lib/, lib/main_function/, target screens individually - all confirmed zero AppButton usage
- **Committed in:** 50add696

---

**Total deviations:** 1 discovery (task complete by absence)
**Impact on plan:** No scope change - deprecation and migration guide provide pattern for any future AppButton discoveries. Foundation token work completed as specified.

## Issues Encountered

None - plan executed exactly as written with one discovery (no AppButton instances to migrate).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Foundation tokens complete - ready for Phase 2-5 component work:**
- All 5 missing token systems created and verified
- Design token foundation now 100% complete:
  - ✅ AppColors (existing)
  - ✅ AppSpacing (existing)
  - ✅ AppTypography (existing)
  - ✅ AppBorderRadius (new)
  - ✅ AppElevation (new)
  - ✅ AppOpacity (new)
  - ✅ AppIconSize (new)
  - ✅ AppDuration (new)

**Button standardization complete:**
- AppButton deprecated with migration path
- AppButtonEnhanced has full variant coverage (primary, secondary, ghost, gradient, destructive)
- Migration guide ready for any future AppButton discoveries

**Blockers:** None

**Next step:** Ready for Plan 02-02 (Card standardization + duplication cleanup)

---
*Phase: 02-component-library-standardization*
*Completed: 2026-01-16*
