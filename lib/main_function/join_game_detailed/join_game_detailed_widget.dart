import '/backend/backend.dart';
import '/components/date_format_widget.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/branded_golf_header.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_card.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/models/game.dart';
import '/models/vibe_profile.dart';
import '/profile/profile_user/profile_user_firebase_widget.dart';
import '/providers/provider_extensions.dart';
import '/main_function/game_joined_detailed/game_joined_detailed_widget.dart';
import '/services/vibe_group_matcher.dart';
import '/services/vibe_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/providers/chat_provider.dart';
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
      _loadGroupVibeMatch(gameRecord, currentUserRef, groupRefs);
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
  ) async {
    setState(() {
      _isGroupVibeLoading = true;
    });
    try {
      final myVibes = await _vibeRepository.getMyVibesCached();
      final members = <GroupVibeMember>[];
      for (final ref in groupRefs) {
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

  List<GroupVibeMemberResult> _sortedMemberResults(
    GroupVibeMatchResult result,
  ) {
    final sorted = result.memberResults.toList()
      ..sort((a, b) => a.displayScore.compareTo(b.displayScore));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gameRef == null) {
      return Scaffold(
        backgroundColor: AppTheme.of(context).secondaryBackground,
        body: Center(
          child: Text(
            'Game details are unavailable.',
            style: AppTheme.of(context).bodyMedium,
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
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppTheme.of(context).secondaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: SpinKitWanderingCubes(
                  color: AppTheme.of(context).secondary,
                  size: 50.0,
                ),
              ),
            ),
          );
        }

        final joinGameDetailedGamesRecord = Game.fromDoc(snapshot.data!);
        _ensureGroupVibeMatch(joinGameDetailedGamesRecord, currentUserRef);

        return Scaffold(
          key: scaffoldKey,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leading: InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async {
                debugPrint('🔙 JOIN GAME DETAIL: Back button pressed, navigating to Game List');
                // Always navigate to Game List, not pop() which could go to "Add Your Group"
                // This ensures clean navigation flow
                final router = GoRouter.of(context);
                router.go('/gamesList');
              },
              child: Icon(
                Icons.chevron_left_rounded,
                color: AppTheme.of(context).primary,
                size: 32.0,
              ),
            ),
            title: Text(
              'Available Game',
              style: AppTheme.of(context).headlineSmall.override(
                    font: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500,
                      fontStyle: AppTheme.of(context).headlineSmall.fontStyle,
                    ),
                    color: AppTheme.of(context).primary,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                    fontStyle: AppTheme.of(context).headlineSmall.fontStyle,
                  ),
            ),
            actions: [],
            centerTitle: false,
            elevation: 0.0,
          ),
          body: FairwayBackgroundDark(
            showOrganic: true,
            showTexture: true,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Branded header with abstract golf pattern
                      Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: BrandedGolfHeader(
                          username: joinGameDetailedGamesRecord.nameGame,
                          courseName: joinGameDetailedGamesRecord.coursePlay,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: _buildGroupVibeSummary(),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 0.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DateFormatWidget(
                              date: joinGameDetailedGamesRecord.date,
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 10.0, 0.0, 0.0),
                              child: Text(
                                'Game Details:',
                                style: AppTheme.of(context).bodyMedium.override(
                                      font: GoogleFonts.outfit(
                                        fontWeight: AppTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: AppTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: Colors.white,
                                      letterSpacing: 0.0,
                                      fontWeight: AppTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: AppTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 8.0, 0.0, 0.0),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 12.0, 0.0, 12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            width: 64.0,
                                            height: 64.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  AppTheme.of(context).primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppTheme.of(context)
                                                    .primaryBtnText,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Container(
                                              width: 64.0,
                                              height: 64.0,
                                              child: custom_widgets
                                                  .DynamicTextSize(
                                                width: 64.0,
                                                height: 64.0,
                                                text:
                                                    joinGameDetailedGamesRecord
                                                        .styleGame,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Betting\n',
                                              textAlign: TextAlign.center,
                                              style: AppTheme.of(context)
                                                  .bodySmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.lexendDeca(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 12.0, 0.0, 12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            width: 64.0,
                                            height: 64.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  AppTheme.of(context).primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppTheme.of(context)
                                                    .primaryBtnText,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Container(
                                              width: 64.0,
                                              height: 64.0,
                                              child: custom_widgets
                                                  .DynamicTextSize(
                                                width: 64.0,
                                                height: 64.0,
                                                text:
                                                    joinGameDetailedGamesRecord
                                                        .rulesSetting,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Rule\nStyle',
                                              textAlign: TextAlign.center,
                                              style: AppTheme.of(context)
                                                  .bodySmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.lexendDeca(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 12.0, 0.0, 12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            width: 64.0,
                                            height: 64.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  AppTheme.of(context).primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppTheme.of(context)
                                                    .primaryBtnText,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Container(
                                              width: 64.0,
                                              height: 64.0,
                                              child: custom_widgets
                                                  .DynamicTextSize(
                                                width: 64.0,
                                                height: 64.0,
                                                text:
                                                    joinGameDetailedGamesRecord
                                                        .gameType,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Game\nType',
                                              textAlign: TextAlign.center,
                                              style: AppTheme.of(context)
                                                  .bodySmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.lexendDeca(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 12.0, 0.0, 12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            width: 64.0,
                                            height: 64.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  AppTheme.of(context).primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppTheme.of(context)
                                                    .primaryBtnText,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Container(
                                              width: 64.0,
                                              height: 64.0,
                                              child: custom_widgets
                                                  .DynamicTextSize(
                                                width: 64.0,
                                                height: 64.0,
                                                text:
                                                    joinGameDetailedGamesRecord
                                                        .scoring,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Scoring\n',
                                              textAlign: TextAlign.center,
                                              style: AppTheme.of(context)
                                                  .bodySmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.lexendDeca(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 12.0, 0.0, 12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            width: 64.0,
                                            height: 64.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  AppTheme.of(context).primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppTheme.of(context)
                                                    .primaryBtnText,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Container(
                                              width: 64.0,
                                              height: 64.0,
                                              child: custom_widgets
                                                  .DynamicTextSize(
                                                width: 64.0,
                                                height: 64.0,
                                                text:
                                                    joinGameDetailedGamesRecord
                                                        .memberDiscount,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Member\nDiscount',
                                              textAlign: TextAlign.center,
                                              style: AppTheme.of(context)
                                                  .bodySmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.lexendDeca(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 12.0, 0.0, 12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            width: 64.0,
                                            height: 64.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  AppTheme.of(context).primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppTheme.of(context)
                                                    .primaryBtnText,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Container(
                                              width: 64.0,
                                              height: 64.0,
                                              child: custom_widgets
                                                  .DynamicTextSize(
                                                width: 64.0,
                                                height: 64.0,
                                                text:
                                                    joinGameDetailedGamesRecord
                                                        .friendGame,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Friends\nOnly?',
                                              textAlign: TextAlign.center,
                                              style: AppTheme.of(context)
                                                  .bodySmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.lexendDeca(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]
                                      .divide(SizedBox(width: 10.0))
                                      .addToStart(SizedBox(width: 10.0))
                                      .addToEnd(SizedBox(width: 10.0)),
                                ),
                              ),
                            ),
                            Divider(
                              height: 32.0,
                              thickness: 1.0,
                              color: AppTheme.of(context).alternate,
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 8.0, 0.0, 0.0),
                              child: Text(
                                'Players in this Group:',
                                style:
                                    AppTheme.of(context).labelMedium.override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w800,
                                            fontStyle: AppTheme.of(context)
                                                .labelMedium
                                                .fontStyle,
                                          ),
                                          color: Colors.white,
                                          fontSize: 18.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w800,
                                          fontStyle: AppTheme.of(context)
                                              .labelMedium
                                              .fontStyle,
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 0.0, 8.0),
                        child: Container(
                          height: 120.0,
                          decoration: BoxDecoration(),
                          child: Builder(
                            builder: (context) {
                              final groupPlayers = joinGameDetailedGamesRecord
                                  .joinedPlayers
                                  .toList();
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

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    ...List.generate(groupPlayers.length,
                                        (groupPlayersIndex) {
                                      final groupPlayersItem =
                                          groupPlayers[groupPlayersIndex];
                                      return Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            12.0, 12.0, 0.0, 12.0),
                                        child: StreamBuilder<UsersRecord>(
                                          stream: UsersRecord.getDocument(
                                              groupPlayersItem),
                                          builder: (context, snapshot) {
                                            // Customize what your widget looks like when it's loading.
                                            if (!snapshot.hasData) {
                                              return Center(
                                                child: SizedBox(
                                                  width: 50.0,
                                                  height: 50.0,
                                                  child: SpinKitWanderingCubes(
                                                    color: AppTheme.of(context)
                                                        .secondary,
                                                    size: 50.0,
                                                  ),
                                                ),
                                              );
                                            }

                                            final friend1UsersRecord =
                                                snapshot.data!;

                                            return Column(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Container(
                                                  width: 64.0,
                                                  height: 64.0,
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.of(context)
                                                        .info,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color:
                                                          AppTheme.of(context)
                                                              .tertiary,
                                                      width: 2.0,
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.all(4.0),
                                                    child: InkWell(
                                                      splashColor:
                                                          Colors.transparent,
                                                      focusColor:
                                                          Colors.transparent,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      onTap: () {
                                                        Navigator.of(context)
                                                            .push(
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                ProfileUserFirebaseWidget(
                                                              userRef:
                                                                  friend1UsersRecord
                                                                      .reference,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: Container(
                                                        width: 70.0,
                                                        height: 70.0,
                                                        clipBehavior:
                                                            Clip.antiAlias,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: Image.network(
                                                          valueOrDefault<
                                                              String>(
                                                            friend1UsersRecord
                                                                .photoUrl,
                                                            'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                                                          ),
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context,
                                                                  error,
                                                                  stackTrace) =>
                                                              Image.asset(
                                                            'assets/images/error_image.png',
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 8.0, 0.0, 0.0),
                                                  child: Text(
                                                    friend1UsersRecord
                                                        .displayName,
                                                    textAlign: TextAlign.center,
                                                    style: AppTheme.of(context)
                                                        .bodySmall
                                                        .override(
                                                          font: GoogleFonts
                                                              .lexendDeca(
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontStyle,
                                                          ),
                                                          color: Colors.white,
                                                          fontSize: 14.0,
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
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      );
                                    }),
                                    ...guestPlayers.map(
                                      (guestName) => Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            12.0, 12.0, 0.0, 12.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Container(
                                              width: 64.0,
                                              height: 64.0,
                                              decoration: BoxDecoration(
                                                color:
                                                    AppTheme.of(context).info,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppTheme.of(context)
                                                      .tertiary,
                                                  width: 2.0,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'G',
                                                  style: AppTheme.of(context)
                                                      .titleMedium
                                                      .override(
                                                        font:
                                                            GoogleFonts.outfit(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontStyle:
                                                              AppTheme.of(
                                                                      context)
                                                                  .titleMedium
                                                                  .fontStyle,
                                                        ),
                                                        color: Colors.white,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontStyle:
                                                            AppTheme.of(context)
                                                                .titleMedium
                                                                .fontStyle,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(0.0, 8.0, 0.0, 0.0),
                                              child: Text(
                                                guestName,
                                                textAlign: TextAlign.center,
                                                style: AppTheme.of(context)
                                                    .bodySmall
                                                    .override(
                                                      font: GoogleFonts
                                                          .lexendDeca(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            AppTheme.of(context)
                                                                .bodySmall
                                                                .fontStyle,
                                                      ),
                                                      color: Colors.white,
                                                      fontSize: 14.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      if (joinGameDetailedGamesRecord.userRef != currentUserRef)
                        Align(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 8.0),
                            child: SizedBox(
                              width: 300.0,
                              child: AppButtonEnhanced(
                                text: 'Join Game',
                                variant: AppButtonVariant.primary,
                                size: AppButtonSize.large,
                                onPressed: () async {
                                  if ((joinGameDetailedGamesRecord.maxPlayers >
                                          (joinGameDetailedGamesRecord
                                                  .joinedPlayers.length +
                                              joinGameDetailedGamesRecord
                                                  .guestPlayers.length)) &&
                                      ((joinGameDetailedGamesRecord
                                                  .friendGame ==
                                              'Public') ||
                                          ((joinGameDetailedGamesRecord
                                                      .friendGame ==
                                                  'Friends') &&
                                              isCreatorFriend))) {
                                    final currentUser =
                                        FirebaseAuth.instance.currentUser;
                                    if (currentUser == null) {
                                      showSnackbar(
                                        context,
                                        'Please sign in to join this game.',
                                      );
                                      return;
                                    }
                                    final currentUserRef = FirebaseFirestore
                                        .instance
                                        .collection('users')
                                        .doc(currentUser.uid);
                                    try {
                                      await joinGameDetailedGamesRecord.reference
                                          .update({
                                        'joined_players':
                                            FieldValue.arrayUnion([currentUserRef]),
                                      });
                                    } on FirebaseException catch (error) {
                                      if (!mounted) {
                                        return;
                                      }
                                      final message =
                                          error.code == 'permission-denied'
                                              ? 'You do not have permission to join this game.'
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
                                      } catch (_) {
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
                                          transitionType:
                                              PageTransitionType.bottomToTop,
                                          duration: Duration(milliseconds: 220),
                                        ),
                                      },
                                    );
                                  } else {
                                    await showDialog(
                                      context: context,
                                      builder: (alertDialogContext) {
                                        return AlertDialog(
                                          title: Text('Sorry!'),
                                          content: Text(
                                              'You are not friends with the game creator or the group  is full.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                  alertDialogContext),
                                              child: Text('Ok'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
