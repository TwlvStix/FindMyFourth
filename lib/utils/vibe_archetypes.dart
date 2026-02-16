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
    this.baseArchetype,
    this.isWarden = false,
  });

  final VibeArchetype archetype;
  final double score;

  /// The underlying archetype before the Warden modifier was applied.
  /// Null if this is not a Warden.
  final VibeArchetype? baseArchetype;

  /// True if this player triggered the Warden modifier (2+ dealbreakers).
  final bool isWarden;

  String get name => archetype.name;
  String get description => archetype.description;

  /// Returns the display name with optional base archetype.
  /// e.g. "The Warden" or "The Warden (Shark)"
  String get displayName {
    if (!isWarden || baseArchetype == null) return name;
    return '$name (${baseArchetype!.name})';
  }

  /// Returns just the base archetype name for subtitle use.
  /// e.g. "Shark at heart" or null if not a Warden.
  String? get baseLabel {
    if (!isWarden || baseArchetype == null) return null;
    return '${baseArchetype!.name} at heart';
  }
}

/// The 12 vibe style archetypes + The Warden modifier
/// Note: Values in ideal profiles use 0-5 range (code values)
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
        'Do not mistake the silence for not caring. Takes their time, reads every putt, and might be quietly taking your money without saying a word. You will figure it out on 18. Let them play their game \u2014 you can talk after.',
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

  /// The Warden is not a value-based archetype — it is a modifier
  /// applied when a player has 2+ dealbreakers. The ideal values
  /// are unused for classification; only the name and description matter.
  static const warden = VibeArchetype(
    name: 'The Warden',
    description:
        'I know exactly what I want and what I will not put up with. Cross the line and you will know about it before the turn.',
    ideal: {},
  );

  /// Minimum number of dealbreakers to trigger the Warden modifier.
  static const int wardenDealbreakerThreshold = 2;

  /// The base archetypes used for value-based classification.
  /// The Warden is excluded — it is applied as a modifier, not matched on values.
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

  /// Classifies a vibe profile and returns the best-matching archetype.
  ///
  /// Step 1: Find the closest base archetype using Euclidean distance.
  /// Step 2: If the player has 2+ dealbreakers, apply the Warden modifier.
  /// Step 3: Store the base archetype so the UI can show "The Warden (Shark)".
  static VibeArchetypeMatch classifyProfile(VibeProfile profile) {
    // Step 1: classify on values
    final baseMatch = _classifyByValues(profile);

    // Step 2: count dealbreakers
    final dealbreakerCount = VibeCategory.values
        .where((c) => profile.preferenceFor(c).dealbreaker)
        .length;

    // Step 3: if 2+ dealbreakers, override to Warden
    if (dealbreakerCount >= wardenDealbreakerThreshold) {
      return VibeArchetypeMatch(
        archetype: warden,
        score: baseMatch.score,
        baseArchetype: baseMatch.archetype,
        isWarden: true,
      );
    }

    return baseMatch;
  }

  /// Pure value-based classification using Euclidean distance.
  static VibeArchetypeMatch _classifyByValues(VibeProfile profile) {
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

      distance = math.sqrt(distance);

      if (distance < bestDistance) {
        bestDistance = distance;
        bestMatch = archetype;
      }
    }

    // Convert distance to a 0-100 compatibility score
    // Max possible distance is sqrt(6 * 5^2) = sqrt(150)
    final maxPossibleDistance = math.sqrt(6 * 25.0);
    final compatibilityScore =
        100 * (1 - (bestDistance / maxPossibleDistance)).clamp(0.0, 1.0);

    return bestMatch!.withScore(compatibilityScore);
  }
}
