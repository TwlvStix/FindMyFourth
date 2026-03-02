import 'dart:async';

import '/backend/backend.dart';
import '/core/motion/animation_helpers.dart';
import '/core/motion/motion_helpers.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/utils/app_log.dart';
import '/core/utils/state_update.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/vibe_floor_bottom_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/main_function/game_joined_detailed/components/group_vibe_summary_selector.dart';
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
import '/providers/game_provider.dart';
import '/providers/group_vibe_provider.dart';
import '/providers/profile_provider.dart';
import '/providers/join_request_provider.dart';
import '/services/vibe_group_matcher.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '/providers/chat_provider.dart';
import '/core/widgets/vibe/group_vibe_breakdown_sheet.dart';
import '/main_function/game_joined_detailed/components/player_list_section_selector.dart';
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

  // Stream subscription for game data (side effects handled via subscription)
  StreamSubscription<GamesRecord?>? _gameSubscription;

  // Local state for game data (replaces StreamBuilder to avoid duplicate listeners)
  GamesRecord? _gamesRecord;
  bool _hasStreamError = false;
  Object? _streamError;

  // Tracking by cache key (not gameId) since roster changes affect key
  String? _loadedGroupVibeCacheKey;
  String? _loadedRequestGameId;
  bool _hasTriggeredAnimation = false;

  @override
  void initState() {
    super.initState();
    _initGameSubscription();
  }

  @override
  void didUpdateWidget(JoinGameDetailedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If gameRef changed, cancel old subscription and reinitialize
    if (widget.gameRef?.id != oldWidget.gameRef?.id) {
      _gameSubscription?.cancel();

      // Reset all tracking state
      _loadedGroupVibeCacheKey = null;
      _loadedRequestGameId = null;
      _hasTriggeredAnimation = false;

      // Reset UI state for new game
      _existingRequest = null;
      _isCheckingRequest = true;
      _hasShownAccessDeniedDialog = false;

      // Reset stream state
      _gamesRecord = null;
      _hasStreamError = false;
      _streamError = null;

      _initGameSubscription();
    }
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    super.dispose();
  }

  void _initGameSubscription() {
    final gameRef = widget.gameRef;
    if (gameRef == null) return;

    final gameStream = context.read<GameProvider>().watchGame(gameRef.id);
    _gameSubscription = gameStream.listen(
      _onGameDataReceived,
      onError: (Object error) {
        AppLog.d('❌ JoinGameDetailed stream error: $error');
        if (!mounted) return;

        updateState(this, () {
          _hasStreamError = true;
          _streamError = error;
        });

        // Handle permission-denied (friends-only game) with one-shot dialog
        if (FirebaseErrorUtils.isPermissionDenied(error) &&
            !_hasShownAccessDeniedDialog) {
          _hasShownAccessDeniedDialog = true;
          _logAccessDeniedOnce(widget.gameRef?.id ?? 'unknown', error);
          _showFriendsOnlyDialogAndPop(context);
        }
      },
    );
  }

  void _onGameDataReceived(GamesRecord? gamesRecord) {
    if (!mounted) return;

    // Store the record and clear error state, trigger rebuild
    updateState(this, () {
      _gamesRecord = gamesRecord;
      _hasStreamError = false;
      _streamError = null;
    });

    if (gamesRecord == null) return;

    final currentUserRef = currentUserReference;
    final currentUserId = currentUserRef?.id;
    final game = Game.fromRecord(gamesRecord);

    // 1. Trigger entrance animation (once per widget lifetime)
    if (!_hasTriggeredAnimation) {
      _hasTriggeredAnimation = true;
      updateState(this, () => _hasAnimated = true);
    }

    // 2. Check for existing join request (once per gameId)
    if (currentUserId != null && _loadedRequestGameId != game.reference.id) {
      _loadedRequestGameId = game.reference.id;
      _loadExistingRequest(game.reference.id, currentUserId);
    }

    // 3. Load group vibe data (once per cache key — includes roster)
    if (currentUserId != null) {
      _loadGroupVibeIfNeeded(game, currentUserId);
    }
  }

  void _loadGroupVibeIfNeeded(Game game, String currentUserId) {
    final groupVibeProvider = context.read<GroupVibeProvider>();

    final cacheKey = groupVibeProvider.buildGameCacheKey(
      gameRecord: game,
      currentUserId: currentUserId,
    );

    // Skip if already loaded this cache key or provider says no load needed
    if (_loadedGroupVibeCacheKey == cacheKey) return;
    if (!groupVibeProvider.shouldLoad(cacheKey)) return;

    _loadedGroupVibeCacheKey = cacheKey;
    _loadGroupVibeData(game, currentUserId, cacheKey);
  }

  Future<void> _loadGroupVibeData(
    Game game,
    String currentUserId,
    String cacheKey,
  ) async {
    if (!mounted) return;

    final groupVibeProvider = context.read<GroupVibeProvider>();
    final memberIds = groupVibeProvider.otherMemberIdsForGame(
      gameRecord: game,
      currentUserId: currentUserId,
    );

    await groupVibeProvider.ensureGroupVibeMatch(
      cacheKey: cacheKey,
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
    );
  }

  Future<void> _loadExistingRequest(String gameId, String userId) async {
    if (!mounted) return;

    try {
      final request = await _controller.loadExistingRequest(
        joinRequestProvider: context.read<JoinRequestProvider>(),
        gameId: gameId,
        userId: userId,
      );

      if (mounted) {
        updateState(this, () {
          _existingRequest = request;
          _isCheckingRequest = false;
        });
      }
    } catch (e) {
      AppLog.d('❌ JoinGameDetailed._loadExistingRequest error: $e');
      if (mounted) {
        updateState(this, () => _isCheckingRequest = false);
      }
    }
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
      profileProvider: context.read<ProfileProvider>(),
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

      if (!mounted) return;

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

    // Handle stream error state (permission denied for friends-only, etc.)
    // Note: Permission-denied dialog is triggered from onError handler, not here
    if (_hasStreamError) {
      final error = _streamError;
      // For permission-denied, return empty while dialog pops the screen
      if (error != null && FirebaseErrorUtils.isPermissionDenied(error)) {
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
    final gamesRecord = _gamesRecord;
    if (gamesRecord == null) {
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
  }

  Widget _buildGameContent({
    required BuildContext context,
    required GamesRecord gamesRecord,
    required DocumentReference? currentUserRef,
  }) {
    final game = Game.fromRecord(gamesRecord);
    final currentUserId = currentUserRef?.id;

    // Build cache key for GroupVibe selectors (pure function, no reactivity)
    final groupVibeCacheKey = currentUserId == null
        ? null
        : context.read<GroupVibeProvider>().buildGameCacheKey(
            gameRecord: game,
            currentUserId: currentUserId,
          );

    // PURE BUILD: Side effects handled via stream subscription in _onGameDataReceived()
    // GroupVibe selects moved into GroupVibeSummarySelector and PlayerListSectionSelector

    final isCancelled = game.isCancelledStatus;

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
                        child: GroupVibeSummarySelector(
                          groupVibeCacheKey: groupVibeCacheKey,
                          onViewBreakdown: (result) =>
                              GroupVibeBreakdownSheet.show(
                            context: context,
                            result: result,
                          ),
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
                    PlayerListSectionSelector(
                      game: game,
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
}
