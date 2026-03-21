import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/backend/backend.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/navigation/nav_extensions.dart';
import '/core/navigation/transition_standards.dart';

/// Host information section showing avatar, name, and view profile button
class HostInfoSection extends StatelessWidget {
  const HostInfoSection({
    super.key,
    required this.hostUser,
  });

  final UsersRecord hostUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.whiteSubtle,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navyLight, AppColors.navy],
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: hostUser.photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: hostUser.photoUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 96,
                    memCacheHeight: 96,
                    fadeInDuration: Duration.zero,
                    errorWidget: (_, __, ___) => AppIcon(
                      icon: AppPhosphorIcons.profile,
                      color: AppColors.pure,
                      size: AppIconSize.md,
                    ),
                  )
                : AppIcon(
                    icon: AppPhosphorIcons.profile,
                    color: AppColors.pure,
                    size: AppIconSize.md,
                  ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hosted by',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  hostUser.displayName.isNotEmpty
                      ? hostUser.displayName
                      : 'Golfer',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.pure,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // View profile button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.pushProfileUser(
                userRef: hostUser.reference,
                transition: TransitionStandards.noTransition,
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.horizontalXxs,
                  AppIcon(
                    icon: AppPhosphorIcons.chevronRight,
                    color: AppColors.textPrimary,
                    size: AppIconSize.xs,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
