import 'dart:async';

/// Data class representing a notification message.
/// Mirrors the structure of a Firebase RemoteMessage for testability.
class TestableNotification {
  const TestableNotification({
    required this.title,
    required this.body,
    required this.data,
  });

  final String title;
  final String body;
  final Map<String, dynamic> data;

  /// Convenience getter for notification type (e.g., 'friend_request_received').
  String? get type => data['type'] as String?;

  /// Convenience getter for deep link route.
  String? get route => data['route'] as String?;

  /// Convenience getter for tab parameter (used in friend notifications).
  String? get tab => data['tab'] as String?;

  @override
  String toString() => 'TestableNotification(title: $title, type: $type)';
}

/// Abstract interface for notification handling.
///
/// The real app uses [FcmNotificationService] which wraps Firebase Messaging.
/// Tests use [FakeNotificationService] which allows injecting notifications.
///
/// This abstraction enables integration testing of notification → navigation
/// flows without depending on real push notifications.
abstract class NotificationService {
  /// Stream of notifications received while app is in foreground.
  Stream<TestableNotification> get onNotificationReceived;

  /// Stream of notification taps (for navigation handling).
  Stream<TestableNotification> get onNotificationTapped;

  /// Dispose of any resources.
  void dispose();
}
