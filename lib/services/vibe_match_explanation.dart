import 'dart:math';

import '/models/vibe_profile.dart';
import '/services/vibe_matcher.dart';
import '/vibe/vibe_scoring.dart';

enum VibeWeightLevel {
  high,
  medium,
  low,
}

enum VibeStatusBadge {
  aligned,
  withinTolerance,
  watchPoint,
  dealbreakerRisk,
}

enum VibeInsightType {
  positive,
  difference,
}

class CategoryBreakdown {
  const CategoryBreakdown({
    required this.category,
    required this.label,
    required this.matchPercent,
    required this.weight,
    required this.weightLevel,
    required this.statusBadge,
    required this.isDefaultA,
    required this.isDefaultB,
    required this.withinTolerance,
    required this.distance,
    required this.tolerance,
    required this.dealbreakerRisk,
    required this.weightNormalized,
  });

  final VibeCategory category;
  final String label;
  final double matchPercent;
  final double weight;
  final VibeWeightLevel weightLevel;
  final VibeStatusBadge statusBadge;
  final bool isDefaultA;
  final bool isDefaultB;
  final bool withinTolerance;
  final int distance;
  final int tolerance;
  final bool dealbreakerRisk;
  final double weightNormalized;
}

class InsightItem {
  const InsightItem({
    required this.title,
    required this.description,
    required this.type,
    required this.categoryKey,
    required this.isActivityBased,
  });

  final String title;
  final String description;
  final VibeInsightType type;
  final VibeCategory? categoryKey;
  final bool isActivityBased;
}

class MatchExplanation {
  const MatchExplanation({
    required this.totalScore,
    required this.confidenceLevel,
    required this.confidenceReason,
    required this.defaultCategoryCount,
    required this.categories,
    required this.topDifferencesThatMatter,
    required this.whyThisMatchWorks,
    required this.whatHelpedThisMatch,
  });

  final int totalScore;
  final VibeConfidence confidenceLevel;
  final String confidenceReason;
  final int defaultCategoryCount;
  final List<CategoryBreakdown> categories;
  final List<InsightItem> topDifferencesThatMatter;
  final List<InsightItem> whyThisMatchWorks;
  final List<InsightItem> whatHelpedThisMatch;
}

MatchExplanation buildMatchExplanation({
  required VibeMatchResult matchResult,
  required VibeProfile a,
  required VibeProfile b,
}) {
  final perCategory = matchResult.perCategory;
  final conflictsByCategory = <VibeCategory>{
    for (final conflict in matchResult.conflicts) conflict.category,
  };

  final rawBreakdowns = <_BreakdownSeed>[];
  for (final category in VibeCategory.values) {
    final prefA = a.preferenceFor(category);
    final prefB = b.preferenceFor(category);
    final score = perCategory[category]?.categoryMatch ?? 0;
    final weight = perCategory[category]?.weight ?? 0;
    final distance = (prefA.value - prefB.value).abs();
    final tolerance = min(prefA.threshold, prefB.threshold);
    final withinTolerance = distance <= tolerance;
    final isDefaultA = isDefault(
      category,
      prefA.value,
      isDefaultFlag: prefA.isDefault,
    );
    final isDefaultB = isDefault(
      category,
      prefB.value,
      isDefaultFlag: prefB.isDefault,
    );
    final dealbreakerRisk = conflictsByCategory.contains(category);

    rawBreakdowns.add(
      _BreakdownSeed(
        category: category,
        label: VibeLabels.titleFor(category),
        matchPercent: score,
        weight: weight,
        isDefaultA: isDefaultA,
        isDefaultB: isDefaultB,
        withinTolerance: withinTolerance,
        distance: distance,
        tolerance: tolerance,
        dealbreakerRisk: dealbreakerRisk,
        prefA: prefA,
        prefB: prefB,
      ),
    );
  }

  final sortedByWeight = List<_BreakdownSeed>.from(rawBreakdowns)
    ..sort((a, b) => b.weight.compareTo(a.weight));
  final highCount = min(2, sortedByWeight.length);
  final highSet = <VibeCategory>{
    for (final seed in sortedByWeight.take(highCount)) seed.category,
  };
  final lowCount = min(2, max(0, sortedByWeight.length - highCount));
  final lowSet = <VibeCategory>{
    for (final seed in sortedByWeight.reversed.take(lowCount)) seed.category,
  };
  final totalWeight = rawBreakdowns.fold<double>(
    0,
    (sum, seed) => sum + seed.weight,
  );

  final breakdowns = rawBreakdowns.map((seed) {
    final weightLevel = highSet.contains(seed.category)
        ? VibeWeightLevel.high
        : lowSet.contains(seed.category)
            ? VibeWeightLevel.low
            : VibeWeightLevel.medium;
    final aligned = seed.matchPercent >= 85 &&
        !(seed.isDefaultA && seed.isDefaultB);
    final watchPoint = !seed.withinTolerance &&
        (weightLevel != VibeWeightLevel.low || seed.matchPercent < 75);
    final statusBadge = seed.dealbreakerRisk
        ? VibeStatusBadge.dealbreakerRisk
        : aligned
            ? VibeStatusBadge.aligned
            : seed.withinTolerance
                ? VibeStatusBadge.withinTolerance
                : watchPoint
                    ? VibeStatusBadge.watchPoint
                    : VibeStatusBadge.watchPoint;

    final weightNormalized =
        totalWeight > 0 ? (seed.weight / totalWeight).toDouble() : 0.0;
    return CategoryBreakdown(
      category: seed.category,
      label: seed.label,
      matchPercent: seed.matchPercent,
      weight: seed.weight,
      weightLevel: weightLevel,
      statusBadge: statusBadge,
      isDefaultA: seed.isDefaultA,
      isDefaultB: seed.isDefaultB,
      withinTolerance: seed.withinTolerance,
      distance: seed.distance,
      tolerance: seed.tolerance,
      dealbreakerRisk: seed.dealbreakerRisk,
      weightNormalized: weightNormalized,
    );
  }).toList();

  final maxOutside = rawBreakdowns.fold<int>(
    0,
    (maxValue, seed) => max(maxValue, max(0, seed.distance - seed.tolerance)),
  );
  final differences = <_ImpactItem>[];
  for (final breakdown in breakdowns) {
    final outsideBy = max(0, breakdown.distance - breakdown.tolerance);
    final outsideTolerance = outsideBy > 0;
    final outsideFactor = outsideTolerance
        ? 1 + (maxOutside > 0 ? min(1, outsideBy / maxOutside) : 0)
        : 0;
    final strictnessFactor = _strictnessFactor(
      breakdown.category,
      rawBreakdowns,
    );
    final defaultDampener =
        (breakdown.isDefaultA || breakdown.isDefaultB) ? 0.5 : 1.0;
    final impact = breakdown.weightNormalized *
        strictnessFactor *
        outsideFactor *
        (1 - (breakdown.matchPercent / 100)) *
        defaultDampener;

    if (impact > 0 &&
        (outsideTolerance || breakdown.weightLevel != VibeWeightLevel.low)) {
      differences.add(
        _ImpactItem(
          category: breakdown.category,
          impact: impact,
          description: _differenceDescription(
            breakdown.category,
            outsideTolerance,
          ),
        ),
      );
    }
  }

  differences.sort((a, b) => b.impact.compareTo(a.impact));
  final topDifferences = differences.take(3).map((item) {
    return InsightItem(
      title: VibeLabels.titleFor(item.category),
      description: item.description,
      type: VibeInsightType.difference,
      categoryKey: item.category,
      isActivityBased: false,
    );
  }).toList();

  final positives = breakdowns
      .where((breakdown) {
        final goodFit =
            breakdown.withinTolerance || breakdown.matchPercent >= 85;
        final bothDefault = breakdown.isDefaultA && breakdown.isDefaultB;
        return goodFit && !bothDefault;
      })
      .toList()
    ..sort((a, b) => b.weight.compareTo(a.weight));

  final whatHelped = positives.take(2).map((breakdown) {
    return InsightItem(
      title: breakdown.label,
      description: _positiveDescription(breakdown.category),
      type: VibeInsightType.positive,
      categoryKey: breakdown.category,
      isActivityBased: false,
    );
  }).toList();

  final defaultCategoryCount = breakdowns
      .where((breakdown) => breakdown.isDefaultA || breakdown.isDefaultB)
      .length;
  final defaultWeight = breakdowns
      .where((breakdown) => breakdown.isDefaultA || breakdown.isDefaultB)
      .fold<double>(0, (sum, breakdown) => sum + breakdown.weight);
  final defaultWeightShare =
      totalWeight > 0 ? defaultWeight / totalWeight : 0;

  final highWeightBreakdowns = breakdowns
      .where((breakdown) => breakdown.weightLevel == VibeWeightLevel.high)
      .toList();
  final highWeightWatchPoints = highWeightBreakdowns.where((breakdown) {
    return breakdown.statusBadge == VibeStatusBadge.watchPoint ||
        breakdown.statusBadge == VibeStatusBadge.dealbreakerRisk;
  }).length;
  final highWeightAligned = highWeightBreakdowns.isEmpty
      ? true
      : highWeightBreakdowns.every((breakdown) {
          return breakdown.statusBadge == VibeStatusBadge.aligned ||
              breakdown.statusBadge == VibeStatusBadge.withinTolerance;
        });
  final dealbreakerRisk = breakdowns.any(
    (breakdown) => breakdown.statusBadge == VibeStatusBadge.dealbreakerRisk,
  );

  VibeConfidence confidence;
  if (!dealbreakerRisk && highWeightAligned && defaultCategoryCount <= 1) {
    confidence = VibeConfidence.high;
  } else if (highWeightWatchPoints >= 2 ||
      defaultCategoryCount >= 4 ||
      defaultWeightShare >= 0.4) {
    confidence = VibeConfidence.low;
  } else if (highWeightWatchPoints >= 1 ||
      (defaultCategoryCount >= 2 && defaultCategoryCount <= 3)) {
    confidence = VibeConfidence.medium;
  } else {
    confidence = VibeConfidence.medium;
  }

  final confidenceReason = _confidenceReason(
    confidence,
    defaultCategoryCount,
  );

  final displayScore =
      (matchResult.cappedScore ?? matchResult.totalScore).round();

  final whyThisMatchWorks = <InsightItem>[];
  if (confidence != VibeConfidence.low) {
    final interactionRules = matchResult.interactionAppliedRules;
    if (interactionRules.isNotEmpty) {
      final rule = interactionRules.first;
      whyThisMatchWorks.add(
        InsightItem(
          title: VibeLabels.titleFor(rule.category),
          description: rule.reason,
          type: VibeInsightType.positive,
          categoryKey: rule.category,
          isActivityBased: true,
        ),
      );
    }

    for (final item in whatHelped) {
      if (whyThisMatchWorks.length >= 2) {
        break;
      }
      final alreadyIncluded = whyThisMatchWorks
          .any((existing) => existing.categoryKey == item.categoryKey);
      if (!alreadyIncluded) {
        whyThisMatchWorks.add(item);
      }
    }
  }

  return MatchExplanation(
    totalScore: displayScore,
    confidenceLevel: confidence,
    confidenceReason: confidenceReason,
    defaultCategoryCount: defaultCategoryCount,
    categories: breakdowns,
    topDifferencesThatMatter: topDifferences,
    whyThisMatchWorks: whyThisMatchWorks,
    whatHelpedThisMatch: whatHelped,
  );
}

class _BreakdownSeed {
  const _BreakdownSeed({
    required this.category,
    required this.label,
    required this.matchPercent,
    required this.weight,
    required this.isDefaultA,
    required this.isDefaultB,
    required this.withinTolerance,
    required this.distance,
    required this.tolerance,
    required this.dealbreakerRisk,
    required this.prefA,
    required this.prefB,
  });

  final VibeCategory category;
  final String label;
  final double matchPercent;
  final double weight;
  final bool isDefaultA;
  final bool isDefaultB;
  final bool withinTolerance;
  final int distance;
  final int tolerance;
  final bool dealbreakerRisk;
  final VibePreference prefA;
  final VibePreference prefB;
}

class _ImpactItem {
  const _ImpactItem({
    required this.category,
    required this.impact,
    required this.description,
  });

  final VibeCategory category;
  final double impact;
  final String description;
}

double _strictnessFactor(
  VibeCategory category,
  List<_BreakdownSeed> seeds,
) {
  final seed = seeds.firstWhere((element) => element.category == category);
  if (seed.prefA.dealbreaker || seed.prefB.dealbreaker) {
    return 2.0;
  }
  final minTolerance = min(seed.prefA.threshold, seed.prefB.threshold);
  if (minTolerance <= 1) {
    return 1.5;
  }
  return 1.0;
}

String _differenceDescription(VibeCategory category, bool outsideTolerance) {
  switch (category) {
    case VibeCategory.music:
      return outsideTolerance
          ? 'Music preferences differ and fall outside tolerance.'
          : 'Music preferences differ and could affect the vibe.';
    case VibeCategory.pace:
      return 'Pace expectations could feel mismatched.';
    case VibeCategory.chat:
      return 'Chat level could feel mismatched late in the round.';
    case VibeCategory.money:
      return 'Spending expectations may clash in competitive rounds.';
    case VibeCategory.competitive:
      return 'Competitive intensity may feel uneven during the round.';
    case VibeCategory.drinking:
      return 'Drinking preferences may feel out of sync.';
    case VibeCategory.weed:
      return 'Cannabis comfort levels may feel mismatched.';
  }
}

String _positiveDescription(VibeCategory category) {
  switch (category) {
    case VibeCategory.pace:
      return 'Both prioritize pace of play.';
    case VibeCategory.competitive:
      return 'Similar competitiveness keeps expectations aligned.';
    case VibeCategory.chat:
      return 'Conversation style feels compatible.';
    case VibeCategory.money:
      return 'Spending expectations feel aligned.';
    case VibeCategory.music:
      return 'Music vibe feels compatible.';
    case VibeCategory.drinking:
      return 'Drinking vibe feels compatible.';
    case VibeCategory.weed:
      return 'Cannabis comfort levels align.';
  }
}

String _confidenceReason(VibeConfidence confidence, int defaultCount) {
  String reason;
  switch (confidence) {
    case VibeConfidence.high:
      reason =
          'Most high-impact categories are aligned with minimal unresolved differences.';
      break;
    case VibeConfidence.medium:
      reason =
          'A couple categories are unclear or mismatched, but core fit looks solid.';
      break;
    case VibeConfidence.low:
      reason =
          'Several key categories are missing data or misaligned, so this score is less certain.';
      break;
  }
  if (defaultCount > 0) {
    reason = '$reason $defaultCount categories still default.';
  }
  return reason;
}
