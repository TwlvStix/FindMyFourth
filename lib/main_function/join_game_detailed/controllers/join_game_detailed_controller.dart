import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/exceptions/app_exceptions.dart';
import '/core/utils/app_log.dart';
import '/models/game.dart';
import '/models/join_game_result.dart';
import '/models/join_request.dart';
import '/providers/chat_provider.dart';
import '/providers/game_provider.dart';
import '/providers/join_request_provider.dart';
import '/providers/profile_provider.dart';
import '/providers/user_provider.dart';

enum JoinGameAttemptStatus {
  success,
  requiresApproval,
  alreadyRequested,
  blocked,
  unauthenticated,
  error,
  genderRestricted,
}

class JoinGameApprovalPayload {
  const JoinGameApprovalPayload({
    required this.ownerFirstName,
    required this.eligibilityData,
    required this.playerName,
    required this.currentUserId,
    required this.ownerId,
  });

  final String ownerFirstName;
  final JoinGameEligibilityData eligibilityData;
  final String playerName;
  final String currentUserId;
  final String ownerId;
}

class JoinGameAttemptResult {
  const JoinGameAttemptResult({
    required this.status,
    this.message,
    this.approvalPayload,
  });

  final JoinGameAttemptStatus status;
  final String? message;
  final JoinGameApprovalPayload? approvalPayload;
}

class JoinGameDetailedController {
  JoinGameDetailedController();

  Future<JoinRequest?> loadExistingRequest({
    required JoinRequestProvider joinRequestProvider,
    required String gameId,
    required String userId,
  }) {
    return joinRequestProvider.getExistingRequestForGame(gameId, userId);
  }

  Future<JoinGameAttemptResult> attemptJoin({
    required Game game,
    required DocumentReference? currentUserRef,
    required bool isCreatorFriend,
    required String? userGender,
    required GameProvider gameProvider,
    required ChatProvider chatProvider,
    required UserProvider userProvider,
    required ProfileProvider profileProvider,
  }) async {
    if (currentUserRef == null) {
      return const JoinGameAttemptResult(
        status: JoinGameAttemptStatus.unauthenticated,
        message: 'Please sign in to join this game.',
      );
    }

    final accessResult = await _checkJoinAccess(
      game: game,
      currentUserRef: currentUserRef,
      isCreatorFriend: isCreatorFriend,
      profileProvider: profileProvider,
    );
    if (!accessResult.allowed) {
      return JoinGameAttemptResult(
        status: JoinGameAttemptStatus.blocked,
        message: accessResult.message,
      );
    }

    try {
      final result = await gameProvider.joinGame(
        game.reference.id,
        currentUserRef.id,
        userGender: userGender,
        ownerId: game.userRef?.id,
      );

      if (result.result == JoinGameResult.alreadyRequested) {
        return const JoinGameAttemptResult(
          status: JoinGameAttemptStatus.alreadyRequested,
          message: 'You already have a pending request for this game.',
        );
      }

      if (result.result == JoinGameResult.requiresApproval) {
        final ownerFirstName = await _loadOwnerFirstName(game.userRef, profileProvider);
        final playerName = userProvider.currentUser?.displayName ?? 'A player';
        final ownerId = game.userRef?.id;
        if (ownerId == null) {
          return const JoinGameAttemptResult(
            status: JoinGameAttemptStatus.error,
            message: 'Unable to submit request right now. Please try again.',
          );
        }
        return JoinGameAttemptResult(
          status: JoinGameAttemptStatus.requiresApproval,
          approvalPayload: JoinGameApprovalPayload(
            ownerFirstName: ownerFirstName,
            eligibilityData: result,
            playerName: playerName,
            currentUserId: currentUserRef.id,
            ownerId: ownerId,
          ),
        );
      }
    } on GameOperationException catch (error) {
      switch (error.code) {
        case 'game-full':
          return const JoinGameAttemptResult(
            status: JoinGameAttemptStatus.error,
            message: 'This game is now full',
          );
        case 'already-joined':
          return const JoinGameAttemptResult(
            status: JoinGameAttemptStatus.error,
            message: "You've already joined this game",
          );
        case 'transaction-conflict':
          return const JoinGameAttemptResult(
            status: JoinGameAttemptStatus.error,
            message: 'Game updated by another user, please refresh',
          );
        case 'game-not-found':
          return const JoinGameAttemptResult(
            status: JoinGameAttemptStatus.error,
            message: 'Game not found',
          );
        case 'game-cancelled':
          return const JoinGameAttemptResult(
            status: JoinGameAttemptStatus.error,
            message: 'This game has been cancelled',
          );
        case 'gender-restricted':
          return const JoinGameAttemptResult(
            status: JoinGameAttemptStatus.genderRestricted,
          );
        default:
          return JoinGameAttemptResult(
            status: JoinGameAttemptStatus.error,
            message: error.message,
          );
      }
    } on FirebaseException catch (error) {
      final friendGameLower = game.friendGame.trim().toLowerCase();
      final isFriendsOnly = friendGameLower == 'friends';
      final message = error.code == 'permission-denied'
          ? (isFriendsOnly
              ? 'You must be friends with the game creator to join this game.'
              : 'You do not have permission to join this game.')
          : 'Unable to join the game right now. Please try again.';
      return JoinGameAttemptResult(
        status: JoinGameAttemptStatus.error,
        message: message,
      );
    } catch (error) {
      AppLog.d('JoinGameDetailedController.attemptJoin failed: $error');
      return const JoinGameAttemptResult(
        status: JoinGameAttemptStatus.error,
        message: 'Unable to join the game right now. Please try again.',
      );
    }

    gameProvider.invalidateAvailableGamesCache();
    final userId = userProvider.userIdOrNull;
    if (userId != null && userId.isNotEmpty) {
      gameProvider.invalidateUserGamesCache(userId);
    } else {
      AppLog.d('⚠️ JoinGameDetailedController: skipping user games cache invalidation (no userId)');
    }
    if (game.chatRef != null) {
      final chatId = game.chatRef!.id;
      chatProvider.invalidateChatCache(chatId);
      chatProvider.invalidateMessagesCache(chatId);
    }

    return const JoinGameAttemptResult(status: JoinGameAttemptStatus.success);
  }

  Future<_JoinAccessResult> _checkJoinAccess({
    required Game game,
    required DocumentReference currentUserRef,
    required bool isCreatorFriend,
    required ProfileProvider profileProvider,
  }) async {
    final friendGameLower = game.friendGame.trim().toLowerCase();
    final isFriendsOnly = friendGameLower == 'friends';
    final isPublic = friendGameLower == 'public';
    var isOwnerFriendsWithUser = isCreatorFriend;

    if (!isFriendsOnly) {
      return const _JoinAccessResult(allowed: true);
    }

    try {
      final ownerRef = game.userRef;
      if (ownerRef != null) {
        final ownerProfile = await profileProvider.getProfile(ownerRef.id);
        if (ownerProfile != null) {
          final ownerFriends = ownerProfile.friends;
          isOwnerFriendsWithUser = ownerFriends.any(
            (ref) => ref.id == currentUserRef.id,
          );
        } else {
          isOwnerFriendsWithUser = false;
        }
      }
    } catch (error) {
      AppLog.d('JoinGameDetailedController owner friend check failed: $error');
    }

    if (isPublic || (isFriendsOnly && isOwnerFriendsWithUser)) {
      return const _JoinAccessResult(allowed: true);
    }

    return const _JoinAccessResult(
      allowed: false,
      message: 'You must be friends with the game creator to join this game.',
    );
  }

  Future<String> _loadOwnerFirstName(
    DocumentReference? ownerRef,
    ProfileProvider profileProvider,
  ) async {
    if (ownerRef == null) {
      return 'This player';
    }
    try {
      final ownerProfile = await profileProvider.getProfile(ownerRef.id);
      if (ownerProfile != null) {
        final firstName = ownerProfile.firstName;
        final displayName = ownerProfile.displayName;
        if (firstName.trim().isNotEmpty) {
          return firstName;
        }
        if (displayName.trim().isNotEmpty) {
          return displayName.split(' ').first;
        }
      }
    } catch (error) {
      AppLog.d('JoinGameDetailedController owner name lookup failed: $error');
    }
    return 'This player';
  }

}

class _JoinAccessResult {
  const _JoinAccessResult({
    required this.allowed,
    this.message,
  });

  final bool allowed;
  final String? message;
}
