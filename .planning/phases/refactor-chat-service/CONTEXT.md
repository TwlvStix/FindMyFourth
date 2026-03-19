# Refactor: ChatService Split - Context

**Gathered:** 2026-03-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Split `lib/services/chat_service.dart` (985 lines) into 3 focused sub-services by domain responsibility. Maintain all existing functionality. Update ChatProvider and RebookService to consume the new services.

</domain>

<decisions>
## Implementation Decisions

### Split boundaries — 3 services by domain responsibility

**ChatLifecycleService** (~400 lines) — Chat CRUD + membership
- `createOrGetDirectChat`, `createGameChat`, `deleteChat`, `leaveChat`
- `addMember`, `removeMember`, `ensureGameChatMembership`, `isLastMember`
- `_deleteChatAndMessages` (internal helper)
- `_userChatRef` helper (duplicated — needs `_firestore`)
- `_chunkList` helper (duplicated where needed)
- Rationale: Membership and lifecycle are tightly coupled — `createOrGetDirectChat` sets up chatRefs, `leaveChat` calls `removeMember`

**ChatMessageService** (~450 lines) — Message operations + chat streams
- `sendMessage`, `sendSystemMessage`
- `getChatListStream`, `getChatStream`, `getMessagesStream`, `getMessagesSnapshotStream`, `getMessagesPage`
- `markChatRead`, `markChatNotificationsAsRead`, `markMessageAsRead`, `markMessagesAsReadBatch`
- `getUserProfile`, `clearUserCache` (display cache — tightly coupled to message rendering)
- `MessagesPage` class (query result wrapper, stays with its service)
- `logError` helper
- `_userChatRef` helper (duplicated)
- `_chunkList` helper (duplicated)

**ChatInteractionService** (~90 lines) — Reactions + typing
- `addReaction`, `removeReaction` (transaction-based)
- `setTypingStatus`
- Small but distinct domain. Matches existing small-service pattern (`cancellation_service.dart` 28 lines, `app_badge_service.dart` 39 lines)

### Shared helpers — Duplicate per service (no shared base)

- Codebase has zero shared service base classes or mixins — all services are fully independent
- `_userChatRef()` (4 lines, needs `_firestore`) — duplicated in each service that uses it
- `_chunkList()` (7 lines, generic) — duplicated where needed
- No mixin, no base class, no utility file

### Provider wiring — Multi-service injection

- Follows `RebookService` multi-dependency pattern
- `ChatProvider({ChatLifecycleService? lifecycleService, ChatMessageService? messageService, ChatInteractionService? interactionService})`
- Each service injected independently for testability
- Provider routes method calls to the correct sub-service internally
- No facade service needed — provider IS the facade

### File organization — Flat in services/ with naming prefix

- Follows notification system pattern (6 flat files) and vibe system (8+ flat files)
- `lib/services/chat_lifecycle_service.dart`
- `lib/services/chat_message_service.dart`
- `lib/services/chat_interaction_service.dart`
- Delete `lib/services/chat_service.dart` after migration complete

### Constructor pattern — Standard DI

Each sub-service follows established codebase pattern:
```dart
class ChatLifecycleService {
  ChatLifecycleService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;
}
```

### Consumer updates required

- `lib/providers/chat_provider.dart` — inject 3 services instead of 1, route each method call
- `lib/services/rebook_service.dart` — change `ChatService` → `ChatLifecycleService` (only uses `createGameChat`)
- No widget changes — widgets use `ChatProvider`, never `ChatService` directly

### Claude's Discretion
- Exact import ordering in new files
- Whether to add doc comments beyond what exists
- Internal method ordering within each new service

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Source file
- `lib/services/chat_service.dart` — The 985-line file being split (read for exact method signatures and logic)

### Consumers to update
- `lib/providers/chat_provider.dart` — Primary consumer, wraps all ChatService methods with caching/streams
- `lib/services/rebook_service.dart` — Uses `createGameChat` only (line 123)

### Existing split patterns to follow
- `lib/services/notification_permission_service.dart` — Example of focused service (~466 lines)
- `lib/services/notification_crud_service.dart` — Example of CRUD-focused service (~347 lines)
- `lib/services/cancellation_service.dart` — Example of small focused service (28 lines)

### Project conventions
- `CLAUDE.md` — Service pattern, DI pattern, error handling, logging conventions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `InputSanitizer` (`lib/core/utils/input_sanitizer.dart`): Used by sendMessage/sendSystemMessage — stays in ChatMessageService
- `ChatOperationException` (`lib/core/exceptions/app_exceptions.dart`): Used by addMember/removeMember — stays in ChatLifecycleService
- `Chat` model (`lib/models/chat.dart`): Used by stream methods
- `ChatMessage` model (`lib/models/chat_message.dart`): Used by message methods

### Established Patterns
- Instance DI with optional `FirebaseFirestore?` constructor parameter
- `FirebaseException` catch with `AppLog.d('❌ ...')` and rethrow
- Non-critical operations use generic `catch` and log silently (e.g., `ensureGameChatMembership`)
- Transactions for concurrent-safe operations (reactions, chat creation, message send)

### Integration Points
- `ChatProvider` in `lib/main.dart` line 88 — instantiation stays the same (just different constructor params)
- `StreamRequestManager` in ChatProvider — wraps service streams with caching
- `ChatViewModelManager` in ChatProvider — already uses compositional delegation

</code_context>

<specifics>
## Specific Ideas

- User wants split strictly by domain responsibility
- All existing functionality must be maintained (no behavior changes)
- Follow existing codebase conventions exactly

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within refactor scope

</deferred>

---

*Refactor: chat-service-split*
*Context gathered: 2026-03-19*
