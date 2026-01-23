---
phase: 09-data-model-schema-audit
plan: 01
subsystem: database
tags: [firestore, schema-design, data-modeling, denormalization, validation]

# Dependency graph
requires:
  - phase: 08-file-structure-code-duplication-audit
    provides: Architectural violations context (16 direct Firestore access issues)
provides:
  - Comprehensive Firestore schema audit (9 collections, 120+ fields analyzed)
  - 47 prioritized schema issues with refactoring recommendations
  - Denormalization pattern analysis (good/bad/missing)
  - Pre-beta refactoring roadmap (90-120 hours estimated)
  - Schema design best practices guide
affects: [11-architectural-refactoring, data-model, query-performance, type-safety]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Enum over String for type-safe fields"
    - "Structured data classes over unstructured Maps"
    - "Intentional denormalization with sync triggers"
    - "snake_case field naming convention for Firestore"
    - "DocumentReference suffix pattern (userRef, courseRef)"

key-files:
  created:
    - .planning/phases/09-data-model-schema-audit/SCHEMA-DESIGN-AUDIT.md
  modified: []

key-decisions:
  - "Standardize on snake_case for Firestore field names"
  - "Enums + security rule validation for all type fields (game_type, scoring, etc.)"
  - "Remove uid field redundancy (use DocumentReference.id instead)"
  - "Complete users→memberIds migration in chats collection"
  - "Denormalize host info in games to eliminate N+1 queries"
  - "Structure vibe_profile as data class (not unstructured Map)"

patterns-established:
  - "Field naming: snake_case, timestamps end in _at, references end in Ref"
  - "Type safety: Enum classes for constrained strings"
  - "Denormalization: Identify read-heavy fields, add sync triggers"
  - "Validation: Security rules enforce enum values and required fields"

# Metrics
duration: 6min
completed: 2026-01-22
---

# Phase 09 Plan 01: Schema Design Audit Summary

**Comprehensive Firestore schema analysis identifying 47 issues across 9 collections with data model health score of 68/100**

## Performance

- **Duration:** 6 min
- **Started:** 2026-01-22T14:46:24Z
- **Completed:** 2026-01-22T14:52:09Z
- **Tasks:** 3 (all autonomous)
- **Files modified:** 1 created

## Accomplishments

- **9 collections analyzed field-by-field** (users, games, chats, chat_messages, friend_request, course, roles, add_players, verification_dash)
- **47 schema issues identified** with priorities: 8 Critical, 15 High, 18 Medium, 6 Low
- **Data model health score calculated**: 68/100 based on naming consistency (60), type safety (55), data integrity (70), query performance (75), security validation (80)
- **Denormalization audit complete**: 4 good patterns, 4 bad patterns, 3 missing patterns causing N+1 queries
- **Pre-beta refactoring roadmap**: 90-120 hours to fix Critical + High issues (23 of 47), health score improvement 68→85
- **Best practices guide created**: Field naming standards, when to denormalize, type safety patterns, validation rule templates
- **Cross-referenced Phase 8 findings**: Schema issues enable 16 direct Firestore access violations (unstructured vibe_profile forces widget logic)

## Task Commits

1. **Task 1: Analyze collection schema design** - `177a2881` (feat)
   - All 9 collections analyzed field-by-field
   - 32 individual issues documented (S-SCHEMA-001 through S-SCHEMA-032)
   - Issues include: naming inconsistencies, type mismatches, data redundancy, missing validation, legacy migrations incomplete

Tasks 2 and 3 integrated into comprehensive audit document (not separate commits).

**Plan metadata:** _(will be added in final commit)_

## Files Created/Modified

- `.planning/phases/09-data-model-schema-audit/SCHEMA-DESIGN-AUDIT.md` - Comprehensive 1545-line schema audit report

## Decisions Made

### Critical Architecture Decisions

1. **Field Naming Convention**: Standardize on **snake_case** for all Firestore field names
   - Rationale: Matches Firestore conventions, easier to read in console, current majority pattern
   - Impact: 14 naming inconsistency issues resolved, improves developer experience
   - Implementation: Apply during Phase 11 refactoring with data migration

2. **Type Safety Over Strings**: Replace free-form Strings with Enums for all constrained fields
   - Affected fields: `game_type`, `style_game`, `scoring`, `request_status`, `role`
   - Rationale: Prevents typos, enables IDE autocomplete, allows security rule validation
   - Pattern: Dart enum + security rule validation function

3. **uid Redundancy Elimination**: Remove `uid` fields where DocumentReference exists
   - Affected collections: users, games, friend_request
   - Rationale: Document ID IS the uid (Firestore convention), eliminates divergence risk
   - Implementation: Use `reference.id` accessor, migrate existing code

4. **Complete Chat Migration**: Finish users→memberIds migration in chats collection
   - Remove legacy fields: `users`, `user_a`, `user_b`, `lastMessageSentBy`
   - Keep modern fields: `memberIds`, `lastMessageSenderId`
   - Rationale: Single source of truth, simpler security rules, one index instead of two
   - Effort: 10-14 hours including migration script

5. **Denormalization Strategy**: Add intentional denormalization for read-heavy fields with sync triggers
   - Games: Denormalize `hostName`, `hostPhoto` (eliminate N+1 in game list)
   - Chats: Denormalize `memberNames` map (eliminate N lookups in chat list)
   - Friend Requests: Denormalize `requesterName`, `requesterPhoto`
   - Pattern: Cloud Function triggers maintain consistency when source docs update

### Data Model Decisions

6. **vibe_profile Structure**: Replace unstructured Map with VibeProfile data class
   - Current: `Map<String, dynamic>` with no schema
   - New: Structured class with `energyLevel`, `competitive`, `social`, `speed` (int 1-5)
   - Rationale: Type safety, autocomplete, enables vibe matching logic in provider
   - Connects to Phase 8: Enables extraction of vibe matching from widgets to VibeMatchProvider

7. **Notification Preferences Consolidation**: Replace 9 boolean fields with single Map
   - Current: `notify_all`, `notify_money_game`, `notify_vegas_game`, etc. (9 booleans)
   - New: Single `notification_prefs` Map with structure and versioning
   - Rationale: Extensible, smaller security rule surface, eliminates logic conflicts
   - Effort: 8-12 hours (large migration impact)

8. **Friends Array Scalability**: Keep short-term, plan subcollection migration
   - Short-term: Keep `friends` array (acceptable for <500 friends)
   - Remove: `friend_requests` array (use friend_request collection exclusively)
   - Long-term: Migrate to `users/{uid}/friends/{friendId}` subcollection
   - Rationale: Current design breaks at 500-1000 friends, subcollection has no size limit

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Next Phase Readiness

**Pre-Beta Blockers Identified** (must address before beta release):

### Critical Issues (P0 - 8 issues, 44-58 hours)

1. **S-SCHEMA-005**: users.friends array scalability (breaks at 1000 friends)
2. **S-SCHEMA-010**: games uid + userRef redundancy (divergence risk)
3. **S-SCHEMA-014**: games.joined_players mixed types (String vs DocumentReference)
4. **S-SCHEMA-016**: chats users vs memberIds incomplete migration
5. **S-SCHEMA-021**: Two chat message systems coexist (legacy + modern)
6. **S-SCHEMA-025**: friend_request missing timestamps (can't expire old requests)
7. **S-SCHEMA-027**: roles collection has no security rules (open security risk)
8. **S-SCHEMA-029**: add_players subcollection has no security rules

### High Priority Issues (P1 - 15 issues, 46-62 hours)

- Notification preferences explosion (9 booleans)
- vibe_profile unstructured Map
- date vs created_time confusion
- String fields that should be enums
- Missing denormalization (N+1 query risks)

### Quick Wins (5 issues, 10-15 hours)

High-impact, low-effort improvements that should be prioritized:
- Remove uid field redundancy (S-SCHEMA-006)
- Add role enum validation (S-SCHEMA-008)
- Add request_status enum (S-SCHEMA-022)
- Add friend_request timestamps (S-SCHEMA-025)
- Remove computed lastMessageSentBy property (S-SCHEMA-017)

**Phase 11 Recommended Scope**: Critical + High + Quick Wins = 100-135 hours (~12-17 days)
- Fixes 30 of 47 issues (64%)
- Improves health score from 68 → 85 (+17 points)
- Makes beta-ready: All security issues resolved, type safety established, N+1 queries eliminated

**Deferred to Post-Beta** (Medium/Low priority):
- Field naming standardization (36-48 hours)
- Documentation improvements
- Minor optimization opportunities

**Connection to Phase 8 Architectural Violations**:

Schema issues directly enable the 16 direct Firestore access violations found in Phase 8:
- Unstructured `vibe_profile` forces vibe matching logic into widgets (should be in VibeMatchProvider)
- Missing GameService due to inconsistent `joined_players` types (widgets handle type checking)
- No service layer because schema inconsistency makes centralized queries complex

Fixing Critical + High schema issues prerequisite for Phase 11 architectural refactoring.

---

**Phase: 09-data-model-schema-audit**
**Completed: 2026-01-22**
