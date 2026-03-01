import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_stat_card.dart';
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
            UsersRecord.collection.doc(uid),
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
    required int age,
    required String gender,
    required bool isSelf,
    required Map<String, dynamic> data,
    required bool showVibeMatch,
  }) {
    // Build inline metadata string: "age · gender · @handle"
    final metadataParts = <String>[];
    if (age > 0) metadataParts.add(age.toString());
    if (gender.isNotEmpty) metadataParts.add(gender);
    if (handle.isNotEmpty) metadataParts.add(handle);
    final metadataLine = metadataParts.join(' · ');

    return Column(
      children: [
        // Avatar with optional friend FAB
        SizedBox(
          width: 170,
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 1,
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
                            AppColors.navy,
                            AppColors.gold.withValues(alpha: 0.9),
                            AppColors.gold,
                            AppColors.goldLight,
                            AppColors.gold.withValues(alpha: 0.9),
                            AppColors.navy,
                          ],
                          stops: [0.0, 0.15, 0.35, 0.65, 0.85, 1.0],
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
                      AppPhosphorIcons.profile,
                      size: AppIconSize.hero,
                      color: AppColors.stone,
                    ),
                  ),
                ),
              ),
              // Friend FAB at bottom-right (public profiles only)
              if (!isSelf)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _buildAvatarFriendFab(context, data),
                ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Text(
          name,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (metadataLine.isNotEmpty) ...[
          SizedBox(height: AppSpacing.xs),
          Text(
            metadataLine,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
        ],
        if (showVibeMatch) ...[
          SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  /// Calculate age from date of birth
  int? _calculateAge(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  /// Compact circular FAB for friend actions on avatar
  /// Positioned at bottom-right of avatar, only shown on public profiles
  Widget _buildAvatarFriendFab(
      BuildContext context, Map<String, dynamic> data) {
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
        List<Color> gradientColors;
        VoidCallback? onTap;

        if (isFriend) {
          icon = AppPhosphorIcons.check;
          gradientColors = [AppColors.navyDark, AppColors.navy];
        } else if (hasPending) {
          icon = AppPhosphorIcons.pending;
          gradientColors = [AppColors.gold, AppColors.goldLight];
        } else {
          icon = AppPhosphorIcons.addPlayer;
          gradientColors = [AppColors.gold, AppColors.goldLight];
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
                      color: AppColors.textPrimary,
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
                      color: AppColors.textPrimary,
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.navyDark,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: AppColors.pure,
              size: AppIconSize.button,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection(
    BuildContext context, {
    required String handicap,
    required String homeCourse,
    required int friendsCount,
    required bool isSelf,
  }) {
    // Get vibe match score for public profiles
    final result = !isSelf ? _vibeMatchResult : null;
    final vibeScore = result == null ? null : result.myFitPercent.round();
    final canOpenVibe = vibeScore != null;

    // Dynamic color based on vibe score: green (80+), gold (50-79), muted (<50)
    Color vibeColor;
    if (vibeScore != null) {
      if (vibeScore >= 80) {
        vibeColor = AppColors.green;
      } else if (vibeScore >= 50) {
        vibeColor = AppColors.gold;
      } else {
        vibeColor = AppColors.textSecondary;
      }
    } else {
      vibeColor = AppColors.textPrimary; // loading state
    }

    return Column(
      children: [
        // Two-card row: Handicap + Your Fit (or Friends for own profile)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handicap card
                Expanded(
                  child: AppStatCard(
                    icon: AppPhosphorIcons.golf,
                    value: handicap,
                    label: 'Handicap',
                    variant: AppStatCardVariant.glass,
                    iconGradient: [AppColors.gold, AppColors.goldLight],
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                // Your Fit (public) or Friends (own profile)
                Expanded(
                  child: isSelf
                      ? AppStatCard(
                          icon: AppPhosphorIcons.users,
                          value: friendsCount.toString(),
                          label: 'Friends',
                          variant: AppStatCardVariant.glass,
                          iconGradient: [AppColors.gold, AppColors.goldLight],
                        )
                      : GestureDetector(
                          onTap: canOpenVibe ? _openVibePage : null,
                          child: AppStatCard(
                            icon: AppPhosphorIcons.sparkle,
                            value: vibeScore != null ? '$vibeScore%' : '...',
                            label: 'Your Fit',
                            variant: AppStatCardVariant.glass,
                            iconGradient: [AppColors.gold, AppColors.goldLight],
                            valueStyle: AppTypography.monoLarge.copyWith(
                              color: vibeColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        // Home course text row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppPhosphorIcons.homeCourse,
              color: AppColors.textSecondary,
              size: AppIconSize.sm,
            ),
            SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                homeCourse,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
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
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: AppColors.navyLight,
          ),
        ),
        child: Column(
          children: [
            if (hasAvatars)
              _buildOverlappingAvatarsDark(friends.take(3).toList())
            else
              // Premium green gradient icon when no avatars
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.navyLight, AppColors.navy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  boxShadow: [AppElevation.md],
                ),
                child: Icon(
                  AppPhosphorIcons.people,
                  color: AppColors.pure,
                  size: AppIconSize.button,
                ),
              ),
            SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
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

  /// Dark-themed overlapping avatars for bottom sheet quick actions area
  Widget _buildOverlappingAvatarsDark(List<UsersRecord> friends) {
    const avatarSize = 36.0;
    const overlap = 12.0;
    final count = friends.length.clamp(1, 3);
    final totalWidth = avatarSize + (count - 1) * (avatarSize - overlap);

    return SizedBox(
      width: totalWidth,
      height: 40, // Match other action card icon heights
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
                border: Border.all(color: AppColors.navy, width: 2),
                color: AppColors.navyLight,
                boxShadow: [AppElevation.sm],
              ),
              child: ClipOval(
                child: friend.photoUrl.isNotEmpty
                    ? Image.network(
                        friend.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          AppPhosphorIcons.profile,
                          size: AppIconSize.button,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : Icon(
                        AppPhosphorIcons.profile,
                        size: AppIconSize.button,
                        color: AppColors.textSecondary,
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
    Map<String, dynamic> data,
  ) {
    // Quick actions: Message | Mutual Friends only
    // Your Fit has moved to the stats section
    final cards = <Widget>[
      if (currentUserReference?.path != widget.userRef.path)
        Expanded(
          child: _buildQuickActionCard(
            context,
            icon: AppPhosphorIcons.chat,
            label: 'Message',
            gradient: [AppColors.navyLight, AppColors.navy],
            onTap: () => _openChatWithUser(widget.userRef),
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
    Color? labelColor,
    Widget? richLabel,
  }) {
    final effectiveGradient =
        isDisabled ? [AppColors.navyLight, AppColors.navyLight] : gradient;
    final effectiveLabelColor = isDisabled
        ? AppColors.textMuted
        : (labelColor ?? AppColors.textSecondary);
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: AppColors.navyLight,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: effectiveGradient),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                boxShadow: isDisabled
                    ? []
                    : [
                        BoxShadow(
                          color: effectiveGradient[0].withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
              ),
              child: Icon(
                icon,
                color: isDisabled ? AppColors.textMuted : AppColors.pure,
                size: AppIconSize.button,
              ),
            ),
            SizedBox(height: 4),
            if (richLabel != null)
              richLabel
            else
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: effectiveLabelColor,
                  fontWeight: FontWeight.w600,
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
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            context,
            icon: AppPhosphorIcons.verified,
            label: 'Golf Canada #',
            value: golfCanadaNumber,
          ),
          if (email != null) ...[
            SizedBox(height: AppSpacing.lg),
            _buildInfoRow(
              context,
              icon: AppPhosphorIcons.email,
              label: 'Email',
              value: email,
            ),
          ],
          if (phone != null) ...[
            SizedBox(height: AppSpacing.lg),
            _buildInfoRow(
              context,
              icon: AppPhosphorIcons.phone,
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
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.navyLight),
      ),
      child: Row(
        children: [
          // Just icon, no container background
          Icon(icon, color: AppColors.textMuted, size: AppIconSize.md),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
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
                        child: PremiumBackButton(
                            onTap: () => Navigator.of(context).pop()),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(AppPhosphorIcons.error,
                                  color: AppColors.glassTextTertiary,
                                  size: AppIconSize.xxl),
                              SizedBox(height: AppSpacing.md),
                              Text(
                                'Unable to load profile',
                                style: AppTypography.titleMedium
                                    .copyWith(color: AppColors.textPrimary),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: AppSpacing.xs),
                              Text(
                                'Please try again later',
                                style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.glassTextTertiary),
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
                        child: PremiumBackButton(
                            onTap: () => Navigator.of(context).pop()),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.textPrimary),
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
          final email =
              isSelf && currentUserEmail.isNotEmpty ? currentUserEmail : null;
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
                        age: _calculateAge(userRecord.dateOfBirth) ?? 0,
                        gender: userRecord.gender.isNotEmpty
                            ? userRecord.gender
                            : '',
                        isSelf: isSelf,
                        data: data,
                        showVibeMatch: !isSelf,
                      ),
                      SizedBox(height: AppSpacing.xl),
                      _buildStatsSection(
                        context,
                        handicap: handicap,
                        homeCourse: homeCourse,
                        friendsCount: friendsCount,
                        isSelf: isSelf,
                      ),
                      SizedBox(height: AppSpacing.xl),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.navyDark,
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
                                color: AppColors.navyLight,
                                borderRadius:
                                    BorderRadius.circular(AppBorderRadius.xxs),
                              ),
                            ),
                            SizedBox(height: AppSpacing.lg),
                            if (!isSelf)
                              _buildQuickActionsGrid(
                                context,
                                data,
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
        color: AppColors.navyDark,
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
              color: AppColors.greenLight,
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
                    color: AppColors.pure,
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
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  ),
                  child: Text(
                    mutualFriends.length > 3 ? '3+' : '${mutualFriends.length}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
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
                color: AppColors.navyLight,
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
                            color: AppColors.navy,
                          ),
                          child: ClipOval(
                            child: friend.photoUrl.isNotEmpty
                                ? Image.network(
                                    friend.photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      AppPhosphorIcons.profile,
                                      color: AppColors.textSecondary,
                                      size: AppIconSize.md,
                                    ),
                                  )
                                : Icon(
                                    AppPhosphorIcons.profile,
                                    color: AppColors.textSecondary,
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
                                  color: AppColors.pure,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (displayName.isNotEmpty)
                                Text(
                                  '@$displayName',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
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
                            color: AppColors.gold.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.sm),
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
                          AppPhosphorIcons.chevronRight,
                          color: AppColors.textSecondary,
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
