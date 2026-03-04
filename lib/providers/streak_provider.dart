import 'dart:async';
import 'package:flutter/foundation.dart';

import '/core/request_manager.dart';
import '/core/utils/app_log.dart';
import '/models/streak_profile.dart';
import '/services/streak_service.dart';

/// StreakProvider manages streak profile state with caching.
///
/// Wraps StreakService with stateful provider pattern:
/// - Caching layer with 5-minute TTL
/// - StreamRequestManager for reactive streams
/// - Cache invalidation after mutations
/// - Debounced notifyListeners for performance
///
/// Usage:
/// - Access via `context.streakProvider` (read) or `context.watchStreakProvider` (watch)
class StreakProvider extends ChangeNotifier {
  StreakProvider({StreakService? service})
      : _service = service ?? StreakService();

  final StreakService _service;

  // ========================================
  // STATE FIELDS
  // ========================================

  // Streak profile cache (by user ID)
  final Map<String, StreakProfile> _streakCache = {};

  // Cache timestamps for TTL tracking
  final Map<String, DateTime> _streakCacheTimestamps = {};

  // StreamRequestManagers for streak streams
  final Map<String, StreamRequestManager<StreakProfile?>> _streakStreamManagers =
      {};

  // Cache TTL duration (5 minutes)
  final Duration _cacheTTL = const Duration(minutes: 5);

  // Debounce timer for notifyListeners
  Timer? _notifyTimer;

  // Track disposal state for safe async operations
  bool _disposed = false;

  // ========================================
  // CACHE GETTERS
  // ========================================

  /// Get cached streak profile by user ID.
  StreakProfile? getCachedStreak(String userId) => _streakCache[userId];

  /// Check if streak cache is valid (within TTL).
  bool isStreakCacheValid(String userId) {
    final timestamp = _streakCacheTimestamps[userId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheTTL;
  }

  // ========================================
  // STREAK QUERIES (CACHED)
  // ========================================

  /// Get streak profile for the current authenticated user.
  ///
  /// Returns cached value if valid, otherwise fetches from Firestore.
  Future<StreakProfile?> getMyStreak() async {
    try {
      final streak = await _service.getMyStreak();
      if (streak != null) {
        // Cache using a special key for current user
        _streakCache['_current'] = streak;
        _streakCacheTimestamps['_current'] = DateTime.now();
        _scheduleNotify();
      }
      return streak;
    } catch (e) {
      AppLog.d('❌ StreakProvider.getMyStreak error: $e');
      rethrow;
    }
  }

  /// Get streak profile for a specific user by ID with caching.
  ///
  /// Returns cached value if valid, otherwise fetches from Firestore.
  Future<StreakProfile?> getStreak(String userId) async {
    // Return cached value if valid
    if (isStreakCacheValid(userId)) {
      return getCachedStreak(userId);
    }

    try {
      final streak = await _service.getStreak(userId);
      if (streak != null) {
        _streakCache[userId] = streak;
        _streakCacheTimestamps[userId] = DateTime.now();
        _scheduleNotify();
      }
      return streak;
    } catch (e) {
      AppLog.d('❌ StreakProvider.getStreak error: $e');
      rethrow;
    }
  }

  /// Watch streak profile for the current authenticated user.
  ///
  /// Caches streak data as it streams through.
  Stream<StreakProfile?> watchMyStreak() {
    const queryKey = 'watch_my_streak';

    // Get or create StreamRequestManager for this query
    if (!_streakStreamManagers.containsKey(queryKey)) {
      _streakStreamManagers[queryKey] =
          StreamRequestManager<StreakProfile?>(5);
    }

    return _streakStreamManagers[queryKey]!.performRequest(
      uniqueQueryKey: queryKey,
      requestFn: () => _service.watchMyStreak().map((streak) {
        if (streak != null) {
          _streakCache['_current'] = streak;
          _streakCacheTimestamps['_current'] = DateTime.now();
          // Don't call _scheduleNotify() here - stream delivers data directly
        }
        return streak;
      }),
    );
  }

  /// Watch streak profile for a specific user by ID.
  ///
  /// Caches streak data as it streams through.
  Stream<StreakProfile?> watchStreak(String userId) {
    final queryKey = 'watch_streak_$userId';

    // Get or create StreamRequestManager for this query
    if (!_streakStreamManagers.containsKey(queryKey)) {
      _streakStreamManagers[queryKey] =
          StreamRequestManager<StreakProfile?>(5);
    }

    return _streakStreamManagers[queryKey]!.performRequest(
      uniqueQueryKey: queryKey,
      requestFn: () => _service.watchStreak(userId).map((streak) {
        if (streak != null) {
          _streakCache[userId] = streak;
          _streakCacheTimestamps[userId] = DateTime.now();
          // Don't call _scheduleNotify() here - stream delivers data directly
        }
        return streak;
      }),
    );
  }

  // ========================================
  // MUTATIONS
  // ========================================

  /// Deploy a streak freeze for a specific week.
  ///
  /// The weekKey should be the Monday of the week in YYYY-MM-DD format.
  /// Returns the result map from the Cloud Function.
  ///
  /// Invalidates cache after successful freeze deployment.
  Future<Map<String, dynamic>> deployFreeze(String weekKey) async {
    try {
      final result = await _service.deployStreakFreeze(weekKey);

      // Invalidate cache on success to force refresh
      if (result['status'] == 'ok') {
        invalidateMyStreakCache();
        await getMyStreak();
      }

      return result;
    } catch (e) {
      AppLog.d('❌ StreakProvider.deployFreeze error: $e');
      rethrow;
    }
  }

  // ========================================
  // CACHE INVALIDATION METHODS
  // ========================================

  /// Invalidate cache for the current user's streak.
  void invalidateMyStreakCache() {
    _streakCache.remove('_current');
    _streakCacheTimestamps.remove('_current');
    _scheduleNotify();
  }

  /// Invalidate cache for a specific user's streak.
  void invalidateStreakCache(String userId) {
    _streakCache.remove(userId);
    _streakCacheTimestamps.remove(userId);
    _scheduleNotify();
  }

  /// Invalidate all streak caches.
  void invalidateAllCache() {
    _streakCache.clear();
    _streakCacheTimestamps.clear();
    for (final manager in _streakStreamManagers.values) {
      manager.clear();
    }
    _streakStreamManagers.clear();
    _scheduleNotify();
  }

  /// Refresh current user's streak (invalidate and refetch).
  Future<void> refreshMyStreak() async {
    invalidateMyStreakCache();
    await getMyStreak();
  }

  /// Refresh a specific user's streak (invalidate and refetch).
  Future<void> refreshStreak(String userId) async {
    invalidateStreakCache(userId);
    await getStreak(userId);
  }

  // ========================================
  // INTERNAL HELPERS
  // ========================================

  /// Debounced notifyListeners to avoid excessive rebuilds.
  ///
  /// Pattern from existing providers - prevents multiple rapid updates
  /// from causing UI jank.
  void _scheduleNotify() {
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 50), () {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  // ========================================
  // DISPOSE CLEANUP
  // ========================================

  @override
  void dispose() {
    _disposed = true;
    _notifyTimer?.cancel();

    // Clear all stream request managers
    for (final manager in _streakStreamManagers.values) {
      manager.clear();
    }
    _streakStreamManagers.clear();

    // Clear all caches
    _streakCache.clear();
    _streakCacheTimestamps.clear();

    super.dispose();
  }
}
