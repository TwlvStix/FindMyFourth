import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/motion/animation_helpers.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/cancelled_game_banner.dart';
import '/core/widgets/game_details_section.dart';
import '/core/widgets/premium_section_header.dart';
import '/models/game.dart';
import '/models/join_request.dart';
import '/models/vibe_profile.dart';
import '/services/vibe_group_matcher.dart';
import '/utils/app_util.dart';
import 'package:flutter/material.dart';

import 'pending_requests_section.dart';
import 'player_list_section_selector.dart';

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

class GameJoinedDashboardDetailsPlayersSection extends StatelessWidget {
  const GameJoinedDashboardDetailsPlayersSection({
    super.key,
    required this.game,
    required this.screenGameRef,
    required this.currentUserRef,
    required this.hasAnimated,
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
  });

  final Game game;
  final DocumentReference? screenGameRef;
  final DocumentReference? currentUserRef;
  final bool hasAnimated;
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

  @override
  Widget build(BuildContext context) {
    final isCancelled = game.isCancelledStatus;
    final isOwner = game.userRef == currentUserRef;
    final playerCount = _getPlayerCount(game);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
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
        PlayerListSectionSelector(
          game: game,
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
                  isEditMode: true,
                  transition: TransitionStandards.detailTransition,
                );
              },
            ),
          ),
        if (isOwner && playerCount < 4 && !isCancelled)
          SizedBox(height: AppSpacing.md),
      ],
    );
  }

  int _getPlayerCount(Game gameRecord) {
    final joinedCount = gameRecord.joinedPlayers.length;
    final guestCount =
        gameRecord.guestPlayers.where((name) => name.trim().isNotEmpty).length;
    return joinedCount + guestCount;
  }
}
