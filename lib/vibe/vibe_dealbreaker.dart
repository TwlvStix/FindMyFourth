import 'dart:math';

import '/models/vibe_profile.dart';
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

double? dealbreakerCappedScore({
  required double score,
  required bool isDealbreaker,
  required double cap,
}) {
  if (!isDealbreaker) {
    return null;
  }
  return min(score, cap).toDouble();
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
