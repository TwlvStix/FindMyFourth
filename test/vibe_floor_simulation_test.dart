import 'dart:math';

import 'package:test/test.dart';

import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/services/vibe_matcher.dart';

// ============================================================================
// ARCHETYPE DEFINITIONS
// ============================================================================

enum GolferArchetype {
  ultraCompetitive,
  competitiveSocial,
  casualSocial,
  beginnerLearning,
  seriousRelaxed,
}

extension GolferArchetypeExt on GolferArchetype {
  String get label {
    switch (this) {
      case GolferArchetype.ultraCompetitive:
        return 'Ultra-Competitive';
      case GolferArchetype.competitiveSocial:
        return 'Competitive-Social';
      case GolferArchetype.casualSocial:
        return 'Casual-Social';
      case GolferArchetype.beginnerLearning:
        return 'Beginner/Learning';
      case GolferArchetype.seriousRelaxed:
        return 'Serious-Relaxed';
    }
  }

  String get shortLabel {
    switch (this) {
      case GolferArchetype.ultraCompetitive:
        return 'UltraComp';
      case GolferArchetype.competitiveSocial:
        return 'CompSocial';
      case GolferArchetype.casualSocial:
        return 'Casual';
      case GolferArchetype.beginnerLearning:
        return 'Beginner';
      case GolferArchetype.seriousRelaxed:
        return 'Relaxed';
    }
  }
}

// ============================================================================
// SYNTHETIC PROFILE
// ============================================================================

class SyntheticProfile {
  SyntheticProfile({
    required this.id,
    required this.archetype,
    required this.profile,
  });

  final String id;
  final GolferArchetype archetype;
  final VibeProfile profile;
}

// ============================================================================
// MATCH PAIR
// ============================================================================

class MatchPair {
  MatchPair({
    required this.owner,
    required this.player,
    required this.result,
  });

  final SyntheticProfile owner;
  final SyntheticProfile player;
  final VibeMatchResult result;

  /// Owner's perspective score - how the owner will feel about the player
  double get ownerScore => result.myFitPercent;
}

// ============================================================================
// PROFILE GENERATOR
// ============================================================================

class ProfileGenerator {
  ProfileGenerator({int? seed}) : _random = Random(seed ?? 42);

  final Random _random;
  int _nextId = 1;

  /// Distribution of archetypes (sums to 100)
  static const Map<GolferArchetype, int> archetypeDistribution = {
    GolferArchetype.ultraCompetitive: 15,
    GolferArchetype.competitiveSocial: 25,
    GolferArchetype.casualSocial: 30,
    GolferArchetype.beginnerLearning: 15,
    GolferArchetype.seriousRelaxed: 15,
  };

  List<SyntheticProfile> generate(int count) {
    final profiles = <SyntheticProfile>[];

    // Calculate counts per archetype
    final counts = <GolferArchetype, int>{};
    var remaining = count;
    for (final entry in archetypeDistribution.entries) {
      if (entry.key == archetypeDistribution.keys.last) {
        counts[entry.key] = remaining;
      } else {
        final c = (count * entry.value / 100).round();
        counts[entry.key] = c;
        remaining -= c;
      }
    }

    // Generate profiles for each archetype
    for (final archetype in GolferArchetype.values) {
      final c = counts[archetype] ?? 0;
      for (var i = 0; i < c; i++) {
        profiles.add(_generateProfile(archetype));
      }
    }

    // Shuffle to mix archetypes
    profiles.shuffle(_random);
    return profiles;
  }

  SyntheticProfile _generateProfile(GolferArchetype archetype) {
    final prefs = <VibeCategory, VibePreference>{};
    final importance = <VibeCategory, VibeImportance>{};

    for (final category in VibeCategory.values) {
      final config = _categoryConfig(archetype, category);
      prefs[category] = _generatePreference(config);
      importance[category] = config.importance;
    }

    final profile = VibeProfile(
      prefs: prefs,
      importance: importance,
      confirmedAt: DateTime.now(),
    );

    return SyntheticProfile(
      id: 'profile_${_nextId++}',
      archetype: archetype,
      profile: profile,
    );
  }

  VibePreference _generatePreference(_CategoryConfig config) {
    // Base value within range
    var value = _randomInRange(config.valueMin, config.valueMax);

    // Add variance with 40% probability
    if (_random.nextDouble() < 0.4) {
      final variance = _random.nextBool() ? 1 : -1;
      value = (value + variance).clamp(0, 5);
    }

    // Threshold within range
    final threshold = _randomInRange(config.thresholdMin, config.thresholdMax);

    // Dealbreaker based on probability
    final dealbreaker = _random.nextDouble() < config.dealbreakerProb;

    return VibePreference(
      value: value,
      dealbreaker: dealbreaker,
      threshold: threshold,
      isDefault: false,
    );
  }

  int _randomInRange(int min, int max) {
    if (min >= max) return min;
    return min + _random.nextInt(max - min + 1);
  }

  _CategoryConfig _categoryConfig(GolferArchetype archetype, VibeCategory cat) {
    switch (archetype) {
      case GolferArchetype.ultraCompetitive:
        return _ultraCompetitiveConfig(cat);
      case GolferArchetype.competitiveSocial:
        return _competitiveSocialConfig(cat);
      case GolferArchetype.casualSocial:
        return _casualSocialConfig(cat);
      case GolferArchetype.beginnerLearning:
        return _beginnerLearningConfig(cat);
      case GolferArchetype.seriousRelaxed:
        return _seriousRelaxedConfig(cat);
    }
  }

  // Ultra-Competitive: pace=4-5, competitive=4-5, money=3-5, drinking=0-2, music=0-2, chat=1-3
  _CategoryConfig _ultraCompetitiveConfig(VibeCategory cat) {
    switch (cat) {
      case VibeCategory.pace:
        return _CategoryConfig(
          valueMin: 4, valueMax: 5,
          thresholdMin: 0, thresholdMax: 1,
          dealbreakerProb: 0.30,
          importance: VibeImportance.top,
        );
      case VibeCategory.competitive:
        return _CategoryConfig(
          valueMin: 4, valueMax: 5,
          thresholdMin: 0, thresholdMax: 1,
          dealbreakerProb: 0.25,
          importance: VibeImportance.top,
        );
      case VibeCategory.money:
        return _CategoryConfig(
          valueMin: 3, valueMax: 5,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.05,
          importance: VibeImportance.normal,
        );
      case VibeCategory.drinking:
        return _CategoryConfig(
          valueMin: 0, valueMax: 2,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.15,
          importance: VibeImportance.normal,
        );
      case VibeCategory.music:
        return _CategoryConfig(
          valueMin: 0, valueMax: 2,
          thresholdMin: 1, thresholdMax: 3,
          dealbreakerProb: 0.05,
          importance: VibeImportance.bottom,
        );
      case VibeCategory.chat:
        return _CategoryConfig(
          valueMin: 1, valueMax: 3,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.05,
          importance: VibeImportance.normal,
        );
    }
  }

  // Competitive-Social: pace=3-4, competitive=2-4, money=2-4, drinking=2-4, music=2-4, chat=3-4
  _CategoryConfig _competitiveSocialConfig(VibeCategory cat) {
    switch (cat) {
      case VibeCategory.pace:
        return _CategoryConfig(
          valueMin: 3, valueMax: 4,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.10,
          importance: VibeImportance.normal,
        );
      case VibeCategory.competitive:
        return _CategoryConfig(
          valueMin: 2, valueMax: 4,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.10,
          importance: VibeImportance.normal,
        );
      case VibeCategory.money:
        return _CategoryConfig(
          valueMin: 2, valueMax: 4,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.05,
          importance: VibeImportance.normal,
        );
      case VibeCategory.drinking:
        return _CategoryConfig(
          valueMin: 2, valueMax: 4,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.05,
          importance: VibeImportance.normal,
        );
      case VibeCategory.music:
        return _CategoryConfig(
          valueMin: 2, valueMax: 4,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.02,
          importance: VibeImportance.normal,
        );
      case VibeCategory.chat:
        return _CategoryConfig(
          valueMin: 3, valueMax: 4,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.05,
          importance: VibeImportance.normal,
        );
    }
  }

  // Casual-Social: pace=1-3, competitive=0-2, money=0-2, drinking=2-4, music=3-5, chat=3-5
  _CategoryConfig _casualSocialConfig(VibeCategory cat) {
    switch (cat) {
      case VibeCategory.pace:
        return _CategoryConfig(
          valueMin: 1, valueMax: 3,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.20, // Don't want to be rushed
          importance: VibeImportance.top,
        );
      case VibeCategory.competitive:
        return _CategoryConfig(
          valueMin: 0, valueMax: 2,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.10,
          importance: VibeImportance.bottom,
        );
      case VibeCategory.money:
        return _CategoryConfig(
          valueMin: 0, valueMax: 2,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.10,
          importance: VibeImportance.bottom,
        );
      case VibeCategory.drinking:
        return _CategoryConfig(
          valueMin: 2, valueMax: 4,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.05,
          importance: VibeImportance.normal,
        );
      case VibeCategory.music:
        return _CategoryConfig(
          valueMin: 3, valueMax: 5,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.05,
          importance: VibeImportance.top,
        );
      case VibeCategory.chat:
        return _CategoryConfig(
          valueMin: 3, valueMax: 5,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.05,
          importance: VibeImportance.top,
        );
    }
  }

  // Beginner/Learning: pace=0-2, competitive=0-2, money=0-1, drinking=0-2, music=1-3, chat=2-4
  _CategoryConfig _beginnerLearningConfig(VibeCategory cat) {
    switch (cat) {
      case VibeCategory.pace:
        return _CategoryConfig(
          valueMin: 0, valueMax: 2,
          thresholdMin: 2, thresholdMax: 3, // More tolerant
          dealbreakerProb: 0.15,
          importance: VibeImportance.top, // Pace anxiety is real
        );
      case VibeCategory.competitive:
        return _CategoryConfig(
          valueMin: 0, valueMax: 2,
          thresholdMin: 2, thresholdMax: 3,
          dealbreakerProb: 0.05,
          importance: VibeImportance.bottom,
        );
      case VibeCategory.money:
        return _CategoryConfig(
          valueMin: 0, valueMax: 1,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.10,
          importance: VibeImportance.bottom,
        );
      case VibeCategory.drinking:
        return _CategoryConfig(
          valueMin: 0, valueMax: 2,
          thresholdMin: 2, thresholdMax: 3,
          dealbreakerProb: 0.02,
          importance: VibeImportance.normal,
        );
      case VibeCategory.music:
        return _CategoryConfig(
          valueMin: 1, valueMax: 3,
          thresholdMin: 2, thresholdMax: 3,
          dealbreakerProb: 0.02,
          importance: VibeImportance.normal,
        );
      case VibeCategory.chat:
        return _CategoryConfig(
          valueMin: 2, valueMax: 4,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.05,
          importance: VibeImportance.normal,
        );
    }
  }

  // Serious-Relaxed: pace=2-4, competitive=3-5, money=1-3, drinking=1-4, music=2-4, chat=2-4
  _CategoryConfig _seriousRelaxedConfig(VibeCategory cat) {
    switch (cat) {
      case VibeCategory.pace:
        return _CategoryConfig(
          valueMin: 2, valueMax: 4,
          thresholdMin: 2, thresholdMax: 3, // Don't stress pace
          dealbreakerProb: 0.05,
          importance: VibeImportance.normal,
        );
      case VibeCategory.competitive:
        return _CategoryConfig(
          valueMin: 3, valueMax: 5,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.10,
          importance: VibeImportance.top,
        );
      case VibeCategory.money:
        return _CategoryConfig(
          valueMin: 1, valueMax: 3,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.05,
          importance: VibeImportance.normal,
        );
      case VibeCategory.drinking:
        return _CategoryConfig(
          valueMin: 1, valueMax: 4,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.05,
          importance: VibeImportance.normal,
        );
      case VibeCategory.music:
        return _CategoryConfig(
          valueMin: 2, valueMax: 4,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.02,
          importance: VibeImportance.normal,
        );
      case VibeCategory.chat:
        return _CategoryConfig(
          valueMin: 2, valueMax: 4,
          thresholdMin: 1, thresholdMax: 2,
          dealbreakerProb: 0.05,
          importance: VibeImportance.normal,
        );
    }
  }
}

class _CategoryConfig {
  const _CategoryConfig({
    required this.valueMin,
    required this.valueMax,
    required this.thresholdMin,
    required this.thresholdMax,
    required this.dealbreakerProb,
    required this.importance,
  });

  final int valueMin;
  final int valueMax;
  final int thresholdMin;
  final int thresholdMax;
  final double dealbreakerProb;
  final VibeImportance importance;
}

// ============================================================================
// ANALYSIS FUNCTIONS
// ============================================================================

class SimulationStats {
  SimulationStats(List<double> scores) {
    if (scores.isEmpty) {
      minimum = 0;
      maximum = 0;
      mean = 0;
      median = 0;
      stdDev = 0;
      return;
    }

    final sorted = List<double>.from(scores)..sort();
    minimum = sorted.first;
    maximum = sorted.last;
    mean = scores.reduce((a, b) => a + b) / scores.length;

    final mid = sorted.length ~/ 2;
    median = sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;

    final variance = scores.map((s) => pow(s - mean, 2)).reduce((a, b) => a + b) / scores.length;
    stdDev = sqrt(variance);
  }

  late final double minimum;
  late final double maximum;
  late final double mean;
  late final double median;
  late final double stdDev;
}

class ThresholdAnalysis {
  ThresholdAnalysis({
    required this.threshold,
    required this.blockedPairs,
    required this.totalPairs,
    required this.uniquePlayersBlockedFromSome,
    required this.uniquePlayersBlockedFromAll,
    required this.totalPlayers,
    required this.avgGamesPerPlayer,
  });

  final int threshold;
  final int blockedPairs;
  final int totalPairs;
  final int uniquePlayersBlockedFromSome;
  final int uniquePlayersBlockedFromAll;
  final int totalPlayers;
  final double avgGamesPerPlayer;

  double get blockRate => totalPairs > 0 ? blockedPairs / totalPairs * 100 : 0;
  double get playersBlockedFromSomePercent =>
      totalPlayers > 0 ? uniquePlayersBlockedFromSome / totalPlayers * 100 : 0;
  double get playersBlockedFromAllPercent =>
      totalPlayers > 0 ? uniquePlayersBlockedFromAll / totalPlayers * 100 : 0;
}

ThresholdAnalysis analyzeThreshold(
  List<MatchPair> pairs,
  Set<String> playerIds,
  int threshold,
  int totalOwners,
) {
  final blocked = pairs.where((p) => p.ownerScore < threshold).toList();

  // Track which games each player is blocked from
  final blockedFromGames = <String, Set<String>>{};
  for (final playerId in playerIds) {
    blockedFromGames[playerId] = {};
  }
  for (final pair in blocked) {
    blockedFromGames[pair.player.id]!.add(pair.owner.id);
  }

  final blockedFromSome = blockedFromGames.values.where((s) => s.isNotEmpty).length;
  final blockedFromAll = blockedFromGames.values.where((s) => s.length >= totalOwners).length;

  // Average games available per player
  final availableGames = playerIds.map((pid) {
    final blockedCount = blockedFromGames[pid]?.length ?? 0;
    return totalOwners - blockedCount;
  }).toList();
  final avgGames = availableGames.reduce((a, b) => a + b) / availableGames.length;

  return ThresholdAnalysis(
    threshold: threshold,
    blockedPairs: blocked.length,
    totalPairs: pairs.length,
    uniquePlayersBlockedFromSome: blockedFromSome,
    uniquePlayersBlockedFromAll: blockedFromAll,
    totalPlayers: playerIds.length,
    avgGamesPerPlayer: avgGames,
  );
}

// ============================================================================
// REPORT PRINTING
// ============================================================================

void printHeader(String title) {
  print('');
  print('=' * 70);
  print(title.toUpperCase());
  print('=' * 70);
}

void printDistributionReport(List<MatchPair> pairs) {
  printHeader('Score Distribution Overview');

  final scores = pairs.map((p) => p.ownerScore).toList();
  final stats = SimulationStats(scores);

  print('Total match pairs: ${pairs.length}');
  print('');
  print('Statistics (Owner\'s Perspective Score):');
  print('  Minimum:  ${stats.minimum.toStringAsFixed(1)}%');
  print('  Maximum:  ${stats.maximum.toStringAsFixed(1)}%');
  print('  Mean:     ${stats.mean.toStringAsFixed(1)}%');
  print('  Median:   ${stats.median.toStringAsFixed(1)}%');
  print('  Std Dev:  ${stats.stdDev.toStringAsFixed(1)}');

  // Histogram in 5% buckets
  print('');
  print('Score Distribution Histogram (5% buckets):');
  print('');

  final buckets = List<int>.filled(20, 0); // 0-5, 5-10, ... 95-100
  for (final score in scores) {
    final bucket = (score / 5).floor().clamp(0, 19);
    buckets[bucket]++;
  }

  final maxCount = buckets.reduce((a, b) => a > b ? a : b);
  final barWidth = 40;

  for (var i = 0; i < 20; i++) {
    final rangeStart = i * 5;
    final rangeEnd = rangeStart + 5;
    final count = buckets[i];
    final barLength = maxCount > 0 ? (count / maxCount * barWidth).round() : 0;
    final bar = '#' * barLength;
    final pct = (count / scores.length * 100).toStringAsFixed(1);
    print('${rangeStart.toString().padLeft(2)}-${rangeEnd.toString().padLeft(2)}% | $bar ${count.toString().padLeft(4)} (${pct.padLeft(5)}%)');
  }
}

void printThresholdAnalysis(List<MatchPair> pairs, List<int> thresholds) {
  printHeader('Threshold Analysis');

  final playerIds = pairs.map((p) => p.player.id).toSet();
  final ownerIds = pairs.map((p) => p.owner.id).toSet();

  print('Analyzing vibe floor thresholds: ${thresholds.map((t) => "$t%").join(", ")}');
  print('');
  print('Floor | Block Rate | Blocked from 1+ | Blocked from ALL | Avg Games');
  print('-' * 70);

  for (final threshold in thresholds) {
    final analysis = analyzeThreshold(pairs, playerIds, threshold, ownerIds.length);
    final blockRate = analysis.blockRate.toStringAsFixed(1).padLeft(5);
    final fromSome = '${analysis.uniquePlayersBlockedFromSome}/${analysis.totalPlayers} (${analysis.playersBlockedFromSomePercent.toStringAsFixed(1)}%)'.padLeft(16);
    final fromAll = '${analysis.uniquePlayersBlockedFromAll}/${analysis.totalPlayers} (${analysis.playersBlockedFromAllPercent.toStringAsFixed(1)}%)'.padLeft(18);
    final avgGames = analysis.avgGamesPerPlayer.toStringAsFixed(1).padLeft(9);
    print(' ${threshold.toString().padLeft(2)}%  |   $blockRate%  |     $fromSome |      $fromAll |    $avgGames');
  }

  print('');
  print('Legend:');
  print('  Block Rate        = % of join attempts that would require approval');
  print('  Blocked from 1+   = Players blocked from at least one game');
  print('  Blocked from ALL  = Players blocked from every game');
  print('  Avg Games         = Average number of games each player can auto-join');
}

void printArchetypeBreakdown(List<MatchPair> pairs) {
  printHeader('Archetype Compatibility Matrix');

  print('Average owner-perspective score by archetype pairing:');
  print('(Rows = Owner archetype, Columns = Player archetype)');
  print('');

  // Calculate average scores for each archetype pair
  final scoreMatrix = <GolferArchetype, Map<GolferArchetype, List<double>>>{};
  for (final archetype in GolferArchetype.values) {
    scoreMatrix[archetype] = {};
    for (final playerArchetype in GolferArchetype.values) {
      scoreMatrix[archetype]![playerArchetype] = [];
    }
  }

  for (final pair in pairs) {
    scoreMatrix[pair.owner.archetype]![pair.player.archetype]!.add(pair.ownerScore);
  }

  // Print header row
  final header = ''.padRight(12) +
      GolferArchetype.values.map((a) => a.shortLabel.padLeft(10)).join(' ');
  print(header);
  print('-' * header.length);

  // Print each row
  for (final ownerArchetype in GolferArchetype.values) {
    final row = StringBuffer(ownerArchetype.shortLabel.padRight(12));
    for (final playerArchetype in GolferArchetype.values) {
      final scores = scoreMatrix[ownerArchetype]![playerArchetype]!;
      final avg = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
      row.write(avg.toStringAsFixed(1).padLeft(10));
      row.write(' ');
    }
    print(row);
  }

  // Identify problematic pairings at different thresholds
  print('');
  printHeader('High-Risk Pairings');

  for (final threshold in [30, 40]) {
    print('');
    print('Pairings with >50% block rate at ${threshold}% floor:');

    final problems = <String>[];
    for (final ownerArchetype in GolferArchetype.values) {
      for (final playerArchetype in GolferArchetype.values) {
        final scores = scoreMatrix[ownerArchetype]![playerArchetype]!;
        if (scores.isEmpty) continue;
        final blockedCount = scores.where((s) => s < threshold).length;
        final blockRate = blockedCount / scores.length * 100;
        if (blockRate > 50) {
          problems.add('  ${ownerArchetype.shortLabel} owner + ${playerArchetype.shortLabel} player: ${blockRate.toStringAsFixed(1)}% blocked');
        }
      }
    }

    if (problems.isEmpty) {
      print('  (none)');
    } else {
      for (final p in problems) {
        print(p);
      }
    }
  }

  // Check for disproportionately blocked archetypes
  print('');
  printHeader('Archetype Access Analysis');

  for (final threshold in [30, 40]) {
    print('');
    print('At ${threshold}% floor - average block rate by player archetype:');

    for (final playerArchetype in GolferArchetype.values) {
      final playerPairs = pairs.where((p) => p.player.archetype == playerArchetype).toList();
      if (playerPairs.isEmpty) continue;

      final blockedCount = playerPairs.where((p) => p.ownerScore < threshold).length;
      final blockRate = blockedCount / playerPairs.length * 100;

      final status = blockRate > 50 ? ' *** CONCERN ***' : '';
      print('  ${playerArchetype.label.padRight(20)}: ${blockRate.toStringAsFixed(1)}% blocked$status');
    }
  }
}

void printRecommendation(List<MatchPair> pairs) {
  printHeader('Recommendation');

  final playerIds = pairs.map((p) => p.player.id).toSet();
  final ownerIds = pairs.map((p) => p.owner.id).toSet();

  // Analyze all candidate thresholds
  final candidates = <int, ThresholdAnalysis>{};
  for (final t in [20, 25, 30, 35, 40, 45, 50]) {
    candidates[t] = analyzeThreshold(pairs, playerIds, t, ownerIds.length);
  }

  // Check archetype fairness
  bool archetypeFair(int threshold) {
    for (final playerArchetype in GolferArchetype.values) {
      final playerPairs = pairs.where((p) => p.player.archetype == playerArchetype).toList();
      if (playerPairs.isEmpty) continue;
      final blockedCount = playerPairs.where((p) => p.ownerScore < threshold).length;
      final blockRate = blockedCount / playerPairs.length * 100;
      if (blockRate > 50) return false;
    }
    return true;
  }

  print('Criteria:');
  print('  1. Block rate between 5-15% (balance protection vs friction)');
  print('  2. No archetype blocked from >50% of games');
  print('  3. No players blocked from ALL games');
  print('');

  print('Analysis by threshold:');
  for (final entry in candidates.entries) {
    final t = entry.key;
    final a = entry.value;
    final fair = archetypeFair(t);

    final checks = <String>[];
    if (a.blockRate >= 5 && a.blockRate <= 15) {
      checks.add('Block rate OK');
    } else if (a.blockRate < 5) {
      checks.add('Block rate too low (minimal protection)');
    } else {
      checks.add('Block rate too high (too much friction)');
    }

    if (fair) {
      checks.add('Archetypes fair');
    } else {
      checks.add('Some archetypes disproportionately blocked');
    }

    if (a.uniquePlayersBlockedFromAll == 0) {
      checks.add('No total lockouts');
    } else {
      checks.add('${a.uniquePlayersBlockedFromAll} players locked out');
    }

    print('  $t%: ${checks.join(" | ")}');
  }

  // Find best threshold
  int? recommended;
  for (final t in [30, 35, 25, 40, 45]) {
    final a = candidates[t]!;
    if (a.blockRate >= 5 && a.blockRate <= 15 && archetypeFair(t) && a.uniquePlayersBlockedFromAll == 0) {
      recommended = t;
      break;
    }
  }

  // Fallback: find closest to 10% block rate that's fair
  if (recommended == null) {
    var bestDiff = double.infinity;
    for (final entry in candidates.entries) {
      if (archetypeFair(entry.key) && entry.value.uniquePlayersBlockedFromAll == 0) {
        final diff = (entry.value.blockRate - 10).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          recommended = entry.key;
        }
      }
    }
  }

  print('');
  if (recommended != null) {
    final analysis = candidates[recommended]!;
    print('RECOMMENDATION: ${recommended}% vibe floor');
    print('');
    print('  Expected outcomes:');
    print('  - ${analysis.blockRate.toStringAsFixed(1)}% of join attempts require owner approval');
    print('  - ${analysis.uniquePlayersBlockedFromSome} players will need approval for at least one game');
    print('  - ${analysis.uniquePlayersBlockedFromAll} players locked out of all games');
    print('  - Average of ${analysis.avgGamesPerPlayer.toStringAsFixed(1)} games per player for auto-join');
  } else {
    print('No threshold meets all criteria. Consider:');
    print('  - Adjusting criteria based on business priorities');
    print('  - Reviewing archetype balance if one type is consistently blocked');
  }
}

// ============================================================================
// MAIN TEST
// ============================================================================

void main() {
  test('Vibe Floor Distribution Simulation', () {
    print('');
    print('*' * 70);
    print('VIBE FLOOR SIMULATION');
    print('*' * 70);

    // 1. Generate profiles
    final generator = ProfileGenerator(seed: 42);
    final profiles = generator.generate(200);

    printHeader('Profile Generation Summary');
    print('Generated ${profiles.length} synthetic profiles:');
    for (final archetype in GolferArchetype.values) {
      final count = profiles.where((p) => p.archetype == archetype).length;
      print('  ${archetype.label.padRight(20)}: $count (${(count / profiles.length * 100).toStringAsFixed(0)}%)');
    }

    // 2. Select owners (6 per archetype = 30 total)
    final owners = <SyntheticProfile>[];
    for (final archetype in GolferArchetype.values) {
      final archetypeProfiles = profiles.where((p) => p.archetype == archetype).toList();
      owners.addAll(archetypeProfiles.take(6));
    }
    final ownerIds = owners.map((o) => o.id).toSet();
    final players = profiles.where((p) => !ownerIds.contains(p.id)).toList();

    print('');
    print('Simulation setup:');
    print('  Game owners: ${owners.length} (6 per archetype)');
    print('  Players: ${players.length}');
    print('  Total match pairs: ${owners.length * players.length}');

    // 3. Run pairwise matching
    final allPairs = <MatchPair>[];
    for (final owner in owners) {
      for (final player in players) {
        final result = VibeMatcher.score(owner.profile, player.profile);
        allPairs.add(MatchPair(owner: owner, player: player, result: result));
      }
    }

    // 4. Generate reports
    printDistributionReport(allPairs);
    printThresholdAnalysis(allPairs, [25, 30, 35, 40, 45, 50]);
    printArchetypeBreakdown(allPairs);
    printRecommendation(allPairs);

    print('');
    print('*' * 70);
    print('END OF SIMULATION');
    print('*' * 70);
    print('');
  });
}
