import '/models/game.dart';
import '/models/player_eligibility.dart';

/// Immutable metadata derived from the current games snapshot.
/// Computed once per build to avoid repeated state mutations.
class GameFilterMeta {
  final Set<String> availableGameTypes;
  final Set<String> availableVibes;
  final Set<String> availableStakes;
  final Set<String> availableHandicaps;
  final Set<String> availableCourses;
  final Set<String> availableEligibilities;

  const GameFilterMeta({
    required this.availableGameTypes,
    required this.availableVibes,
    required this.availableStakes,
    required this.availableHandicaps,
    required this.availableCourses,
    required this.availableEligibilities,
  });

  /// Creates an empty filter metadata instance.
  const GameFilterMeta.empty()
      : availableGameTypes = const {},
        availableVibes = const {},
        availableStakes = const {},
        availableHandicaps = const {},
        availableCourses = const {},
        availableEligibilities = const {};

  factory GameFilterMeta.fromGames(
    List<Game> games,
    String? Function(Game) gameTypeExtractor,
    String? Function(Game) vibeExtractor,
    String? Function(Game) stakesExtractor,
    String? Function(Game) handicapExtractor,
  ) {
    final types = <String>{};
    final vibes = <String>{};
    final stakes = <String>{};
    final handicaps = <String>{};
    final courses = <String>{};
    final eligibilities = <String>{};

    for (final game in games) {
      final type = gameTypeExtractor(game);
      if (type != null) types.add(type);

      final vibe = vibeExtractor(game);
      if (vibe != null) vibes.add(vibe);

      final stake = stakesExtractor(game);
      if (stake != null) stakes.add(stake);

      final handicap = handicapExtractor(game);
      if (handicap != null) handicaps.add(handicap);

      final course = game.coursePlay.trim();
      if (course.isNotEmpty) courses.add(course);

      // Extract eligibility value
      eligibilities.add(game.playerEligibility.toFirestoreValue());
    }

    return GameFilterMeta(
      availableGameTypes: types,
      availableVibes: vibes,
      availableStakes: stakes,
      availableHandicaps: handicaps,
      availableCourses: courses,
      availableEligibilities: eligibilities,
    );
  }
}
