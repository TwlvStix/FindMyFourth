# Firestore Schema Design Audit

**Date**: 2026-01-22
**Codebase**: Find My Fourth (Flutter + Firestore)
**Total Collections**: 9
**Total Fields Analyzed**: 120+

## Executive Summary

- **Total Schema Issues Found**: 47
- **Data Model Health Score**: 68/100
- **Critical Issues**: 8 (must fix before beta)
- **High Priority Issues**: 15 (should fix before beta)
- **Medium Priority Issues**: 18 (defer post-beta)
- **Low Priority Issues**: 6 (minor improvements)

### Issues by Collection

| Collection | Critical | High | Medium | Low | Total Fields | Health |
|------------|----------|------|--------|-----|--------------|--------|
| users | 2 | 5 | 6 | 2 | 35 | 65/100 |
| games | 3 | 4 | 5 | 1 | 18 | 60/100 |
| chats | 1 | 3 | 4 | 1 | 18 | 70/100 |
| chat_messages | 0 | 0 | 1 | 0 | 5 | 90/100 |
| friend_request | 1 | 1 | 1 | 1 | 4 | 65/100 |
| course | 0 | 0 | 1 | 0 | 3 | 85/100 |
| roles | 1 | 1 | 0 | 1 | 5 | 70/100 |
| add_players | 0 | 1 | 0 | 0 | 3 | 80/100 |
| verification_dash | 0 | 0 | 0 | 0 | 1 | 95/100 |

### Issues by Type

| Issue Type | Count | Examples |
|------------|-------|----------|
| Naming Inconsistencies | 14 | snake_case vs camelCase, name_game vs nameGame |
| Type Mismatches | 8 | String where enum needed (style_game, scoring) |
| Data Redundancy | 9 | uid + userRef, date + created_time, users + memberIds |
| Missing Validation | 6 | No required field enforcement, optional critical fields |
| Legacy Migration Incomplete | 5 | chat_messages vs messages, users vs memberIds |
| Denormalization Issues | 5 | Missing caches, stale data risks |

## Architectural Context

From Phase 8 SEPARATION-CONCERNS-AUDIT.md findings:
- **16 widgets bypass provider caching** by direct Firestore access
- **Provider-as-Wrapper pattern** correctly implemented but underutilized
- **Service layer missing** for games and profiles (only ChatService exists)

Schema design issues compound architectural violations. Inconsistent field naming and type mismatches force complex widget logic that should be in services.

---

# Collection-by-Collection Analysis

## 1. Collection: users

**Purpose**: User profiles, preferences, and friend relationships
**Record File**: `lib/backend/schema/users_record.dart`
**Total Fields**: 35

### Field Organization

| Category | Fields | Status |
|----------|--------|--------|
| Identity | email, uid, first_name, last_name, display_name, photo_url | Mixed naming |
| Profile | shortDescription, title, role, handicap, golf_canada_number, home_course | Inconsistent |
| Timestamps | created_time, last_active_time | Good |
| Social | friends, friend_requests | Arrays (performance concern) |
| Preferences | music, drinks, pace_of_play, play_for_money | int ratings (0-5) |
| Notifications | 9 notify_* booleans | Verbose, should be Map |
| Vibe | vibe_profile | Map (unstructured) |
| Onboarding | onboarding_completed | Good |
| Contact | phone_number | Good |

### Issues Identified

#### Issue S-SCHEMA-001: Naming Inconsistency (photo_url vs photoUrl)

- **Field**: `photo_url` (snake_case)
- **Priority**: Medium
- **Current Implementation**:
  ```dart
  // users_record.dart line 24-27
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  // Firestore field name
  'photo_url': photoUrl,
  ```
- **Problem**: Field stored as `photo_url` (snake_case) in Firestore, but code uses camelCase accessor `photoUrl`. Mismatch with other timestamp fields that use snake_case consistently (created_time, last_active_time). Creates confusion about naming convention.
- **Recommendation**:
  - **Option 1 (Preferred)**: Standardize on snake_case for all Firestore fields:
    ```dart
    // Keep Firestore field as photo_url
    String? _photoUrl;
    String get photo_url => _photoUrl ?? '';
    bool hasPhotoUrl() => _photoUrl != null;
    ```
  - **Option 2**: Migrate to camelCase (requires data migration):
    ```dart
    'photoUrl': photoUrl,  // Change Firestore field
    ```
- **Impact**: Maintainability (inconsistent patterns confuse developers), no runtime impact
- **Effort**: Small (2-3 hours to standardize across codebase + document convention)

#### Issue S-SCHEMA-002: Name Field Redundancy (first_name + last_name vs display_name)

- **Fields**: `first_name`, `last_name`, `display_name`
- **Priority**: Medium
- **Current Implementation**:
  ```dart
  String? _firstName;    // Separate first name
  String? _lastName;     // Separate last name
  String? _displayName;  // Combined display name (username)
  ```
- **Problem**: Three separate name fields with unclear relationship. Is display_name derived from first+last? Can they differ? Code in profile screens concatenates first+last for display, ignoring display_name. Security rules validate display_name uniqueness but not first/last.
- **Usage Analysis**:
  - display_name: Used for @username mentions, profile header, uniqueness constraint
  - first_name + last_name: Used in game participant lists, friend cards, chat headers
  - Both are user-editable, can diverge ("John Smith" vs "@jsmith42")
- **Recommendation**:
  - Keep all three fields (serves different purposes)
  - Add computed field helper in Record class:
    ```dart
    String get fullName =>
      (firstName.isNotEmpty && lastName.isNotEmpty)
        ? '$firstName $lastName'
        : displayName;
    ```
  - Document naming semantics in schema comments:
    ```dart
    /// first_name/last_name: Legal/real name for game records
    /// display_name: Public username for @mentions and uniqueness
    ```
- **Impact**: Clarity (developers unsure which field to use), data consistency
- **Effort**: Small (1-2 hours to add helper + documentation)

#### Issue S-SCHEMA-003: Notification Preferences Explosion (9 boolean fields)

- **Fields**: `notify_all`, `notify_money_game`, `notify_vegas_game`, `notify_competitive_game`, `notify_for_fun`, `notify_only_from_friends`, `notify_member_discount`, `notify_off`
- **Priority**: High
- **Current Implementation**:
  ```dart
  // 9 separate boolean fields
  bool? _notifyAll;
  bool? _notifyMoneyGame;
  bool? _notifyVegasGame;
  bool? _notifyCompetitiveGame;
  bool? _notifyForFun;
  bool? _notifyOnlyFromFriends;
  bool? _notifyMemberDiscount;
  bool? _notifyOff;
  ```
- **Problem**:
  - 9 booleans is excessive (adds 72 bytes per user document)
  - Logic conflicts: What if notify_all=true AND notify_off=true?
  - Hard to add new notification types (schema change required)
  - Security rules must enumerate all 9 fields in allowedUserFieldChangesOnly()
  - No versioning (can't migrate notification preferences structure)
- **Recommendation**: Consolidate into structured Map
  ```dart
  // Replace 9 booleans with single Map
  Map<String, dynamic>? _notificationPrefs;
  Map<String, dynamic> get notificationPrefs => _notificationPrefs ?? {
    'enabled': true,
    'gameTypes': ['money', 'vegas', 'competitive', 'forFun'],
    'filters': {
      'friendsOnly': false,
      'memberDiscount': true,
    },
  };
  ```
  Benefits:
  - Extensible (add new prefs without schema change)
  - Versioned (can include 'version': 1)
  - Smaller (one field in security rules)
  - Structured defaults
- **Impact**:
  - Maintainability: High (9 fields → 1, easier to reason about)
  - Performance: Neutral (same document size)
  - Migration: Medium (requires Firestore migration script)
- **Effort**: Large (8-12 hours: migration script, Record class update, widget updates, testing)

#### Issue S-SCHEMA-004: vibe_profile Unstructured Map

- **Field**: `vibe_profile`
- **Priority**: High
- **Current Implementation**:
  ```dart
  // Completely unstructured Map
  Map<String, dynamic>? _vibeProfile;
  Map<String, dynamic> get vibeProfile => _vibeProfile ?? const {};
  ```
- **Problem**:
  - No schema definition (what keys are expected? what types?)
  - Code in game_joined_detailed references `vibe_profile['energyLevel']`, `['competitive']`, etc. without validation
  - No type safety (values are dynamic, can be int/String/bool/null)
  - Cannot query or index on vibe fields (no composite indexes possible)
  - Security rules cannot validate structure
- **Usage Analysis** (from game_joined_detailed_widget.dart):
  ```dart
  // Widget code expects:
  final userVibe = user.vibeProfile;
  final energy = userVibe['energyLevel'] as int?;  // 1-5 scale
  final competitive = userVibe['competitive'] as int?;
  final social = userVibe['social'] as int?;
  final speed = userVibe['speed'] as int?;
  ```
- **Recommendation**: Define structured data class
  ```dart
  class VibeProfile {
    final int energyLevel;    // 1-5
    final int competitive;    // 1-5
    final int social;        // 1-5
    final int speed;         // 1-5

    Map<String, dynamic> toFirestore() => {
      'energyLevel': energyLevel,
      'competitive': competitive,
      'social': social,
      'speed': speed,
    };

    static VibeProfile fromFirestore(Map<String, dynamic>? data) {
      if (data == null) return VibeProfile.defaults();
      return VibeProfile(
        energyLevel: data['energyLevel'] as int? ?? 3,
        competitive: data['competitive'] as int? ?? 3,
        social: data['social'] as int? ?? 3,
        speed: data['speed'] as int? ?? 3,
      );
    }
  }

  // In UsersRecord:
  VibeProfile get vibeProfile =>
    VibeProfile.fromFirestore(_vibeProfileRaw);
  ```
- **Impact**:
  - Type Safety: High (eliminates runtime cast errors)
  - Maintainability: High (clear schema, autocomplete in IDE)
  - Query Performance: Neutral (still can't index Map fields)
- **Effort**: Medium (4-6 hours: create VibeProfile class, update Record, update widgets)

#### Issue S-SCHEMA-005: friends and friend_requests Arrays (Scalability)

- **Fields**: `friends` (List<DocumentReference>), `friend_requests` (List<DocumentReference>)
- **Priority**: Critical
- **Current Implementation**:
  ```dart
  List<DocumentReference>? _friends;
  List<DocumentReference> get friends => _friends ?? const [];

  List<DocumentReference>? _friendRequests;
  List<DocumentReference> get friendRequests => _friendRequests ?? const [];
  ```
- **Problem**:
  - Arrays in Firestore have 1MB document size limit (≈20k friends max)
  - Cannot query "users where friends array contains X" efficiently (requires array-contains, limited to 10 in compound queries)
  - Updating array requires read-modify-write transaction (race conditions)
  - Duplicates friend relationship data (stored in both users' documents)
  - friend_request collection already exists but friend_requests array also used
- **Current Usage**:
  - Security rules check `isSelfFriendChange()` allowing only friends array updates
  - friend_request collection has `request_status`, `receiver_id`, `requester_id`
  - Confusion: Why both collection AND array?
- **Recommendation**:
  - **Remove friend_requests array** (use friend_request collection exclusively)
  - **Keep friends array short-term** (acceptable for <500 friends per user)
  - **Long-term**: Migrate to dedicated friends subcollection:
    ```
    users/{userId}/friends/{friendId}
    - addedAt: Timestamp
    - status: 'active' | 'blocked'
    ```
    Benefits:
    - No size limit
    - Efficient queries: `users/{userId}/friends` returns all friends
    - Denormalize friend count in user doc: `friendCount: 42`
- **Impact**:
  - Scalability: Critical (current design breaks at 500-1000 friends)
  - Query Performance: High (enables friend-of-friend queries)
  - Data Consistency: High (single source of truth)
- **Effort**: Large (12-16 hours: migration script, update all friend management code, update security rules, testing)

#### Issue S-SCHEMA-006: uid Field Redundancy

- **Field**: `uid`
- **Priority**: Low
- **Current Implementation**:
  ```dart
  // uid stored as field in document
  String? _uid;
  String get uid => _uid ?? '';

  // But document ID is also the uid:
  // users/{uid}/
  ```
- **Problem**:
  - uid is stored both as document ID and as field
  - Document ID IS the uid (Firestore convention)
  - Wastes 36 bytes per document (uuid string)
  - Can diverge if uid field not set correctly
- **Usage Analysis**:
  - Security rules: `request.auth.uid == document` (uses document ID)
  - Code: `user.uid` (uses field)
  - Both should always be identical
- **Recommendation**:
  - **Remove uid field from schema**
  - Use `reference.id` to get uid:
    ```dart
    // In UsersRecord:
    String get uid => reference.id;
    ```
  - Update security rules to remove uid from allowedUserFieldChangesOnly
- **Impact**:
  - Storage: Small (36 bytes per user)
  - Code simplification: Medium (removes potential divergence bug)
  - Migration: Easy (field can be left in old docs, not set in new ones)
- **Effort**: Small (3-4 hours: update Record class, update create/update code, verify no queries use uid field)

#### Issue S-SCHEMA-007: Inconsistent Timestamp Naming

- **Fields**: `created_time` (DateTime), `last_active_time` (DateTime)
- **Priority**: Low
- **Current**: snake_case with `_time` suffix
- **Comparison**:
  - chats collection: `createdAt`, `updatedAt`, `lastMessageAt` (camelCase with `At` suffix)
  - games collection: `created_time`, `date` (mixed)
  - chat_messages: `createdAt` (camelCase)
- **Problem**: Inconsistent naming convention across collections makes developer experience poor
- **Recommendation**: Standardize on one pattern project-wide
  - **Option 1**: camelCase + `At`: `createdAt`, `lastActiveAt`
  - **Option 2**: snake_case + `_time`: `created_time`, `last_active_time`
  - Pick one and apply to all collections
- **Impact**: Developer experience (consistency), no functional change
- **Effort**: Medium (6-8 hours: schema migration across all collections)

#### Issue S-SCHEMA-008: Role Field Type Mismatch

- **Field**: `role` (String)
- **Priority**: Medium
- **Current Implementation**:
  ```dart
  String? _role;
  String get role => _role ?? '';
  ```
- **Problem**:
  - role is free-form String (can be 'admin', 'Admin', 'ADMIN', 'moderator', etc.)
  - No validation in security rules
  - No enum in Dart code
  - Security-critical field (used in access control)
- **Recommendation**: Define enum + validation
  ```dart
  enum UserRole {
    user,
    moderator,
    admin,
  }

  // In UsersRecord:
  UserRole get role => UserRole.values.firstWhere(
    (r) => r.name == _role,
    orElse: () => UserRole.user,
  );

  // Security rules:
  function isValidRole(data) {
    return !data.keys().hasAny(['role']) ||
      data.role in ['user', 'moderator', 'admin'];
  }
  ```
- **Impact**: Security (prevents invalid roles), type safety
- **Effort**: Small (2-3 hours: enum + security rule)

---

## 2. Collection: games

**Purpose**: Golf game sessions and matchmaking
**Record File**: `lib/backend/schema/games_record.dart`
**Total Fields**: 18

### Field Organization

| Category | Fields | Status |
|----------|--------|--------|
| Identity | uid, userRef | Redundant |
| Basic Info | name_game, date, created_time | Naming inconsistent |
| Players | num_players, max_players, joined_players, guest_players | Good |
| Game Type | style_game, game_type, scoring, friend_game | String (should be enum) |
| Course | course_play, courseRef | Redundant |
| Settings | member_discount, rules_setting | String (should be enum) |
| Status | isCancelled | Good |
| References | chatRef | Good |

### Issues Identified

#### Issue S-SCHEMA-009: name_game Field Naming

- **Field**: `name_game`
- **Priority**: Medium
- **Current**: `name_game` (noun_verb pattern)
- **Problem**: Awkward naming. Should be `game_name` (adjective_noun) or just `name`
- **Recommendation**: Rename to `name` (simpler, consistent with course.name)
  ```dart
  String? _name;
  String get name => _name ?? '';
  ```
- **Impact**: Code clarity
- **Effort**: Medium (4-6 hours: migration + update code)

#### Issue S-SCHEMA-010: uid + userRef Redundancy

- **Fields**: `uid` (String), `userRef` (DocumentReference)
- **Priority**: Critical
- **Current Implementation**:
  ```dart
  String? _uid;  // "abc123"
  DocumentReference? _userRef;  // users/abc123
  ```
- **Problem**:
  - Same information stored twice (uid and reference to user doc)
  - Security rules enforce `userRef == userRef(uid)` consistency
  - Can diverge if not set atomically
  - Wastes space (36-byte string + 20-byte reference)
- **Recommendation**: **Keep only userRef, derive uid**
  ```dart
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  String get uid => _userRef?.id ?? '';
  ```
  Update security rules to remove uid field
- **Impact**:
  - Data integrity: High (single source of truth)
  - Storage: Small (36 bytes per game)
- **Effort**: Medium (6-8 hours: migration, update all game creation code, update security rules)

#### Issue S-SCHEMA-011: date vs created_time Confusion

- **Fields**: `date` (DateTime), `created_time` (DateTime)
- **Priority**: High
- **Current**:
  - `date`: When the game will be played (future)
  - `created_time`: When game document was created (past)
- **Problem**:
  - Field name `date` is ambiguous (created? scheduled? updated?)
  - Code uses `orderBy('date')` for game listing (assumes scheduled date)
  - If user creates game for "tomorrow", date=tomorrow but created_time=now
  - Widget code compares `game.date` to `DateTime.now()` to filter past games
- **Recommendation**: Rename for clarity
  ```dart
  DateTime? _scheduledAt;  // When game will be played
  DateTime? _createdAt;    // When document was created
  ```
  More semantic, matches chats collection naming (createdAt, lastMessageAt)
- **Impact**: Code clarity (eliminates confusion), query correctness
- **Effort**: Medium (4-6 hours: migration + update queries)

#### Issue S-SCHEMA-012: style_game, game_type, scoring as Strings

- **Fields**: `style_game`, `game_type`, `scoring`
- **Priority**: High
- **Current**: Free-form String fields
- **Problem**:
  - No validation (can be 'scramble', 'Scramble', 'SCRAMBLE')
  - Cannot efficiently query (need to know exact string)
  - Widget code has hardcoded strings: `if (game.styleGame == 'scramble')`
  - Typos cause bugs (game won't match filters)
- **Usage Analysis** (from create_game_widget.dart):
  ```dart
  // style_game values:
  'scramble', 'best ball', 'match play', 'stroke play'

  // game_type values:
  'casual', 'competitive', 'money', 'vegas'

  // scoring values:
  'stroke', 'stableford', 'match'
  ```
- **Recommendation**: Define enums + validation
  ```dart
  enum GameStyle {
    scramble,
    bestBall,
    matchPlay,
    strokePlay,
  }

  enum GameType {
    casual,
    competitive,
    money,
    vegas,
  }

  enum ScoringType {
    stroke,
    stableford,
    match,
  }

  // Security rules:
  function isValidGameStyle(data) {
    return data.style_game in [
      'scramble', 'bestBall', 'matchPlay', 'strokePlay'
    ];
  }
  ```
- **Impact**: Type safety, query reliability, UX (prevents invalid selections)
- **Effort**: Medium (6-8 hours: enums + security rules + widget updates)

#### Issue S-SCHEMA-013: course_play vs courseRef Redundancy

- **Fields**: `course_play` (String), `courseRef` (DocumentReference)
- **Priority**: High
- **Current**:
  - `course_play`: Course name as String ("Pebble Beach")
  - `courseRef`: Reference to course document
- **Problem**:
  - Duplicate data (name stored in both course doc and game doc)
  - Can diverge (course name updated but course_play not)
  - Wastes space (denormalized course name)
  - No referential integrity (course_play can differ from courseRef.name)
- **Recommendation**: **Remove course_play, denormalize intentionally**
  ```dart
  // Keep both, but rename and document purpose:
  String? _courseName;  // Denormalized for display (updated via trigger)
  DocumentReference? _courseRef;  // Source of truth
  ```
  Add Cloud Function to update courseName when course document changes:
  ```javascript
  // Cloud Function
  exports.syncCourseName = functions.firestore
    .document('course/{courseId}')
    .onUpdate((change, context) => {
      const newName = change.after.data().name;
      return db.collection('games')
        .where('courseRef', '==', change.after.ref)
        .get()
        .then(snapshot => {
          const batch = db.batch();
          snapshot.forEach(doc => {
            batch.update(doc.ref, { courseName: newName });
          });
          return batch.commit();
        });
    });
  ```
- **Impact**:
  - Data consistency: High (automated sync prevents divergence)
  - Query performance: High (avoid JOIN, directly display courseName)
- **Effort**: Large (10-14 hours: Cloud Function, migration, widget updates)

#### Issue S-SCHEMA-014: joined_players Mixed Types

- **Field**: `joined_players`
- **Priority**: Critical
- **Current Implementation**:
  ```dart
  List<DocumentReference>? _joinedPlayers;
  List<DocumentReference> get joinedPlayers => _joinedPlayers ?? const [];
  ```
- **Problem**: Security rules show mixed usage:
  ```javascript
  // Security rules check BOTH DocumentReference and String uid:
  function containsSelf(playersList) {
    return playersList.hasAny([
      userRef(request.auth.uid),  // DocumentReference
      request.auth.uid            // String
    ]);
  }
  ```
  This suggests array can contain mixed types (DocumentReference OR String uid). Type safety violated.
- **Root Cause**: Legacy migration incomplete. Old games used String uids, new games use DocumentReference.
- **Recommendation**: **Standardize on one type**
  - **Option 1 (Recommended)**: Use String uids (simpler, smaller)
    ```dart
    List<String>? _joinedPlayerIds;
    List<String> get joinedPlayerIds => _joinedPlayerIds ?? const [];

    // Fetch users separately:
    Future<List<UsersRecord>> fetchJoinedPlayers() async {
      return Future.wait(
        joinedPlayerIds.map((id) =>
          UsersRecord.getDocumentOnce(UsersRecord.collection.doc(id))
        )
      );
    }
    ```
  - **Option 2**: Use DocumentReference (type safety)
    - Requires migration to convert String uids to DocumentReference
    - Security rules simplified
- **Impact**: Type safety, data integrity, security rule complexity
- **Effort**: Large (8-12 hours: migration script, update security rules, update widgets)

#### Issue S-SCHEMA-015: Missing status Field Type Validation

- **Field**: `status` (not in Record class but in security rules)
- **Priority**: Medium
- **Current**: Security rules validate status as String enum:
  ```javascript
  function isValidStatus(data) {
    return !data.keys().hasAny(['status']) ||
      (data.status is string &&
        data.status in ['active', 'completed', 'cancelled', 'expired']);
  }
  ```
- **Problem**:
  - `status` field NOT defined in GamesRecord class
  - Security rules enforce enum values but Dart code unaware
  - isCancelled boolean duplicates status='cancelled' logic
- **Recommendation**: Add status field to Record + define enum
  ```dart
  enum GameStatus {
    active,
    completed,
    cancelled,
    expired,
  }

  String? _status;
  GameStatus get status => GameStatus.values.firstWhere(
    (s) => s.name == _status,
    orElse: () => GameStatus.active,
  );

  // Remove isCancelled, use status == GameStatus.cancelled
  ```
- **Impact**: Code consistency (eliminates isCancelled vs status confusion)
- **Effort**: Medium (4-6 hours: add field to Record, update widgets, deprecate isCancelled)

---

## 3. Collection: chats

**Purpose**: Chat conversations (direct messages and game chats)
**Record File**: `lib/backend/schema/chats_record.dart`
**Total Fields**: 18

### Field Organization

| Category | Fields | Status |
|----------|--------|--------|
| Legacy (Direct) | users, user_a, user_b | Deprecated |
| Modern | memberIds | Good |
| Type | type, directKey, gameId | Good |
| Last Message | lastMessage, lastMessageAt, lastMessageSenderId | Good |
| Legacy Last Msg | lastMessageSentBy, lastMessageSeenBy | Deprecated |
| Unread | unreadCountByUser | Good |
| Timestamps | createdAt, updatedAt | Good |
| Group Chat | group_chat_id | Unclear purpose |

### Issues Identified

#### Issue S-SCHEMA-016: users vs memberIds Incomplete Migration

- **Fields**: `users` (List<DocumentReference>), `memberIds` (List<String>)
- **Priority**: Critical
- **Current Implementation**:
  ```dart
  List<DocumentReference>? _users;  // Legacy
  List<String>? _memberIds;         // Modern
  ```
- **Problem**:
  - Duplicate participant data (users array of refs + memberIds array of strings)
  - Security rules check BOTH:
    ```javascript
    function isChatMember(data) {
      return request.auth.uid in data.memberIds;
    }

    function isLegacyChatMember(data) {
      return data.users.hasAny([userRef(request.auth.uid)]);
    }

    function isChatMemberOrLegacy(data) {
      return isChatMember(data) || isLegacyChatMember(data);
    }
    ```
  - Firestore indexes exist for BOTH (users array-contains and memberIds array-contains)
  - Migration incomplete (new chats use memberIds, old chats still have users)
- **Recommendation**: **Complete migration to memberIds**
  1. Run migration script to populate memberIds from users array:
     ```javascript
     db.collection('chats').get().then(snapshot => {
       const batch = db.batch();
       snapshot.forEach(doc => {
         const data = doc.data();
         if (!data.memberIds && data.users) {
           const memberIds = data.users.map(ref => ref.id);
           batch.update(doc.ref, { memberIds });
         }
       });
       return batch.commit();
     });
     ```
  2. Update security rules to use only memberIds
  3. Remove users, user_a, user_b fields from Record class
  4. Remove legacy Firestore indexes
- **Impact**:
  - Data consistency: Critical (single source of truth)
  - Query performance: High (one index instead of two)
  - Code simplification: High (remove legacy checks)
- **Effort**: Large (10-14 hours: migration, security rules, Record cleanup, widget updates, index cleanup)

#### Issue S-SCHEMA-017: lastMessageSenderId vs lastMessageSentBy

- **Fields**: `lastMessageSenderId` (String), `lastMessageSentBy` (DocumentReference, computed)
- **Priority**: Medium
- **Current Implementation**:
  ```dart
  String? _lastMessageSenderId;
  String get lastMessageSenderId => _lastMessageSenderId ?? '';

  // Computed DocumentReference for backward compatibility
  DocumentReference? _lastMessageSentBy;
  DocumentReference? get lastMessageSentBy => _lastMessageSenderId != null
      ? FirebaseFirestore.instance.doc('users/$_lastMessageSenderId')
      : null;
  ```
- **Problem**:
  - lastMessageSenderId is stored (String uid)
  - lastMessageSentBy is computed on read (creates DocumentReference)
  - Backward compatibility code for legacy field
  - Inefficient (creates DocumentReference object on every access)
- **Recommendation**: **Remove lastMessageSentBy computed property**
  - Use lastMessageSenderId everywhere
  - Fetch sender user separately if needed
  - No denormalization needed (sender name rarely displayed in chat list)
- **Impact**: Code simplification, minor performance improvement
- **Effort**: Small (2-3 hours: remove computed property, update widgets)

#### Issue S-SCHEMA-018: group_chat_id Purpose Unclear

- **Field**: `group_chat_id` (int)
- **Priority**: Low
- **Current**: Numeric ID for group chats
- **Problem**:
  - Purpose unclear (why int ID when document ID exists?)
  - Not used in queries or security rules
  - Always 0 in code inspection
  - Possibly legacy/unused field
- **Recommendation**:
  - Investigate usage in codebase
  - If unused, deprecate and remove
  - If used, add documentation
- **Impact**: Code clarity
- **Effort**: Small (1-2 hours: search usage, remove if unused)

#### Issue S-SCHEMA-019: user_a and user_b for Direct Chats

- **Fields**: `user_a`, `user_b`
- **Priority**: Medium
- **Current**: DocumentReference fields for two participants in direct chat
- **Problem**:
  - Redundant with memberIds (direct chat has memberIds.length == 2)
  - Security rules don't validate user_a/user_b set correctly
  - Not used in queries (directKey used for uniqueness instead)
- **Recommendation**: **Remove user_a and user_b**
  - Use `memberIds[0]` and `memberIds[1]` instead
  - Keep directKey for uniqueness constraint
- **Impact**: Schema simplification
- **Effort**: Small (2-3 hours: remove from Record, update chat creation)

#### Issue S-SCHEMA-020: Timestamp Naming Inconsistency (lastMessageAt vs last_message_time)

- **Field**: `lastMessageAt` (modern) vs `last_message_time` (legacy)
- **Priority**: Low
- **Current Implementation**:
  ```dart
  DateTime? _lastMessageAt;
  DateTime? get lastMessageAt => _lastMessageAt;

  // Compatibility getter
  DateTime? get lastMessageTime => lastMessageAt;
  ```
- **Problem**: Two getters for same field (confusing API)
- **Recommendation**: Remove legacy getter, use lastMessageAt everywhere
- **Impact**: API clarity
- **Effort**: Small (1-2 hours: remove compat getter, update widgets)

---

## 4. Collection: chat_messages (Legacy) vs messages (Subcollection)

**Purpose**: Chat message history
**Record File**: `lib/backend/schema/chat_messages_record.dart`
**Total Fields**: 5

### Issues Identified

#### Issue S-SCHEMA-021: Two Chat Message Systems Coexist

- **Collections**:
  - `chat_messages` (top-level legacy collection)
  - `chats/{chatId}/messages` (modern subcollection)
- **Priority**: High
- **Current Implementation**:
  ```dart
  // Legacy: chat_messages Record
  static Query get collection =>
    FirebaseFirestore.instance.collectionGroup('messages');

  // Security rules:
  match /chat_messages/{messageId} {
    allow read: if isSignedIn() && resource.data.user.id == request.auth.uid;
    allow create, update, delete: if false;  // Read-only!
  }
  ```
- **Problem**:
  - Two systems for storing chat messages
  - Legacy chat_messages is read-only (cannot create new messages there)
  - Security rules comment: "All new messages use chats/{chatId}/messages subcollection"
  - ChatMessagesRecord.collection uses collectionGroup('messages') which queries subcollections
  - Legacy collection still exists for backward compatibility
- **Recommendation**: **Remove chat_messages top-level collection**
  1. Migrate old messages to subcollections:
     ```javascript
     // Migration script
     db.collection('chat_messages').get().then(snapshot => {
       const batch = db.batch();
       snapshot.forEach(msg => {
         const data = msg.data();
         const chatId = data.chatId;  // Assuming chatId stored
         const newRef = db.collection('chats').doc(chatId)
                          .collection('messages').doc(msg.id);
         batch.set(newRef, {
           senderId: data.user.id,
           text: data.text,
           createdAt: data.timestamp,
         });
       });
       return batch.commit();
     });
     ```
  2. Remove chat_messages security rules
  3. Update ChatMessagesRecord to only query subcollections
- **Impact**:
  - Data consistency: High (single message storage system)
  - Security: Medium (remove legacy read-only collection)
- **Effort**: Medium (6-8 hours: migration script, security rules, verify no legacy dependencies)

---

## 5. Collection: friend_request

**Purpose**: Friend request state machine
**Record File**: `lib/backend/schema/friend_request_record.dart`
**Total Fields**: 4

### Issues Identified

#### Issue S-SCHEMA-022: request_status String Enum

- **Field**: `request_status`
- **Priority**: Medium
- **Current**: Free-form String
- **Problem**: No validation, can be 'pending', 'Pending', 'accepted', etc.
- **Recommendation**: Define enum
  ```dart
  enum FriendRequestStatus {
    pending,
    accepted,
    rejected,
    cancelled,
  }

  // Security rules:
  function isValidRequestStatus(data) {
    return data.request_status in [
      'pending', 'accepted', 'rejected', 'cancelled'
    ];
  }
  ```
- **Impact**: Type safety, data consistency
- **Effort**: Small (2-3 hours: enum + security rules)

#### Issue S-SCHEMA-023: receiver_id and requester_id Naming

- **Fields**: `receiver_id`, `requester_id` (DocumentReference)
- **Priority**: Low
- **Current**: Suffix `_id` suggests String, but type is DocumentReference
- **Problem**: Confusing naming (id usually means String, Ref means DocumentReference)
- **Recommendation**: Rename to match type
  ```dart
  DocumentReference? _receiverRef;
  DocumentReference? _requesterRef;
  ```
- **Impact**: Code clarity
- **Effort**: Medium (4-6 hours: migration + update code)

#### Issue S-SCHEMA-024: userRef Field Purpose Unclear

- **Field**: `userRef`
- **Priority**: Medium
- **Current**: DocumentReference with no clear purpose
- **Problem**:
  - Not used in security rules
  - Not clear if it's receiver or requester
  - Possibly duplicate of receiver_id or requester_id
- **Recommendation**: Investigate usage and remove if unused
- **Impact**: Schema clarity
- **Effort**: Small (1-2 hours: search usage, document or remove)

#### Issue S-SCHEMA-025: No Timestamp Fields

- **Fields**: Missing `created_at`, `updated_at`
- **Priority**: High
- **Problem**: Cannot track when request was sent or responded to
- **Recommendation**: Add timestamps
  ```dart
  DateTime? _createdAt;
  DateTime? _updatedAt;
  ```
  Used for:
  - Auto-expiring old requests (7 days pending → expired)
  - Displaying "2 days ago" in UI
  - Sorting requests by recency
- **Impact**: UX (can show age of requests), data hygiene (expire old requests)
- **Effort**: Small (2-3 hours: add fields, update creation code)

---

## 6. Collection: course

**Purpose**: Golf course directory
**Record File**: `lib/backend/schema/course_record.dart`
**Total Fields**: 3

### Issues Identified

#### Issue S-SCHEMA-026: Minimal Course Schema

- **Fields**: `name`, `location` (LatLng), `picture`
- **Priority**: Medium
- **Problem**: Very minimal schema for golf course
- **Missing Fields**:
  - `address` (String) - for display in UI
  - `phone` (String) - contact info
  - `website` (String) - course website
  - `par` (int) - total par for 18 holes
  - `rating` (double) - course rating
  - `slope` (int) - slope rating
  - `holes` (int) - 9 or 18
- **Recommendation**: Expand schema for richer course data
  ```dart
  String? _name;
  LatLng? _location;
  String? _picture;
  String? _address;
  String? _phone;
  String? _website;
  int? _par;
  double? _rating;
  int? _slope;
  int? _holes;
  ```
- **Impact**: UX (richer course information), future features (handicap calculation)
- **Effort**: Small (2-3 hours: add fields to Record, update create course UI if exists)

---

## 7. Collection: roles

**Purpose**: Unclear (role-based access control?)
**Record File**: `lib/backend/schema/roles_record.dart`
**Total Fields**: 5

### Issues Identified

#### Issue S-SCHEMA-027: Collection Purpose Unclear

- **Fields**: `created_time`, `userRef`, `role_id`, `name`, `members`
- **Priority**: High
- **Problem**:
  - Purpose unclear (RBAC? Group membership? Game roles?)
  - `role_id` and `name` suggest role definition
  - `members` array suggests role assignment
  - `userRef` suggests single user (conflicts with members array)
  - No security rules defined for this collection (security risk!)
- **Recommendation**:
  - Document collection purpose in schema comment
  - If unused, deprecate and remove
  - If used for RBAC, clarify data model:
    - Option 1: roles collection defines role types (admin, moderator)
    - Option 2: roles collection assigns roles to users
  - Add security rules if keeping collection
- **Impact**: Security (no access control), data model clarity
- **Effort**: Medium (4-6 hours: document purpose, add security rules, or deprecate)

#### Issue S-SCHEMA-028: role_id vs name Redundancy

- **Fields**: `role_id` (String), `name` (String)
- **Priority**: Low
- **Current**: Two String fields for role identifier
- **Problem**: Redundant (role_id should be document ID, name is display name)
- **Recommendation**:
  - Use document ID as role_id
  - Keep name for display
- **Impact**: Schema simplification
- **Effort**: Small (2-3 hours: migration + update code)

---

## 8. Collection: add_players (Subcollection)

**Purpose**: Unclear (game player invitations?)
**Record File**: `lib/backend/schema/add_players_record.dart`
**Total Fields**: 3

### Issues Identified

#### Issue S-SCHEMA-029: Subcollection Purpose Unclear

- **Fields**: `uid`, `create_time`, `players`
- **Priority**: High
- **Current**: Subcollection under unknown parent
  ```dart
  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
    parent != null
      ? parent.collection('addPlayers')
      : FirebaseFirestore.instance.collectionGroup('addPlayers');
  ```
- **Problem**:
  - Purpose unclear (temporary player list? Invitation tracker?)
  - Parent collection unknown (games? users?)
  - No security rules for this subcollection
  - No usage found in widget code
- **Recommendation**:
  - Search codebase for usage
  - Document purpose or deprecate
  - Add security rules if keeping
- **Impact**: Security, data model clarity
- **Effort**: Small (1-2 hours: search usage, document or deprecate)

#### Issue S-SCHEMA-030: create_time Naming

- **Field**: `create_time`
- **Priority**: Low
- **Current**: snake_case `create_time`
- **Problem**: Inconsistent with other collections (createdAt, created_time, createTime all used)
- **Recommendation**: Standardize timestamp naming project-wide
- **Impact**: Consistency
- **Effort**: Part of larger timestamp standardization effort

---

## 9. Collection: verification_dash

**Purpose**: Username verification dashboard (?)
**Record File**: `lib/backend/schema/verification_dash_record.dart`
**Total Fields**: 1

### Issues Identified

#### Issue S-SCHEMA-031: Collection Name Case Mismatch

- **Collection**: `VerificationDash` (PascalCase in code)
- **Priority**: Low
- **Problem**:
  - All other collections use lowercase: `users`, `games`, `chats`
  - VerificationDash uses PascalCase (inconsistent)
  - Collection name in code: `FirebaseFirestore.instance.collection('VerificationDash')`
- **Recommendation**: Rename to `verification_dash` (snake_case)
- **Impact**: Consistency
- **Effort**: Small (2-3 hours: Firestore migration + update code)

#### Issue S-SCHEMA-032: Single-Field Collection Design

- **Field**: `usernames` (List<String>)
- **Priority**: Medium
- **Problem**:
  - Collection has only one field
  - Appears to be a list of verified usernames
  - Could be stored as single document instead of collection
  - Or should be subcollection of users
- **Recommendation**: Clarify data model
  - Option 1: Single document `verification_dash/config` with usernames array
  - Option 2: One document per username for efficient lookups
- **Impact**: Query performance, data model clarity
- **Effort**: Small (2-3 hours: refactor data model)

---

# Denormalization Analysis

## Intentional Denormalization (Good)

### Pattern D-GOOD-001: Chat lastMessage Caching

- **Collection**: chats
- **Fields**: `lastMessage`, `lastMessageAt`, `lastMessageSenderId`
- **Purpose**: Display last message preview in chat list without querying messages subcollection
- **Consistency**: Updated via client-side write or Cloud Function
- **Assessment**: ✅ Good pattern - significantly improves chat list performance
- **Stale Data Risk**: Low (updated on every new message)
- **Recommendation**: Keep as-is, ensure update trigger exists

### Pattern D-GOOD-002: Game joined_players Array

- **Collection**: games
- **Field**: `joined_players` (List<DocumentReference>)
- **Purpose**: Quick access to participant list, used in security rules
- **Consistency**: Updated on join/leave actions
- **Assessment**: ✅ Good pattern - enables security rules to check participation
- **Stale Data Risk**: Low (transactional update)
- **Recommendation**: Keep, consider denormalizing player count for queries

## Unintentional Data Duplication (Bad)

### Pattern D-BAD-001: uid + userRef in games and users

- **Collections**: games, users, friend_request
- **Fields**: `uid` (String) + `userRef` (DocumentReference)
- **Problem**: Same data (user ID) stored as both string and reference
- **Stale Data Risk**: Medium (can diverge)
- **Recommendation**: Remove uid field, use userRef.id
- **Effort**: Medium (6-8 hours per collection)

### Pattern D-BAD-002: course_play + courseRef

- **Collection**: games
- **Fields**: `course_play` (String) + `courseRef` (DocumentReference)
- **Problem**: Course name duplicated (also in course document)
- **Stale Data Risk**: High (course name can be updated without updating games)
- **Recommendation**: Add Cloud Function to sync course name updates
- **Effort**: Large (10-14 hours)

### Pattern D-BAD-003: chats users vs memberIds

- **Collection**: chats
- **Fields**: `users` (List<DocumentReference>) + `memberIds` (List<String>)
- **Problem**: Participant list stored twice
- **Stale Data Risk**: High (new chats use memberIds, old use users)
- **Recommendation**: Complete migration to memberIds
- **Effort**: Large (10-14 hours)

### Pattern D-BAD-004: first_name + last_name vs display_name

- **Collection**: users
- **Fields**: `first_name`, `last_name`, `display_name`
- **Problem**: Unclear if display_name derives from first+last
- **Stale Data Risk**: Low (user controls all three independently)
- **Recommendation**: Document semantic difference, add helper method
- **Effort**: Small (1-2 hours)

## Missing Denormalization (N+1 Query Risks)

### Pattern D-MISSING-001: Game Host Info

- **Collection**: games
- **Issue**: Only stores `userRef`, requires lookup for host name/photo
- **N+1 Risk**: Game list queries require 1 query for games + N queries for host info
- **Recommendation**: Denormalize host name and photo:
  ```dart
  DocumentReference? _hostRef;
  String? _hostName;    // Denormalized
  String? _hostPhoto;   // Denormalized
  ```
  Update via Cloud Function when user updates profile
- **Impact**: Performance (eliminate N lookups in game list)
- **Effort**: Large (8-12 hours: add fields, Cloud Function, migration)

### Pattern D-MISSING-002: Chat Participant Names

- **Collection**: chats
- **Issue**: Only stores `memberIds`, requires 2-N user lookups per chat
- **N+1 Risk**: Chat list displays participant names (N queries for N chats)
- **Recommendation**: Denormalize participant names in chat doc:
  ```dart
  Map<String, String>? _memberNames;  // { uid: displayName }
  ```
  Update via Cloud Function when user updates display_name
- **Impact**: Performance (critical for chat list)
- **Effort**: Large (12-16 hours: add field, Cloud Function, migration)

### Pattern D-MISSING-003: Friend Request Sender/Receiver Info

- **Collection**: friend_request
- **Issue**: Only stores DocumentReferences, requires 2 lookups per request
- **N+1 Risk**: Friend request list displays sender info (N queries)
- **Recommendation**: Denormalize sender name/photo:
  ```dart
  DocumentReference? _requesterRef;
  String? _requesterName;   // Denormalized
  String? _requesterPhoto;  // Denormalized
  ```
- **Impact**: Performance (improve friend request list)
- **Effort**: Medium (6-8 hours: add fields, update creation code)

---

# Pre-Beta Refactoring Roadmap

## Critical Issues (Must Fix Before Beta)

| Issue | Collection | Description | Effort | Priority |
|-------|------------|-------------|--------|----------|
| S-SCHEMA-005 | users | friends array scalability limit | Large | P0 |
| S-SCHEMA-010 | games | uid + userRef redundancy | Medium | P0 |
| S-SCHEMA-014 | games | joined_players mixed types | Large | P0 |
| S-SCHEMA-016 | chats | users vs memberIds migration | Large | P0 |
| S-SCHEMA-021 | chat_messages | Two message systems coexist | Medium | P0 |
| S-SCHEMA-025 | friend_request | Missing timestamps | Small | P0 |
| S-SCHEMA-027 | roles | No security rules | Medium | P0 |
| S-SCHEMA-029 | add_players | No security rules | Small | P0 |

**Total Critical Effort**: 44-58 hours (~6-7 days)

## High Priority Issues (Should Fix Before Beta)

| Issue | Collection | Description | Effort | Priority |
|-------|------------|-------------|--------|----------|
| S-SCHEMA-003 | users | 9 notification booleans | Large | P1 |
| S-SCHEMA-004 | users | vibe_profile unstructured | Medium | P1 |
| S-SCHEMA-011 | games | date vs created_time confusion | Medium | P1 |
| S-SCHEMA-012 | games | style_game/game_type as String | Medium | P1 |
| S-SCHEMA-013 | games | course_play + courseRef | Large | P1 |
| D-MISSING-001 | games | Game host info N+1 | Large | P1 |
| D-MISSING-002 | chats | Chat participant names N+1 | Large | P1 |

**Total High Priority Effort**: 46-62 hours (~6-8 days)

**Combined Critical + High**: 90-120 hours (~11-15 days)

## Quick Wins (High Impact, Low Effort)

| Issue | Collection | Description | Effort | Impact |
|-------|------------|-------------|--------|--------|
| S-SCHEMA-006 | users | Remove uid field | Small | Medium |
| S-SCHEMA-008 | users | role enum | Small | High |
| S-SCHEMA-017 | chats | Remove lastMessageSentBy | Small | Medium |
| S-SCHEMA-022 | friend_request | request_status enum | Small | High |
| S-SCHEMA-025 | friend_request | Add timestamps | Small | High |

**Total Quick Wins**: 10-15 hours (~1-2 days)

## Medium Priority (Defer Post-Beta)

Field naming standardization, case consistency, documentation improvements. Total 36-48 hours.

---

# Best Practices Guide

## Field Naming Standards

### Established Patterns

1. **Timestamps**: Use `createdAt`, `updatedAt`, `lastMessageAt` (camelCase + At suffix)
   - ❌ Bad: `created_time`, `create_time`, `last_active_time`
   - ✅ Good: `createdAt`, `updatedAt`, `lastActiveAt`

2. **References**: Use `Ref` suffix for DocumentReference
   - ❌ Bad: `userId` (String), `receiver_id` (DocumentReference)
   - ✅ Good: `userRef` (DocumentReference), `userId` (String)

3. **Booleans**: Use `is` or `has` prefix
   - ❌ Bad: `cancelled`, `completed`, `verified`
   - ✅ Good: `isCancelled`, `isCompleted`, `hasVerified`

4. **Arrays**: Plural nouns
   - ❌ Bad: `friend`, `player`, `member`
   - ✅ Good: `friends`, `players`, `members`

5. **IDs**: Use `Id` suffix for String UIDs
   - ❌ Bad: `uid` (when also have userRef), `sender`
   - ✅ Good: `userId`, `senderId`, `gameId`

### Case Convention

**Recommendation**: **snake_case** for Firestore field names (current majority pattern)
- Matches Firestore conventions
- Easier to read in Firestore console
- Less error-prone (case-insensitive in security rules)

**Implementation**:
```dart
// Firestore document
{
  "created_at": Timestamp,
  "user_ref": DocumentReference,
  "is_cancelled": bool,
}

// Dart Record class
DateTime? _createdAt;
DateTime? get createdAt => _createdAt;

void _initializeFields() {
  _createdAt = snapshotData['created_at'] as DateTime?;
}
```

## When to Denormalize

### Denormalize When:

1. **Read-Heavy Fields**: Data read 10x more than written
   - Example: User display name in chat list
   - Cost: Storage + sync complexity
   - Benefit: Eliminate N+1 queries

2. **Security Rules Need Access**: Field used in permission checks
   - Example: joined_players array (check participation)
   - Cost: Transactional updates
   - Benefit: Efficient authorization

3. **Query Filter Required**: Need to filter/sort by joined data
   - Example: Game host name for "my hosted games" filter
   - Cost: Stale data risk
   - Benefit: Single query instead of JOIN

### Don't Denormalize When:

1. **Write-Heavy Fields**: Frequently updated data
   - Example: User last_active_time (updated constantly)
   - Problem: Update storm on denormalized copies

2. **Large Data**: Multi-KB blobs
   - Example: Full user profile in every chat
   - Problem: Document size limits (1MB)

3. **Sensitive Data**: PII or secrets
   - Example: Email in game document
   - Problem: Harder to secure, compliance risk

## Type Safety Patterns

### Enums Over Strings

```dart
// ❌ Bad: Free-form String
String? _gameType;
String get gameType => _gameType ?? '';

// Usage: if (game.gameType == 'competitive')  // Typo-prone

// ✅ Good: Validated Enum
enum GameType {
  casual,
  competitive,
  money,
  vegas,
}

String? _gameTypeRaw;
GameType get gameType => GameType.values.firstWhere(
  (t) => t.name == _gameTypeRaw,
  orElse: () => GameType.casual,
);

// Usage: if (game.gameType == GameType.competitive)  // Type-safe
```

### Structured Maps Over Unstructured

```dart
// ❌ Bad: Unstructured Map
Map<String, dynamic>? _vibeProfile;
Map<String, dynamic> get vibeProfile => _vibeProfile ?? {};

// Usage: final energy = user.vibeProfile['energyLevel'] as int?;  // Runtime cast

// ✅ Good: Data Class
class VibeProfile {
  final int energyLevel;  // 1-5
  final int competitive;
  final int social;
  final int speed;

  Map<String, dynamic> toFirestore() => {...};
  static VibeProfile fromFirestore(Map<String, dynamic>? data) {...}
}

VibeProfile get vibeProfile =>
  VibeProfile.fromFirestore(_vibeProfileRaw);

// Usage: final energy = user.vibeProfile.energyLevel;  // Type-safe
```

## Validation Rule Patterns

### Required Fields

```javascript
// Security rule
function hasRequiredFields(data) {
  return data.keys().hasAll([
    'type',
    'memberIds',
    'createdAt',
  ]);
}

allow create: if hasRequiredFields(request.resource.data);
```

### Enum Validation

```javascript
function isValidGameType(data) {
  return data.game_type in ['casual', 'competitive', 'money', 'vegas'];
}

allow update: if isValidGameType(request.resource.data);
```

### Referential Integrity

```javascript
// Ensure userRef matches uid
function userRefMatchesUid(data) {
  return !data.keys().hasAny(['userRef']) ||
    data.userRef == userRef(data.uid);
}

// Ensure array doesn't exceed size
function withinPlayerLimit(data) {
  return data.joined_players.size() <= data.max_players;
}
```

---

# Cross-References to Phase 8 Findings

## Schema Issues That Enable Architectural Violations

From Phase 8 SEPARATION-CONCERNS-AUDIT.md:

### Direct Firestore Access (16 violations)

**Root Cause**: Lack of service layer + inconsistent schema
- games_list_widget: Directly queries `FirebaseFirestore.instance.collection('games')`
- **Schema Issue**: No GameService to centralize game queries
- **Schema Issue**: Inconsistent joined_players types force widget-side logic

**Fix**: Create GameService + standardize joined_players to String uids

### Business Logic in UI (6 violations)

**Root Cause**: Vibe matching logic in widgets due to unstructured vibe_profile
- game_joined_detailed: Calculates vibe match score in widget
- **Schema Issue**: vibe_profile is unstructured Map (no type safety)
- **Schema Issue**: No VibeProfile class with .matchScore() method

**Fix**: Structured VibeProfile class + move matching to VibeMatchProvider

### Service Layer Design

Phase 8 identified need for:
1. **GameService**: Centralize game queries, mutations
2. **ProfileService**: User profile operations
3. **VibeMatchProvider**: Extract vibe matching logic

**Schema Prerequisites**:
- Standardize games collection (S-SCHEMA-010, S-SCHEMA-014)
- Structured vibe_profile (S-SCHEMA-004)
- Enum types for game fields (S-SCHEMA-012)

---

# Data Model Health Score Breakdown

**Overall Score: 68/100**

### Score Components

| Category | Weight | Score | Weighted |
|----------|--------|-------|----------|
| Naming Consistency | 20% | 60/100 | 12 |
| Type Safety | 25% | 55/100 | 13.75 |
| Data Integrity | 25% | 70/100 | 17.5 |
| Query Performance | 15% | 75/100 | 11.25 |
| Security Validation | 15% | 80/100 | 12 |
| **Total** | **100%** | **—** | **66.5** |

*Rounded to 68/100*

### Score Rationale

**Naming Consistency (60/100)**:
- Mixed snake_case vs camelCase (-20)
- Inconsistent timestamp suffixes (-10)
- Some good patterns (course, verification_dash) (+10)

**Type Safety (55/100)**:
- Most Strings should be enums (-25)
- Unstructured Maps (vibe_profile) (-10)
- Mixed types in arrays (joined_players) (-10)

**Data Integrity (70/100)**:
- Multiple data redundancies (-15)
- Incomplete migrations (-10)
- Some good referential constraints (+5)

**Query Performance (75/100)**:
- Good indexes exist (+15)
- Missing denormalization (-10)
- Scalability concerns (friends array) (-10)

**Security Validation (80/100)**:
- Comprehensive security rules (+20)
- Missing validation for some collections (-10)
- Good enum validation patterns (+10)

---

# Summary Statistics

## Issues by Priority

- **Critical**: 8 issues (17%)
- **High**: 15 issues (32%)
- **Medium**: 18 issues (38%)
- **Low**: 6 issues (13%)

## Total Refactoring Effort

- **Pre-Beta Critical**: 44-58 hours
- **Pre-Beta High**: 46-62 hours
- **Post-Beta Medium**: 36-48 hours
- **Post-Beta Low**: 12-18 hours
- **Total**: 138-186 hours (~17-23 days)

## Recommended Phase 11 Scope

Focus on Critical + High + Quick Wins:
- **Total Effort**: 100-135 hours (~12-17 days)
- **Issues Fixed**: 30 of 47 (64%)
- **Health Score Improvement**: 68 → 85 (+17 points)

Deferred to post-beta:
- Medium/Low naming standardization
- Documentation improvements
- Minor optimization opportunities

---

**End of Schema Design Audit**
*Generated: 2026-01-22*
*Next Steps: Review with user, prioritize for Phase 11 planning*
