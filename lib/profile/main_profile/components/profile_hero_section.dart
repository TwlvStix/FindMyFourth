import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/utils/app_util.dart';

/// Hero section of the main profile page.
///
/// Contains the animated avatar ring, profile photo, edit button,
/// user name, and metadata row (age, gender, username).
class ProfileHeroSection extends StatelessWidget {
  const ProfileHeroSection({
    super.key,
    required this.ringController,
    required this.onPhotoTap,
  });

  /// Animation controller for the rotating gradient ring.
  final AnimationController ringController;

  /// Called when the user taps the profile photo or edit button.
  final VoidCallback onPhotoTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Animated Avatar with Rotating Gradient Ring
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final avatarSize = (screenWidth * 0.45).clamp(120.0, 160.0);
            final ringSize = avatarSize * 0.925;
            final borderSize = avatarSize * 0.875;
            final photoSize = avatarSize * 0.825;
            final buttonSize = avatarSize * 0.25;
            final iconSize = avatarSize * 0.375;

            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow - gold with ambient intensity
                Container(
                  width: avatarSize,
                  height: avatarSize,
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

                // Rotating gradient ring - gold-centric for premium feel
                AnimatedBuilder(
                  animation: ringController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: ringController.value * 2 * 3.14159,
                      child: Container(
                        width: ringSize,
                        height: ringSize,
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

                // White border
                Container(
                  width: borderSize,
                  height: borderSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.pure,
                  ),
                ),

                // Profile photo
                AuthUserStreamWidget(
                  builder: (context) => Semantics(
                    button: true,
                    label: 'Change profile photo',
                    child: Material(
                      color: AppColors.transparent,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onPhotoTap();
                        },
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: photoSize,
                          height: photoSize,
                          child: Image.network(
                            valueOrDefault<String>(
                              currentUserPhoto,
                              'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                            ),
                            fit: BoxFit.cover,
                            semanticLabel: 'Your profile photo',
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: AppColors.sand,
                              child: AppIcon(
                                icon: AppPhosphorIcons.profile,
                                size: iconSize,
                                color: AppColors.stone,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Edit photo button
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Semantics(
                    button: true,
                    label: 'Edit photo',
                    child: Material(
                      color: AppColors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onPhotoTap();
                        },
                        customBorder: const CircleBorder(),
                        child: Ink(
                          width: buttonSize,
                          height: buttonSize,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.green, AppColors.greenLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [AppElevation.glowGreen],
                          ),
                          child: AppIcon(
                            icon: AppPhosphorIcons.camera,
                            color: AppColors.pure,
                            size: buttonSize * 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        SizedBox(height: AppSpacing.lg),

        // Name
        AuthUserStreamWidget(
          builder: (context) => Text(
            '${valueOrDefault(currentUserDocument?.firstName, '')} ${valueOrDefault(currentUserDocument?.lastName, '')}',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.pure,
            ),
          ),
        ),

        SizedBox(height: AppSpacing.xs),

        // Metadata row: age · gender · @username
        AuthUserStreamWidget(
          builder: (context) {
            final metadataParts = <String>[];

            // Calculate age from date of birth
            final dob = currentUserDocument?.dateOfBirth;
            if (dob != null) {
              final now = DateTime.now();
              int age = now.year - dob.year;
              if (now.month < dob.month ||
                  (now.month == dob.month && now.day < dob.day)) {
                age--;
              }
              if (age > 0) metadataParts.add(age.toString());
            }

            // Gender
            final gender = valueOrDefault(currentUserDocument?.gender, '');
            if (gender.isNotEmpty) metadataParts.add(gender);

            // Username
            final handle = currentUserDisplayName;
            if (handle.isNotEmpty) metadataParts.add('@$handle');

            final metadataLine = metadataParts.join(' · ');

            if (metadataLine.isEmpty) return SizedBox.shrink();

            return Text(
              metadataLine,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
            );
          },
        ),
      ],
    );
  }
}
