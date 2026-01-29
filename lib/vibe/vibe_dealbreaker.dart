import 'dart:math';

import '/models/vibe_profile.dart';
import '/vibe/vibe_match_types.dart';
import '/vibe/vibe_tuning.dart';

int dealbreakerConflictThreshold({
  required bool mineDealbreaker,
  required bool theirsDealbreaker,
  required int myThreshold,
  required int theirThreshold,
}) {
  if (mineDealbreaker && theirsDealbreaker) {
    return min(myThreshold, theirThreshold);
  }
  if (mineDealbreaker) {
    return myThreshold;
  }
  if (theirsDealbreaker) {
    return theirThreshold;
  }
  return min(myThreshold, theirThreshold);
}

class HardBlockResult {
  const HardBlockResult({
    required this.isHardBlocked,
    required this.conflicts,
  });

  final bool isHardBlocked;
  final List<VibeHardConflict> conflicts;
}

HardBlockResult evaluateHardBlocks(VibeProfile a, VibeProfile b) {
  final conflicts = <VibeHardConflict>[];

  for (final category in VibeCategory.values) {
    final aPref = a.preferenceFor(category);
    final bPref = b.preferenceFor(category);
    if (!aPref.dealbreaker && !bPref.dealbreaker) {
      continue;
    }

    final distance = (aPref.value - bPref.value).abs();
    // Use the same threshold selection as the existing dealbreaker logic.
    final tolerance = dealbreakerConflictThreshold(
      mineDealbreaker: aPref.dealbreaker,
      theirsDealbreaker: bPref.dealbreaker,
      myThreshold: aPref.threshold,
      theirThreshold: bPref.threshold,
    );
    final hardLimit = tolerance + VibeTuning.hardMargin;

    if (distance >= hardLimit) {
      conflicts.add(
        VibeHardConflict(
          category: category,
          myValue: aPref.value.toDouble(),
          theirValue: bPref.value.toDouble(),
          distance: distance.toDouble(),
          thresholdOrLimit: hardLimit.toDouble(),
          reason: _hardBlockReason(category, distance, hardLimit),
          myDealbreaker: aPref.dealbreaker,
          theirDealbreaker: bPref.dealbreaker,
        ),
      );
    }
  }

  return HardBlockResult(
    isHardBlocked: conflicts.isNotEmpty,
    conflicts: conflicts,
  );
}

bool dealbreakerTriggeredForCategory({
  required VibeCategory category,
  required int aValue,
  required bool aDealbreaker,
  required bool aIsDefault,
  required int bValue,
  required bool bDealbreaker,
  required bool bIsDefault,
}) {
  if (!aDealbreaker && !bDealbreaker) {
    return false;
  }

  final defaultValue =
      VibeTuning.defaultValuesByCategory[category] ?? VibePreference.defaultValue;
  final aDefault = aIsDefault || aValue == defaultValue;
  final bDefault = bIsDefault || bValue == defaultValue;
  if (aDefault || bDefault) {
    return false;
  }

  final bounds = VibeTuning.dealbreakerBounds[category];
  if (bounds == null) {
    return false;
  }

  bool violates({
    required int myValue,
    required bool myDealbreaker,
    required int theirValue,
  }) {
    if (!myDealbreaker) {
      return false;
    }
    if (myValue <= bounds.lowAnchor) {
      return theirValue >= bounds.lowForbiddenMin;
    }
    if (myValue >= bounds.highAnchor) {
      return theirValue <= bounds.highForbiddenMax;
    }
    return false;
  }

  return violates(
        myValue: aValue,
        myDealbreaker: aDealbreaker,
        theirValue: bValue,
      ) ||
      violates(
        myValue: bValue,
        myDealbreaker: bDealbreaker,
        theirValue: aValue,
      );
}

String _hardBlockReason(
  VibeCategory category,
  int distance,
  double hardLimit,
) {
  final label = VibeLabels.titleFor(category);
  final overBy = (distance - hardLimit).toDouble();
  if (overBy.abs() < 1e-6) {
    return '$label mismatch exceeds the dealbreaker limit.';
  }
  return '$label mismatch exceeds the dealbreaker limit by ${overBy.toStringAsFixed(1)}.';
}
