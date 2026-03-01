import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/users_record.dart';
import '/main_function/games_list/components/game_list_filter_bottom_sheet.dart';
import '/models/game.dart';

/// Checks if two dates are on the same calendar day.
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Checks if a game date matches the selected date range filter.
///
/// Returns true for [GameDateRange.any] regardless of game date.
/// Returns false if [gameDate] is null and range is not [GameDateRange.any].
bool matchesDateRange(DateTime? gameDate, GameDateRange range) {
  if (range == GameDateRange.any) {
    return true;
  }
  if (gameDate == null) {
    return false;
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final gameDay = DateTime(gameDate.year, gameDate.month, gameDate.day);
  switch (range) {
    case GameDateRange.today:
      return isSameDay(gameDay, today);
    case GameDateRange.tomorrow:
      return isSameDay(gameDay, today.add(Duration(days: 1)));
    case GameDateRange.next7Days:
      final end = today.add(Duration(days: 7));
      return !gameDay.isBefore(today) && !gameDay.isAfter(end);
    case GameDateRange.any:
      return true;
  }
}

/// Checks if a game is publicly visible (not friends-only).
bool isPublicGame(Game game) {
  final value = game.friendGame.trim().toLowerCase();
  return value.isEmpty || value == 'public';
}

/// Checks if a game is friends-only.
bool isFriendsOnlyGame(Game game) {
  return game.friendGame.trim().toLowerCase() == 'friends';
}

/// Extracts friend IDs from a user record as a Set.
///
/// Returns an empty set if the record is null or has no friends.
Set<String> friendIdsFromRecord(UsersRecord? record) {
  final friends = record?.friends ?? const <DocumentReference>[];
  final ids = <String>{};
  for (final entry in friends) {
    ids.add(entry.id);
  }
  return ids;
}

/// Checks if the current user is a participant in the game.
///
/// Returns true if the user is either the owner or has joined the game.
bool isUserGame(Game game, DocumentReference? currentUserReference) {
  return currentUserReference != null &&
      (game.userRef == currentUserReference ||
          game.joinedPlayers.contains(currentUserReference));
}

/// Checks if a game is joinable by the current user.
///
/// A game is joinable if:
/// - The user is already a participant (owner or joined)
/// - The game is public
/// - The game is friends-only AND the user is friends with the owner
bool isJoinableGame(
  Game game,
  DocumentReference? currentUserReference,
  Set<String> friendIds,
) {
  if (isUserGame(game, currentUserReference)) {
    return true;
  }
  if (isPublicGame(game)) {
    return true;
  }
  if (isFriendsOnlyGame(game)) {
    final ownerRef = game.userRef;
    if (ownerRef == null) {
      return false;
    }
    return friendIds.contains(ownerRef.id) || friendIds.contains(game.uid);
  }
  return true;
}
