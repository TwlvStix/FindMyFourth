import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '/backend/backend.dart';
import '/core/utils/app_log.dart';
import '/models/game.dart';
import '/models/join_request.dart';
import '/models/vibe_profile.dart';
import '/providers/game_provider.dart';
import '/providers/group_vibe_provider.dart';
import '/providers/join_request_provider.dart';
import '/providers/profile_provider.dart';
import '/services/vibe_group_matcher.dart';
import 'join_game_detailed_controller.dart';

/// Callback definitions for state updates from the stream controller.
typedef OnGameDataReceived = void Function(GamesRecord? gamesRecord);
typedef OnStreamError = void Function(bool hasError, Object? error);
typedef OnAnimationTrigger = void Function();
typedef OnExistingRequestLoaded = void Function(
  JoinRequest? request,
  bool isLoading,
);

/// Manages game stream subscription and orchestrates side-effect loading.
///
/// State ownership stays in the widget; this class coordinates data loading
/// and calls back to update widget state.
class JoinGameDetailedStreamController {
  JoinGameDetailedStreamController({
    required this.controller,
  });

  final JoinGameDetailedController controller;

  // Stream subscription managed by this controller
  StreamSubscription<GamesRecord?>? _gameSubscription;

  // Tracking state for deduplication (owned here, not widget)
  String? _loadedGroupVibeCacheKey;
  String? _loadedRequestGameId;
  bool _hasTriggeredAnimation = false;

  /// Initializes the game stream subscription.
  ///
  /// [context] - BuildContext for provider access
  /// [gameId] - The game ID to watch
  /// [onData] - Callback when game data is received
  /// [onError] - Callback when stream errors
  void initSubscription({
    required BuildContext context,
    required String gameId,
    required OnGameDataReceived onData,
    required OnStreamError onError,
  }) {
    final gameStream = context.read<GameProvider>().watchGame(gameId);
    _gameSubscription = gameStream.listen(
      onData,
      onError: (Object error) {
        AppLog.d('❌ JoinGameDetailed stream error: $error');
        onError(true, error);
      },
    );
  }

  /// Cancels the current subscription and resets all tracking state.
  ///
  /// Call this in didUpdateWidget when gameRef changes.
  void resetAndCancel() {
    _gameSubscription?.cancel();
    _gameSubscription = null;

    // Reset all tracking state
    _loadedGroupVibeCacheKey = null;
    _loadedRequestGameId = null;
    _hasTriggeredAnimation = false;
  }

  /// Cancels subscription without reset. Call in dispose().
  void dispose() {
    _gameSubscription?.cancel();
    _gameSubscription = null;
  }

  /// Processes incoming game data and triggers side effects.
  ///
  /// This is the orchestration entry point called from the widget's
  /// stream data handler.
  ///
  /// Returns immediately if [gamesRecord] is null.
  void processGameData({
    required State state,
    required BuildContext context,
    required GamesRecord? gamesRecord,
    required String? currentUserId,
    required OnAnimationTrigger onAnimationTrigger,
    required OnExistingRequestLoaded onExistingRequestLoaded,
  }) {
    if (gamesRecord == null) return;

    final game = Game.fromRecord(gamesRecord);

    // 1. Trigger entrance animation (once per widget lifetime)
    if (!_hasTriggeredAnimation) {
      _hasTriggeredAnimation = true;
      onAnimationTrigger();
    }

    // 2. Check for existing join request (once per gameId)
    if (currentUserId != null &&
        _loadedRequestGameId != game.reference.id) {
      _loadedRequestGameId = game.reference.id;
      _loadExistingRequest(
        state: state,
        context: context,
        gameId: game.reference.id,
        userId: currentUserId,
        onLoaded: onExistingRequestLoaded,
      );
    }

    // 3. Load group vibe data (once per cache key — includes roster)
    if (currentUserId != null) {
      _loadGroupVibeIfNeeded(
        state: state,
        context: context,
        game: game,
        currentUserId: currentUserId,
      );
    }
  }

  Future<void> _loadExistingRequest({
    required State state,
    required BuildContext context,
    required String gameId,
    required String userId,
    required OnExistingRequestLoaded onLoaded,
  }) async {
    if (!state.mounted) return;

    try {
      final request = await controller.loadExistingRequest(
        joinRequestProvider: context.read<JoinRequestProvider>(),
        gameId: gameId,
        userId: userId,
      );

      if (state.mounted) {
        onLoaded(request, false);
      }
    } catch (e) {
      AppLog.d('❌ JoinGameDetailed._loadExistingRequest error: $e');
      if (state.mounted) {
        onLoaded(null, false);
      }
    }
  }

  void _loadGroupVibeIfNeeded({
    required State state,
    required BuildContext context,
    required Game game,
    required String currentUserId,
  }) {
    final groupVibeProvider = context.read<GroupVibeProvider>();

    final cacheKey = groupVibeProvider.buildGameCacheKey(
      gameRecord: game,
      currentUserId: currentUserId,
    );

    // Skip if already loaded this cache key or provider says no load needed
    if (_loadedGroupVibeCacheKey == cacheKey) return;
    if (!groupVibeProvider.shouldLoad(cacheKey)) return;

    _loadedGroupVibeCacheKey = cacheKey;
    _loadGroupVibeData(
      state: state,
      context: context,
      game: game,
      currentUserId: currentUserId,
      cacheKey: cacheKey,
    );
  }

  Future<void> _loadGroupVibeData({
    required State state,
    required BuildContext context,
    required Game game,
    required String currentUserId,
    required String cacheKey,
  }) async {
    if (!state.mounted) return;

    final groupVibeProvider = context.read<GroupVibeProvider>();
    final memberIds = groupVibeProvider.otherMemberIdsForGame(
      gameRecord: game,
      currentUserId: currentUserId,
    );

    await groupVibeProvider.ensureGroupVibeMatch(
      cacheKey: cacheKey,
      memberUserIds: memberIds,
      memberLoader: (userIds) async {
        final profileMap =
            await context.read<ProfileProvider>().batchGetProfiles(userIds);
        final members = <GroupVibeMember>[];
        for (final entry in profileMap.entries) {
          final userRecord = entry.value;
          final displayName = userRecord.displayName.isNotEmpty
              ? userRecord.displayName
              : 'Player';
          members.add(
            GroupVibeMember(
              id: entry.key,
              name: displayName,
              profile: VibeProfile.fromFirestore(userRecord.vibeProfile),
            ),
          );
        }
        return members;
      },
    );
  }
}
