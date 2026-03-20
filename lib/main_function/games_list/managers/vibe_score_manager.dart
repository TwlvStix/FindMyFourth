import 'package:flutter/widgets.dart';

import '/core/utils/app_log.dart';
import '/core/utils/state_update.dart';
import '/models/vibe_profile.dart';
import '/services/vibe_matcher.dart';
import '/services/vibe_repository.dart';

/// Manages lazy vibe score computation for visible game cards.
///
/// Scores are computed only when cards become visible (called from sliver builder),
/// batched via post-frame callback to avoid per-card Firestore reads.
/// Scores are keyed by owner UID (not game ref ID) since the same host
/// produces the same vibe score regardless of which game they posted.
class GamesListVibeScoreManager {
  GamesListVibeScoreManager({
    required State state,
    required Map<String, double> vibeScoresCache,
    VibeRepository? vibeRepository,
  })  : _state = state,
        _vibeScores = vibeScoresCache,
        _vibeRepository = vibeRepository ?? VibeRepository();

  final State _state;
  final Map<String, double> _vibeScores;
  final VibeRepository _vibeRepository;

  // Owner UIDs pending vibe computation (batched per frame)
  final Set<String> _pendingOwnerUids = {};

  // Owner UIDs already computed or in-flight (prevents duplicate work)
  final Set<String> _processedOwnerUids = {};

  // Gate to prevent scheduling multiple post-frame callbacks
  bool _callbackScheduled = false;

  /// Request a vibe score for a game card.
  ///
  /// Called from the sliver builder when a card becomes visible.
  /// If the score is already cached, returns immediately.
  /// Otherwise, batches the request and schedules computation after the frame.
  void requestScore(String gameRefId, String ownerUid) {
    // Already computed
    if (_vibeScores.containsKey(ownerUid)) return;

    // Already processed or in-flight
    if (_processedOwnerUids.contains(ownerUid)) return;

    _pendingOwnerUids.add(ownerUid);
    _scheduleComputation();
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

    if (_pendingOwnerUids.isEmpty) return;

    // Snapshot and clear pending set
    final ownerUids = Set<String>.from(_pendingOwnerUids);
    _pendingOwnerUids.clear();
    _processedOwnerUids.addAll(ownerUids);

    try {
      // Get current user's vibe profile (sync if cached, async first time)
      VibeProfile? myVibes = _vibeRepository.getCachedVibeProfileSync();
      myVibes ??= await _vibeRepository.getMyVibesCached();

      // Batch-fetch owner vibe profiles
      final ownerProfiles = await _vibeRepository.batchGetVibeProfiles(
        ownerUids.toList(),
      );

      // Compute scores
      var hasNewScores = false;
      for (final entry in ownerProfiles.entries) {
        if (_vibeScores.containsKey(entry.key)) continue;

        final result = VibeMatcher.score(myVibes, entry.value);
        _vibeScores[entry.key] = result.finalScorePercent;
        hasNewScores = true;
      }

      // Trigger rebuild so visible cards pick up scores
      if (hasNewScores && _state.mounted) {
        updateState(_state, () {});
      }

      assert(() {
        AppLog.d('📊 VibeScoreManager: Computed ${ownerProfiles.length} vibe scores');
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
    _pendingOwnerUids.clear();
    _processedOwnerUids.clear();
  }
}
