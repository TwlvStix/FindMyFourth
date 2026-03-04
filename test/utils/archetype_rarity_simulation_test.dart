import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/utils/vibe_archetypes.dart';
import 'package:find_my_fourth/utils/vibe_archetype_metadata.dart';

void main() {
  group('Archetype Rarity Simulation', () {
    test('simulate archetype distribution with bell curve', () {
      const sampleSize = 100000;
      final random = Random(42); // seeded for reproducibility
      final counts = <String, int>{};

      for (var i = 0; i < sampleSize; i++) {
        final profile = _generateRandomProfile(random);
        final match = VibeArchetypes.classifyProfile(profile);
        counts[match.name] = (counts[match.name] ?? 0) + 1;
      }

      // Print comparison table
      print('\n${'=' * 60}');
      print('ARCHETYPE RARITY SIMULATION (n=$sampleSize)');
      print('${'=' * 60}');
      print(
          '${'Archetype'.padRight(20)} ${'Simulated'.padLeft(10)} ${'Hardcoded'.padLeft(10)} ${'Delta'.padLeft(10)}');
      print('${'-' * 60}');

      for (final name in _sortedArchetypeNames) {
        final simulated = (counts[name] ?? 0) / sampleSize * 100;
        final hardcoded =
            VibeArchetypeMetadata.archetypeDistribution[name] ?? 0;
        final delta = simulated - hardcoded;
        print(
            '${name.padRight(20)} ${simulated.toStringAsFixed(1).padLeft(9)}% ${hardcoded.toString().padLeft(9)}% ${_formatDelta(delta).padLeft(10)}');
      }
      print('${'=' * 60}\n');

      // Also print value distribution for debugging
      _printValueDistribution(random);
    });

    test('simulate with varying dealbreaker rates', () {
      const sampleSize = 50000;
      final random = Random(42);

      for (final dealbreakerRate in [0.0, 0.05, 0.10, 0.15, 0.20]) {
        final counts = <String, int>{};

        for (var i = 0; i < sampleSize; i++) {
          final profile =
              _generateRandomProfile(random, dealbreakerRate: dealbreakerRate);
          final match = VibeArchetypes.classifyProfile(profile);
          counts[match.name] = (counts[match.name] ?? 0) + 1;
        }

        final wardenPct = (counts['The Warden'] ?? 0) / sampleSize * 100;
        final everymanPct = (counts['The Everyman'] ?? 0) / sampleSize * 100;

        print(
            'Dealbreaker rate ${(dealbreakerRate * 100).toInt()}%: Warden=${wardenPct.toStringAsFixed(1)}%, Everyman=${everymanPct.toStringAsFixed(1)}%');
      }
    });

    test('simulate with uniform distribution (for comparison)', () {
      const sampleSize = 100000;
      final random = Random(42);
      final counts = <String, int>{};

      for (var i = 0; i < sampleSize; i++) {
        final profile = _generateUniformProfile(random);
        final match = VibeArchetypes.classifyProfile(profile);
        counts[match.name] = (counts[match.name] ?? 0) + 1;
      }

      print('\n${'=' * 60}');
      print('UNIFORM DISTRIBUTION SIMULATION (n=$sampleSize)');
      print('${'=' * 60}');
      print(
          '${'Archetype'.padRight(20)} ${'Simulated'.padLeft(10)} ${'Hardcoded'.padLeft(10)} ${'Delta'.padLeft(10)}');
      print('${'-' * 60}');

      for (final name in _sortedArchetypeNames) {
        final simulated = (counts[name] ?? 0) / sampleSize * 100;
        final hardcoded =
            VibeArchetypeMetadata.archetypeDistribution[name] ?? 0;
        final delta = simulated - hardcoded;
        print(
            '${name.padRight(20)} ${simulated.toStringAsFixed(1).padLeft(9)}% ${hardcoded.toString().padLeft(9)}% ${_formatDelta(delta).padLeft(10)}');
      }
      print('${'=' * 60}\n');
    });
  });
}

VibeProfile _generateRandomProfile(Random random,
    {double dealbreakerRate = 0.10}) {
  // Bell curve: Box-Muller transform, mean=2.5, std=1.2
  final prefs = <VibeCategory, VibePreference>{};
  var dealbreakerCount = 0;
  const maxDealbreakers = 3;

  for (final category in VibeCategory.values) {
    final value = _bellCurveValue(random, mean: 2.5, std: 1.2);
    // Only assign dealbreaker if under rate threshold and under cap
    final isDealbreaker = dealbreakerCount < maxDealbreakers &&
        random.nextDouble() < dealbreakerRate;
    if (isDealbreaker) dealbreakerCount++;

    prefs[category] = VibePreference(
      value: value,
      dealbreaker: isDealbreaker,
      threshold: 1,
      isDefault: false,
    );
  }

  return VibeProfile(prefs: prefs);
}

VibeProfile _generateUniformProfile(Random random,
    {double dealbreakerRate = 0.10}) {
  final prefs = <VibeCategory, VibePreference>{};
  var dealbreakerCount = 0;
  const maxDealbreakers = 3;

  for (final category in VibeCategory.values) {
    final value = random.nextInt(6); // 0-5 uniform
    final isDealbreaker = dealbreakerCount < maxDealbreakers &&
        random.nextDouble() < dealbreakerRate;
    if (isDealbreaker) dealbreakerCount++;

    prefs[category] = VibePreference(
      value: value,
      dealbreaker: isDealbreaker,
      threshold: 1,
      isDefault: false,
    );
  }

  return VibeProfile(prefs: prefs);
}

int _bellCurveValue(Random random, {required double mean, required double std}) {
  // Box-Muller transform for normal distribution
  final u1 = random.nextDouble();
  final u2 = random.nextDouble();
  final z = sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  final value = (mean + z * std).round().clamp(0, 5);
  return value;
}

String _formatDelta(double delta) {
  final sign = delta >= 0 ? '+' : '';
  return '$sign${delta.toStringAsFixed(1)}%';
}

void _printValueDistribution(Random random) {
  // Generate sample values to show the bell curve distribution
  const samples = 10000;
  final valueCounts = <int, int>{};

  for (var i = 0; i < samples; i++) {
    final v = _bellCurveValue(random, mean: 2.5, std: 1.2);
    valueCounts[v] = (valueCounts[v] ?? 0) + 1;
  }

  print('\nValue Distribution (bell curve, n=$samples):');
  for (var v = 0; v <= 5; v++) {
    final pct = (valueCounts[v] ?? 0) / samples * 100;
    final bar = '█' * (pct ~/ 2);
    print('  $v: ${pct.toStringAsFixed(1).padLeft(5)}% $bar');
  }
  print('');
}

const _sortedArchetypeNames = [
  'The Juggernaut',
  'The Grinder',
  'The High Roller',
  'The Purist',
  'The Vibe King',
  'The Shark',
  'The Hustler',
  'The Warden',
  'The Ghost',
  'The Tourist',
  'The DJ',
  'The Mayor',
  'The Everyman',
];
