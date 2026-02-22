import '/backend/backend.dart';
import '/backend/schema/trust_profile.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/trust/luxury_player_card.dart';
import '/core/motion/motion_helpers.dart';
import '/utils/app_util.dart';
import '/providers/provider_extensions.dart';
import '/providers/game_provider.dart';
import '/providers/profile_provider.dart';
import '/providers/trust_provider.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon_button.dart';
import '/main_function/games_joined/games_joined_widget.dart';
import '/main_function/games_list/games_list_widget.dart';
import '/main_function/player_list/player_list_widget.dart';
import '/models/game.dart';
import '/models/vibe_profile.dart';
import '/vibe/vibe_match_types.dart';
import '/vibe/vibe_recommendation_rank.dart';
import '/services/vibe_group_matcher.dart';
import '/services/vibe_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/providers/chat_provider.dart';
import '/services/vibe_match_explanation.dart';
import '/services/vibe_matcher.dart';
import '/utils/vibe_archetypes.dart';
import '/vibe/premium_vibe_page/premium_vibe_page_data.dart';
import 'components/premium_app_bar.dart';
import 'components/premium_hero_section.dart';
import 'components/quick_stats_row.dart';
import 'components/group_vibe_summary.dart';
import 'components/player_match_chip.dart';
import 'components/firm_it_up_banner.dart';
import 'components/firm_it_up_bottom_sheet.dart';
import 'components/edit_game_details_bottom_sheet.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/screens/trust/cancellation_warning_modal.dart';

enum _CancelListingHandling {
  removeNow,
  hideAfter7Days,
}

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

class _GameJoinedDetailedWidgetState extends State<GameJoinedDetailedWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final VibeRepository _vibeRepository = VibeRepository();
  GroupVibeMatchResult? _groupVibeMatch;
  Map<String, GroupVibeMemberResult> _memberMatchesById = {};
  bool _isGroupVibeLoading = false;
  String _groupVibeKey = '';

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
    final otherIds = gameRecord.joinedPlayers
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
      final groupRefs = _groupMemberRefs(gameRecord);
      _loadGroupVibeMatch(gameRecord, currentUserRef, groupRefs, profileProvider);
    });
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
                  child: Icon(
                    Icons.error_outline_rounded,
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
        _ensureGroupVibeMatch(gameJoinedDetailedGamesRecord, currentUserRef);

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

                    // Premium Hero Section
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: PremiumHeroSection(
                        game: gameJoinedDetailedGamesRecord,
                      ),
                    ),

                    // Firm It Up Banner (only for flexible games created by current user)
                    if (gameJoinedDetailedGamesRecord.scheduleType == 'flexible' &&
                        FirebaseAuth.instance.currentUser != null &&
                        gameJoinedDetailedGamesRecord.userRef ==
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid))
                      FirmItUpBanner(
                        onPressed: () async {
                          final result = await showModalBottomSheet<Map<String, dynamic>?>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => FirmItUpBottomSheet(
                              gameRef: gameJoinedDetailedGamesRecord.reference,
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
                                          color: AppColors.gold,
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
                              debugPrint('🎯 Firm It Up: Updating Firestore...');
                              debugPrint('🎯 Game ref path: ${gameJoinedDetailedGamesRecord.reference.path}');

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

                              debugPrint('🎯 Update data: $updateData');
                              await gameJoinedDetailedGamesRecord.reference.update(updateData);

                              debugPrint('✅ Firm It Up: Update successful');

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
                                // Refresh game data
                                setState(() {});
                              }
                            } catch (e, stackTrace) {
                              debugPrint('❌ Firm It Up: Error occurred');
                              debugPrint('❌ Error: $e');
                              debugPrint('❌ Stack trace: $stackTrace');

                              // Close loading dialog
                              if (mounted) Navigator.pop(context);

                              // Show error message
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to confirm tee time: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),

                    // Quick Stats Row (Date, Players, Chat)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: QuickStatsRow(
                        game: gameJoinedDetailedGamesRecord,
                        isOwner: gameJoinedDetailedGamesRecord.userRef == currentUserRef,
                        onEditPressed: gameJoinedDetailedGamesRecord.userRef == currentUserRef
                            ? () => _handleEditGameDetails(context, gameJoinedDetailedGamesRecord)
                            : null,
                      ),
                    ),

                    SizedBox(height: AppSpacing.md),

                    // Premium Message Group Button
                    if (gameJoinedDetailedGamesRecord.chatRef != null)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: GestureDetector(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            final chatRef = gameJoinedDetailedGamesRecord.chatRef;
                            if (chatRef == null) {
                              return;
                            }
                            final currentUser = FirebaseAuth.instance.currentUser;
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
                                .any((player) => player.id == currentUserRef.id);
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
                                kTransitionInfoKey: TransitionStandards.detailTransition,
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
                                colors: [AppColors.green, AppColors.greenLight],
                              ),
                              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                              boxShadow: [AppElevation.glowGreen],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppIcon(assetPath: AppIcons.chat, color: AppColors.pure, size: AppIconSize.md),
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

                    SizedBox(height: AppSpacing.md),

                    // Group Vibe Summary
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: GroupVibeSummary(
                        groupVibeMatch: _groupVibeMatch,
                        onViewBreakdown: _openGroupVibeBreakdown,
                      ),
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
                                    colors: [AppColors.gold, AppColors.goldLight],
                                  ),
                                  borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
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
                          Builder(builder: (context) {
                            final isFun = gameJoinedDetailedGamesRecord.isFunGame;
                            String funOr(String val) =>
                                isFun && val.isEmpty ? 'Just for Fun' : val;
                            return GridView.count(
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
                                  iconColors: [AppColors.gold, AppColors.goldLight],
                                  label: 'Betting',
                                  value: funOr(gameJoinedDetailedGamesRecord.styleGame),
                                  isFunBadge: isFun && gameJoinedDetailedGamesRecord.styleGame.isEmpty,
                                ),
                                _buildPremiumInfoCard(
                                  context,
                                  icon: Icons.rule_rounded,
                                  iconColors: [AppColors.navyLight, AppColors.navy],
                                  label: 'Rule Style',
                                  value: funOr(gameJoinedDetailedGamesRecord.rulesSetting),
                                  isFunBadge: isFun && gameJoinedDetailedGamesRecord.rulesSetting.isEmpty,
                                ),
                                _buildPremiumInfoCard(
                                  context,
                                  icon: Icons.sports_golf_rounded,
                                  iconColors: [AppColors.navyLight, AppColors.navy],
                                  label: 'Game Type',
                                  value: funOr(gameJoinedDetailedGamesRecord.gameType),
                                  isFunBadge: isFun && gameJoinedDetailedGamesRecord.gameType.isEmpty,
                                ),
                                _buildPremiumInfoCard(
                                  context,
                                  icon: Icons.scoreboard_rounded,
                                  iconColors: [AppColors.goldLight, AppColors.error],
                                  label: 'Scoring',
                                  value: funOr(gameJoinedDetailedGamesRecord.scoring),
                                  isFunBadge: isFun && gameJoinedDetailedGamesRecord.scoring.isEmpty,
                                ),
                                _buildPremiumInfoCard(
                                  context,
                                  icon: Icons.discount_rounded,
                                  iconColors: [AppColors.navyLight, AppColors.navy],
                                  label: 'Member Discount',
                                  value: funOr(gameJoinedDetailedGamesRecord.memberDiscount),
                                  isFunBadge: isFun && gameJoinedDetailedGamesRecord.memberDiscount.isEmpty,
                                ),
                                _buildPremiumInfoCard(
                                  context,
                                  icon: Icons.group_rounded,
                                  iconColors: [AppColors.gold, AppColors.goldLight],
                                  label: 'Friends Only',
                                  value: gameJoinedDetailedGamesRecord.friendGame,
                                ),
                              ],
                            );
                          }),
                          SizedBox(height: AppSpacing.lg),

                          // Players Section Header with gradient accent
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [AppColors.gold, AppColors.goldLight],
                                  ),
                                  borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
                                ),
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Text(
                                'Players',
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                ),
                                child: Text(
                                  '${_getPlayerCount(gameJoinedDetailedGamesRecord)}/4',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                  // Players horizontal cards
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Builder(
                      builder: (context) {
                        final groupPlayers = gameJoinedDetailedGamesRecord
                            .joinedPlayers
                            .toList();
                        if (_memberMatchesById.isNotEmpty) {
                          groupPlayers.sort(
                            (a, b) => _compareMemberIds(a.id, b.id),
                          );
                        }
                        final guestPlayers = gameJoinedDetailedGamesRecord
                            .guestPlayers
                            .where((name) => name.trim().isNotEmpty)
                            .toList();
                        final gameOwner = gameJoinedDetailedGamesRecord.userRef;

                        final playerIds =
                            groupPlayers.map((playerRef) => playerRef.id).toList();
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
                                  final userRef =
                                      friendRecord?.reference ?? groupPlayersItem;
                                  final photoUrl = friendRecord?.photoUrl ?? '';

                                  // Fetch trust profile for badge display
                                  final trustProvider = context.read<TrustProvider>();
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
                                        onTap: () => _openPremiumVibePage(
                                          context,
                                          userRef,
                                          displayName,
                                          photoUrl,
                                          _memberMatchesById[
                                              groupPlayersItem.id],
                                        ),
                                      ),
                                      trailingWidget:
                                          gameJoinedDetailedGamesRecord
                                                      .userRef ==
                                                  currentUserRef
                                              ? AppIconButton(
                                                  icon: Icon(
                                                    Icons.remove_circle_outline,
                                                    color: AppColors.error,
                                                    size: AppIconSize.md,
                                                  ),
                                                  borderRadius: 20.0,
                                                  buttonSize: 40.0,
                                                  fillColor: Colors.transparent,
                                                  tooltip: 'Remove player',
                                                  onPressed: () =>
                                                      _showRemovePlayerDialog(
                                                    context: context,
                                                    playerName: displayName,
                                                    playerRef: groupPlayersItem,
                                                    isGuest: false,
                                                    gameRecord:
                                                        gameJoinedDetailedGamesRecord,
                                                  ),
                                                )
                                              : AppIcon(
                                                  assetPath: AppIcons.joined,
                                                  color: AppColors.goldLight,
                                                  size: AppIconSize.md,
                                                ),
                                      onTap: () {
                                        context.pushNamed(
                                          'ProfileUser',
                                          extra: <String, dynamic>{
                                            'userRef': userRef,
                                            kTransitionInfoKey:
                                                TransitionStandards
                                                    .detailTransition,
                                          },
                                        );
                                      },
                                    ),
                                  );
                                    },
                                  );
                                }),
                            // Guest players
                            ...guestPlayers.map(
                              (guestName) => Padding(
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
                                      // Remove button for owner
                                      if (gameJoinedDetailedGamesRecord.userRef == currentUserRef)
                                        AppIconButton(
                                          icon: Icon(
                                            Icons.remove_circle_outline,
                                            color: AppColors.error,
                                            size: 24.0,
                                          ),
                                          borderRadius: 20.0,
                                          buttonSize: 40.0,
                                          fillColor: Colors.transparent,
                                          tooltip: 'Remove guest',
                                          onPressed: () => _showRemovePlayerDialog(
                                            context: context,
                                            playerName: guestName,
                                            playerRef: null,
                                            isGuest: true,
                                            guestName: guestName,
                                            gameRecord: gameJoinedDetailedGamesRecord,
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
                  // Add Players button (for owner, when not full)
                  if (gameJoinedDetailedGamesRecord.userRef == currentUserRef &&
                      _getPlayerCount(gameJoinedDetailedGamesRecord) < 4)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: AppButtonEnhanced(
                        text: 'Add Players',
                        leadingIcon: Icons.person_add,
                        variant: AppButtonVariant.secondary,
                        size: AppButtonSize.medium,
                        fullWidth: true,
                        onPressed: () => _navigateToAddPlayers(context),
                      ),
                    ),
                  if (gameJoinedDetailedGamesRecord.userRef == currentUserRef &&
                      _getPlayerCount(gameJoinedDetailedGamesRecord) < 4)
                    SizedBox(height: AppSpacing.md),
                  // Leave game button (for non-owner)
                  if (gameJoinedDetailedGamesRecord.userRef != currentUserRef)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: _buildDestructiveButton(
                        context: context,
                        text: 'Leave game',
                        onPressed: () async {
                          // Show tier-aware cancellation warning
                          final confirmed = await CancellationWarningModal.show(
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
                          final removeValues = <Object>[
                            currentUserRef,
                          ];
                          try {
                            await gameRef.update({
                              'joined_players':
                                  FieldValue.arrayRemove(removeValues),
                            });
                            final chatRef = gameJoinedDetailedGamesRecord.chatRef;
                            if (chatRef != null) {
                              try {
                                await context.read<ChatProvider>().removeMember(
                                  chatId: chatRef.id,
                                  uid: currentUserRef.id,
                                );
                              } catch (chatError) {
                                debugPrint('LeaveGame: chat removal failed $chatError');
                              }
                            }
                          } on FirebaseException catch (error) {
                            if (!mounted) {
                              return;
                            }
                            final message =
                                error.code == 'permission-denied'
                                    ? 'You do not have permission to leave this game.'
                                    : 'Unable to leave the game right now. Please try again.';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          } catch (_) {
                            if (!mounted) {
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
                            return;
                          }
                          context.read<GameProvider>().invalidateUserGamesCache(
                              currentUserRef.id);

                          // Show success toast
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('You left the game'),
                              backgroundColor: AppColors.success,
                              duration: Duration(seconds: 2),
                            ),
                          );

                          // Navigate to Schedule tab (My Games)
                          context.goNamed(GamesJoinedWidget.routeName);
                        },
                      ),
                    ),
                  // Cancel game button (for owner)
                  if (gameJoinedDetailedGamesRecord.userRef == currentUserRef)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: _buildDestructiveButton(
                        context: context,
                        text: 'Cancel game',
                        onPressed: () async {
                          if (currentUserRef == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Please sign in to cancel the game.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          final confirmDialogResponse = await showDialog<bool>(
                                context: context,
                                builder: (alertDialogContext) {
                                  return AlertDialog(
                                    title: Text('Cancel this game?'),
                                    content:
                                        Text(
                                          'This will end the game for everyone.',
                                        ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(
                                            alertDialogContext, false),
                                        child: Text('Keep game'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(
                                            alertDialogContext, true),
                                        child: Text('Cancel game'),
                                      ),
                                    ],
                                  );
                                },
                              ) ??
                              false;
                          if (!confirmDialogResponse) {
                            return;
                          }

                          final visibilityChoice =
                              await showDialog<_CancelListingHandling>(
                            context: context,
                            builder: (alertDialogContext) {
                              return AlertDialog(
                                title: Text('Remove game listing?'),
                                content: Text(
                                  'Choose when to remove this game from your list.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(
                                      alertDialogContext,
                                      _CancelListingHandling.hideAfter7Days,
                                    ),
                                    child: Text('Hide after 7 days'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(
                                      alertDialogContext,
                                      _CancelListingHandling.removeNow,
                                    ),
                                    child: Text('Remove now'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(
                                      alertDialogContext,
                                      null,
                                    ),
                                    child: Text('Back'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (visibilityChoice == null) {
                            return;
                          }

                          if (widget.gameRef != null) {
                            if (visibilityChoice ==
                                _CancelListingHandling.removeNow) {
                              AppState().setCancelledGameHandling(
                                gameRef.path,
                                'removeNow',
                              );
                            } else {
                              AppState().setCancelledGameHandling(
                                gameRef.path,
                                'removeAfter7Days',
                              );
                              AppState().setCancelledGameHideAt(
                                gameRef.path,
                                getCurrentTimestamp.add(Duration(days: 7)),
                              );
                            }
                          }

                          {
                            try {
                              debugPrint(
                                'CancelGame: updating ${widget.gameRef?.path}',
                              );
                              await gameRef.update({
                                'isCancelled': true,
                                'status': 'cancelled',
                              });
                              final updatedSnapshot =
                                  await gameRef.get();
                              final updatedData = updatedSnapshot.data()
                                  as Map<String, dynamic>?;
                              debugPrint(
                                'CancelGame: isCancelled=${updatedData?['isCancelled']}',
                              );
                            } catch (error, stackTrace) {
                              debugPrint('CancelGame: failed $error');
                              debugPrintStack(stackTrace: stackTrace);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Unable to cancel the game. Please try again.',
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            final currentUserId =
                                FirebaseAuth.instance.currentUser?.uid;
                            final chatRef = gameJoinedDetailedGamesRecord.chatRef;
                            if (chatRef != null && currentUserId != null) {
                              final gameName =
                                  gameJoinedDetailedGamesRecord.nameGame;
                              final cancelMessage =
                                  gameName.trim().isNotEmpty
                                  ? 'Game "$gameName" has been cancelled.'
                                  : 'This game has been cancelled.';
                              try {
                                await context.read<ChatProvider>().sendMessage(
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
                              } catch (error, stackTrace) {
                                debugPrint(
                                  'CancelGame: chat update failed $error',
                                );
                                debugPrintStack(stackTrace: stackTrace);
                              }
                            }

                            // Show success toast
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Game cancelled successfully'),
                                backgroundColor: AppColors.success,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            context.gameProvider.invalidateUserGamesCache(context.userProvider.userId);

                            // Navigate to Games list tab
                            context.goNamed(GamesListWidget.routeName);
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
                        color: AppColors.cloud,
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
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
                      color: AppColors.navyDark,
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
                          borderRadius: BorderRadius.circular(AppBorderRadius.full),
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

  Widget _buildGroupMatchRow(GroupVibeMemberResult memberResult) {
    final matchScore = memberResult.displayScore.round();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
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
              color: AppColors.navyDark,
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
          content: Text('You cannot remove yourself. Use "Cancel game" instead.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (alertDialogContext) {
        return AlertDialog(
          title: Text('Remove Player?'),
          content: Text('Remove $playerName from this game?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(alertDialogContext, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(alertDialogContext, true),
              child: Text(
                'Remove',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    ) ?? false;

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
      debugPrint('Player Management: gameRef is null');
      return;
    }

    try {

      if (isGuest && guestName != null) {
        // Remove guest player
        await gameRef.update({
          'guest_players': FieldValue.arrayRemove([guestName]),
        });

        debugPrint('Player Management: Removed guest player: $guestName');
      } else if (!isGuest && playerRef != null) {
        // Remove registered player from game
        await gameRef.update({
          'joined_players': FieldValue.arrayRemove([playerRef]),
        });

        // Remove from chat group if chat exists
        final chatRef = gameRecord.chatRef;
        if (chatRef != null) {
          try {
            await context.read<ChatProvider>().removeMember(
              chatId: chatRef.id,
              uid: playerRef.id,
            );
            debugPrint('Player Management: Removed from chat: ${playerRef.id}');
          } catch (chatError) {
            debugPrint('Player Management: Chat removal failed: $chatError');
            // Continue even if chat removal fails - game removal succeeded
          }
        }

        debugPrint('Player Management: Removed registered player: ${playerRef.id}');
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$playerName removed from game'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Player Management: Remove failed - $error');
      debugPrintStack(stackTrace: stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove player. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
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
                  transitionType: PageTransitionType.fade,
                  enterDuration: Duration(milliseconds: 200),
                  exitDuration: Duration(milliseconds: 170),
                  scaleOnPush: true,
                ),
      },
    );
  }

  // Helper method to build destructive action buttons (Leave/Cancel)
  Widget _buildDestructiveButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56.0,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.5),
          width: 2.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          child: Center(
            child: Text(
              text,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // PREMIUM INFO CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPremiumInfoCard(
    BuildContext context, {
    required IconData icon,
    required List<Color> iconColors,
    required String label,
    required String value,
    bool isFunBadge = false,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isFunBadge
            ? AppColors.navy.withValues(alpha: 0.4)
            : AppColors.navy.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: isFunBadge
              ? AppColors.gold.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: iconColors),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              boxShadow: [
                BoxShadow(
                  color: iconColors.first.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.pure, size: AppIconSize.button),
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
                    color: isFunBadge ? AppColors.gold : Colors.white,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // Edit Game Details
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _handleEditGameDetails(
    BuildContext context,
    Game gameRecord,
  ) async {
    debugPrint('🎯 Edit Game Details: Starting edit flow');

    // Validate 2-hour restriction
    final teeTime = gameRecord.date;
    if (teeTime != null) {
      final hoursUntilTeeTime = teeTime.difference(DateTime.now()).inHours;
      debugPrint('🎯 Hours until tee time: $hoursUntilTeeTime');

      if (hoursUntilTeeTime < 2) {
        debugPrint('❌ Edit blocked: Less than 2 hours until tee time');
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Cannot Edit'),
            content: Text(
              'Tee time is less than 2 hours away. Consider cancelling this game and creating a new one instead.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
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
      debugPrint('🎯 Edit result received: $result');
      await _updateGameDetails(context, gameRecord, result);
    }
  }

  Future<void> _updateGameDetails(
    BuildContext context,
    Game gameRecord,
    Map<String, dynamic> updateData,
  ) async {
    debugPrint('🎯 Update Game Details: Starting update');

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
                CircularProgressIndicator(color: AppColors.gold),
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
      // Update Firestore
      final firestoreUpdate = <String, dynamic>{
        'date': updateData['date'],
        'course_play': updateData['course'],
        'courseRef': updateData['courseRef'],
      };

      debugPrint('🎯 Updating Firestore: $firestoreUpdate');
      await gameRecord.reference.update(firestoreUpdate);

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

        debugPrint('🎯 Sending notifications to ${recipients.length} players');
        debugPrint('🎯 Notification text: $notificationText');

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

      debugPrint('✅ Game details updated successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Edit Game Details: Error occurred');
      debugPrint('❌ Error: $e');
      debugPrint('❌ Stack trace: $stackTrace');

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
