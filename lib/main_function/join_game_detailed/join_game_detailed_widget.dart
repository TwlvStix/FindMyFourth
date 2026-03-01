import 'dart:async';

import '/backend/backend.dart';
import '/core/motion/animation_helpers.dart';
import '/core/motion/motion_helpers.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/vibe_floor_bottom_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/main_function/game_joined_detailed/components/group_vibe_summary.dart';
import '/main_function/game_joined_detailed/components/premium_app_bar.dart';
import '/core/widgets/trust/restriction_banner.dart';
import '/core/widgets/cancelled_game_banner.dart';
import '/core/widgets/game_details_section.dart';
import '/core/widgets/premium_section_header.dart';
import '/utils/app_util.dart';
import '/core/utils/firebase_error_utils.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/providers/trust_provider.dart';
import '/providers/user_provider.dart';
import '/models/game.dart';
import '/models/join_request.dart';
import '/models/player_eligibility.dart';
import '/models/vibe_profile.dart';
import '/providers/provider_extensions.dart';
import '/providers/game_provider.dart';
import '/providers/profile_provider.dart';
import '/providers/join_request_provider.dart';
import '/services/vibe_group_matcher.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '/providers/chat_provider.dart';
import '/core/widgets/vibe/group_vibe_breakdown_sheet.dart';
import '/main_function/game_joined_detailed/components/player_list_section.dart';
import 'controllers/join_game_detailed_controller.dart';
import 'components/join_game_state_handler.dart';
import 'components/host_hero_card.dart';
import 'components/join_game_action_section.dart';
import 'components/available_game_stats_row.dart';

class JoinGameDetailedWidget extends StatefulWidget {
  const JoinGameDetailedWidget({
    super.key,
    this.gameRef,
  });

  final DocumentReference? gameRef;

  static String routeName = 'JoinGameDetailed';
  static String routePath = '/joinGameDetailed';

  @override
  State<JoinGameDetailedWidget> createState() => _JoinGameDetailedWidgetState();
}

class _JoinGameDetailedWidgetState extends State<JoinGameDetailedWidget>
    with SingleTickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final JoinGameDetailedController _controller = JoinGameDetailedController();
  bool _hasLoggedAccessDenied = false;
  bool _hasShownAccessDeniedDialog = false;
  bool _hasAnimated = false;
  JoinRequest? _existingRequest;
  bool _isCheckingRequest = true;
  String? _lastCheckedGameId;

  void _ensureExistingRequestChecked(String gameId, String userId) {
    if (_lastCheckedGameId == gameId) return;
    _lastCheckedGameId = gameId;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        final request = await _controller.loadExistingRequest(
          joinRequestProvider: context.read<JoinRequestProvider>(),
          gameId: gameId,
          userId: userId,
        );

        if (mounted) {
          setState(() {
            _existingRequest = request;
            _isCheckingRequest = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isCheckingRequest = false);
        }
      }
    });
  }

  void _logAccessDeniedOnce(String gameId, Object error) {
    if (_hasLoggedAccessDenied) return;
    _hasLoggedAccessDenied = true;
    AppLog.d(
      'JoinGameDetailed: access denied for game $gameId (likely friends-only). Error: $error',
    );
  }

  Future<void> _showFriendsOnlyDialogAndPop(BuildContext context) async {
    if (_hasShownAccessDeniedDialog) return;
    _hasShownAccessDeniedDialog = true;
    await showPremiumDialog(
      context: context,
      variant: PremiumDialogVariant.informational,
      icon: PhosphorIconsRegular.lock,
      title: 'Friends Only Game',
      body:
          'This game is visible to friends only. Add the host as a friend to view details.',
      actionLabel: 'Got It',
    );
    if (!context.mounted) return;
    context.pop();
  }

  Future<void> _handleJoinPressed({
    required Game game,
    required DocumentReference? currentUserRef,
    required bool isCreatorFriend,
    required String? userGender,
  }) async {
    final joinResult = await _controller.attemptJoin(
      game: game,
      currentUserRef: currentUserRef,
      isCreatorFriend: isCreatorFriend,
      userGender: userGender,
      gameProvider: context.read<GameProvider>(),
      chatProvider: context.read<ChatProvider>(),
      userProvider: context.read<UserProvider>(),
    );

    if (!mounted) return;

    if (joinResult.status == JoinGameAttemptStatus.requiresApproval) {
      final payload = joinResult.approvalPayload;
      if (payload == null) {
        showSnackbar(
          context,
          'Unable to submit request right now. Please try again.',
        );
        return;
      }

      final eligibility = payload.eligibilityData;
      final submittedRequest = await showAppBottomSheet<JoinRequest?>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => VibeFloorBottomSheet(
          ownerFirstName: payload.ownerFirstName,
          playerName: payload.playerName,
          matchResult: eligibility.matchResult!,
          ownerProfile: eligibility.ownerProfile!,
          playerProfile: eligibility.playerProfile!,
          gameId: game.reference.id,
          playerId: payload.currentUserId,
          ownerId: payload.ownerId,
          vibeScore: eligibility.vibeScore!,
          vibeFloor: eligibility.vibeFloor!,
        ),
      );

      if (submittedRequest != null) {
        setState(() {
          _existingRequest = submittedRequest;
          _isCheckingRequest = false;
        });
      }
      return;
    }

    if (joinResult.status == JoinGameAttemptStatus.genderRestricted) {
      final restrictionLabel =
          game.playerEligibility == PlayerEligibility.womenOnly
              ? 'women'
              : 'men';
      await showPremiumDialog(
        context: context,
        variant: PremiumDialogVariant.informational,
        icon: PhosphorIconsRegular.prohibit,
        title: 'Unable to Join',
        body: 'This game is restricted to $restrictionLabel only.',
        actionLabel: 'OK',
      );
      return;
    }

    if (joinResult.status != JoinGameAttemptStatus.success) {
      final message = joinResult.message;
      if (message != null && message.isNotEmpty) {
        showSnackbar(context, message);
      }
      return;
    }

    context.goGameJoinedDetailed(
      gameRef: game.reference,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserRef = currentUserReference;
    final gameRef = widget.gameRef;

    // Handle null gameRef
    if (gameRef == null) {
      return JoinGameStateHandler(
        props: JoinGameStateProps(
          gameRef: null,
          hasError: false,
          hasData: false,
          child: const SizedBox.shrink(),
        ),
      );
    }

    return StreamBuilder<GamesRecord?>(
      stream: context.read<GameProvider>().watchGame(gameRef.id),
      builder: (context, snapshot) {
        // Handle permission denied (friends-only)
        if (snapshot.hasError) {
          final error = snapshot.error!;
          if (FirebaseErrorUtils.isPermissionDenied(error)) {
            _logAccessDeniedOnce(gameRef.id, error);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showFriendsOnlyDialogAndPop(context);
            });
            return const SizedBox.shrink();
          }
          return JoinGameStateHandler(
            props: JoinGameStateProps(
              gameRef: gameRef,
              hasError: true,
              hasData: false,
              child: const SizedBox.shrink(),
            ),
          );
        }

        // Loading or null data state
        final gamesRecord = snapshot.data;
        if (!snapshot.hasData || gamesRecord == null) {
          return JoinGameStateHandler(
            props: JoinGameStateProps(
              gameRef: gameRef,
              hasError: false,
              hasData: false,
              child: const SizedBox.shrink(),
            ),
          );
        }

        return _buildGameContent(
          context: context,
          gamesRecord: gamesRecord,
          currentUserRef: currentUserRef,
        );
      },
    );
  }

  Widget _buildGameContent({
    required BuildContext context,
    required GamesRecord gamesRecord,
    required DocumentReference? currentUserRef,
  }) {
    final game = Game.fromRecord(gamesRecord);
    final groupVibeProvider = context.watchGroupVibeProvider;
    final currentUserId = currentUserRef?.id;

    final groupVibeCacheKey = currentUserId == null
        ? null
        : groupVibeProvider.buildGameCacheKey(
            gameRecord: game,
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
      _loadGroupVibe(
        context: context,
        groupVibeProvider: groupVibeProvider,
        groupVibeCacheKey: groupVibeCacheKey,
        game: game,
        currentUserId: currentUserId,
      );
    }

    final isCancelled = game.isCancelledStatus;

    if (currentUserRef != null) {
      _ensureExistingRequestChecked(game.reference.id, currentUserRef.id);
    }

    // Trigger entrance animation once
    if (!_hasAnimated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasAnimated) setState(() => _hasAnimated = true);
      });
    }

    return Scaffold(
      key: scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: const PremiumAppBar(title: 'Available Game'),
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: SafeArea(
          top: false,
          child: StreamBuilder<UsersRecord>(
            stream: currentUserRef == null
                ? null
                : UsersRecord.getDocument(currentUserRef),
            builder: (context, userSnapshot) {
              final currentUserRecord =
                  userSnapshot.hasData ? userSnapshot.data : null;
              final isCreatorFriend =
                  currentUserRecord?.friends.contains(game.userRef) ?? false;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top padding for AppBar
                    SizedBox(height: MediaQuery.of(context).padding.top + 22),

                    // Hero Section with host info
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      child: HostHeroCard(
                        game: game,
                        hasAnimated: _hasAnimated,
                      ),
                    )
                        .animate(target: _hasAnimated ? 1 : 0)
                        .fadeIn(
                          duration: ReducedMotionService.adjust(
                            MotionTokens.routeEnter,
                          ),
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
                          duration: ReducedMotionService.adjust(
                            MotionTokens.routeEnter,
                          ),
                          curve: MotionTokens.curveEnter,
                        ),

                    // Quick Stats Row
                    buildAnimatedSection(
                      sectionIndex: 0,
                      hasAnimated: _hasAnimated,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: AvailableGameStatsRow(game: game),
                      ),
                    ),

                    SizedBox(height: AppSpacing.md),

                    // Group Vibe Summary
                    buildAnimatedSection(
                      sectionIndex: 1,
                      hasAnimated: _hasAnimated,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: GroupVibeSummary(
                          groupVibeMatch: groupVibeMatch,
                          onViewBreakdown: () {
                            if (groupVibeMatch == null) return;
                            GroupVibeBreakdownSheet.show(
                              context: context,
                              result: groupVibeMatch,
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: AppSpacing.lg),

                    // Game Details Section
                    buildAnimatedSection(
                      sectionIndex: 2,
                      hasAnimated: _hasAnimated,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PremiumSectionHeader(title: 'Game Details'),
                            SizedBox(height: AppSpacing.sm),
                            GameDetailsSection(game: game),
                            SizedBox(height: AppSpacing.lg),
                            PremiumSectionHeader(
                              title: 'Players',
                              trailing: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.navyLight
                                      .withValues(alpha: 0.3),
                                  borderRadius:
                                      BorderRadius.circular(AppBorderRadius.md),
                                ),
                                child: Text(
                                  '${game.playerCount}/4',
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

                    // Players list
                    PlayerListSection(
                      game: game,
                      memberMatchesById: memberMatchesById,
                      groupVibeCacheKey: groupVibeCacheKey,
                      hasAnimated: _hasAnimated,
                      isOwner: false,
                      onRemovePlayer: null,
                      onPlayerTap: (userRef) => context.pushProfileUser(
                        userRef: userRef,
                      ),
                      onMatchChipTap: null,
                    ),

                    SizedBox(height: AppSpacing.md),

                    // Cancelled game banner
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

                    // Restriction banner
                    if (game.userRef != currentUserRef && !isCancelled)
                      Consumer<TrustProvider>(
                        builder: (context, trust, _) {
                          final restriction =
                              trust.myStanding?.currentRestriction;
                          if (restriction == null) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              AppSpacing.md,
                            ),
                            child: RestrictionBanner(
                              restriction: restriction,
                              onViewStanding: () => context.pushYourStanding(),
                            ),
                          );
                        },
                      ),

                    // Join button section
                    if (game.userRef != currentUserRef && !isCancelled)
                      Consumer2<TrustProvider, UserProvider>(
                        builder: (context, trust, userProvider, _) {
                          final isRestricted =
                              trust.myStanding?.currentRestriction != null;
                          final userGender = userProvider.currentUser?.gender;

                          return JoinGameActionSection(
                            state: JoinGameActionState(
                              game: game,
                              existingRequest: _existingRequest,
                              isCheckingRequest: _isCheckingRequest,
                              isRestricted: isRestricted,
                              userGender: userGender,
                            ),
                            onJoinPressed: () => _handleJoinPressed(
                              game: game,
                              currentUserRef: currentUserRef,
                              isCreatorFriend: isCreatorFriend,
                              userGender: userGender,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _loadGroupVibe({
    required BuildContext context,
    required dynamic groupVibeProvider,
    required String groupVibeCacheKey,
    required Game game,
    required String currentUserId,
  }) {
    final memberIds = groupVibeProvider.otherMemberIdsForGame(
      gameRecord: game,
      currentUserId: currentUserId,
    ) as List<String>;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        context.groupVibeProvider.ensureGroupVibeMatch(
          cacheKey: groupVibeCacheKey,
          memberUserIds: memberIds,
          memberLoader: (userIds) async {
            final profileMap =
                await context.read<ProfileProvider>().batchGetProfiles(userIds);
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
                  profile: VibeProfile.fromFirestore(userRecord.vibeProfile),
                ),
              );
            }
            return members;
          },
        ),
      );
    });
  }
}
