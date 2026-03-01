/// Find My Fourth - Microcopy Constants
///
/// This file contains reusable copy strings that follow the brand voice guidelines.
/// See: MicroCopy FM4.pdf for full tone documentation.
///
/// Voice: Quiet confidence. Clear, composed, trustworthy.
/// Tone: Calm and precise. Not playful, not loud, not pretentious.
///
/// Rules:
/// - No emoji in system messages, errors, or trust flows
/// - No exclamation marks in system flows
/// - Sentence case everywhere
/// - Short, complete sentences
/// - Clear over clever
library;

// =============================================================================
// CONFIRMATIONS
// =============================================================================

/// Copy for successful actions - neutral, factual confirmation
class AppConfirmations {
  AppConfirmations._();

  // Round/Game confirmations
  static const String spotConfirmed = 'You\'re confirmed for this round.';
  static const String spotSecured = 'Your spot is secured.';
  static const String requestSent = 'Your request has been sent.';
  static const String roundScheduled = 'Your round is scheduled.';
  static const String roundCreated = 'Your round has been created.';
  static const String roundUpdated = 'Your round has been updated.';
  static const String roundCanceled = 'Your round has been canceled.';
  static const String leftRound = 'You\'ve left this round.';

  // Player/Host confirmations
  static const String playerApproved = 'Player has been approved.';
  static const String playerRemoved = 'Player has been removed.';
  static const String requestApproved = 'Request approved.';
  static const String requestDeclined = 'Request declined.';

  // Profile confirmations
  static const String profileUpdated = 'Your profile has been updated.';
  static const String preferencesUpdated = 'Your preferences have been updated.';
  static const String photoUpdated = 'Your photo has been updated.';

  // Social confirmations
  static const String friendRequestSent = 'Friend request sent.';
  static const String friendRequestAccepted = 'Friend request accepted.';
  static const String friendRemoved = 'Friend removed.';

  // Settings confirmations
  static const String settingsSaved = 'Your settings have been saved.';
  static const String notificationsUpdated = 'Notification preferences updated.';
}

// =============================================================================
// ERRORS
// =============================================================================

/// Copy for error states - state what happened, then what to do
class AppErrors {
  AppErrors._();

  // Generic errors
  static const String genericError = 'Something went wrong. Please try again.';
  static const String connectionError =
      'Unable to connect. Check your connection and try again.';
  static const String loadError = 'We couldn\'t load this content. Try again.';
  static const String saveError =
      'We couldn\'t save your changes. Please try again.';
  static const String timeoutError = 'Request timed out. Please try again.';

  // Round/Game errors
  static const String roundLoadError = 'We couldn\'t load this round.';
  static const String roundFullError = 'This round is now full.';
  static const String roundUnavailableError = 'This round is no longer available.';
  static const String roundJoinError =
      'We couldn\'t add you to this round. Please try again.';
  static const String roundCreateError =
      'We couldn\'t create your round. Please try again.';
  static const String roundUpdateError =
      'We couldn\'t update this round. Please try again.';
  static const String alreadyJoinedError = 'You\'re already in this round.';

  // Request errors
  static const String requestNotSent =
      'Your request wasn\'t sent. Please try again.';
  static const String requestError =
      'We couldn\'t process your request. Please try again.';

  // Profile errors
  static const String profileLoadError = 'We couldn\'t load this profile.';
  static const String profileUpdateError =
      'We couldn\'t update your profile. Please try again.';

  // Auth errors
  static const String signInError =
      'We couldn\'t sign you in. Please try again.';
  static const String signOutError =
      'We couldn\'t sign you out. Please try again.';
  static const String sessionExpired =
      'Your session has expired. Please sign in again.';

  // Permission errors
  static const String permissionDenied =
      'You don\'t have permission to do this.';
  static const String locationPermissionDenied =
      'Location access is required for this feature.';
}

// =============================================================================
// EMPTY STATES
// =============================================================================

/// Empty state copy following the Empty-State Language Quality Standard.
///
/// Patterns:
/// - **Pattern A (Informational Neutral)**: Low-stakes, no action suggested
/// - **Pattern B (Informational + Forward)**: User can change the outcome
/// - **Pattern C (Time-Dependent Reassurance)**: Availability fluctuates
/// - **Pattern D (Procedural State)**: Restricted/paused/system conditions
/// - **Pattern E (Early Lifecycle)**: New user hasn't engaged yet
///
/// Rules:
/// - No emotional framing (no sadness, celebration, hype)
/// - No blame language
/// - No finality unless truly permanent
/// - Stay neutral and time-aware
/// - No emoji, exclamation marks, or motivational phrases
class AppEmptyStates {
  AppEmptyStates._();

  // ===========================================================================
  // PATTERN A: Informational Neutral (low-stakes screens)
  // Structure: What is happening. No action suggested.
  // Note: Pattern A typically has title only, no message needed.
  // ===========================================================================

  /// Notifications - Pattern A (title only)
  static const String noNotificationsTitle = 'No new notifications';

  /// Recent activity - Pattern A (title only)
  static const String noRecentActivityTitle = 'No recent activity';

  /// Saved items - Pattern A (title only)
  static const String noSavedGroupsTitle = 'No saved groups';

  /// Mutual friends - Pattern A (title only)
  static const String noMutualFriendsTitle = 'No mutual friends';

  // ===========================================================================
  // PATTERN B: Informational + Forward Option (user can change outcome)
  // Structure: What is happening. Clear, optional next step.
  // ===========================================================================

  /// Games list filtered - Pattern B
  static const String noGamesTitle = 'No compatible groups for this time';
  static const String noGamesMessage =
      'Adjust your date or filters to see more options.';

  /// Games nearby - Pattern B
  static const String noGamesNearbyTitle = 'No rounds nearby';
  static const String noGamesNearbyMessage =
      'Try expanding your search radius.';

  /// Upcoming rounds - Pattern B
  static const String noUpcomingGamesTitle = 'No upcoming rounds';
  static const String noUpcomingGamesMessage =
      'Explore available groups to get started.';

  /// Search results - Pattern B
  static const String noSearchResultsTitle = 'No results found';
  static const String noSearchResultsMessage = 'Try a different search term.';

  /// Matches - Pattern B
  static const String noMatchesTitle = 'No high-compatibility groups available right now';
  static const String noMatchesMessage =
      'Adjust your filters to see more options.';

  // ===========================================================================
  // PATTERN C: Time-Dependent Reassurance (availability fluctuates)
  // Structure: Current state. Subtle time cue.
  // ===========================================================================

  /// Games available - Pattern C
  static const String noGamesRightNowTitle = 'No groups available right now';
  static const String noGamesRightNowMessage = 'New groups are added regularly.';

  /// Player requests (for hosts) - Pattern C
  static const String noPlayerRequestsTitle = 'No player requests yet';
  static const String noPlayerRequestsMessage =
      'Requests will appear here as players apply.';

  /// Friend requests - Pattern C
  static const String noFriendRequestsTitle = 'No pending requests';
  static const String noFriendRequestsMessage =
      'Friend requests will appear here.';

  /// Chat messages - Pattern C
  static const String noMessagesTitle = 'No messages yet';
  static const String noMessagesMessage = 'Messages will appear here.';

  /// Game alerts - Pattern C
  static const String noAlertsTitle = 'No matching rounds yet';
  static const String noAlertsMessage =
      'You\'ll be notified when rounds match your alert criteria.';

  // ===========================================================================
  // PATTERN D: Procedural State (restricted/paused/system conditions)
  // Structure: Clear status. What governs this state.
  // ===========================================================================

  /// Requests paused - Pattern D
  static const String requestsPausedTitle = 'Requests are temporarily paused';
  static const String requestsPausedMessage =
      'You\'ll be notified when submissions reopen.';

  /// Profile review - Pattern D
  static const String profileReviewTitle = 'Profile review in progress';
  static const String profileReviewMessage = 'This usually takes up to 24 hours.';

  /// Account restricted - Pattern D
  static const String accountRestrictedTitle = 'Account restricted';
  static const String accountRestrictedMessage =
      'Review your standing for more details.';

  /// Feature unavailable - Pattern D
  static const String featureUnavailableTitle = 'This feature is unavailable';
  static const String featureUnavailableMessage =
      'Check back later or contact support.';

  // ===========================================================================
  // PATTERN E: Early Lifecycle State (new user hasn't engaged)
  // Structure: Current state. First action (instructional, not corrective).
  // ===========================================================================

  /// No rounds booked - Pattern E
  static const String noRoundsBookedTitle = 'No rounds booked yet';
  static const String noRoundsBookedMessage =
      'Browse available groups to get started.';

  /// No past rounds - Pattern E
  static const String noPastGamesTitle = 'No completed rounds';
  static const String noPastGamesMessage =
      'Your round history will appear here.';

  /// No friends - Pattern E
  static const String noFriendsTitle = 'No friends added yet';
  static const String noFriendsMessage =
      'Search for players to connect with.';

  /// No preferences - Pattern E
  static const String noPreferencesTitle = 'No preferences set';
  static const String noPreferencesMessage =
      'Complete your profile to improve matching.';

  /// No chats - Pattern E
  static const String noChatsTitle = 'No conversations yet';
  static const String noChatsMessage =
      'Chat threads appear when you join rounds.';
}

/// Enum for empty state pattern types (for widget configuration)
enum EmptyStatePattern {
  /// Low-stakes informational (Pattern A)
  informational,

  /// User can take action (Pattern B)
  informationalWithAction,

  /// Availability fluctuates (Pattern C)
  timeDependent,

  /// System/restricted state (Pattern D)
  procedural,

  /// New user state (Pattern E)
  earlyLifecycle,
}

/// Escalation levels for empty state tone calibration
enum EmptyStateStakes {
  /// Notifications, saved items - pure informational
  low,

  /// Search results, booking - neutral + optional forward action
  medium,

  /// Trust limitations, suspended features - procedural clarity only
  high,
}

// =============================================================================
// NOTIFICATIONS
// =============================================================================

/// Copy for push notifications and in-app notifications
class AppNotifications {
  AppNotifications._();

  // Match/Game notifications
  static const String newMatch = 'You have a new match.';
  static const String requestApproved = 'A host approved your request.';
  static const String playerJoined = 'A player joined your round.';
  static const String playerLeft = 'A player left your round.';
  static const String roundCanceled = 'A round you joined has been canceled.';
  static const String roundUpdated = 'A round you joined has been updated.';
  static const String roundReminder = 'Your round is coming up.';
  static const String roundStartingSoon = 'Your round starts soon.';

  // Request notifications
  static const String newRequest = 'You have a new join request.';
  static const String requestDeclined = 'Your request was declined.';

  // Join request notifications (vibe floor)
  static const String joinRequestReceivedPrefix = 'Requesting to join';
  static const String joinRequestApprovedTitle = 'You\'re in';
  static String joinRequestApprovedBody(String ownerName, String gameName) =>
      '$ownerName approved your request for $gameName';
  static const String joinRequestDeclinedBody =
      'Your request wasn\'t approved this time';
  static const String roundFilledBeforeApproval =
      'This round filled before your request was reviewed';
  static const String joinRequestExpiredBody =
      'This round has passed. Your request was not reviewed in time.';

  // Social notifications
  static const String newFriendRequest = 'You have a new friend request.';
  static const String friendRequestAccepted =
      'Your friend request was accepted.';

  // Chat notifications
  static const String newMessage = 'You have a new message.';
}

// =============================================================================
// BUTTON LABELS
// =============================================================================

/// Button copy - max 3 words, clear action verbs
class AppButtonLabels {
  AppButtonLabels._();

  // Primary actions
  static const String requestSpot = 'Request spot';
  static const String joinRound = 'Join round';
  static const String confirmRound = 'Confirm round';
  static const String createRound = 'Create round';
  static const String leaveRound = 'Leave round';
  static const String cancelRound = 'Cancel round';

  // Secondary actions
  static const String updatePreferences = 'Update preferences';
  static const String editProfile = 'Edit profile';
  static const String saveChanges = 'Save changes';
  static const String viewDetails = 'View details';
  static const String seeAll = 'See all';

  // Player management
  static const String approveRequest = 'Approve';
  static const String declineRequest = 'Decline';
  static const String removePlayer = 'Remove player';

  // Social
  static const String addFriend = 'Add friend';
  static const String removeFriend = 'Remove friend';
  static const String acceptRequest = 'Accept';
  static const String sendMessage = 'Send message';

  // Navigation
  static const String done = 'Done';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String continueAction = 'Continue';
  static const String back = 'Back';
  static const String next = 'Next';
  static const String skip = 'Skip';
  static const String tryAgain = 'Try again';
  static const String retry = 'Retry';

  // Auth
  static const String signIn = 'Sign in';
  static const String signUp = 'Sign up';
  static const String signOut = 'Sign out';
}

// =============================================================================
// FIELD LABELS
// =============================================================================

/// Field labels - simple nouns, no personality
class AppFieldLabels {
  AppFieldLabels._();

  // Profile fields
  static const String displayName = 'Display name';
  static const String email = 'Email';
  static const String phone = 'Phone';
  static const String handicap = 'Handicap';
  static const String homeCourse = 'Home course';
  static const String location = 'Location';
  static const String bio = 'Bio';

  // Preferences
  static const String pacePreference = 'Pace preference';
  static const String competitiveLevel = 'Competitive level';
  static const String playStyle = 'Play style';
  static const String bettingPreference = 'Betting preference';

  // Round fields
  static const String course = 'Course';
  static const String date = 'Date';
  static const String teeTime = 'Tee time';
  static const String spotsAvailable = 'Spots available';
  static const String groupSize = 'Group size';
  static const String walkingRiding = 'Walking or riding';
  static const String gameType = 'Game type';
  static const String notes = 'Notes';
}

// =============================================================================
// TRUST & SENSITIVE AREAS
// =============================================================================

/// Copy for trust-sensitive flows - neutral, procedural, no judgment
class AppTrustCopy {
  AppTrustCopy._();

  // Vibe/Rating explanations
  static const String vibeScoreExplanation =
      'Your vibe score reflects feedback from completed rounds.';
  static const String trustScoreExplanation =
      'Your trust score is based on your reliability and behavior.';

  // Cancellation copy (no blame)
  static const String lateCancellation =
      'This cancellation falls within the late window.';
  static const String cancellationRecorded =
      'This cancellation has been recorded.';
  static const String cancellationPolicy =
      'Cancellations within 24 hours of tee time may affect your trust score.';

  // Restriction copy
  static const String accountRestricted = 'Your account is currently restricted.';
  static String restrictionEndsAt(String date) =>
      'This restriction ends on $date.';

  // Report copy
  static const String reportSubmitted = 'Your report has been submitted.';
  static const String reportUnderReview = 'This report is under review.';
}

// =============================================================================
// ONBOARDING
// =============================================================================

/// Onboarding copy - the only place with mild warmth
class AppOnboardingCopy {
  AppOnboardingCopy._();

  static const String welcomeTitle = 'Find your group';
  static const String welcomeMessage =
      'We\'ll help you find the right group.';

  static const String preferencesTitle = 'Set your preferences';
  static const String preferencesMessage =
      'Set your preferences so we can match you accurately.';

  static const String handicapTitle = 'Your handicap';
  static const String handicapMessage =
      'This helps us match you with compatible players.';

  static const String vibeTitle = 'How do you play?';
  static const String vibeMessage =
      'Tell us about your play style and preferences.';

  static const String locationTitle = 'Where do you play?';
  static const String locationMessage =
      'We\'ll show you rounds near your preferred courses.';

  static const String notificationsTitle = 'Stay updated';
  static const String notificationsMessage =
      'Get notified when new rounds match your preferences.';

  static const String completeTitle = 'You\'re all set';
  static const String completeMessage =
      'Start browsing rounds or create your own.';
}

// =============================================================================
// HOST VS JOINER
// =============================================================================

/// Context-specific copy for hosts and joiners
class AppRoleCopy {
  AppRoleCopy._();

  // Host copy (control clarity)
  static const String hostReviewMessage =
      'You\'ll review player requests before confirming.';
  static const String hostApprovalRequired =
      'Players must be approved before joining.';
  static const String hostCanRemove =
      'You can remove players from your round at any time.';

  // Joiner copy (reassurance clarity)
  static const String joinerReviewMessage =
      'Your request will be reviewed by the host.';
  static const String joinerPendingMessage =
      'Your request is pending host approval.';
  static const String joinerConfirmedMessage =
      'You\'re confirmed for this round.';
}

// =============================================================================
// HELPER TEXT / HINTS
// =============================================================================

/// Helper text and input hints
class AppHelperText {
  AppHelperText._();

  static const String handicapHint = 'Enter your USGA handicap index';
  static const String searchCoursesHint = 'Search courses';
  static const String searchPlayersHint = 'Search players';
  static const String messageHint = 'Type a message';
  static const String notesHint = 'Add any additional details for players';
  static const String bioHint = 'Tell others about yourself';
}

// =============================================================================
// VIBE FLOOR
// =============================================================================

/// Copy for vibe floor bottom sheet and join button states
class AppVibeFloorCopy {
  AppVibeFloorCopy._();

  // Bottom sheet - mismatch state
  static const String mismatchTitle = 'Approval needed';
  static String mismatchBody(String ownerName) =>
      'This round\'s play style differs from yours in a few areas. $ownerName will review your request.';
  static const String requestToJoinButton = 'Request to join';
  static const String notNowButton = 'Not now';

  // Bottom sheet - confirmation state
  static const String requestSentTitle = 'Request sent';
  static String requestSentBody(String ownerName) =>
      '$ownerName has been notified. You\'ll receive a notification if approved.';
  static const String doneButton = 'Done';

  // Join button states
  static const String joinRoundButton = 'Join round';
  static const String requestPendingButton = 'Request pending';
  static const String requestDeclinedButton = 'Request declined';
  static const String requestDeclinedSubtitle =
      'The owner is looking for a different play style this round.';

  // Game creation toggle
  static const String requireVibeMatchLabel = 'Require vibe match';
  static const String requireVibeMatchDescription =
      'Players with a different play style will need your approval';

  // Request card states (owner view)
  static const String pendingRequestsHeader = 'Pending requests';
  static const String howStylesCompare = 'How your styles compare';
  static String approvedNotification(String playerName) =>
      'Approved — $playerName has been notified';
  static const String declinedStatus = 'Declined';

  // Error states
  static const String roundFullError = 'This round is now full';

  // Request expired state
  static const String requestExpiredButton = 'Round has passed';
}

// =============================================================================
// VIBE EDIT
// =============================================================================

/// Copy for vibe profile edit cooldown
class AppVibeEditCopy {
  AppVibeEditCopy._();

  // Cooldown banner (shown in EditVibesWidget when in cooldown)
  static String cooldownBannerMessage(String date) =>
      'Your vibe profile can be updated on $date.';
  static const String cooldownBannerSubtitle =
      'Vibe profiles can be updated every 30 days to keep matchmaking accurate.';

  // Cooldown button text
  static String cooldownButtonText(String date) => 'Edit available $date';

  // Confirmation dialog (shown before confirming vibe changes)
  static const String confirmDialogTitle = 'Lock in your vibes?';
  static const String confirmDialogBody =
      'Once confirmed, your vibe preferences will be locked for 30 days. '
      'Make sure your settings reflect how you really want to play.';
  static const String confirmDialogAction = 'Confirm vibes';
  static const String confirmDialogCancel = 'Review changes';
}
