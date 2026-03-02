import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';

/// Quick actions grid on the main profile page.
///
/// Contains Edit Profile and Golf Vibes action cards.
/// Adapts to screen width with 2-column or 3-column layout.
class ProfileQuickActionsGrid extends StatelessWidget {
  const ProfileQuickActionsGrid({
    super.key,
    required this.onEditProfile,
    required this.onGolfVibes,
  });

  /// Called when the user taps "Edit Profile".
  final VoidCallback onEditProfile;

  /// Called when the user taps "Golf Vibes".
  final VoidCallback onGolfVibes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          // Use 2 columns for small screens, 3 for larger screens
          final useCompactLayout = screenWidth < 400;

          if (useCompactLayout) {
            // 2-column layout for small screens
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: AppPhosphorIcons.editProfile,
                        label: 'Edit Profile',
                        gradient: [AppColors.navyLight, AppColors.navy],
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onEditProfile();
                        },
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: AppPhosphorIcons.golfVibes,
                        label: 'Golf Vibes',
                        gradient: [AppColors.gold, AppColors.goldLight],
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onGolfVibes();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            // 3-column layout for larger screens
            return Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: AppPhosphorIcons.editProfile,
                    label: 'Edit Profile',
                    gradient: [AppColors.navyLight, AppColors.navy],
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onEditProfile();
                    },
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: AppPhosphorIcons.golfVibes,
                    label: 'Golf Vibes',
                    gradient: [AppColors.green, AppColors.greenLight],
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onGolfVibes();
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildQuickActionCard({
    required PhosphorIconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: AppColors.navyLight,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: AppIconSize.iconBoxLg,
                  height: AppIconSize.iconBoxLg,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: AppIcon(
                    icon: icon,
                    color: AppColors.pure,
                    size: AppIconSize.button,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: AppTypography.medium,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
