import 'dart:async';

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
import '/core/navigation/nav_extensions.dart';
import '/core/utils/formatting_utils.dart';
import '/profile/profile_user/components/profile_user_actions.dart';
import '/profile/profile_user/components/profile_user_content.dart';
import '/profile/profile_user/components/profile_user_state_scaffold.dart';
import '/profile/profile_user/controller/profile_user_controller.dart';
import '/providers/profile_provider.dart';

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
  final ProfileUserController _controller = ProfileUserController();
  late AnimationController _ringController;

  UsersRecord? _userRecord;
  bool _hasError = false;
  StreamSubscription<UsersRecord?>? _subscription;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _initSubscription();
  }

  @override
  void didUpdateWidget(ProfileUserFirebaseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userRef.path != oldWidget.userRef.path) {
      _subscription?.cancel();
      _controller.reset();
      setState(() {
        _userRecord = null;
        _hasError = false;
      });
      _initSubscription();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    _ringController.dispose();
    super.dispose();
  }

  void _initSubscription() {
    _subscription = context
        .read<ProfileProvider>()
        .watchProfile(widget.userRef.id)
        .listen(_onProfileReceived, onError: _onStreamError);
  }

  void _onProfileReceived(UsersRecord? record) {
    if (!mounted) return;
    setState(() {
      _userRecord = record;
      _hasError = false;
    });
    if (record != null) {
      final isSelf = currentUserReference?.path == widget.userRef.path;
      _controller.onProfileDataReceived(
        record,
        widget.userRef,
        isSelf: isSelf,
        myFriends: currentUserDocument?.friends.toList() ?? [],
      );
    }
  }

  void _onStreamError(Object error) {
    if (!mounted) return;
    setState(() => _hasError = true);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: _hasError
          ? _buildError()
          : _userRecord == null
              ? _buildLoading()
              : _buildContent(_userRecord!),
    );
  }

  Widget _buildError() {
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

  Widget _buildLoading() {
    return ProfileUserStateScaffold(
      scaffoldKey: scaffoldKey,
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildContent(UsersRecord userRecord) {
    final isSelf = currentUserReference?.path == widget.userRef.path;

    final photoUrl = userRecord.photoUrl.isNotEmpty
        ? userRecord.photoUrl
        : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';
    final firstName = userRecord.firstName;
    final lastName = userRecord.lastName;
    final displayName = userRecord.displayName.isNotEmpty
        ? userRecord.displayName
        : 'Golfer';

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

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return ProfileUserContent(
          scaffoldKey: scaffoldKey,
          photoUrl: photoUrl,
          displayTitle: displayTitle,
          handle: handle,
          age: calculateAge(userRecord.dateOfBirth) ?? 0,
          gender: userRecord.gender.isNotEmpty ? userRecord.gender : '',
          isSelf: isSelf,
          userRef: widget.userRef,
          friendRequests: userRecord.friendRequests,
          ringAnimation: _ringController,
          handicap: handicap,
          homeCourse: homeCourse,
          friendsCount: friendsCount,
          vibeMatchResult: _controller.vibeMatchResult,
          mutualFriends: _controller.mutualFriends,
          mutualFriendsLoaded: _controller.mutualFriendsLoaded,
          userRecord: userRecord,
          golfCanadaNumber: golfCanadaNumber,
          email: email,
          phone: phoneNumber,
          hometown: userRecord.hometownName.isNotEmpty
              ? userRecord.hometownName
              : null,
          onOpenVibe: () {
            final data = _controller.buildVibePageData(widget.userRef);
            if (data != null) {
              context.pushPremiumVibePage(
                userId: widget.userRef.id,
                data: data,
              );
            }
          },
          onMessageTap: () =>
              ProfileUserActions.openChatWithUser(context, widget.userRef),
          onMutualFriendsTap: () =>
              ProfileUserActions.showMutualFriendsSheet(
            context,
            mutualFriends: _controller.mutualFriends,
          ),
          onReport: isSelf
              ? null
              : () => ProfileUserActions.showReportSheet(
                    context,
                    reportedUid: widget.userRef.id,
                    displayName: displayName,
                  ),
          onBlock: isSelf
              ? null
              : () => ProfileUserActions.handleBlock(
                    context,
                    userRef: widget.userRef,
                    displayName: displayName,
                  ),
        );
      },
    );
  }
}
