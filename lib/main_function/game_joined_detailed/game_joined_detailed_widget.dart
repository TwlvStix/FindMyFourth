import 'dart:async';

import '/backend/backend.dart';
import '/core/content/app_copy.dart';
import '/core/exceptions/app_exceptions.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/fairway_background.dart';
import 'components/pending_requests_section.dart';
import 'components/player_list_section.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/models/join_request.dart';
import '/utils/app_util.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/providers/join_request_provider.dart';
import '/providers/provider_extensions.dart';
import '/providers/game_provider.dart';
import '/providers/profile_provider.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/cancelled_game_banner.dart';
import '/core/widgets/game_details_section.dart';
import '/core/widgets/premium_section_header.dart';
import '/main_function/games_joined/games_joined_widget.dart';
import '/main_function/games_list/games_list_widget.dart';
import '/main_function/player_list/player_list_widget.dart';
import '/models/game.dart';
import '/models/vibe_profile.dart';
import '/services/vibe_group_matcher.dart';
import '/services/vibe_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '/providers/chat_provider.dart';
import '/services/vibe_match_explanation.dart';
import '/services/vibe_matcher.dart';
import '/utils/vibe_archetypes.dart';
import '/vibe/premium_vibe_page/premium_vibe_page_data.dart';
import '/core/widgets/vibe/group_vibe_breakdown_sheet.dart';
import 'components/premium_app_bar.dart';
import 'components/premium_hero_section.dart';
import 'components/quick_stats_row.dart';
import 'components/group_vibe_summary.dart';
import 'components/firm_it_up_banner.dart';
import 'components/firm_it_up_bottom_sheet.dart';
import 'components/edit_game_details_bottom_sheet.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/screens/trust/cancellation_warning_modal.dart';

const int _cancelledChatArchiveDays = 3;

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

  // Animation state - triggers once when content loads
  bool _hasAnimated = false;

  // Owner-facing: pending join requests for this game
  List<JoinRequest> _pendingRequests = [];
  bool _isLoadingPendingRequests = false;
  String? _lastLoadedPendingGameId;
  // Cache owner's vibe profile for all request cards
  VibeProfile? _ownerVibeProfile;
  // Track which request is currently expanded (accordion pattern)
  String? _expandedRequestId;

  @override
  void initState() {
    super.initState();
    // ✅ PERFORMANCE: Removed empty post-frame setState (no-op rebuild)
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PENDING REQUESTS (OWNER VIEW)
  // ═══════════════════════════════════════════════════════════════════════════

  void _ensurePendingRequestsLoaded(String gameId, String ownerId) {
    // Skip if already loaded for this game
    if (_lastLoadedPendingGameId == gameId || _isLoadingPendingRequests) {
      return;
    }
    _lastLoadedPendingGameId = gameId;
    _isLoadingPendingRequests = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        // Load pending requests and owner's vibe profile in parallel
        final results = await Future.wait([
          context
              .read<JoinRequestProvider>()
              .getPendingRequestsForGame(gameId, ownerId),
          _vibeRepository.getVibeProfileForUser(ownerId),
        ]);

        if (mounted) {
          final requests = results[0] as List<JoinRequest>;
          // Sort by createdAt ascending (oldest first)
          requests.sort((a, b) => a.createdAt.compareTo(b.createdAt));

          setState(() {
            _pendingRequests = requests;
            _ownerVibeProfile = results[1] as VibeProfile;
            _isLoadingPendingRequests = false;
            // Auto-expand first request
            if (_pendingRequests.isNotEmpty) {
              _expandedRequestId = _pendingRequests.first.id;
            }
          });
          AppLog.d(
              '📖 Loaded ${_pendingRequests.length} pending join requests');
        }
      } catch (e) {
        AppLog.d('❌ Error loading pending join requests: $e');
        // Silently fail - owner can still view the game
        if (mounted) {
          setState(() => _isLoadingPendingRequests = false);
        }
      }
    });
  }

  /// Handle approve action for a join request
  Future<void> _handleApproveRequest(
      JoinRequest request, String? chatId) async {
    try {
      await context.read<JoinRequestProvider>().approveJoinRequest(
            gameId: request.gameId,
            requestId: request.id,
            requesterId: request.requesterId,
            chatId: chatId,
          );

      // Refresh game data to show new player
      if (mounted) {
        context.gameProvider.invalidateAvailableGamesCache();
      }
    } on GameOperationException catch (e) {
      if (e.code == 'game-full' && mounted) {
        showSnackbar(context, AppVibeFloorCopy.roundFullError);
        // Notify player the round filled
        context.read<JoinRequestProvider>().notifyRoundFilledBeforeApproval(
              request.gameId,
              request.requesterId,
            );
      }
    } catch (e) {
      if (mounted) {
        showSnackbar(context, 'Failed to approve request. Please try again.');
      }
    }
  }

  /// Handle decline action for a join request
  Future<void> _handleDeclineRequest(JoinRequest request) async {
    try {
      await context.read<JoinRequestProvider>().declineJoinRequest(
            gameId: request.gameId,
            requestId: request.id,
            requesterId: request.requesterId,
          );
    } catch (e) {
      if (mounted) {
        showSnackbar(context, 'Failed to decline request. Please try again.');
      }
    }
  }

  void _removeRequestFromList(String requestId) {
    if (!mounted) return;

    setState(() {
      _pendingRequests.removeWhere((r) => r.id == requestId);

      // Auto-expand next request if the removed one was expanded
      if (_expandedRequestId == requestId) {
        if (_pendingRequests.isNotEmpty) {
          // Requests are already sorted by createdAt, expand first remaining
          _expandedRequestId = _pendingRequests.first.id;
        } else {
          _expandedRequestId = null;
        }
      }
    });
  }

  /// Switch to expand a different request (accordion behavior)
  void _expandRequest(String requestId) {
    if (_expandedRequestId != requestId) {
      setState(() {
        _expandedRequestId = requestId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gameRef == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const PremiumAppBar(title: 'Game'),
        body: FairwayBackgroundDark(
          showOrganic: true,
          showTexture: true,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(
                    icon: AppPhosphorIcons.error,
                    color: AppColors.pure.withValues(alpha: 0.5),
                    size: AppIconSize.xl,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Game Unavailable',
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'This game is no longer available',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserRef = currentUser == null
        ? null
        : FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

    // Early return if gameRef is null (defensive programming)
    final gameRef = widget.gameRef;
    if (gameRef == null) {
      return Scaffold(
        appBar: const PremiumAppBar(title: 'Game'),
        body: Center(child: Text('Game not found')),
      );
    }

    return StreamBuilder<GamesRecord?>(
      stream: context.read<GameProvider>().watchGame(gameRef.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: const PremiumAppBar(title: 'Game'),
            body: FairwayBackgroundDark(
              showOrganic: true,
              showTexture: true,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.navy.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: AppIcon(
                        icon: AppPhosphorIcons.error,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: AppIconSize.xl,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Unable to load game',
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Please try again later.',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        // Premium loading state
        if (!snapshot.hasData) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: const PremiumAppBar(title: 'Loading...'),
            body: FairwayBackgroundDark(
              showOrganic: true,
              showTexture: true,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinKitWanderingCubes(
                      color: AppColors.green,
                      size: 50.0,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Loading game details...',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final gamesRecord = snapshot.data;
        if (gamesRecord == null) {
          return Scaffold(
            appBar: const PremiumAppBar(title: 'Game'),
            body: Center(child: Text('Game not found')),
          );
        }
        final gameJoinedDetailedGamesRecord = Game.fromRecord(gamesRecord);
        final groupVibeProvider = context.watchGroupVibeProvider;
        final currentUserId = currentUserRef?.id;
        final groupVibeCacheKey = currentUserId == null
            ? null
            : groupVibeProvider.buildGameCacheKey(
                gameRecord: gameJoinedDetailedGamesRecord,
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
            gameRecord: gameJoinedDetailedGamesRecord,
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
                  final profileMap = await context
                      .read<ProfileProvider>()
                      .batchGetProfiles(userIds);
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
        final isCancelled = gameJoinedDetailedGamesRecord.isCancelledStatus;

        // Load pending join requests if user is the game owner
        if (gameJoinedDetailedGamesRecord.userRef == currentUserRef &&
            currentUserRef != null) {
          _ensurePendingRequestsLoaded(
            gameJoinedDetailedGamesRecord.reference.id,
            currentUserRef.id,
          );
        }

        // Trigger entrance animations once when content first loads
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
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top padding for AppBar
                    SizedBox(height: MediaQuery.of(context).padding.top + 56),

                    // Premium Hero Section - Fade + Scale entrance
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: PremiumHeroSection(
                        game: gameJoinedDetailedGamesRecord,
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

                    // Firm It Up Banner (only for flexible games created by current user)
                    // Content section 1 - Staggered reveal
                    if (gameJoinedDetailedGamesRecord.scheduleType ==
                            'flexible' &&
                        FirebaseAuth.instance.currentUser != null &&
                        gameJoinedDetailedGamesRecord.userRef ==
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid))
                      _buildAnimatedSection(
                        sectionIndex: 0,
                        child: FirmItUpBanner(
                          onPressed: () async {
                            final result = await showModalBottomSheet<
                                Map<String, dynamic>?>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => FirmItUpBottomSheet(
                                gameRef:
                                    gameJoinedDetailedGamesRecord.reference,
                              ),
                            );

                            if (result != null && mounted) {
                              // Show loading indicator
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
                                AppLog.d(
                                    '🎯 Firm It Up: Updating via GameProvider...');
                                AppLog.d(
                                    '🎯 Game ref path: ${gameJoinedDetailedGamesRecord.reference.path}');

                                // Build update map
                                final updateData = <String, dynamic>{
                                  'schedule_type': 'confirmed',
                                  'date': result['date'],
                                  'course_play': result['course'],
                                  'courseRef': result['courseRef'],
                                  'flexible_week': null,
                                  'flexible_days': null,
                                  'flexible_time_of_day': null,
                                };

                                AppLog.d('🎯 Update data: $updateData');
                                // Use GameProvider instead of direct Firestore
                                await context.gameProvider.updateGame(
                                  gameJoinedDetailedGamesRecord.reference.id,
                                  updateData,
                                );

                                AppLog.d('✅ Firm It Up: Update successful');

                                // Close loading dialog
                                if (mounted) Navigator.pop(context);

                                // Show success message
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Tee time confirmed!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e, stackTrace) {
                                AppLog.d('❌ Firm It Up: Error occurred');
                                AppLog.d('❌ Error: $e');
                                AppLog.d('❌ Stack trace: $stackTrace');

                                // Close loading dialog
                                if (mounted) Navigator.pop(context);

                                // Show error message
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Failed to confirm tee time: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),

                    // Quick Stats Row (Date, Players, Chat)
                    // Content section 2 - Staggered reveal
                    _buildAnimatedSection(
                      sectionIndex: 1,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: QuickStatsRow(
                          game: gameJoinedDetailedGamesRecord,
                          isOwner: gameJoinedDetailedGamesRecord.userRef ==
                              currentUserRef,
                          onEditPressed:
                              gameJoinedDetailedGamesRecord.userRef ==
                                      currentUserRef
                                  ? () => _handleEditGameDetails(
                                      context, gameJoinedDetailedGamesRecord)
                                  : null,
                        ),
                      ),
                    ),

                    SizedBox(height: AppSpacing.md),

                    // Premium Message Group Button
                    // Content section 3 - Staggered reveal
                    if (gameJoinedDetailedGamesRecord.chatRef != null)
                      _buildAnimatedSection(
                        sectionIndex: 2,
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: GestureDetector(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              final chatRef =
                                  gameJoinedDetailedGamesRecord.chatRef;
                              if (chatRef == null) {
                                return;
                              }
                              final currentUser =
                                  FirebaseAuth.instance.currentUser;
                              if (currentUser == null) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Please sign in to open the chat.',
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }
                              final currentUserRef = FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser.uid);
                              final isMember = gameJoinedDetailedGamesRecord
                                  .joinedPlayers
                                  .any((player) =>
                                      player.id == currentUserRef.id);
                              if (!isMember) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Join the game to access the group chat.',
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }
                              if (!mounted) {
                                return;
                              }
                              context.pushNamed(
                                'ChatDetails',
                                pathParameters: {'chatId': chatRef.id},
                                extra: <String, dynamic>{
                                  kTransitionInfoKey:
                                      TransitionStandards.detailTransition,
                                },
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.green,
                                    AppColors.greenLight
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius.circular(AppBorderRadius.lg),
                                boxShadow: [AppElevation.glowGreen],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AppIcon(
                                      icon: AppPhosphorIcons.chat,
                                      color: AppColors.pure,
                                      size: AppIconSize.md),
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

                    // Group Vibe Summary
                    // Content section 4 - Staggered reveal
                    _buildAnimatedSection(
                      sectionIndex: 3,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: GroupVibeSummary(
                          groupVibeMatch: groupVibeMatch,
                          onViewBreakdown: () {
                            if (groupVibeMatch == null) {
                              return;
                            }
                            GroupVibeBreakdownSheet.show(
                              context: context,
                              result: groupVibeMatch,
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: AppSpacing.xl),

                    // Game Details Section
                    // Content section 5 - Staggered reveal
                    _buildAnimatedSection(
                      sectionIndex: 4,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Header with gradient accent
                            PremiumSectionHeader(title: 'Game Details'),
                            SizedBox(height: AppSpacing.sm),

                            // Game Details Section
                            GameDetailsSection(
                                game: gameJoinedDetailedGamesRecord),
                            SizedBox(height: AppSpacing.lg),

                            // Pending requests section (owner only)
                            if (gameJoinedDetailedGamesRecord.userRef ==
                                    currentUserRef &&
                                _pendingRequests.isNotEmpty &&
                                _ownerVibeProfile != null)
                              PendingRequestsSection(
                                pendingRequests: _pendingRequests,
                                ownerVibeProfile: _ownerVibeProfile!,
                                expandedRequestId: _expandedRequestId,
                                onApprove: (request) => _handleApproveRequest(
                                  request,
                                  gameJoinedDetailedGamesRecord.chatRef?.id,
                                ),
                                onDecline: _handleDeclineRequest,
                                onRemoved: _removeRequestFromList,
                                onExpandRequest: _expandRequest,
                              ),

                            // Players Section Header with gradient accent
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
                                  '${_getPlayerCount(gameJoinedDetailedGamesRecord)}/4',
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
                    // Players list section (extracted component)
                    PlayerListSection(
                      game: gameJoinedDetailedGamesRecord,
                      memberMatchesById: memberMatchesById,
                      groupVibeCacheKey: groupVibeCacheKey,
                      hasAnimated: _hasAnimated,
                      isOwner: gameJoinedDetailedGamesRecord.userRef ==
                          currentUserRef,
                      onRemovePlayer: ({
                        required String playerName,
                        required DocumentReference? playerRef,
                        required bool isGuest,
                        String? guestName,
                      }) =>
                          _showRemovePlayerDialog(
                        context: context,
                        playerName: playerName,
                        playerRef: playerRef,
                        isGuest: isGuest,
                        guestName: guestName,
                        gameRecord: gameJoinedDetailedGamesRecord,
                      ),
                      onPlayerTap: (userRef) => context.pushNamed(
                        'ProfileUser',
                        extra: <String, dynamic>{
                          'userRef': userRef,
                          kTransitionInfoKey: TransitionStandards.detailTransition,
                        },
                      ),
                      onMatchChipTap: (userRef, displayName, photoUrl, memberMatch) =>
                          _openPremiumVibePage(
                        context,
                        userRef,
                        displayName,
                        photoUrl,
                        memberMatch,
                      ),
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

                    // Add Players button (for owner, when not full, not cancelled)
                    if (gameJoinedDetailedGamesRecord.userRef ==
                            currentUserRef &&
                        _getPlayerCount(gameJoinedDetailedGamesRecord) < 4 &&
                        !isCancelled)
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
                          onPressed: () => _navigateToAddPlayers(context),
                        ),
                      ),
                    if (gameJoinedDetailedGamesRecord.userRef ==
                            currentUserRef &&
                        _getPlayerCount(gameJoinedDetailedGamesRecord) < 4 &&
                        !isCancelled)
                      SizedBox(height: AppSpacing.md),
                    // Leave game button (for non-owner, not cancelled)
                    if (gameJoinedDetailedGamesRecord.userRef !=
                            currentUserRef &&
                        !isCancelled)
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: AppButtonEnhanced(
                          text: 'Leave game',
                          variant: AppButtonVariant.destructiveOutlined,
                          size: AppButtonSize.large,
                          fullWidth: true,
                          onPressed: () async {
                            // Show tier-aware cancellation warning
                            final confirmed =
                                await CancellationWarningModal.show(
                              context,
                              game: gameJoinedDetailedGamesRecord,
                            );
                            if (confirmed != true) return;
                            if (currentUserRef == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Please sign in to leave the game.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }
                            try {
                              // Use GameProvider to leave game (handles Firestore + chat removal)
                              await context.gameProvider.leaveGame(
                                gameRef.id,
                                currentUserRef.id,
                                chatId: gameJoinedDetailedGamesRecord.chatRef?.id,
                              );

                              // Show success toast
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('You left the game'),
                                    backgroundColor: AppColors.success,
                                    duration: Duration(seconds: 2),
                                  ),
                                );

                                // Navigate to Schedule tab (My Games)
                                context.goNamed(GamesJoinedWidget.routeName);
                              }
                            } on FirebaseException catch (error) {
                              if (!mounted) return;
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
                              if (!mounted) return;
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
                    // Cancel game button (for owner, not already cancelled)
                    if (gameJoinedDetailedGamesRecord.userRef ==
                            currentUserRef &&
                        !isCancelled)
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: AppButtonEnhanced(
                          text: 'Cancel game',
                          variant: AppButtonVariant.destructiveOutlined,
                          size: AppButtonSize.large,
                          fullWidth: true,
                          onPressed: () async {
                            if (currentUserRef == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Please sign in to cancel the game.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }
                            final confirmDialogResponse =
                                await showPremiumDialog(
                                      context: context,
                                      variant: PremiumDialogVariant.destructive,
                                      icon: PhosphorIconsRegular.xCircle,
                                      title: 'Cancel Game',
                                      body:
                                          'This will end the game for all players.',
                                      actionLabel: 'Cancel Game',
                                      cancelLabel: 'Keep Game',
                                    ) ??
                                    false;
                            if (!confirmDialogResponse) {
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

                            if (widget.gameRef != null) {
                              AppState().setCancelledGameHandling(
                                gameRef.path,
                                'removeNow',
                              );
                            }

                            try {
                              AppLog.d(
                                'CancelGame: updating via GameProvider ${widget.gameRef?.path}',
                              );
                              // Use GameProvider to cancel game (handles Firestore + cache)
                              await context.gameProvider.cancelGame(gameRef.id);
                              AppLog.d('CancelGame: game cancelled successfully');

                              // Archive chat (send cancel message + set read-only)
                              final currentUserId =
                                  FirebaseAuth.instance.currentUser?.uid;
                              final chatRef =
                                  gameJoinedDetailedGamesRecord.chatRef;
                              if (chatRef != null && currentUserId != null) {
                                final gameName =
                                    gameJoinedDetailedGamesRecord.nameGame;
                                final cancelMessage = gameName.trim().isNotEmpty
                                    ? 'Game "$gameName" has been cancelled.'
                                    : 'This game has been cancelled.';
                                try {
                                  await context
                                      .read<ChatProvider>()
                                      .sendMessage(
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
                                        Duration(
                                            days: _cancelledChatArchiveDays),
                                      ),
                                    ),
                                  });
                                } catch (chatError, stackTrace) {
                                  AppLog.d(
                                    'CancelGame: chat update failed $chatError',
                                  );
                                  AppLog.d(
                                      'CancelGame chat stackTrace: $stackTrace');
                                  // Continue - game cancellation succeeded
                                }
                              }

                              // Show success toast
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Game cancelled successfully'),
                                    backgroundColor: AppColors.success,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                context.gameProvider.invalidateUserGamesCache(
                                    context.userProvider.userId);

                                // Navigate to Games list tab
                                context.goNamed(GamesListWidget.routeName);
                              }
                            } catch (error, stackTrace) {
                              AppLog.d('CancelGame: failed $error');
                              AppLog.d('CancelGame stackTrace: $stackTrace');
                              if (mounted) {
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
            ),
          ),
        );
      },
    );
  }

  /// Builds a content section with staggered fade-in animation.
  ///
  /// Uses MotionTokens.contentReveal (160ms) timing with 24ms stagger delay
  /// per section index. Respects reduced motion preferences.
  Widget _buildAnimatedSection({
    required int sectionIndex,
    required Widget child,
  }) {
    // Calculate stagger delay based on section index (max 8 sections animated)
    final clampedIndex = sectionIndex < MotionTokens.staggerMaxItems
        ? sectionIndex
        : MotionTokens.staggerMaxItems - 1;
    final staggerDelay = ReducedMotionService.shouldStagger
        ? MotionTokens.staggerDelay * clampedIndex
        : Duration.zero;

    return child.animate(target: _hasAnimated ? 1 : 0).fadeIn(
          delay: staggerDelay,
          duration: ReducedMotionService.adjust(MotionTokens.contentReveal),
          curve: MotionTokens.curveEnter,
        );
  }

  Future<void> _openPremiumVibePage(
    BuildContext context,
    DocumentReference userRef,
    String userName,
    String userPhotoUrl,
    GroupVibeMemberResult? memberMatch,
  ) async {
    if (memberMatch == null) return;

    try {
      // Get vibe profiles
      final myVibes = await _vibeRepository.getMyVibesCached();
      final theirVibes = memberMatch.member.profile;

      // Calculate one-on-one match (not group match)
      final result = VibeMatcher.score(myVibes, theirVibes);
      final explanation = buildMatchExplanation(
        matchResult: result,
        a: myVibes,
        b: theirVibes,
      );

      final myArchetype = VibeArchetypes.classifyProfile(myVibes);
      final theirArchetype = VibeArchetypes.classifyProfile(theirVibes);

      final pageData = PremiumVibePageData(
        userId: userRef.id,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        userRef: userRef,
        matchResult: result,
        explanation: explanation,
        myProfile: myVibes,
        theirProfile: theirVibes,
        myArchetype: myArchetype,
        theirArchetype: theirArchetype,
      );

      if (!mounted) return;

      context.pushNamed(
        'PremiumVibePage',
        pathParameters: {
          'userId': userRef.id,
        },
        extra: pageData,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load vibe match. Please try again.'),
        ),
      );
    }
  }

  // Helper method to get player count
  int _getPlayerCount(Game gameRecord) {
    final joinedCount = gameRecord.joinedPlayers.length;
    final guestCount =
        gameRecord.guestPlayers.where((name) => name.trim().isNotEmpty).length;
    return joinedCount + guestCount;
  }

  // Player management helper methods

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

    // Prevent owner from removing themselves
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
      // Use GameProvider to remove player (handles Firestore + chat removal)
      await context.gameProvider.removePlayer(
        gameRef.id,
        playerId: playerRef?.id,
        guestName: guestName,
        isGuest: isGuest,
        chatId: gameRecord.chatRef?.id,
      );

      AppLog.d('Player Management: Removed ${isGuest ? 'guest' : 'player'}: ${isGuest ? guestName : playerRef?.id}');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$playerName removed from game'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error, stackTrace) {
      AppLog.d('Player Management: Remove failed - $error');
      AppLog.d('Player Management stackTrace: $stackTrace');

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

  void _navigateToAddPlayers(BuildContext context) {
    // Navigate to PlayerListWidget with game reference
    // This reuses the exact same flow as game creation
    context.pushNamed(
      PlayerListWidget.routeName,
      extra: <String, dynamic>{
        'gameRef': widget.gameRef,
        kTransitionInfoKey: const TransitionInfo(
          hasTransition: true,
          transitionType: AppTransitionType.fade,
          enterDuration: Duration(milliseconds: 200),
          exitDuration: Duration(milliseconds: 170),
          scaleOnPush: true,
        ),
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Edit Game Details
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _handleEditGameDetails(
    BuildContext context,
    Game gameRecord,
  ) async {
    AppLog.d('🎯 Edit Game Details: Starting edit flow');

    // Validate 2-hour restriction
    final teeTime = gameRecord.date;
    if (teeTime != null) {
      final hoursUntilTeeTime = teeTime.difference(DateTime.now()).inHours;
      AppLog.d('🎯 Hours until tee time: $hoursUntilTeeTime');

      if (hoursUntilTeeTime < 2) {
        AppLog.d('❌ Edit blocked: Less than 2 hours until tee time');
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

    // Show edit bottom sheet
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

    if (result != null && mounted) {
      AppLog.d('🎯 Edit result received: $result');
      await _updateGameDetails(context, gameRecord, result);
    }
  }

  Future<void> _updateGameDetails(
    BuildContext context,
    Game gameRecord,
    Map<String, dynamic> updateData,
  ) async {
    AppLog.d('🎯 Update Game Details: Starting update');

    // Show loading
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
      // Use GameProvider to update (handles Firestore + cache invalidation)
      final firestoreUpdate = <String, dynamic>{
        'date': updateData['date'],
        'course_play': updateData['course'],
        'courseRef': updateData['courseRef'],
      };

      AppLog.d('🎯 Updating via GameProvider: $firestoreUpdate');
      await context.gameProvider.updateGame(gameRecord.reference.id, firestoreUpdate);

      // Send notifications to all players (except owner)
      final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
      final recipients = gameRecord.joinedPlayers
          .where((ref) => ref.id != currentUserUid)
          .toList();

      if (recipients.isNotEmpty) {
        final newDate = updateData['date'] as DateTime;
        final newCourse = updateData['course'] as String;

        final dayName = dateTimeFormat("EEEE", newDate);
        final dateStr = dateTimeFormat("MMM d", newDate);
        final timeStr = dateTimeFormat("jm", newDate);

        final notificationText =
            'Game updated — now $dayName $dateStr, $timeStr at $newCourse';

        AppLog.d('🎯 Sending notifications to ${recipients.length} players');
        AppLog.d('🎯 Notification text: $notificationText');

        triggerPushNotification(
          notificationTitle: 'Game Details Updated',
          notificationText: notificationText,
          userRefs: recipients,
          initialPageName: 'GameJoinedDetailed',
          parameterData: {'gameRef': gameRecord.reference.path},
        );
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Game details updated!'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      AppLog.d('✅ Game details updated successfully');
    } catch (e, stackTrace) {
      AppLog.d('❌ Edit Game Details: Error occurred');
      AppLog.d('❌ Error: $e');
      AppLog.d('❌ Stack trace: $stackTrace');

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update game details: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

}
