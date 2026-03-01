import '/models/alert_subscription.dart';
import '/models/game.dart';

/// Alert matching service
///
/// Implements the notification matching contract:
/// - Notifications are triggered by GAME CREATION, not by individual filters
/// - A user receives at most ONE notification per game
/// - AND across categories (all selected categories must match)
/// - OR within a category (any one value matches)
/// - Empty category = match-all
class AlertMatcher {
  /// Check if an alert subscription matches a game
  ///
  /// Matching rules:
  /// 1. AND across categories: Every category the user selected must match
  /// 2. OR within a category: If multiple values selected, any one match passes
  /// 3. Empty category = match-all: If category is empty, it doesn't restrict
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

    // Check each category with AND logic across categories
    // (all non-empty categories must match)

    // 1. Game Vibe (rulesSetting)
    if (sub.gameVibes.isNotEmpty) {
      if (!_matchesAny(sub.gameVibes, game.rulesSetting)) {
        return false; // This category doesn't match, fail immediately
      }
    }

    // 2. Stakes (styleGame)
    if (sub.stakes.isNotEmpty) {
      if (!_matchesAny(sub.stakes, game.styleGame)) {
        return false;
      }
    }

    // 3. Format (gameType)
    if (sub.formats.isNotEmpty) {
      if (!_matchesAny(sub.formats, game.gameType)) {
        return false;
      }
    }

    // 4. Handicap Use (scoring)
    if (sub.handicapUses.isNotEmpty) {
      if (!_matchesAny(sub.handicapUses, game.scoring)) {
        return false;
      }
    }

    // 5. Course (courseRef ID)
    if (sub.courses.isNotEmpty) {
      final gameCourseId = game.courseRef?.id;
      if (gameCourseId == null || !sub.courses.contains(gameCourseId)) {
        return false;
      }
    }

    // 6. Special options
    // Games: OFF = don't care, ON = game must have side games
    if (sub.special.games) {
      if (!game.hasSideGames) {
        return false;
      }
    }

    // 2v2: OFF = don't care, ON = game must be 2v2
    if (sub.special.twoVTwo) {
      if (!game.is2v2) {
        return false;
      }
    }

    // Discount: OFF = don't care, ON = game must have member discount
    if (sub.special.discount) {
      if (!_hasMemberDiscount(game.memberDiscount)) {
        return false;
      }
    }

    // All categories matched (or were empty)
    return true;
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

  /// Get a debug string explaining why a subscription didn't match
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

    final failures = <String>[];

    // Check each category
    if (sub.gameVibes.isNotEmpty &&
        !_matchesAny(sub.gameVibes, game.rulesSetting)) {
      failures.add(
          'Game Vibe mismatch: wanted [${sub.gameVibes.join(', ')}], got "${game.rulesSetting}"');
    }

    if (sub.stakes.isNotEmpty && !_matchesAny(sub.stakes, game.styleGame)) {
      failures.add(
          'Stakes mismatch: wanted [${sub.stakes.join(', ')}], got "${game.styleGame}"');
    }

    if (sub.formats.isNotEmpty && !_matchesAny(sub.formats, game.gameType)) {
      failures.add(
          'Format mismatch: wanted [${sub.formats.join(', ')}], got "${game.gameType}"');
    }

    if (sub.handicapUses.isNotEmpty &&
        !_matchesAny(sub.handicapUses, game.scoring)) {
      failures.add(
          'Handicap Use mismatch: wanted [${sub.handicapUses.join(', ')}], got "${game.scoring}"');
    }

    if (sub.courses.isNotEmpty) {
      final gameCourseId = game.courseRef?.id;
      if (gameCourseId == null) {
        failures.add('Course mismatch: game has no course set');
      } else if (!sub.courses.contains(gameCourseId)) {
        failures.add(
            'Course mismatch: wanted [${sub.courses.join(', ')}], got "$gameCourseId"');
      }
    }

    if (sub.special.games && !game.hasSideGames) {
      failures.add('Special mismatch: wanted side games');
    }

    if (sub.special.twoVTwo && !game.is2v2) {
      failures.add('Special mismatch: wanted 2v2');
    }

    if (sub.special.discount && !_hasMemberDiscount(game.memberDiscount)) {
      failures.add('Special mismatch: wanted member discount');
    }

    if (failures.isEmpty) {
      return 'Match successful - all filters passed';
    }

    return 'Match failed:\n${failures.map((f) => '  • $f').join('\n')}';
  }
}
