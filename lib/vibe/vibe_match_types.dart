import '/models/vibe_profile.dart';

enum VibeRecommendation {
  recommended,
  caution,
  notRecommended,
}

class VibeHardConflict {
  const VibeHardConflict({
    required this.category,
    required this.myValue,
    required this.theirValue,
    required this.distance,
    required this.thresholdOrLimit,
    required this.reason,
    required this.myDealbreaker,
    required this.theirDealbreaker,
  });

  final VibeCategory category;
  final double myValue;
  final double theirValue;
  final double distance;
  final double thresholdOrLimit;
  final String reason;
  final bool myDealbreaker;
  final bool theirDealbreaker;
}

class VibeSoftRisk {
  const VibeSoftRisk({
    required this.category,
    required this.distance,
    required this.tolerance,
    required this.overBy,
    required this.severity01,
    required this.weight,
    required this.reason,
  });

  final VibeCategory category;
  final double distance;
  final double tolerance;
  final double overBy;
  final double severity01;
  final double weight;
  final String reason;
}
