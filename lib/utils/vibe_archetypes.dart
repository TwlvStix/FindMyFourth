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

/// Represents a single elimination gate requirement.
/// A category must be in the LOW (0-2) or HIGH (3-5) range to pass.
class _Gate {
  const _Gate(this.category, this.mustBeHigh);
  final VibeCategory category;
  final bool mustBeHigh; // true = must be 3-5, false = must be 0-2
}

/// The 12 vibe style archetypes + The Warden modifier
///
/// Classification uses Approach 3: Elimination Gates + Weighted Distance
/// Step 1: Eliminate archetypes whose defining categories don't match
/// Step 2: Weighted Euclidean distance on survivors (defining cats = 3x weight)
/// Step 3: Fallback to Everyman if nothing passes gates
///
/// Note: Values in ideal profiles use 0-5 range (code values)
class VibeArchetypes {
  static const grinder = VibeArchetype(
    name: 'The Grinder',
    description:
        'Fast pace, fierce competition, zero distractions. You don\'t talk on my backswing because I don\'t talk on yours.',
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
        'I play fast, I compete hard, and I\'ll talk trash the entire round. I\'ll buy you a beer after I take your money.',
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
        'I play fast and I take the game seriously. No speakers, no bets, no distractions. Just me and the course. That\'s enough.',
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
        'Don\'t mistake my silence for not caring. I take my time, I read every putt, and I\'m competing whether you know it or not. You\'ll figure it out on 18.',
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
        'I\'ve got no agenda, no pressure, no rush. I take in every hole like it\'s the first time. My scorecard\'s in the cart somewhere, probably.',
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
        'I don\'t know what I shot but I know everyone had a good time. The music was right, the drinks were flowing, and the conversation never stopped.',
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
        'I want it all. Skins on the front, nassau on the back, speaker\'s blasting, beer\'s cold, and I\'m still trying to birdie every hole. Why choose?',
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
        'I\'m down for whatever the group wants. A little of everything, nothing too much. I\'m the guy every foursome wants on the text chain.',
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
        'I play fast and there\'s always money on it. I\'ve already done the math on the bet before we reach the first tee. You\'ll figure out the damage on 18.',
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
        'I\'m not here to compete or bet. Good company and the perfect playlist — that\'s my round. My speaker goes in the cart before the clubs do.',
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
        'Big bets, big energy, drinks are flowing, and I\'m competing on every hole. If there\'s nothing on the line, what are we even doing out here?',
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
        'I know the starter by name and I can find you a fourth in ten minutes. The round\'s about the people, not the scorecard.',
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
        'I know exactly what I want and what I won\'t put up with. Cross the line and you\'ll know about it before the turn.',
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

  // ---------------------------------------------------------------------------
  // Elimination Gates
  // ---------------------------------------------------------------------------
  // Each archetype has defining categories that MUST be in range.
  // HIGH = code value 3-5, LOW = code value 0-2.
  // If any gate fails, the archetype is disqualified.
  // ---------------------------------------------------------------------------

  static const Map<String, List<_Gate>> _eliminationGates = {
    'The Grinder': [
      _Gate(VibeCategory.competitive, true), // must be HIGH
      _Gate(VibeCategory.money, true), // must be HIGH
      _Gate(VibeCategory.chat, false), // must be LOW
      _Gate(VibeCategory.drinking, false), // must be LOW
    ],
    'The Shark': [
      _Gate(VibeCategory.competitive, true), // must be HIGH
      _Gate(VibeCategory.money, true), // must be HIGH
      _Gate(VibeCategory.chat, true), // must be HIGH
      _Gate(VibeCategory.pace, true), // must be HIGH
    ],
    'The Purist': [
      _Gate(VibeCategory.pace, true), // must be HIGH
      _Gate(VibeCategory.music, false), // must be LOW
      _Gate(VibeCategory.money, false), // must be LOW
      _Gate(VibeCategory.drinking, false), // must be LOW
    ],
    'The Ghost': [
      _Gate(VibeCategory.chat, false), // must be LOW
      _Gate(VibeCategory.drinking, false), // must be LOW
      _Gate(VibeCategory.music, false), // must be LOW
    ],
    'The Tourist': [
      _Gate(VibeCategory.pace, false), // must be LOW
      _Gate(VibeCategory.competitive, false), // must be LOW
      _Gate(VibeCategory.money, false), // must be LOW
    ],
    'The Vibe King': [
      _Gate(VibeCategory.chat, true), // must be HIGH
      _Gate(VibeCategory.drinking, true), // must be HIGH
      _Gate(VibeCategory.music, true), // must be HIGH
    ],
    'The Juggernaut': [
      _Gate(VibeCategory.competitive, true), // must be HIGH
      _Gate(VibeCategory.money, true), // must be HIGH
      _Gate(VibeCategory.drinking, true), // must be HIGH
      _Gate(VibeCategory.music, true), // must be HIGH
    ],
    'The Everyman': [], // Special handling: no value above 4 or below 1
    'The Hustler': [
      _Gate(VibeCategory.pace, true), // must be HIGH
      _Gate(VibeCategory.money, true), // must be HIGH
      _Gate(VibeCategory.music, false), // must be LOW
    ],
    'The DJ': [
      _Gate(VibeCategory.music, true), // must be HIGH
      _Gate(VibeCategory.competitive, false), // must be LOW
      _Gate(VibeCategory.money, false), // must be LOW
    ],
    'The High Roller': [
      _Gate(VibeCategory.competitive, true), // must be HIGH
      _Gate(VibeCategory.money, true), // must be HIGH
      _Gate(VibeCategory.chat, true), // must be HIGH
      _Gate(VibeCategory.drinking, true), // must be HIGH
    ],
    'The Mayor': [
      _Gate(VibeCategory.chat, true), // must be HIGH
      _Gate(VibeCategory.competitive, false), // must be LOW
      _Gate(VibeCategory.money, false), // must be LOW
    ],
  };

  // ---------------------------------------------------------------------------
  // Defining Categories (for 3x weighting in distance calculation)
  // ---------------------------------------------------------------------------
  // These are the categories that DEFINE each archetype's identity.
  // They get 3x weight in the Euclidean distance. Non-defining get 1x.
  // ---------------------------------------------------------------------------

  static const Map<String, Set<VibeCategory>> _definingCategories = {
    'The Grinder': {
      VibeCategory.pace,
      VibeCategory.competitive,
      VibeCategory.money,
      VibeCategory.chat,
    },
    'The Shark': {
      VibeCategory.pace,
      VibeCategory.competitive,
      VibeCategory.money,
      VibeCategory.chat,
    },
    'The Purist': {
      VibeCategory.pace,
      VibeCategory.money,
      VibeCategory.music,
      VibeCategory.drinking,
    },
    'The Ghost': {
      VibeCategory.chat,
      VibeCategory.drinking,
      VibeCategory.music,
    },
    'The Tourist': {
      VibeCategory.pace,
      VibeCategory.competitive,
      VibeCategory.money,
    },
    'The Vibe King': {
      VibeCategory.chat,
      VibeCategory.drinking,
      VibeCategory.music,
    },
    'The Juggernaut': {
      VibeCategory.competitive,
      VibeCategory.money,
      VibeCategory.drinking,
      VibeCategory.music,
    },
    'The Everyman': <VibeCategory>{}, // All weighted equally
    'The Hustler': {
      VibeCategory.pace,
      VibeCategory.money,
      VibeCategory.music,
    },
    'The DJ': {
      VibeCategory.music,
      VibeCategory.competitive,
      VibeCategory.money,
    },
    'The High Roller': {
      VibeCategory.competitive,
      VibeCategory.money,
      VibeCategory.chat,
      VibeCategory.drinking,
    },
    'The Mayor': {
      VibeCategory.chat,
      VibeCategory.competitive,
      VibeCategory.money,
    },
  };

  /// Classifies a vibe profile and returns the best-matching archetype.
  ///
  /// Step 1: Find the closest base archetype using Approach 3
  ///         (Elimination Gates + Weighted Euclidean Distance).
  /// Step 2: If the player has 2+ dealbreakers, apply the Warden modifier.
  /// Step 3: Store the base archetype so the UI can show "The Warden (Shark)".
  static VibeArchetypeMatch classifyProfile(VibeProfile profile) {
    // Step 1: classify on values using gates + weighted distance
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

  /// Checks if a profile passes all elimination gates for an archetype.
  /// LOW = 0-2, HIGH = 3-5.
  static bool _passesGates(
    VibeArchetype archetype,
    Map<VibeCategory, int> userValues,
  ) {
    // Special handling for The Everyman: no value above 4 or below 1
    if (archetype.name == 'The Everyman') {
      for (final category in VibeCategory.values) {
        final value = userValues[category] ?? 0;
        if (value > 4 || value < 1) return false;
      }
      return true;
    }

    final gates = _eliminationGates[archetype.name];
    if (gates == null || gates.isEmpty) return true;

    for (final gate in gates) {
      final value = userValues[gate.category] ?? 0;
      if (gate.mustBeHigh) {
        // Must be HIGH: 3-5
        if (value < 3) return false;
      } else {
        // Must be LOW: 0-2
        if (value > 2) return false;
      }
    }
    return true;
  }

  /// Approach 3 classification:
  /// 1. Filter archetypes through elimination gates
  /// 2. Weighted Euclidean distance on survivors (defining categories = 3x)
  /// 3. Fallback to Everyman if all archetypes are eliminated
  static VibeArchetypeMatch _classifyByValues(VibeProfile profile) {
    // Build user profile map
    final userValues = <VibeCategory, int>{};
    for (final category in VibeCategory.values) {
      userValues[category] = profile.preferenceFor(category).value;
    }

    // Step 1: Filter through elimination gates
    final eligible = <VibeArchetype>[];
    for (final archetype in all) {
      if (_passesGates(archetype, userValues)) {
        eligible.add(archetype);
      }
    }

    // Step 3: Fallback — if nothing passes, use Everyman
    if (eligible.isEmpty) {
      eligible.add(everyman);
    }

    // Step 2: Weighted Euclidean distance on eligible archetypes
    VibeArchetype? bestMatch;
    double bestDistance = double.infinity;

    for (final archetype in eligible) {
      final definingCats = _definingCategories[archetype.name] ?? {};
      double distance = 0.0;

      for (final category in VibeCategory.values) {
        final userValue = userValues[category] ?? 0;
        final idealValue = archetype.ideal[category] ?? 0;
        final diff = userValue - idealValue;
        final weight = definingCats.contains(category) ? 3.0 : 1.0;
        distance += weight * diff * diff;
      }

      distance = math.sqrt(distance);

      if (distance < bestDistance) {
        bestDistance = distance;
        bestMatch = archetype;
      }
    }

    // Convert distance to a 0-100 compatibility score.
    // Calculate max distance based on the winning archetype's actual weights.
    // Defining categories use 3x weight, non-defining use 1x.
    // Max diff per category is 5 (0 vs 5), so max squared diff is 25.
    final bestDefiningCats = _definingCategories[bestMatch!.name] ?? {};
    final definingCount = bestDefiningCats.length;
    final nonDefiningCount = VibeCategory.values.length - definingCount;
    final maxPossibleDistance = math.sqrt(
      (definingCount * 3.0 * 25.0) + (nonDefiningCount * 1.0 * 25.0),
    );
    final compatibilityScore =
        100 * (1 - (bestDistance / maxPossibleDistance)).clamp(0.0, 1.0);

    return bestMatch.withScore(compatibilityScore);
  }
}
