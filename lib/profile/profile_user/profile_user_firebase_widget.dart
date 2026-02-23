import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/motion/motion_helpers.dart';
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
import '/screens/trust/trust_profile_section.dart';

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

  // Mutual friends state
  List<UsersRecord> _mutualFriends = [];
  bool _mutualFriendsLoaded = true;
  String? _lastMutualFriendsProfileId;

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

  void _fetchMutualFriends(
    String profileUserId,
    List<DocumentReference> theirFriends,
    List<DocumentReference> myFriends,
  ) async {
    if (_lastMutualFriendsProfileId == profileUserId && _mutualFriendsLoaded) {
      return;
    }
    _lastMutualFriendsProfileId = profileUserId;

    final myUids = myFriends.map((r) => r.id).toSet();
    final theirUids = theirFriends.map((r) => r.id).toSet();
    final mutualUids = myUids.intersection(theirUids);

    if (mutualUids.isEmpty) {
      if (mounted) {
        setState(() {
          _mutualFriends = [];
          _mutualFriendsLoaded = true;
        });
      }
      return;
    }

    // Only show skeleton now that we know a Firestore fetch is needed
    if (mounted) {
      setState(() {
        _mutualFriendsLoaded = false;
      });
    }

    try {
      final futures = mutualUids.map((uid) => UsersRecord.getDocumentOnce(
            FirebaseFirestore.instance.collection('users').doc(uid),
          ));
      final results = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _mutualFriends = results;
          _mutualFriendsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _mutualFriends = [];
          _mutualFriendsLoaded = true;
        });
      }
    }
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
                    color: AppColors.gold.withValues(alpha:0.3),
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
                          AppColors.gold,
                          AppColors.goldLight,
                          AppColors.error,
                          AppColors.navyLight,
                          AppColors.gold,
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
                    size: AppIconSize.hero,
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
              color: AppColors.navy.withValues(alpha:0.4),
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              border: Border.all(
                color: AppColors.glassSurface,
              ),
            ),
            child: Text(
              handle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        if (showVibeMatch) ...[
          SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildStatsSection(
    BuildContext context, {
    required String handicap,
    required String homeCourse,
    required int friendsCount,
    required bool isSelf,
    required Map<String, dynamic> data,
  }) {
    final shortCourse = homeCourse.length > 12
        ? '${homeCourse.substring(0, 10)}...'
        : homeCourse;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: FontAwesomeIcons.golfBall,
              value: handicap,
              label: 'Handicap',
              gradient: [AppColors.gold, AppColors.goldLight],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard(
              context,
              icon: FontAwesomeIcons.mapMarkerAlt,
              value: shortCourse,
              label: 'Home Course',
              gradient: [AppColors.navyLight, AppColors.navy],
              isText: true,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: isSelf
                ? _buildStatCard(
                    context,
                    icon: FontAwesomeIcons.userFriends,
                    value: friendsCount.toString(),
                    label: 'Friends',
                    gradient: [AppColors.green, AppColors.greenLight],
                  )
                : _buildFriendStatusButton(context, data),
          ),
        ],
        ),
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
          color: AppColors.navy.withValues(alpha:0.3),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: AppColors.glassSurface,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Icon(
                icon,
                color: AppColors.pure,
                size: AppIconSize.xs,
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
                color: AppColors.glassTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showMutualFriendsSheet(BuildContext context) {
    final friends = _mutualFriends;
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (sheetContext) => MutualFriendsSheet(
        mutualFriends: friends,
        onFriendTap: (friend) {
          Navigator.of(sheetContext).pop();
          context.pushNamed(
            'ProfileUser',
            extra: <String, dynamic>{
              'userRef': friend.reference,
            },
          );
        },
      ),
    );
  }

  /// Friend status button for hero stats section (public profiles only)
  /// Wrapped in AuthUserStreamWidget to access current user's friend data
  Widget _buildFriendStatusButton(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    return AuthUserStreamWidget(
      builder: (context) {
        final userProvider = context.watch<UserProvider>();
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
                theirRequestsList.contains(currentUserRef)) ||
            userProvider.hasPendingOutgoingRequest(widget.userRef.id);

        IconData icon;
        String label;
        List<Color> gradientColors;
        List<BoxShadow>? boxShadow;
        VoidCallback? onTap;

        if (isFriend) {
          // Friends: premium checkmark with green gradient
          icon = Icons.check_rounded;
          label = 'FRIENDS';
          gradientColors = [AppColors.navyDark, AppColors.navy];
          boxShadow = [
            BoxShadow(
              color: AppColors.navy.withValues(alpha:0.4),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ];
        } else if (hasPending) {
          // Pending: premium hourglass with warm golden gradient
          icon = Icons.hourglass_top_rounded;
          label = 'PENDING';
          gradientColors = [AppColors.gold, AppColors.goldLight];
          boxShadow = [
            BoxShadow(
              color: AppColors.gold.withValues(alpha:0.3),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ];
        } else {
          // Add Friend: premium person-add with warm accent gradient
          icon = Icons.person_add_alt_1_rounded;
          label = 'ADD';
          gradientColors = [AppColors.gold, AppColors.goldLight];
          boxShadow = [
            BoxShadow(
              color: AppColors.gold.withValues(alpha:0.4),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ];
          onTap = () async {
            HapticFeedback.lightImpact();
            try {
              await context
                  .read<UserProvider>()
                  .sendFriendRequest(widget.userRef);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Friend request sent!',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  duration: Duration(milliseconds: 1500),
                  backgroundColor: AppColors.navyDark,
                ),
              );
            } catch (error) {
              if (!mounted) return;
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

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha:0.3),
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(
                color: AppColors.glassSurface,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: boxShadow,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.pure,
                    size: AppIconSize.md,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.glassTextSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Mutual friends action card for quick actions row (bottom sheet area)
  Widget _buildMutualFriendsActionCard(BuildContext context) {
    final friends = _mutualFriends;
    final hasAvatars = _mutualFriendsLoaded && friends.isNotEmpty;
    final label = !_mutualFriendsLoaded
        ? 'Mutual Friends'
        : friends.isEmpty
            ? 'Mutual Friends'
            : friends.length > 3
                ? '${friends.length} Mutual'
                : '${friends.length} Mutual';

    // Always use premium green gradient - never grey
    return GestureDetector(
      onTap: hasAvatars ? () => _showMutualFriendsSheet(context) : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: AppColors.cloud,
          ),
        ),
        child: Column(
          children: [
            if (hasAvatars)
              _buildOverlappingAvatarsLight(friends.take(3).toList())
            else
              // Premium green gradient icon when no avatars
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.navyLight, AppColors.navy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  boxShadow: [AppElevation.lg],
                ),
                child: Icon(
                  Icons.people_alt_rounded,
                  color: AppColors.pure,
                  size: AppIconSize.md,
                ),
              ),
            SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.slate,
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

  /// Light-themed overlapping avatars for bottom sheet quick actions area
  Widget _buildOverlappingAvatarsLight(List<UsersRecord> friends) {
    const avatarSize = 40.0;
    const overlap = 14.0;
    final count = friends.length.clamp(1, 3);
    final totalWidth = avatarSize + (count - 1) * (avatarSize - overlap);

    return SizedBox(
      width: totalWidth,
      height: 48, // Match other action card icon heights
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(count, (i) {
          final friend = friends[i];
          return Positioned(
            left: i * (avatarSize - overlap),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.sand, width: 2),
                color: AppColors.navy.withValues(alpha: 0.15),
                boxShadow: [AppElevation.sm],
              ),
              child: ClipOval(
                child: friend.photoUrl.isNotEmpty
                    ? Image.network(
                        friend.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person,
                          size: AppIconSize.button,
                          color: AppColors.navy,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: AppIconSize.button,
                        color: AppColors.navy,
                      ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuickActionsGrid(
    BuildContext context,
    Map<String, dynamic> data, {
    required bool showVibeMatch,
  }) {
    // Quick actions: Message | Golf Vibes | Mutual Friends
    // (Friend status has moved to hero stats section)
    final result = showVibeMatch ? _vibeMatchResult : null;
    final vibeScore = result == null ? null : result.myFitPercent.round();
    final vibeLabel =
        vibeScore == null ? 'Golf Vibes' : 'Your Fit $vibeScore%';
    final canOpenVibe = vibeScore != null;

    final cards = <Widget>[
      if (currentUserReference?.path != widget.userRef.path)
        Expanded(
          child: _buildQuickActionCard(
            context,
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Message',
            gradient: [AppColors.navyLight, AppColors.navy],
            onTap: () => _openChatWithUser(widget.userRef),
          ),
        ),
      if (showVibeMatch)
        Expanded(
          child: _buildQuickActionCard(
            context,
            icon: Icons.auto_awesome_rounded,
            label: vibeLabel,
            gradient: [AppColors.gold, AppColors.goldLight],
            onTap: canOpenVibe ? _openVibePage : null,
            isDisabled: !canOpenVibe,
          ),
        ),
      if (currentUserReference?.path != widget.userRef.path)
        Expanded(
          child: _buildMutualFriendsActionCard(context),
        ),
    ];

    final spacedCards = <Widget>[];
    for (var i = 0; i < cards.length; i++) {
      if (i > 0) {
        spacedCards.add(SizedBox(width: AppSpacing.sm));
      }
      spacedCards.add(cards[i]);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(children: spacedCards),
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
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
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
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                boxShadow: isDisabled
                    ? []
                    : [
                        BoxShadow(
                          color: effectiveGradient[0].withValues(alpha:0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
              ),
              child: Icon(
                icon,
                color: isDisabled ? AppColors.stone : AppColors.pure,
                size: AppIconSize.md,
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
            style: AppTypography.titleLarge.copyWith(
              fontSize: 18,
              color: AppColors.onyx,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            context,
            icon: Icons.verified_rounded,
            iconColor: AppColors.navy,
            label: 'Golf Canada #',
            value: golfCanadaNumber,
          ),
          if (email != null) ...[
            SizedBox(height: AppSpacing.sm),
            _buildInfoRow(
              context,
              icon: Icons.email_outlined,
              iconColor: AppColors.goldLight,
              label: 'Email',
              value: email,
            ),
          ],
          if (phone != null) ...[
            SizedBox(height: AppSpacing.sm),
            _buildInfoRow(
              context,
              icon: Icons.phone_outlined,
              iconColor: AppColors.gold,
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
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.cloud),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: AppIconSize.button),
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
          // Handle error state
          if (snapshot.hasError) {
            return Scaffold(
              key: scaffoldKey,
              backgroundColor: AppColors.navyDark,
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: PremiumBackButton(onTap: () => Navigator.of(context).pop()),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, color: AppColors.glassTextTertiary, size: AppIconSize.xxl),
                              SizedBox(height: AppSpacing.md),
                              Text(
                                'Unable to load profile',
                                style: AppTypography.titleMedium.copyWith(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: AppSpacing.xs),
                              Text(
                                'Please try again later',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.glassTextTertiary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Handle loading state
          if (!snapshot.hasData || snapshot.data == null) {
            return Scaffold(
              key: scaffoldKey,
              backgroundColor: AppColors.navyDark,
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: PremiumBackButton(onTap: () => Navigator.of(context).pop()),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ],
                ),
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _fetchMutualFriends(
                  widget.userRef.id,
                  userRecord.friends,
                  currentUserDocument?.friends.toList() ?? [],
                );
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
                        isSelf: isSelf,
                        data: data,
                      ),
                      SizedBox(height: AppSpacing.xl),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.pure,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(AppBorderRadius.xxl),
                            topRight: Radius.circular(AppBorderRadius.xxl),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.overlayDark,
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
                                borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
                              ),
                            ),
                            SizedBox(height: AppSpacing.lg),
                            _buildQuickActionsGrid(
                              context,
                              data,
                              showVibeMatch: !isSelf,
                            ),
                            TrustProfileSection(
                              user: userRecord,
                              isOwnProfile: isSelf,
                            ),
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

class MutualFriendsSheet extends StatelessWidget {
  const MutualFriendsSheet({
    super.key,
    required this.mutualFriends,
    required this.onFriendTap,
  });

  final List<UsersRecord> mutualFriends;
  final void Function(UsersRecord friend) onFriendTap;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppBorderRadius.xxl),
          topRight: Radius.circular(AppBorderRadius.xxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cloud,
              borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  'Mutual Friends',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.onyx,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  ),
                  child: Text(
                    mutualFriends.length > 3
                        ? '3+'
                        : '${mutualFriends.length}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          // Friend list
          Flexible(
            child: ListView.separated(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.xxxl,
              ),
              shrinkWrap: true,
              itemCount: mutualFriends.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: AppColors.cloud,
              ),
              itemBuilder: (context, index) {
                final friend = mutualFriends[index];
                final handicapStr = friend.handicap < 0
                    ? '+${friend.handicap.abs()}'
                    : friend.handicap.toString();
                final displayName = friend.displayName.isNotEmpty
                    ? friend.displayName
                    : 'Golfer';
                final fullName = [friend.firstName, friend.lastName]
                    .where((n) => n.trim().isNotEmpty)
                    .join(' ')
                    .trim();
                final title = fullName.isNotEmpty ? fullName : displayName;

                return GestureDetector(
                  onTap: () => onFriendTap(friend),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.navy.withValues(alpha:0.15),
                          ),
                          child: ClipOval(
                            child: friend.photoUrl.isNotEmpty
                                ? Image.network(
                                    friend.photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.person,
                                      color: AppColors.navy,
                                      size: AppIconSize.md,
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    color: AppColors.navy,
                                    size: AppIconSize.md,
                                  ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        // Name & username
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.onyx,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (displayName.isNotEmpty)
                                Text(
                                  '@$displayName',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.stone,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        // Handicap badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha:0.12),
                            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                          ),
                          child: Text(
                            handicapStr,
                            style: AppTypography.monoSmall.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.stone,
                          size: AppIconSize.button,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
