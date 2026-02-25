/// Eligibility restrictions for who can join a game based on gender.
enum PlayerEligibility {
  /// Anyone can join regardless of gender
  openToAll,

  /// Only users with gender 'Female' can join
  womenOnly,

  /// Only users with gender 'Male' can join
  menOnly,
}

/// Extension for Firestore serialization of PlayerEligibility.
extension PlayerEligibilityExtension on PlayerEligibility {
  /// Convert enum to Firestore string value.
  String toFirestoreValue() => switch (this) {
        PlayerEligibility.openToAll => 'open_to_all',
        PlayerEligibility.womenOnly => 'women_only',
        PlayerEligibility.menOnly => 'men_only',
      };

  /// Parse Firestore string to enum (defaults to openToAll for unknown values).
  static PlayerEligibility fromFirestoreValue(String? value) => switch (value) {
        'women_only' => PlayerEligibility.womenOnly,
        'men_only' => PlayerEligibility.menOnly,
        _ => PlayerEligibility.openToAll,
      };
}
