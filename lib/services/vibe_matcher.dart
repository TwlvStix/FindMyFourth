import 'dart:math';

import '/models/vibe_profile.dart';

enum VibeConfidence {
  high,
  medium,
  low,
}

enum VibeDealbreakerOwner {
  me,
  them,
  both,
}

class VibeCategoryScore {
  const VibeCategoryScore({
    required this.categoryMatch,
    required this.weight,
    required this.distance,
  });

  final double categoryMatch;
  final double weight;
  final int distance;
}

class VibeConflict {
  const VibeConflict({
    required this.category,
    required this.myValue,
    required this.theirValue,
    required this.distance,
    required this.threshold,
    required this.whoHasDealbreaker,
  });

  final VibeCategory category;
  final int myValue;
  final int theirValue;
  final int distance;
  final int threshold;
  final VibeDealbreakerOwner whoHasDealbreaker;
}

class VibeDifference {
  const VibeDifference({
    required this.category,
    required this.distance,
  });

  final VibeCategory category;
  final int distance;
}

class VibeMatchResult {
  const VibeMatchResult({
    required this.totalScore,
    required this.cappedScore,
    required this.isRecommended,
    required this.conflicts,
    required this.topDifferences,
    required this.perCategory,
    required this.confidence,
    required this.confidenceLabel,
    required this.defaultCount,
    required this.defaultPercent,
  });

  final double totalScore;
  final double? cappedScore;
  final bool isRecommended;
  final List<VibeConflict> conflicts;
  final List<VibeDifference> topDifferences;
  final Map<VibeCategory, VibeCategoryScore> perCategory;
  final VibeConfidence confidence;
  final String confidenceLabel;
  final int defaultCount;
  final double defaultPercent;
}

class VibeMatcher {
  static const Map<VibeCategory, double> weights = {
    VibeCategory.pace: 25,
    VibeCategory.money: 20,
    VibeCategory.drinking: 15,
    VibeCategory.weed: 10,
    VibeCategory.music: 10,
    VibeCategory.chat: 10,
    VibeCategory.competitive: 10,
  };

  static const double _conflictScoreCap = 39;

  static VibeMatchResult score(
    VibeProfile mine,
    VibeProfile theirs,
  ) {
    final perCategory = <VibeCategory, VibeCategoryScore>{};
    final conflicts = <VibeConflict>[];
    final differences = <VibeDifference>[];

    var weightedSum = 0.0;
    var defaultCount = 0;

    for (final category in VibeCategory.values) {
      final myPref = mine.preferenceFor(category);
      final theirPref = theirs.preferenceFor(category);

      if (myPref.isDefault || theirPref.isDefault) {
        defaultCount += 1;
      }

      final distance = (myPref.value - theirPref.value).abs();
      final categoryMatch = (1 - (distance / 5)) * 100;
      final weight = weights[category] ?? 0;
      weightedSum += categoryMatch * weight;

      perCategory[category] = VibeCategoryScore(
        categoryMatch: categoryMatch,
        weight: weight,
        distance: distance,
      );

      differences.add(VibeDifference(category: category, distance: distance));

      if (_hasDealbreakerConflict(myPref, theirPref, distance)) {
        conflicts.add(
          VibeConflict(
            category: category,
            myValue: myPref.value,
            theirValue: theirPref.value,
            distance: distance,
            threshold: _conflictThreshold(myPref, theirPref),
            whoHasDealbreaker: _dealbreakerOwner(myPref, theirPref),
          ),
        );
      }
    }

    final totalScore = weightedSum / 100;
    final isRecommended = conflicts.isEmpty;
    final cappedScore =
        isRecommended ? null : min(totalScore, _conflictScoreCap);
    final topDifferences = _topDifferences(differences);
    final defaultPercent = defaultCount / VibeCategory.values.length;
    final confidence = _confidenceFromDefaults(defaultCount);

    return VibeMatchResult(
      totalScore: totalScore,
      cappedScore: cappedScore,
      isRecommended: isRecommended,
      conflicts: conflicts,
      topDifferences: topDifferences,
      perCategory: perCategory,
      confidence: confidence,
      confidenceLabel: _confidenceLabel(confidence),
      defaultCount: defaultCount,
      defaultPercent: defaultPercent,
    );
  }

  static bool _hasDealbreakerConflict(
    VibePreference mine,
    VibePreference theirs,
    int distance,
  ) {
    if (!(mine.dealbreaker || theirs.dealbreaker)) {
      return false;
    }
    final threshold = _conflictThreshold(mine, theirs);
    return distance >= threshold;
  }

  static int _conflictThreshold(
    VibePreference mine,
    VibePreference theirs,
  ) {
    if (mine.dealbreaker && theirs.dealbreaker) {
      return min(mine.threshold, theirs.threshold);
    }
    if (mine.dealbreaker) {
      return mine.threshold;
    }
    if (theirs.dealbreaker) {
      return theirs.threshold;
    }
    return VibePreference.defaultThreshold;
  }

  static VibeDealbreakerOwner _dealbreakerOwner(
    VibePreference mine,
    VibePreference theirs,
  ) {
    if (mine.dealbreaker && theirs.dealbreaker) {
      return VibeDealbreakerOwner.both;
    }
    if (mine.dealbreaker) {
      return VibeDealbreakerOwner.me;
    }
    return VibeDealbreakerOwner.them;
  }

  static List<VibeDifference> _topDifferences(
    List<VibeDifference> differences,
  ) {
    final sorted = List<VibeDifference>.from(differences)
      ..sort((a, b) => b.distance.compareTo(a.distance));
    final count = min(3, sorted.length);
    return sorted.take(count).toList();
  }

  static VibeConfidence _confidenceFromDefaults(int defaultCount) {
    if (defaultCount >= 3) {
      return VibeConfidence.low;
    }
    if (defaultCount == 2) {
      return VibeConfidence.medium;
    }
    return VibeConfidence.high;
  }

  static String _confidenceLabel(VibeConfidence confidence) {
    switch (confidence) {
      case VibeConfidence.high:
        return 'high confidence';
      case VibeConfidence.medium:
        return 'medium confidence';
      case VibeConfidence.low:
        return 'low confidence';
    }
  }
}
