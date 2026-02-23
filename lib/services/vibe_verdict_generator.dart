import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/services/vibe_match_explanation.dart';
import 'package:find_my_fourth/services/vibe_matcher.dart';
import 'package:find_my_fourth/vibe/vibe_match_types.dart';

/// Generates plain-language verdict sentences for vibe match results.
///
/// Takes the structured match data and confidence levels and produces
/// human-readable recommendations in a "caddie's scouting report" style.
String generateVibeVerdict(
  VibeMatchResult result,
  MatchExplanation explanation,
) {
  final recommendation = result.recommendation;
  final confidence = result.confidence;

  // Count watch points and dealbreakers
  final watchPoints = explanation.categories
      .where((c) => c.statusBadge == VibeStatusBadge.watchPoint)
      .toList();

  final dealbreakers = explanation.categories
      .where((c) => c.statusBadge == VibeStatusBadge.dealbreakerRisk)
      .toList();

  // Dealbreaker risk - strongest warning
  if (dealbreakers.isNotEmpty) {
    return "Major dealbreaker conflict. Not recommended.";
  }

  // By recommendation level
  switch (recommendation) {
    case VibeRecommendation.recommended:
      if (confidence == VibeConfidence.high) {
        return "Great fit on the things that matter most.";
      } else if (confidence == VibeConfidence.medium) {
        return "Looks promising, but a few categories still default.";
      } else {
        return "Could be a good match, but limited data to be sure.";
      }

    case VibeRecommendation.caution:
      if (watchPoints.isEmpty) {
        return "Solid match with a few minor differences.";
      } else if (watchPoints.length == 1) {
        final categoryName = _getCategoryLabel(watchPoints.first.category);
        return "Worth chatting about ${categoryName.toLowerCase()} expectations.";
      } else {
        final topCategories = _getTopWatchPointCategories(watchPoints, 2);
        return "Tension around $topCategories. Worth chatting first.";
      }

    case VibeRecommendation.notRecommended:
      return "Significant mismatches on core vibes. Proceed carefully.";
  }
}

/// Gets the display label for a watch point category
String _getCategoryLabel(VibeCategory category) {
  switch (category) {
    case VibeCategory.pace:
      return 'Pace';
    case VibeCategory.competitive:
      return 'Competitive style';
    case VibeCategory.drinking:
      return 'Drinking';
    case VibeCategory.chat:
      return 'Chat';
    case VibeCategory.money:
      return 'Money';
    case VibeCategory.music:
      return 'Music';
  }
}

/// Gets formatted string of top N watch point categories
String _getTopWatchPointCategories(
  List<CategoryBreakdown> watchPoints,
  int count,
) {
  // Sort by weight (highest first)
  final sorted = watchPoints.toList()
    ..sort((a, b) => b.weight.compareTo(a.weight));

  final topCategories = sorted.take(count).map((c) {
    final label = _getCategoryLabel(c.category);
    return label.toLowerCase();
  }).toList();

  if (topCategories.length == 1) {
    return topCategories.first;
  } else if (topCategories.length == 2) {
    return "${topCategories[0]} and ${topCategories[1]}";
  } else {
    // For 3+, join with commas and 'and' for last item
    final allButLast = topCategories.sublist(0, topCategories.length - 1);
    final last = topCategories.last;
    return "${allButLast.join(', ')}, and $last";
  }
}
