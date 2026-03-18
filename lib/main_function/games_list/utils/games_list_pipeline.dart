import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/utils/geo_utils.dart';
import '/main_function/games_list/components/game_list_filter_bottom_sheet.dart';
import '/main_function/games_list/utils/game_canonicalization.dart';
import '/main_function/games_list/utils/game_filtering.dart';
import '/models/game.dart';
import '/models/player_eligibility.dart';
import '/services/game_eligibility_service.dart';

/// Filters games to only include active ones.
///
/// Removes expired, completed, played, and cancelled games.
List<Game> filterActiveGames(List<Game> games) {
  return games.where((game) {
    if (game.status == 'expired' ||
        game.status == 'completed' ||
        game.status == 'played' ||
        game.status == 'cancelled') {
      return false;
    }
    return true;
  }).toList();
}

/// Applies user-selected filters to a game list.
///
/// Filters by game type, vibe, stakes, handicap, course, eligibility, and date range.
List<Game> applyGameListFilters(List<Game> games, GameListFilters filters) {
  return games.where((game) {
    if (filters.selectedGameTypes.isNotEmpty) {
      final gameType = gameTypeForFilters(game);
      if (gameType == null || !filters.selectedGameTypes.contains(gameType)) {
        return false;
      }
    }
    if (filters.selectedVibes.isNotEmpty) {
      final vibe = vibeForFilters(game);
      if (vibe == null || !filters.selectedVibes.contains(vibe)) {
        return false;
      }
    }
    if (filters.selectedStakes.isNotEmpty) {
      final stakes = stakesForFilters(game);
      if (stakes == null || !filters.selectedStakes.contains(stakes)) {
        return false;
      }
    }
    if (filters.selectedHandicaps.isNotEmpty) {
      final handicap = handicapForFilters(game);
      if (handicap == null || !filters.selectedHandicaps.contains(handicap)) {
        return false;
      }
    }
    if (filters.selectedCourse != null &&
        filters.selectedCourse!.trim().isNotEmpty) {
      if (game.coursePlay.trim() != filters.selectedCourse!.trim()) {
        return false;
      }
    }
    if (filters.selectedEligibility.isNotEmpty) {
      final eligibility = game.playerEligibility.toFirestoreValue();
      if (!filters.selectedEligibility.contains(eligibility)) {
        return false;
      }
    }
    if (!matchesDateRange(game.date, filters.selectedDateRange)) {
      return false;
    }
    return true;
  }).toList();
}

/// Filters games to those within [radiusKm] of the given center.
/// Games without coordinates are KEPT (don't penalize legacy data).
List<Game> applyGeoFilter(
  List<Game> games, {
  required double centerLat,
  required double centerLng,
  required double radiusKm,
}) {
  return games.where((game) {
    final lat = game.courseLat;
    final lng = game.courseLng;
    // Keep games without coordinates (legacy docs)
    if (lat == null || lng == null) return true;
    final distance = distanceKm(centerLat, centerLng, lat, lng);
    return distance <= radiusKm;
  }).toList();
}

/// Filters out games the user isn't eligible for based on gender restrictions.
///
/// Owner always sees their own games regardless of eligibility.
List<Game> filterEligibleGames(
  List<Game> games, {
  required DocumentReference? currentUserReference,
  required String? userGender,
}) {
  return games.where((game) {
    // Owner always sees their own games
    if (game.userRef == currentUserReference) {
      return true;
    }

    // Check gender eligibility
    final eligibilityResult = checkPlayerEligibility(
      eligibility: game.playerEligibility,
      userGender: userGender,
    );
    return eligibilityResult.allowed;
  }).toList();
}

/// Filters out games hosted by or containing blocked users.
List<Game> filterBlockedUserGames(List<Game> games, Set<String> blockedUserIds) {
  if (blockedUserIds.isEmpty) return games;
  return games.where((game) {
    final hostId = game.userRef?.id ?? game.uid;
    if (blockedUserIds.contains(hostId)) return false;
    for (final playerRef in game.joinedPlayers) {
      if (blockedUserIds.contains(playerRef.id)) return false;
    }
    return true;
  }).toList();
}

/// Result of partitioning games into joinable, mutual, and locked lists.
///
/// - [joinable]: Games the user can join directly (public or friends with host)
/// - [mutual]: Friends-only games where user has mutual friend with host
/// - [locked]: Friends-only games with no connection (hidden from feed)
class PartitionedGames {
  final List<Game> joinable;
  final List<Game> mutual;
  final List<Game> locked;

  const PartitionedGames({
    required this.joinable,
    required this.mutual,
    required this.locked,
  });
}

/// Partitions games into joinable, mutual, and locked lists.
///
/// A game is:
/// - [joinable]: User is a participant, game is public, or user is friends with host
/// - [mutual]: Friends-only AND user has mutual friend with host (not direct friend)
/// - [locked]: Friends-only with no connection (hidden from feed)
///
/// [mutualFriendHostIds] is the set of host UIDs that the user has mutual friends with.
PartitionedGames partitionJoinableAndLockedGames(
  List<Game> games, {
  required DocumentReference? currentUserReference,
  required Set<String> friendIds,
  Set<String> mutualFriendHostIds = const {},
}) {
  final joinable = <Game>[];
  final mutual = <Game>[];
  final locked = <Game>[];

  for (final game in games) {
    if (isJoinableGame(game, currentUserReference, friendIds)) {
      // User can join: participant, public, or friend of host
      joinable.add(game);
    } else if (isFriendsOnlyGame(game)) {
      // Friends-only game where user is NOT a direct friend
      final hostId = game.userRef?.id ?? game.uid;
      if (mutualFriendHostIds.contains(hostId)) {
        // Has mutual friend - show amber card
        mutual.add(game);
      } else {
        // No connection - hidden from feed
        locked.add(game);
      }
    } else {
      joinable.add(game);
    }
  }

  return PartitionedGames(joinable: joinable, mutual: mutual, locked: locked);
}

/// Result of splitting games into flexible and scheduled lists.
class SplitGames {
  final List<Game> flexible;
  final List<Game> scheduled;

  const SplitGames({required this.flexible, required this.scheduled});
}

/// Splits games into flexible and scheduled, then sorts each list.
///
/// - Scheduled games are sorted by date ascending (soonest first)
/// - Flexible games are sorted by joined player count descending (most players first)
SplitGames splitAndSortGames(List<Game> games) {
  final flexible = games.where((g) => g.isFlexible).toList();
  final scheduled = games.where((g) => !g.isFlexible).toList();

  // Sort scheduled by date ascending (soonest first)
  scheduled.sort((a, b) {
    final aDate = a.date;
    final bDate = b.date;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return aDate.compareTo(bDate);
  });

  // Sort flexible by readiness (most players first)
  flexible.sort(
    (a, b) => b.joinedPlayers.length.compareTo(a.joinedPlayers.length),
  );

  return SplitGames(flexible: flexible, scheduled: scheduled);
}
