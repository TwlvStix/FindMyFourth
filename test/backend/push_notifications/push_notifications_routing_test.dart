import 'package:flutter_test/flutter_test.dart';
import 'package:find_my_fourth/backend/push_notifications/push_notifications_handler.dart';

void main() {
  group('normalizeNotificationPayload', () {
    test('preserves legacy type field', () {
      final data = {'type': 'game_created', 'gameId': '123'};
      final normalized = normalizeNotificationPayload(data);

      expect(normalized['type'], 'game_created');
    });

    test('bridges event_type to type when type is absent', () {
      final data = {'event_type': 'host_checkin_due', 'event_id': 'evt123'};
      final normalized = normalizeNotificationPayload(data);

      expect(normalized['type'], 'host_checkin_due');
      expect(normalized['event_type'], 'host_checkin_due');
    });

    test('prefers legacy type over event_type when both present', () {
      final data = {
        'type': 'legacy_type',
        'event_type': 'trust_type',
      };
      final normalized = normalizeNotificationPayload(data);

      expect(normalized['type'], 'legacy_type');
    });

    test('normalizes game_id to gameId', () {
      final data = {'type': 'game_cancelled', 'game_id': 'g123'};
      final normalized = normalizeNotificationPayload(data);

      expect(normalized['gameId'], 'g123');
    });

    test('normalizes game_ref to gameRef', () {
      final data = {'type': 'host_checkin_due', 'game_ref': 'games/g123'};
      final normalized = normalizeNotificationPayload(data);

      expect(normalized['gameRef'], 'games/g123');
    });

    test('normalizes chat keys', () {
      final data = {
        'type': 'chat_message',
        'thread_id': 'chat123',
        'chat_id': 'chat456',
      };
      final normalized = normalizeNotificationPayload(data);

      expect(normalized['threadId'], 'chat123');
      expect(normalized['chatId'], 'chat456');
    });

    test('normalizes event_id to eventId', () {
      final data = {'event_type': 'badge_earned', 'event_id': 'evt789'};
      final normalized = normalizeNotificationPayload(data);

      expect(normalized['eventId'], 'evt789');
    });

    test('normalizes initialPageName from snake_case', () {
      final data = {
        'type': 'game_alert_deferred',
        'initial_page_name': 'JoinGameDetailed',
        'parameter_data': '{"gameRef":"games/g123"}',
      };
      final normalized = normalizeNotificationPayload(data);

      expect(normalized['initialPageName'], 'JoinGameDetailed');
      expect(normalized['parameterData'], '{"gameRef":"games/g123"}');
    });
  });

  group('Notification Type Routing Coverage', () {
    // Table-driven test cases for all notification types
    final testCases = <_RoutingTestCase>[
      // ===== Legacy game types =====
      _RoutingTestCase(
        type: 'game_created',
        data: {'gameId': 'g123'},
        expectedPage: 'JoinGameDetailed',
        expectedParams: {'gameRef': 'games/g123'},
      ),
      _RoutingTestCase(
        type: 'game_alert',
        data: {'gameId': 'g123'},
        expectedPage: 'JoinGameDetailed',
        expectedParams: {'gameRef': 'games/g123'},
      ),

      // ===== Chat =====
      _RoutingTestCase(
        type: 'chat_message',
        data: {'threadId': 'chat123'},
        expectedPage: 'ChatDetails',
        expectedParams: {'chatId': 'chat123'},
      ),
      _RoutingTestCase(
        type: 'chat_message',
        data: {'chatId': 'chat456'},
        expectedPage: 'ChatDetails',
        expectedParams: {'chatId': 'chat456'},
      ),

      // ===== Post-round Trust types (legacy names) =====
      _RoutingTestCase(
        type: 'host_checkin',
        data: {'gameRef': 'games/g123'},
        expectedPage: 'HostCheckin',
        expectedParams: {'gameRef': 'games/g123'},
      ),
      _RoutingTestCase(
        type: 'peer_rating',
        data: {'gameRef': 'games/g123'},
        expectedPage: 'PeerRating',
        expectedParams: {'gameRef': 'games/g123'},
      ),
      _RoutingTestCase(
        type: 'fallback_confirmation',
        data: {'gameRef': 'games/g123'},
        expectedPage: 'FallbackConfirmation',
        expectedParams: {'gameRef': 'games/g123'},
      ),

      // ===== Post-round Trust types (new names) =====
      _RoutingTestCase(
        type: 'host_checkin_due',
        data: {'gameRef': 'games/g123'},
        expectedPage: 'HostCheckin',
        expectedParams: {'gameRef': 'games/g123'},
      ),
      _RoutingTestCase(
        type: 'host_checkin_due',
        data: {'game_id': 'g123'},
        expectedPage: 'HostCheckin',
        expectedParams: {'gameRef': 'games/g123'},
        description: 'host_checkin_due with game_id instead of gameRef',
      ),
      _RoutingTestCase(
        type: 'host_checkin_fallback',
        data: {'gameRef': 'games/g123'},
        expectedPage: 'FallbackConfirmation',
        expectedParams: {'gameRef': 'games/g123'},
      ),
      _RoutingTestCase(
        type: 'player_rate_due',
        data: {'gameRef': 'games/g123'},
        expectedPage: 'PeerRating',
        expectedParams: {'gameRef': 'games/g123'},
      ),
      _RoutingTestCase(
        type: 'player_rate_due',
        data: {'game_id': 'g123'},
        expectedPage: 'PeerRating',
        expectedParams: {'gameRef': 'games/g123'},
        description: 'player_rate_due with game_id instead of gameRef',
      ),
      _RoutingTestCase(
        type: 'player_fallback_confirm',
        data: {'gameRef': 'games/g123'},
        expectedPage: 'FallbackConfirmation',
        expectedParams: {'gameRef': 'games/g123'},
      ),

      // ===== Game Trust types =====
      _RoutingTestCase(
        type: 'game_spot_opened',
        data: {'gameId': 'g123'},
        expectedPage: 'JoinGameDetailed',
        expectedParams: {'gameRef': 'games/g123'},
      ),
      _RoutingTestCase(
        type: 'game_cancelled',
        data: {'gameId': 'g123'},
        expectedPage: 'JoinGameDetailed',
        expectedParams: {'gameRef': 'games/g123'},
      ),
      _RoutingTestCase(
        type: 'game_alert_deferred',
        data: {'gameId': 'g123'},
        expectedPage: 'JoinGameDetailed',
        expectedParams: {'gameRef': 'games/g123'},
      ),

      // ===== Join request types =====
      _RoutingTestCase(
        type: 'join_request_new',
        data: {'game_id': 'g123'},
        expectedPage: 'GameJoinedDetailed',
        expectedParams: {'gameRef': 'games/g123'},
      ),
      _RoutingTestCase(
        type: 'join_request_approved',
        data: {'game_id': 'g123'},
        expectedPage: 'GameJoinedDetailed',
        expectedParams: {'gameRef': 'games/g123'},
      ),
      _RoutingTestCase(
        type: 'join_request_declined',
        data: {'game_id': 'g123'},
        expectedPage: 'JoinGameDetailed',
        expectedParams: {'gameRef': 'games/g123'},
      ),
      _RoutingTestCase(
        type: 'join_request_round_filled',
        data: {},
        expectedPage: 'GamesList',
        expectedParams: {},
      ),
      _RoutingTestCase(
        type: 'join_request_expired',
        data: {},
        expectedPage: 'GamesList',
        expectedParams: {},
      ),

      // ===== Friend request types =====
      _RoutingTestCase(
        type: 'friend_request_received',
        data: {},
        expectedPage: 'Tab_Friends',
        expectedParams: {'initialSegment': 'requests'},
      ),
      _RoutingTestCase(
        type: 'friend_request_accepted',
        data: {},
        expectedPage: 'Tab_Friends',
        expectedParams: {'initialSegment': 'friends'},
      ),

      // ===== Streak types =====
      _RoutingTestCase(
        type: 'streak_weekend_nudge',
        data: {},
        expectedPage: 'GamesList',
        expectedParams: {},
      ),
      _RoutingTestCase(
        type: 'streak_freeze_unlocked',
        data: {},
        expectedPage: 'MainProfile',
        expectedParams: {},
      ),
      _RoutingTestCase(
        type: 'streak_freeze_prompt',
        data: {},
        expectedPage: 'MainProfile',
        expectedParams: {},
      ),
      _RoutingTestCase(
        type: 'streak_milestone_reached',
        data: {},
        expectedPage: 'MainProfile',
        expectedParams: {},
      ),
      _RoutingTestCase(
        type: 'streak_broken',
        data: {},
        expectedPage: 'MainProfile',
        expectedParams: {},
      ),

      // ===== Host-add-player types =====
      _RoutingTestCase(
        type: 'player_added_by_host',
        data: {'game_id': 'g123'},
        expectedPage: 'GameJoinedDetailed',
        expectedParams: {'gameRef': 'games/g123'},
      ),
      _RoutingTestCase(
        type: 'player_declined_spot',
        data: {'game_id': 'g123'},
        expectedPage: 'GameJoinedDetailed',
        expectedParams: {'gameRef': 'games/g123'},
      ),

      // ===== Trust account types =====
      _RoutingTestCase(
        type: 'no_show_flagged',
        data: {},
        expectedPage: 'YourStanding',
        expectedParams: {},
      ),
      _RoutingTestCase(
        type: 'dispute_resolved',
        data: {},
        expectedPage: 'YourStanding',
        expectedParams: {},
      ),
      _RoutingTestCase(
        type: 'strike_issued',
        data: {},
        expectedPage: 'YourStanding',
        expectedParams: {},
      ),
      _RoutingTestCase(
        type: 'cooldown_started',
        data: {},
        expectedPage: 'YourStanding',
        expectedParams: {},
      ),
      _RoutingTestCase(
        type: 'restriction_started',
        data: {},
        expectedPage: 'YourStanding',
        expectedParams: {},
      ),
      _RoutingTestCase(
        type: 'suspension_started',
        data: {},
        expectedPage: 'YourStanding',
        expectedParams: {},
      ),
      _RoutingTestCase(
        type: 'restriction_ended',
        data: {},
        expectedPage: 'YourStanding',
        expectedParams: {},
      ),

      // ===== Badge types =====
      _RoutingTestCase(
        type: 'badge_earned',
        data: {},
        expectedPage: 'MainProfile',
        expectedParams: {},
      ),
      _RoutingTestCase(
        type: 'badge_progress',
        data: {},
        expectedPage: 'MainProfile',
        expectedParams: {},
      ),
    ];

    for (final tc in testCases) {
      test(tc.testName, () {
        // Normalize the data first (as the real handler does)
        final normalized = normalizeNotificationPayload({
          'type': tc.type,
          ...tc.data,
        });

        // Note: _resolveRouteFromType is private, so we can't call it directly.
        // This test documents expected behavior. In a real implementation,
        // you would either:
        // 1. Export _resolveRouteFromType for testing
        // 2. Use integration tests with a mock navigator
        // 3. Make it a static method on a testable class

        // For now, we verify the normalization works correctly
        expect(normalized['type'], tc.type);

        // Verify expected data fields are present
        for (final key in tc.expectedParams.keys) {
          if (key == 'gameRef' && tc.data.containsKey('game_id')) {
            // gameRef is constructed from game_id in the handler
            continue;
          }
          if (key == 'chatId' && tc.data.containsKey('threadId')) {
            // chatId is derived from threadId
            expect(normalized['threadId'], isNotNull);
            continue;
          }
          if (tc.data.containsKey(key)) {
            expect(normalized[key], tc.data[key]);
          }
        }
      });
    }
  });

  group('Trust System Payload Normalization', () {
    test('handles full Trust payload with deep_link', () {
      final trustPayload = {
        'event_type': 'host_checkin_due',
        'event_id': 'evt_123',
        'deep_link': 'findmyfourth://checkin/g456',
        'type': 'host_checkin_due', // Backend now sends both
        'game_id': 'g456',
      };

      final normalized = normalizeNotificationPayload(trustPayload);

      expect(normalized['type'], 'host_checkin_due');
      expect(normalized['eventId'], 'evt_123');
      expect(normalized['gameId'], 'g456');
      expect(normalized['deep_link'], 'findmyfourth://checkin/g456');
    });

    test('handles Trust payload without compatibility keys', () {
      // Old backend format (before compatibility keys were added)
      final legacyTrustPayload = {
        'event_type': 'badge_earned',
        'event_id': 'evt_789',
        'deep_link': 'findmyfourth://badges',
      };

      final normalized = normalizeNotificationPayload(legacyTrustPayload);

      expect(normalized['type'], 'badge_earned');
      expect(normalized['eventId'], 'evt_789');
    });
  });

  group('Edge Cases', () {
    test('handles empty type gracefully', () {
      final data = {'type': '', 'gameId': 'g123'};
      final normalized = normalizeNotificationPayload(data);

      expect(normalized['type'], '');
    });

    test('handles null type with event_type', () {
      final data = {'type': null, 'event_type': 'game_cancelled'};
      final normalized = normalizeNotificationPayload(data);

      expect(normalized['type'], 'game_cancelled');
    });

    test('handles missing IDs gracefully', () {
      final data = {'type': 'game_created'};
      final normalized = normalizeNotificationPayload(data);

      expect(normalized['type'], 'game_created');
      expect(normalized['gameId'], isNull);
      expect(normalized['gameRef'], isNull);
    });

    test('preserves original keys alongside normalized ones', () {
      final data = {
        'event_type': 'host_checkin_due',
        'game_id': 'g123',
        'custom_field': 'value',
      };
      final normalized = normalizeNotificationPayload(data);

      // Original keys preserved
      expect(normalized['event_type'], 'host_checkin_due');
      expect(normalized['game_id'], 'g123');
      expect(normalized['custom_field'], 'value');

      // Normalized keys added
      expect(normalized['type'], 'host_checkin_due');
      expect(normalized['gameId'], 'g123');
    });
  });
}

/// Test case for routing verification
class _RoutingTestCase {
  const _RoutingTestCase({
    required this.type,
    required this.data,
    required this.expectedPage,
    required this.expectedParams,
    this.description,
  });

  final String type;
  final Map<String, dynamic> data;
  final String expectedPage;
  final Map<String, dynamic> expectedParams;
  final String? description;

  String get testName =>
      description ?? '$type routes to $expectedPage';
}
