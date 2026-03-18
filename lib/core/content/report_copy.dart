/// Microcopy constants for report and block flows.
///
/// Voice: Neutral, procedural. No emoji, no blame.
library;

class ReportReasons {
  ReportReasons._();

  static const String inappropriateBehavior = 'inappropriate_behavior';
  static const String harassment = 'harassment';
  static const String spam = 'spam';
  static const String fakeProfile = 'fake_profile';
  static const String other = 'other';

  static const List<String> all = [
    inappropriateBehavior,
    harassment,
    spam,
    fakeProfile,
    other,
  ];

  static String displayLabel(String reason) {
    switch (reason) {
      case inappropriateBehavior:
        return 'Inappropriate behavior';
      case harassment:
        return 'Harassment';
      case spam:
        return 'Spam';
      case fakeProfile:
        return 'Fake profile';
      case other:
        return 'Other';
      default:
        return reason;
    }
  }
}

class ReportBlockCopy {
  ReportBlockCopy._();

  // Report flow
  static const String reportTitle = 'Report user';
  static const String reportSubmitted = 'Report submitted. Thank you.';
  static const String reportFailed =
      'We couldn\'t submit your report. Please try again.';
  static const String reportDetailsHint =
      'Provide any additional details (optional)';
  static const String submitReport = 'Submit';

  // Block flow
  static String blockTitle(String name) => 'Block $name?';
  static const String blockBody =
      'They won\'t be able to see your games or contact you. '
      'You can unblock them later in Settings.';
  static const String blockAction = 'Block';
  static const String userBlocked = 'User blocked.';
  static const String userUnblocked = 'User unblocked.';
  static const String blockFailed =
      'We couldn\'t block this user. Please try again.';
  static const String unblockFailed =
      'We couldn\'t unblock this user. Please try again.';

  // Blocked users list
  static const String blockedUsersTitle = 'Blocked users';
  static const String noBlockedUsersTitle = 'No blocked users';
  static const String unblock = 'Unblock';
}
