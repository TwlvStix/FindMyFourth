import 'dart:async';
import 'package:flutter/foundation.dart';

import '/services/profile_service.dart';
import '/backend/backend.dart';
import '/core/request_manager.dart';
import '/core/utils/app_log.dart';

/// ProfileProvider manages user profile state and provides cached access to profile data
///
/// Wraps ProfileService with stateful provider pattern following UserProvider/ChatProvider:
/// - Caching layer with 5-minute TTL
/// - StreamRequestManager for reactive streams
/// - Cache invalidation after mutations
/// - Debounced notifyListeners for performance
///
/// Usage:
/// - Access via `Provider.of<ProfileProvider>(context)`
/// - Or use `Consumer<ProfileProvider>` for reactive updates
class ProfileProvider extends ChangeNotifier {
  ProfileProvider({ProfileService? service})
      : _service = service ?? ProfileService();

  final ProfileService _service;

  // ========================================
  // STATE FIELDS
  // ========================================

  // Profile cache (by user ID)
  final Map<String, UsersRecord> _profileCache = {};

  // Stats cache (by user ID)
  final Map<String, Map<String, dynamic>> _statsCache = {};

  // Cache timestamps for TTL tracking
  final Map<String, DateTime> _profileCacheTimestamps = {};
  final Map<String, DateTime> _statsCacheTimestamps = {};

  // StreamRequestManagers for profile streams
  final Map<String, StreamRequestManager<UsersRecord?>>
      _profileStreamManagers = {};
  final Map<String, StreamRequestManager<List<UsersRecord>>>
      _searchStreamManagers = {};

  // Cache TTL duration (5 minutes - matches UserProvider)
  final Duration _cacheTTL = const Duration(minutes: 5);

  // Debounce timer for notifyListeners
  Timer? _notifyTimer;

  // Track disposal state for safe async operations
  bool _disposed = false;

  // ========================================
  // CACHE GETTERS
  // ========================================

  /// Get cached profile by user ID
  UsersRecord? getCachedProfile(String userId) => _profileCache[userId];

  /// Get cached stats by user ID
  Map<String, dynamic>? getCachedStats(String userId) => _statsCache[userId];

  /// Check if profile cache is valid (within TTL)
  bool isProfileCacheValid(String userId) {
    final timestamp = _profileCacheTimestamps[userId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheTTL;
  }

  /// Check if stats cache is valid (within TTL)
  bool isStatsCacheValid(String userId) {
    final timestamp = _statsCacheTimestamps[userId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheTTL;
  }

  // ========================================
  // PROFILE QUERIES (CACHED)
  // ========================================

  /// Get a user profile by ID with caching
  ///
  /// Returns cached value if valid, otherwise fetches from Firestore
  Future<UsersRecord?> getProfile(String userId) async {
    // Return cached value if valid
    if (isProfileCacheValid(userId)) {
      return getCachedProfile(userId);
    }

    try {
      final profile = await _service.getUserProfile(userId);
      if (profile != null) {
        _profileCache[userId] = profile;
        _profileCacheTimestamps[userId] = DateTime.now();
        _scheduleNotify();
      }
      return profile;
    } catch (e) {
      AppLog.d('❌ ProfileProvider.getProfile error: $e');
      rethrow;
    }
  }

  /// Watch a user profile by ID for reactive updates
  ///
  /// Caches profile data as it streams through
  Stream<UsersRecord?> watchProfile(String userId) {
    final queryKey = 'watch_profile_$userId';

    // Get or create StreamRequestManager for this query
    if (!_profileStreamManagers.containsKey(queryKey)) {
      _profileStreamManagers[queryKey] =
          StreamRequestManager<UsersRecord?>(5);
    }

    return _profileStreamManagers[queryKey]!.performRequest(
      uniqueQueryKey: queryKey,
      requestFn: () => _service.watchUserProfile(userId).map((profile) {
        if (profile != null) {
          // Cache the profile when it comes through the stream
          _profileCache[userId] = profile;
          _profileCacheTimestamps[userId] = DateTime.now();
          _scheduleNotify();
        }
        return profile;
      }),
    );
  }

  /// Get user statistics with caching
  ///
  /// Returns cached stats if valid, otherwise fetches from Firestore
  Future<Map<String, dynamic>> getStats(String userId) async {
    // Return cached value if valid
    if (isStatsCacheValid(userId)) {
      return getCachedStats(userId) ?? {};
    }

    try {
      final stats = await _service.getUserStats(userId);
      _statsCache[userId] = stats;
      _statsCacheTimestamps[userId] = DateTime.now();
      _scheduleNotify();
      return stats;
    } catch (e) {
      AppLog.d('❌ ProfileProvider.getStats error: $e');
      rethrow;
    }
  }

  /// Search users by name (cached with StreamRequestManager)
  Stream<List<UsersRecord>> searchUsersStream(
    String searchQuery, {
    bool overrideCache = false,
  }) {
    final queryKey = 'search_$searchQuery';

    // Get or create StreamRequestManager for this query
    if (!_searchStreamManagers.containsKey(queryKey)) {
      _searchStreamManagers[queryKey] =
          StreamRequestManager<List<UsersRecord>>(5);
    }

    return _searchStreamManagers[queryKey]!.performRequest(
      uniqueQueryKey: queryKey,
      overrideCache: overrideCache,
      requestFn: () => _service.searchUsersByName(searchQuery),
    );
  }

  /// Batch get multiple user profiles with caching
  ///
  /// Returns `Map<String, UsersRecord>` where key is userId
  /// Uses cache when possible, fetches missing profiles
  Future<Map<String, UsersRecord>> batchGetProfiles(
      List<String> userIds) async {
    final result = <String, UsersRecord>{};
    final missingIds = <String>[];

    // First, check cache for valid entries
    for (final userId in userIds) {
      if (isProfileCacheValid(userId)) {
        final cached = getCachedProfile(userId);
        if (cached != null) {
          result[userId] = cached;
        } else {
          missingIds.add(userId);
        }
      } else {
        missingIds.add(userId);
      }
    }

    // Fetch missing profiles in batch
    if (missingIds.isNotEmpty) {
      try {
        final fetched = await _service.batchGetUserProfiles(missingIds);
        // Cache fetched profiles
        fetched.forEach((userId, profile) {
          _profileCache[userId] = profile;
          _profileCacheTimestamps[userId] = DateTime.now();
          result[userId] = profile;
        });
        _scheduleNotify();
      } catch (e) {
        AppLog.d('❌ ProfileProvider.batchGetProfiles error: $e');
        rethrow;
      }
    }

    return result;
  }

  /// Warm profile cache for a set of user IDs (fire-and-forget batch prefetch)
  ///
  /// This is the primary method for eliminating N+1 queries in list views.
  /// Call this once at screen/widget init with all UIDs that will be displayed,
  /// then use getCachedProfile() synchronously in row widgets.
  ///
  /// Example usage in Games List:
  /// ```dart
  /// final ownerUids = games.map((g) => g.userRef?.id).whereType<String>().toSet();
  /// profileProvider.warmProfiles(ownerUids);
  /// ```
  ///
  /// Features:
  /// - Deduplicates requests (only fetches UIDs not in cache)
  /// - Batches Firestore reads in chunks of 10
  /// - Fire-and-forget: does not block UI, returns immediately
  /// - Debug logging shows batch count (only in debug mode)
  Future<void> warmProfiles(Set<String> userIds) async {
    if (userIds.isEmpty) return;

    // Filter out profiles that are already cached and valid
    final missingIds = userIds.where((uid) => !isProfileCacheValid(uid)).toList();

    if (missingIds.isEmpty) {
      // All profiles already cached
      assert(() {
        AppLog.d('🔥 ProfileProvider.warmProfiles: All ${userIds.length} profiles already cached');
        return true;
      }());
      return;
    }

    // Debug log batch operation (proof of no N+1)
    assert(() {
      final batchCount = (missingIds.length / 10).ceil();
      AppLog.d('🔥 ProfileProvider.warmProfiles: Warming ${missingIds.length} profiles in $batchCount batch(es)');
      return true;
    }());

    try {
      final fetched = await _service.batchGetUserProfiles(missingIds);

      // Cache all fetched profiles
      fetched.forEach((userId, profile) {
        _profileCache[userId] = profile;
        _profileCacheTimestamps[userId] = DateTime.now();
      });

      _scheduleNotify();

      assert(() {
        AppLog.d('✅ ProfileProvider.warmProfiles: Cached ${fetched.length} profiles');
        return true;
      }());
    } catch (e) {
      AppLog.d('❌ ProfileProvider.warmProfiles error: $e');
      // Don't rethrow - warming is a best-effort operation that shouldn't break the UI
    }
  }

  // ========================================
  // PROFILE MUTATIONS (WITH CACHE INVALIDATION)
  // ========================================

  /// Update user profile
  ///
  /// Invalidates profile cache and refreshes data
  Future<void> updateProfile(
      String userId, Map<String, dynamic> updates) async {
    try {
      await _service.updateProfile(userId, updates);
      // Invalidate profile cache to force refresh
      invalidateProfileCache(userId);
      // Refresh the profile data
      await getProfile(userId);
    } catch (e) {
      AppLog.d('❌ ProfileProvider.updateProfile error: $e');
      rethrow;
    }
  }

  /// Update vibe profile
  ///
  /// Invalidates profile cache and refreshes data
  Future<void> updateVibeProfile(
      String userId, Map<String, dynamic> vibeData) async {
    try {
      await _service.updateVibeProfile(userId, vibeData);
      // Invalidate profile cache to force refresh
      invalidateProfileCache(userId);
      // Refresh the profile data
      await getProfile(userId);
    } catch (e) {
      AppLog.d('❌ ProfileProvider.updateVibeProfile error: $e');
      rethrow;
    }
  }

  // ========================================
  // CACHE INVALIDATION METHODS
  // ========================================

  /// Invalidate cache for a specific profile
  void invalidateProfileCache(String userId) {
    _profileCache.remove(userId);
    _profileCacheTimestamps.remove(userId);
    _scheduleNotify();
  }

  /// Invalidate stats cache for a specific user
  void invalidateStatsCache(String userId) {
    _statsCache.remove(userId);
    _statsCacheTimestamps.remove(userId);
    _scheduleNotify();
  }

  /// Invalidate search cache
  void invalidateSearchCache() {
    for (final manager in _searchStreamManagers.values) {
      manager.clear();
    }
    _searchStreamManagers.clear();
    _scheduleNotify();
  }

  /// Invalidate all profile caches
  void invalidateAllProfileCache() {
    _profileCache.clear();
    _profileCacheTimestamps.clear();
    _statsCache.clear();
    _statsCacheTimestamps.clear();
    for (final manager in _profileStreamManagers.values) {
      manager.clear();
    }
    _profileStreamManagers.clear();
    for (final manager in _searchStreamManagers.values) {
      manager.clear();
    }
    _searchStreamManagers.clear();
    _scheduleNotify();
  }

  /// Refresh a specific profile (invalidate and refetch)
  Future<void> refreshProfile(String userId) async {
    invalidateProfileCache(userId);
    await getProfile(userId);
  }

  /// Refresh stats for a specific user (invalidate and refetch)
  Future<void> refreshStats(String userId) async {
    invalidateStatsCache(userId);
    await getStats(userId);
  }

  // ========================================
  // INTERNAL HELPERS
  // ========================================

  /// Debounced notifyListeners to avoid excessive rebuilds
  ///
  /// Pattern from ChatProvider - prevents multiple rapid updates from causing UI jank
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
    for (final manager in _profileStreamManagers.values) {
      manager.clear();
    }
    _profileStreamManagers.clear();
    for (final manager in _searchStreamManagers.values) {
      manager.clear();
    }
    _searchStreamManagers.clear();

    // Clear all caches
    _profileCache.clear();
    _profileCacheTimestamps.clear();
    _statsCache.clear();
    _statsCacheTimestamps.clear();

    super.dispose();
  }
}
