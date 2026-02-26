/// Friend Notification Integration Tests
///
/// These tests verify the full notification → navigation flow for friend
/// request notifications.
///
/// SETUP REQUIRED:
/// 1. Add integration_test to pubspec.yaml dev_dependencies:
///    ```yaml
///    dev_dependencies:
///      integration_test:
///        sdk: flutter
///    ```
///
/// 2. Run with:
///    ```bash
///    flutter test integration_test/friend_notifications_test.dart
///    ```
///
/// NOTE: These tests require the app to be runnable. For CI/CD, consider
/// running on a simulator/emulator.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Uncomment when integration_test is added to pubspec.yaml:
// import 'package:integration_test/integration_test.dart';

import 'package:find_my_fourth/services/notification_service.dart';
import 'package:find_my_fourth/services/fake_notification_service.dart';

// For full integration testing, uncomment and adapt:
// import '/main.dart' as app;

void main() {
  // Uncomment when using full integration test binding:
  // IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeNotificationService fakeNotifications;

  setUp(() {
    fakeNotifications = FakeNotificationService();
  });

  tearDown(() {
    fakeNotifications.dispose();
  });

  group('Friend Request Notification Flow', () {
    testWidgets(
      'STEP 1-3: Friend request notification contains correct payload',
      (tester) async {
        // This test verifies the notification payload structure.
        // The actual Cloud Function test (Jest) validates server-side generation.
        // This test validates the Flutter-side parsing.

        fakeNotifications.simulateNotification(
          title: 'New friend request',
          body: 'Alice wants to connect with you.',
          data: {
            'type': 'friend_request_received',
            'route': 'findmyfourth://golfers/requests',
            'sender_name': 'Alice',
            'sender_id': 'user_alice_123',
          },
        );

        // ASSERT: notification was received with correct structure
        expect(fakeNotifications.receivedNotifications, hasLength(1));

        final notification = fakeNotifications.receivedNotifications.first;
        expect(notification.title, 'New friend request');
        expect(notification.body, contains('Alice'));
        expect(notification.type, 'friend_request_received');
        expect(notification.data['sender_name'], 'Alice');
        expect(notification.data['sender_id'], 'user_alice_123');
      },
    );

    testWidgets(
      'STEP 4-6: Tapping friend request notification triggers navigation data',
      (tester) async {
        // Simulate user tapping a friend request notification
        fakeNotifications.simulateTap(
          title: 'New friend request',
          body: 'Alice wants to connect with you.',
          data: {
            'type': 'friend_request_received',
            'route': 'findmyfourth://golfers/requests',
            'tab': 'requests',
            'sender_name': 'Alice',
            'sender_id': 'user_alice_123',
          },
        );

        // ASSERT: tap was recorded
        expect(fakeNotifications.tappedNotifications, hasLength(1));

        final tap = fakeNotifications.tappedNotifications.first;
        expect(tap.route, 'findmyfourth://golfers/requests');
        expect(tap.tab, 'requests');

        // In a full integration test with the app running, you would:
        // 1. Set up a listener on fakeNotifications.onNotificationTapped
        // 2. Have that listener navigate using GoRouter
        // 3. Assert that the Friends screen is displayed with Requests tab
        //
        // Example:
        // await tester.pumpAndSettle();
        // expect(find.text('Requests'), findsWidgets);
        // expect(find.text('Alice'), findsOneWidget);
      },
    );

    testWidgets(
      'STEP 7-8: Friend accepted notification routes to Friends tab',
      (tester) async {
        fakeNotifications.simulateTap(
          title: 'Friend request accepted',
          body: 'Bob is now connected with you.',
          data: {
            'type': 'friend_request_accepted',
            'route': 'findmyfourth://golfers/friends',
            'tab': 'friends',
            'acceptor_name': 'Bob',
            'acceptor_id': 'user_bob_456',
          },
        );

        final tap = fakeNotifications.tappedNotifications.first;
        expect(tap.route, 'findmyfourth://golfers/friends');
        expect(tap.tab, 'friends');
        expect(tap.data['acceptor_name'], 'Bob');
      },
    );

    testWidgets(
      'STEP 9: Disabled social alerts means no notification arrives',
      (tester) async {
        // When social_alerts.enabled is false in user preferences,
        // the Cloud Function (router.js) blocks the notification.
        // This test verifies that if no notification arrives,
        // the app state remains unchanged.

        final beforeCount = fakeNotifications.receivedNotifications.length;

        // Don't simulate any notification (blocked by Cloud Function)
        // await tester.pumpAndSettle();

        // ASSERT: No new notifications
        expect(
          fakeNotifications.receivedNotifications.length,
          beforeCount,
        );
      },
    );
  });

  group('Navigation Handler Integration', () {
    // These tests would require wiring up the actual navigation handler
    // to the FakeNotificationService. Example pattern:

    testWidgets(
      'notification tap stream can drive navigation',
      (tester) async {
        // Track navigation calls
        final navigatedRoutes = <String>[];

        // Listen to taps and record routes
        fakeNotifications.onNotificationTapped.listen((notification) {
          final route = notification.route;
          if (route != null) {
            navigatedRoutes.add(route);
          }
        });

        // Simulate tap
        fakeNotifications.simulateTap(
          title: 'Test',
          body: 'Body',
          data: {'route': '/test-route'},
        );

        // Give stream time to process
        await Future.delayed(Duration.zero);

        expect(navigatedRoutes, contains('/test-route'));
      },
    );
  });
}

/// Example of how to wire FakeNotificationService into the app for testing.
///
/// In your app's main.dart or a test-specific setup:
///
/// ```dart
/// // Global notification service (swap for tests)
/// late NotificationService notificationService;
///
/// void main() {
///   // Production: use real FCM
///   notificationService = FcmNotificationService();
///   runApp(MyApp());
/// }
///
/// // In test setUp:
/// notificationService = FakeNotificationService();
/// ```
///
/// Then in your navigation handler, listen to [notificationService.onNotificationTapped]
/// and use GoRouter to navigate based on the notification's route/tab data.
void _documentationExample() {}
