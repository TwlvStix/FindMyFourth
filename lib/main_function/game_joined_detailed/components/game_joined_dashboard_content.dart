import '/backend/backend.dart';
import '/core/design_tokens/spacing.dart';
import '/models/game.dart';
import '/models/join_request.dart';
import '/models/vibe_profile.dart';
import '/services/vibe_group_matcher.dart';
import 'package:flutter/material.dart';

import 'game_joined_dashboard_actions_section.dart';
import 'game_joined_dashboard_details_players_section.dart';
import 'game_joined_dashboard_overview_section.dart';

// Public callback typedefs - exported for parent widget wiring
typedef ApproveJoinRequestCallback = Future<void> Function(JoinRequest request);
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
    return SafeArea(
      top: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.top + 22),
          ),
          SliverToBoxAdapter(
            child: GameJoinedDashboardOverviewSection(
              game: game,
              currentUserRef: currentUserRef,
              hasAnimated: hasAnimated,
              groupVibeCacheKey: groupVibeCacheKey,
              onEditGameDetails: onEditGameDetails,
            ),
          ),
          // Player list section: max 4 players + game details, FutureBuilder-driven --
          // SliverToBoxAdapter is appropriate here (SliverList would require deep
          // refactor of PlayerListSection for negligible gain on 4 items).
          SliverToBoxAdapter(
            child: GameJoinedDashboardDetailsPlayersSection(
              game: game,
              screenGameRef: screenGameRef,
              currentUserRef: currentUserRef,
              hasAnimated: hasAnimated,
              groupVibeCacheKey: groupVibeCacheKey,
              pendingRequests: pendingRequests,
              ownerVibeProfile: ownerVibeProfile,
              expandedRequestId: expandedRequestId,
              onApproveRequest: onApproveRequest,
              onDeclineRequest: onDeclineRequest,
              onRemoveRequest: onRemoveRequest,
              onExpandRequest: onExpandRequest,
              onShowRemovePlayerDialog: onShowRemovePlayerDialog,
              onOpenPremiumVibePage: onOpenPremiumVibePage,
            ),
          ),
          SliverToBoxAdapter(
            child: GameJoinedDashboardActionsSection(
              game: game,
              screenGameRef: screenGameRef,
              currentUserRef: currentUserRef,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.md),
          ),
        ],
      ),
    );
  }
}
