import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/push_notifications/push_notifications_util.dart';
import '/core/content/app_copy.dart';
import '/core/exceptions/app_exceptions.dart';
import '/core/utils/app_log.dart';
import '/models/game.dart';
import '/models/join_request.dart';
import '/models/vibe_profile.dart';
import '/providers/game_provider.dart';
import '/providers/join_request_provider.dart';
import '/services/vibe_repository.dart';
import '/utils/app_util.dart';

const int cancelledChatDeleteDays = 3;

class PendingRequestsLoadResult {
  const PendingRequestsLoadResult({
    required this.requests,
    required this.ownerVibeProfile,
    this.errorMessage,
  });

  final List<JoinRequest> requests;
  final VibeProfile? ownerVibeProfile;
  final String? errorMessage;
}

class GameJoinedActionResult {
  const GameJoinedActionResult({
    required this.success,
    this.message,
  });

  final bool success;
  final String? message;

  static const ok = GameJoinedActionResult(success: true);

  factory GameJoinedActionResult.fail(String message) =>
      GameJoinedActionResult(success: false, message: message);
}

class GameJoinedDetailedController {
  GameJoinedDetailedController({
    required JoinRequestProvider joinRequestProvider,
    required GameProvider gameProvider,
    required AppState appState,
    VibeRepository? vibeRepository,
  })  : _joinRequestProvider = joinRequestProvider,
        _gameProvider = gameProvider,
        _appState = appState,
        _vibeRepository = vibeRepository ?? VibeRepository();

  final JoinRequestProvider _joinRequestProvider;
  final GameProvider _gameProvider;
  final AppState _appState;
  final VibeRepository _vibeRepository;

  Future<PendingRequestsLoadResult> loadPendingRequests({
    required String gameId,
    required String ownerId,
  }) async {
    try {
      final results = await Future.wait([
        _joinRequestProvider.getPendingRequestsForGame(gameId, ownerId),
        _vibeRepository.getVibeProfileForUser(ownerId),
      ]);

      final requests = results[0] as List<JoinRequest>;
      requests.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return PendingRequestsLoadResult(
        requests: requests,
        ownerVibeProfile: results[1] as VibeProfile,
      );
    } catch (error) {
      AppLog.d('❌ Error loading pending join requests: $error');
      return const PendingRequestsLoadResult(
        requests: <JoinRequest>[],
        ownerVibeProfile: null,
        errorMessage: 'Unable to load pending requests.',
      );
    }
  }

  Future<GameJoinedActionResult> approveRequest({
    required JoinRequest request,
  }) async {
    try {
      await _joinRequestProvider.approveJoinRequest(
        gameId: request.gameId,
        requestId: request.id,
        requesterId: request.requesterId,
      );
      _gameProvider.invalidateAvailableGamesCache();
      return GameJoinedActionResult.ok;
    } on GameOperationException catch (error) {
      if (error.code == 'game-full') {
        _joinRequestProvider.notifyRoundFilledBeforeApproval(
          request.gameId,
          request.requesterId,
        );
        return GameJoinedActionResult.fail(AppVibeFloorCopy.roundFullError);
      }
      return GameJoinedActionResult.fail(
        'Failed to approve request. Please try again.',
      );
    } catch (_) {
      return GameJoinedActionResult.fail(
        'Failed to approve request. Please try again.',
      );
    }
  }

  Future<GameJoinedActionResult> declineRequest(JoinRequest request) async {
    try {
      await _joinRequestProvider.declineJoinRequest(
        gameId: request.gameId,
        requestId: request.id,
        requesterId: request.requesterId,
      );
      return GameJoinedActionResult.ok;
    } catch (_) {
      return GameJoinedActionResult.fail(
        'Failed to decline request. Please try again.',
      );
    }
  }

  Future<GameJoinedActionResult> confirmFlexibleSchedule({
    required String gameId,
    required DateTime date,
    required String course,
    required DocumentReference? courseRef,
  }) async {
    try {
      await _gameProvider.updateGame(gameId, <String, dynamic>{
        'schedule_type': 'confirmed',
        'date': date,
        'course_play': course,
        'courseRef': courseRef,
        'flexible_week': null,
        'flexible_days': null,
        'flexible_time_of_day': null,
      });
      return GameJoinedActionResult.ok;
    } catch (error) {
      return GameJoinedActionResult.fail('Failed to confirm tee time: $error');
    }
  }

  Future<GameJoinedActionResult> leaveGame({
    required String gameId,
    required String userId,
  }) async {
    try {
      await _gameProvider.leaveGame(gameId, userId);
      return GameJoinedActionResult.ok;
    } on FirebaseException catch (error) {
      return GameJoinedActionResult.fail(
        error.code == 'permission-denied'
            ? 'You do not have permission to leave this game.'
            : 'Unable to leave the game right now. Please try again.',
      );
    } catch (_) {
      return GameJoinedActionResult.fail(
        'Unable to leave the game right now. Please try again.',
      );
    }
  }

  Future<GameJoinedActionResult> cancelGame({
    required Game gameRecord,
    required String? currentUserId,
    required bool removeNow,
    required String userIdForCache,
  }) async {
    if (removeNow) {
      _appState.setCancelledGameHandling(
        gameRecord.reference.path,
        'removeNow',
      );
    }

    try {
      await _gameProvider.cancelGame(gameRecord.reference.id);
      _gameProvider.invalidateUserGamesCache(userIdForCache);

      final chatRef = gameRecord.chatRef;
      if (chatRef != null) {
        final gameName = gameRecord.nameGame;
        final cancelMessage = gameName.trim().isNotEmpty
            ? 'Game "$gameName" has been cancelled.'
            : 'This game has been cancelled.';
        try {
          // Update chat metadata: lock immediately, schedule deletion
          // Banner shows status; no system messages (cleaner UX)
          await chatRef.update({
            'isReadOnly': true,
            'pinnedMessage': cancelMessage,
            'pinnedAt': FieldValue.serverTimestamp(),
            'deletesAt': Timestamp.fromDate(
              getCurrentTimestamp.add(
                Duration(days: cancelledChatDeleteDays),
              ),
            ),
          });
        } catch (chatError, stackTrace) {
          AppLog.d('CancelGame: chat update failed $chatError');
          AppLog.d('CancelGame chat stackTrace: $stackTrace');
        }
      }

      return GameJoinedActionResult.ok;
    } catch (error, stackTrace) {
      AppLog.d('CancelGame: failed $error');
      AppLog.d('CancelGame stackTrace: $stackTrace');
      return GameJoinedActionResult.fail(
        'Unable to cancel the game. Please try again.',
      );
    }
  }

  Future<GameJoinedActionResult> removePlayer({
    required String gameId,
    required bool isGuest,
    required DocumentReference? playerRef,
    required String? guestName,
  }) async {
    try {
      await _gameProvider.removePlayer(
        gameId,
        playerId: playerRef?.id,
        guestName: guestName,
        isGuest: isGuest,
      );
      return GameJoinedActionResult.ok;
    } catch (_) {
      return GameJoinedActionResult.fail(
        'Failed to remove player. Please try again.',
      );
    }
  }

  Future<GameJoinedActionResult> updateGameDetails({
    required Game gameRecord,
    required DateTime date,
    required String course,
    required DocumentReference? courseRef,
    required String? currentUserUid,
  }) async {
    try {
      await _gameProvider.updateGame(gameRecord.reference.id, <String, dynamic>{
        'date': date,
        'course_play': course,
        'courseRef': courseRef,
      });

      final recipients = gameRecord.joinedPlayers
          .where((ref) => ref.id != currentUserUid)
          .toList();

      if (recipients.isNotEmpty) {
        final dayName = dateTimeFormat('EEEE', date);
        final dateStr = dateTimeFormat('MMM d', date);
        final timeStr = dateTimeFormat('jm', date);
        final notificationText =
            'Game updated — now $dayName $dateStr, $timeStr at $course';
        triggerPushNotification(
          notificationTitle: 'Game Details Updated',
          notificationText: notificationText,
          userRefs: recipients,
          initialPageName: 'GameJoinedDetailed',
          parameterData: {'gameRef': gameRecord.reference.path},
        );
      }

      return GameJoinedActionResult.ok;
    } catch (error) {
      return GameJoinedActionResult.fail(
        'Failed to update game details: $error',
      );
    }
  }

  Future<GameJoinedActionResult> validateGroupChatAccess({
    required Game gameRecord,
    required String? currentUserId,
  }) async {
    if (gameRecord.chatRef == null) {
      return const GameJoinedActionResult(
        success: false,
        message: 'Group chat is unavailable for this game.',
      );
    }
    if (currentUserId == null) {
      return const GameJoinedActionResult(
        success: false,
        message: 'Please sign in to open the chat.',
      );
    }
    final isMember =
        gameRecord.joinedPlayers.any((player) => player.id == currentUserId);
    if (!isMember) {
      return const GameJoinedActionResult(
        success: false,
        message: 'Join the game to access the group chat.',
      );
    }
    return GameJoinedActionResult.ok;
  }
}
