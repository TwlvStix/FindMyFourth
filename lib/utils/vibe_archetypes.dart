import '/models/vibe_profile.dart';
import 'dart:math' as math;

/// Represents a vibe style archetype with its ideal profile signature
class VibeArchetype {
  const VibeArchetype({
    required this.name,
    required this.description,
    required this.ideal,
  });

  final String name;
  final String description;
  final Map<VibeCategory, int> ideal;

  /// Creates a copy with a score
  VibeArchetypeMatch withScore(double score) {
    return VibeArchetypeMatch(
      archetype: this,
      score: score,
    );
  }
}

/// An archetype match result with a compatibility score
class VibeArchetypeMatch {
  const VibeArchetypeMatch({
    required this.archetype,
    required this.score,
  });

  final VibeArchetype archetype;
  final double score;

  String get name => archetype.name;
  String get description => archetype.description;
}

/// The 12 vibe style archetypes
/// Note: Values in ideal profiles use 0-5 range (code values)
/// Spec shows 1-6, so spec value 1 = code value 0, spec value 6 = code value 5
class VibeArchetypes {
  static const grinder = VibeArchetype(
    name: 'The Grinder',
    description:
        'Fast pace, high stakes, zero distractions. You do not talk on my backswing because I do not talk on yours.',
    ideal: {
      VibeCategory.pace: 5,
      VibeCategory.competitive: 5,
      VibeCategory.money: 5,
      VibeCategory.chat: 0,
      VibeCategory.drinking: 0,
      VibeCategory.music: 0,
    },
  );

  static const shark = VibeArchetype(
    name: 'The Shark',
    description:
        'I play fast, I compete hard, and I will talk trash the entire round. I will buy you a beer after I take your money.',
    ideal: {
      VibeCategory.pace: 5,
      VibeCategory.competitive: 5,
      VibeCategory.money: 5,
      VibeCategory.chat: 4,
      VibeCategory.drinking: 2,
      VibeCategory.music: 0,
    },
  );

  static const purist = VibeArchetype(
    name: 'The Purist',
    description:
        'I am first on the range and last to leave. No speakers, no bets, no distractions. Just me and the course. That is enough.',
    ideal: {
      VibeCategory.pace: 5,
      VibeCategory.competitive: 3,
      VibeCategory.money: 0,
      VibeCategory.chat: 0,
      VibeCategory.drinking: 0,
      VibeCategory.music: 0,
    },
  );

  static const ghost = VibeArchetype(
    name: 'The Ghost',
    description:
        'Do not mistake the silence for not caring. Takes their time, reads every putt, and might be quietly taking your money without saying a word. You will figure it out on 18. Let them play their game — you can talk after.',
    ideal: {
      VibeCategory.pace: 2,
      VibeCategory.competitive: 3,
      VibeCategory.money: 2,
      VibeCategory.chat: 0,
      VibeCategory.drinking: 0,
      VibeCategory.music: 0,
    },
  );

  static const tourist = VibeArchetype(
    name: 'The Tourist',
    description:
        'I have got no agenda, no pressure, no rush. I take in every hole like it is the first time. My scorecard is in the cart somewhere, probably.',
    ideal: {
      VibeCategory.pace: 0,
      VibeCategory.competitive: 0,
      VibeCategory.money: 0,
      VibeCategory.chat: 2,
      VibeCategory.drinking: 0,
      VibeCategory.music: 0,
    },
  );

  static const vibeKing = VibeArchetype(
    name: 'The Vibe King',
    description:
        'I do not know what I shot but I can tell you every song that played, every joke that landed, and what round I am buying at the turn.',
    ideal: {
      VibeCategory.pace: 1,
      VibeCategory.competitive: 0,
      VibeCategory.money: 0,
      VibeCategory.chat: 5,
      VibeCategory.drinking: 5,
      VibeCategory.music: 5,
    },
  );

  static const juggernaut = VibeArchetype(
    name: 'The Juggernaut',
    description:
        'I want it all. 2 dollar Vegas game, speaker is blasting, beer is cold, and I am still trying to birdie every hole. Why choose?',
    ideal: {
      VibeCategory.pace: 3,
      VibeCategory.competitive: 5,
      VibeCategory.money: 5,
      VibeCategory.chat: 5,
      VibeCategory.drinking: 5,
      VibeCategory.music: 5,
    },
  );

  static const everyman = VibeArchetype(
    name: 'The Everyman',
    description:
        'I am down for whatever the group wants. A couple bets, a couple beers, good conversation. I am the guy every foursome wants on the text chain.',
    ideal: {
      VibeCategory.pace: 2,
      VibeCategory.competitive: 2,
      VibeCategory.money: 2,
      VibeCategory.chat: 4,
      VibeCategory.drinking: 4,
      VibeCategory.music: 2,
    },
  );

  static const hustler = VibeArchetype(
    name: 'The Hustler',
    description:
        'I play fast and there is always money on it. I have already done the math on the bet before we reach the first tee. You will figure out the damage on 18.',
    ideal: {
      VibeCategory.pace: 5,
      VibeCategory.competitive: 3,
      VibeCategory.money: 5,
      VibeCategory.chat: 2,
      VibeCategory.drinking: 2,
      VibeCategory.music: 0,
    },
  );

  static const dj = VibeArchetype(
    name: 'The DJ',
    description:
        'I am not here to compete or bet. Just a cold drink, good company, and the perfect playlist. My speaker goes in the cart before the clubs do.',
    ideal: {
      VibeCategory.pace: 2,
      VibeCategory.competitive: 0,
      VibeCategory.money: 0,
      VibeCategory.chat: 2,
      VibeCategory.drinking: 2,
      VibeCategory.music: 5,
    },
  );

  static const highRoller = VibeArchetype(
    name: 'The High Roller',
    description:
        'Big bets, big energy, drinks are flowing, and I am competing on every hole. If there is nothing on the line, what are we even doing out here?',
    ideal: {
      VibeCategory.pace: 3,
      VibeCategory.competitive: 5,
      VibeCategory.money: 5,
      VibeCategory.chat: 5,
      VibeCategory.drinking: 4,
      VibeCategory.music: 2,
    },
  );

  static const mayor = VibeArchetype(
    name: 'The Mayor',
    description:
        'I know the starter by name, the cart girl already has my order ready, and I can find you a fourth in ten minutes. The round is about the people, not the scorecard.',
    ideal: {
      VibeCategory.pace: 2,
      VibeCategory.competitive: 0,
      VibeCategory.money: 0,
      VibeCategory.chat: 5,
      VibeCategory.drinking: 4,
      VibeCategory.music: 0,
    },
  );

  static const all = [
    grinder,
    shark,
    purist,
    ghost,
    tourist,
    vibeKing,
    juggernaut,
    everyman,
    hustler,
    dj,
    highRoller,
    mayor,
  ];

  /// Classifies a vibe profile and returns the best-matching archetype
  ///
  /// Uses Euclidean distance to find the closest archetype to the user's profile.
  /// Lower distance = better match.
  static VibeArchetypeMatch classifyProfile(VibeProfile profile) {
    VibeArchetype? bestMatch;
    double bestDistance = double.infinity;

    for (final archetype in all) {
      double distance = 0.0;

      for (final category in VibeCategory.values) {
        final userValue = profile.preferenceFor(category).value;
        final idealValue = archetype.ideal[category] ?? 0;
        final diff = userValue - idealValue;
        distance += diff * diff;
      }

      // Take square root to get actual Euclidean distance
      distance = math.sqrt(distance);

      if (distance < bestDistance) {
        bestDistance = distance;
        bestMatch = archetype;
      }
    }

    // Convert distance to a 0-100 compatibility score
    // Max possible distance is sqrt(6 * 5^2) = sqrt(150) ≈ 12.25
    // We'll map 0 distance to 100 score, and max distance to 0 score
    final maxPossibleDistance = math.sqrt(6 * 25.0); // sqrt(150)
    final compatibilityScore =
        100 * (1 - (bestDistance / maxPossibleDistance)).clamp(0.0, 1.0);

    return bestMatch!.withScore(compatibilityScore);
  }
}
