import '/backend/backend.dart';
import '/core/exceptions/app_exceptions.dart';
import '/core/motion/motion_helpers.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/core/widgets/trust/restriction_banner.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/utils/firebase_error_utils.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_icons.dart';
import '/core/widgets/app_icon.dart';
import '/providers/trust_provider.dart';
import '/models/game.dart';
import '/models/vibe_profile.dart';
import '/vibe/vibe_match_types.dart';
import '/vibe/vibe_recommendation_rank.dart';
import '/providers/provider_extensions.dart';
import '/providers/game_provider.dart';
import '/providers/profile_provider.dart';
import '/main_function/game_joined_detailed/game_joined_detailed_widget.dart';
import '/services/vibe_group_matcher.dart';
import '/services/vibe_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '/providers/chat_provider.dart';
import 'components/game_details_card.dart';
import 'components/host_info_section.dart';
import 'components/player_slots_section.dart';
import '../game_joined_detailed/components/quick_stats_row.dart';

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

class _JoinGameDetailedWidgetState extends State<JoinGameDetailedWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final VibeRepository _vibeRepository = VibeRepository();
  GroupVibeMatchResult? _groupVibeMatch;
  Map<String, GroupVibeMemberResult> _memberMatchesById = {};
  bool _isGroupVibeLoading = false;
  String _groupVibeKey = '';
  bool _hasLoggedAccessDenied = false;
  bool _hasShownAccessDeniedDialog = false;

  @override
  void initState() {
    super.initState();
    // ✅ PERFORMANCE: Removed empty post-frame setState (no-op rebuild)
  }

  @override
  void dispose() {
    super.dispose();
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
    debugPrint(
      'JoinGameDetailed: access denied for game $gameId (likely friends-only). Error: $error',
    );
  }

  Widget _buildAccessDeniedScaffold(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildPremiumAppBar(context, 'Game'),
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.fairway.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(
                    assetPath: AppIcons.lock,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 44,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Friends Only Game',
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'This game is visible to friends only. Add the host as a friend to view details.',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.md),
                AppButtonEnhanced(
                  text: 'Go back',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.medium,
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showFriendsOnlyDialogAndPop(BuildContext context) async {
    if (_hasShownAccessDeniedDialog) {
      return;
    }
    _hasShownAccessDeniedDialog = true;
    await showDialog<void>(
      context: context,
      builder: (alertDialogContext) {
        return AlertDialog(
          title: Text('Friends Only Game'),
          content: Text(
            'This game is visible to friends only. Add the host as a friend to view details.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(alertDialogContext),
              child: Text('Ok'),
            ),
          ],
        );
      },
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

  String _stringValue(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return fallback;
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
              color: AppColors.pure,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
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
                        color: AppColors.cloud,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Group Fit',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.onyx,
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    '${result.groupFitScore.round()}%',
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.fairwayDark,
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  if (result.conflicts.isNotEmpty) ...[
                    Text(
                      'Potential conflicts',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.onyx,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    ...result.conflicts.map(
                      (conflict) => Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          '${VibeLabels.titleFor(conflict.category)} with ${conflict.memberName}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.stone,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                  ],
                  Text(
                    'Top differences vs group avg',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.onyx,
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
                          color: AppColors.sand,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.cloud,
                          ),
                        ),
                        child: Text(
                          '${VibeLabels.titleFor(difference.category)} • gap ${difference.distance.toStringAsFixed(1)}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.slate,
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
                            color: AppColors.stone,
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Player matches',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.onyx,
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
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cloud),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              memberResult.member.name,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onyx,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
          Text(
            '$matchScore%',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.fairwayDark,
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

  Widget _buildPlayerMatchChip(String userId, String name) {
    final match = _memberMatchesById[userId];
    final scoreLabel = match == null
        ? '--%'
        : '${match.displayScore.round()}%';
    final label = '$name $scoreLabel';

    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.fairway.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.fairway.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.fairwayDark,
            letterSpacing: AppTypography.letterSpacingNormal,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PREMIUM APP BAR
  // ═══════════════════════════════════════════════════════════════════════════
  PreferredSizeWidget _buildPremiumAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: PremiumBackButton(
        onTap: () {
          final router = GoRouter.of(context);
          router.go('/gamesList');
        },
      ),
      title: Text(
        title,
        style: AppTypography.headlineMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: false,
      elevation: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gameRef == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildPremiumAppBar(context, 'Game'),
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
                    color: AppColors.fairway.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 40,
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
        appBar: _buildPremiumAppBar(context, 'Game'),
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
            appBar: _buildPremiumAppBar(context, 'Game'),
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
                        color: AppColors.fairway.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 40,
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
            appBar: _buildPremiumAppBar(context, 'Loading...'),
            body: FairwayBackgroundDark(
              showOrganic: true,
              showTexture: true,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinKitWanderingCubes(
                      color: AppColors.sunsetGold,
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
            appBar: _buildPremiumAppBar(context, 'Game'),
            body: Center(child: Text('Game not found')),
          );
        }
        final joinGameDetailedGamesRecord = Game.fromRecord(gamesRecord);
        _ensureGroupVibeMatch(joinGameDetailedGamesRecord, currentUserRef);

        return Scaffold(
          key: scaffoldKey,
          extendBodyBehindAppBar: true,
          appBar: _buildPremiumAppBar(context, 'Available Game'),
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
                      SizedBox(height: MediaQuery.of(context).padding.top + 56),

                      // Premium Hero Section
                      Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: joinGameDetailedGamesRecord.userRef == null
                          ? Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: AppColors.fairway.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Text(
                                  'Host information unavailable',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
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
                              debugPrint('JoinGameDetailed: Host data error: ${hostSnapshot.error}');
                              return Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: AppColors.fairway.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person_outline_rounded,
                                        color: Colors.white.withValues(alpha: 0.5),
                                        size: 40,
                                      ),
                                      SizedBox(height: AppSpacing.sm),
                                      Text(
                                        'Host information unavailable',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: Colors.white.withValues(alpha: 0.7),
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
                                  color: AppColors.fairway.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Center(
                                  child: SpinKitWanderingCubes(
                                    color: AppColors.sunsetGold,
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
                                    AppColors.fairway.withValues(alpha: 0.4),
                                    AppColors.fairwayDark.withValues(alpha: 0.6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.fairwayDark.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
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
                      ),

                      // Quick Stats Row (Date, Players, Spots)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: QuickStatsRow(
                          game: joinGameDetailedGamesRecord,
                          isOwner: false, // User is viewing a game to join, not their own game
                        ),
                      ),

                      SizedBox(height: AppSpacing.md),

                      // Group Vibe Summary
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: _buildPremiumGroupVibeSummary(),
                      ),

                      SizedBox(height: AppSpacing.lg),

                      // Game Details Section
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Header with gradient accent
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Game Details',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.sm),

                            // Premium Info Grid
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              crossAxisSpacing: AppSpacing.sm,
                              mainAxisSpacing: AppSpacing.sm,
                              childAspectRatio: 3.0,
                              children: [
                                _buildPremiumInfoCard(
                                  context,
                                  icon: Icons.attach_money_rounded,
                                  iconColors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                                  label: 'Betting',
                                  value: joinGameDetailedGamesRecord.styleGame,
                                ),
                                _buildPremiumInfoCard(
                                  context,
                                  icon: Icons.rule_rounded,
                                  iconColors: [AppColors.fairwayLight, AppColors.fairway],
                                  label: 'Rule Style',
                                  value: joinGameDetailedGamesRecord.rulesSetting,
                                ),
                                _buildPremiumInfoCard(
                                  context,
                                  icon: Icons.sports_golf_rounded,
                                  iconColors: [AppColors.fairwayLight, AppColors.fairway],
                                  label: 'Game Type',
                                  value: joinGameDetailedGamesRecord.gameType,
                                ),
                                _buildPremiumInfoCard(
                                  context,
                                  icon: Icons.scoreboard_rounded,
                                  iconColors: [AppColors.sunsetPeach, AppColors.sunsetRose],
                                  label: 'Scoring',
                                  value: joinGameDetailedGamesRecord.scoring,
                                ),
                                _buildPremiumInfoCard(
                                  context,
                                  svgPath: AppIcons.memberDiscount,
                                  iconColors: [AppColors.fairwayLight, AppColors.fairway],
                                  label: 'Member Discount',
                                  value: joinGameDetailedGamesRecord.memberDiscount,
                                ),
                                _buildPremiumInfoCard(
                                  context,
                                  svgPath: AppIcons.groups,
                                  iconColors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                                  label: 'Friends Only',
                                  value: joinGameDetailedGamesRecord.friendGame,
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.lg),

                            // Players Section Header with gradient accent
                            PlayerSlotsSectionHeader(
                              currentCount: _getPlayerCount(joinGameDetailedGamesRecord),
                              maxCount: 4,
                            ),
                            SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      ),
                      // Players vertical cards
                      Padding(
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
                                    // Registered players
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

                                      return Padding(
                                        padding:
                                            EdgeInsets.only(bottom: AppSpacing.sm),
                                        child: InkWell(
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
                                          child: Container(
                                            padding: EdgeInsets.all(AppSpacing.sm),
                                            decoration: BoxDecoration(
                                              color: AppColors.fairway
                                                  .withValues(alpha: 0.3),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.fairwayLight
                                                    .withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                // Avatar
                                                Container(
                                                  width: 48.0,
                                                  height: 48.0,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [AppColors.fairwayLight, AppColors.fairway],
                                                    ),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: Colors.white.withValues(alpha: 0.2),
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(10),
                                                    child: photoUrl.isNotEmpty
                                                        ? Image.network(
                                                            photoUrl,
                                                            fit: BoxFit.cover,
                                                            cacheWidth: 96,
                                                            cacheHeight: 96,
                                                            errorBuilder: (context, error, stackTrace) =>
                                                                Icon(
                                                              Icons.person_rounded,
                                                              color: Colors.white,
                                                              size: 24,
                                                            ),
                                                          )
                                                        : Icon(
                                                            Icons.person_rounded,
                                                            color: Colors.white,
                                                            size: 24,
                                                          ),
                                                  ),
                                                ),
                                                SizedBox(width: AppSpacing.sm),
                                                // Name and ready status
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Flexible(
                                                            child: Text(
                                                              displayName,
                                                              style: AppTheme.of(context)
                                                                  .bodyLarge
                                                                  .override(
                                                                    font: TextStyle(fontFamily: 'Manrope',
                                                                      fontWeight:
                                                                          FontWeight.w500,
                                                                      fontStyle:
                                                                          AppTheme.of(
                                                                                  context)
                                                                              .bodyLarge
                                                                              .fontStyle,
                                                                    ),
                                                                    color: Colors.white,
                                                                    letterSpacing: 0.0,
                                                                    fontWeight:
                                                                        FontWeight.w500,
                                                                    fontStyle:
                                                                        AppTheme.of(
                                                                                context)
                                                                            .bodyLarge
                                                                            .fontStyle,
                                                                  ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          if (isOwner) ...[
                                                            SizedBox(width: 6),
                                                            AppIcon(
                                                              assetPath: AppIcons.owner,
                                                              color: AppColors.sunsetGold,
                                                              size: 16,
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      SizedBox(height: AppSpacing.xxs),
                                                      Text(
                                                        'Ready',
                                                        style: AppTheme.of(context)
                                                            .bodySmall
                                                            .override(
                                                              font: TextStyle(fontFamily: 'Manrope',
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                                fontStyle:
                                                                    AppTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .fontStyle,
                                                              ),
                                                              color: AppColors
                                                                  .sunsetGold,
                                                              letterSpacing: 0.0,
                                                              fontWeight:
                                                                  FontWeight.normal,
                                                              fontStyle:
                                                                  AppTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontStyle,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    right: AppSpacing.sm,
                                                  ),
                                                  child: _buildPlayerMatchChip(
                                                    groupPlayersItem.id,
                                                    displayName,
                                                  ),
                                                ),
                                                // Checkmark icon
                                                AppIcon(
                                                  assetPath: AppIcons.joined,
                                                  color: AppColors.sunsetGold,
                                                  size: 24.0,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                // Guest players
                                ...guestPlayers.map(
                                  (guestName) => Padding(
                                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: Container(
                                      padding: EdgeInsets.all(AppSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: AppColors.fairway
                                            .withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.fairwayLight
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
                                              color: AppColors.fairwayLight
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
                                                style: AppTheme.of(context)
                                                    .titleMedium
                                                    .override(
                                                      font: TextStyle(fontFamily: 'Manrope',
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle:
                                                            AppTheme.of(context)
                                                                .titleMedium
                                                                .fontStyle,
                                                      ),
                                                      color: Colors.white,
                                                      letterSpacing: 0.0,
                                                      fontWeight: FontWeight.w600,
                                                      fontStyle:
                                                          AppTheme.of(context)
                                                              .titleMedium
                                                              .fontStyle,
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
                                                  style: AppTheme.of(context)
                                                      .bodyLarge
                                                      .override(
                                                        font: TextStyle(fontFamily: 'Manrope',
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontStyle:
                                                              AppTheme.of(context)
                                                                  .bodyLarge
                                                                  .fontStyle,
                                                        ),
                                                        color: Colors.white,
                                                        letterSpacing: 0.0,
                                                        fontWeight: FontWeight.w500,
                                                        fontStyle:
                                                            AppTheme.of(context)
                                                                .bodyLarge
                                                                .fontStyle,
                                                      ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: AppSpacing.xxs),
                                                Text(
                                                  'Guest',
                                                  style: AppTheme.of(context)
                                                      .bodySmall
                                                      .override(
                                                        font: TextStyle(fontFamily: 'Manrope',
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              AppTheme.of(context)
                                                                  .bodySmall
                                                                  .fontStyle,
                                                        ),
                                                        color: Colors.white
                                                            .withValues(alpha: 0.7),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            AppTheme.of(context)
                                                                .bodySmall
                                                                .fontStyle,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      ),
                    ),

                      SizedBox(height: AppSpacing.md),

                      // Restriction banner — shown above join button when player is restricted
                      if (joinGameDetailedGamesRecord.userRef != currentUserRef)
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

                      if (joinGameDetailedGamesRecord.userRef != currentUserRef)
                        Consumer<TrustProvider>(
                          builder: (context, trust, _) {
                            final isRestricted = trust.myStanding?.currentRestriction != null;
                            return Align(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Padding(
                            padding: EdgeInsets.only(
                                bottom: AppSpacing.xs),
                            child: SizedBox(
                              width: 300.0,
                              child: AppButtonEnhanced(
                                text: 'Join Game',
                                variant: AppButtonVariant.primary,
                                size: AppButtonSize.large,
                                enabled: !isRestricted,
                                onPressed: isRestricted ? null : () async {
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
                                      debugPrint('JoinGameDetailed: owner friend check failed $error');
                                    }
                                  }
                                  if (!(isPublic || (isFriendsOnly && isOwnerFriendsWithUser))) {
                                    await showAppDialog(
                                      context: context,
                                      builder: (alertDialogContext) {
                                        return AlertDialog(
                                          title: Text('Sorry!'),
                                          content: Text(
                                            'You must be friends with the game creator to join this game.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(alertDialogContext),
                                              child: Text('Ok'),
                                            ),
                                          ],
                                        );
                                      },
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
                                    // Use GameProvider to join and invalidate caches
                                    await context.read<GameProvider>().joinGame(
                                          joinGameDetailedGamesRecord.reference.id,
                                          currentUser.uid,
                                        );
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

                                    if (joinGameDetailedGamesRecord.chatRef !=
                                        null) {
                                      try {
                                        await context
                                            .read<ChatProvider>()
                                            .addMember(
                                              chatId: joinGameDetailedGamesRecord
                                                  .chatRef!
                                                  .id,
                                              uid: currentUser.uid,
                                            );
                                      } on FirebaseException {
                                        if (mounted) {
                                          showSnackbar(
                                            context,
                                            'Joined the game, but chat access is unavailable right now.',
                                          );
                                        }
                                      } catch (error) {
                                        if (mounted) {
                                          showSnackbar(
                                            context,
                                            'Joined the game, but chat access is unavailable right now.',
                                          );
                                        }
                                      }
                                    }

                                    if (!mounted) {
                                      return;
                                    }
                                    context.userProvider.refreshAvailableGames();
                                    context.userProvider.refreshMyGames();
                                    context.goNamed(
                                      GameJoinedDetailedWidget.routeName,
                                      extra: <String, dynamic>{
                                        'gameRef':
                                            joinGameDetailedGamesRecord.reference,
                                        kTransitionInfoKey: TransitionInfo(
                  hasTransition: true,
                  transitionType: PageTransitionType.fade,
                  enterDuration: Duration(milliseconds: 200),
                  exitDuration: Duration(milliseconds: 170),
                  scaleOnPush: true,
                ),
                                      },
                                    );
                                  },
                                ),
                              ),
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
  // PREMIUM GROUP VIBE SUMMARY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPremiumGroupVibeSummary() {
    final result = _groupVibeMatch;
    final groupScore = result?.groupFitScore.round() ?? 0;
    final hasResult = result != null;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.fairway.withValues(alpha: 0.4),
            AppColors.fairwayDark.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Group Vibe Match',
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      hasResult ? 'Based on your preferences' : 'Calculating...',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Score badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  gradient: hasResult
                      ? LinearGradient(
                          colors: groupScore >= 70
                              ? [AppColors.fairwayLight, AppColors.fairway]
                              : groupScore >= 40
                                  ? [AppColors.sunsetGold, AppColors.sunsetPeach]
                                  : [AppColors.sunsetRose, AppColors.error],
                        )
                      : null,
                  color: hasResult ? null : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: hasResult
                    ? Text(
                        '$groupScore%',
                        style: AppTypography.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.sunsetGold,
                        ),
                      ),
              ),
            ],
          ),
          if (hasResult) ...[
            // Cohesion warning banner
            if (result.hasCohesionIssue && result.cohesionWarning != null) ...[
              SizedBox(height: AppSpacing.sm),
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.sunsetRose.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.sunsetRose.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        result.cohesionWarning!,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: _openGroupVibeBreakdown,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      color: AppColors.sunsetGold,
                      size: 18,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      'View Detailed Breakdown',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PREMIUM INFO CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPremiumInfoCard(
    BuildContext context, {
    IconData? icon,
    String? svgPath,
    required List<Color> iconColors,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.fairway.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: iconColors),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: iconColors.first.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: svgPath != null
                ? AppIcon(assetPath: svgPath, color: Colors.white, size: 18)
                : Icon(icon, color: Colors.white, size: 18),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '--',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
