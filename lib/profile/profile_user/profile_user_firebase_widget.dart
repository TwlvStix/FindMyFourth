import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/navigation/app_router.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/models/vibe_profile.dart';
import '/providers/chat_provider.dart';
import '/providers/user_provider.dart';
import '/providers/profile_provider.dart';
import '/backend/schema/users_record.dart';
import '/services/vibe_match_explanation.dart';
import '/services/vibe_matcher.dart';
import '/services/vibe_repository.dart';
import '/utils/vibe_archetypes.dart';
import '/vibe/premium_vibe_page/premium_vibe_page_data.dart';

class ProfileUserFirebaseWidget extends StatefulWidget {
  const ProfileUserFirebaseWidget({
    super.key,
    required this.userRef,
  });

  final DocumentReference userRef;

  @override
  State<ProfileUserFirebaseWidget> createState() =>
      _ProfileUserFirebaseWidgetState();
}

class _ProfileUserFirebaseWidgetState extends State<ProfileUserFirebaseWidget>
    with SingleTickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final VibeRepository _vibeRepository = VibeRepository();
  late AnimationController _ringController;

  VibeMatchResult? _vibeMatchResult;
  VibeProfile? _myVibes;
  VibeProfile? _theirVibes;
  bool _isVibeMatchLoading = false;
  String? _vibeMatchUserId;
  String _cachedUserName = '';
  String _cachedUserPhotoUrl = '';

  Future<void> _openChatWithUser(DocumentReference userRef) async {
    final currentUserRef = currentUserReference;
    if (currentUserRef == null) {
      return;
    }

    try {
      final chatRef = await context.read<ChatProvider>().createOrGetDirectChat(
            currentUid: currentUserRef.id,
            otherUid: userRef.id,
          );
      _openChat(chatRef.id);
    } catch (error, stackTrace) {
      context
          .read<ChatProvider>()
          .logError('createOrGetDirectChat failed', error, stackTrace);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start chat. Please try again.'),
        ),
      );
    }
  }

  void _openChat(String chatId) {
    context.pushNamed(
      'ChatDetails',
      pathParameters: {
        'chatId': chatId,
      },
      extra: <String, dynamic>{
        kTransitionInfoKey: TransitionStandards.detailTransition,
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  void _ensureVibeMatch(DocumentSnapshot snapshot) {
    if (_isVibeMatchLoading) {
      return;
    }
    if (_vibeMatchResult != null && _vibeMatchUserId == snapshot.id) {
      return;
    }
    _vibeMatchUserId = snapshot.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadVibeMatch(snapshot);
    });
  }

  Future<void> _loadVibeMatch(DocumentSnapshot snapshot) async {
    setState(() {
      _isVibeMatchLoading = true;
      _vibeMatchResult = null;
    });
    try {
      final myVibes = await _vibeRepository.getMyVibesCached();
      final theirVibes = _vibeRepository.profileFromSnapshot(snapshot);
      final result = VibeMatcher.score(myVibes, theirVibes);
      if (!mounted) {
        return;
      }
      setState(() {
        _myVibes = myVibes;
        _theirVibes = theirVibes;
        _vibeMatchResult = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _vibeMatchResult = null;
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isVibeMatchLoading = false;
      });
    }
  }

  void _openVibePage() {
    final result = _vibeMatchResult;
    final myVibes = _myVibes;
    final theirVibes = _theirVibes;
    if (result == null || myVibes == null || theirVibes == null) {
      return;
    }

    // Build explanation
    final explanation = buildMatchExplanation(
      matchResult: result,
      a: myVibes,
      b: theirVibes,
    );

    // Get archetypes
    final myArchetype = VibeArchetypes.classifyProfile(myVibes);
    final theirArchetype = VibeArchetypes.classifyProfile(theirVibes);

    // Use cached user data (set from StreamBuilder)
    final userName = _cachedUserName.isNotEmpty ? _cachedUserName : 'Golfer';
    final userPhotoUrl = _cachedUserPhotoUrl.isNotEmpty
        ? _cachedUserPhotoUrl
        : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';

    // Create data model
    final pageData = PremiumVibePageData(
      userId: widget.userRef.id,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      userRef: widget.userRef,
      matchResult: result,
      explanation: explanation,
      myProfile: myVibes,
      theirProfile: theirVibes,
      myArchetype: myArchetype,
      theirArchetype: theirArchetype,
    );

    // Navigate
    context.pushNamed(
      'PremiumVibePage',
      pathParameters: {
        'userId': widget.userRef.id,
      },
      extra: pageData,
    );
  }

  Widget _buildVibeMatchRow() {
    final result = _vibeMatchResult;
    final displayScore =
        result == null ? '--' : '${result.myFitPercent.round()}%';
    final label = 'Your Fit $displayScore';
    final canOpenSheet = result != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    letterSpacing: AppTypography.letterSpacingNormal,
                  ),
                ),
                if (_isVibeMatchLoading) ...[
                  const SizedBox(width: AppSpacing.xs),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          InkWell(
            onTap: canOpenSheet ? _openVibePage : null,
            child: Text(
              'Why?',
              style: AppTypography.bodySmall.copyWith(
                color: canOpenSheet ? Colors.white : AppColors.stone,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context, {
    required String photoUrl,
    required String name,
    required String handle,
    required bool showVibeMatch,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sunsetGold.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _ringController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _ringController.value * 2 * 3.14159,
                  child: Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          AppColors.sunsetGold,
                          AppColors.sunsetPeach,
                          AppColors.sunsetRose,
                          AppColors.fairwayLight,
                          AppColors.sunsetGold,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.pure,
              ),
            ),
            Container(
              width: 132,
              height: 132,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.sand,
                  child: Icon(
                    Icons.person_rounded,
                    size: 60,
                    color: AppColors.stone,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        Text(
          name,
          style: AppTypography.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (handle.isNotEmpty) ...[
          SizedBox(height: AppSpacing.xxs),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.fairway.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Text(
              handle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.sunsetGold,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        if (showVibeMatch) ...[
          SizedBox(height: AppSpacing.sm),
          _buildVibeMatchRow(),
        ],
      ],
    );
  }

  Widget _buildStatsSection(
    BuildContext context, {
    required String handicap,
    required String homeCourse,
    required int friendsCount,
  }) {
    final shortCourse = homeCourse.length > 12
        ? '${homeCourse.substring(0, 10)}...'
        : homeCourse;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: FontAwesomeIcons.golfBall,
              value: handicap,
              label: 'Handicap',
              gradient: [AppColors.sunsetGold, AppColors.sunsetPeach],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard(
              context,
              icon: FontAwesomeIcons.mapMarkerAlt,
              value: shortCourse,
              label: 'Home Course',
              gradient: [AppColors.fairwayLight, AppColors.fairway],
              isText: true,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard(
              context,
              icon: FontAwesomeIcons.userFriends,
              value: friendsCount.toString(),
              label: 'Friends',
              gradient: [AppColors.sunsetPeach, AppColors.sunsetRose],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required List<Color> gradient,
    bool isText = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.fairway.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: isText
                  ? AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    )
                  : AppTypography.monoLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(
    BuildContext context,
    Map<String, dynamic> data, {
    required bool showVibeMatch,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AuthUserStreamWidget(
        builder: (context) {
          final currentUserRef = currentUserReference;
          final currentFriends = currentUserDocument?.friends.toList() ?? [];
          final currentRequests =
              currentUserDocument?.friendRequests.toList() ?? [];
          final theirRequests = data['friend_requests'];
          final theirRequestsList =
              theirRequests is List ? theirRequests : const [];
          final isFriend = currentFriends.contains(widget.userRef);
          final hasPending = currentRequests.contains(widget.userRef) ||
              (currentUserRef != null &&
                  theirRequestsList.contains(currentUserRef));

          String friendLabel;
          IconData friendIcon;
          List<Color> friendGradient;
          VoidCallback? friendAction;
          bool friendDisabled = false;

          if (isFriend) {
            friendLabel = 'Friends';
            friendIcon = Icons.check_circle_rounded;
            friendGradient = [AppColors.fairwayLight, AppColors.fairway];
            friendDisabled = true;
          } else if (hasPending) {
            friendLabel = 'Pending';
            friendIcon = Icons.schedule_rounded;
            friendGradient = [AppColors.cloud, AppColors.cloud];
            friendDisabled = true;
          } else {
            friendLabel = 'Add Friend';
            friendIcon = Icons.person_add_rounded;
            friendGradient = [AppColors.sunsetGold, AppColors.sunsetPeach];
            friendAction = () async {
              HapticFeedback.lightImpact();
              try {
                await context
                    .read<UserProvider>()
                    .sendFriendRequest(widget.userRef);
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Friend request sent!',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    duration: Duration(milliseconds: 1500),
                    backgroundColor: AppColors.fairwayDark,
                  ),
                );
              } catch (error) {
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Unable to send request.',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            };
          }

          final result = showVibeMatch ? _vibeMatchResult : null;
          final vibeScore = result == null ? null : result.myFitPercent.round();
          final vibeLabel =
              vibeScore == null ? 'Your Fit' : 'Your Fit $vibeScore%';
          final canOpenVibe = vibeScore != null;

          final cards = <Widget>[
            if (currentUserReference?.path != widget.userRef.path)
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Message',
                  gradient: [AppColors.fairwayLight, AppColors.fairway],
                  onTap: () => _openChatWithUser(widget.userRef),
                ),
              ),
            if (showVibeMatch)
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  icon: Icons.auto_awesome_rounded,
                  label: vibeLabel,
                  gradient: [AppColors.sunsetGold, AppColors.sunsetPeach],
                  onTap: canOpenVibe ? _openVibePage : null,
                  isDisabled: !canOpenVibe,
                ),
              ),
            if (currentUserReference?.path != widget.userRef.path)
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  icon: friendIcon,
                  label: friendLabel,
                  gradient: friendGradient,
                  onTap: friendAction,
                  isDisabled: friendDisabled,
                ),
              ),
          ];

          final spacedCards = <Widget>[];
          for (var i = 0; i < cards.length; i++) {
            if (i > 0) {
              spacedCards.add(SizedBox(width: AppSpacing.sm));
            }
            spacedCards.add(cards[i]);
          }

          return Row(children: spacedCards);
        },
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required List<Color> gradient,
    VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    final effectiveGradient =
        isDisabled ? [AppColors.cloud, AppColors.cloud] : gradient;
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cloud,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: effectiveGradient),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isDisabled
                    ? []
                    : [
                        BoxShadow(
                          color: effectiveGradient[0].withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
              ),
              child: Icon(
                icon,
                color: isDisabled ? AppColors.stone : Colors.white,
                size: 24,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isDisabled ? AppColors.stone : AppColors.slate,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGolfInfoSection(
    BuildContext context, {
    required String golfCanadaNumber,
    // email and phone are only passed when viewing the current user's own
    // profile (isSelf == true). They are intentionally omitted for other users
    // so contact info is never exposed on public profiles.
    String? email,
    String? phone,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Golf Info',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.onyx,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            context,
            icon: Icons.verified_rounded,
            iconColor: AppColors.fairway,
            label: 'Golf Canada #',
            value: golfCanadaNumber,
          ),
          if (email != null) ...[
            SizedBox(height: AppSpacing.sm),
            _buildInfoRow(
              context,
              icon: Icons.email_outlined,
              iconColor: AppColors.sunsetPeach,
              label: 'Email',
              value: email,
            ),
          ],
          if (phone != null) ...[
            SizedBox(height: AppSpacing.sm),
            _buildInfoRow(
              context,
              icon: Icons.phone_outlined,
              iconColor: AppColors.sunsetGold,
              label: 'Phone',
              value: phone,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cloud),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.stone,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onyx,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: StreamBuilder<UsersRecord?>(
        stream: context.read<ProfileProvider>().watchProfile(widget.userRef.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return Scaffold(
              key: scaffoldKey,
              backgroundColor: AppColors.fairwayDark,
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final userRecord = snapshot.data!;

          // Create data map for legacy _buildQuickActionsGrid method
          final data = <String, dynamic>{
            'friend_requests': userRecord.friendRequests,
          };
          final isSelf = currentUserReference?.path == widget.userRef.path;
          if (!isSelf) {
            // TODO(11-06): Migrate vibe matching to VibeMatchProvider
            // For now, fetch DocumentSnapshot separately for vibe matching
            widget.userRef.get().then((docSnapshot) {
              if (mounted) {
                _ensureVibeMatch(docSnapshot);
              }
            });
          }
          final photoUrl = userRecord.photoUrl.isNotEmpty
              ? userRecord.photoUrl
              : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';
          final firstName = userRecord.firstName;
          final lastName = userRecord.lastName;
          final displayName = userRecord.displayName.isNotEmpty
              ? userRecord.displayName
              : 'Golfer';
          _cachedUserName = displayName;
          _cachedUserPhotoUrl = photoUrl;
          // Contact info is private — only expose for the current user's own profile.
          // Do not read email/phone from another user's record.
          final phoneNumber = isSelf && currentPhoneNumber.isNotEmpty
              ? currentPhoneNumber
              : null;
          final email = isSelf && currentUserEmail.isNotEmpty
              ? currentUserEmail
              : null;
          final homeCourse = userRecord.homeCourse.isNotEmpty
              ? userRecord.homeCourse
              : 'Not set';
          final handicap = userRecord.handicap < 0
              ? '+${userRecord.handicap.abs()}'
              : userRecord.handicap.toString();
          final golfCanadaNumber = userRecord.golfCanadaNumber.isNotEmpty
              ? userRecord.golfCanadaNumber
              : 'Not set';

          final fullName = [firstName, lastName]
              .where((name) => name.trim().isNotEmpty)
              .join(' ')
              .trim();
          final displayTitle = fullName.isNotEmpty ? fullName : displayName;
          final handle = displayName.trim().isNotEmpty ? '@$displayName' : '';
          final friendsCount = userRecord.friends.length;

          return Scaffold(
            key: scaffoldKey,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              elevation: 0.0,
              leading: PremiumBackButton(
                onTap: () {
                  Navigator.of(context).maybePop();
                },
              ),
            ),
            body: FairwayBackgroundDark(
              showOrganic: true,
              showTexture: true,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).padding.top + 60,
                      ),
                      _buildHeroSection(
                        context,
                        photoUrl: photoUrl,
                        name: displayTitle.isNotEmpty ? displayTitle : 'Golfer',
                        handle: handle,
                        showVibeMatch: !isSelf,
                      ),
                      SizedBox(height: AppSpacing.xl),
                      _buildStatsSection(
                        context,
                        handicap: handicap,
                        homeCourse: homeCourse,
                        friendsCount: friendsCount,
                      ),
                      SizedBox(height: AppSpacing.xl),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.pure,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32.0),
                            topRight: Radius.circular(32.0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 30,
                              offset: Offset(0, -10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: AppSpacing.sm),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.cloud,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(height: AppSpacing.lg),
                            _buildQuickActionsGrid(
                              context,
                              data,
                              showVibeMatch: !isSelf,
                            ),
                            SizedBox(height: AppSpacing.md),
                            _buildGolfInfoSection(
                              context,
                              golfCanadaNumber: golfCanadaNumber,
                              email: email,
                              phone: phoneNumber,
                            ),
                            SizedBox(height: AppSpacing.xxxl),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
