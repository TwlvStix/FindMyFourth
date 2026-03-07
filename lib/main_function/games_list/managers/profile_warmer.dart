import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '/providers/profile_provider.dart';

/// Handles deferred profile warming for the games list.
///
/// Schedules profile warm operations to run after builds complete,
/// avoiding side effects during widget build.
class GamesListProfileWarmer {
  GamesListProfileWarmer({
    required State state,
    this.onProfilesWarmed,
  }) : _state = state;

  final State _state;

  /// Called after profiles have been warmed, to trigger dependent operations.
  final VoidCallback? onProfilesWarmed;

  // Track last warmed profile UIDs to avoid redundant warming calls
  Set<String> _lastWarmedProfileUids = {};

  // Pending warm UIDs for deferred processing (avoids side effects during build)
  Set<String>? _pendingWarmUids;

  // Gate to prevent scheduling multiple callbacks before prior one runs
  bool _warmScheduled = false;

  /// Schedules profile warming to run after the current build completes.
  void scheduleProfileWarm(Set<String> ownerUids) {
    if (ownerUids.isEmpty) return;
    if (setEquals(ownerUids, _lastWarmedProfileUids)) return;

    // Prevent scheduling if already scheduled for same UIDs
    if (_warmScheduled && setEquals(ownerUids, _pendingWarmUids)) return;

    _pendingWarmUids = ownerUids;

    if (!_warmScheduled) {
      _warmScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processPendingProfileWarm();
      });
    }
  }

  Future<void> _processPendingProfileWarm() async {
    _warmScheduled = false;
    if (!_state.mounted) return;

    final uids = _pendingWarmUids;
    if (uids == null || uids.isEmpty) return;

    _pendingWarmUids = null;
    _lastWarmedProfileUids = uids;

    // Warm profiles and wait for completion
    await _state.context.read<ProfileProvider>().warmProfiles(uids);

    // After profiles are warmed, notify callback for dependent operations
    if (_state.mounted && onProfilesWarmed != null) {
      onProfilesWarmed!();
    }
  }
}
