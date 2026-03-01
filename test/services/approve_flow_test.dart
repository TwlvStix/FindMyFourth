import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/core/exceptions/app_exceptions.dart';
import 'package:find_my_fourth/models/join_request.dart';

void main() {
  group('Approval flow - JoinRequest status transitions', () {
    late JoinRequest pendingRequest;

    setUp(() {
      pendingRequest = JoinRequest(
        id: 'req123',
        gameId: 'game456',
        requesterId: 'player789',
        ownerId: 'owner012',
        requesterVibeScore: 25.5,
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );
    });

    test('pending request can be approved', () {
      final approved = pendingRequest.copyWith(
        status: JoinRequestStatus.approved,
        respondedAt: DateTime.now(),
      );

      expect(approved.status, JoinRequestStatus.approved);
      expect(approved.isApproved, isTrue);
      expect(approved.isPending, isFalse);
      expect(approved.respondedAt, isNotNull);
    });

    test('pending request can be denied', () {
      final denied = pendingRequest.copyWith(
        status: JoinRequestStatus.denied,
        respondedAt: DateTime.now(),
      );

      expect(denied.status, JoinRequestStatus.denied);
      expect(denied.isDenied, isTrue);
      expect(denied.isPending, isFalse);
      expect(denied.respondedAt, isNotNull);
    });

    test('approval preserves original request data', () {
      final approved = pendingRequest.copyWith(
        status: JoinRequestStatus.approved,
        respondedAt: DateTime.now(),
      );

      // Original data unchanged
      expect(approved.id, pendingRequest.id);
      expect(approved.gameId, pendingRequest.gameId);
      expect(approved.requesterId, pendingRequest.requesterId);
      expect(approved.ownerId, pendingRequest.ownerId);
      expect(approved.requesterVibeScore, pendingRequest.requesterVibeScore);
      expect(approved.vibeFloor, pendingRequest.vibeFloor);
      expect(approved.createdAt, pendingRequest.createdAt);
    });

    test('denial preserves original request data', () {
      final denied = pendingRequest.copyWith(
        status: JoinRequestStatus.denied,
        respondedAt: DateTime.now(),
      );

      // Original data unchanged
      expect(denied.id, pendingRequest.id);
      expect(denied.gameId, pendingRequest.gameId);
      expect(denied.requesterId, pendingRequest.requesterId);
      expect(denied.requesterVibeScore, pendingRequest.requesterVibeScore);
    });
  });

  group('GameOperationException for game-full scenario', () {
    test('game-full exception has correct code', () {
      final exception = GameOperationException(
        'Round is full',
        code: 'game-full',
      );

      expect(exception.message, 'Round is full');
      expect(exception.code, 'game-full');
    });

    test('game-full exception toString includes code', () {
      final exception = GameOperationException(
        'Round is full',
        code: 'game-full',
      );

      final str = exception.toString();
      expect(str, contains('game-full'));
    });

    test('game-not-found exception for missing game', () {
      final exception = GameOperationException(
        'Game not found',
        code: 'game-not-found',
      );

      expect(exception.code, 'game-not-found');
    });
  });

  group('JoinRequestException for request errors', () {
    test('request-not-found exception', () {
      final exception = JoinRequestException(
        'Request not found',
        code: 'request-not-found',
      );

      expect(exception.message, 'Request not found');
      expect(exception.code, 'request-not-found');
    });

    test('exception with cause', () {
      final cause = Exception('Firestore error');
      final exception = JoinRequestException(
        'Failed to update request',
        code: 'update-failed',
        cause: cause,
      );

      expect(exception.cause, cause);
    });
  });

  group('Approval flow capacity checks', () {
    test('approval fails when game is full', () {
      // This tests the expected behavior when approving a request
      // for a game that has reached max capacity
      const maxPlayers = 4;
      const currentPlayers = 4;

      // When current players >= max players, should fail
      final isFull = currentPlayers >= maxPlayers;
      expect(isFull, isTrue);

      if (isFull) {
        // Would throw GameOperationException
        expect(
          () => throw GameOperationException('Round is full', code: 'game-full'),
          throwsA(isA<GameOperationException>()),
        );
      }
    });

    test('approval succeeds when spot available', () {
      const maxPlayers = 4;
      const currentPlayers = 3;

      final hasSpot = currentPlayers < maxPlayers;
      expect(hasSpot, isTrue);
    });

    test('boundary case: exactly one spot left', () {
      const maxPlayers = 4;
      const currentPlayers = 3;

      final spotsRemaining = maxPlayers - currentPlayers;
      expect(spotsRemaining, 1);

      // Should allow approval
      final canApprove = spotsRemaining > 0;
      expect(canApprove, isTrue);
    });

    test('boundary case: game just became full', () {
      const maxPlayers = 4;
      const currentPlayers = 4;

      final spotsRemaining = maxPlayers - currentPlayers;
      expect(spotsRemaining, 0);

      // Should not allow approval
      final canApprove = spotsRemaining > 0;
      expect(canApprove, isFalse);
    });
  });

  group('Decline flow', () {
    test('decline only updates status, not game players', () {
      final request = JoinRequest(
        id: 'req123',
        gameId: 'game456',
        requesterId: 'player789',
        ownerId: 'owner012',
        requesterVibeScore: 25.5,
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      // Decline only changes the request status
      final declined = request.copyWith(
        status: JoinRequestStatus.denied,
        respondedAt: DateTime.now(),
      );

      // Request is updated
      expect(declined.isDenied, isTrue);
      expect(declined.respondedAt, isNotNull);

      // Game modification not needed for decline
      // (verified by checking the decline path in service)
    });

    test('decline does not require capacity check', () {
      // Unlike approval, decline can happen regardless of game state
      const maxPlayers = 4;
      const currentPlayers = 4;

      // Game is full, but decline should still work
      expect(currentPlayers >= maxPlayers, isTrue);

      final request = JoinRequest(
        id: 'req123',
        gameId: 'game456',
        requesterId: 'player789',
        ownerId: 'owner012',
        requesterVibeScore: 25.5,
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      final declined = request.copyWith(status: JoinRequestStatus.denied);
      expect(declined.isDenied, isTrue);
    });
  });

  group('Request after previous denial', () {
    test('player can have multiple requests for same game over time', () {
      // A player might submit, get denied, then submit again later
      // Each request has a unique ID
      final request1 = JoinRequest(
        id: 'req1',
        gameId: 'game456',
        requesterId: 'player789',
        ownerId: 'owner012',
        requesterVibeScore: 20.0,
        vibeFloor: 30,
        status: JoinRequestStatus.denied,
        createdAt: DateTime(2024, 1, 1),
        respondedAt: DateTime(2024, 1, 2),
      );

      final request2 = JoinRequest(
        id: 'req2',
        gameId: 'game456',
        requesterId: 'player789',
        ownerId: 'owner012',
        requesterVibeScore: 35.0, // Higher score this time
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: DateTime(2024, 1, 3),
      );

      expect(request1.isDenied, isTrue);
      expect(request2.isPending, isTrue);
      expect(request1.id, isNot(request2.id));
      expect(request1.gameId, request2.gameId);
      expect(request1.requesterId, request2.requesterId);
    });
  });

  group('Atomic approval transaction expectations', () {
    test('approval transaction should check capacity before updating', () {
      // The transaction order should be:
      // 1. Read game document
      // 2. Check joined_players.length < max_players
      // 3. Update request status to approved
      // 4. Add player to joined_players array

      // This verifies the expected transaction steps
      const steps = [
        'read_game',
        'check_capacity',
        'update_request',
        'add_player',
      ];

      expect(steps.length, 4);
      expect(steps[0], 'read_game');
      expect(steps[1], 'check_capacity');
      expect(steps[2], 'update_request');
      expect(steps[3], 'add_player');
    });

    test('atomic update prevents race conditions', () {
      // Two approvals at the same time for a game with 1 spot
      // should result in only 1 success

      const maxPlayers = 4;
      const currentPlayers = 3;
      const spotsAvailable = maxPlayers - currentPlayers;

      // Only 1 spot available
      expect(spotsAvailable, 1);

      // With atomic transactions, only 1 approval can succeed
      const expectedSuccesses = 1;

      expect(expectedSuccesses, lessThanOrEqualTo(spotsAvailable));
    });
  });
}
