import 'dart:async';

import 'package:flutter/foundation.dart';

import '/services/trust_repository.dart';
import '/backend/schema/player_standing.dart';
import '/backend/schema/trust_profile.dart';
import '/core/request_manager.dart';
import '/core/utils/app_log.dart';

/// TrustProvider manages trust system state with 5-minute TTL caching.
///
/// Follows the same pattern as UserProvider / GameProvider:
/// - FutureRequestManager for async requests
/// - 5-minute TTL with explicit timestamp tracking
/// - Debounced notifyListeners (100ms)
/// - Safe disposal guard
///
/// Usage:
///   `Provider.of<TrustProvider>(context)`
///   `Consumer<TrustProvider>`
class TrustProvider extends ChangeNotifier {
  TrustProvider() : _repo = const TrustRepository();

  /// Test constructor for dependency injection.
  @visibleForTesting
  TrustProvider.withRepository(this._repo);

  final TrustRepository _repo;

  // ─────────────────────────────────────────────────────────────────────────
  // Public trust profile cache (per userId)
  // ─────────────────────────────────────────────────────────────────────────

  final Map<String, TrustProfile> _profileCache = {};
  final Map<String, DateTime> _profileCacheTimestamps = {};

  final FutureRequestManager<TrustProfile?> _profileManager =
      FutureRequestManager(20);
  final Map<String, Completer<TrustProfile?>> _inFlightBatchFetches = {};

  // ─────────────────────────────────────────────────────────────────────────
  // Private player standing (current user only)
  // ─────────────────────────────────────────────────────────────────────────

  PlayerStanding? _myStanding;
  DateTime? _myStandingTimestamp;
  bool _standingLoading = false;

  /// The current user's cached standing, or null if not yet loaded.
  PlayerStanding? get myStanding => _myStanding;
  bool get standingLoading => _standingLoading;

  // ─────────────────────────────────────────────────────────────────────────
  // TTL + debounce
  // ─────────────────────────────────────────────────────────────────────────

  final Duration _cacheTTL = const Duration(minutes: 5);
  Timer? _notifyTimer;
  bool _disposed = false;

  bool _isProfileCacheValid(String userId) {
    final ts = _profileCacheTimestamps[userId];
    if (ts == null) return false;
    return DateTime.now().difference(ts) < _cacheTTL;
  }

  bool _isStandingCacheValid() {
    if (_myStandingTimestamp == null) return false;
    return DateTime.now().difference(_myStandingTimestamp!) < _cacheTTL;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Return cached trust profile for [userId], or fetch if stale / missing.
  TrustProfile? getCachedProfile(String userId) => _profileCache[userId];

  Future<TrustProfile?> fetchTrustProfile(String userId) async {
    if (_isProfileCacheValid(userId)) return _profileCache[userId];

    try {
      final profile = await _profileManager.performRequest(
        uniqueQueryKey: 'trust_profile_$userId',
        overrideCache: true,
        requestFn: () => _repo.getTrustProfile(userId),
      );
      if (profile != null) {
        _profileCache[userId] = profile;
        _profileCacheTimestamps[userId] = DateTime.now();
        _scheduleNotify();
      }
      return profile;
    } catch (e) {
      AppLog.d('❌ TrustProvider.fetchTrustProfile error for $userId: $e');
      return null;
    }
  }

  /// Batch fetch trust profiles with caching.
  ///
  /// Checks cache first, only fetches missing profiles from repository.
  /// Returns `Map<userId, TrustProfile?>` with cached values where valid.
  Future<Map<String, TrustProfile?>> batchGetTrustProfiles(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};

    final uniqueIds = userIds.toSet().toList();
    final result = <String, TrustProfile?>{};
    final missingIds = <String>[];

    // Check cache first
    for (final userId in uniqueIds) {
      if (_isProfileCacheValid(userId)) {
        result[userId] = _profileCache[userId];
      } else {
        missingIds.add(userId);
      }
    }

    if (missingIds.isEmpty) {
      return result;
    }

    final idsToStartNow = <String>[];
    for (final userId in missingIds) {
      if (!_inFlightBatchFetches.containsKey(userId)) {
        idsToStartNow.add(userId);
      }
    }

    if (idsToStartNow.isNotEmpty) {
      AppLog.d('🔥 TrustProvider.batchGetTrustProfiles: '
          'Fetching ${idsToStartNow.length} profiles in batch '
          '(${result.length} cached, ${missingIds.length - idsToStartNow.length} in-flight)');
      _startBatchFetch(idsToStartNow);
    }

    final inFlightFutures = <String, Future<TrustProfile?>>{};
    for (final userId in missingIds) {
      final inFlight = _inFlightBatchFetches[userId];
      if (inFlight != null) {
        inFlightFutures[userId] = inFlight.future;
      }
    }

    for (final userId in missingIds) {
      final inFlightFuture = inFlightFutures[userId];
      if (inFlightFuture != null) {
        result[userId] = await inFlightFuture;
      } else {
        result[userId] =
            _isProfileCacheValid(userId) ? _profileCache[userId] : null;
      }
    }

    return result;
  }

  /// Fetch (or return cached) current user's player standing.
  Future<PlayerStanding?> fetchPlayerStanding() async {
    if (_isStandingCacheValid() && _myStanding != null) return _myStanding;
    if (_standingLoading) return _myStanding;

    _standingLoading = true;
    _scheduleNotify();

    try {
      final standing = await _repo.getPlayerStanding();
      _myStanding = standing;
      _myStandingTimestamp = DateTime.now();
      return standing;
    } catch (e) {
      AppLog.d('❌ TrustProvider.fetchPlayerStanding error: $e');
      return null;
    } finally {
      _standingLoading = false;
      _scheduleNotify();
    }
  }

  /// Convenience method: returns the current user's active strike count.
  ///
  /// Fetches standing if not cached, returns 0 on failure.
  Future<int> getActiveStrikeCount() async {
    final standing = await fetchPlayerStanding();
    return standing?.totalActiveStrikes ?? 0;
  }

  /// Invalidate all caches (call after a round is verified or a strike is issued).
  void refreshAfterRound() {
    clearAll();
  }

  /// Invalidate a specific user's profile cache.
  void invalidateProfile(String userId) {
    _profileCache.remove(userId);
    _profileCacheTimestamps.remove(userId);
    _profileManager.clearRequest('trust_profile_$userId');
  }

  /// Invalidate the current user's standing cache.
  void invalidateStanding() {
    _myStanding = null;
    _myStandingTimestamp = null;
  }

  void clearAll() {
    _profileCache.clear();
    _profileCacheTimestamps.clear();
    _profileManager.clear();
    _myStanding = null;
    _myStandingTimestamp = null;
    _scheduleNotify();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal
  // ─────────────────────────────────────────────────────────────────────────

  void _scheduleNotify() {
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 100), () {
      if (!_disposed) notifyListeners();
    });
  }

  void _startBatchFetch(List<String> userIds) {
    if (userIds.isEmpty) return;

    final completers = <String, Completer<TrustProfile?>>{};
    for (final userId in userIds) {
      final completer = Completer<TrustProfile?>();
      _inFlightBatchFetches[userId] = completer;
      completers[userId] = completer;
    }

    unawaited(() async {
      var cacheUpdated = false;
      try {
        final fetched = await _repo.batchGetTrustProfiles(userIds);
        for (final userId in userIds) {
          final profile = fetched[userId];
          if (profile != null) {
            _profileCache[userId] = profile;
            _profileCacheTimestamps[userId] = DateTime.now();
            cacheUpdated = true;
          }
          final completer = completers[userId];
          if (completer != null && !completer.isCompleted) {
            completer.complete(profile);
          }
        }
      } catch (e) {
        AppLog.d('❌ TrustProvider.batchGetTrustProfiles error: $e');
        for (final completer in completers.values) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        }
      } finally {
        for (final userId in userIds) {
          _inFlightBatchFetches.remove(userId);
        }
        if (cacheUpdated) {
          _scheduleNotify();
        }
      }
    }());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Test helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Expire cache for a specific user (for testing TTL behavior).
  @visibleForTesting
  void expireCacheForTest(String userId) {
    _profileCacheTimestamps[userId] =
        DateTime.now().subtract(const Duration(minutes: 6));
  }

  @override
  void dispose() {
    _disposed = true;
    _notifyTimer?.cancel();
    super.dispose();
  }
}
