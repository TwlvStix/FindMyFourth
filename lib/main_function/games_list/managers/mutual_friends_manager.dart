import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '/core/utils/state_update.dart';
import '/providers/profile_provider.dart';
import '/providers/user_provider.dart';

/// Manages mutual friend computation and caching for the games list.
///
/// Computes mutual friends between the current user and game hosts using
/// cached profile data from ProfileProvider, avoiding additional Firestore reads.
class GamesListMutualFriendsManager {
  GamesListMutualFriendsManager({
    required State state,
  }) : _state = state;

  final State _state;

  // Mutual friend caches: hostId -> list of mutual friend UIDs
  final Map<String, List<String>> mutualFriendsMap = {};

  // First mutual friend display name cache: hostId -> name
  final Map<String, String> firstMutualFriendName = {};

  // Hosts that need mutual friend computation (persists until computed)
  final Set<String> _hostsNeedingMutualComputation = {};

  // Gate to prevent scheduling multiple callbacks
  bool _mutualFetchScheduled = false;

  /// Returns the set of host IDs that have mutual friends with the current user.
  Set<String> get mutualFriendHostIds => mutualFriendsMap.keys.toSet();

  /// Clears all cached mutual friend data.
  void clearCache() {
    mutualFriendsMap.clear();
    firstMutualFriendName.clear();
    _hostsNeedingMutualComputation.clear();
  }

  /// Schedules mutual friend computation to run after the current build completes.
  void scheduleMutualFriendFetch(Set<String> hostIds) {
    if (hostIds.isEmpty) return;

    // Add hosts that we haven't computed yet
    final newHostIds = hostIds.where((id) => !mutualFriendsMap.containsKey(id));
    _hostsNeedingMutualComputation.addAll(newHostIds);

    if (_hostsNeedingMutualComputation.isEmpty) return;

    if (!_mutualFetchScheduled) {
      _mutualFetchScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        processPendingMutualFetch();
      });
    }
  }

  /// Computes mutual friends from cached ProfileProvider data.
  ///
  /// Uses the already-warmed profiles to get host friends lists and compute
  /// mutual friends locally, avoiding additional Firestore reads.
  void processPendingMutualFetch() {
    _mutualFetchScheduled = false;
    if (!_state.mounted) return;

    if (_hostsNeedingMutualComputation.isEmpty) return;

    final context = _state.context;
    final userProvider = context.read<UserProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final myFriends = userProvider.currentUser?.friends ?? [];
    if (myFriends.isEmpty) return;

    // Build set of my friend UIDs for intersection
    final myFriendIds = myFriends.map((ref) => ref.id).toSet();

    // Collect UIDs of mutual friends we find (to warm their profiles for names)
    final mutualFriendUidsToWarm = <String>{};
    final hostsToRemove = <String>[];
    var hasUpdates = false;

    for (final hostId in _hostsNeedingMutualComputation) {
      // Skip if already computed
      if (mutualFriendsMap.containsKey(hostId)) {
        hostsToRemove.add(hostId);
        continue;
      }

      // Get host's profile from cache (already warmed by onOwnerUidsReady)
      final hostProfile = profileProvider.getCachedProfile(hostId);
      if (hostProfile == null) {
        // Profile not cached yet - will be recomputed after profile warm completes
        continue;
      }

      // Get host's friend UIDs
      final hostFriendIds = hostProfile.friends.map((ref) => ref.id).toSet();

      // Compute intersection locally (no Firestore call!)
      final mutualIds = myFriendIds.intersection(hostFriendIds);

      if (mutualIds.isNotEmpty) {
        // Get first mutual friend's name from cache (if available)
        final firstMutualId = mutualIds.first;
        final firstMutualProfile =
            profileProvider.getCachedProfile(firstMutualId);
        final firstName = firstMutualProfile?.displayName ?? '';

        mutualFriendsMap[hostId] = mutualIds.toList();
        firstMutualFriendName[hostId] =
            firstName.isNotEmpty ? firstName : 'a friend';
        hasUpdates = true;

        // Schedule warming of mutual friend profiles for display names
        mutualFriendUidsToWarm.addAll(mutualIds);
      }

      // Mark this host as processed (whether or not it had mutual friends)
      hostsToRemove.add(hostId);
    }

    // Remove processed hosts
    _hostsNeedingMutualComputation.removeAll(hostsToRemove);

    // Warm mutual friend profiles to get their display names
    if (mutualFriendUidsToWarm.isNotEmpty) {
      profileProvider.warmProfiles(mutualFriendUidsToWarm);
    }

    // Trigger rebuild if we found any mutual friends
    if (hasUpdates && _state.mounted) {
      updateState(_state, () {});
    }
  }

  /// Check if there are hosts needing mutual friend computation.
  bool get hasPendingHosts => _hostsNeedingMutualComputation.isNotEmpty;
}
