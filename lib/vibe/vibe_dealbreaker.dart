import 'dart:math';

import '/models/vibe_labels.dart';
import '/models/vibe_profile.dart';
import '/vibe/vibe_match_types.dart';
import '/vibe/vibe_tuning.dart';

/// Determines the effective tolerance threshold for a dealbreaker check
/// between two players on a single category.
///
/// When both sides have a dealbreaker, we use the stricter (lower) threshold.
/// When only one side does, we respect that side's threshold.
/// Fallback (neither dealbreaker) returns the stricter of the two — though
/// callers should typically skip non-dealbreaker categories.
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
  // Fallback — neither is a dealbreaker. Callers should not typically
  // reach here, but we return the stricter threshold defensively.
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

/// Evaluates all categories for hard-block dealbreaker conflicts.
///
/// Phase 1 change: hardMargin is now 1.0 (via VibeTuning), so a dealbreaker
/// with threshold=1 blocks at distance >= 2 instead of >= 3.
///
/// Phase 1 change: when both players set a dealbreaker on the same category,
/// we now use hardMargin 0.0 (just the raw threshold) — two people who both
/// feel strongly should trigger on a smaller gap.
HardBlockResult evaluateHardBlocks(VibeProfile a, VibeProfile b) {
  final conflicts = <VibeHardConflict>[];

  for (final category in VibeCategory.values) {
    final aPref = a.preferenceFor(category);
    final bPref = b.preferenceFor(category);
    if (!aPref.dealbreaker && !bPref.dealbreaker) {
      continue;
    }

    final distance = (aPref.value - bPref.value).abs();

    final tolerance = dealbreakerConflictThreshold(
      mineDealbreaker: aPref.dealbreaker,
      theirsDealbreaker: bPref.dealbreaker,
      myThreshold: aPref.threshold,
      theirThreshold: bPref.threshold,
    );

    // Phase 1: when BOTH sides flag a dealbreaker, apply no extra margin —
    // the raw threshold is the limit. When only one side flags it, apply
    // the standard hardMargin (now 1.0 from VibeTuning).
    final double effectiveMargin =
        (aPref.dealbreaker && bPref.dealbreaker) ? 0.0 : VibeTuning.hardMargin;
    final hardLimit = tolerance + effectiveMargin;

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

/// Checks whether a dealbreaker is triggered for a single category
/// using the bounds-based approach (anchor/forbidden zone logic).
///
/// Returns false if either side has default/unset data — we don't
/// penalize incomplete profiles with hard blocks.
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

  final defaultValue = VibeTuning.defaultValuesByCategory[category] ??
      VibePreference.defaultValue;
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
