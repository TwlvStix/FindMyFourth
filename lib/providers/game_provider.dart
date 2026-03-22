import 'dart:async';
import 'package:flutter/foundation.dart';

import '/services/game_service.dart';
import '/services/trust_repository.dart';
import '/backend/backend.dart';
import '/core/request_manager.dart';
import '/core/utils/app_log.dart';
import '/models/join_game_result.dart';
import '/services/vibe_floor_service.dart';

/// GameProvider manages global game state and provides cached access to game data
///
/// Wraps GameService with stateful provider pattern following UserProvider/ChatProvider:
/// - Caching layer with 5-minute TTL
/// - StreamRequestManager for reactive streams
/// - Cache invalidation after mutations
/// - Debounced notifyListeners for performance
///
/// Usage:
/// - Access via `Provider.of<GameProvider>(context)`
/// - Or use `Consumer<GameProvider>` for reactive updates
class GameProvider extends ChangeNotifier {
  GameProvider({
    GameService? service,
    VibeFloorService? vibeFloorService,
    TrustRepository? trustRepository,
  })  : _service = service ?? GameService(),
        _vibeFloorService = vibeFloorService ?? VibeFloorService(),
        _trustRepository = trustRepository ?? const TrustRepository();

  final GameService _service;
  final VibeFloorService _vibeFloorService;
  final TrustRepository _trustRepository;

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
  // PAGINATION STATE
  // ========================================

  // Cursor for fetching subsequent pages
  DocumentSnapshot? _lastPageCursor;

  // Whether more pages are available
  bool _hasMorePages = true;

  // Whether a page load is in progress
  bool _isLoadingMore = false;

  // Games from pages 2+ (merged with stream page 1 in UI)
  List<GamesRecord> _additionalPages = [];

  /// Whether more pages of games are available to load.
  bool get hasMorePages => _hasMorePages;

  /// Whether a page load is currently in progress.
  bool get isLoadingMore => _isLoadingMore;

  /// Games fetched from pages beyond the first (stream) page.
  List<GamesRecord> get additionalPageGames => _additionalPages;

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
      final game = await _service.getGameById(gameId);
      if (game != null) {
        // Cache the game when fetched
        // (no notifyListeners - caller awaits result directly)
        _gameCache[gameId] = game;
        _gameCacheTimestamps[gameId] = DateTime.now();
      }
      return game;
    } catch (e) {
      AppLog.d('❌ GameProvider.getGame error: $e');
      rethrow;
    }
  }

  /// Watch a single game by ID for reactive updates
  ///
  /// Caches game data as it streams through
  Stream<GamesRecord?> watchGame(String gameId) {
    try {
      return _service.watchGameById(gameId).map((game) {
        if (game != null) {
          // Cache the game when it comes through the stream
          // (no notifyListeners - stream delivers data directly to subscribers)
          _gameCache[gameId] = game;
          _gameCacheTimestamps[gameId] = DateTime.now();
        }
        return game;
      });
    } catch (e) {
      AppLog.d('❌ GameProvider.watchGame error: $e');
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
    int? limit,
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
      requestFn: () => _service.queryAvailableGames(
        courseFilter: courseFilter,
        styleFilter: styleFilter,
        dateFilter: dateFilter,
        limit: limit,
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
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return Stream.value(const <GamesRecord>[]);
    }

    final queryKey = 'user_games_$normalizedUserId';

    // Get or create StreamRequestManager for this query
    if (!_gameStreamManagers.containsKey(queryKey)) {
      _gameStreamManagers[queryKey] =
          StreamRequestManager<List<GamesRecord>>(5);
    }

    return _gameStreamManagers[queryKey]!.performRequest(
      uniqueQueryKey: queryKey,
      overrideCache: overrideCache,
      requestFn: () => _service.queryUserGames(normalizedUserId),
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
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return null;
    }
    final queryKey = 'user_games_$normalizedUserId';

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

  /// Join a game with vibe floor eligibility check
  ///
  /// When [ownerId] is provided, performs a vibe floor check before joining:
  /// - Friends always auto-join
  /// - Players above the vibe floor auto-join
  /// - Players below the floor receive [JoinGameResult.requiresApproval]
  ///
  /// Returns [JoinGameEligibilityData] indicating the outcome:
  /// - [JoinGameResult.joined]: Successfully joined the game
  /// - [JoinGameResult.requiresApproval]: Player needs owner approval (includes profile data)
  /// - [JoinGameResult.alreadyRequested]: Player already has a pending request
  ///
  /// When [ownerId] is null, skips vibe floor check (legacy behavior).
  Future<JoinGameEligibilityData> joinGame(
    String gameId,
    String userId, {
    String? userGender,
    String? ownerId,
  }) async {
    try {
      // Perform vibe floor check if ownerId is provided
      if (ownerId != null) {
        final eligibility = await _vibeFloorService.evaluateJoinEligibility(
          gameId: gameId,
          playerId: userId,
          ownerId: ownerId,
        );

        if (eligibility.needsApproval) {
          AppLog.d('🚦 GameProvider.joinGame: Player requires approval (score: ${eligibility.vibeScore}, floor: ${eligibility.vibeFloor})');
          return JoinGameEligibilityData(
            result: JoinGameResult.requiresApproval,
            matchResult: eligibility.matchResult,
            ownerProfile: eligibility.ownerProfile,
            playerProfile: eligibility.playerProfile,
            vibeScore: eligibility.vibeScore,
            vibeFloor: eligibility.vibeFloor,
          );
        }

        if (eligibility.hasExistingRequest) {
          AppLog.d('🚦 GameProvider.joinGame: Player already has pending request');
          return JoinGameEligibilityData.alreadyRequested();
        }
      }

      // Proceed with join
      // Note: Chat membership is synced automatically by syncGameChatMembers trigger
      await _service.joinGame(gameId, userId, userGender: userGender);
      // Invalidate game cache to force refresh
      invalidateGameCache(gameId);
      // Invalidate user games cache to refresh joined games list
      invalidateUserGamesCache(userId);
      // Refresh the game data
      await getGame(gameId);
      return JoinGameEligibilityData.joined();
    } catch (e) {
      AppLog.d('❌ GameProvider.joinGame error: $e');
      rethrow;
    }
  }

  /// Leave a game
  ///
  /// Removes user from joined_players.
  /// Chat membership is synced automatically by syncGameChatMembers trigger.
  /// Invalidates game cache and refreshes data.
  Future<void> leaveGame(String gameId, String userId) async {
    try {
      await _service.leaveGame(gameId, userId);

      // Fire-and-forget: recordCancellation is fault-tolerant (returns {} on error)
      // and its result is never used in this flow. Standing cache is invalidated
      // separately by the caller via TrustProvider.invalidateStanding().
      unawaited(_trustRepository.recordCancellation(gameId, userId));

      // Invalidate game cache to force refresh
      invalidateGameCache(gameId);
      // Invalidate user games cache to refresh joined games list
      invalidateUserGamesCache(userId);
    } catch (e) {
      AppLog.d('❌ GameProvider.leaveGame error: $e');
      rethrow;
    }
  }

  /// Update game details
  ///
  /// Invalidates game cache and refreshes data
  Future<void> updateGame(String gameId, Map<String, dynamic> updates) async {
    try {
      await _service.updateGameDetails(gameId, updates);
      // Invalidate game cache to force refresh
      invalidateGameCache(gameId);
      // Refresh the game data
      await getGame(gameId);
    } catch (e) {
      AppLog.d('❌ GameProvider.updateGame error: $e');
      rethrow;
    }
  }

  /// Create a new game
  ///
  /// Returns the created game's DocumentReference
  Future<GamesRecord?> createGame(Map<String, dynamic> gameData) async {
    try {
      final gameRef = await _service.createGame(gameData);
      // Fetch and cache the newly created game
      final game = await _service.getGameById(gameRef.id);
      if (game != null) {
        _gameCache[gameRef.id] = game;
        _gameCacheTimestamps[gameRef.id] = DateTime.now();
        _scheduleNotify();
      }
      return game;
    } catch (e) {
      AppLog.d('❌ GameProvider.createGame error: $e');
      rethrow;
    }
  }

  /// Cancel a game
  ///
  /// Invalidates game cache and refreshes data
  Future<void> cancelGame(String gameId) async {
    try {
      await _service.cancelGame(gameId);
      // Invalidate game cache to force refresh
      invalidateGameCache(gameId);
      // Refresh the game data
      await getGame(gameId);
    } catch (e) {
      AppLog.d('❌ GameProvider.cancelGame error: $e');
      rethrow;
    }
  }

  /// Remove a player from a game (owner action)
  ///
  /// For registered players: removes from joined_players
  /// For guest players: removes from guest_players array
  /// Chat membership is synced automatically by syncGameChatMembers trigger.
  ///
  /// Invalidates game cache after removal
  Future<void> removePlayer(
    String gameId, {
    String? playerId,
    String? guestName,
    required bool isGuest,
  }) async {
    try {
      await _service.removePlayer(
        gameId,
        playerId: playerId,
        guestName: guestName,
        isGuest: isGuest,
      );

      // Invalidate game cache
      invalidateGameCache(gameId);

      // Invalidate removed player's user games cache
      if (!isGuest && playerId != null) {
        invalidateUserGamesCache(playerId);
      }
    } catch (e) {
      AppLog.d('❌ GameProvider.removePlayer error: $e');
      rethrow;
    }
  }

  // ========================================
  // PAGINATION METHODS
  // ========================================

  /// Load the next page of available games.
  ///
  /// Fetches the next server page using cursor-based pagination,
  /// appends results to [_additionalPages], and updates the cursor.
  Future<void> loadMoreAvailableGames({
    String? courseFilter,
    String? styleFilter,
    DateTime? dateFilter,
  }) async {
    if (_isLoadingMore || !_hasMorePages) return;

    _isLoadingMore = true;
    _scheduleNotify();

    try {
      final page = await _service.queryAvailableGamesPage(
        courseFilter: courseFilter,
        styleFilter: styleFilter,
        dateFilter: dateFilter,
        pageSize: 50,
        startAfterDocument: _lastPageCursor,
      );

      _additionalPages = [..._additionalPages, ...page.games];
      _lastPageCursor = page.lastDocument;
      _hasMorePages = page.hasMore;
    } catch (e) {
      AppLog.d('❌ GameProvider.loadMoreAvailableGames error: $e');
    } finally {
      _isLoadingMore = false;
      _scheduleNotify();
    }
  }

  /// Reset pagination state (on pull-to-refresh or filter change).
  void resetPagination() {
    _lastPageCursor = null;
    _hasMorePages = true;
    _isLoadingMore = false;
    _additionalPages = [];
  }

  // ========================================
  // CACHE INVALIDATION METHODS
  // ========================================

  /// Invalidate cache for a specific game
  void invalidateGameCache(String gameId) {
    _gameCache.remove(gameId);
    _gameCacheTimestamps.remove(gameId);
    // No notify - stream consumers get fresh data when resubscribed
  }

  /// Invalidate user games cache (when user joins/leaves games)
  void invalidateUserGamesCache(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      AppLog.d('⚠️ GameProvider.invalidateUserGamesCache: skipped (empty userId)');
      return;
    }
    final queryKey = 'user_games_$normalizedUserId';
    // Clear query result caches — live snapshot streams continue delivering updates
    _queryResultCache.remove(queryKey);
    _queryResultCacheTimestamps.remove(queryKey);
  }

  /// Invalidate available games cache (when filters change)
  void invalidateAvailableGamesCache() {
    // Clear query result caches — live snapshot streams continue delivering updates
    _queryResultCache.removeWhere((key, _) => key.startsWith('available_'));
    _queryResultCacheTimestamps.removeWhere((key, _) => key.startsWith('available_'));
  }

  /// Invalidate all game caches
  void invalidateAllGameCache() {
    _gameCache.clear();
    _gameCacheTimestamps.clear();
    _queryResultCache.clear();
    _queryResultCacheTimestamps.clear();
    resetPagination();
    // Do NOT close live stream managers — Firestore snapshot listeners
    // continue delivering updates automatically
  }

  /// Force-close available games streams so the next call creates a fresh Firestore listener.
  /// Use only for explicit user-initiated refresh (pull-to-refresh).
  void resetAvailableGamesStream() {
    _gameStreamManagers.removeWhere((key, value) {
      if (key.startsWith('available_')) {
        value.clear();
        return true;
      }
      return false;
    });
    resetPagination();
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
