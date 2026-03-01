import '/backend/backend.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/animation_helpers.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/core/widgets/cancelled_game_banner.dart';
import '/core/widgets/game_details_section.dart';
import '/core/widgets/premium_section_header.dart';
import '/core/widgets/vibe/group_vibe_breakdown_sheet.dart';
import '/models/game.dart';
import '/models/join_request.dart';
import '/models/vibe_profile.dart';
import '/providers/chat_provider.dart';
import '/providers/provider_extensions.dart';
import '/screens/trust/cancellation_warning_modal.dart';
import '/services/vibe_group_matcher.dart';
import '/utils/app_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import 'firm_it_up_banner.dart';
import 'firm_it_up_bottom_sheet.dart';
import 'group_vibe_summary.dart';
import 'pending_requests_section.dart';
import 'player_list_section.dart';
import 'premium_hero_section.dart';
import 'quick_stats_row.dart';

const int _cancelledChatArchiveDays = 3;

typedef ApproveJoinRequestCallback = Future<void> Function(
  JoinRequest request,
  String? chatId,
);
typedef DeclineJoinRequestCallback = Future<void> Function(JoinRequest request);
typedef RemoveRequestCallback = void Function(String requestId);
typedef ExpandRequestCallback = void Function(String requestId);

typedef ShowRemovePlayerDialogCallback = Future<void> Function({
  required BuildContext context,
  required String playerName,
  required DocumentReference? playerRef,
  required bool isGuest,
  String? guestName,
  required Game gameRecord,
});

typedef OpenPremiumVibePageCallback = Future<void> Function(
  BuildContext context,
  DocumentReference userRef,
  String userName,
  String userPhotoUrl,
  GroupVibeMemberResult? memberMatch,
);

typedef EditGameDetailsCallback = Future<void> Function(
  BuildContext context,
  Game gameRecord,
);

class GameJoinedDashboardContent extends StatelessWidget {
  const GameJoinedDashboardContent({
    super.key,
    required this.game,
    required this.screenGameRef,
    required this.currentUserRef,
    required this.hasAnimated,
    required this.groupVibeMatch,
    required this.memberMatchesById,
    required this.groupVibeCacheKey,
    required this.pendingRequests,
    required this.ownerVibeProfile,
    required this.expandedRequestId,
    required this.onApproveRequest,
    required this.onDeclineRequest,
    required this.onRemoveRequest,
    required this.onExpandRequest,
    required this.onShowRemovePlayerDialog,
    required this.onOpenPremiumVibePage,
    required this.onEditGameDetails,
  });

  final Game game;
  final DocumentReference? screenGameRef;
  final DocumentReference? currentUserRef;
  final bool hasAnimated;
  final GroupVibeMatchResult? groupVibeMatch;
  final Map<String, GroupVibeMemberResult> memberMatchesById;
  final String? groupVibeCacheKey;
  final List<JoinRequest> pendingRequests;
  final VibeProfile? ownerVibeProfile;
  final String? expandedRequestId;
  final ApproveJoinRequestCallback onApproveRequest;
  final DeclineJoinRequestCallback onDeclineRequest;
  final RemoveRequestCallback onRemoveRequest;
  final ExpandRequestCallback onExpandRequest;
  final ShowRemovePlayerDialogCallback onShowRemovePlayerDialog;
  final OpenPremiumVibePageCallback onOpenPremiumVibePage;
  final EditGameDetailsCallback onEditGameDetails;

  @override
  Widget build(BuildContext context) {
    final isCancelled = game.isCancelledStatus;
    final isOwner = game.userRef == currentUserRef;
    final playerCount = _getPlayerCount(game);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 56),
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: PremiumHeroSection(game: game),
            )
                .animate(target: hasAnimated ? 1 : 0)
                .fadeIn(
                  duration:
                      ReducedMotionService.adjust(MotionTokens.routeEnter),
                  curve: MotionTokens.curveEnter,
                )
                .scale(
                  begin: ReducedMotionService.shouldScale
                      ? Offset(
                          MotionTokens.pageScaleStart,
                          MotionTokens.pageScaleStart,
                        )
                      : const Offset(1, 1),
                  end: const Offset(1, 1),
                  duration:
                      ReducedMotionService.adjust(MotionTokens.routeEnter),
                  curve: MotionTokens.curveEnter,
                ),
            if (game.scheduleType == 'flexible' && isOwner)
              buildAnimatedSection(
                sectionIndex: 0,
                hasAnimated: hasAnimated,
                child: FirmItUpBanner(
                  onPressed: () async {
                    final result =
                        await showModalBottomSheet<Map<String, dynamic>?>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => FirmItUpBottomSheet(
                        gameRef: game.reference,
                      ),
                    );

                    if (result != null && context.mounted) {
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
                                  CircularProgressIndicator(
                                    color: AppColors.green,
                                  ),
                                  SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Confirming tee time...',
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
                          game.reference.id,
                          <String, dynamic>{
                            'schedule_type': 'confirmed',
                            'date': result['date'],
                            'course_play': result['course'],
                            'courseRef': result['courseRef'],
                            'flexible_week': null,
                            'flexible_days': null,
                            'flexible_time_of_day': null,
                          },
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tee time confirmed!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (error, stackTrace) {
                        AppLog.d('Firm It Up failed: $error');
                        AppLog.d('Firm It Up stackTrace: $stackTrace');
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Failed to confirm tee time: $error'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ),
            buildAnimatedSection(
              sectionIndex: 1,
              hasAnimated: hasAnimated,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: QuickStatsRow(
                  game: game,
                  isOwner: isOwner,
                  onEditPressed:
                      isOwner ? () => onEditGameDetails(context, game) : null,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            if (game.chatRef != null)
              buildAnimatedSection(
                sectionIndex: 2,
                hasAnimated: hasAnimated,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final chatRef = game.chatRef;
                      if (chatRef == null) {
                        return;
                      }
                      if (currentUserRef == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please sign in to open the chat.'),
                          ),
                        );
                        return;
                      }
                      final isMember = game.joinedPlayers
                          .any((p) => p.id == currentUserRef!.id);
                      if (!isMember) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Join the game to access the group chat.'),
                          ),
                        );
                        return;
                      }
                      if (!context.mounted) {
                        return;
                      }
                      context.pushChatDetails(
                        chatId: chatRef.id,
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.green, AppColors.greenLight],
                        ),
                        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                        boxShadow: [AppElevation.glowGreen],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(
                            icon: AppPhosphorIcons.chat,
                            color: AppColors.pure,
                            size: AppIconSize.md,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            'Message Group',
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(height: AppSpacing.lg),
            buildAnimatedSection(
              sectionIndex: 3,
              hasAnimated: hasAnimated,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: GroupVibeSummary(
                  groupVibeMatch: groupVibeMatch,
                  onViewBreakdown: () {
                    if (groupVibeMatch == null) {
                      return;
                    }
                    GroupVibeBreakdownSheet.show(
                      context: context,
                      result: groupVibeMatch!,
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            buildAnimatedSection(
              sectionIndex: 4,
              hasAnimated: hasAnimated,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumSectionHeader(title: 'Game Details'),
                    SizedBox(height: AppSpacing.sm),
                    GameDetailsSection(game: game),
                    SizedBox(height: AppSpacing.lg),
                    if (isOwner &&
                        pendingRequests.isNotEmpty &&
                        ownerVibeProfile != null)
                      PendingRequestsSection(
                        pendingRequests: pendingRequests,
                        ownerVibeProfile: ownerVibeProfile!,
                        expandedRequestId: expandedRequestId,
                        onApprove: (request) =>
                            onApproveRequest(request, game.chatRef?.id),
                        onDecline: onDeclineRequest,
                        onRemoved: onRemoveRequest,
                        onExpandRequest: onExpandRequest,
                      ),
                    PremiumSectionHeader(
                      title: 'Players',
                      trailing: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navyLight.withValues(alpha: 0.3),
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.md),
                        ),
                        child: Text(
                          '$playerCount/4',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            PlayerListSection(
              game: game,
              memberMatchesById: memberMatchesById,
              groupVibeCacheKey: groupVibeCacheKey,
              hasAnimated: hasAnimated,
              isOwner: isOwner,
              onRemovePlayer: ({
                required String playerName,
                required DocumentReference? playerRef,
                required bool isGuest,
                String? guestName,
              }) =>
                  onShowRemovePlayerDialog(
                context: context,
                playerName: playerName,
                playerRef: playerRef,
                isGuest: isGuest,
                guestName: guestName,
                gameRecord: game,
              ),
              onPlayerTap: (userRef) => context.pushProfileUser(
                userRef: userRef,
              ),
              onMatchChipTap: (userRef, displayName, photoUrl, memberMatch) =>
                  onOpenPremiumVibePage(
                context,
                userRef,
                displayName,
                photoUrl,
                memberMatch,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            if (isCancelled)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: const CancelledGameBanner(),
              ),
            if (isOwner && playerCount < 4 && !isCancelled)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: AppButtonEnhanced(
                  text: 'Add Players',
                  leadingWidget: AppIcon(
                    icon: AppPhosphorIcons.addPlayer,
                    size: AppIconSize.button,
                    color: AppColors.textPrimary,
                  ),
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.medium,
                  fullWidth: true,
                  onPressed: () {
                    final gameRef = screenGameRef;
                    if (gameRef == null) {
                      return;
                    }
                    context.pushPlayerList(
                      gameRef: gameRef,
                      transition: TransitionStandards.detailTransition,
                    );
                  },
                ),
              ),
            if (isOwner && playerCount < 4 && !isCancelled)
              SizedBox(height: AppSpacing.md),
            if (!isOwner && !isCancelled)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: AppButtonEnhanced(
                  text: 'Leave game',
                  variant: AppButtonVariant.destructiveOutlined,
                  size: AppButtonSize.large,
                  fullWidth: true,
                  onPressed: () async {
                    final gameProvider = context.gameProvider;
                    final confirmed = await CancellationWarningModal.show(
                        context,
                        game: game);
                    if (confirmed != true || currentUserRef == null) {
                      return;
                    }
                    if (!context.mounted) {
                      return;
                    }
                    try {
                      await gameProvider.leaveGame(
                        game.reference.id,
                        currentUserRef!.id,
                        chatId: game.chatRef?.id,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('You left the game'),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        context.goGamesJoined();
                      }
                    } on FirebaseException catch (error) {
                      if (!context.mounted) {
                        return;
                      }
                      final message = error.code == 'permission-denied'
                          ? 'You do not have permission to leave this game.'
                          : 'Unable to leave the game right now. Please try again.';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    } catch (_) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Unable to leave the game right now. Please try again.',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
              ),
            if (isOwner && !isCancelled)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: AppButtonEnhanced(
                  text: 'Cancel game',
                  variant: AppButtonVariant.destructiveOutlined,
                  size: AppButtonSize.large,
                  fullWidth: true,
                  onPressed: () async {
                    final gameProvider = context.gameProvider;
                    final userProvider = context.userProvider;
                    final chatProvider = context.read<ChatProvider>();
                    if (currentUserRef == null || screenGameRef == null) {
                      return;
                    }
                    final confirmDialogResponse = await showPremiumDialog(
                          context: context,
                          variant: PremiumDialogVariant.destructive,
                          icon: PhosphorIconsRegular.xCircle,
                          title: 'Cancel Game',
                          body: 'This will end the game for all players.',
                          actionLabel: 'Cancel Game',
                          cancelLabel: 'Keep Game',
                        ) ??
                        false;
                    if (!confirmDialogResponse) {
                      return;
                    }

                    if (!context.mounted) {
                      return;
                    }
                    final shouldRemove = await showPremiumDialog(
                      context: context,
                      variant: PremiumDialogVariant.destructive,
                      icon: PhosphorIconsRegular.trashSimple,
                      title: 'Remove Game Listing',
                      body:
                          'This game will be removed from your list immediately.',
                      actionLabel: 'Delete Now',
                    );
                    if (shouldRemove != true) {
                      return;
                    }

                    if (!context.mounted) {
                      return;
                    }
                    AppState().setCancelledGameHandling(
                      screenGameRef!.path,
                      'removeNow',
                    );

                    try {
                      await gameProvider.cancelGame(screenGameRef!.id);
                      final currentUserId = currentUserRef!.id;
                      final chatRef = game.chatRef;
                      if (chatRef != null) {
                        final gameName = game.nameGame;
                        final cancelMessage = gameName.trim().isNotEmpty
                            ? 'Game "$gameName" has been cancelled.'
                            : 'This game has been cancelled.';
                        try {
                          await chatProvider.sendMessage(
                            chatId: chatRef.id,
                            senderId: currentUserId,
                            text: cancelMessage,
                          );
                          await chatRef.update({
                            'isReadOnly': true,
                            'pinnedMessage': cancelMessage,
                            'pinnedAt': FieldValue.serverTimestamp(),
                            'archivedAt': Timestamp.fromDate(
                              getCurrentTimestamp.add(
                                Duration(days: _cancelledChatArchiveDays),
                              ),
                            ),
                          });
                        } catch (chatError, stackTrace) {
                          AppLog.d('CancelGame: chat update failed $chatError');
                          AppLog.d('CancelGame stackTrace: $stackTrace');
                        }
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Game cancelled successfully'),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        gameProvider.invalidateUserGamesCache(
                          userProvider.userId,
                        );
                        context.goGamesList();
                      }
                    } catch (error, stackTrace) {
                      AppLog.d('CancelGame failed: $error');
                      AppLog.d('CancelGame stackTrace: $stackTrace');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Unable to cancel the game. Please try again.',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  int _getPlayerCount(Game gameRecord) {
    final joinedCount = gameRecord.joinedPlayers.length;
    final guestCount =
        gameRecord.guestPlayers.where((name) => name.trim().isNotEmpty).length;
    return joinedCount + guestCount;
  }
}
