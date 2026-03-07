import '/models/game.dart';

/// Quick filter options for the games list.
///
/// These filters provide fast, single-tap filtering of the game list.
/// Unlike the full filter bottom sheet, these are ephemeral UI state
/// that resets on navigation.
enum QuickFilter {
  all('All Games'),
  flexible('Flexible'),
  nearMe('Near Me'),
  thisWeekend('This Weekend');

  const QuickFilter(this.label);

  /// Display label for the filter chip
  final String label;

  /// Returns the emoji prefix for special filters (if any)
  String? get emoji {
    switch (this) {
      case QuickFilter.flexible:
        return '\u26A1'; // lightning bolt
      default:
        return null;
    }
  }

  /// Display label with emoji prefix (if applicable)
  String get displayLabel {
    final prefix = emoji;
    return prefix != null ? '$prefix $label' : label;
  }
}

/// Extension methods for applying quick filters to game lists.
extension QuickFilterExtension on QuickFilter {
  /// Applies this filter to a list of games.
  ///
  /// Returns the filtered list. Note that [nearMe] does not filter games
  /// and instead relies on separate sort handling via [GameSortOption].
  List<Game> apply(List<Game> games) {
    switch (this) {
      case QuickFilter.all:
        return games;

      case QuickFilter.flexible:
        return games.where((game) => game.isFlexible).toList();

      case QuickFilter.thisWeekend:
        return games.where((game) => _isThisWeekend(game)).toList();

      case QuickFilter.nearMe:
        // Near Me is a sort filter, not a predicate filter
        return games;
    }
  }

  /// Whether this filter modifies sort order rather than filtering games.
  bool get isSortFilter {
    return this == QuickFilter.nearMe;
  }
}

/// Checks if a game falls on this weekend (Saturday or Sunday).
bool _isThisWeekend(Game game) {
  if (game.isFlexible) {
    // For flexible games, check if weekend is in their availability
    final flexibleDays = game.flexibleDays;
    if (flexibleDays != null && flexibleDays.isNotEmpty) {
      // Dart weekday: Sunday=7 (or 0 in flexibleDays), Saturday=6
      // flexibleDays uses: 0=Sun, 1=Mon, ..., 6=Sat
      return flexibleDays.contains(0) || flexibleDays.contains(6);
    }
    // Also check flexibleWeek
    return game.flexibleWeek == 'this_weekend';
  } else {
    // For confirmed games, check if date is on Saturday or Sunday
    final date = game.date;
    if (date == null) return false;

    final now = DateTime.now();
    final saturday = _getThisSaturday(now);
    final sunday = saturday.add(const Duration(days: 1));

    return _isSameDay(date, saturday) || _isSameDay(date, sunday);
  }
}

/// Gets the Saturday of the current week.
DateTime _getThisSaturday(DateTime date) {
  // Dart weekday: Monday=1, Sunday=7
  final daysUntilSaturday = (DateTime.saturday - date.weekday) % 7;
  if (daysUntilSaturday == 0 && date.weekday != DateTime.saturday) {
    // It's before Saturday, go to next Saturday
    return DateTime(date.year, date.month, date.day + 7);
  }
  return DateTime(date.year, date.month, date.day + daysUntilSaturday);
}

/// Checks if two dates are the same day.
bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Sorting options for games list.
enum GameSortOption {
  soonest('Soonest'),
  topVibe('Top VIBE'),
  mostSpots('Most Spots');

  const GameSortOption(this.label);
  final String label;
}

/// Extension for sorting games.
extension GameSortExtension on GameSortOption {
  /// Sorts games according to this sort option.
  ///
  /// [vibeScores] is required for [topVibe] sorting - maps game reference ID
  /// to vibe match score (0-100).
  List<Game> sort(List<Game> games, {Map<String, double>? vibeScores}) {
    final sorted = List<Game>.from(games);

    switch (this) {
      case GameSortOption.soonest:
        sorted.sort((a, b) {
          // Flexible games go after confirmed games
          if (a.isFlexible != b.isFlexible) {
            return a.isFlexible ? 1 : -1;
          }
          // Sort confirmed games by date
          if (!a.isFlexible && !b.isFlexible) {
            final aDate = a.date;
            final bDate = b.date;
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return aDate.compareTo(bDate);
          }
          // Sort flexible games by player count (more players = more interest)
          return b.playerCount.compareTo(a.playerCount);
        });
        break;

      case GameSortOption.topVibe:
        if (vibeScores != null) {
          sorted.sort((a, b) {
            final aScore = vibeScores[a.reference.id] ?? 0.0;
            final bScore = vibeScores[b.reference.id] ?? 0.0;
            return bScore.compareTo(aScore); // Descending
          });
        }
        break;

      case GameSortOption.mostSpots:
        sorted.sort((a, b) {
          final aSpots = a.maxPlayers - a.playerCount;
          final bSpots = b.maxPlayers - b.playerCount;
          return bSpots.compareTo(aSpots); // Descending
        });
        break;
    }

    return sorted;
  }
}
