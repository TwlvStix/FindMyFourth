import 'dart:async';
import 'package:flutter/foundation.dart';

import '/core/utils/app_log.dart';
import '/models/leaderboard_entry.dart';
import '/services/leaderboard_service.dart';

/// LeaderboardProvider manages seasonal leaderboard state with caching.
///
/// Wraps LeaderboardService with stateful provider pattern:
/// - Caching layer with 5-minute TTL
/// - Visibility gating (>= 50 active users)
/// - Debounced notifyListeners for performance
///
/// Usage:
/// - Access via `context.leaderboardProvider` (read) or `context.watchLeaderboardProvider` (watch)
class LeaderboardProvider extends ChangeNotifier {
  LeaderboardProvider({LeaderboardService? service})
      : _service = service ?? LeaderboardService();

  final LeaderboardService _service;

  // ========================================
  // STATE FIELDS
  // ========================================

  List<LeaderboardEntry> _topPlayers = [];
  int _userRank = 0;
  bool _isVisible = false;
  bool _isLoading = false;

  // Cache timestamps for TTL tracking
  DateTime? _cacheTimestamp;

  // Cache TTL duration (5 minutes)
  final Duration _cacheTTL = const Duration(minutes: 5);

  // Debounce timer for notifyListeners
  Timer? _notifyTimer;

  // Track disposal state for safe async operations
  bool _disposed = false;

  // ========================================
  // GETTERS
  // ========================================

  List<LeaderboardEntry> get topPlayers => _topPlayers;
  int get userRank => _userRank;
  bool get isVisible => _isVisible;
  bool get isLoading => _isLoading;

  /// Whether the current user appears in the top players list.
  bool get isCurrentUserInTop =>
      _topPlayers.any((entry) => entry.isCurrentUser);

  // ========================================
  // CACHE HELPERS
  // ========================================

  bool get _isCacheValid {
    if (_cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheTTL;
  }

  // ========================================
  // LEADERBOARD QUERIES
  // ========================================

  /// Load leaderboard data (visibility check, top players, user rank).
  ///
  /// Respects cache TTL. Set [force] to true to bypass cache.
  Future<void> loadLeaderboard({bool force = false}) async {
    if (!force && _isCacheValid) return;

    _isLoading = true;
    _scheduleNotify();

    try {
      // Check visibility threshold first
      final visible = await _service.isLeaderboardVisible();
      _isVisible = visible;

      if (!visible) {
        _topPlayers = [];
        _userRank = 0;
        _cacheTimestamp = DateTime.now();
        _isLoading = false;
        _scheduleNotify();
        return;
      }

      // Fetch top players and user rank in parallel
      final results = await Future.wait([
        _service.getTopPlayers(),
        _service.getUserRank(),
      ]);

      _topPlayers = results[0] as List<LeaderboardEntry>;
      _userRank = results[1] as int;
      _cacheTimestamp = DateTime.now();
      _isLoading = false;
      _scheduleNotify();

      AppLog.d(
        '✅ LeaderboardProvider.loadLeaderboard: '
        '${_topPlayers.length} players, rank #$_userRank',
      );
    } catch (e) {
      _isLoading = false;
      _scheduleNotify();
      AppLog.d('❌ LeaderboardProvider.loadLeaderboard error: $e');
      rethrow;
    }
  }

  /// Refresh leaderboard data (invalidates cache and reloads).
  Future<void> refresh() async {
    _cacheTimestamp = null;
    await loadLeaderboard(force: true);
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
    _topPlayers = [];
    super.dispose();
  }
}
