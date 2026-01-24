class ErrorMessages {
  /// Map Firebase error codes to user-friendly messages
  static String forFirebaseCode(String code) {
    switch (code) {
      // Auth errors
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'requires-recent-login':
        return 'Please log in again to continue.';

      // Firestore errors
      case 'permission-denied':
        return "You don't have permission to access this.";
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      case 'deadline-exceeded':
        return 'Request timed out. Please check your connection.';
      case 'not-found':
        return 'The requested item was not found.';

      // Network errors
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';

      default:
        return 'Something went wrong. Please try again.';
    }
  }

  /// Generic fallback messages by category
  static const String gameNotFound = 'Game not found or no longer available.';
  static const String userNotFound = 'User profile not found.';
  static const String loadingFailed = 'Failed to load data. Pull to refresh.';
  static const String updateFailed = 'Failed to save changes. Please try again.';
  static const String networkError =
      'No internet connection. Please check your network.';
  static const String genericError = 'Something went wrong. Please try again.';
}
