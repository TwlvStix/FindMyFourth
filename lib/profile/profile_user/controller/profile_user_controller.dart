import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/backend/schema/users_record.dart';
import '/models/vibe_profile.dart';
import '/services/friend_service.dart';
import '/services/vibe_match_explanation.dart';
import '/services/vibe_matcher.dart';
import '/utils/vibe_archetypes.dart';
import '/vibe/premium_vibe_page/premium_vibe_page_data.dart';
import '/services/vibe_repository.dart';

class ProfileUserController extends ChangeNotifier {
  ProfileUserController({
    VibeRepository? vibeRepository,
    FriendService? friendService,
  })  : _vibeRepository = vibeRepository ?? VibeRepository(),
        _friendService = friendService ?? FriendService();

  final VibeRepository _vibeRepository;
  final FriendService _friendService;

  // ═══════════════════════════════════════════════════════════════════════════
  // VIBE MATCH STATE
  // ═══════════════════════════════════════════════════════════════════════════
  VibeMatchResult? _vibeMatchResult;
  VibeMatchResult? get vibeMatchResult => _vibeMatchResult;

  VibeProfile? _myVibes;
  VibeProfile? _theirVibes;
  bool _isVibeMatchLoading = false;
  bool get isVibeMatchLoading => _isVibeMatchLoading;

  String? _vibeMatchUserId;

  String _cachedUserName = '';
  String _cachedUserPhotoUrl = '';

  // ═══════════════════════════════════════════════════════════════════════════
  // MUTUAL FRIENDS STATE
  // ═══════════════════════════════════════════════════════════════════════════
  List<UsersRecord> _mutualFriends = [];
  List<UsersRecord> get mutualFriends => _mutualFriends;

  bool _mutualFriendsLoaded = true;
  bool get mutualFriendsLoaded => _mutualFriendsLoaded;

  String? _lastMutualFriendsProfileId;

  bool _disposed = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  void onProfileDataReceived(
    UsersRecord userRecord,
    DocumentReference userRef, {
    required bool isSelf,
    required List<DocumentReference> myFriends,
  }) {
    _cachedUserName = userRecord.displayName.isNotEmpty
        ? userRecord.displayName
        : 'Golfer';
    _cachedUserPhotoUrl = userRecord.photoUrl.isNotEmpty
        ? userRecord.photoUrl
        : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';

    if (!isSelf) {
      _ensureVibeMatch(userRef);
      _fetchMutualFriends(
        userRef.id,
        userRecord.friends,
        myFriends,
      );
    }
  }

  PremiumVibePageData? buildVibePageData(DocumentReference userRef) {
    final result = _vibeMatchResult;
    final myVibes = _myVibes;
    final theirVibes = _theirVibes;
    if (result == null || myVibes == null || theirVibes == null) {
      return null;
    }

    final explanation = buildMatchExplanation(
      matchResult: result,
      a: myVibes,
      b: theirVibes,
    );

    return PremiumVibePageData(
      userId: userRef.id,
      userName: _cachedUserName,
      userPhotoUrl: _cachedUserPhotoUrl,
      userRef: userRef,
      matchResult: result,
      explanation: explanation,
      myProfile: myVibes,
      theirProfile: theirVibes,
      myArchetype: VibeArchetypes.classifyProfile(myVibes),
      theirArchetype: VibeArchetypes.classifyProfile(theirVibes),
    );
  }

  void reset() {
    _vibeMatchResult = null;
    _myVibes = null;
    _theirVibes = null;
    _isVibeMatchLoading = false;
    _vibeMatchUserId = null;
    _cachedUserName = '';
    _cachedUserPhotoUrl = '';
    _mutualFriends = [];
    _mutualFriendsLoaded = true;
    _lastMutualFriendsProfileId = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL
  // ═══════════════════════════════════════════════════════════════════════════

  void _ensureVibeMatch(DocumentReference userRef) {
    if (_isVibeMatchLoading) return;
    if (_vibeMatchResult != null && _vibeMatchUserId == userRef.id) return;

    _vibeMatchUserId = userRef.id;
    _loadVibeMatch(userRef);
  }

  Future<void> _loadVibeMatch(DocumentReference userRef) async {
    _isVibeMatchLoading = true;
    _vibeMatchResult = null;
    _safeNotify();

    try {
      final snapshot = await userRef.get();
      final myVibes = await _vibeRepository.getMyVibesCached();
      final theirVibes = _vibeRepository.profileFromSnapshot(snapshot);
      final result = VibeMatcher.score(myVibes, theirVibes);

      _myVibes = myVibes;
      _theirVibes = theirVibes;
      _vibeMatchResult = result;
      _vibeMatchUserId = snapshot.id;
      _isVibeMatchLoading = false;
    } catch (_) {
      _myVibes = null;
      _theirVibes = null;
      _vibeMatchResult = null;
      _isVibeMatchLoading = false;
    }
    _safeNotify();
  }

  Future<void> _fetchMutualFriends(
    String profileUserId,
    List<DocumentReference> theirFriends,
    List<DocumentReference> myFriends,
  ) async {
    if (_lastMutualFriendsProfileId == profileUserId && _mutualFriendsLoaded) {
      return;
    }
    _lastMutualFriendsProfileId = profileUserId;

    final myUids = myFriends.map((r) => r.id).toSet();
    final theirUids = theirFriends.map((r) => r.id).toSet();
    final mutualUids = myUids.intersection(theirUids);

    if (mutualUids.isEmpty) {
      _mutualFriends = [];
      _mutualFriendsLoaded = true;
      _safeNotify();
      return;
    }

    _mutualFriendsLoaded = false;
    _safeNotify();

    final results = await _friendService.getMutualFriends(
      myFriends: myFriends,
      theirFriends: theirFriends,
    );

    _mutualFriends = results;
    _mutualFriendsLoaded = true;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
