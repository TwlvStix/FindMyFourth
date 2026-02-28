import '/backend/backend.dart';
import '/backend/schema/trust_profile.dart';
import '/core/content/app_copy.dart';
import '/core/exceptions/app_exceptions.dart';
import '/core/motion/motion_helpers.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/trust/luxury_player_card.dart';
import '/core/widgets/vibe_floor_bottom_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/main_function/game_joined_detailed/components/player_match_chip.dart';
import '/main_function/game_joined_detailed/components/group_vibe_summary.dart';
import '/main_function/game_joined_detailed/components/premium_app_bar.dart';
import '/core/widgets/trust/restriction_banner.dart';
import '/core/widgets/cancelled_game_banner.dart';
import '/core/widgets/game_details_section.dart';
import '/core/widgets/premium_section_header.dart';
import '/utils/app_util.dart';
import '/core/utils/firebase_error_utils.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_icon.dart';
import '/providers/trust_provider.dart';
import '/providers/user_provider.dart';
import '/models/game.dart';
import '/models/join_game_result.dart';
import '/models/join_request.dart';
import '/models/player_eligibility.dart';
import '/models/vibe_profile.dart';
import '/services/game_eligibility_service.dart';
import '/vibe/vibe_recommendation_rank.dart';
import '/providers/provider_extensions.dart';
import '/providers/game_provider.dart';
import '/providers/profile_provider.dart';
import '/providers/join_request_provider.dart';
import '/main_function/game_joined_detailed/game_joined_detailed_widget.dart';
import '/services/vibe_group_matcher.dart';
import '/services/vibe_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '/providers/chat_provider.dart';
import 'components/game_details_card.dart';
import 'components/host_info_section.dart';
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
  final VibeRepository _vibeRepository = VibeRepository();
  GroupVibeMatchResult? _groupVibeMatch;
  Map<String, GroupVibeMemberResult> _memberMatchesById = {};
  bool _isGroupVibeLoading = false;
  String _groupVibeKey = '';
  bool _hasLoggedAccessDenied = false;
  bool _hasShownAccessDeniedDialog = false;

  // Animation state - triggers once when content loads
  bool _hasAnimated = false;

  // Join request state - tracks existing pending/denied requests
  JoinRequest? _existingRequest;
  bool _isCheckingRequest = true;
  String? _lastCheckedGameId;

  @override
  void initState() {
    super.initState();
    // ✅ PERFORMANCE: Removed empty post-frame setState (no-op rebuild)
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Check for existing join request (pending or denied) on screen load
  void _ensureExistingRequestChecked(String gameId, String userId) {
    // Skip if already checked for this game
    if (_lastCheckedGameId == gameId) return;
    _lastCheckedGameId = gameId;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        final request = await context
            .read<JoinRequestProvider>()
            .getExistingRequestForGame(gameId, userId);

        if (mounted) {
          setState(() {
            _existingRequest = request;
            _isCheckingRequest = false;
          });
        }
      } catch (e) {
        // Silently fail - allow user to try joining
        if (mounted) {
          setState(() => _isCheckingRequest = false);
        }
      }
    });
  }

  /// Get button text based on existing request status
  String _getJoinButtonText() {
    if (_existingRequest?.isPending == true) {
      return AppVibeFloorCopy.requestPendingButton;
    }
    if (_existingRequest?.isDenied == true) {
      return AppVibeFloorCopy.requestDeclinedButton;
    }
    if (_existingRequest?.isExpired == true) {
      return AppVibeFloorCopy.requestExpiredButton;
    }
    return AppVibeFloorCopy.joinRoundButton;
  }

  /// Get button variant based on existing request status
  AppButtonVariant _getJoinButtonVariant() {
    if (_existingRequest != null) return AppButtonVariant.secondary;
    return AppButtonVariant.primary;
  }

  /// Check if join button should be enabled
  bool _isJoinButtonEnabled() {
    return _existingRequest == null && !_isCheckingRequest;
  }

  void _ensureGroupVibeMatch(
    Game gameRecord,
    DocumentReference? currentUserRef,
  ) {
    if (currentUserRef == null) {
      return;
    }
    final groupRefs = _groupMemberRefs(gameRecord);
    final otherIds = groupRefs
        .where((ref) => ref.id != currentUserRef.id)
        .map((ref) => ref.id)
        .toList()
      ..sort();
    final nextKey = '${currentUserRef.id}:${otherIds.join(',')}';
    if (_isGroupVibeLoading || _groupVibeKey == nextKey) {
      return;
    }
    _groupVibeKey = nextKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final profileProvider = context.read<ProfileProvider>();
      _loadGroupVibeMatch(gameRecord, currentUserRef, groupRefs, profileProvider);
    });
  }

  void _logAccessDeniedOnce(String gameId, Object error) {
    if (_hasLoggedAccessDenied) {
      return;
    }
    _hasLoggedAccessDenied = true;
    AppLog.d(
      'JoinGameDetailed: access denied for game $gameId (likely friends-only). Error: $error',
    );
  }

  Future<void> _showFriendsOnlyDialogAndPop(BuildContext context) async {
    if (_hasShownAccessDeniedDialog) {
      return;
    }
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
    if (mounted) {
      context.pop();
    }
  }

  List<DocumentReference> _groupMemberRefs(Game gameRecord) {
    final groupRefs = gameRecord.joinedPlayers.toList();
    final owner = gameRecord.userRef;
    if (owner != null && !groupRefs.contains(owner)) {
      groupRefs.insert(0, owner);
    }
    return groupRefs;
  }

  Future<void> _loadGroupVibeMatch(
    Game gameRecord,
    DocumentReference currentUserRef,
    List<DocumentReference> groupRefs,
    ProfileProvider profileProvider,
  ) async {
    setState(() {
      _isGroupVibeLoading = true;
    });
    try {
      final myVibes = await _vibeRepository.getMyVibesCached();
      final userIds = groupRefs
          .where((ref) => ref.id != currentUserRef.id)
          .map((ref) => ref.id)
          .toList();

      final profileMap = await profileProvider.batchGetProfiles(userIds);
      final members = <GroupVibeMember>[];
      for (final entry in profileMap.entries) {
        final userId = entry.key;
        final userRecord = entry.value;
        final displayName = userRecord.displayName.isNotEmpty
            ? userRecord.displayName
            : 'Player';
        members.add(
          GroupVibeMember(
            id: userId,
            name: displayName,
            profile: VibeProfile.fromFirestore(userRecord.vibeProfile),
          ),
        );
      }

      final result = GroupVibeMatcher.scoreGroup(
        mine: myVibes,
        others: members,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _groupVibeMatch = result;
        _memberMatchesById = {
          for (final memberResult in result.memberResults)
            memberResult.member.id: memberResult,
        };
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _groupVibeMatch = null;
        _memberMatchesById = {};
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isGroupVibeLoading = false;
      });
    }
  }

  void _openGroupVibeBreakdown() {
    final result = _groupVibeMatch;
    if (result == null) {
      return;
    }
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.navyDark,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppBorderRadius.xl),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Group Fit',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.pure,
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    '${result.groupFitScore.round()}%',
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  if (result.conflicts.isNotEmpty) ...[
                    Text(
                      'Potential conflicts',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.pure,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    ...result.conflicts.map(
                      (conflict) => Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          '${VibeLabels.titleFor(conflict.category)} with ${conflict.memberName}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                  ],
                  Text(
                    'Top differences vs group avg',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.pure,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: result.topDifferences.map((difference) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(AppBorderRadius.full),
                          border: Border.all(
                            color: AppColors.navyLight,
                          ),
                        ),
                        child: Text(
                          '${VibeLabels.titleFor(difference.category)} • gap ${difference.distance.toStringAsFixed(1)}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: AppTypography.letterSpacingNormal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (result.softRisks.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.sm),
                    ...result.softRisks.map(
                      (risk) => Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          risk.reason,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Player matches',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.pure,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  ..._sortedMemberResults(result).map((memberResult) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _buildGroupMatchRow(memberResult),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupMatchRow(GroupVibeMemberResult memberResult) {
    final matchScore = memberResult.displayScore.round();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.navyLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              memberResult.member.name,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.pure,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
          Text(
            '$matchScore%',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
    );
  }

  List<GroupVibeMemberResult> _sortedMemberResults(
    GroupVibeMatchResult result,
  ) {
    final sorted = result.memberResults.toList()
      ..sort((a, b) {
        final rankA = recommendationRank(a.matchResult.recommendation);
        final rankB = recommendationRank(b.matchResult.recommendation);
        if (rankA != rankB) {
          return rankA.compareTo(rankB);
        }
        return b.displayScore.compareTo(a.displayScore);
      });
    return sorted;
  }

  // Helper method to get player count
  int _getPlayerCount(Game gameRecord) {
    final joinedCount = gameRecord.joinedPlayers.length;
    final guestCount =
        gameRecord.guestPlayers.where((name) => name.trim().isNotEmpty).length;
    // Include owner if not already in joined players
    final owner = gameRecord.userRef;
    final ownerCount = (owner != null && !gameRecord.joinedPlayers.contains(owner)) ? 1 : 0;
    return joinedCount + guestCount + ownerCount;
  }

  int _compareMemberIds(String aId, String bId) {
    final aMatch = _memberMatchesById[aId];
    final bMatch = _memberMatchesById[bId];
    if (aMatch == null && bMatch == null) {
      return 0;
    }
    if (aMatch == null) {
      return 1;
    }
    if (bMatch == null) {
      return -1;
    }
    final rankA = recommendationRank(aMatch.matchResult.recommendation);
    final rankB = recommendationRank(bMatch.matchResult.recommendation);
    if (rankA != rankB) {
      return rankA.compareTo(rankB);
    }
    return bMatch.displayScore.compareTo(aMatch.displayScore);
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
                    color: AppColors.glassTextTertiary,
                    size: AppIconSize.xl,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Game Unavailable',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'This game is no longer available',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.glassTextSecondary,
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
          final error = snapshot.error!;
          if (FirebaseErrorUtils.isPermissionDenied(error)) {
            _logAccessDeniedOnce(gameRef.id, error);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showFriendsOnlyDialogAndPop(context);
              }
            });
            return SizedBox.shrink();
          }
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
                        color: AppColors.glassTextTertiary,
                        size: AppIconSize.xl,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Unable to load game',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Please try again later.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.glassTextSecondary,
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
                      color: AppColors.gold,
                      size: 50.0,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Loading game details...',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.glassTextSecondary,
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
        final joinGameDetailedGamesRecord = Game.fromRecord(gamesRecord);
        final isCancelled = joinGameDetailedGamesRecord.isCancelledStatus;
        _ensureGroupVibeMatch(joinGameDetailedGamesRecord, currentUserRef);

        // Check for existing join request (pending/denied)
        if (currentUserRef != null) {
          _ensureExistingRequestChecked(
            joinGameDetailedGamesRecord.reference.id,
            currentUserRef.id,
          );
        }

        // Trigger entrance animation once when content first loads
        if (!_hasAnimated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasAnimated) {
              setState(() => _hasAnimated = true);
            }
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
                final isCreatorFriend = currentUserRecord?.friends.contains(
                      joinGameDetailedGamesRecord.userRef,
                    ) ??
                    false;

                return SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top padding for AppBar
                      SizedBox(height: MediaQuery.of(context).padding.top + 22),

                      // Premium Hero Section
                      Padding(
                        padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                        child: joinGameDetailedGamesRecord.userRef == null
                          ? Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: AppColors.navy.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
                              ),
                              child: Center(
                                child: Text(
                                  'Host information unavailable',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.glassTextSecondary,
                                  ),
                                ),
                              ),
                            )
                          : StreamBuilder<UsersRecord>(
                          stream: UsersRecord.getDocument(
                            joinGameDetailedGamesRecord.userRef!,
                          ),
                          builder: (context, hostSnapshot) {
                            // Handle error state - show fallback UI instead of infinite loading
                            if (hostSnapshot.hasError) {
                              AppLog.d('JoinGameDetailed: Host data error: ${hostSnapshot.error}');
                              return Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: AppColors.navy.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AppIcon(
                                        icon: AppPhosphorIcons.profile,
                                        color: AppColors.glassTextTertiary,
                                        size: AppIconSize.xl,
                                      ),
                                      SizedBox(height: AppSpacing.sm),
                                      Text(
                                        'Host information unavailable',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.glassTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            // Show loading only while waiting for data
                            if (!hostSnapshot.hasData) {
                              return Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: AppColors.navy.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
                                ),
                                child: Center(
                                  child: SpinKitWanderingCubes(
                                    color: AppColors.gold,
                                    size: 30.0,
                                  ),
                                ),
                              );
                            }
                            return Container(
                              padding: EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.navy.withValues(alpha: 0.4),
                                    AppColors.navyDark.withValues(alpha: 0.6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                boxShadow: [AppElevation.xl],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GameDetailsCard(game: joinGameDetailedGamesRecord),
                                  SizedBox(height: AppSpacing.lg),
                                  HostInfoSection(hostUser: hostSnapshot.data!),
                                ],
                              ),
                            );
                          },
                        )
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

                      // Quick Stats Row (Date, Players, Spots)
                      // Content section 1 - Staggered reveal
                      _buildAnimatedSection(
                        sectionIndex: 0,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: AvailableGameStatsRow(
                            game: joinGameDetailedGamesRecord,
                          ),
                        ),
                      ),

                      SizedBox(height: AppSpacing.md),

                      // Group Vibe Summary
                      // Content section 2 - Staggered reveal
                      _buildAnimatedSection(
                        sectionIndex: 1,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: GroupVibeSummary(
                            groupVibeMatch: _groupVibeMatch,
                            onViewBreakdown: _openGroupVibeBreakdown,
                          ),
                        ),
                      ),

                      SizedBox(height: AppSpacing.lg),

                      // Game Details Section
                      // Content section 3 - Staggered reveal
                      _buildAnimatedSection(
                        sectionIndex: 2,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Header with gradient accent
                            PremiumSectionHeader(title: 'Game Details'),
                            SizedBox(height: AppSpacing.sm),

                            // Game Details Section
                            GameDetailsSection(game: joinGameDetailedGamesRecord),
                            SizedBox(height: AppSpacing.lg),

                            // Players Section Header with gradient accent
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
                                  '${_getPlayerCount(joinGameDetailedGamesRecord)}/4',
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
                      // Players vertical cards
                      // Content section 4 - Staggered reveal
                      _buildAnimatedSection(
                        sectionIndex: 3,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Builder(
                          builder: (context) {
                            final groupPlayers = joinGameDetailedGamesRecord
                                .joinedPlayers
                                .toList();
                            if (_memberMatchesById.isNotEmpty) {
                              groupPlayers.sort(
                                (a, b) => _compareMemberIds(a.id, b.id),
                              );
                            }
                            final guestPlayers = joinGameDetailedGamesRecord
                                .guestPlayers
                                .where((name) => name.trim().isNotEmpty)
                                .toList();
                            final gameOwner =
                                joinGameDetailedGamesRecord.userRef;
                            if (gameOwner != null &&
                                !groupPlayers.contains(gameOwner)) {
                              groupPlayers.insert(0, gameOwner);
                            }

                            final playerIds = groupPlayers
                                .map((playerRef) => playerRef.id)
                                .toList();
                            final profilesFuture = playerIds.isEmpty
                                ? Future.value(<String, UsersRecord>{})
                                : context
                                    .read<ProfileProvider>()
                                    .batchGetProfiles(playerIds);

                            return FutureBuilder<Map<String, UsersRecord>>(
                              future: profilesFuture,
                              builder: (context, profilesSnapshot) {
                                final profileMap =
                                    profilesSnapshot.data ?? <String, UsersRecord>{};

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Registered players - using LuxuryPlayerCard with trust badges
                                    ...List.generate(groupPlayers.length,
                                        (groupPlayersIndex) {
                                      final groupPlayersItem =
                                          groupPlayers[groupPlayersIndex];
                                      final isOwner = gameOwner != null &&
                                          groupPlayersItem == gameOwner;
                                      final friendRecord =
                                          profileMap[groupPlayersItem.id];
                                      final displayName =
                                          (friendRecord?.displayName ?? '')
                                                  .trim()
                                                  .isNotEmpty
                                              ? friendRecord!.displayName
                                              : 'Golfer';
                                      final userRef = friendRecord?.reference ??
                                          groupPlayersItem;
                                      final photoUrl =
                                          friendRecord?.photoUrl ?? '';

                                      // Fetch trust profile for badge display
                                      final trustProvider = context.read<TrustProvider>();
                                      // Stagger delay: 24ms per card, max 8 cards animated
                                      final staggerIndex = groupPlayersIndex < MotionTokens.staggerMaxItems
                                          ? groupPlayersIndex
                                          : MotionTokens.staggerMaxItems - 1;
                                      final staggerDelay = ReducedMotionService.shouldStagger
                                          ? MotionTokens.staggerDelay * staggerIndex
                                          : Duration.zero;

                                      return FutureBuilder<TrustProfile?>(
                                        future: trustProvider.fetchTrustProfile(groupPlayersItem.id),
                                        builder: (context, trustSnapshot) {
                                          final trustProfile = trustSnapshot.data;
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              top: 8,
                                              bottom: AppSpacing.sm,
                                            ),
                                            child: LuxuryPlayerCard(
                                              name: displayName,
                                              avatarUrl: photoUrl,
                                              tier: trustProfile?.currentBadge ??
                                                  BadgeTier.newPlayer,
                                              isFavorite: isOwner,
                                              status: 'Ready',
                                              percentWidget: PlayerMatchChip(
                                                name: displayName,
                                                memberMatch: _memberMatchesById[
                                                    groupPlayersItem.id],
                                                onTap: null, // Non-member can't view detailed vibe page
                                              ),
                                              trailingWidget: AppIcon(
                                                icon: AppPhosphorIcons.joined,
                                                color: AppColors.textSecondary,
                                                size: AppIconSize.md,
                                              ),
                                              onTap: () {
                                                context.pushNamed(
                                                  'ProfileUser',
                                                  extra: <String, dynamic>{
                                                    'userRef': userRef,
                                                    kTransitionInfoKey:
                                                        TransitionStandards.detailTransition,
                                                  },
                                                );
                                              },
                                            ),
                                          )
                                              .animate(target: _hasAnimated ? 1 : 0)
                                              .fadeIn(
                                                delay: staggerDelay,
                                                duration: ReducedMotionService.adjust(
                                                  MotionTokens.contentReveal,
                                                ),
                                                curve: MotionTokens.curveEnter,
                                              )
                                              .slideY(
                                                delay: staggerDelay,
                                                begin: 0.1,
                                                end: 0,
                                                duration: ReducedMotionService.adjust(
                                                  MotionTokens.contentReveal,
                                                ),
                                                curve: MotionTokens.curveEnter,
                                              );
                                        },
                                      );
                                    }),
                                // Guest players with stagger animation
                                ...guestPlayers.asMap().entries.map((entry) {
                                  final guestIndex = entry.key;
                                  final guestName = entry.value;
                                  // Continue stagger from registered players count
                                  final combinedIndex = groupPlayers.length + guestIndex;
                                  final staggerIndex = combinedIndex < MotionTokens.staggerMaxItems
                                      ? combinedIndex
                                      : MotionTokens.staggerMaxItems - 1;
                                  final staggerDelay = ReducedMotionService.shouldStagger
                                      ? MotionTokens.staggerDelay * staggerIndex
                                      : Duration.zero;

                                  return Padding(
                                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: Container(
                                      padding: EdgeInsets.all(AppSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: AppColors.navy
                                            .withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                        border: Border.all(
                                          color: AppColors.navyLight
                                              .withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Avatar placeholder
                                          Container(
                                            width: 48.0,
                                            height: 48.0,
                                            decoration: BoxDecoration(
                                              color: AppColors.navyLight
                                                  .withValues(alpha: 0.5),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: 0.3),
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'G',
                                                style: AppTypography.titleMedium.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: AppSpacing.sm),
                                          // Name and guest label
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  guestName,
                                                  style: AppTypography.bodyLarge.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: AppSpacing.xxs),
                                                Text(
                                                  'Guest',
                                                  style: AppTypography.bodySmall.copyWith(
                                                    color: Colors.white.withValues(alpha: 0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                      .animate(target: _hasAnimated ? 1 : 0)
                                      .fadeIn(
                                        delay: staggerDelay,
                                        duration: ReducedMotionService.adjust(
                                          MotionTokens.contentReveal,
                                        ),
                                        curve: MotionTokens.curveEnter,
                                      )
                                      .slideY(
                                        delay: staggerDelay,
                                        begin: 0.1,
                                        end: 0,
                                        duration: ReducedMotionService.adjust(
                                          MotionTokens.contentReveal,
                                        ),
                                        curve: MotionTokens.curveEnter,
                                      );
                                }),
                              ],
                            );
                          },
                        );
                      },
                      ),
                        ),
                      ),

                      SizedBox(height: AppSpacing.md),

                      // Cancelled game banner — shown when game is cancelled
                      if (isCancelled)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.md, 0, AppSpacing.md, AppSpacing.md,
                          ),
                          child: const CancelledGameBanner(),
                        ),

                      // Restriction banner — shown above join button when player is restricted
                      if (joinGameDetailedGamesRecord.userRef != currentUserRef && !isCancelled)
                        Consumer<TrustProvider>(
                          builder: (context, trust, _) {
                            final restriction = trust.myStanding?.currentRestriction;
                            if (restriction == null) return const SizedBox.shrink();
                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md,
                              ),
                              child: RestrictionBanner(
                                restriction: restriction,
                                onViewStanding: () => context.pushNamed('YourStanding'),
                              ),
                            );
                          },
                        ),

                      if (joinGameDetailedGamesRecord.userRef != currentUserRef && !isCancelled)
                        Consumer2<TrustProvider, UserProvider>(
                          builder: (context, trust, userProvider, _) {
                            final isRestricted = trust.myStanding?.currentRestriction != null;

                            // Check player eligibility
                            final userGender = userProvider.currentUser?.gender;
                            final eligibilityResult = checkPlayerEligibility(
                              eligibility: joinGameDetailedGamesRecord.playerEligibility,
                              userGender: userGender,
                            );
                            final isIneligible = !eligibilityResult.allowed;
                            final isDisabled = isRestricted || isIneligible;

                            // Build eligibility explanation text
                            String? eligibilityText;
                            if (isIneligible) {
                              eligibilityText = joinGameDetailedGamesRecord.playerEligibility == PlayerEligibility.womenOnly
                                  ? 'This game is open to women only'
                                  : 'This game is open to men only';
                            }

                            // Determine button state based on existing request
                            final buttonEnabled = _isJoinButtonEnabled() && !isDisabled;

                            return Padding(
                          padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppButtonEnhanced(
                                text: _getJoinButtonText(),
                                variant: _getJoinButtonVariant(),
                                size: AppButtonSize.large,
                                fullWidth: true,
                                enabled: buttonEnabled,
                                onPressed: !buttonEnabled ? null : () async {
                                  // Check permission before attempting join
                                  final friendGameValue =
                                      joinGameDetailedGamesRecord.friendGame.trim();
                                  final friendGameLower = friendGameValue.toLowerCase();
                                  final isFriendsOnly = friendGameLower == 'friends';
                                  final isPublic = friendGameLower == 'public';
                                  bool isOwnerFriendsWithUser = isCreatorFriend;
                                  if (isFriendsOnly) {
                                    try {
                                      final ownerRef = joinGameDetailedGamesRecord.userRef;
                                      if (ownerRef != null && currentUserRef != null) {
                                        final ownerSnap = await ownerRef.get();
                                        final ownerData = ownerSnap.data() as Map<String, dynamic>? ?? {};
                                        final ownerFriends = ownerData['friends'];
                                        final currentUserId = currentUserRef.id;
                                        String? normalizeFriendEntry(Object? entry) {
                                          if (entry is DocumentReference) {
                                            return entry.id;
                                          }
                                          if (entry is String) {
                                            if (entry.contains('/')) {
                                              final parts = entry.split('/');
                                              return parts.isNotEmpty ? parts.last : entry;
                                            }
                                            return entry;
                                          }
                                          return null;
                                        }
                                        if (ownerFriends is List) {
                                          isOwnerFriendsWithUser = ownerFriends.any(
                                            (entry) =>
                                                normalizeFriendEntry(entry) == currentUserId,
                                          );
                                        } else {
                                          isOwnerFriendsWithUser = false;
                                        }
                                      }
                                    } catch (error) {
                                      AppLog.d('JoinGameDetailed: owner friend check failed $error');
                                    }
                                  }
                                  if (!(isPublic || (isFriendsOnly && isOwnerFriendsWithUser))) {
                                    await showPremiumDialog(
                                      context: context,
                                      variant: PremiumDialogVariant.informational,
                                      icon: PhosphorIconsRegular.usersThree,
                                      title: 'Friends Only',
                                      body:
                                          'You must be friends with the game creator to join this game.',
                                      actionLabel: 'Got It',
                                    );
                                    return;
                                  }

                                  final currentUser = FirebaseAuth.instance.currentUser;
                                  if (currentUser == null) {
                                    showSnackbar(
                                      context,
                                      'Please sign in to join this game.',
                                    );
                                    return;
                                  }

                                  try {
                                    // Use GameProvider to join with vibe floor check
                                    final ownerId = joinGameDetailedGamesRecord.userRef?.id;
                                    final result = await context.read<GameProvider>().joinGame(
                                          joinGameDetailedGamesRecord.reference.id,
                                          currentUser.uid,
                                          userGender: userGender,
                                          ownerId: ownerId,
                                        );

                                    // Handle vibe floor results
                                    if (result.result == JoinGameResult.requiresApproval) {
                                      if (!mounted) return;

                                      // Fetch owner's first name for personalized copy
                                      String ownerFirstName = 'This player';
                                      final ownerRef = joinGameDetailedGamesRecord.userRef;
                                      if (ownerRef != null) {
                                        try {
                                          final ownerSnap = await ownerRef.get();
                                          final ownerData = ownerSnap.data() as Map<String, dynamic>?;
                                          final firstName = ownerData?['first_name'] as String?;
                                          final displayName = ownerData?['display_name'] as String?;
                                          ownerFirstName = firstName ??
                                              displayName?.split(' ').first ??
                                              'This player';
                                        } catch (e) {
                                          // Use default fallback
                                        }
                                      }

                                      // Get current player's display name for notification
                                      final playerName = context.userProvider.currentUser?.displayName ??
                                          'A player';

                                      // Show vibe floor bottom sheet - returns JoinRequest if submitted
                                      final submittedRequest =
                                          await showAppBottomSheet<JoinRequest?>(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) => VibeFloorBottomSheet(
                                          ownerFirstName: ownerFirstName,
                                          playerName: playerName,
                                          matchResult: result.matchResult!,
                                          ownerProfile: result.ownerProfile!,
                                          playerProfile: result.playerProfile!,
                                          gameId: joinGameDetailedGamesRecord.reference.id,
                                          playerId: currentUser.uid,
                                          ownerId: ownerId!,
                                          vibeScore: result.vibeScore!,
                                          vibeFloor: result.vibeFloor!,
                                        ),
                                      );

                                      // Update button state if request was submitted
                                      if (submittedRequest != null && mounted) {
                                        setState(() {
                                          _existingRequest = submittedRequest;
                                          _isCheckingRequest = false;
                                        });
                                      }
                                      return;
                                    }
                                    if (result.result == JoinGameResult.alreadyRequested) {
                                      if (!mounted) return;
                                      showSnackbar(
                                        context,
                                        'You already have a pending request for this game.',
                                      );
                                      return;
                                    }
                                  } on GameOperationException catch (error) {
                                    if (!mounted) {
                                      return;
                                    }
                                    // Handle specific error codes from transaction
                                    String message;
                                    switch (error.code) {
                                      case 'game-full':
                                        message = 'This game is now full';
                                        break;
                                      case 'already-joined':
                                        message = "You've already joined this game";
                                        break;
                                      case 'transaction-conflict':
                                        message = 'Game updated by another user, please refresh';
                                        break;
                                      case 'game-not-found':
                                        message = 'Game not found';
                                        break;
                                      case 'game-cancelled':
                                        message = 'This game has been cancelled';
                                        break;
                                      case 'gender-restricted':
                                        final restrictionLabel =
                                            joinGameDetailedGamesRecord.playerEligibility ==
                                                    PlayerEligibility.womenOnly
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
                                      default:
                                        message = error.message;
                                    }
                                    showSnackbar(context, message);
                                    return;
                                  } on FirebaseException catch (error) {
                                    if (!mounted) {
                                      return;
                                    }
                                    final friendGameValue =
                                        joinGameDetailedGamesRecord.friendGame.trim();
                                    final friendGameLower = friendGameValue.toLowerCase();
                                    final isFriendsOnly = friendGameLower == 'friends';
                                    final message = error.code == 'permission-denied'
                                        ? (isFriendsOnly && !isOwnerFriendsWithUser
                                            ? 'You must be friends with the game creator to join this game.'
                                            : 'You do not have permission to join this game.')
                                        : 'Unable to join the game right now. Please try again.';
                                    showSnackbar(context, message);
                                    return;
                                  } catch (_) {
                                    if (!mounted) {
                                      return;
                                    }
                                    showSnackbar(
                                      context,
                                      'Unable to join the game right now. Please try again.',
                                    );
                                    return;
                                  }

                                    if (!mounted) {
                                      return;
                                    }
                                    context.gameProvider.invalidateAvailableGamesCache();
                                    context.gameProvider.invalidateUserGamesCache(context.userProvider.userId);
                                    // Invalidate chat caches so memberJoinedAt is refreshed
                                    // (GameProvider._ensureChatMembership uses ChatService directly,
                                    // bypassing ChatProvider cache invalidation)
                                    if (joinGameDetailedGamesRecord.chatRef != null) {
                                      final chatId = joinGameDetailedGamesRecord.chatRef!.id;
                                      context.read<ChatProvider>().invalidateChatCache(chatId);
                                      context.read<ChatProvider>().invalidateMessagesCache(chatId);
                                    }
                                    context.goNamed(
                                      GameJoinedDetailedWidget.routeName,
                                      extra: <String, dynamic>{
                                        'gameRef':
                                            joinGameDetailedGamesRecord.reference,
                                        kTransitionInfoKey: TransitionInfo(
                  hasTransition: true,
                  transitionType: AppTransitionType.fade,
                  enterDuration: Duration(milliseconds: 200),
                  exitDuration: Duration(milliseconds: 170),
                  scaleOnPush: true,
                ),
                                      },
                                    );
                                  },
                                ),
                                // Eligibility explanation text
                                if (eligibilityText != null) ...[
                                  SizedBox(height: AppSpacing.xs),
                                  Text(
                                    eligibilityText,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                // Request declined subtitle
                                if (_existingRequest?.isDenied == true) ...[
                                  SizedBox(height: AppSpacing.xs),
                                  Text(
                                    AppVibeFloorCopy.requestDeclinedSubtitle,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                            ],
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
    },
  );
}


  // ═══════════════════════════════════════════════════════════════════════════
  // PENDING REQUESTS SECTION (OWNER-ONLY)
  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATED SECTION HELPER
  // ═══════════════════════════════════════════════════════════════════════════
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

    return child
        .animate(target: _hasAnimated ? 1 : 0)
        .fadeIn(
          delay: staggerDelay,
          duration: ReducedMotionService.adjust(MotionTokens.contentReveal),
          curve: MotionTokens.curveEnter,
        );
  }

}
