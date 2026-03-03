import 'package:cloud_firestore/cloud_firestore.dart';

import '/main_function/games_list/components/game_list_filter_bottom_sheet.dart';
import '/main_function/games_list/utils/game_canonicalization.dart';
import '/main_function/games_list/utils/game_filtering.dart';
import '/models/game.dart';
import '/models/player_eligibility.dart';
import '/services/game_eligibility_service.dart';

/// Filters games to only include active ones (not expired/completed).
///
/// Cancelled games are delegated to [shouldHideCancelledGame] callback.
List<Game> filterActiveGames(
  List<Game> games, {
  required bool Function(Game) shouldHideCancelledGame,
}) {
  return games.where((game) {
    // Always hide expired and completed games
    if (game.status == 'expired' || game.status == 'completed') {
      return false;
    }

    // For cancelled games, check user preference via callback
    if (game.status == 'cancelled') {
      return !shouldHideCancelledGame(game);
    }

    // Show active games
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

/// Result of partitioning games into joinable and locked lists.
class PartitionedGames {
  final List<Game> joinable;
  final List<Game> locked;

  const PartitionedGames({required this.joinable, required this.locked});
}

/// Partitions games into joinable and locked (friends-only) lists.
///
/// A game is joinable if:
/// - User is already a participant
/// - Game is public
/// - Game is friends-only AND user is friends with owner
PartitionedGames partitionJoinableAndLockedGames(
  List<Game> games, {
  required DocumentReference? currentUserReference,
  required Set<String> friendIds,
}) {
  final joinable = <Game>[];
  final locked = <Game>[];

  for (final game in games) {
    if (isJoinableGame(game, currentUserReference, friendIds)) {
      joinable.add(game);
    } else if (isFriendsOnlyGame(game)) {
      locked.add(game);
    } else {
      joinable.add(game);
    }
  }

  return PartitionedGames(joinable: joinable, locked: locked);
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
