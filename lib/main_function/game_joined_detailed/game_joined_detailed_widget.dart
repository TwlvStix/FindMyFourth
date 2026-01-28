import '/backend/backend.dart';
import '/core/widgets/fairway_background.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/providers/provider_extensions.dart';
import '/providers/game_provider.dart';
import '/providers/profile_provider.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/navigation/app_router.dart';
import '/main_function/games_joined/games_joined_widget.dart';
import '/main_function/games_list/games_list_widget.dart';
import '/main_function/player_list/player_list_widget.dart';
import '/models/game.dart';
import '/models/vibe_profile.dart';
import '/services/vibe_group_matcher.dart';
import '/services/vibe_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/providers/chat_provider.dart';
import 'components/premium_app_bar.dart';
import 'components/premium_hero_section.dart';
import 'components/quick_stats_row.dart';
import 'components/group_vibe_summary.dart';
import 'components/player_match_chip.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
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
      _loadGroupVibeMatch(gameRecord, currentUserRef);
    });
  }

  Future<void> _loadGroupVibeMatch(
    Game gameRecord,
    DocumentReference currentUserRef,
  ) async {
    setState(() {
      _isGroupVibeLoading = true;
    });
    try {
      final myVibes = await _vibeRepository.getMyVibesCached();
      final members = <GroupVibeMember>[];
      for (final ref in gameRecord.joinedPlayers) {
        if (ref.id == currentUserRef.id) {
          continue;
        }
        final snapshot = await ref.get();
        final data =
            (snapshot.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
        final displayName = _stringValue(data, 'display_name', 'Player');
        members.add(
          GroupVibeMember(
            id: ref.id,
            name: displayName,
            profile: _vibeRepository.profileFromSnapshot(snapshot),
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
            appBar: const PremiumAppBar(title: 'Loading...'),
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

                    // Quick Stats Row (Date, Players, Chat)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: QuickStatsRow(game: gameJoinedDetailedGamesRecord),
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
                            try {
                              await context.read<ChatProvider>().addMember(
                                    chatId: chatRef.id,
                                    uid: currentUser.uid,
                                  );
                            } on FirebaseException catch (error) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      error.code == 'permission-denied'
                                          ? 'Chat access is not available right now.'
                                          : 'Unable to open the chat. Please try again.',
                                    ),
                                  ),
                                );
                              }
                              return;
                            } catch (_) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Unable to open the chat. Please try again.',
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
                                colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.sunsetGold.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 22),
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
                                value: gameJoinedDetailedGamesRecord.styleGame,
                              ),
                              _buildPremiumInfoCard(
                                context,
                                icon: Icons.rule_rounded,
                                iconColors: [AppColors.fairwayLight, AppColors.fairway],
                                label: 'Rule Style',
                                value: gameJoinedDetailedGamesRecord.rulesSetting,
                              ),
                              _buildPremiumInfoCard(
                                context,
                                icon: Icons.sports_golf_rounded,
                                iconColors: [AppColors.fairwayLight, AppColors.fairway],
                                label: 'Game Type',
                                value: gameJoinedDetailedGamesRecord.gameType,
                              ),
                              _buildPremiumInfoCard(
                                context,
                                icon: Icons.scoreboard_rounded,
                                iconColors: [AppColors.sunsetPeach, AppColors.sunsetRose],
                                label: 'Scoring',
                                value: gameJoinedDetailedGamesRecord.scoring,
                              ),
                              _buildPremiumInfoCard(
                                context,
                                icon: Icons.discount_rounded,
                                iconColors: [AppColors.fairwayLight, AppColors.fairway],
                                label: 'Member Discount',
                                value: gameJoinedDetailedGamesRecord.memberDiscount,
                              ),
                              _buildPremiumInfoCard(
                                context,
                                icon: Icons.group_rounded,
                                iconColors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                                label: 'Friends Only',
                                value: gameJoinedDetailedGamesRecord.friendGame,
                              ),
                            ],
                          ),
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
                                    colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
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
                                  color: AppColors.sunsetGold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_getPlayerCount(gameJoinedDetailedGamesRecord)}/4',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.sunsetGold,
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
                            (a, b) => _memberScoreForId(a.id)
                                .compareTo(_memberScoreForId(b.id)),
                          );
                        }
                        final guestPlayers = gameJoinedDetailedGamesRecord
                            .guestPlayers
                            .where((name) => name.trim().isNotEmpty)
                            .toList();

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
                                                color: AppColors.fairwayLight,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppColors.sunsetGold,
                                                  width: 2.0,
                                                ),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: Image.network(
                                                photoUrl.isNotEmpty
                                                    ? photoUrl
                                                    : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Image.asset(
                                                  'assets/images/error_image.png',
                                                  fit: BoxFit.cover,
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
                                                  Text(
                                                    displayName,
                                                    style: AppTheme.of(context)
                                                        .bodyLarge
                                                        .override(
                                                          font: GoogleFonts
                                                              .outfit(
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
                                                  SizedBox(height: AppSpacing.xxs),
                                                  Text(
                                                    'Ready',
                                                    style: AppTheme.of(context)
                                                        .bodySmall
                                                        .override(
                                                          font: GoogleFonts
                                                              .outfit(
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
                                              child: PlayerMatchChip(
                                                name: displayName,
                                                memberMatch:
                                                    _memberMatchesById[groupPlayersItem.id],
                                              ),
                                            ),
                                            // Show remove button for owner, checkmark for others
                                            if (gameJoinedDetailedGamesRecord.userRef ==
                                                currentUserRef)
                                              AppIconButton(
                                                icon: Icon(
                                                  Icons.remove_circle_outline,
                                                  color: AppTheme.of(context).error,
                                                  size: 24.0,
                                                ),
                                                borderRadius: 20.0,
                                                buttonSize: 40.0,
                                                fillColor: Colors.transparent,
                                                tooltip: 'Remove player',
                                                onPressed: () => _showRemovePlayerDialog(
                                                  context: context,
                                                  playerName: displayName,
                                                  playerRef: groupPlayersItem,
                                                  isGuest: false,
                                                  gameRecord: gameJoinedDetailedGamesRecord,
                                                ),
                                              )
                                            else
                                              Icon(
                                                Icons.check_circle,
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
                                                  font: GoogleFonts.outfit(
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
                                                    font: GoogleFonts.outfit(
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
                                                    font: GoogleFonts.outfit(
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
                                      // Remove button for owner
                                      if (gameJoinedDetailedGamesRecord.userRef == currentUserRef)
                                        AppIconButton(
                                          icon: Icon(
                                            Icons.remove_circle_outline,
                                            color: AppTheme.of(context).error,
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
                          if (currentUserRef == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Please sign in to leave the game.'),
                                backgroundColor: AppTheme.of(context).error,
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
                                backgroundColor: AppTheme.of(context).error,
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
                                backgroundColor: AppTheme.of(context).error,
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
                              backgroundColor: AppTheme.of(context).success,
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
                                backgroundColor: AppTheme.of(context).error,
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
                                  backgroundColor: AppTheme.of(context).error,
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
                                backgroundColor: AppTheme.of(context).success,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            context.userProvider.refreshMyGames();

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
    showModalBottomSheet(
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
      ..sort((a, b) => a.displayScore.compareTo(b.displayScore));
    return sorted;
  }

  double _memberScoreForId(String memberId) {
    final match = _memberMatchesById[memberId];
    if (match == null) {
      return double.infinity;
    }
    return match.displayScore;
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
          backgroundColor: AppTheme.of(context).error,
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
                style: TextStyle(color: AppTheme.of(context).error),
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
          backgroundColor: AppTheme.of(context).success,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Player Management: Remove failed - $error');
      debugPrintStack(stackTrace: stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove player. Please try again.'),
          backgroundColor: AppTheme.of(context).error,
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
          transitionType: PageTransitionType.bottomToTop,
          duration: Duration(milliseconds: 220),
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
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.5),
          width: 2.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.0),
          child: Center(
            child: Text(
              text,
              style: AppTheme.of(context).bodyLarge.override(
                    font: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
                    ),
                    color: AppColors.error,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                    fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
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
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  value.isNotEmpty ? value : '--',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
