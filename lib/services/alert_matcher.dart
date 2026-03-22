import '/models/alert_subscription.dart';
import '/models/game.dart';

/// Alert matching service
///
/// Implements the notification matching contract:
/// - Notifications are triggered by GAME CREATION, not by individual filters
/// - A user receives at most ONE notification per game
/// - OR across categories (any selected category match triggers)
/// - OR within a category (any one value matches)
/// - Empty category = match-all
class AlertMatcher {
  /// Check if an alert subscription matches a game
  ///
  /// Matching rules:
  /// 1. OR across categories: Any category the user selected matching triggers
  /// 2. OR within a category: If multiple values selected, any one match passes
  /// 3. Empty category = ignored: If category is empty, it doesn't participate
  /// 4. If enabled and all empty, user receives all game notifications
  static bool doesAlertSubMatchGame(
    AlertSubscription sub,
    Game game,
  ) {
    // If subscription is disabled, no match
    if (!sub.enabled) {
      return false;
    }

    // If all categories are empty, match all games
    if (!sub.hasActiveFilters) {
      return true;
    }

    // Check each category with OR logic across categories
    // (any non-empty category matching is enough)

    // 1. Game Vibe (rulesSetting)
    if (sub.gameVibes.isNotEmpty) {
      if (_matchesAny(sub.gameVibes, game.rulesSetting)) {
        return true;
      }
    }

    // 2. Stakes (styleGame)
    if (sub.stakes.isNotEmpty) {
      if (_matchesAny(sub.stakes, game.styleGame)) {
        return true;
      }
    }

    // 3. Format (gameType)
    if (sub.formats.isNotEmpty) {
      if (_matchesAny(sub.formats, game.gameType)) {
        return true;
      }
    }

    // 4. Handicap Use (scoring)
    if (sub.handicapUses.isNotEmpty) {
      if (_matchesAny(sub.handicapUses, game.scoring)) {
        return true;
      }
    }

    // 5. Course (courseRef ID)
    if (sub.courses.isNotEmpty) {
      final gameCourseId = game.courseRef?.id;
      if (gameCourseId != null && sub.courses.contains(gameCourseId)) {
        return true;
      }
    }

    // 6. Special options
    // Games: OFF = don't care, ON = match if game has side games
    if (sub.special.games && game.hasSideGames) {
      return true;
    }

    // 2v2: OFF = don't care, ON = match if game is 2v2
    if (sub.special.twoVTwo && game.is2v2) {
      return true;
    }

    // Discount: OFF = don't care, ON = match if game has member discount
    if (sub.special.discount && _hasMemberDiscount(game.memberDiscount)) {
      return true;
    }

    // No category matched
    return false;
  }

  /// Check if any value in the list matches the target
  /// Case-insensitive comparison
  static bool _matchesAny(List<String> values, String target) {
    if (target.isEmpty) {
      return false;
    }

    final targetLower = target.toLowerCase().trim();

    for (final value in values) {
      if (value.toLowerCase().trim() == targetLower) {
        return true;
      }
    }

    return false;
  }

  static bool _hasMemberDiscount(String memberDiscount) {
    final normalized = memberDiscount.trim().toLowerCase();
    return normalized == 'yes';
  }

  /// Get a debug string explaining the match result
  /// Useful for testing and debugging
  static String getMatchDebugInfo(
    AlertSubscription sub,
    Game game,
  ) {
    if (!sub.enabled) {
      return 'Subscription is disabled';
    }

    if (!sub.hasActiveFilters) {
      return 'No filters set - matches all games';
    }

    final matches = <String>[];
    final misses = <String>[];

    // Check each category
    if (sub.gameVibes.isNotEmpty) {
      if (_matchesAny(sub.gameVibes, game.rulesSetting)) {
        matches.add(
            'Game Vibe matched: [${sub.gameVibes.join(', ')}] contains "${game.rulesSetting}"');
      } else {
        misses.add(
            'Game Vibe: wanted [${sub.gameVibes.join(', ')}], got "${game.rulesSetting}"');
      }
    }

    if (sub.stakes.isNotEmpty) {
      if (_matchesAny(sub.stakes, game.styleGame)) {
        matches.add(
            'Stakes matched: [${sub.stakes.join(', ')}] contains "${game.styleGame}"');
      } else {
        misses.add(
            'Stakes: wanted [${sub.stakes.join(', ')}], got "${game.styleGame}"');
      }
    }

    if (sub.formats.isNotEmpty) {
      if (_matchesAny(sub.formats, game.gameType)) {
        matches.add(
            'Format matched: [${sub.formats.join(', ')}] contains "${game.gameType}"');
      } else {
        misses.add(
            'Format: wanted [${sub.formats.join(', ')}], got "${game.gameType}"');
      }
    }

    if (sub.handicapUses.isNotEmpty) {
      if (_matchesAny(sub.handicapUses, game.scoring)) {
        matches.add(
            'Handicap Use matched: [${sub.handicapUses.join(', ')}] contains "${game.scoring}"');
      } else {
        misses.add(
            'Handicap Use: wanted [${sub.handicapUses.join(', ')}], got "${game.scoring}"');
      }
    }

    if (sub.courses.isNotEmpty) {
      final gameCourseId = game.courseRef?.id;
      if (gameCourseId != null && sub.courses.contains(gameCourseId)) {
        matches.add('Course matched: "$gameCourseId"');
      } else {
        misses.add(
            'Course: wanted [${sub.courses.join(', ')}], got "${gameCourseId ?? 'none'}"');
      }
    }

    if (sub.special.games) {
      if (game.hasSideGames) {
        matches.add('Special matched: side games');
      } else {
        misses.add('Special: wanted side games');
      }
    }

    if (sub.special.twoVTwo) {
      if (game.is2v2) {
        matches.add('Special matched: 2v2');
      } else {
        misses.add('Special: wanted 2v2');
      }
    }

    if (sub.special.discount) {
      if (_hasMemberDiscount(game.memberDiscount)) {
        matches.add('Special matched: member discount');
      } else {
        misses.add('Special: wanted member discount');
      }
    }

    if (matches.isNotEmpty) {
      return 'Match successful (OR) - matched ${matches.length} category(s):\n${matches.map((m) => '  + $m').join('\n')}';
    }

    return 'Match failed - no categories matched:\n${misses.map((f) => '  - $f').join('\n')}';
  }
}
