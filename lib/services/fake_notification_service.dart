import 'dart:async';
import 'notification_service.dart';

/// Test fake that allows injecting notifications manually.
///
/// Use this in integration tests instead of the real FCM service.
/// Provides [simulateNotification] and [simulateTap] methods to trigger
/// the notification streams, enabling testing of the full notification
/// → navigation flow without actual push notifications.
///
/// Example usage in tests:
/// ```dart
/// final fakeNotifications = FakeNotificationService();
///
/// // Simulate receiving a friend request notification
/// fakeNotifications.simulateNotification(
///   title: 'New friend request',
///   body: 'Alice wants to connect with you.',
///   data: {
///     'type': 'friend_request_received',
///     'route': '/friends',
///     'tab': 'requests',
///     'sender_name': 'Alice',
///     'sender_id': 'user_123',
///   },
/// );
///
/// // Simulate user tapping the notification
/// fakeNotifications.simulateTap(
///   title: 'New friend request',
///   body: 'Alice wants to connect with you.',
///   data: {'type': 'friend_request_received', 'route': '/friends', 'tab': 'requests'},
/// );
/// ```
class FakeNotificationService implements NotificationService {
  final _notificationController =
      StreamController<TestableNotification>.broadcast();
  final _tapController = StreamController<TestableNotification>.broadcast();

  /// Track received notifications for assertions in tests.
  final List<TestableNotification> receivedNotifications = [];

  /// Track tapped notifications for assertions in tests.
  final List<TestableNotification> tappedNotifications = [];

  @override
  Stream<TestableNotification> get onNotificationReceived =>
      _notificationController.stream;

  @override
  Stream<TestableNotification> get onNotificationTapped => _tapController.stream;

  /// Simulate receiving a foreground notification.
  ///
  /// This adds the notification to [receivedNotifications] and emits it
  /// on the [onNotificationReceived] stream.
  void simulateNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    final notification = TestableNotification(
      title: title,
      body: body,
      data: data,
    );
    receivedNotifications.add(notification);
    _notificationController.add(notification);
  }

  /// Simulate the user tapping a notification.
  ///
  /// This adds the notification to [tappedNotifications] and emits it
  /// on the [onNotificationTapped] stream, which should trigger navigation.
  void simulateTap({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    final notification = TestableNotification(
      title: title,
      body: body,
      data: data,
    );
    tappedNotifications.add(notification);
    _tapController.add(notification);
  }

  /// Reset state between test cases.
  void reset() {
    receivedNotifications.clear();
    tappedNotifications.clear();
  }

  @override
  void dispose() {
    _notificationController.close();
    _tapController.close();
  }
}
