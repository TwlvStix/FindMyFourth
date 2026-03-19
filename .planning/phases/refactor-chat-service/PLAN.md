# Refactor: ChatService Split - Plan

**Created:** 2026-03-19
**Context:** CONTEXT.md
**Goal:** Split `chat_service.dart` (985 lines) into 3 focused services, update consumers

## Execution Order

Tasks must run sequentially — each builds on the previous.

---

### Task 1: Create `chat_lifecycle_service.dart`

**File:** `lib/services/chat_lifecycle_service.dart`

Extract these methods from `chat_service.dart`:
- `createOrGetDirectChat()` (lines 193-254)
- `createGameChat()` (lines 256-287)
- `addMember()` (lines 296-323)
- `ensureGameChatMembership()` (lines 332-352)
- `removeMember()` (lines 360-379)
- `isLastMember()` (lines 386-402)
- `leaveChat()` (lines 410-445)
- `deleteChat()` (lines 682-750)
- `_deleteChatAndMessages()` (lines 450-488) — private helper
- `_userChatRef()` (lines 21-27) — duplicated helper
- `_chunkList()` (lines 92-99) — duplicated helper (used by _deleteChatAndMessages batch ops)

**Imports needed:**
- `cloud_firestore`, `cloud_functions`, `firebase_auth`
- `app_exceptions.dart` (ChatOperationException)
- `app_log.dart`
- `input_sanitizer.dart` (used by createGameChat)

**Constructor:** `ChatLifecycleService({FirebaseFirestore? firestore})`

**Verification:** File compiles, all method signatures match original exactly.

---

### Task 2: Create `chat_message_service.dart`

**File:** `lib/services/chat_message_service.dart`

Extract these methods from `chat_service.dart`:
- `getChatListStream()` (lines 29-89)
- `getChatStream()` (lines 101-109)
- `getMessagesStream()` (lines 111-138)
- `getMessagesSnapshotStream()` (lines 140-160)
- `getMessagesPage()` (lines 162-191)
- `sendMessage()` (lines 558-623)
- `sendSystemMessage()` (lines 495-544)
- `markChatRead()` (lines 625-633)
- `markChatNotificationsAsRead()` (lines 638-680)
- `markMessageAsRead()` (lines 854-868)
- `markMessagesAsReadBatch()` (lines 881-969)
- `getUserProfile()` (lines 752-761) + `_userCache` field
- `clearUserCache()` (lines 763-765)
- `logError()` (lines 971-974)
- `_userChatRef()` (lines 21-27) — duplicated helper
- `_chunkList()` (lines 92-99) — duplicated helper

**Also include:** `MessagesPage` class (lines 977-985)

**Imports needed:**
- `cloud_firestore`, `firebase_auth`, `rxdart`
- `app_log.dart`, `input_sanitizer.dart`
- `chat.dart`, `chat_message.dart`

**Constructor:** `ChatMessageService({FirebaseFirestore? firestore})`

**Verification:** File compiles, all method signatures match original exactly.

---

### Task 3: Create `chat_interaction_service.dart`

**File:** `lib/services/chat_interaction_service.dart`

Extract these methods from `chat_service.dart`:
- `addReaction()` (lines 787-818)
- `removeReaction()` (lines 820-852)
- `setTypingStatus()` (lines 767-785)

**Imports needed:**
- `cloud_firestore`
- `app_log.dart`

**Constructor:** `ChatInteractionService({FirebaseFirestore? firestore})`

**Verification:** File compiles, all method signatures match original exactly.

---

### Task 4: Update `chat_provider.dart`

**File:** `lib/providers/chat_provider.dart`

Changes:
1. Replace `import '/services/chat_service.dart'` with 3 new imports
2. Change constructor:
   ```dart
   ChatProvider({
     ChatLifecycleService? lifecycleService,
     ChatMessageService? messageService,
     ChatInteractionService? interactionService,
   }) : _lifecycleService = lifecycleService ?? ChatLifecycleService(),
        _messageService = messageService ?? ChatMessageService(),
        _interactionService = interactionService ?? ChatInteractionService();
   ```
3. Replace `_service` field with `_lifecycleService`, `_messageService`, `_interactionService`
4. Route each method call to correct sub-service:
   - **Lifecycle:** `createOrGetDirectChat`, `createGameChat`, `addMember`, `removeMember`, `leaveChat`, `ensureGameChatMembership`, `isLastMember`, `deleteChat`
   - **Message:** `getChatListStream` → `chatListStream`, `getChatStream` → `chatStream`, `getMessagesStream` → `messagesStream`, `getMessagesSnapshotStream` → `messagesSnapshotStream`, `getMessagesPage`, `sendMessage`, `sendImageMessage` (calls sendMessage), `sendSystemMessage`, `markChatRead`, `markChatNotificationsAsRead`, `markMessageAsRead`, `markMessagesAsReadBatch`, `getUserProfile`, `clearUserCache`, `logError`
   - **Interaction:** `addReaction`, `removeReaction`, `setTypingStatus`

**Verification:** `flutter analyze` passes. No remaining references to `ChatService`.

---

### Task 5: Update `rebook_service.dart`

**File:** `lib/services/rebook_service.dart`

Changes:
1. Replace `import '/services/chat_service.dart'` with `import '/services/chat_lifecycle_service.dart'`
2. Change constructor parameter: `ChatService? chatService` → `ChatLifecycleService? chatLifecycleService`
3. Change field: `_chatService` → `_chatLifecycleService` (or keep `_chatService` name, just change type)
4. Usage at line 123 stays the same: `_chatLifecycleService.createGameChat(...)`

**Verification:** File compiles. `createGameChat` call unchanged.

---

### Task 6: Delete `chat_service.dart` and verify

1. Delete `lib/services/chat_service.dart`
2. Run `flutter analyze` — expect zero errors
3. Grep for any remaining `ChatService` references (should be none)

**Verification:** `flutter analyze` clean. `grep -r 'ChatService' lib/` returns no results.

---

## Success Criteria

- [ ] 3 new service files exist with correct method assignments
- [ ] `chat_service.dart` deleted
- [ ] `ChatProvider` injects 3 services, routes all methods correctly
- [ ] `RebookService` uses `ChatLifecycleService`
- [ ] `flutter analyze` passes with zero errors
- [ ] No remaining imports of `chat_service.dart`
- [ ] All method signatures identical to original (no behavior change)
