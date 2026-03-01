import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/profile/profile_user/components/profile_avatar_friend_fab.dart';

class ProfileHeroSection extends StatelessWidget {
  const ProfileHeroSection({
    super.key,
    required this.photoUrl,
    required this.name,
    required this.handle,
    required this.age,
    required this.gender,
    required this.isSelf,
    required this.userRef,
    required this.friendRequests,
    required this.ringAnimation,
    required this.showVibeMatch,
  });

  final String photoUrl;
  final String name;
  final String handle;
  final int age;
  final String gender;
  final bool isSelf;
  final DocumentReference userRef;
  final List<dynamic> friendRequests;
  final Animation<double> ringAnimation;
  final bool showVibeMatch;

  @override
  Widget build(BuildContext context) {
    final metadataParts = <String>[];
    if (age > 0) metadataParts.add(age.toString());
    if (gender.isNotEmpty) metadataParts.add(gender);
    if (handle.isNotEmpty) metadataParts.add(handle);
    final metadataLine = metadataParts.join(' · ');

    return Column(
      children: [
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
                animation: ringAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: ringAnimation.value * 2 * 3.14159,
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
                decoration: BoxDecoration(shape: BoxShape.circle),
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
              if (!isSelf)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: ProfileAvatarFriendFab(
                    userRef: userRef,
                    friendRequests: friendRequests,
                  ),
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
        if (showVibeMatch) SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
