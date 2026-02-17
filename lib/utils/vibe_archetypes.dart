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
        'Fast pace, high stakes, zero distractions. You don\'t talk on my backswing because I don\'t talk on yours.',
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
        'I\'m first on the range and last to leave. No speakers, no bets, no distractions. Just me and the course. That\'s enough.',
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
        'Don\'t mistake my silence for not caring. I take my time, I read every putt, and I might be quietly taking your money. You\'ll figure it out on 18.',
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
        'I don\'t know what I shot but I can tell you every song that played, every joke that landed, and what round I\'m buying at the turn.',
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
        'I\'m down for whatever the group wants. A couple bets, a couple beers, good conversation. I\'m the guy every foursome wants on the text chain.',
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
        'I play fast and there\'s always money on it. I\'ve already done the math on the bet before we reach the first tee.',
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
        'I\'m not here to compete or bet. Just a cold drink, good company, and the perfect playlist. My speaker goes in the cart before the clubs do.',
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
        'I know the starter by name, the cart girl already has my order ready, and I can find you a fourth in ten minutes. The round\'s about the people, not the scorecard.',
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

  /// Returns true if value is in the LOW range (0-2).
  static bool _isLow(int value) => value >= 0 && value <= 2;

  /// Returns true if value is in the HIGH range (3-5).
  static bool _isHigh(int value) => value >= 3 && value <= 5;

  /// Elimination gates per archetype.
  /// A profile must pass all gates to be eligible for classification as that archetype.
  static final Map<String, bool Function(Map<VibeCategory, int>)>
      _eliminationGates = {
    'The Grinder': (v) =>
        _isHigh(v[VibeCategory.competitive]!) &&
        _isHigh(v[VibeCategory.money]!) &&
        _isLow(v[VibeCategory.chat]!) &&
        _isLow(v[VibeCategory.drinking]!),
    'The Shark': (v) =>
        _isHigh(v[VibeCategory.competitive]!) &&
        _isHigh(v[VibeCategory.money]!) &&
        _isHigh(v[VibeCategory.chat]!) &&
        _isHigh(v[VibeCategory.pace]!),
    'The Purist': (v) =>
        _isHigh(v[VibeCategory.pace]!) &&
        _isLow(v[VibeCategory.music]!) &&
        _isLow(v[VibeCategory.money]!) &&
        _isLow(v[VibeCategory.drinking]!),
    'The Ghost': (v) =>
        _isLow(v[VibeCategory.chat]!) &&
        _isLow(v[VibeCategory.drinking]!) &&
        _isLow(v[VibeCategory.music]!),
    'The Tourist': (v) =>
        _isLow(v[VibeCategory.pace]!) &&
        _isLow(v[VibeCategory.competitive]!) &&
        _isLow(v[VibeCategory.money]!),
    'The Vibe King': (v) =>
        _isHigh(v[VibeCategory.chat]!) &&
        _isHigh(v[VibeCategory.drinking]!) &&
        _isHigh(v[VibeCategory.music]!),
    'The Juggernaut': (v) =>
        _isHigh(v[VibeCategory.competitive]!) &&
        _isHigh(v[VibeCategory.money]!) &&
        _isHigh(v[VibeCategory.drinking]!) &&
        _isHigh(v[VibeCategory.music]!),
    'The Everyman': (v) {
      for (final value in v.values) {
        if (value > 4 || value < 1) return false;
      }
      return true;
    },
    'The Hustler': (v) =>
        _isHigh(v[VibeCategory.pace]!) &&
        _isHigh(v[VibeCategory.money]!) &&
        _isLow(v[VibeCategory.music]!),
    'The DJ': (v) =>
        _isHigh(v[VibeCategory.music]!) &&
        _isLow(v[VibeCategory.competitive]!) &&
        _isLow(v[VibeCategory.money]!),
    'The High Roller': (v) =>
        _isHigh(v[VibeCategory.competitive]!) &&
        _isHigh(v[VibeCategory.money]!) &&
        _isHigh(v[VibeCategory.chat]!) &&
        _isHigh(v[VibeCategory.drinking]!),
    'The Mayor': (v) =>
        _isHigh(v[VibeCategory.chat]!) &&
        _isLow(v[VibeCategory.competitive]!) &&
        _isLow(v[VibeCategory.money]!),
  };

  /// Defining categories per archetype — these receive 3x weight in distance calculation.
  /// Non-defining categories receive 1x weight.
  /// The Everyman has no defining categories (all 1x).
  static final Map<String, Set<VibeCategory>> _definingCategories = {
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
    'The Everyman': {},
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
  /// Step 1: Filter archetypes using elimination gates (defining categories must be in range).
  /// Step 2: Calculate weighted Euclidean distance for eligible archetypes (3x weight on defining categories).
  /// Step 3: Fallback to The Everyman if all archetypes are eliminated.
  /// Step 4: If the player has 2+ dealbreakers, apply the Warden modifier.
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

  /// Pure value-based classification using elimination gates + weighted Euclidean distance.
  ///
  /// Step 1: Filter archetypes through elimination gates — archetypes whose defining
  ///         categories are not in the required HIGH/LOW range are disqualified.
  /// Step 2: Among eligible archetypes, calculate weighted distance (3x on defining categories).
  /// Step 3: If all archetypes are eliminated, fall back to The Everyman.
  static VibeArchetypeMatch _classifyByValues(VibeProfile profile) {
    // Build user profile map once
    final userValues = <VibeCategory, int>{};
    for (final category in VibeCategory.values) {
      userValues[category] = profile.preferenceFor(category).value;
    }

    // Step 1: Filter archetypes through elimination gates
    final eligible = <VibeArchetype>[];
    for (final archetype in all) {
      final gate = _eliminationGates[archetype.name];
      if (gate != null && gate(userValues)) {
        eligible.add(archetype);
      }
    }

    // Step 3: Fallback — if nothing passes the gates, use The Everyman
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
    // Max possible distance with 3x weights: sqrt(6 * 3 * 5^2) = sqrt(450) ≈ 21.2
    final maxPossibleDistance = math.sqrt(6 * 3.0 * 25.0);
    final compatibilityScore =
        100 * (1 - (bestDistance / maxPossibleDistance)).clamp(0.0, 1.0);

    return bestMatch!.withScore(compatibilityScore);
  }
}
