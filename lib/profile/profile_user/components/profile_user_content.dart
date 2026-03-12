import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/schema/users_record.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/core/widgets/streak/streak_chip.dart';
import '/models/streak_profile.dart';
import '/profile/profile_user/components/golf_info_section.dart';
import '/profile/profile_user/components/profile_hero_section.dart';
import '/profile/profile_user/components/profile_quick_actions_grid.dart';
import '/profile/profile_user/components/profile_stats_section.dart';
import '/screens/trust/trust_profile_section.dart';
import '/services/vibe_matcher.dart';

class ProfileUserContent extends StatelessWidget {
  const ProfileUserContent({
    super.key,
    required this.scaffoldKey,
    required this.photoUrl,
    required this.displayTitle,
    required this.handle,
    required this.age,
    required this.gender,
    required this.isSelf,
    required this.userRef,
    required this.friendRequests,
    required this.ringAnimation,
    required this.handicap,
    required this.homeCourse,
    required this.friendsCount,
    required this.vibeMatchResult,
    required this.mutualFriends,
    required this.mutualFriendsLoaded,
    required this.userRecord,
    required this.golfCanadaNumber,
    required this.email,
    required this.phone,
    required this.hometown,
    required this.onOpenVibe,
    required this.onMessageTap,
    required this.onMutualFriendsTap,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final String photoUrl;
  final String displayTitle;
  final String handle;
  final int age;
  final String gender;
  final bool isSelf;
  final DocumentReference userRef;
  final List<dynamic> friendRequests;
  final Animation<double> ringAnimation;
  final String handicap;
  final String homeCourse;
  final int friendsCount;
  final VibeMatchResult? vibeMatchResult;
  final List<UsersRecord> mutualFriends;
  final bool mutualFriendsLoaded;
  final UsersRecord userRecord;
  final String golfCanadaNumber;
  final String? email;
  final String? phone;
  final String? hometown;
  final VoidCallback onOpenVibe;
  final VoidCallback onMessageTap;
  final VoidCallback onMutualFriendsTap;

  /// Build streak chip from user record data.
  Widget _buildStreakChip() {
    final profile = StreakProfile.fromUserRecord(userRecord);
    if (!profile.hasActiveStreak) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          StreakChipExtended(
            profile: profile,
            size: StreakChipSize.medium,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppColors.navyDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
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
                SizedBox(height: MediaQuery.of(context).padding.top + 60),
                ProfileHeroSection(
                  photoUrl: photoUrl,
                  name: displayTitle.isNotEmpty ? displayTitle : 'Golfer',
                  handle: handle,
                  age: age,
                  gender: gender,
                  isSelf: isSelf,
                  userRef: userRef,
                  friendRequests: friendRequests,
                  ringAnimation: ringAnimation,
                  showVibeMatch: !isSelf,
                ),
                SizedBox(height: AppSpacing.xl),
                ProfileStatsSection(
                  handicap: handicap,
                  homeCourse: homeCourse,
                  friendsCount: friendsCount,
                  isSelf: isSelf,
                  vibeMatchResult: vibeMatchResult,
                  onOpenVibe: onOpenVibe,
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
                        ProfileQuickActionsGrid(
                          isSelf: isSelf,
                          mutualFriends: mutualFriends,
                          mutualFriendsLoaded: mutualFriendsLoaded,
                          onMessageTap: onMessageTap,
                          onMutualFriendsTap: onMutualFriendsTap,
                        ),
                      TrustProfileSection(
                        user: userRecord,
                        isOwnProfile: isSelf,
                      ),
                      // Streak chip for public profiles
                      _buildStreakChip(),
                      GolfInfoSection(
                        golfCanadaNumber: golfCanadaNumber,
                        email: email,
                        phone: phone,
                        hometown: hometown,
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
  }
}
