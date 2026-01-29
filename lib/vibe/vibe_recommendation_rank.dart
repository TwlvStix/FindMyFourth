import '/vibe/vibe_match_types.dart';

int recommendationRank(VibeRecommendation recommendation) {
  switch (recommendation) {
    case VibeRecommendation.recommended:
      return 0;
    case VibeRecommendation.caution:
      return 1;
    case VibeRecommendation.notRecommended:
      return 2;
  }
}
