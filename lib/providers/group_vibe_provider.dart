import 'dart:async';

import 'package:flutter/foundation.dart';

import '/core/utils/app_log.dart';
import '/models/game.dart';
import '/models/vibe_profile.dart';
import '/services/vibe_group_matcher.dart';
import '/services/vibe_repository.dart';
import '/vibe/vibe_recommendation_rank.dart';

typedef GroupVibeMembersLoader = Future<List<GroupVibeMember>> Function(
  List<String> userIds,
);

/// Caches group vibe matches by key and exposes member-level match maps.
class GroupVibeProvider extends ChangeNotifier {
  GroupVibeProvider({
    VibeRepository? vibeRepository,
    Future<VibeProfile> Function()? loadMyVibes,
    Duration cacheTTL = const Duration(minutes: 5),
    DateTime Function()? now,
  })  : _vibeRepository = vibeRepository,
        _loadMyVibes = loadMyVibes,
        _cacheTTL = cacheTTL,
        _now = now ?? DateTime.now;

  VibeRepository? _vibeRepository;
  final Future<VibeProfile> Function()? _loadMyVibes;
  final Duration _cacheTTL;
  final DateTime Function() _now;

  final Map<String, GroupVibeMatchResult> _matchCache = {};
  final Map<String, Map<String, GroupVibeMemberResult>> _memberMatchCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Set<String> _loadingKeys = <String>{};

  Timer? _notifyTimer;
  bool _disposed = false;

  String buildGameCacheKey({
    required Game gameRecord,
    required String currentUserId,
  }) {
    final otherIds = otherMemberIdsForGame(
      gameRecord: gameRecord,
      currentUserId: currentUserId,
    );
    return '${gameRecord.reference.id}:$currentUserId:${otherIds.join(',')}';
  }

  List<String> otherMemberIdsForGame({
    required Game gameRecord,
    required String currentUserId,
  }) {
    final groupRefs = gameRecord.joinedPlayers.toList();
    final owner = gameRecord.userRef;
    if (owner != null && !groupRefs.contains(owner)) {
      groupRefs.insert(0, owner);
    }
    return groupRefs
        .where((ref) => ref.id != currentUserId)
        .map((ref) => ref.id)
        .toList()
      ..sort();
  }

  GroupVibeMatchResult? getMatch(String cacheKey) => _matchCache[cacheKey];

  Map<String, GroupVibeMemberResult> getMemberMatchesById(String cacheKey) {
    return _memberMatchCache[cacheKey] ??
        const <String, GroupVibeMemberResult>{};
  }

  bool isLoading(String cacheKey) => _loadingKeys.contains(cacheKey);

  bool hasFreshCache(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) {
      return false;
    }
    if (!_matchCache.containsKey(cacheKey)) {
      return false;
    }
    return _now().difference(timestamp) < _cacheTTL;
  }

  bool shouldLoad(String cacheKey) {
    return !isLoading(cacheKey) && !hasFreshCache(cacheKey);
  }

  int compareMemberIds({
    required String cacheKey,
    required String aId,
    required String bId,
  }) {
    final memberMatchesById = getMemberMatchesById(cacheKey);
    final aMatch = memberMatchesById[aId];
    final bMatch = memberMatchesById[bId];
    if (aMatch == null && bMatch == null) {
      return 0;
    }
    if (aMatch == null) {
      return 1;
    }
    if (bMatch == null) {
      return -1;
    }
    final rankA = recommendationRank(aMatch.matchResult.recommendation);
    final rankB = recommendationRank(bMatch.matchResult.recommendation);
    if (rankA != rankB) {
      return rankA.compareTo(rankB);
    }
    return bMatch.displayScore.compareTo(aMatch.displayScore);
  }

  Future<void> ensureGroupVibeMatch({
    required String cacheKey,
    required List<String> memberUserIds,
    required GroupVibeMembersLoader memberLoader,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && !shouldLoad(cacheKey)) {
      return;
    }

    _loadingKeys.add(cacheKey);
    _scheduleNotify();

    try {
      final myVibes = await (_loadMyVibes?.call() ??
          (_vibeRepository ??= VibeRepository()).getMyVibesCached());
      final members = memberUserIds.isEmpty
          ? const <GroupVibeMember>[]
          : await memberLoader(memberUserIds);
      final result = GroupVibeMatcher.scoreGroup(
        mine: myVibes,
        others: members,
      );

      _matchCache[cacheKey] = result;
      _memberMatchCache[cacheKey] = {
        for (final memberResult in result.memberResults)
          memberResult.member.id: memberResult,
      };
      _cacheTimestamps[cacheKey] = _now();
    } catch (error) {
      AppLog.d('❌ GroupVibeProvider.ensureGroupVibeMatch error: $error');
      _matchCache.remove(cacheKey);
      _memberMatchCache[cacheKey] = const <String, GroupVibeMemberResult>{};
      _cacheTimestamps.remove(cacheKey);
    } finally {
      _loadingKeys.remove(cacheKey);
      _scheduleNotify();
    }
  }

  void invalidateCacheKey(String cacheKey) {
    _matchCache.remove(cacheKey);
    _memberMatchCache.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);
    _loadingKeys.remove(cacheKey);
    _scheduleNotify();
  }

  void invalidateGame(String gameId) {
    final keysToRemove = _matchCache.keys
        .where((key) => key.startsWith('$gameId:'))
        .toList(growable: false);
    for (final key in keysToRemove) {
      _matchCache.remove(key);
      _memberMatchCache.remove(key);
      _cacheTimestamps.remove(key);
      _loadingKeys.remove(key);
    }
    if (keysToRemove.isNotEmpty) {
      _scheduleNotify();
    }
  }

  void clearCache() {
    _matchCache.clear();
    _memberMatchCache.clear();
    _cacheTimestamps.clear();
    _loadingKeys.clear();
    _scheduleNotify();
  }

  void _scheduleNotify() {
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 100), () {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _notifyTimer?.cancel();
    super.dispose();
  }
}
