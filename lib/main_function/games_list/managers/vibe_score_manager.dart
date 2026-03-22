import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '/core/utils/app_log.dart';
import '/core/utils/state_update.dart';
import '/models/game.dart';
import '/models/vibe_profile.dart';
import '/services/vibe_group_matcher.dart';
import '/services/vibe_matcher.dart';
import '/services/vibe_repository.dart';

/// Manages lazy vibe score computation for visible game cards.
///
/// Scores are computed only when cards become visible (called from sliver builder),
/// batched via post-frame callback to avoid per-card Firestore reads.
/// Scores are keyed by game reference ID and account for all joined players:
/// - 1 other player (host only): 1:1 VibeMatcher score
/// - 2+ other players: GroupVibeMatcher group score
class GamesListVibeScoreManager {
  GamesListVibeScoreManager({
    required State state,
    required Map<String, double> vibeScoresCache,
    VibeRepository? vibeRepository,
    FirebaseAuth? auth,
  })  : _state = state,
        _vibeScores = vibeScoresCache,
        _vibeRepository = vibeRepository ?? VibeRepository(),
        _auth = auth ?? FirebaseAuth.instance;

  final State _state;
  final Map<String, double> _vibeScores;
  final VibeRepository _vibeRepository;
  final FirebaseAuth _auth;

  // Games pending vibe computation (batched per frame), keyed by gameRefId
  final Map<String, Game> _pendingGames = {};

  // Game ref IDs already computed or in-flight (prevents duplicate work)
  final Set<String> _processedGameIds = {};

  // Roster fingerprint per game — used to detect player roster changes
  // and invalidate stale scores (e.g. when someone joins/leaves)
  final Map<String, String> _rosterKeys = {};

  // Gate to prevent scheduling multiple post-frame callbacks
  bool _callbackScheduled = false;

  /// Request a vibe score for a game card.
  ///
  /// Called from the sliver builder when a card becomes visible.
  /// If the score is already cached and the roster hasn't changed,
  /// returns immediately. Otherwise, batches the request and schedules
  /// computation after the frame.
  void requestScore(Game game) {
    final gameId = game.reference.id;
    final rosterKey = _buildRosterKey(game);

    // Check if roster changed since last computation
    if (_rosterKeys[gameId] != null && _rosterKeys[gameId] != rosterKey) {
      // Roster changed — invalidate cached score
      _vibeScores.remove(gameId);
      _processedGameIds.remove(gameId);
    }

    // Already computed with current roster
    if (_vibeScores.containsKey(gameId)) return;

    // Already processed or in-flight
    if (_processedGameIds.contains(gameId)) return;

    _pendingGames[gameId] = game;
    _scheduleComputation();
  }

  /// Build a roster fingerprint from a game's player list.
  String _buildRosterKey(Game game) {
    final currentUid = _auth.currentUser?.uid ?? '';
    final uids = <String>[];

    // Owner
    final ownerUid = game.userRef?.id ?? game.uid;
    if (ownerUid.isNotEmpty && ownerUid != currentUid) {
      uids.add(ownerUid);
    }

    // Joined players
    for (final ref in game.joinedPlayers) {
      if (ref.id != currentUid) {
        uids.add(ref.id);
      }
    }

    uids.sort();
    return uids.join(',');
  }

  void _scheduleComputation() {
    if (_callbackScheduled) return;
    _callbackScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processVibeComputations();
    });
  }

  Future<void> _processVibeComputations() async {
    _callbackScheduled = false;
    if (!_state.mounted) return;

    if (_pendingGames.isEmpty) return;

    final currentUid = _auth.currentUser?.uid ?? '';

    // Snapshot and clear pending games
    final games = Map<String, Game>.from(_pendingGames);
    _pendingGames.clear();
    _processedGameIds.addAll(games.keys);

    try {
      // Get current user's vibe profile (sync if cached, async first time)
      VibeProfile? myVibes = _vibeRepository.getCachedVibeProfileSync();
      myVibes ??= await _vibeRepository.getMyVibesCached();

      // Collect all unique other-player UIDs across all pending games
      final allPlayerUids = <String>{};
      final gamePlayerMap = <String, List<String>>{}; // gameId -> other UIDs

      for (final entry in games.entries) {
        final game = entry.value;
        final otherUids = <String>{};

        // Owner
        final ownerUid = game.userRef?.id ?? game.uid;
        if (ownerUid.isNotEmpty && ownerUid != currentUid) {
          otherUids.add(ownerUid);
        }

        // Joined players
        for (final ref in game.joinedPlayers) {
          if (ref.id != currentUid) {
            otherUids.add(ref.id);
          }
        }

        gamePlayerMap[entry.key] = otherUids.toList();
        allPlayerUids.addAll(otherUids);
      }

      // Batch-fetch all player vibe profiles
      final profiles = allPlayerUids.isEmpty
          ? <String, VibeProfile>{}
          : await _vibeRepository.batchGetVibeProfiles(
              allPlayerUids.toList(),
            );

      // Compute scores for each game
      var hasNewScores = false;
      for (final entry in games.entries) {
        final gameId = entry.key;
        if (_vibeScores.containsKey(gameId)) continue;

        final otherUids = gamePlayerMap[gameId] ?? [];
        if (otherUids.isEmpty) continue;

        double score;
        if (otherUids.length == 1) {
          // 1:1 fallback: host only, no other joined players
          final otherProfile = profiles[otherUids.first];
          if (otherProfile == null) continue;
          final result = VibeMatcher.score(myVibes, otherProfile);
          score = result.finalScorePercent;
        } else {
          // Group scoring: 2+ other players
          final members = <GroupVibeMember>[];
          for (final uid in otherUids) {
            final profile = profiles[uid];
            if (profile == null) continue;
            members.add(GroupVibeMember(
              id: uid,
              name: '', // Name not needed for score computation
              profile: profile,
            ));
          }
          if (members.isEmpty) continue;
          final result = GroupVibeMatcher.scoreGroup(
            mine: myVibes,
            others: members,
          );
          score = result.groupFitScore;
        }

        _vibeScores[gameId] = score;
        _rosterKeys[gameId] = _buildRosterKey(entry.value);
        hasNewScores = true;
      }

      // Trigger rebuild so visible cards pick up scores
      if (hasNewScores && _state.mounted) {
        updateState(_state, () {});
      }

      assert(() {
        AppLog.d('📊 VibeScoreManager: Computed ${games.length} vibe scores');
        return true;
      }());
    } catch (e) {
      AppLog.d('❌ VibeScoreManager._processVibeComputations error: $e');
      // Non-fatal - cards show without vibe scores
    }
  }

  /// Clear all cached scores and processing state.
  ///
  /// Called on pull-to-refresh to force recomputation.
  void clearCache() {
    _vibeScores.clear();
    _pendingGames.clear();
    _processedGameIds.clear();
    _rosterKeys.clear();
  }
}
