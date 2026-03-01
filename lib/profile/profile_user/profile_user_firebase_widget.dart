import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/users_record.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/motion_helpers.dart';
import '/core/navigation/nav_extensions.dart';
import '/core/navigation/transition_standards.dart';
import '/core/utils/state_update.dart';
import '/models/vibe_profile.dart';
import '/profile/profile_user/components/mutual_friends_sheet.dart';
import '/profile/profile_user/components/profile_user_content.dart';
import '/profile/profile_user/components/profile_user_state_scaffold.dart';
import '/profile/profile_user/controller/profile_user_controller.dart';
import '/providers/chat_provider.dart';
import '/providers/profile_provider.dart';
import '/services/vibe_match_explanation.dart';
import '/services/vibe_matcher.dart';
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
  final ProfileUserController _profileUserController = ProfileUserController();
  late AnimationController _ringController;

  VibeMatchResult? _vibeMatchResult;
  VibeProfile? _myVibes;
  VibeProfile? _theirVibes;
  bool _isVibeMatchLoading = false;
  String? _vibeMatchUserId;
  String _cachedUserName = '';
  String _cachedUserPhotoUrl = '';

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
      if (!mounted) return;
      context
          .read<ChatProvider>()
          .logError('createOrGetDirectChat failed', error, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start chat. Please try again.'),
        ),
      );
    }
  }

  void _openChat(String chatId) {
    context.pushChatDetails(chatId: chatId);
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

  Future<void> _fetchMutualFriends(
    String profileUserId,
    List<DocumentReference> theirFriends,
    List<DocumentReference> myFriends,
  ) async {
    if (_lastMutualFriendsProfileId == profileUserId && _mutualFriendsLoaded) {
      return;
    }
    _lastMutualFriendsProfileId = profileUserId;

    final result = await _profileUserController.fetchMutualFriends(
      theirFriends: theirFriends,
      myFriends: myFriends,
      onRemoteFetchStart: () {
        if (!mounted) return;
        updateState(this, () {
          _mutualFriendsLoaded = false;
        });
      },
    );

    if (!mounted) {
      return;
    }

    updateState(this, () {
      _mutualFriends = result.friends;
      _mutualFriendsLoaded = result.loaded;
    });
  }

  void _ensureVibeMatch(DocumentSnapshot snapshot) {
    final shouldLoad = _profileUserController.shouldLoadVibeMatch(
      isLoading: _isVibeMatchLoading,
      existingMatch: _vibeMatchResult,
      loadedUserId: _vibeMatchUserId,
      snapshot: snapshot,
    );
    if (!shouldLoad) {
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
    updateState(this, () {
      _isVibeMatchLoading = true;
      _vibeMatchResult = null;
    });

    final result = await _profileUserController.loadVibeMatch(snapshot);

    if (!mounted) {
      return;
    }

    updateState(this, () {
      _myVibes = result.myVibes;
      _theirVibes = result.theirVibes;
      _vibeMatchResult = result.match;
      _vibeMatchUserId = result.profileId;
      _isVibeMatchLoading = result.isLoading;
    });
  }

  void _openVibePage() {
    final result = _vibeMatchResult;
    final myVibes = _myVibes;
    final theirVibes = _theirVibes;
    if (result == null || myVibes == null || theirVibes == null) {
      return;
    }

    final explanation = buildMatchExplanation(
      matchResult: result,
      a: myVibes,
      b: theirVibes,
    );

    final myArchetype = VibeArchetypes.classifyProfile(myVibes);
    final theirArchetype = VibeArchetypes.classifyProfile(theirVibes);

    final userName = _cachedUserName.isNotEmpty ? _cachedUserName : 'Golfer';
    final userPhotoUrl = _cachedUserPhotoUrl.isNotEmpty
        ? _cachedUserPhotoUrl
        : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';

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

    context.pushPremiumVibePage(
      userId: widget.userRef.id,
      data: pageData,
    );
  }

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
          context.pushProfileUser(
            userRef: friend.reference,
            transition: TransitionStandards.noTransition,
          );
        },
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
          if (snapshot.hasError) {
            return ProfileUserStateScaffold(
              scaffoldKey: scaffoldKey,
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppPhosphorIcons.error,
                        color: AppColors.glassTextTertiary,
                        size: AppIconSize.xxl,
                      ),
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
                          color: AppColors.glassTextTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return ProfileUserStateScaffold(
              scaffoldKey: scaffoldKey,
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }

          final userRecord = snapshot.data!;
          final isSelf = currentUserReference?.path == widget.userRef.path;

          if (!isSelf) {
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

          return ProfileUserContent(
            scaffoldKey: scaffoldKey,
            photoUrl: photoUrl,
            displayTitle: displayTitle,
            handle: handle,
            age: _calculateAge(userRecord.dateOfBirth) ?? 0,
            gender: userRecord.gender.isNotEmpty ? userRecord.gender : '',
            isSelf: isSelf,
            userRef: widget.userRef,
            friendRequests: userRecord.friendRequests,
            ringAnimation: _ringController,
            handicap: handicap,
            homeCourse: homeCourse,
            friendsCount: friendsCount,
            vibeMatchResult: _vibeMatchResult,
            mutualFriends: _mutualFriends,
            mutualFriendsLoaded: _mutualFriendsLoaded,
            userRecord: userRecord,
            golfCanadaNumber: golfCanadaNumber,
            email: email,
            phone: phoneNumber,
            onOpenVibe: _openVibePage,
            onMessageTap: () => _openChatWithUser(widget.userRef),
            onMutualFriendsTap: () => _showMutualFriendsSheet(context),
          );
        },
      ),
    );
  }
}
