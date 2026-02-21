import 'dart:async';

import 'package:flutter/foundation.dart';

import '/backend/api_requests/trust_repository.dart';
import '/backend/schema/player_standing.dart';
import '/backend/schema/trust_profile.dart';
import '/core/request_manager.dart';

/// TrustProvider manages trust system state with 5-minute TTL caching.
///
/// Follows the same pattern as UserProvider / GameProvider:
/// - FutureRequestManager for async requests
/// - 5-minute TTL with explicit timestamp tracking
/// - Debounced notifyListeners (100ms)
/// - Safe disposal guard
///
/// Usage:
///   Provider.of<TrustProvider>(context)
///   Consumer<TrustProvider>
class TrustProvider extends ChangeNotifier {
  TrustProvider() : _repo = const TrustRepository();

  final TrustRepository _repo;

  // ─────────────────────────────────────────────────────────────────────────
  // Public trust profile cache (per userId)
  // ─────────────────────────────────────────────────────────────────────────

  final Map<String, TrustProfile> _profileCache = {};
  final Map<String, DateTime> _profileCacheTimestamps = {};

  final FutureRequestManager<TrustProfile?> _profileManager =
      FutureRequestManager(20);

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
      debugPrint('TrustProvider.fetchTrustProfile error for $userId: $e');
      return null;
    }
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
      debugPrint('TrustProvider.fetchPlayerStanding error: $e');
      return null;
    } finally {
      _standingLoading = false;
      _scheduleNotify();
    }
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

  @override
  void dispose() {
    _disposed = true;
    _notifyTimer?.cancel();
    super.dispose();
  }
}
