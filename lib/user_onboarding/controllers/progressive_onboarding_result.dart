// ═══════════════════════════════════════════════════════════════════════════
// PROGRESSIVE ONBOARDING RESULTS
// ═══════════════════════════════════════════════════════════════════════════

/// Failure types for progressive onboarding.
enum OnboardingFailureType {
  /// Form validation failed (missing required fields).
  formInvalid,

  /// Username is already taken.
  usernameTaken,

  /// Email update requires re-authentication.
  /// Widget should show reauth dialog.
  requiresReauth,

  /// Email update failed for another reason.
  emailUpdateFailed,

  /// Cloud function call failed.
  cloudFunctionFailed,

  /// User record not ready after completion.
  userRecordNotReady,

  /// User not authenticated.
  userNotAuthenticated,

  /// Unknown error.
  unknown,
}

/// Result of progressive onboarding submission.
sealed class ProgressiveOnboardingResult {
  const ProgressiveOnboardingResult();
}

/// Onboarding completed successfully.
class OnboardingSuccess extends ProgressiveOnboardingResult {
  const OnboardingSuccess();
}

/// Onboarding failed with a typed reason.
class OnboardingFailure extends ProgressiveOnboardingResult {
  const OnboardingFailure(this.type, this.message);

  final OnboardingFailureType type;
  final String message;
}
