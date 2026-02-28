import 'dart:async';

import '/backend/backend.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/core/content/app_copy.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/exceptions/app_exceptions.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/core/widgets/fairway_background.dart';
import '/models/game.dart';
import '/models/join_request.dart';
import '/models/vibe_profile.dart';
import '/providers/game_provider.dart';
import '/providers/join_request_provider.dart';
import '/providers/profile_provider.dart';
import '/providers/provider_extensions.dart';
import '/services/vibe_group_matcher.dart';
import '/services/vibe_repository.dart';
import '/utils/app_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import 'components/edit_game_details_bottom_sheet.dart';
import 'components/game_joined_dashboard_content.dart';
import 'components/game_joined_state_handler.dart';
import 'components/open_premium_vibe_page.dart';
import 'components/premium_app_bar.dart';

class GameJoinedDetailedWidget extends StatefulWidget {
  const GameJoinedDetailedWidget({
    super.key,
    this.gameRef,
  });

  final DocumentReference? gameRef;

  static String routeName = 'GameJoinedDetailed';
  static String routePath = '/gameJoinedDetailed';

  @override
  State<GameJoinedDetailedWidget> createState() =>
      _GameJoinedDetailedWidgetState();
}

class _GameJoinedDetailedWidgetState extends State<GameJoinedDetailedWidget>
    with SingleTickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final VibeRepository _vibeRepository = VibeRepository();

  bool _hasAnimated = false;

  List<JoinRequest> _pendingRequests = [];
  bool _isLoadingPendingRequests = false;
  String? _lastLoadedPendingGameId;
  VibeProfile? _ownerVibeProfile;
  String? _expandedRequestId;

  @override
  void initState() {
    super.initState();
  }

  void _ensurePendingRequestsLoaded(String gameId, String ownerId) {
    if (_lastLoadedPendingGameId == gameId || _isLoadingPendingRequests) {
      return;
    }
    _lastLoadedPendingGameId = gameId;
    _isLoadingPendingRequests = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      try {
        final results = await Future.wait([
          context
              .read<JoinRequestProvider>()
              .getPendingRequestsForGame(gameId, ownerId),
          _vibeRepository.getVibeProfileForUser(ownerId),
        ]);

        if (!mounted) {
          return;
        }

        final requests = results[0] as List<JoinRequest>;
        requests.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        setState(() {
          _pendingRequests = requests;
          _ownerVibeProfile = results[1] as VibeProfile;
          _isLoadingPendingRequests = false;
          if (_pendingRequests.isNotEmpty) {
            _expandedRequestId = _pendingRequests.first.id;
          }
        });
      } catch (error) {
        AppLog.d('Error loading pending join requests: $error');
        if (mounted) {
          setState(() {
            _isLoadingPendingRequests = false;
          });
        }
      }
    });
  }

  Future<void> _handleApproveRequest(
      JoinRequest request, String? chatId) async {
    try {
      await context.read<JoinRequestProvider>().approveJoinRequest(
            gameId: request.gameId,
            requestId: request.id,
            requesterId: request.requesterId,
            chatId: chatId,
          );
      if (mounted) {
        context.gameProvider.invalidateAvailableGamesCache();
      }
    } on GameOperationException catch (error) {
      if (error.code == 'game-full' && mounted) {
        showSnackbar(context, AppVibeFloorCopy.roundFullError);
        context.read<JoinRequestProvider>().notifyRoundFilledBeforeApproval(
              request.gameId,
              request.requesterId,
            );
      }
    } catch (_) {
      if (mounted) {
        showSnackbar(context, 'Failed to approve request. Please try again.');
      }
    }
  }

  Future<void> _handleDeclineRequest(JoinRequest request) async {
    try {
      await context.read<JoinRequestProvider>().declineJoinRequest(
            gameId: request.gameId,
            requestId: request.id,
            requesterId: request.requesterId,
          );
    } catch (_) {
      if (mounted) {
        showSnackbar(context, 'Failed to decline request. Please try again.');
      }
    }
  }

  void _removeRequestFromList(String requestId) {
    if (!mounted) {
      return;
    }

    setState(() {
      _pendingRequests.removeWhere((r) => r.id == requestId);
      if (_expandedRequestId == requestId) {
        _expandedRequestId =
            _pendingRequests.isNotEmpty ? _pendingRequests.first.id : null;
      }
    });
  }

  void _expandRequest(String requestId) {
    if (_expandedRequestId != requestId) {
      setState(() {
        _expandedRequestId = requestId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameRef = widget.gameRef;

    if (gameRef == null) {
      return GameJoinedStateHandler(
        props: GameJoinedStateProps(
          gameRef: null,
          hasError: false,
          hasData: false,
          isDataNull: false,
          child: const SizedBox.shrink(),
        ),
      );
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserRef = currentUser == null
        ? null
        : FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

    return StreamBuilder<GamesRecord?>(
      stream: context.read<GameProvider>().watchGame(gameRef.id),
      builder: (context, snapshot) {
        final gamesRecord = snapshot.data;

        if (snapshot.hasError || !snapshot.hasData || gamesRecord == null) {
          return GameJoinedStateHandler(
            props: GameJoinedStateProps(
              gameRef: gameRef,
              hasError: snapshot.hasError,
              hasData: snapshot.hasData,
              isDataNull: snapshot.hasData && gamesRecord == null,
              errorMessage: 'Please try again later.',
              child: const SizedBox.shrink(),
            ),
          );
        }

        final gameRecord = Game.fromRecord(gamesRecord);

        final groupVibeProvider = context.watchGroupVibeProvider;
        final currentUserId = currentUserRef?.id;
        final groupVibeCacheKey = currentUserId == null
            ? null
            : groupVibeProvider.buildGameCacheKey(
                gameRecord: gameRecord,
                currentUserId: currentUserId,
              );
        final groupVibeMatch = groupVibeCacheKey == null
            ? null
            : groupVibeProvider.getMatch(groupVibeCacheKey);
        final memberMatchesById = groupVibeCacheKey == null
            ? const <String, GroupVibeMemberResult>{}
            : groupVibeProvider.getMemberMatchesById(groupVibeCacheKey);

        if (groupVibeCacheKey != null &&
            currentUserId != null &&
            groupVibeProvider.shouldLoad(groupVibeCacheKey)) {
          final memberIds = groupVibeProvider.otherMemberIdsForGame(
            gameRecord: gameRecord,
            currentUserId: currentUserId,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            unawaited(
              context.groupVibeProvider.ensureGroupVibeMatch(
                cacheKey: groupVibeCacheKey,
                memberUserIds: memberIds,
                memberLoader: (userIds) async {
                  final profileMap =
                      await context.read<ProfileProvider>().batchGetProfiles(
                            userIds,
                          );
                  final members = <GroupVibeMember>[];
                  for (final entry in profileMap.entries) {
                    final userRecord = entry.value;
                    final displayName = userRecord.displayName.isNotEmpty
                        ? userRecord.displayName
                        : 'Player';
                    members.add(
                      GroupVibeMember(
                        id: entry.key,
                        name: displayName,
                        profile:
                            VibeProfile.fromFirestore(userRecord.vibeProfile),
                      ),
                    );
                  }
                  return members;
                },
              ),
            );
          });
        }

        if (gameRecord.userRef == currentUserRef && currentUserRef != null) {
          _ensurePendingRequestsLoaded(
            gameRecord.reference.id,
            currentUserRef.id,
          );
        }

        if (!_hasAnimated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasAnimated) {
              setState(() {
                _hasAnimated = true;
              });
            }
          });
        }

        return Scaffold(
          key: scaffoldKey,
          extendBodyBehindAppBar: true,
          appBar: const PremiumAppBar(title: 'Game Dashboard'),
          body: FairwayBackgroundDark(
            showOrganic: true,
            showTexture: true,
            child: GameJoinedDashboardContent(
              game: gameRecord,
              screenGameRef: gameRef,
              currentUserRef: currentUserRef,
              hasAnimated: _hasAnimated,
              groupVibeMatch: groupVibeMatch,
              memberMatchesById: memberMatchesById,
              groupVibeCacheKey: groupVibeCacheKey,
              pendingRequests: _pendingRequests,
              ownerVibeProfile: _ownerVibeProfile,
              expandedRequestId: _expandedRequestId,
              onApproveRequest: _handleApproveRequest,
              onDeclineRequest: _handleDeclineRequest,
              onRemoveRequest: _removeRequestFromList,
              onExpandRequest: _expandRequest,
              onShowRemovePlayerDialog: _showRemovePlayerDialog,
              onOpenPremiumVibePage: _openPremiumVibePage,
              onEditGameDetails: _handleEditGameDetails,
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPremiumVibePage(
    BuildContext context,
    DocumentReference userRef,
    String userName,
    String userPhotoUrl,
    GroupVibeMemberResult? memberMatch,
  ) {
    return openPremiumVibePage(
      context: context,
      vibeRepository: _vibeRepository,
      userRef: userRef,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      memberMatch: memberMatch,
    );
  }

  Future<void> _showRemovePlayerDialog({
    required BuildContext context,
    required String playerName,
    required DocumentReference? playerRef,
    required bool isGuest,
    String? guestName,
    required Game gameRecord,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserRef = currentUser == null
        ? null
        : FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

    if (!isGuest && playerRef == currentUserRef) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('You cannot remove yourself. Use "Cancel game" instead.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await showPremiumDialog(
          context: context,
          variant: PremiumDialogVariant.destructive,
          icon: PhosphorIconsRegular.userMinus,
          title: 'Remove Player',
          body: 'This will remove $playerName from the game.',
          actionLabel: 'Remove',
        ) ??
        false;

    if (confirmed) {
      if (!context.mounted) {
        return;
      }
      await _removePlayer(
        context: context,
        playerRef: playerRef,
        isGuest: isGuest,
        guestName: guestName,
        playerName: playerName,
        gameRecord: gameRecord,
      );
    }
  }

  Future<void> _removePlayer({
    required BuildContext context,
    required DocumentReference? playerRef,
    required bool isGuest,
    String? guestName,
    required String playerName,
    required Game gameRecord,
  }) async {
    final gameRef = widget.gameRef;
    if (gameRef == null) {
      AppLog.d('Player Management: gameRef is null');
      return;
    }

    try {
      await context.gameProvider.removePlayer(
        gameRef.id,
        playerId: playerRef?.id,
        guestName: guestName,
        isGuest: isGuest,
        chatId: gameRecord.chatRef?.id,
      );

      if (!context.mounted) {
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$playerName removed from game'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove player. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleEditGameDetails(
    BuildContext context,
    Game gameRecord,
  ) async {
    final teeTime = gameRecord.date;
    if (teeTime != null) {
      final hoursUntilTeeTime = teeTime.difference(DateTime.now()).inHours;
      if (hoursUntilTeeTime < 2) {
        await showPremiumDialog(
          context: context,
          variant: PremiumDialogVariant.informational,
          icon: PhosphorIconsRegular.info,
          title: 'Cannot Edit',
          body:
              'Tee time is less than 2 hours away. Consider cancelling this game and creating a new one instead.',
          actionLabel: 'Got It',
        );
        return;
      }
    }

    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditGameDetailsBottomSheet(
        gameRef: gameRecord.reference,
        initialDate: gameRecord.date ?? DateTime.now(),
        initialCourse: gameRecord.coursePlay,
        initialCourseRef: gameRecord.courseRef,
      ),
    );

    if (result != null && context.mounted) {
      await _updateGameDetails(context, gameRecord, result);
    }
  }

  Future<void> _updateGameDetails(
    BuildContext context,
    Game gameRecord,
    Map<String, dynamic> updateData,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          margin: EdgeInsets.all(AppSpacing.xl),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.green),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Updating game details...',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await context.gameProvider.updateGame(
        gameRecord.reference.id,
        <String, dynamic>{
          'date': updateData['date'],
          'course_play': updateData['course'],
          'courseRef': updateData['courseRef'],
        },
      );

      final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
      final recipients = gameRecord.joinedPlayers
          .where((ref) => ref.id != currentUserUid)
          .toList();

      if (recipients.isNotEmpty) {
        final newDate = updateData['date'] as DateTime;
        final newCourse = updateData['course'] as String;
        final dayName = dateTimeFormat('EEEE', newDate);
        final dateStr = dateTimeFormat('MMM d', newDate);
        final timeStr = dateTimeFormat('jm', newDate);
        final notificationText =
            'Game updated — now $dayName $dateStr, $timeStr at $newCourse';

        triggerPushNotification(
          notificationTitle: 'Game Details Updated',
          notificationText: notificationText,
          userRefs: recipients,
          initialPageName: 'GameJoinedDetailed',
          parameterData: {'gameRef': gameRecord.reference.path},
        );
      }

      if (!context.mounted) {
        return;
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Game details updated!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (error) {
      AppLog.d('Edit Game Details failed: $error');
      if (!context.mounted) {
        return;
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update game details: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
