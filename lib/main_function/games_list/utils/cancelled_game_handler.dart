import '/models/game.dart';
import '/utils/app_util.dart';

/// Options for how to handle cancelled games in the games list.
enum CancelledGameHandling {
  removeNow,
  removeEndOfDay,
  removeAfter7Days,
  keepInList,
}

/// Map from enum values to storage string keys.
const Map<CancelledGameHandling, String> cancelledHandlingStorageMap = {
  CancelledGameHandling.removeNow: 'removeNow',
  CancelledGameHandling.removeEndOfDay: 'removeEndOfDay',
  CancelledGameHandling.removeAfter7Days: 'removeAfter7Days',
  CancelledGameHandling.keepInList: 'keepInList',
};

/// Parses a stored string value back to [CancelledGameHandling].
///
/// Returns null if the value is null or unrecognized.
CancelledGameHandling? parseCancelledHandling(String? value) {
  if (value == null) {
    return null;
  }
  for (final entry in cancelledHandlingStorageMap.entries) {
    if (entry.value == value) {
      return entry.key;
    }
  }
  return null;
}

/// Gets the cached or stored cancelled game handling for a game.
///
/// First checks the in-memory [cache], then falls back to [AppState] storage.
/// If found in storage, the value is added to the cache for future lookups.
CancelledGameHandling? getCancelledHandling(
  Game game,
  Map<DocumentReference, CancelledGameHandling> cache,
) {
  final cached = cache[game.reference];
  if (cached != null) {
    return cached;
  }
  final storedValue = AppState().getCancelledGameHandling(game.reference.path);
  final parsed = parseCancelledHandling(storedValue);
  if (parsed != null) {
    cache[game.reference] = parsed;
  }
  return parsed;
}

/// Determines if a cancelled game should be hidden from the list.
///
/// Returns true if:
/// - The game is not cancelled (always returns false)
/// - The game has expired based on schedule type
/// - User selected "Remove now"
/// - User selected "Remove end of day" and end of day has passed
/// - User selected "Remove after 7 days" and 7 days have passed
bool shouldHideCancelledGame(
  Game game,
  Map<DocumentReference, CancelledGameHandling> cache,
) {
  // Use status field instead of isCancelled
  if (game.status != 'cancelled') {
    return false;
  }

  // Auto-hide cancelled games after they've expired
  // This happens regardless of user preference
  if (isCancelledGameExpired(game)) {
    return true;
  }

  // For same-day cancelled games, check if user selected "Remove now"
  final handling = getCancelledHandling(game, cache);
  if (handling == CancelledGameHandling.removeNow) {
    return true;
  }

  // Legacy handling options (kept for backward compatibility)
  if (handling == CancelledGameHandling.removeEndOfDay) {
    final gameDate = game.date;
    if (gameDate == null) {
      return false;
    }
    final endOfDay = DateTime(
      gameDate.year,
      gameDate.month,
      gameDate.day,
      23,
      59,
      59,
    );
    return getCurrentTimestamp.isAfter(endOfDay);
  }
  if (handling == CancelledGameHandling.removeAfter7Days) {
    final hideAt = AppState().getCancelledGameHideAt(game.reference.path);
    if (hideAt == null) {
      return false;
    }
    return getCurrentTimestamp.isAfter(hideAt);
  }
  return false;
}

/// Checks if a cancelled game should be auto-hidden based on expiration.
///
/// - Scheduled games: hidden after the scheduled date passes
/// - Flexible games: hidden after the cancellation date passes
bool isCancelledGameExpired(Game game) {
  final now = getCurrentTimestamp;

  // Scheduled games: hide after scheduled date passes
  if (game.scheduleType == 'scheduled' && game.date != null) {
    final endOfDay = DateTime(
      game.date!.year,
      game.date!.month,
      game.date!.day,
      23,
      59,
      59,
    );
    return now.isAfter(endOfDay);
  }

  // Flexible games: hide after cancellation date passes
  if (game.scheduleType == 'flexible' && game.cancelledAt != null) {
    final cancelDate = game.cancelledAt!;
    final endOfCancelDay = DateTime(
      cancelDate.year,
      cancelDate.month,
      cancelDate.day,
      23,
      59,
      59,
    );
    return now.isAfter(endOfCancelDay);
  }

  return false;
}
