import 'dart:async';
import 'package:flutter/foundation.dart';

import '/backend/api_requests/game_service.dart';
import '/backend/backend.dart';
import '/core/request_manager.dart';
import '/services/chat_service.dart';

/// GameProvider manages global game state and provides cached access to game data
///
/// Wraps GameService with stateful provider pattern following UserProvider/ChatProvider:
/// - Caching layer with 5-minute TTL
/// - StreamRequestManager for reactive streams
/// - Cache invalidation after mutations
/// - Debounced notifyListeners for performance
///
/// Usage:
/// - Access via Provider.of<GameProvider>(context)
/// - Or use Consumer<GameProvider> for reactive updates
class GameProvider extends ChangeNotifier {
  GameProvider();

  // ========================================
  // STATE FIELDS
  // ========================================

  // Game cache (by game ID)
  final Map<String, GamesRecord> _gameCache = {};

  // Cache timestamps for TTL tracking
  final Map<String, DateTime> _gameCacheTimestamps = {};

  // Query result cache (by query key)
  final Map<String, List<GamesRecord>> _queryResultCache = {};

  // Query cache timestamps for TTL tracking
  final Map<String, DateTime> _queryResultCacheTimestamps = {};

  // StreamRequestManagers for game streams
  final Map<String, StreamRequestManager<List<GamesRecord>>>
      _gameStreamManagers = {};

  // Cache TTL duration (5 minutes - matches UserProvider)
  final Duration _cacheTTL = const Duration(minutes: 5);

  // Debounce timer for notifyListeners
  Timer? _notifyTimer;

  // Track disposal state for safe async operations
  bool _disposed = false;

  // ========================================
  // CACHE GETTERS
  // ========================================

  /// Get cached game by ID
  GamesRecord? getCachedGame(String gameId) => _gameCache[gameId];

  /// Check if game cache is valid (within TTL)
  bool isGameCacheValid(String gameId) {
    final timestamp = _gameCacheTimestamps[gameId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheTTL;
  }

  /// Check if query result cache is valid (within TTL)
  bool isQueryCacheValid(String queryKey) {
    final timestamp = _queryResultCacheTimestamps[queryKey];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheTTL;
  }

  // ========================================
  // GAME QUERIES (CACHED)
  // ========================================

  /// Get a single game by ID with caching
  ///
  /// Returns cached value if valid, otherwise fetches from Firestore
  Future<GamesRecord?> getGame(String gameId) async {
    // Return cached value if valid
    if (isGameCacheValid(gameId)) {
      return getCachedGame(gameId);
    }

    try {
      final game = await GameService.getGameById(gameId);
      if (game != null) {
        _gameCache[gameId] = game;
        _gameCacheTimestamps[gameId] = DateTime.now();
        _scheduleNotify();
      }
      return game;
    } catch (e) {
      debugPrint('GameProvider.getGame error: $e');
      rethrow;
    }
  }

  /// Watch a single game by ID for reactive updates
  ///
  /// Caches game data as it streams through
  Stream<GamesRecord?> watchGame(String gameId) {
    try {
      return GameService.watchGameById(gameId).map((game) {
        if (game != null) {
          // Cache the game when it comes through the stream
          _gameCache[gameId] = game;
          _gameCacheTimestamps[gameId] = DateTime.now();
          _scheduleNotify();
        }
        return game;
      });
    } catch (e) {
      debugPrint('GameProvider.watchGame error: $e');
      rethrow;
    }
  }

  /// Stream available games with optional filters (cached with StreamRequestManager)
  ///
  /// Filters:
  /// - courseFilter: filter by course name
  /// - styleFilter: filter by game style
  /// - dateFilter: filter by games on or after this date
  Stream<List<GamesRecord>> availableGamesStream({
    String? courseFilter,
    String? styleFilter,
    DateTime? dateFilter,
    bool overrideCache = false,
  }) {
    // Create unique query key based on filters
    final queryKey =
        'available_${courseFilter ?? ''}_${styleFilter ?? ''}_${dateFilter?.toIso8601String() ?? ''}';

    // Get or create StreamRequestManager for this query
    if (!_gameStreamManagers.containsKey(queryKey)) {
      _gameStreamManagers[queryKey] =
          StreamRequestManager<List<GamesRecord>>(5);
    }

    return _gameStreamManagers[queryKey]!.performRequest(
      uniqueQueryKey: queryKey,
      overrideCache: overrideCache,
      requestFn: () => GameService.queryAvailableGames(
        courseFilter: courseFilter,
        styleFilter: styleFilter,
        dateFilter: dateFilter,
      ),
    ).map((games) {
      // Cache query results when they come through the stream
      _queryResultCache[queryKey] = games;
      _queryResultCacheTimestamps[queryKey] = DateTime.now();
      return games;
    });
  }

  /// Stream user's joined games (cached with StreamRequestManager)
  Stream<List<GamesRecord>> userGamesStream(
    String userId, {
    bool overrideCache = false,
  }) {
    final queryKey = 'user_games_$userId';

    // Get or create StreamRequestManager for this query
    if (!_gameStreamManagers.containsKey(queryKey)) {
      _gameStreamManagers[queryKey] =
          StreamRequestManager<List<GamesRecord>>(5);
    }

    return _gameStreamManagers[queryKey]!.performRequest(
      uniqueQueryKey: queryKey,
      overrideCache: overrideCache,
      requestFn: () => GameService.queryUserGames(userId),
    ).map((games) {
      // Cache query results when they come through the stream
      _queryResultCache[queryKey] = games;
      _queryResultCacheTimestamps[queryKey] = DateTime.now();
      return games;
    });
  }

  /// Get cached available games list if available (no fetch)
  List<GamesRecord>? getCachedAvailableGames({
    String? courseFilter,
    String? styleFilter,
    DateTime? dateFilter,
  }) {
    final queryKey =
        'available_${courseFilter ?? ''}_${styleFilter ?? ''}_${dateFilter?.toIso8601String() ?? ''}';

    // Check query result cache first
    if (isQueryCacheValid(queryKey)) {
      return _queryResultCache[queryKey];
    }

    // Fall back to BehaviorSubject cache
    return _gameStreamManagers[queryKey]?.getLastValue(queryKey);
  }

  /// Get cached user games list if available (no fetch)
  List<GamesRecord>? getCachedUserGames(String userId) {
    final queryKey = 'user_games_$userId';

    // Check query result cache first
    if (isQueryCacheValid(queryKey)) {
      return _queryResultCache[queryKey];
    }

    // Fall back to BehaviorSubject cache
    return _gameStreamManagers[queryKey]?.getLastValue(queryKey);
  }

  // ========================================
  // GAME MUTATIONS (WITH CACHE INVALIDATION)
  // ========================================

  /// Join a game
  ///
  /// Invalidates game cache and refreshes data
  Future<void> joinGame(String gameId, String userId) async {
    try {
      await GameService.joinGame(gameId, userId);
      await _ensureChatMembership(gameId, userId);
      // Invalidate game cache to force refresh
      invalidateGameCache(gameId);
      // Invalidate user games cache to refresh joined games list
      invalidateUserGamesCache(userId);
      // Refresh the game data
      await getGame(gameId);
    } catch (e) {
      debugPrint('GameProvider.joinGame error: $e');
      rethrow;
    }
  }

  /// Leave a game
  ///
  /// Invalidates game cache and refreshes data
  Future<void> leaveGame(String gameId, String userId) async {
    try {
      await GameService.leaveGame(gameId, userId);
      // Invalidate game cache to force refresh
      invalidateGameCache(gameId);
      // Invalidate user games cache to refresh joined games list
      invalidateUserGamesCache(userId);
      // Refresh the game data
      await getGame(gameId);
    } catch (e) {
      debugPrint('GameProvider.leaveGame error: $e');
      rethrow;
    }
  }

  /// Update game details
  ///
  /// Invalidates game cache and refreshes data
  Future<void> updateGame(String gameId, Map<String, dynamic> updates) async {
    try {
      await GameService.updateGameDetails(gameId, updates);
      // Invalidate game cache to force refresh
      invalidateGameCache(gameId);
      // Refresh the game data
      await getGame(gameId);
    } catch (e) {
      debugPrint('GameProvider.updateGame error: $e');
      rethrow;
    }
  }

  /// Create a new game
  ///
  /// Returns the created game's DocumentReference
  Future<GamesRecord?> createGame(Map<String, dynamic> gameData) async {
    try {
      final gameRef = await GameService.createGame(gameData);
      // Fetch and cache the newly created game
      final game = await GameService.getGameById(gameRef.id);
      if (game != null) {
        _gameCache[gameRef.id] = game;
        _gameCacheTimestamps[gameRef.id] = DateTime.now();
        _scheduleNotify();
      }
      return game;
    } catch (e) {
      debugPrint('GameProvider.createGame error: $e');
      rethrow;
    }
  }

  Future<void> _ensureChatMembership(String gameId, String userId) async {
    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final gameRef =
          FirebaseFirestore.instance.collection('games').doc(gameId);

      for (var attempt = 0; attempt < 3; attempt += 1) {
        final gameSnap = await gameRef.get();
        if (!gameSnap.exists) {
          return;
        }

        final data = gameSnap.data() ?? {};
        final joinedPlayers = data['joined_players'];
        final inGame = joinedPlayers is List &&
            joinedPlayers.any((entry) => entry == userRef || entry == userId);
        final chatRef = data['chatRef'];

        if (inGame && chatRef is DocumentReference) {
          await ChatService().addMember(chatId: chatRef.id, uid: userId);
          return;
        }

        await Future.delayed(const Duration(milliseconds: 250));
      }
    } catch (error) {
      debugPrint('GameProvider: chat membership sync failed: $error');
    }
  }

  /// Cancel a game
  ///
  /// Invalidates game cache and refreshes data
  Future<void> cancelGame(String gameId) async {
    try {
      await GameService.cancelGame(gameId);
      // Invalidate game cache to force refresh
      invalidateGameCache(gameId);
      // Refresh the game data
      await getGame(gameId);
    } catch (e) {
      debugPrint('GameProvider.cancelGame error: $e');
      rethrow;
    }
  }

  // ========================================
  // CACHE INVALIDATION METHODS
  // ========================================

  /// Invalidate cache for a specific game
  void invalidateGameCache(String gameId) {
    _gameCache.remove(gameId);
    _gameCacheTimestamps.remove(gameId);
    _scheduleNotify();
  }

  /// Invalidate user games cache (when user joins/leaves games)
  void invalidateUserGamesCache(String userId) {
    final queryKey = 'user_games_$userId';
    _gameStreamManagers[queryKey]?.clear();
    _queryResultCache.remove(queryKey);
    _queryResultCacheTimestamps.remove(queryKey);
    _scheduleNotify();
  }

  /// Invalidate available games cache (when filters change)
  void invalidateAvailableGamesCache() {
    // Clear all available_* stream managers and query caches
    _gameStreamManagers.removeWhere((key, value) {
      if (key.startsWith('available_')) {
        value.clear();
        return true;
      }
      return false;
    });
    _queryResultCache.removeWhere((key, value) => key.startsWith('available_'));
    _queryResultCacheTimestamps.removeWhere((key, value) => key.startsWith('available_'));
    _scheduleNotify();
  }

  /// Invalidate all game caches
  void invalidateAllGameCache() {
    _gameCache.clear();
    _gameCacheTimestamps.clear();
    _queryResultCache.clear();
    _queryResultCacheTimestamps.clear();
    for (final manager in _gameStreamManagers.values) {
      manager.clear();
    }
    _gameStreamManagers.clear();
    _scheduleNotify();
  }

  /// Refresh a specific game (invalidate and refetch)
  Future<void> refreshGame(String gameId) async {
    invalidateGameCache(gameId);
    await getGame(gameId);
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
    for (final manager in _gameStreamManagers.values) {
      manager.clear();
    }
    _gameStreamManagers.clear();

    // Clear all caches
    _gameCache.clear();
    _gameCacheTimestamps.clear();

    super.dispose();
  }
}
