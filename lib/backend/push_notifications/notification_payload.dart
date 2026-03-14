// Notification payload normalization and deduplication helpers.
//
// Pure data helpers with no Flutter/Firebase widget dependencies.

/// TTL-based deduplication cache with 5-minute expiry.
/// Prevents duplicate navigation while allowing legitimate taps to same destination.
final handledMessageCache = <String, DateTime>{};

/// Prune stale entries from deduplication cache (older than 5 minutes).
void pruneStaleDedupeEntries() {
  final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
  handledMessageCache.removeWhere((_, timestamp) => timestamp.isBefore(cutoff));
}

/// Compute a content-based hash for deduplication when messageId is null.
///
/// Uses only deterministic payload fields (type + IDs) to create a unique key.
/// This prevents duplicate navigation if the same notification is received twice
/// without a messageId. Note: Two genuinely different notifications with the
/// same type and IDs will be deduped, but this is acceptable since they would
/// navigate to the same screen anyway.
String computeContentHash(Map<String, dynamic> data) {
  final type = data['type'] ?? '';
  final gameId = data['gameId'] ?? data['game_id'] ?? '';
  final chatId = data['chatId'] ?? data['chat_id'] ?? data['threadId'] ?? data['thread_id'] ?? '';
  final gameRef = data['gameRef'] ?? data['game_ref'] ?? '';
  // Use deterministic fields only - no timestamp
  return 'content_${type}_${gameId}_${chatId}_$gameRef';
}

/// Normalize payload keys to handle both camelCase (legacy) and snake_case (backend).
///
/// This function ensures routing works regardless of which key format the
/// backend sends. Original keys are preserved, then normalized versions override.
///
/// Bridges Trust system payloads (event_type) with legacy payloads (type).
Map<String, dynamic> normalizeNotificationPayload(Map<String, dynamic> data) {
  return {
    // Pass through all original keys FIRST
    ...data,

    // Then override with normalized versions (these take precedence)
    // Bridge event_type (Trust system) → type (legacy/routing)
    'type': data['type'] ?? data['event_type'],
    'initialPageName': data['initialPageName'] ?? data['initial_page_name'],
    'parameterData': data['parameterData'] ?? data['parameter_data'],

    // Game keys
    'gameId': data['gameId'] ?? data['game_id'],
    'gameRef': data['gameRef'] ?? data['game_ref'],

    // Chat keys
    'chatId': data['chatId'] ?? data['chat_id'],
    'threadId': data['threadId'] ?? data['thread_id'],

    // Trust system keys preserved for reference
    'eventId': data['eventId'] ?? data['event_id'],

    // Internal tracking
    '_messageId': data['_messageId'],
  };
}
