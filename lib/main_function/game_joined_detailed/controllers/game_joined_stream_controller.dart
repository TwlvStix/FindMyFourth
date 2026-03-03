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
import '/services/vibe_repository.dart';

/// Callback definitions for state updates from the stream controller.
typedef OnGameDataReceived = void Function(GamesRecord? gamesRecord);
typedef OnStreamError = void Function(bool hasError);
typedef OnAnimationTrigger = void Function();
typedef OnPendingRequestsLoaded = void Function(
  List<JoinRequest> requests,
  VibeProfile? ownerProfile,
  String? expandedRequestId,
);
typedef OnPendingRequestsLoadingChanged = void Function(bool isLoading);

/// Manages game stream subscription and orchestrates side-effect loading.
///
/// State ownership stays in the widget; this class coordinates data loading
/// and calls back to update widget state.
class GameJoinedStreamController {
  GameJoinedStreamController({
    required this.vibeRepository,
  });

  final VibeRepository vibeRepository;

  // Stream subscription managed by this controller
  StreamSubscription<GamesRecord?>? _gameSubscription;

  // Tracking state for deduplication (owned here, not widget)
  String? _loadedPendingRequestsGameId;
  bool _isLoadingPendingRequests = false;
  String? _loadedGroupVibeCacheKey;
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
        AppLog.d('❌ GameJoinedDetailed stream error: $error');
        onError(true);
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
    _loadedPendingRequestsGameId = null;
    _hasTriggeredAnimation = false;
    _isLoadingPendingRequests = false;
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
    required DocumentReference? currentUserRef,
    required OnAnimationTrigger onAnimationTrigger,
    required OnPendingRequestsLoaded onPendingRequestsLoaded,
    required OnPendingRequestsLoadingChanged onLoadingChanged,
  }) {
    if (gamesRecord == null) return;

    final currentUserId = currentUserRef?.id;
    final game = Game.fromRecord(gamesRecord);

    // 1. Trigger entrance animation (once per widget lifetime)
    if (!_hasTriggeredAnimation) {
      _hasTriggeredAnimation = true;
      onAnimationTrigger();
    }

    // 2. Load pending requests for owner (once per gameId)
    if (game.userRef == currentUserRef && currentUserRef != null) {
      _loadPendingRequestsIfNeeded(
        state: state,
        context: context,
        gameId: game.reference.id,
        ownerId: currentUserRef.id,
        onLoaded: onPendingRequestsLoaded,
        onLoadingChanged: onLoadingChanged,
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

  void _loadPendingRequestsIfNeeded({
    required State state,
    required BuildContext context,
    required String gameId,
    required String ownerId,
    required OnPendingRequestsLoaded onLoaded,
    required OnPendingRequestsLoadingChanged onLoadingChanged,
  }) {
    if (_loadedPendingRequestsGameId == gameId || _isLoadingPendingRequests) {
      return;
    }
    _loadedPendingRequestsGameId = gameId;
    _isLoadingPendingRequests = true;
    _loadPendingRequests(
      state: state,
      context: context,
      gameId: gameId,
      ownerId: ownerId,
      onLoaded: onLoaded,
      onLoadingChanged: onLoadingChanged,
    );
  }

  Future<void> _loadPendingRequests({
    required State state,
    required BuildContext context,
    required String gameId,
    required String ownerId,
    required OnPendingRequestsLoaded onLoaded,
    required OnPendingRequestsLoadingChanged onLoadingChanged,
  }) async {
    if (!state.mounted) return;

    try {
      final results = await Future.wait([
        context
            .read<JoinRequestProvider>()
            .getPendingRequestsForGame(gameId, ownerId),
        vibeRepository.getVibeProfileForUser(ownerId),
      ]);

      if (!state.mounted) return;

      final requests = results[0] as List<JoinRequest>;
      requests.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final ownerProfile = results[1] as VibeProfile;
      final expandedId = requests.isNotEmpty ? requests.first.id : null;

      _isLoadingPendingRequests = false;
      onLoaded(requests, ownerProfile, expandedId);
    } catch (error) {
      AppLog.d('❌ GameJoinedDetailed._loadPendingRequests error: $error');
      _isLoadingPendingRequests = false;
      if (state.mounted) {
        onLoadingChanged(false);
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
