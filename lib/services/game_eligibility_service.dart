import '/models/player_eligibility.dart';

/// Result of an eligibility check for joining a game.
class EligibilityResult {
  const EligibilityResult({
    required this.allowed,
    this.reason,
  });

  /// Whether the user is allowed to join.
  final bool allowed;

  /// Reason code if not allowed (e.g., 'gender_restricted').
  final String? reason;

  /// Factory for allowed result.
  static const EligibilityResult allowedResult = EligibilityResult(allowed: true);

  /// Factory for gender-restricted result.
  static const EligibilityResult genderRestricted = EligibilityResult(
    allowed: false,
    reason: 'gender_restricted',
  );
}

/// Checks if a user is eligible to join a game based on player eligibility rules.
///
/// This is a pure function with no Firestore dependencies for easy testing.
///
/// Parameters:
/// - [eligibility]: The game's player eligibility setting
/// - [userGender]: The user's gender from their profile ('Male' or 'Female')
///
/// Returns [EligibilityResult] indicating if join is allowed and reason if not.
EligibilityResult checkPlayerEligibility({
  required PlayerEligibility eligibility,
  required String? userGender,
}) {
  return switch (eligibility) {
    PlayerEligibility.openToAll => EligibilityResult.allowedResult,
    PlayerEligibility.womenOnly => userGender == 'Female'
        ? EligibilityResult.allowedResult
        : EligibilityResult.genderRestricted,
    PlayerEligibility.menOnly => userGender == 'Male'
        ? EligibilityResult.allowedResult
        : EligibilityResult.genderRestricted,
  };
}
