/// Centralized input sanitization for user-generated content.
///
/// Applied at the service layer as a backend safety net before Firestore writes.
/// Trims whitespace and enforces max-length limits on all user-typed text fields.
class InputSanitizer {
  InputSanitizer._();

  // ─── Max Length Constants ───────────────────────────────────────────────────
  static const int maxDisplayName = 30;
  static const int maxFirstName = 50;
  static const int maxLastName = 50;
  static const int maxGameName = 100;
  static const int maxChatMessage = 2000;
  static const int maxBio = 500;
  static const int maxGolfCanadaNumber = 20;
  static const int maxPhoneNumber = 15;
  static const int maxUsername = 30;
  static const int maxGeneric = 500;

  // ─── Core Method ───────────────────────────────────────────────────────────

  /// Trims whitespace and truncates to [maxLength].
  ///
  /// Returns `null` if [value] is `null`. Trim is applied before truncation
  /// so that leading/trailing whitespace does not consume the length budget.
  static String? sanitize(String? value, {int maxLength = maxGeneric}) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.length <= maxLength) return trimmed;
    return trimmed.substring(0, maxLength);
  }

  // ─── Convenience Methods ───────────────────────────────────────────────────

  static String? displayName(String? value) =>
      sanitize(value, maxLength: maxDisplayName);

  static String? firstName(String? value) =>
      sanitize(value, maxLength: maxFirstName);

  static String? lastName(String? value) =>
      sanitize(value, maxLength: maxLastName);

  static String? gameName(String? value) =>
      sanitize(value, maxLength: maxGameName);

  static String? chatMessage(String? value) =>
      sanitize(value, maxLength: maxChatMessage);

  static String? bio(String? value) =>
      sanitize(value, maxLength: maxBio);

  static String? golfCanadaNumber(String? value) =>
      sanitize(value, maxLength: maxGolfCanadaNumber);

  static String? phoneNumber(String? value) =>
      sanitize(value, maxLength: maxPhoneNumber);

  static String? username(String? value) =>
      sanitize(value, maxLength: maxUsername);
}
