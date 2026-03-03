import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

/// Hero section with animated avatar and photo change functionality.
///
/// Displays a profile photo with a rotating gradient ring animation
/// and buttons to change the photo.
class EditProfileHeroSection extends StatelessWidget {
  const EditProfileHeroSection({
    super.key,
    required this.photoUrl,
    required this.ringController,
    required this.onChangePhoto,
  });

  /// Current profile photo URL
  final String? photoUrl;

  /// Animation controller for the rotating gradient ring
  final AnimationController ringController;

  /// Callback when user taps to change their photo
  final VoidCallback onChangePhoto;

  String get _effectivePhotoUrl =>
      photoUrl?.isNotEmpty == true
          ? photoUrl!
          : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Animated Avatar with Rotating Gradient Ring
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),

            // Rotating gradient ring - member badge aesthetic
            AnimatedBuilder(
              animation: ringController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: ringController.value * 2 * 3.14159,
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
                        stops: const [0.0, 0.15, 0.35, 0.65, 0.85, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),

            // White border
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.pure,
              ),
            ),

            // Profile photo
            Container(
              width: 132,
              height: 132,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Image.network(
                _effectivePhotoUrl,
                fit: BoxFit.cover,
                semanticLabel: 'Your profile photo',
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

            // Edit photo button
            Positioned(
              bottom: 4,
              right: 4,
              child: Semantics(
                button: true,
                label: 'Edit profile photo',
                child: Material(
                  color: AppColors.transparent,
                  child: InkResponse(
                    radius: 30,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onChangePhoto();
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.green, AppColors.greenLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [AppElevation.glowGreen],
                      ),
                      child: Icon(
                        AppPhosphorIcons.camera,
                        color: AppColors.pure,
                        size: AppIconSize.md,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: AppSpacing.md),

        // Change Photo text
        Semantics(
          button: true,
          label: 'Change profile photo',
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onChangePhoto();
            },
            child: Text(
              'Change Photo',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.gold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
