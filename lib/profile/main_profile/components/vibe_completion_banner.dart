import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/models/vibe_profile.dart';

/// Banner prompting user to complete their vibe profile.
///
/// Only visible when the user's vibe profile is incomplete.
/// Self-contained with [AuthUserStreamWidget] for reactive user data.
class VibeCompletionBanner extends StatelessWidget {
  const VibeCompletionBanner({
    super.key,
    required this.onTap,
  });

  /// Called when the user taps the banner.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AuthUserStreamWidget(
      builder: (context) {
        final profile = VibeProfile.fromFirestore(
          Map<String, dynamic>.from(
            currentUserDocument?.vibeProfile ?? const <String, dynamic>{},
          ),
        );
        if (profile.isComplete) {
          return SizedBox.shrink();
        }
        return Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Semantics(
            button: true,
            label: 'Complete your vibe profile',
            child: Material(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTap();
                },
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: AppIconSize.iconBoxXl,
                        height: AppIconSize.iconBoxXl,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.gold, AppColors.goldLight],
                          ),
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.md),
                        ),
                        child: AppIcon(
                          icon: AppPhosphorIcons.golfVibes,
                          color: AppColors.pure,
                          size: AppIconSize.md,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete Your Vibe Profile',
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xxs),
                            Text(
                              'Help us match you with the right golfers',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppIcon(
                        icon: AppPhosphorIcons.chevronRight,
                        color: AppColors.gold,
                        size: AppIconSize.button,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
