import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/users_record.dart';
import '/models/vibe_profile.dart';
import '/services/friend_service.dart';
import '/services/vibe_matcher.dart';
import '/services/vibe_repository.dart';

class MutualFriendsResult {
  const MutualFriendsResult({
    required this.friends,
    required this.loaded,
  });

  final List<UsersRecord> friends;
  final bool loaded;
}

class VibeMatchLoadResult {
  const VibeMatchLoadResult({
    required this.match,
    required this.myVibes,
    required this.theirVibes,
    required this.isLoading,
    required this.profileId,
  });

  final VibeMatchResult? match;
  final VibeProfile? myVibes;
  final VibeProfile? theirVibes;
  final bool isLoading;
  final String? profileId;
}

class ProfileUserController {
  ProfileUserController({
    VibeRepository? vibeRepository,
    FriendService? friendService,
  })  : _vibeRepository = vibeRepository ?? VibeRepository(),
        _friendService = friendService ?? FriendService();

  final VibeRepository _vibeRepository;
  final FriendService _friendService;

  bool shouldLoadVibeMatch({
    required bool isLoading,
    required VibeMatchResult? existingMatch,
    required String? loadedUserId,
    required DocumentSnapshot snapshot,
  }) {
    if (isLoading) {
      return false;
    }
    if (existingMatch != null && loadedUserId == snapshot.id) {
      return false;
    }
    return true;
  }

  Future<VibeMatchLoadResult> loadVibeMatch(DocumentSnapshot snapshot) async {
    try {
      final myVibes = await _vibeRepository.getMyVibesCached();
      final theirVibes = _vibeRepository.profileFromSnapshot(snapshot);
      final result = VibeMatcher.score(myVibes, theirVibes);
      return VibeMatchLoadResult(
        match: result,
        myVibes: myVibes,
        theirVibes: theirVibes,
        isLoading: false,
        profileId: snapshot.id,
      );
    } catch (_) {
      return VibeMatchLoadResult(
        match: null,
        myVibes: null,
        theirVibes: null,
        isLoading: false,
        profileId: snapshot.id,
      );
    }
  }

  Future<MutualFriendsResult> fetchMutualFriends({
    required List<DocumentReference> theirFriends,
    required List<DocumentReference> myFriends,
    void Function()? onRemoteFetchStart,
  }) async {
    final myUids = myFriends.map((r) => r.id).toSet();
    final theirUids = theirFriends.map((r) => r.id).toSet();
    final mutualUids = myUids.intersection(theirUids);

    if (mutualUids.isEmpty) {
      return const MutualFriendsResult(
        friends: <UsersRecord>[],
        loaded: true,
      );
    }

    onRemoteFetchStart?.call();

    final results = await _friendService.getMutualFriends(
      myFriends: myFriends,
      theirFriends: theirFriends,
    );
    return MutualFriendsResult(
      friends: results,
      loaded: true,
    );
  }
}
