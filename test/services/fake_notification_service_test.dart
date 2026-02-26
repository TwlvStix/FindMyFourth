import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:find_my_fourth/services/notification_service.dart';
import 'package:find_my_fourth/services/fake_notification_service.dart';

void main() {
  group('FakeNotificationService', () {
    late FakeNotificationService service;

    setUp(() {
      service = FakeNotificationService();
    });

    tearDown(() {
      service.dispose();
    });

    group('simulateNotification', () {
      test('adds notification to receivedNotifications list', () {
        service.simulateNotification(
          title: 'New friend request',
          body: 'Alice wants to connect with you.',
          data: {
            'type': 'friend_request_received',
            'sender_name': 'Alice',
          },
        );

        expect(service.receivedNotifications, hasLength(1));
        expect(service.receivedNotifications.first.title, 'New friend request');
        expect(service.receivedNotifications.first.type, 'friend_request_received');
      });

      test('emits notification on onNotificationReceived stream', () async {
        final completer = Completer<TestableNotification>();
        service.onNotificationReceived.listen(completer.complete);

        service.simulateNotification(
          title: 'Test',
          body: 'Body',
          data: {'type': 'test'},
        );

        final notification = await completer.future.timeout(
          const Duration(seconds: 1),
        );
        expect(notification.title, 'Test');
      });

      test('multiple notifications are tracked in order', () {
        service.simulateNotification(
          title: 'First',
          body: 'First body',
          data: {'order': '1'},
        );
        service.simulateNotification(
          title: 'Second',
          body: 'Second body',
          data: {'order': '2'},
        );

        expect(service.receivedNotifications, hasLength(2));
        expect(service.receivedNotifications[0].title, 'First');
        expect(service.receivedNotifications[1].title, 'Second');
      });
    });

    group('simulateTap', () {
      test('adds notification to tappedNotifications list', () {
        service.simulateTap(
          title: 'Friend request accepted',
          body: 'Bob is now connected with you.',
          data: {
            'type': 'friend_request_accepted',
            'route': '/friends',
            'tab': 'friends',
          },
        );

        expect(service.tappedNotifications, hasLength(1));
        expect(service.tappedNotifications.first.type, 'friend_request_accepted');
        expect(service.tappedNotifications.first.route, '/friends');
        expect(service.tappedNotifications.first.tab, 'friends');
      });

      test('emits notification on onNotificationTapped stream', () async {
        final completer = Completer<TestableNotification>();
        service.onNotificationTapped.listen(completer.complete);

        service.simulateTap(
          title: 'Tap test',
          body: 'Body',
          data: {'route': '/test'},
        );

        final notification = await completer.future.timeout(
          const Duration(seconds: 1),
        );
        expect(notification.route, '/test');
      });
    });

    group('reset', () {
      test('clears all tracked notifications', () {
        service.simulateNotification(
          title: 'Received',
          body: 'Body',
          data: {},
        );
        service.simulateTap(
          title: 'Tapped',
          body: 'Body',
          data: {},
        );

        expect(service.receivedNotifications, hasLength(1));
        expect(service.tappedNotifications, hasLength(1));

        service.reset();

        expect(service.receivedNotifications, isEmpty);
        expect(service.tappedNotifications, isEmpty);
      });
    });

    group('TestableNotification', () {
      test('provides convenience getters for common fields', () {
        const notification = TestableNotification(
          title: 'Test',
          body: 'Body',
          data: {
            'type': 'friend_request_received',
            'route': '/friends',
            'tab': 'requests',
          },
        );

        expect(notification.type, 'friend_request_received');
        expect(notification.route, '/friends');
        expect(notification.tab, 'requests');
      });

      test('returns null for missing data fields', () {
        const notification = TestableNotification(
          title: 'Test',
          body: 'Body',
          data: {},
        );

        expect(notification.type, isNull);
        expect(notification.route, isNull);
        expect(notification.tab, isNull);
      });
    });
  });

  group('Friend Notification Data Contracts', () {
    // These tests document the expected notification payload structure
    // as defined in event-registry.js

    test('friend_request_received has correct structure', () {
      // This matches the payload from onFriendRequestReceived hook
      const notification = TestableNotification(
        title: 'New friend request',
        body: 'Alice wants to connect with you.',
        data: {
          'type': 'friend_request_received',
          'route': 'findmyfourth://golfers/requests',
          'sender_name': 'Alice',
          'sender_id': 'user_sender_123',
        },
      );

      expect(notification.type, 'friend_request_received');
      expect(notification.data['sender_name'], 'Alice');
      expect(notification.data['sender_id'], 'user_sender_123');
    });

    test('friend_request_accepted has correct structure', () {
      // This matches the payload from onFriendRequestAccepted hook
      const notification = TestableNotification(
        title: 'Friend request accepted',
        body: 'Bob is now connected with you.',
        data: {
          'type': 'friend_request_accepted',
          'route': 'findmyfourth://golfers/friends',
          'acceptor_name': 'Bob',
          'acceptor_id': 'user_acceptor_456',
        },
      );

      expect(notification.type, 'friend_request_accepted');
      expect(notification.data['acceptor_name'], 'Bob');
      expect(notification.data['acceptor_id'], 'user_acceptor_456');
    });
  });
}
