import 'dart:async';
import 'package:flutter/foundation.dart';

import '/core/request_manager.dart';
import '/core/utils/app_log.dart';
import '/models/challenge.dart';
import '/models/challenge_progress.dart';
import '/services/challenge_service.dart';

/// ChallengeProvider manages challenge progress state with caching.
///
/// Wraps ChallengeService with stateful provider pattern:
/// - Caching layer with 5-minute TTL
/// - StreamRequestManager for reactive streams
/// - Computed getters for UI consumption
/// - Debounced notifyListeners for performance
///
/// Usage:
/// - Access via `context.challengeProvider` (read) or `context.watchChallengeProvider` (watch)
class ChallengeProvider extends ChangeNotifier {
  ChallengeProvider({ChallengeService? service})
      : _service = service ?? ChallengeService();

  final ChallengeService _service;

  // ========================================
  // STATE FIELDS
  // ========================================

  // Progress cache (by user ID or '_current' for current user)
  final Map<String, Map<String, ChallengeProgress>> _progressCache = {};

  // Cache timestamps for TTL tracking
  final Map<String, DateTime> _cacheTimestamps = {};

  // StreamRequestManagers for progress streams
  final Map<String, StreamRequestManager<Map<String, ChallengeProgress>?>>
      _streamManagers = {};

  // Cache TTL duration (5 minutes)
  final Duration _cacheTTL = const Duration(minutes: 5);

  // Debounce timer for notifyListeners
  Timer? _notifyTimer;

  // Track disposal state for safe async operations
  bool _disposed = false;

  // ========================================
  // COMPUTED GETTERS
  // ========================================

  /// Current user's cached progress map, or empty.
  Map<String, ChallengeProgress> get currentProgress =>
      _progressCache['_current'] ?? {};

  /// Number of completed challenges.
  int get completedCount =>
      currentProgress.values.where((p) => p.isCompleted).length;

  /// Total number of challenges defined.
  int get totalCount => Challenge.all.length;

  /// Number of visible (non-hidden) challenges.
  int get visibleCount => Challenge.visible.length;

  /// Whether the user has any progress at all.
  bool get hasAnyProgress =>
      currentProgress.values.any((p) => p.current > 0);

  /// Get progress entries for a specific category.
  List<ChallengeProgress> progressForCategory(ChallengeCategory category) {
    final challengeIds = Challenge.all
        .where((c) => c.category == category)
        .map((c) => c.id)
        .toSet();
    return currentProgress.entries
        .where((e) => challengeIds.contains(e.key))
        .map((e) => e.value)
        .toList();
  }

  /// Get the closest-to-completion challenge in a category (not yet completed).
  ChallengeProgress? closestToCompletion(ChallengeCategory category) {
    final entries = progressForCategory(category)
        .where((p) => !p.isCompleted && p.current > 0)
        .toList();
    if (entries.isEmpty) return null;
    entries.sort((a, b) => b.progressPercent.compareTo(a.progressPercent));
    return entries.first;
  }

  // ========================================
  // CACHE GETTERS
  // ========================================

  /// Check if progress cache is valid (within TTL).
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheTTL;
  }

  // ========================================
  // CHALLENGE QUERIES (CACHED)
  // ========================================

  /// Get challenge progress for the current authenticated user.
  ///
  /// Returns cached value if valid, otherwise fetches from Firestore.
  Future<Map<String, ChallengeProgress>?> getMyProgress() async {
    if (_isCacheValid('_current')) {
      return _progressCache['_current'];
    }

    try {
      final progress = await _service.getMyProgress();
      if (progress != null) {
        _progressCache['_current'] = progress;
        _cacheTimestamps['_current'] = DateTime.now();
        _scheduleNotify();
      }
      return progress;
    } catch (e) {
      AppLog.d('❌ ChallengeProvider.getMyProgress error: $e');
      rethrow;
    }
  }

  /// Watch challenge progress for the current authenticated user.
  ///
  /// Caches progress data as it streams through.
  Stream<Map<String, ChallengeProgress>?> watchMyProgress() {
    const queryKey = 'watch_my_progress';

    if (!_streamManagers.containsKey(queryKey)) {
      _streamManagers[queryKey] =
          StreamRequestManager<Map<String, ChallengeProgress>?>(5);
    }

    return _streamManagers[queryKey]!.performRequest(
      uniqueQueryKey: queryKey,
      requestFn: () => _service.watchMyProgress().map((progress) {
        if (progress != null) {
          _progressCache['_current'] = progress;
          _cacheTimestamps['_current'] = DateTime.now();
          // Don't call _scheduleNotify() here - stream delivers data directly
        }
        return progress;
      }),
    );
  }

  // ========================================
  // CACHE INVALIDATION METHODS
  // ========================================

  /// Invalidate cache for the current user's challenge progress.
  void invalidateMyProgressCache() {
    _progressCache.remove('_current');
    _cacheTimestamps.remove('_current');
    _scheduleNotify();
  }

  /// Invalidate all challenge caches.
  void invalidateAllCache() {
    _progressCache.clear();
    _cacheTimestamps.clear();
    for (final manager in _streamManagers.values) {
      manager.clear();
    }
    _streamManagers.clear();
    _scheduleNotify();
  }

  /// Refresh current user's challenge progress (invalidate and refetch).
  Future<void> refreshMyProgress() async {
    invalidateMyProgressCache();
    await getMyProgress();
  }

  // ========================================
  // INTERNAL HELPERS
  // ========================================

  /// Debounced notifyListeners to avoid excessive rebuilds.
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

    for (final manager in _streamManagers.values) {
      manager.clear();
    }
    _streamManagers.clear();

    _progressCache.clear();
    _cacheTimestamps.clear();

    super.dispose();
  }
}
