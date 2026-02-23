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
import '/core/navigation/app_router.dart';

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
        color: Colors.white.withValues(alpha: 0.05),
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
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: hostUser.photoUrl.isNotEmpty
                ? Image.network(
                    hostUser.photoUrl,
                    fit: BoxFit.cover,
                    cacheWidth: 96,
                    cacheHeight: 96,
                    errorBuilder: (_, __, ___) => AppIcon(
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
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  hostUser.displayName.isNotEmpty
                      ? hostUser.displayName
                      : 'Golfer',
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
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
              context.pushNamed(
                'ProfileUser',
                extra: <String, dynamic>{
                  'userRef': hostUser.reference,
                },
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  AppSpacing.horizontalXxs,
                  AppIcon(
                    icon: AppPhosphorIcons.chevronRight,
                    color: Colors.white.withValues(alpha: 0.8),
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
