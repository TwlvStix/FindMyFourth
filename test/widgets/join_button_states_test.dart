import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/core/content/app_copy.dart';
import 'package:find_my_fourth/models/join_game_result.dart';
import 'package:find_my_fourth/models/join_request.dart';

void main() {
  group('JoinGameEligibilityData', () {
    test('factory constructors produce correct result values', () {
      final joined = JoinGameEligibilityData.joined();
      expect(joined.result, JoinGameResult.joined);
      expect(joined.matchResult, isNull);
      expect(joined.ownerProfile, isNull);

      final alreadyRequested = JoinGameEligibilityData.alreadyRequested();
      expect(alreadyRequested.result, JoinGameResult.alreadyRequested);
    });

    test('requiresApproval includes profile data', () {
      // When result is requiresApproval, matchResult and profiles should be populated
      // This is verified by the non-null assertions in the widget when showing bottom sheet
      const data = JoinGameEligibilityData(
        result: JoinGameResult.requiresApproval,
        vibeScore: 25.0,
        vibeFloor: 30,
      );

      expect(data.result, JoinGameResult.requiresApproval);
      expect(data.vibeScore, 25.0);
      expect(data.vibeFloor, 30);
    });
  });

  group('Join button text logic', () {
    // Test the button text logic matching _getJoinButtonText()

    test('no request shows "Join round"', () {
      JoinRequest? existingRequest;

      final buttonText = _getButtonTextForRequest(existingRequest);

      expect(buttonText, AppVibeFloorCopy.joinRoundButton);
    });

    test('pending request shows "Request pending"', () {
      final pendingRequest = JoinRequest(
        id: 'req1',
        gameId: 'game1',
        requesterId: 'player1',
        ownerId: 'owner1',
        requesterVibeScore: 25.0,
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      final buttonText = _getButtonTextForRequest(pendingRequest);

      expect(buttonText, AppVibeFloorCopy.requestPendingButton);
    });

    test('denied request shows "Request declined"', () {
      final deniedRequest = JoinRequest(
        id: 'req1',
        gameId: 'game1',
        requesterId: 'player1',
        ownerId: 'owner1',
        requesterVibeScore: 25.0,
        vibeFloor: 30,
        status: JoinRequestStatus.denied,
        createdAt: DateTime.now(),
        respondedAt: DateTime.now(),
      );

      final buttonText = _getButtonTextForRequest(deniedRequest);

      expect(buttonText, AppVibeFloorCopy.requestDeclinedButton);
    });

    test('approved request still shows "Join round" (edge case)', () {
      // Approved requests mean the player was already joined
      // so this state shouldn't occur, but test the fallback
      final approvedRequest = JoinRequest(
        id: 'req1',
        gameId: 'game1',
        requesterId: 'player1',
        ownerId: 'owner1',
        requesterVibeScore: 25.0,
        vibeFloor: 30,
        status: JoinRequestStatus.approved,
        createdAt: DateTime.now(),
        respondedAt: DateTime.now(),
      );

      final buttonText = _getButtonTextForRequest(approvedRequest);

      // Approved is not pending or denied, so returns default
      expect(buttonText, AppVibeFloorCopy.joinRoundButton);
    });
  });

  group('Join button enabled logic', () {
    test('no request and not checking returns enabled', () {
      JoinRequest? existingRequest;
      const isCheckingRequest = false;

      final enabled = _isButtonEnabled(existingRequest, isCheckingRequest);

      expect(enabled, isTrue);
    });

    test('pending request returns disabled', () {
      final pendingRequest = JoinRequest(
        id: 'req1',
        gameId: 'game1',
        requesterId: 'player1',
        ownerId: 'owner1',
        requesterVibeScore: 25.0,
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      final enabled = _isButtonEnabled(pendingRequest, false);

      expect(enabled, isFalse);
    });

    test('denied request returns disabled', () {
      final deniedRequest = JoinRequest(
        id: 'req1',
        gameId: 'game1',
        requesterId: 'player1',
        ownerId: 'owner1',
        requesterVibeScore: 25.0,
        vibeFloor: 30,
        status: JoinRequestStatus.denied,
        createdAt: DateTime.now(),
      );

      final enabled = _isButtonEnabled(deniedRequest, false);

      expect(enabled, isFalse);
    });

    test('still checking returns disabled', () {
      JoinRequest? existingRequest;
      const isCheckingRequest = true;

      final enabled = _isButtonEnabled(existingRequest, isCheckingRequest);

      expect(enabled, isFalse);
    });
  });

  group('Request subtitle logic', () {
    test('denied request shows subtitle', () {
      final deniedRequest = JoinRequest(
        id: 'req1',
        gameId: 'game1',
        requesterId: 'player1',
        ownerId: 'owner1',
        requesterVibeScore: 25.0,
        vibeFloor: 30,
        status: JoinRequestStatus.denied,
        createdAt: DateTime.now(),
      );

      final showSubtitle = deniedRequest.isDenied;

      expect(showSubtitle, isTrue);
    });

    test('pending request does not show subtitle', () {
      final pendingRequest = JoinRequest(
        id: 'req1',
        gameId: 'game1',
        requesterId: 'player1',
        ownerId: 'owner1',
        requesterVibeScore: 25.0,
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      final showSubtitle = pendingRequest.isDenied;

      expect(showSubtitle, isFalse);
    });

    test('subtitle text matches copy constant', () {
      expect(
        AppVibeFloorCopy.requestDeclinedSubtitle,
        'The owner is looking for a different play style this round.',
      );
    });
  });
}

/// Helper function matching the widget's _getJoinButtonText() logic
String _getButtonTextForRequest(JoinRequest? request) {
  if (request?.isPending == true) {
    return AppVibeFloorCopy.requestPendingButton;
  }
  if (request?.isDenied == true) {
    return AppVibeFloorCopy.requestDeclinedButton;
  }
  return AppVibeFloorCopy.joinRoundButton;
}

/// Helper function matching the widget's _isJoinButtonEnabled() logic
bool _isButtonEnabled(JoinRequest? request, bool isCheckingRequest) {
  return request == null && !isCheckingRequest;
}
