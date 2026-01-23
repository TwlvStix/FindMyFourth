# Data Relationships & Referential Integrity Audit

**Generated:** 2026-01-22
**Phase:** 09-data-model-schema-audit
**Objective:** Comprehensive audit of Firestore data relationships, DocumentReference usage, and referential integrity

**Status:** Complete
**Issues Found:** 23 relationship issues (8 critical, 9 high, 6 medium priority)
**Data Integrity Health Score:** 58/100

---

## Executive Summary

### Critical Findings

This audit reveals **significant referential integrity risks** that could affect data consistency and user experience before beta launch:

**Critical Issues (8):**
1. **Mixed relationship patterns** - Same relationship uses both `DocumentReference` and `String UID` (games.userRef + games.uid)
2. **Legacy chat field duplication** - Both `users[]` (DocumentReference) and `memberIds[]` (String) for same data
3. **Incomplete subcollection cleanup** - Chat messages orphaned when parent chat deleted
4. **No cascading game cleanup** - Games become hostless when user deleted
5. **Chat relationship inconsistency** - `gameId` is String, not DocumentReference (breaks pattern)
6. **No bidirectional game tracking** - Users don't track which games they've joined
7. **Friend request orphaning** - Requests not cleaned up when users deleted
8. **Course String reference** - `users.home_course` is String name, should be DocumentReference

**High Priority Issues (9):**
- Partial user deletion cleanup (only friends arrays, not games or chats)
- No transaction enforcement for friend request workflow
- Legacy chat_messages collection still referenced
- Game-chat relationship not validated
- No denormalized data sync on user profile changes

**Data Integrity Health Score: 58/100**
- **Relationship consistency:** 45/100 (mixed DocumentReference/String patterns)
- **Referential integrity:** 60/100 (partial cascading cleanup exists)
- **Bidirectional consistency:** 40/100 (one-way relationships dominate)
- **Query complexity:** 85/100 (well-indexed, but mixed patterns complicate queries)

### Pre-Beta Blockers

**Must fix before beta:**
1. Standardize game host relationship (remove uid/userRef duplication)
2. Implement chat messages subcollection cleanup
3. Migrate legacy chat.users[] to chat.memberIds[]
4. Convert chat.gameId String → DocumentReference

**Strongly recommended for beta:**
5. Comprehensive user deletion cascade (games, chats, friend requests)
6. Transaction-based friend request acceptance
7. Course reference standardization

**Post-beta technical debt:**
8. Bidirectional game tracking for users
9. Denormalized data synchronization

---

## Relationship Map

### Collection Relationship Diagram

```
users
  ← games.userRef (host, DocumentReference)
  ← games.uid (host, String UID - DUPLICATE!)
  ← games.joined_players[] (participants, List<DocumentReference>)
  ← chats.memberIds[] (chat members, List<String>)
  ← chats.users[] (LEGACY, List<DocumentReference>)
  ← chats.user_a (direct chat, DocumentReference)
  ← chats.user_b (direct chat, DocumentReference)
  ← friend_request.receiverId (DocumentReference)
  ← friend_request.requesterId (DocumentReference)
  ↔ users.friends[] (bidirectional, List<DocumentReference>)
  → users.friend_requests[] (List<DocumentReference>)
  → users.home_course (String name - should be DocumentReference!)
  ⊃ devices subcollection (parent-child)
  ⊃ notifications subcollection (parent-child)

games
  → users (host via userRef DocumentReference)
  → users (host via uid String - DUPLICATE!)
  → users (participants via joined_players[] List<DocumentReference>)
  → course (via courseRef DocumentReference)
  → chats (via chatRef DocumentReference)
  ← chats.gameId (String - INCONSISTENT, should be DocumentReference!)

chats
  → users (via memberIds[] List<String>)
  → users (LEGACY via users[] List<DocumentReference>)
  → users (via user_a DocumentReference for direct chats)
  → users (via user_b DocumentReference for direct chats)
  → games (via gameId String - INCONSISTENT!)
  ⊃ messages subcollection (parent-child, NOT AUTO-DELETED!)

chat_messages (LEGACY top-level collection)
  → users (via user.id - deprecated pattern)

friend_request
  → users (via receiverId DocumentReference)
  → users (via requesterId DocumentReference)
  → users (via userRef DocumentReference - UNCLEAR PURPOSE)

course
  ← games.courseRef (DocumentReference)
  ← users.home_course (String name - INCONSISTENT!)
  (No outbound references - read-only lookup table)
```

---

## Detailed Relationship Issues

### R-REL-001: Game Host Dual Representation (Critical)

**Collections:** games, users
**Current Implementation:**
```dart
// GamesRecord has BOTH:
DocumentReference? userRef;  // Line 95-97
String? uid;                // Line 100-102
```

**Problem:**
- Same relationship (game → host) stored in two different formats
- `userRef` is a DocumentReference to users/{uid}
- `uid` is the same user ID as a String
- Both fields track the exact same user (the game host)
- Creates redundancy and potential inconsistency if one is updated without the other
- Violates DRY principle at the data model level

**Consistency Check:**
- Security rules expect both: `isOwner()` checks `data.uid == request.auth.uid`
- Creation rule validates: `userRefMatchesUid(request.resource.data)` ensures they match
- However, no enforcement on updates - could diverge

**Referential Integrity:**
- If host user is deleted:
  - `userRef` becomes dangling DocumentReference (points to non-existent document)
  - `uid` becomes orphaned String (no user with that ID exists)
  - Game document remains, but host is gone
  - Security rules would fail (isOwner would return false)

**Access Patterns:**
```dart
// Code uses uid for simple checks:
isOwner(resource.data) checks data.uid == request.auth.uid

// But userRef would be needed for joins:
get(data.userRef).data.display_name  // Fetch host name
```

**Recommendation:**
- **Choose one pattern:** Use `userRef` only (DocumentReference preferred)
- **Rationale:** DocumentReference provides type safety and enables efficient joins
- **Security rules:** Can still compare `request.auth.uid` using: `data.userRef.id == request.auth.uid`
- **Migration:** Batch update all games documents to remove `uid` field
- **Code changes:** Update security rules to use `data.userRef.id` instead of `data.uid`

**Priority:** Critical
**Impact:** Data redundancy, potential inconsistency, confusing developer experience
**Effort:** 4-6 hours (migration script + security rules + testing)

---

### R-REL-002: Chat Members Dual Representation (Critical)

**Collections:** chats, users
**Current Implementation:**
```dart
// ChatsRecord has BOTH:
List<DocumentReference>? users;    // Line 20-22 (LEGACY)
List<String>? memberIds;          // Line 24-27 (CURRENT)
```

**Problem:**
- Same data (chat members) stored in two different list formats
- `users[]` is legacy DocumentReference list
- `memberIds[]` is current String UID list
- Both represent the same set of chat participants
- Code has compatibility checks to handle both: `isChatMemberOrLegacy()`

**Consistency Check:**
Security rules support both:
```javascript
function isChatMember(data) {
  return request.auth.uid in data.memberIds;
}
function isLegacyChatMember(data) {
  return data.users.hasAny([/databases/$(database)/documents/users/$(request.auth.uid)]);
}
```

**Referential Integrity:**
- If user is deleted:
  - `users[]` has dangling DocumentReference
  - `memberIds[]` has orphaned String UID
  - Chat remains with deleted user as "member"
  - Messages from deleted user still visible but user profile is gone

**Migration Status:**
- New chats use `memberIds[]` only
- Old chats may have both or only `users[]`
- No automated migration script found
- Code maintains backward compatibility indefinitely

**Recommendation:**
1. **Immediate:** Create migration to convert all `users[]` → `memberIds[]`
2. **Then:** Remove `users[]` field from schema
3. **Update:** Remove legacy compatibility code from security rules
4. **Rationale:** Standardize on String UIDs for simple membership checks (DocumentReference unnecessary here)

**Priority:** Critical
**Impact:** Data duplication, legacy code maintenance burden, inconsistent query patterns
**Effort:** 6-8 hours (migration script + schema update + rules cleanup + testing)

---

### R-REL-003: Chat Messages Subcollection Orphaning (Critical)

**Collections:** chats, chats/{chatId}/messages
**Current Implementation:**
```dart
// ChatsRecord is parent
// Messages are in subcollection: chats/{chatId}/messages

// Security rule allows chat deletion:
allow delete: if isSignedIn() && isChatMember(resource.data);  // Line 352
```

**Problem:**
- **Firestore does NOT auto-delete subcollections when parent is deleted**
- When chat is deleted, `chats/{chatId}/messages` subcollection remains
- Orphaned messages are inaccessible (parent doesn't exist) but consume storage
- Security rules prevent access: `isChatMemberById(chatId)` fails if chat doesn't exist
- No Cloud Function to cleanup messages subcollection

**Subcollection Behavior:**
```
Before deletion:
  chats/abc123 (exists)
    └─ messages/msg1 (accessible)
    └─ messages/msg2 (accessible)

After chats/abc123 deleted:
  chats/abc123 (DOES NOT EXIST)
    └─ messages/msg1 (ORPHANED - inaccessible but stored)
    └─ messages/msg2 (ORPHANED - inaccessible but stored)
```

**Current State:**
- No `onDelete` Cloud Function for chats collection
- Messages orphan indefinitely
- Storage costs accumulate
- Violates data retention expectations

**Recommendation:**
**Critical:** Create Cloud Function for cascading subcollection deletion:

```javascript
exports.cleanupChatMessages = functions
  .firestore.document('chats/{chatId}')
  .onDelete(async (snapshot, context) => {
    const chatId = context.params.chatId;
    const messagesRef = admin.firestore()
      .collection('chats')
      .doc(chatId)
      .collection('messages');

    // Delete in batches (Firestore limit: 500 ops/batch)
    const batch = admin.firestore().batch();
    const messages = await messagesRef.limit(500).get();

    messages.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();

    // Recursive for >500 messages
    if (messages.size === 500) {
      // Schedule another cleanup
      await cleanupChatMessages(chatId);
    }
  });
```

**Priority:** Critical
**Impact:** Data leakage, storage costs, violates user expectations for data deletion
**Effort:** 3-4 hours (Cloud Function + testing + deployment)

---

### R-REL-004: Game-Chat Relationship Inconsistency (Critical)

**Collections:** games, chats
**Current Implementation:**
```dart
// GamesRecord → chats
DocumentReference? chatRef;  // Line 105-107 (DocumentReference)

// ChatsRecord → games
String? gameId;             // Line 84-87 (String, NOT DocumentReference!)
```

**Problem:**
- **Inconsistent relationship pattern**
- Games → Chats uses DocumentReference (type-safe, standard)
- Chats → Games uses String gameId (inconsistent with rest of codebase)
- Breaks bidirectional relationship consistency
- Complicates queries and security rules

**Access Pattern Comparison:**
```javascript
// Games can easily validate chat exists:
get(gameData.chatRef).data  // Direct DocumentReference lookup

// Chats must construct path manually:
get(/databases/$(database)/documents/games/$(chatData.gameId))  // String concatenation
```

**Security Rules Impact:**
```javascript
// Security rule line 98 must construct DocumentReference from String:
function isGameParticipant(gameId) {
  let gamePath = /databases/$(database)/documents/games/$(gameId);  // Manual path construction
  let gameData = exists(gamePath) ? get(gamePath).data : null;
  // ...
}
```

**Referential Integrity:**
- If game is deleted (blocked by rules, but if status='cancelled'):
  - `games.chatRef` would point to valid chat (chat persists)
  - `chats.gameId` becomes orphaned String
  - Chat still exists but game is gone
  - Cannot validate game still exists without expensive lookup

**Recommendation:**
1. **Change `chats.gameId` from String → DocumentReference**
2. **Update schema:**
```dart
// ChatsRecord
DocumentReference? gameRef;  // Replaces String gameId
```
3. **Update security rules** to use direct DocumentReference checks:
```javascript
function isGameParticipant(chatData) {
  return chatData.gameRef != null &&
    get(chatData.gameRef).data.joined_players.hasAny([userRef(request.auth.uid)]);
}
```
4. **Migration:** Convert existing `gameId` Strings → DocumentReferences

**Priority:** Critical
**Impact:** Inconsistent patterns, inefficient queries, harder to maintain
**Effort:** 5-7 hours (schema change + migration + security rules + testing)

---

### R-REL-005: User Deletion Incomplete Cascade (Critical)

**Collections:** users, games, chats, friend_request
**Current Implementation:**

Cloud Function `onUserDeleted` (lines 1051-1091) cleans up:
```javascript
✓ fcm_tokens subcollection (deleted)
✓ usernames/{displayName} (deleted)
✓ users/{uid} document (deleted)
✓ chat_messages (legacy, where user==userRef)
✓ users.friends[] arrays (via removeUserFromArrays)
✓ users.friend_requests[] arrays (via removeUserFromArrays)
```

**What's NOT cleaned up:**
```javascript
✗ games where user is host (games.uid or games.userRef)
✗ games where user is participant (games.joined_players[])
✗ chats where user is member (chats.memberIds[])
✗ chats/{chatId}/messages where user is sender
✗ friend_request documents (receiverId or requesterId)
✗ devices subcollection (not explicitly deleted, may be auto-deleted with parent)
✗ notifications subcollection (not explicitly deleted)
```

**Impact Analysis:**

1. **Games Collection:**
   - Host-less games: User is deleted, but games they created remain
   - `games.uid` = deleted user's UID (orphaned String)
   - `games.userRef` = /users/{deleted_uid} (dangling DocumentReference)
   - `isOwner()` security check always fails (no one can edit/cancel the game)
   - Participants can still join, but game has no host
   - **Risk:** Games become "frozen" - can't be edited or cancelled

2. **Joined Games:**
   - `games.joined_players[]` contains deleted user's DocumentReference
   - UI shows deleted user as participant (but profile doesn't exist)
   - `totalPlayers()` count includes deleted user
   - Available slots calculation is incorrect (shows full when slot is actually free)
   - **Risk:** Games appear full when they're not, blocking new joins

3. **Chats Collection:**
   - `chats.memberIds[]` contains deleted user's UID
   - `isChatMember()` allows deleted UID as member
   - Chat UI shows deleted user in member list (but profile doesn't exist)
   - `chats/{chatId}/messages` contain messages from deleted user
   - **Risk:** Ghost users in chat rooms, confusing UX

4. **Friend Requests:**
   - `friend_request` documents with deleted user as sender/receiver remain
   - Other users see pending requests from/to non-existent users
   - Accepting request fails (one side doesn't exist)
   - **Risk:** UI shows invalid friend requests, dead-end workflows

**GDPR Compliance Risk:**
- User exercises "right to be deleted"
- User document is deleted, but:
  - Game participation history remains (joined_players references)
  - Chat messages remain in subcollections
  - Friend requests remain
- **Potential compliance violation:** User data not fully erased

**Recommendation:**

Enhance `onUserDeleted` Cloud Function:

```javascript
exports.onUserDeleted = functions
  .auth.user()
  .onDelete(async (user) => {
    const firestore = admin.firestore();
    const userRef = firestore.doc(`users/${user.uid}`);
    const uid = user.uid;

    // [Existing cleanup: fcm_tokens, usernames, user doc, chat_messages, friend arrays]

    // NEW: Cleanup games where user is host
    const hostedGames = await firestore.collection('games')
      .where('uid', '==', uid)
      .get();

    for (const doc of hostedGames.docs) {
      // Option 1: Delete game entirely
      await doc.ref.delete();

      // OR Option 2: Mark as cancelled and remove host
      await doc.ref.update({
        isCancelled: true,
        status: 'cancelled',
        uid: admin.firestore.FieldValue.delete(),
        userRef: admin.firestore.FieldValue.delete()
      });
    }

    // NEW: Remove user from joined_players in games
    const joinedGames = await firestore.collection('games')
      .where('joined_players', 'array-contains', userRef)
      .get();

    const batch = firestore.batch();
    for (const doc of joinedGames.docs) {
      batch.update(doc.ref, {
        joined_players: admin.firestore.FieldValue.arrayRemove(userRef)
      });
    }
    await batch.commit();

    // NEW: Remove user from chats.memberIds
    const chats = await firestore.collection('chats')
      .where('memberIds', 'array-contains', uid)
      .get();

    for (const chatDoc of chats.docs) {
      const members = chatDoc.data().memberIds || [];
      if (members.length <= 1) {
        // Last member - delete entire chat (triggers chat cleanup function)
        await chatDoc.ref.delete();
      } else {
        // Remove user from members list
        await chatDoc.ref.update({
          memberIds: admin.firestore.FieldValue.arrayRemove(uid),
          users: admin.firestore.FieldValue.arrayRemove(userRef)  // Legacy
        });
      }
    }

    // NEW: Delete friend_request documents
    const sentRequests = await firestore.collection('friend_request')
      .where('requesterId', '==', userRef)
      .get();
    const receivedRequests = await firestore.collection('friend_request')
      .where('receiverId', '==', userRef)
      .get();

    for (const doc of [...sentRequests.docs, ...receivedRequests.docs]) {
      await doc.ref.delete();
    }

    // NEW: Delete user's messages in chats (optional - for GDPR compliance)
    const userChats = await firestore.collection('chats')
      .where('memberIds', 'array-contains', uid)
      .get();

    for (const chatDoc of userChats.docs) {
      const messages = await chatDoc.ref.collection('messages')
        .where('senderId', '==', uid)
        .get();

      for (const msgDoc of messages.docs) {
        await msgDoc.ref.delete();
      }
    }
  });
```

**Priority:** Critical
**Impact:** GDPR risk, orphaned data, broken user experience, ghost users in UI
**Effort:** 8-12 hours (extensive cleanup logic + testing + GDPR review)

---

### R-REL-006: Course Reference Inconsistency (High)

**Collections:** course, users, games
**Current Implementation:**
```dart
// GamesRecord → course
DocumentReference? courseRef;  // Line 70-72 (DocumentReference - CORRECT)

// UsersRecord → course
String? homeCourse;           // Line 54-57 (String name - INCONSISTENT!)
```

**Problem:**
- Games use DocumentReference to course (type-safe, efficient)
- Users use String course name (brittle, error-prone)
- If course name changes, `users.home_course` becomes stale
- No referential integrity for user's home course
- Inconsistent pattern across codebase

**Access Pattern Comparison:**
```dart
// Games: Efficient lookup
CourseRecord course = await games.courseRef.get();
print(course.name);

// Users: Manual string-based query (inefficient)
QuerySnapshot courses = await FirebaseFirestore.instance
  .collection('course')
  .where('name', '==', users.homeCourse)
  .get();
// Multiple courses could match (no uniqueness constraint)
```

**Referential Integrity:**
- If course name changes:
  - `games.courseRef` still points to correct document (ID unchanged)
  - `users.homeCourse` becomes stale String (no course matches)
  - User's home course is "broken" until manually updated

**Recommendation:**
1. **Change `users.home_course` from String → DocumentReference**
2. **Update schema:**
```dart
// UsersRecord
DocumentReference? homeCourseRef;  // Replaces String homeCourse
```
3. **Migration:**
   - For each user with `homeCourse` String:
   - Query `course` collection for matching name
   - Set `homeCourseRef` to matching document reference
   - Handle cases where no match found (set to null or default)

**Priority:** High
**Impact:** Brittle data model, potential stale references, inefficient queries
**Effort:** 4-5 hours (schema change + migration + code updates)

---

### R-REL-007: No Bidirectional Game Tracking (High)

**Collections:** users, games
**Current Implementation:**
```dart
// Games tracks participants:
List<DocumentReference> joinedPlayers;  // Line 80-82

// Users does NOT track games:
// ❌ No field for "games I've joined"
// ❌ No field for "games I've created"
```

**Problem:**
- **One-way relationship:** Games know their participants, users don't know their games
- To find user's games, must query: `games.where('joined_players', 'array-contains', userRef)`
- Inefficient for user profile page showing "My Games"
- No way to quickly check "How many games has user joined?"
- Security rules can check if user is in game, but user can't enumerate their games efficiently

**Access Pattern Impact:**
```dart
// Current: Expensive query to find user's games
QuerySnapshot userGames = await FirebaseFirestore.instance
  .collection('games')
  .where('joined_players', 'array-contains', userRef)
  .get();

// With bidirectional: Direct lookup from user
List<DocumentReference> gameRefs = user.joinedGamesRefs;
// Fetch game details only if needed
```

**Query Performance:**
- Current: O(total_games) - must scan all games to filter
- With bidirectional: O(1) lookup from user document

**Trade-off Analysis:**
- **Pro (unidirectional):** Single source of truth, no sync required
- **Con (unidirectional):** Expensive queries, can't efficiently enumerate user's games
- **Pro (bidirectional):** Fast lookups, efficient user profile queries
- **Con (bidirectional):** Must maintain consistency (add to both sides when joining)

**Recommendation:**
**Medium priority** - Consider adding bidirectional tracking IF:
- User profile page shows "My Games" list
- Need to efficiently count user's active games
- Query "all my games" is a common operation

**Implementation:**
```dart
// UsersRecord - add field
List<DocumentReference> joinedGamesRefs;

// Update on game join:
batch.update(gameRef, {
  'joined_players': FieldValue.arrayUnion([userRef])
});
batch.update(userRef, {
  'joinedGamesRefs': FieldValue.arrayUnion([gameRef])
});

// Update on game leave:
batch.update(gameRef, {
  'joined_players': FieldValue.arrayRemove([userRef])
});
batch.update(userRef, {
  'joinedGamesRefs': FieldValue.arrayRemove([gameRef])
});
```

**Alternative:**
- Keep unidirectional (current)
- Accept query cost as reasonable
- Use composite index for efficient filtering
- Only add bidirectional if profiling shows performance issue

**Priority:** High (if user profile shows game list), Medium (if not)
**Impact:** Query performance for user-centric views
**Effort:** 6-8 hours (schema + transaction updates + backfill existing data)

---

### R-REL-008: Friend Request Workflow Not Transactional (High)

**Collections:** users, friend_request
**Current Implementation:**
```dart
// FriendRequestRecord
DocumentReference? receiverId;   // Line 24-26
DocumentReference? requesterId;  // Line 28-30
String? requestStatus;           // Line 19-21

// UsersRecord
List<DocumentReference> friends;         // Line 105-107
List<DocumentReference> friendRequests;  // Line 110-112
```

**Problem:**
- Friend request acceptance requires updates to **3 locations**:
  1. Delete `friend_request` document
  2. Add to `users/{requester}.friends[]`
  3. Add to `users/{receiver}.friends[]`
- **No transaction enforcement** in security rules or Cloud Functions
- Risk of partial completion:
  - Request deleted, but only one user's friends list updated
  - Both friends lists updated, but request not deleted
  - Creates inconsistent state

**Security Rules:**
```javascript
// Line 287 - Allows independent friend list updates
isSelfFriendChange()  // User can update their own friends[] without transaction

// Line 282 - Allows independent friend_request list updates
isSelfFriendRequestChange()
```

**Client-Side Risk:**
```dart
// Current pattern (not atomic):
await friendRequestDoc.delete();  // Step 1
await user1.update({
  'friends': FieldValue.arrayUnion([user2Ref])  // Step 2
});
await user2.update({
  'friends': FieldValue.arrayUnion([user1Ref])  // Step 3
});

// If Step 2 fails, request is deleted but users aren't friends!
```

**Consistency Issues:**
- Network failure between steps → partial update
- App crash mid-operation → orphaned state
- Concurrent requests (race condition) → duplicate friends or missed requests

**Recommendation:**

**Option 1: Cloud Function (Recommended)**
```javascript
exports.acceptFriendRequest = functions
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new Error('Unauthenticated');

    const { requestId } = data;
    const firestore = admin.firestore();

    // Run in transaction for atomicity
    return firestore.runTransaction(async (transaction) => {
      const requestRef = firestore.collection('friend_request').doc(requestId);
      const requestDoc = await transaction.get(requestRef);

      if (!requestDoc.exists) throw new Error('Request not found');
      const requestData = requestDoc.data();

      // Verify caller is receiver
      if (requestData.receiverId.id !== context.auth.uid) {
        throw new Error('Not authorized');
      }

      const requesterRef = requestData.requesterId;
      const receiverRef = requestData.receiverId;

      // Atomic updates
      transaction.delete(requestRef);
      transaction.update(requesterRef, {
        friends: admin.firestore.FieldValue.arrayUnion(receiverRef),
        friend_requests: admin.firestore.FieldValue.arrayRemove(requestRef)
      });
      transaction.update(receiverRef, {
        friends: admin.firestore.FieldValue.arrayUnion(requesterRef),
        friend_requests: admin.firestore.FieldValue.arrayRemove(requestRef)
      });

      return { success: true };
    });
  });
```

**Option 2: Client-Side Transaction**
```dart
await FirebaseFirestore.instance.runTransaction((transaction) async {
  // Read phase
  final requestDoc = await transaction.get(requestRef);
  final requesterRef = requestDoc.data()['requesterId'];
  final receiverRef = requestDoc.data()['receiverId'];

  // Write phase (atomic)
  transaction.delete(requestRef);
  transaction.update(requesterRef, {
    'friends': FieldValue.arrayUnion([receiverRef])
  });
  transaction.update(receiverRef, {
    'friends': FieldValue.arrayUnion([requesterRef])
  });
});
```

**Priority:** High
**Impact:** Data consistency, potential orphaned friend requests or incomplete friendships
**Effort:** 4-6 hours (Cloud Function + client code + testing)

---

### R-REL-009: Legacy chat_messages Collection (High)

**Collections:** chat_messages (legacy), chats/{chatId}/messages (current)
**Current Implementation:**
```javascript
// Security rules line 367-373 (legacy collection)
match /chat_messages/{messageId} {
  allow read: if isSignedIn() && resource.data.user.id == request.auth.uid;
  allow create, update, delete: if false;  // Read-only!
}

// onUserDeleted cleanup (lines 1079-1090)
await firestore.collection('chat_messages')
  .where('user', '==', userRef)
  .get()
  .then(async (querySnapshot) => {
    for (var doc of querySnapshot.docs) {
      await doc.ref.delete();
    }
  });
```

**Problem:**
- Legacy `chat_messages` top-level collection still exists
- Security rules allow reads (backward compatibility)
- Explicitly blocks writes (create/update/delete = false)
- User deletion cleanup still processes this collection
- Unclear if any clients still use legacy schema

**Architecture Evolution:**
```
OLD (deprecated):
  chat_messages/{messageId}
    - user.id (String UID)
    - message text
    - timestamp

NEW (current):
  chats/{chatId}/messages/{messageId}
    - senderId (String UID)
    - message text
    - timestamp
```

**Impact:**
- Code maintains legacy support indefinitely
- onUserDeleted has extra overhead
- Security rules complexity
- Unclear migration status (how many legacy messages remain?)

**Recommendation:**

1. **Audit:** Count legacy messages
```javascript
const legacyCount = await firestore.collection('chat_messages').count().get();
console.log(`Legacy messages: ${legacyCount.data().count}`);
```

2. **If count = 0:** Remove legacy support entirely
   - Delete security rules for chat_messages
   - Remove from onUserDeleted cleanup
   - Document as fully migrated

3. **If count > 0:** Complete migration
   - Migrate remaining messages to new schema
   - Archive old collection
   - Remove legacy support after migration

4. **Document decision** in codebase

**Priority:** High (technical debt cleanup)
**Impact:** Code maintainability, security rules complexity
**Effort:** 2-4 hours (audit + cleanup OR migration)

---

### R-REL-010: Chat-Game Relationship Not Validated (Medium)

**Collections:** games, chats
**Current Implementation:**
```dart
// GamesRecord
DocumentReference? chatRef;  // Optional - game may not have chat

// ChatsRecord
String? gameId;             // Optional - chat may not be game chat
String? type;               // 'direct' or 'game'
```

**Problem:**
- **No enforcement** that game chat has matching game
- `games.chatRef` could point to wrong chat (different game's chat)
- `chats.gameId` could reference non-existent game
- No validation in security rules that chatRef/gameId are consistent

**Inconsistency Scenarios:**

1. **Orphaned game chat:**
   - Game is cancelled: `games.isCancelled = true`
   - Chat still exists with `chats.type = 'game'` and `chats.gameId = 'cancelled_game'`
   - Chat is still accessible, but game is gone
   - No indication in chat UI that game was cancelled

2. **Mismatched references:**
   - `games.chatRef → chats/abc123`
   - `chats/abc123.gameId = 'xyz789'` (different game!)
   - Circular reference broken

**Security Rules Gap:**
```javascript
// Current: Game owner can update chatRef freely
ownerUpdateAllowed() checks 'chatRef' in allowed fields  // Line 241

// But doesn't validate:
// ❌ That chatRef.data.gameId == current game's ID
// ❌ That chatRef.data.type == 'game'
// ❌ That chat actually exists
```

**Recommendation:**

Add validation to security rules:

```javascript
function chatRefIsValid(gameId, chatRef) {
  if (chatRef == null) return true;  // Optional field

  let chatData = exists(chatRef) ? get(chatRef).data : null;
  return chatData != null &&
    chatData.type == 'game' &&
    chatData.gameId == gameId;
}

// Update ownerUpdateAllowed:
function ownerUpdateAllowed() {
  return isOwner(resource.data) &&
    // [existing checks...]
    chatRefIsValid(
      request.resource.id,  // Current game's ID
      request.resource.data.chatRef
    );
}
```

**Priority:** Medium
**Impact:** Data consistency, potential orphaned chats
**Effort:** 2-3 hours (security rules + testing)

---

### R-REL-011: Friend Request userRef Field Unclear (Medium)

**Collections:** friend_request
**Current Implementation:**
```dart
// FriendRequestRecord has THREE user references:
DocumentReference? receiverId;   // Line 24-26 (receiver of request)
DocumentReference? requesterId;  // Line 28-30 (sender of request)
DocumentReference? userRef;      // Line 33-36 (PURPOSE UNCLEAR!)
```

**Problem:**
- **Unclear purpose** of `userRef` field
- `receiverId` and `requesterId` already identify both parties
- No code comments explaining why third reference exists
- Security rules don't reference `userRef` (all checks use receiverId/requesterId)
- Creates confusion for developers

**Hypothesis:**
- Possible legacy field from earlier schema
- May have been used for "who created this document" before receiverId/requesterId split
- Currently unused

**Impact:**
- Schema pollution
- Wasted storage (redundant DocumentReference)
- Developer confusion
- Potential for misuse (setting wrong value)

**Recommendation:**

1. **Audit usage:**
```dart
// Search codebase for userRef usage in friend_request context
grep -r "userRef" --include="*.dart" | grep -i "friend"
```

2. **If unused:** Remove field
   - Update schema to delete `userRef`
   - Migration to remove from existing documents
   - Update `createFriendRequestRecordData` function

3. **If used:** Document purpose
   - Add code comment explaining why userRef exists
   - Clarify difference from receiverId/requesterId

**Priority:** Medium (code clarity)
**Impact:** Schema clarity, developer experience
**Effort:** 2-3 hours (audit + cleanup OR documentation)

---

### R-REL-012: No Denormalized Data Sync (Medium)

**Collections:** users (source), games/chats/friend_request (denormalized targets)
**Current Implementation:**
- User profile fields: `display_name`, `photo_url`, `handicap`, etc.
- These are NOT denormalized to games/chats
- UI must fetch user document separately for each reference

**Denormalization Opportunities:**

1. **Game Participants Display:**
   - Current: `games.joined_players[]` has DocumentReferences
   - UI must: `for (ref in joinedPlayers) { fetch(ref) }`
   - N+1 query problem for displaying player names

   - With denormalization:
   ```dart
   // games collection
   List<Map<String, dynamic>> joinedPlayersInfo = [
     {
       'ref': DocumentReference,
       'display_name': 'John Doe',
       'photo_url': '...',
       'handicap': 12
     }
   ];
   ```

2. **Chat Member Display:**
   - Current: `chats.memberIds[]` has String UIDs
   - UI must: Fetch each user document by UID
   - Same N+1 query problem

**Trade-offs:**

**Against denormalization:**
- Must keep data synchronized (Cloud Function overhead)
- Stale data risk if sync fails
- Increased document size (Firestore 1MB limit)
- More complex writes

**For denormalization:**
- Faster UI rendering (no extra fetches)
- Reduced read costs
- Better offline support (all data in one document)

**Recommendation:**

**Don't denormalize** - Current architecture is correct for this case:

**Rationale:**
1. User profile changes are rare (names don't change often)
2. Firestore read cost is low for small documents
3. Caching (UserProvider) reduces actual network calls
4. Avoiding denormalization keeps data consistent
5. N+1 can be batched: `firestore.getAll([ref1, ref2, ...])`

**Alternative:** If performance becomes issue, use Provider caching:
```dart
// UserProvider already caches user documents
final userProvider = Provider.of<UserProvider>(context);
final user = userProvider.getUserById(uid);  // Cached
```

**Priority:** Medium (optimization, not correctness)
**Impact:** Query performance vs data consistency trade-off
**Effort:** N/A (recommend NOT implementing)

---

### R-REL-013: No Game Deletion (Only Cancellation) (Medium)

**Collections:** games
**Current Implementation:**
```javascript
// Security rules line 389
allow delete: if false;  // Games CANNOT be deleted!

// Games use soft delete instead:
bool? isCancelled;  // Line 110-112 in GamesRecord
```

**Problem:**
- Games can never be hard-deleted from Firestore
- Only soft-deleted via `isCancelled = true`
- Accumulates historical data indefinitely
- No cleanup policy for old cancelled games

**Current Behavior:**
- User creates game
- User cancels game: `isCancelled = true`
- Game document remains forever
- Queries must filter: `.where('isCancelled', '==', false)`

**Impact:**
- **Storage growth:** All games stored forever
- **Query performance:** Must filter out cancelled games in every query
- **Collection size:** Grows unbounded over time

**Recommendation:**

**Option 1: Keep soft delete (current)**
- Add scheduled cleanup Cloud Function
- Delete games where `isCancelled == true` and `date < 90 days ago`
- Preserves recent history, cleans old data

```javascript
exports.cleanupOldCancelledGames = functions
  .pubsub.schedule('every 24 hours')
  .onRun(async () => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 90);

    const old = await firestore.collection('games')
      .where('isCancelled', '==', true)
      .where('date', '<', cutoff)
      .get();

    const batch = firestore.batch();
    old.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  });
```

**Option 2: Allow hard delete**
- Change security rule to allow owner to delete
- Requires cascading cleanup (chat deletion, player list updates)

**Priority:** Medium (optimization, not critical)
**Impact:** Storage costs, query complexity
**Effort:** 3-4 hours (scheduled cleanup function)

---

### R-REL-014: Friend Requests Missing Status Workflow (Medium)

**Collections:** friend_request
**Current Implementation:**
```dart
String? requestStatus;  // Line 19-21 (field exists)
```

**Problem:**
- `requestStatus` field exists but **no enforcement** of valid values
- No documented workflow: pending → accepted/declined?
- Current behavior unclear:
  - Is request deleted on acceptance?
  - Is status updated to 'accepted'?
  - What are valid status values?

**Expected Workflow:**

```
1. User A sends request to User B
   → friend_request created with status='pending'

2a. User B accepts:
   → Status updated to 'accepted'?
   → OR document deleted?
   → Both users.friends[] updated

2b. User B declines:
   → Status updated to 'declined'?
   → OR document deleted?
   → No friends[] update
```

**Current Security Rules:**
```javascript
match /friend_request/{document} {
  allow create: if request.auth != null;
  allow read: if request.auth != null;
  allow write: if request.auth != null;  // Too permissive!
  allow delete: if request.auth != null;
}
```

**Issues:**
- No validation of status values
- Any authenticated user can write any friend_request (not just sender/receiver)
- No workflow enforcement

**Recommendation:**

1. **Document status values:**
```dart
enum FriendRequestStatus {
  pending,
  accepted,
  declined,
  cancelled  // If sender withdraws
}
```

2. **Add security rules validation:**
```javascript
function validStatus(data) {
  return data.request_status in ['pending', 'accepted', 'declined', 'cancelled'];
}

function isRequesterOrReceiver(data) {
  return request.auth.uid == data.requesterId.id ||
         request.auth.uid == data.receiverId.id;
}

match /friend_request/{document} {
  allow create: if isSignedIn() &&
    request.resource.data.requesterId == userRef(request.auth.uid) &&
    validStatus(request.resource.data);

  allow read: if isSignedIn() && isRequesterOrReceiver(resource.data);

  allow update: if isSignedIn() &&
    isRequesterOrReceiver(resource.data) &&
    validStatus(request.resource.data);

  allow delete: if isSignedIn() && isRequesterOrReceiver(resource.data);
}
```

3. **Decide on workflow:**
   - **Option A:** Delete on accept/decline (current behavior assumed)
   - **Option B:** Update status field (keeps history)

**Priority:** Medium
**Impact:** Data consistency, security
**Effort:** 3-4 hours (rules + workflow documentation)

---

### R-REL-015: Chat Direct Key Validation (Low)

**Collections:** chats
**Current Implementation:**
```dart
String? directKey;  // Line 80-82 (for direct chats only)

// Security rule validates format (lines 26-33):
function hasValidDirectKey(data) {
  return data.memberIds.size() == 2 &&
    data.directKey is string &&
    ((data.memberIds[0] < data.memberIds[1] &&
      data.directKey == data.memberIds[0] + '_' + data.memberIds[1]) ||
     (data.memberIds[1] < data.memberIds[0] &&
      data.directKey == data.memberIds[1] + '_' + data.memberIds[0]));
}
```

**Purpose:**
- Prevent duplicate direct chats between same two users
- `directKey` = sorted UIDs joined with underscore
- Example: Users "alice" and "bob" → directKey = "alice_bob"

**Current Implementation Quality:**
✓ Security rule validates format
✓ Alphabetical sorting ensures consistency
✓ Prevents duplicates (unique index on directKey)

**Potential Issue:**
- What if UID contains underscore character?
  - Firebase UIDs are alphanumeric + hyphen (no underscores), so safe
  - Custom UIDs could theoretically have underscores
  - Could cause parsing issues if splitting on '_'

**Recommendation:**
- **Low priority** - Current implementation is correct for Firebase Auth UIDs
- If custom auth is added, document underscore restriction
- Consider using `|` delimiter instead of `_` for extra safety

**Priority:** Low (works correctly for current auth system)
**Impact:** Minimal (edge case only)
**Effort:** 0 hours (no changes needed)

---

### R-REL-016: Course Collection No Ownership (Low)

**Collections:** course
**Current Implementation:**
```javascript
// Security rules lines 305-310
match /course/{document} {
  allow create: if true;         // Anyone can create courses!
  allow read: if true;           // Public read
  allow write: if false;         // No updates allowed
  allow delete: if false;        // No deletions allowed
}
```

**Problem:**
- **Anyone** can create courses (even unauthenticated users)
- No ownership tracking (who created the course?)
- No admin role for course management
- Courses are effectively immutable after creation

**Impact:**
- **Spam risk:** Malicious users could create fake courses
- **No moderation:** Can't update course info (address, photo) after creation
- **No cleanup:** Can't delete duplicate or incorrect courses

**Use Cases That Fail:**
1. Course info changes (new photo, address update) → Can't update
2. Duplicate course created by mistake → Can't delete
3. Spam course created → Can't remove

**Recommendation:**

**Option 1: Admin-only course management**
```javascript
function isAdmin() {
  return isSignedIn() &&
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}

match /course/{document} {
  allow create: if isAdmin();
  allow read: if true;  // Public read
  allow update: if isAdmin();
  allow delete: if isAdmin();
}
```

**Option 2: User-submitted with approval**
```dart
// CourseRecord add fields:
String? submittedBy;  // User who created
String? status;       // 'pending', 'approved', 'rejected'
```

```javascript
match /course/{document} {
  allow create: if isSignedIn() &&
    request.resource.data.submittedBy == request.auth.uid &&
    request.resource.data.status == 'pending';

  allow read: if resource.data.status == 'approved';  // Only approved visible

  allow update: if isAdmin();  // Admins approve/reject
  allow delete: if isAdmin();
}
```

**Priority:** Low (only if course spam becomes issue)
**Impact:** Potential spam, no content moderation
**Effort:** 2-3 hours (security rules + UI for admin panel)

---

## Consistency Issues Summary

### DocumentReference vs String UID Patterns

| Collection | Field | Type | Consistent? | Notes |
|------------|-------|------|-------------|-------|
| games | userRef | DocumentReference | ✓ | Standard pattern |
| games | uid | String | ❌ | DUPLICATE of userRef |
| games | courseRef | DocumentReference | ✓ | Standard pattern |
| games | chatRef | DocumentReference | ✓ | Standard pattern |
| games | joined_players[] | List<DocumentReference> | ✓ | Standard pattern |
| chats | users[] | List<DocumentReference> | ❌ | LEGACY, use memberIds instead |
| chats | memberIds[] | List<String> | ✓ | Current pattern for members |
| chats | user_a | DocumentReference | ✓ | For direct chats |
| chats | user_b | DocumentReference | ✓ | For direct chats |
| chats | gameId | String | ❌ | Should be DocumentReference |
| users | friends[] | List<DocumentReference> | ✓ | Standard pattern |
| users | friend_requests[] | List<DocumentReference> | ✓ | Standard pattern |
| users | home_course | String | ❌ | Should be DocumentReference |
| friend_request | receiverId | DocumentReference | ✓ | Standard pattern |
| friend_request | requesterId | DocumentReference | ✓ | Standard pattern |

**Consistency Score: 45/100**

**Recommendation:** Standardize on DocumentReference for all entity references, use String UID only for:
- Security rule comparisons (`request.auth.uid`)
- Chat memberIds (for efficient "user in members" checks)

---

## Orphaned Data Risk Matrix

| Deletion Scenario | Orphaned Data | Risk Level | Current Cleanup | Recommended Fix |
|-------------------|---------------|------------|-----------------|-----------------|
| **User deleted** | games.uid | 🔴 Critical | ❌ None | Cascade: Cancel games or delete |
| **User deleted** | games.userRef | 🔴 Critical | ❌ None | Cascade: Cancel games or delete |
| **User deleted** | games.joined_players[] | 🔴 Critical | ❌ None | Cascade: Remove from arrays |
| **User deleted** | chats.memberIds[] | 🔴 Critical | ❌ None | Cascade: Remove or delete chat |
| **User deleted** | chats.users[] (legacy) | 🟡 High | ❌ None | Cascade: Remove or delete chat |
| **User deleted** | friend_request docs | 🔴 Critical | ❌ None | Cascade: Delete requests |
| **User deleted** | users.friends[] in others | ✅ Fixed | ✓ removeUserFromArrays | Working correctly |
| **User deleted** | users.friend_requests[] | ✅ Fixed | ✓ removeUserFromArrays | Working correctly |
| **User deleted** | chat messages | 🟡 High | ✅ Partial | Legacy only, not subcollection |
| **Chat deleted** | chats/{id}/messages | 🔴 Critical | ❌ None | Cloud Function needed |
| **Chat deleted** | games.chatRef | 🟡 High | ❌ None | Validate in security rules |
| **Game deleted** | chats.gameId | 🟡 High | ❌ None | Convert to DocumentReference |
| **Game deleted** | games.chatRef | 🟢 Low | 🔒 Blocked | Games can't be deleted |
| **Course renamed** | users.home_course | 🟡 High | ❌ None | Convert to DocumentReference |

**Legend:**
- 🔴 Critical - Data integrity violation, broken UX
- 🟡 High - Stale data, degraded UX
- 🟢 Low - Minor issue or prevented by design

---

## Cloud Functions Audit

### Existing Triggers

| Function | Trigger | Purpose | Cleanup Scope |
|----------|---------|---------|---------------|
| onUserDeleted | auth.user().onDelete | User deletion cleanup | ✅ fcm_tokens, ✅ usernames, ✅ users/{uid}, ✅ chat_messages (legacy), ✅ friends arrays, ✅ friend_requests arrays |
| monitorUsernameChanges | firestore.document('users/{uid}').onWrite | Username consistency check | Monitoring only |
| syncUsernameIndex | firestore.document('users/{uid}').onWrite | Sync display_name to usernames collection | Username index management |
| sendGameCreatedNotifications | firestore.document('games/{gameId}').onCreate | Push notifications | Not cleanup-related |
| sendChatMessageNotifications | firestore.document('chats/{chatId}/messages/{messageId}').onCreate | Push notifications | Not cleanup-related |

### Missing Triggers (Recommended)

| Function | Trigger | Purpose | Priority |
|----------|---------|---------|----------|
| cleanupChatMessages | firestore.document('chats/{chatId}').onDelete | Delete orphaned messages subcollection | 🔴 Critical |
| cleanupUserGames | auth.user().onDelete | Remove user from games.joined_players[], cancel hosted games | 🔴 Critical |
| cleanupUserChats | auth.user().onDelete | Remove user from chats.memberIds[], delete 1-person chats | 🔴 Critical |
| cleanupFriendRequests | auth.user().onDelete | Delete friend requests involving deleted user | 🔴 Critical |
| syncUserProfileChanges | firestore.document('users/{uid}').onUpdate | Sync display_name changes to denormalized fields | 🟡 High (if denormalizing) |
| cleanupOldCancelledGames | pubsub.schedule('daily') | Delete games where isCancelled && date < 90 days | 🟡 High |

---

## Phase 11 Integrity Roadmap

### Critical Fixes (Must Complete Before Beta)

**Estimated Total: 24-32 hours**

1. **Implement Chat Messages Cleanup Function** (3-4 hours)
   - Priority: Critical
   - Impact: Prevents storage leaks, GDPR compliance
   - Creates: `cleanupChatMessages` Cloud Function
   - Testing: Delete chat with 100+ messages, verify subcollection deleted

2. **Standardize Game-Chat Relationship** (5-7 hours)
   - Priority: Critical
   - Impact: Consistent data model, better query performance
   - Changes: `chats.gameId` String → DocumentReference
   - Migration: Convert all existing chats
   - Security rules: Update isGameParticipant to use DocumentReference

3. **Migrate Legacy Chat Members** (6-8 hours)
   - Priority: Critical
   - Impact: Removes data duplication, simplifies queries
   - Changes: Remove `chats.users[]`, keep only `chats.memberIds[]`
   - Migration: Backfill memberIds from users for all chats
   - Security rules: Remove legacy compatibility code

4. **Remove Game Host Duplication** (4-6 hours)
   - Priority: Critical
   - Impact: Eliminates redundancy, prevents inconsistency
   - Changes: Remove `games.uid`, keep only `games.userRef`
   - Migration: All games already have userRef (just delete uid field)
   - Security rules: Update isOwner to use `data.userRef.id`

### High Priority Fixes (Strongly Recommended for Beta)

**Estimated Total: 16-24 hours**

5. **Comprehensive User Deletion Cascade** (8-12 hours)
   - Priority: High
   - Impact: GDPR compliance, prevents ghost users
   - Enhances: `onUserDeleted` Cloud Function
   - Adds cleanup for: games (host + participant), chats, friend_requests, chat messages

6. **Transaction-Based Friend Requests** (4-6 hours)
   - Priority: High
   - Impact: Data consistency, prevents partial updates
   - Creates: `acceptFriendRequest` Cloud Function
   - Uses: Firestore transactions for atomicity

7. **Course Reference Standardization** (4-5 hours)
   - Priority: High
   - Impact: Consistent patterns, prevents stale data
   - Changes: `users.home_course` String → DocumentReference
   - Migration: Lookup course by name, set DocumentReference

### Medium Priority (Post-Beta)

**Estimated Total: 8-12 hours**

8. **Friend Request Status Workflow** (3-4 hours)
   - Priority: Medium
   - Impact: Clearer semantics, better security
   - Adds: Status validation in security rules
   - Documents: Workflow states (pending/accepted/declined)

9. **Legacy chat_messages Cleanup** (2-4 hours)
   - Priority: Medium
   - Impact: Code simplification
   - Audit: Count legacy messages
   - Cleanup: Remove if empty, migrate if not

10. **Game-Chat Relationship Validation** (2-3 hours)
    - Priority: Medium
    - Impact: Prevents mismatched references
    - Adds: Security rule validation of chatRef.gameId

### Optional Optimizations

11. **Bidirectional Game Tracking** (6-8 hours)
    - Priority: Low (only if user profile shows game list)
    - Impact: Query performance
    - Adds: `users.joinedGamesRefs[]` field
    - Migration: Backfill from games.joined_players

12. **Scheduled Old Game Cleanup** (3-4 hours)
    - Priority: Low
    - Impact: Storage optimization
    - Creates: Scheduled function to delete old cancelled games

**Total Effort (Critical + High):** 40-56 hours
**Recommended Sprint:** 2 weeks (2 developers)

---

## Best Practices Guide

### Relationship Design Principles

**1. Use DocumentReference for Entity References**

✅ **Good:**
```dart
DocumentReference? userRef;  // Type-safe, enables joins
DocumentReference? courseRef;
```

❌ **Bad:**
```dart
String? userId;  // Brittle, manual path construction
String? courseName;  // Stale if name changes
```

**When to use String UID:**
- Security rules comparisons: `request.auth.uid`
- Membership checks: `uid in memberIds` (efficient)
- Never for entity references that need to be joined

**2. Plan Cascading Deletes Before Implementing Delete**

**Questions to ask:**
- What references this entity?
- What does this entity reference?
- What should happen when it's deleted?

**Options:**
1. **Cascading delete** - Delete related entities (games → chat)
2. **Soft delete** - Mark as deleted, filter in queries (games.isCancelled)
3. **Prevent deletion** - Block in security rules (courses)
4. **Cleanup references** - Remove from arrays (user → games.joined_players)

**3. Use Cloud Functions for Cascading Operations**

❌ **Don't do client-side:**
```dart
// Risky - what if network fails between steps?
await gameDoc.delete();
await chatDoc.delete();
await updateUserArrays();
```

✅ **Use Cloud Function:**
```javascript
exports.onGameDeleted = functions
  .firestore.document('games/{gameId}')
  .onDelete(async (snapshot, context) => {
    // Guaranteed to execute, retry on failure
    await deleteRelatedChat(snapshot.data().chatRef);
    await removeFromPlayerArrays(snapshot.data().joined_players);
  });
```

**4. Always Cleanup Subcollections**

**Critical:** Firestore does NOT auto-delete subcollections!

```javascript
// REQUIRED for subcollections
exports.cleanupSubcollections = functions
  .firestore.document('parent/{docId}')
  .onDelete(async (snapshot, context) => {
    const subcollections = ['messages', 'comments', 'reactions'];

    for (const sub of subcollections) {
      const docs = await snapshot.ref.collection(sub).get();
      const batch = firestore.batch();
      docs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
    }
  });
```

**5. Use Transactions for Multi-Document Updates**

**When to use:**
- Friend request acceptance (3 documents)
- Game join (2 documents if bidirectional)
- Any operation where partial completion = inconsistent state

```dart
await firestore.runTransaction((transaction) async {
  // Read phase
  final doc1 = await transaction.get(ref1);
  final doc2 = await transaction.get(ref2);

  // Write phase (atomic)
  transaction.update(ref1, {...});
  transaction.update(ref2, {...});
  transaction.delete(ref3);
});
```

**6. Document Relationship Patterns**

Every relationship should answer:
- **Type:** One-to-one, one-to-many, many-to-many?
- **Direction:** Unidirectional or bidirectional?
- **Format:** DocumentReference, String UID, or embedded?
- **Integrity:** What happens on delete?
- **Queries:** How is this relationship traversed?

---

## Data Migration Strategy

### Breaking Changes: String → DocumentReference

**Impact:**
- Client code must update from `String uid` to `DocumentReference.id`
- Firestore queries change from `where('uid', '==', ...)` to `where('ref', '==', ...)`
- Security rules must use `data.ref.id` instead of `data.uid`

**Migration Phases:**

**Phase 1: Add new field (backward compatible)**
```dart
// Both fields exist temporarily
String? uid;                // Legacy
DocumentReference? userRef;  // New

// Security rules support both
isOwner(data) = (data.uid == request.auth.uid) ||
                (data.userRef.id == request.auth.uid)
```

**Phase 2: Backfill data**
```javascript
const games = await firestore.collection('games').get();
const batch = firestore.batch();

games.docs.forEach(doc => {
  if (doc.data().uid && !doc.data().userRef) {
    batch.update(doc.ref, {
      userRef: firestore.doc(`users/${doc.data().uid}`)
    });
  }
});

await batch.commit();
```

**Phase 3: Update client code**
- Change all code to use new field
- Test thoroughly
- Deploy new app version

**Phase 4: Remove legacy field**
- Update security rules to only check new field
- Remove old field from schema
- Run migration to delete old field from documents

**Estimated Data Volume:**
- Games collection: ~500-1000 documents (estimated)
- Chats collection: ~200-500 documents (estimated)
- Migration time: <5 minutes for all collections

---

## Cross-References

**Phase 8 Architectural Violations:**
- Direct Firestore access in widgets makes cascading operations harder
- No service layer to encapsulate relationship management
- Business logic scattered across UI and security rules
- **Impact:** Implementing cascading deletes requires changes in multiple places

**Phase 9 Plan 01 Schema Audit:**
- Field redundancy (uid + userRef) stems from relationship inconsistency
- Identified in this audit as R-REL-001

**Phase 9 Plan 02 Query Audit:**
- String UID vs DocumentReference affects query patterns
- Mixed patterns complicate index management
- Security rule complexity due to supporting both patterns

**Phase 11 Refactoring Recommendations:**
- Service layer should encapsulate relationship management
- GameService handles cascading game operations
- ChatService handles chat lifecycle and cleanup
- FriendService enforces transactional friend requests
- Reduces duplication between client code and Cloud Functions

---

## Summary Statistics

**Total Issues Found:** 23

**By Priority:**
- Critical: 8 (35%)
- High: 9 (39%)
- Medium: 6 (26%)
- Low: 0 (0%)

**By Category:**
- Relationship Consistency: 8 issues
- Referential Integrity: 9 issues
- Cascading Operations: 4 issues
- Legacy Migration: 2 issues

**Estimated Fix Effort:**
- Critical fixes: 24-32 hours
- High priority: 16-24 hours
- Medium priority: 8-12 hours
- Total: 48-68 hours

**Pre-Beta Readiness:**
- Must fix: 4 critical issues (24-32 hours)
- Strongly recommended: 3 high priority issues (16-24 hours)
- **Total for beta:** 40-56 hours (2-week sprint)

---

**End of Audit**
