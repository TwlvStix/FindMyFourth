import '/backend/backend.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/branded_golf_header.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/providers/provider_extensions.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_card.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/navigation/app_router.dart';
import '/main_function/games_joined/games_joined_widget.dart';
import '/main_function/player_list/player_list_widget.dart';
import '/models/game.dart';
import '/models/vibe_profile.dart';
import '/profile/main_profile/main_profile_widget.dart';
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

  // ═══════════════════════════════════════════════════════════════════════════
  // PREMIUM APP BAR
  // ═══════════════════════════════════════════════════════════════════════════
  PreferredSizeWidget _buildPremiumAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          final router = GoRouter.of(context);
          router.go('/gamesList');
        },
        child: Container(
          margin: EdgeInsets.only(left: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.fairway.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Icon(
            Icons.chevron_left_rounded,
            color: Colors.white,
            size: 28.0,
          ),
        ),
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
                    color: AppColors.fairway.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white.withOpacity(0.5),
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
                    color: Colors.white.withOpacity(0.6),
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
    return StreamBuilder<DocumentSnapshot>(
      stream: widget.gameRef!.snapshots(),
      builder: (context, snapshot) {
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
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final gameJoinedDetailedGamesRecord = Game.fromDoc(snapshot.data!);
        _ensureGroupVibeMatch(gameJoinedDetailedGamesRecord, currentUserRef);

        return Scaffold(
          key: scaffoldKey,
          extendBodyBehindAppBar: true,
          appBar: _buildPremiumAppBar(context, 'Game Dashboard'),
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
                      child: _buildPremiumHeroSection(
                        context,
                        gameJoinedDetailedGamesRecord,
                      ),
                    ),

                    // Quick Stats Row (Date, Players, Chat)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: _buildQuickStatsRow(gameJoinedDetailedGamesRecord),
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
                                  color: AppColors.sunsetGold.withOpacity(0.3),
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
                            childAspectRatio: 3.2,
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
                                  color: AppColors.sunsetGold.withOpacity(0.2),
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

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Registered players
                            ...List.generate(groupPlayers.length,
                                (groupPlayersIndex) {
                              final groupPlayersItem =
                                  groupPlayers[groupPlayersIndex];
                              return Padding(
                                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                                child: StreamBuilder<UsersRecord>(
                                  stream:
                                      UsersRecord.getDocument(groupPlayersItem),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Center(
                                        child: SizedBox(
                                          width: 40.0,
                                          height: 40.0,
                                          child: SpinKitWanderingCubes(
                                            color:
                                                AppTheme.of(context).secondary,
                                            size: 40.0,
                                          ),
                                        ),
                                      );
                                    }

                                    final friend1UsersRecord = snapshot.data!;

                                    return InkWell(
                                      onTap: () {
                                        context.pushNamed(
                                          'ProfileUser',
                                          extra: <String, dynamic>{
                                            'userRef':
                                                friend1UsersRecord.reference,
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
                                                friend1UsersRecord.photoUrl !=
                                                        ''
                                                    ? friend1UsersRecord
                                                        .photoUrl
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
                                                    friend1UsersRecord
                                                        .displayName,
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
                                              child: _buildPlayerMatchChip(
                                                friend1UsersRecord.reference.id,
                                                friend1UsersRecord.displayName,
                                              ),
                                            ),
                                            // Show remove button for owner, checkmark for others
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
                                                onPressed: () => _showRemovePlayerDialog(
                                                  context: context,
                                                  playerName: friend1UsersRecord.displayName,
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
                                    );
                                  },
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
                          final currentUser =
                              FirebaseAuth.instance.currentUser;
                          final currentUserId =
                              currentUser?.uid ?? currentUserRef.id;
                          final removeValues = <Object>[
                            currentUserRef,
                            currentUserId,
                          ];
                          await widget.gameRef!.update({
                            'joined_players':
                                FieldValue.arrayRemove(removeValues),
                          });
                          context.userProvider.refreshMyGames();

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
                                widget.gameRef!.path,
                                'removeNow',
                              );
                            } else {
                              AppState().setCancelledGameHandling(
                                widget.gameRef!.path,
                                'removeAfter7Days',
                              );
                              AppState().setCancelledGameHideAt(
                                widget.gameRef!.path,
                                getCurrentTimestamp.add(Duration(days: 7)),
                              );
                            }
                          }

                          {
                            try {
                              debugPrint(
                                'CancelGame: updating ${widget.gameRef?.path}',
                              );
                              await widget.gameRef!.update({
                                'isCancelled': true,
                                'status': 'cancelled',
                              });
                              final updatedSnapshot =
                                  await widget.gameRef!.get();
                              final updatedData = updatedSnapshot.data()
                                  as Map<String, dynamic>?;
                              debugPrint(
                                'CancelGame: isCancelled=${updatedData?['isCancelled']}',
                              );

                              final currentUserId =
                                  FirebaseAuth.instance.currentUser?.uid;
                              if (gameJoinedDetailedGamesRecord.chatRef !=
                                      null &&
                                  currentUserId != null) {
                                final gameName =
                                    gameJoinedDetailedGamesRecord.nameGame;
                                final cancelMessage = (gameName != null &&
                                        gameName.trim().isNotEmpty)
                                    ? 'Game "$gameName" has been cancelled.'
                                    : 'This game has been cancelled.';
                                final chatRef =
                                    gameJoinedDetailedGamesRecord.chatRef!;
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
                              }
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

                            // Show success toast
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Game cancelled successfully'),
                                backgroundColor: AppTheme.of(context).success,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            context.userProvider.refreshMyGames();

                            // Navigate to Schedule tab (My Games)
                            context.goNamed(GamesJoinedWidget.routeName);
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

  // Helper method to format date/time
  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Date not set';
    final formatter = DateFormat('EEEE, MMMM d • HH:mm');
    return formatter.format(date);
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

  Widget _buildGroupVibeSummary() {
    final result = _groupVibeMatch;
    final groupScore = result == null
        ? '--'
        : '${result.groupFitScore.round()}%';
    final lowestMatch = result?.lowestMatch;
    final lowestScore = lowestMatch == null
        ? '--'
        : '${lowestMatch.displayScore.round()}%';
    final lowestCategory = lowestMatch?.matchResult.topDifferences.isNotEmpty ==
            true
        ? VibeLabels.titleFor(
            lowestMatch!.matchResult.topDifferences.first.category,
          )
        : null;
    final lowestLine = lowestMatch == null || lowestCategory == null
        ? 'Lowest match: --'
        : 'Lowest match: $lowestScore ($lowestCategory with ${lowestMatch.member.name})';

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your fit with this group: $groupScore',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.onyx,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            lowestLine,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.stone,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButtonEnhanced(
                  text: 'View breakdown',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.small,
                  fullWidth: true,
                  onPressed: result == null ? null : _openGroupVibeBreakdown,
                ),
              ),
              if (_isGroupVibeLoading) ...[
                SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.of(context).primary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
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

  // Helper method to build info card
  Widget _buildInfoCard(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.fairway.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.fairwayLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.of(context).labelSmall.override(
                        font: GoogleFonts.outfit(
                          fontWeight: FontWeight.w500,
                          fontStyle: AppTheme.of(context).labelSmall.fontStyle,
                        ),
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w500,
                        fontStyle: AppTheme.of(context).labelSmall.fontStyle,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: AppTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                  ),
                  color: Colors.white,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                  fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
    try {

      if (isGuest && guestName != null) {
        // Remove guest player
        await widget.gameRef!.update({
          'guest_players': FieldValue.arrayRemove([guestName]),
        });

        debugPrint('Player Management: Removed guest player: $guestName');
      } else if (!isGuest && playerRef != null) {
        // Remove registered player from game
        await widget.gameRef!.update({
          'joined_players': FieldValue.arrayRemove([playerRef]),
        });

        // Remove from chat group if chat exists
        if (gameRecord.chatRef != null) {
          try {
            await context.read<ChatProvider>().removeMember(
              chatId: gameRecord.chatRef!.id,
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
  // PREMIUM HERO SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPremiumHeroSection(BuildContext context, Game game) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.fairway.withOpacity(0.4),
            AppColors.fairwayDark.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.sunsetGold.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.sunsetGold.withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Joined',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          // Course name with golf icon
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sunsetGold.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.golf_course_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.coursePlay ?? 'Course Name',
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      game.nameGame ?? 'Game',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.sunsetGold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK STATS ROW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildQuickStatsRow(Game game) {
    final spotsLeft = game.maxPlayers - (game.joinedPlayers.length + game.guestPlayers.length);
    final isFull = spotsLeft <= 0;

    return Row(
      children: [
        // Date Card
        Expanded(
          child: Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.fairway.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.sunsetPeach, AppColors.sunsetRose],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateTimeFormat("MMM d", game.date) ?? '',
                        style: AppTypography.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        dateTimeFormat("jm", game.date) ?? '',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        // Players Card
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isFull
                ? AppColors.fairwayLight.withOpacity(0.2)
                : AppColors.sunsetGold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFull
                  ? AppColors.fairwayLight.withOpacity(0.3)
                  : AppColors.sunsetGold.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isFull
                        ? [AppColors.fairwayLight, AppColors.fairway]
                        : [AppColors.sunsetGold, AppColors.sunsetPeach],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isFull ? Icons.groups_rounded : Icons.person_add_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFull ? 'Full' : '$spotsLeft Spots',
                    style: AppTypography.titleSmall.copyWith(
                      color: isFull ? AppColors.fairwayLight : AppColors.sunsetGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${game.joinedPlayers.length + game.guestPlayers.length}/${game.maxPlayers}',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
            AppColors.fairway.withOpacity(0.4),
            AppColors.fairwayDark.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                      hasResult ? 'Your fit with this group' : 'Calculating...',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.6),
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
                  color: hasResult ? null : Colors.white.withOpacity(0.1),
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
            SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: _openGroupVibeBreakdown,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
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
                      color: Colors.white.withOpacity(0.6),
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
    required IconData icon,
    required List<Color> iconColors,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.fairway.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
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
                  color: iconColors.first.withOpacity(0.3),
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
                    color: Colors.white.withOpacity(0.6),
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
