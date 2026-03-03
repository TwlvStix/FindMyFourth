import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';
import 'group_vibe_provider.dart';
import 'game_provider.dart';
import 'join_request_provider.dart';
import 'notification_provider.dart';
import 'notification_list_provider.dart';
import 'profile_provider.dart';
import 'trust_provider.dart';
import 'user_provider.dart';

/// Convenient extensions for accessing providers throughout the app
extension ProviderExtensions on BuildContext {
  /// Access UserProvider without listening for changes
  /// Use this when you just need to call methods or read data once
  UserProvider get userProvider => read<UserProvider>();

  /// Access UserProvider and listen for changes
  /// Use this when you want the widget to rebuild when user data changes
  UserProvider get watchUserProvider => watch<UserProvider>();

  /// Access GameProvider without listening for changes
  GameProvider get gameProvider => read<GameProvider>();

  /// Access GameProvider and listen for changes
  GameProvider get watchGameProvider => watch<GameProvider>();

  /// Access NotificationProvider without listening for changes
  NotificationProvider get notificationProvider => read<NotificationProvider>();

  /// Access NotificationProvider and listen for changes
  NotificationProvider get watchNotificationProvider =>
      watch<NotificationProvider>();

  /// Access JoinRequestProvider without listening for changes
  JoinRequestProvider get joinRequestProvider => read<JoinRequestProvider>();

  /// Access JoinRequestProvider and listen for changes
  JoinRequestProvider get watchJoinRequestProvider =>
      watch<JoinRequestProvider>();

  /// Access GroupVibeProvider without listening for changes
  GroupVibeProvider get groupVibeProvider => read<GroupVibeProvider>();

  /// Access GroupVibeProvider and listen for changes
  GroupVibeProvider get watchGroupVibeProvider => watch<GroupVibeProvider>();

  /// Access NotificationListProvider without listening for changes
  NotificationListProvider get notificationListProvider =>
      read<NotificationListProvider>();

  /// Access NotificationListProvider and listen for changes
  NotificationListProvider get watchNotificationListProvider =>
      watch<NotificationListProvider>();

  /// Select specific data from UserProvider
  /// Only rebuilds when the selected data changes
  ///
  /// Example:
  /// ```dart
  /// final displayName = context.selectUser((provider) => provider.displayName);
  /// ```
  T selectUser<T>(T Function(UserProvider provider) selector) {
    return select<UserProvider, T>(selector);
  }

  // ========================================
  // ADDITIONAL PROVIDER SELECTORS
  // ========================================

  /// Select specific data from GameProvider
  T selectGame<T>(T Function(GameProvider provider) selector) {
    return select<GameProvider, T>(selector);
  }

  /// Select specific data from ChatProvider
  T selectChat<T>(T Function(ChatProvider provider) selector) {
    return select<ChatProvider, T>(selector);
  }

  /// Select specific data from TrustProvider
  T selectTrust<T>(T Function(TrustProvider provider) selector) {
    return select<TrustProvider, T>(selector);
  }

  /// Select specific data from ProfileProvider
  T selectProfile<T>(T Function(ProfileProvider provider) selector) {
    return select<ProfileProvider, T>(selector);
  }

  /// Select specific data from NotificationProvider
  T selectNotification<T>(T Function(NotificationProvider provider) selector) {
    return select<NotificationProvider, T>(selector);
  }

  /// Select specific data from NotificationListProvider
  ///
  /// Use for rebuild boundary optimization:
  /// - `context.selectNotificationList((p) => p.isEmpty)` for app bar visibility
  /// - `context.selectNotificationList((p) => p.listViewState)` for list body
  T selectNotificationList<T>(
      T Function(NotificationListProvider provider) selector) {
    return select<NotificationListProvider, T>(selector);
  }

  // ========================================
  // CONVENIENCE SELECTORS
  // ========================================

  /// Select whether user has pending outgoing request to specific uid
  /// Only rebuilds when the pending state for this specific uid changes
  bool hasPendingOutgoing(String uid) =>
      selectUser((p) => p.hasPendingOutgoingRequest(uid));

  /// Select current user reference only
  DocumentReference? get currentUserRef =>
      selectUser((p) => p.currentUser?.reference);

  /// Select isLoading state only
  bool get userIsLoading => selectUser((p) => p.isLoading);

  /// Select isLoggedIn state only
  bool get userIsLoggedIn => selectUser((p) => p.isLoggedIn);
}

/// Extension for UserProvider to provide common convenience methods
extension UserProviderHelpers on UserProvider {
  /// Get full name of current user
  String get fullName {
    if (firstName.isEmpty && lastName.isEmpty) return displayName;
    return '$firstName $lastName'.trim();
  }

  /// Get user initials for avatar display
  String get initials {
    if (firstName.isEmpty && lastName.isEmpty) {
      return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    }
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return (first + last).toUpperCase();
  }

  /// Check if user profile is complete
  bool get isProfileComplete {
    return displayName.isNotEmpty &&
        firstName.isNotEmpty &&
        lastName.isNotEmpty;
  }

  /// Check if golf profile is set up
  bool get isGolfProfileComplete {
    return homeCourse.isNotEmpty && handicap != 0;
  }

  /// Get a user-friendly handicap display
  String get handicapDisplay {
    if (handicap == 0) return 'Not set';
    if (handicap < 0) {
      return '+${handicap.abs()}'; // Plus handicap: +1, +2, etc.
    }
    return handicap.toString();
  }

  /// Get preference level as string
  String preferenceLevel(int value) {
    if (value == 0) return 'Never';
    if (value <= 1) return 'Rarely';
    if (value <= 2) return 'Sometimes';
    if (value <= 3) return 'Often';
    if (value <= 4) return 'Very Often';
    return 'Always';
  }

  /// Get music preference display
  String get musicPreference => preferenceLevel(music);

  /// Get drinks preference display
  String get drinksPreference => preferenceLevel(drinks);

  /// Get play for money preference display
  String get playForMoneyPreference => preferenceLevel(playForMoney);

  /// Get pace of play preference display
  String get paceOfPlayPreference {
    if (paceOfPlay == 0) return 'Very slow';
    if (paceOfPlay <= 1) return 'Slow';
    if (paceOfPlay <= 2) return 'Moderate';
    if (paceOfPlay <= 3) return 'Average';
    if (paceOfPlay <= 4) return 'Fast';
    return 'Very fast';
  }
}
