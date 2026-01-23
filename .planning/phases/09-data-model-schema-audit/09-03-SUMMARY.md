---
phase: 09-data-model-schema-audit
plan: 03
subsystem: database
tags: [firestore, relationships, referential-integrity, data-model, cloud-functions, cascading-deletes, GDPR]

# Dependency graph
requires:
  - phase: 08-file-structure-code-duplication-audit
    provides: Architectural understanding of direct Firestore access patterns
provides:
  - Comprehensive relationship map across all Firestore collections
  - Orphaned data risk analysis for all deletion scenarios
  - Cloud Functions audit for cascading operations
  - Phase 11 integrity roadmap with prioritized fixes
affects: [11-architecture-refactoring, data-migration, GDPR-compliance]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "DocumentReference vs String UID relationship patterns"
    - "Cascading delete via Cloud Functions"
    - "Soft delete pattern (isCancelled flag)"
    - "Bidirectional relationship management"

key-files:
  created: [.planning/phases/09-data-model-schema-audit/DATA-RELATIONSHIPS-AUDIT.md]
  modified: []

key-decisions:
  - "Identified 23 relationship issues requiring fixes (8 critical, 9 high, 6 medium priority)"
  - "Data integrity health score: 58/100 - significant room for improvement"
  - "Critical pre-beta fixes: 4 issues, 24-32 hours estimated effort"
  - "Standardize on DocumentReference for entity references (not String UID)"
  - "Chat messages subcollection cleanup is highest priority (storage leak + GDPR)"
  - "Comprehensive user deletion cascade needed for GDPR compliance"

patterns-established:
  - "Relationship audit methodology: map, analyze integrity, check cascading, prioritize fixes"
  - "Orphaned data risk matrix with priority levels (Critical/High/Medium/Low)"
  - "Cloud Functions gap analysis (existing vs recommended triggers)"
  - "Migration strategy for breaking changes (String → DocumentReference)"

# Metrics
duration: 9min
completed: 2026-01-22
---

# Phase 09-03: Data Relationships Audit Summary

**Comprehensive audit identifying 23 relationship integrity issues with 58/100 health score; critical pre-beta fixes prioritized**

## Performance

- **Duration:** 9 min
- **Started:** 2026-01-23T02:59:58Z
- **Completed:** 2026-01-23T03:09:08Z
- **Tasks:** 3/3
- **Files modified:** 1

## Accomplishments

- **Mapped all Firestore relationships** across 6 collections (users, games, chats, friend_request, course, chat_messages)
- **Identified 23 relationship issues:** 8 critical, 9 high, 6 medium priority
- **Documented orphaned data risks** for all deletion scenarios (user, game, chat, friend request)
- **Audited Cloud Functions:** 1 existing cleanup function (onUserDeleted), 6 recommended new triggers
- **Created Phase 11 integrity roadmap:** Prioritized 40-56 hours of critical + high priority fixes for beta
- **Calculated data integrity health score:** 58/100 with detailed breakdown

## Task Commits

All tasks were completed in a single comprehensive audit commit:

1. **Task 1-3: Complete data relationships audit** - `29fc1b35` (feat)
   - Mapped all relationship patterns (DocumentReference vs String UID inconsistencies)
   - Identified orphaned data risks (chat messages subcollection, user deletion cascades)
   - Generated integrity roadmap with Cloud Function recommendations

**Plan metadata:** (to be committed separately)

## Files Created/Modified

- `.planning/phases/09-data-model-schema-audit/DATA-RELATIONSHIPS-AUDIT.md` - Comprehensive 1,729-line audit report with:
  - Executive summary with critical findings
  - Complete relationship diagram for all collections
  - 16 detailed relationship issues (R-REL-001 through R-REL-016)
  - Consistency issues summary table
  - Orphaned data risk matrix
  - Cloud Functions audit (existing + recommended)
  - Phase 11 integrity roadmap with effort estimates
  - Best practices guide for relationship design
  - Data migration strategy

## Decisions Made

**Critical Findings:**

1. **Mixed relationship patterns (R-REL-001, R-REL-002):**
   - Games use both `userRef` (DocumentReference) and `uid` (String) for same relationship
   - Chats use both `users[]` (DocumentReference) and `memberIds[]` (String) for members
   - **Decision:** Standardize on DocumentReference for entities, String UID only for security rules

2. **Chat messages subcollection orphaning (R-REL-003):**
   - Firestore doesn't auto-delete subcollections when parent deleted
   - Messages orphaned when chat deleted (storage leak + inaccessible data)
   - **Decision:** Create `cleanupChatMessages` Cloud Function (highest priority fix)

3. **Incomplete user deletion cascade (R-REL-005):**
   - Existing `onUserDeleted` only cleans up friends arrays and legacy chat_messages
   - Doesn't clean up: games (host + participant), chats, friend requests, message subcollections
   - **Decision:** Enhance for comprehensive cleanup (GDPR compliance requirement)

4. **Game-chat relationship inconsistency (R-REL-004):**
   - Games → Chats uses DocumentReference (games.chatRef)
   - Chats → Games uses String (chats.gameId) instead of DocumentReference
   - **Decision:** Convert chats.gameId to DocumentReference for consistency

5. **Course reference pattern (R-REL-006):**
   - Games use DocumentReference (games.courseRef) - correct
   - Users use String name (users.home_course) - brittle and stale-prone
   - **Decision:** Migrate users.home_course to DocumentReference

**Prioritization for Beta:**

- **Must fix (24-32 hours):**
  1. Chat messages cleanup function
  2. Game-chat relationship standardization
  3. Legacy chat members migration
  4. Game host duplication removal

- **Strongly recommended (16-24 hours):**
  5. Comprehensive user deletion cascade
  6. Transaction-based friend requests
  7. Course reference standardization

- **Post-beta technical debt:**
  8. Bidirectional game tracking
  9. Legacy chat_messages cleanup
  10. Friend request status workflow

## Deviations from Plan

None - plan executed exactly as written. All three tasks completed:
1. ✅ Mapped all data relationships and DocumentReference patterns
2. ✅ Identified orphaned data risks and cascading operation gaps
3. ✅ Generated relationship integrity roadmap and best practices

## Issues Encountered

None - audit completed successfully with comprehensive findings.

## Next Phase Readiness

**Data model issues identified for Phase 11 (Architecture Refactoring):**

- 23 relationship issues documented with detailed remediation plans
- Cloud Functions specifications ready for implementation
- Migration strategies documented for breaking changes
- Best practices guide established for relationship design
- Total effort estimated: 48-68 hours (critical + high + medium fixes)

**Critical Path for Beta:**
- Must address 4 critical issues (40-56 hours with strongly recommended fixes)
- Creates 2-week sprint for Phase 11 data integrity work
- GDPR compliance requires comprehensive user deletion cascade

**Blockers:** None - audit is complete, Phase 11 can begin planning.

**Concerns:**
- Data integrity health score of 58/100 indicates significant technical debt
- Some issues (like chat messages subcollection cleanup) are storage leaks affecting all users
- GDPR compliance at risk without comprehensive user deletion cascade
- Mixed relationship patterns create developer confusion and potential bugs

---
*Phase: 09-data-model-schema-audit*
*Completed: 2026-01-22*
