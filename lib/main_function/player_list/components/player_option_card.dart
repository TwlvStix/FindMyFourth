import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';

class PlayerOptionCard extends StatelessWidget {
  const PlayerOptionCard({
    super.key,
    required this.name,
    required this.isGuest,
    this.subtitle,
    this.photoUrl,
    this.onTap,
  });

  final String name;
  final bool isGuest;
  final String? subtitle;
  final String? photoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: EdgeInsets.only(bottom: AppSpacing.xs),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.navyLight,
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _Avatar(
                isGuest: isGuest,
                photoUrl: photoUrl,
              ),
              AppSpacing.horizontalSmBox,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isDisabled)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: AppIcon(
                    icon: AppPhosphorIcons.add,
                    color: AppColors.textPrimary,
                    size: AppIconSize.button,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.isGuest,
    required this.photoUrl,
  });

  final bool isGuest;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        child: (!isGuest && photoUrl != null && photoUrl!.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: photoUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                memCacheWidth: 144,
                memCacheHeight: 144,
                fadeInDuration: Duration.zero,
                errorWidget: (_, __, ___) => AppIcon(
                  icon: AppPhosphorIcons.profile,
                  color: AppColors.textMuted,
                  size: AppIconSize.md,
                ),
              )
            : AppIcon(
                icon: AppPhosphorIcons.profile,
                color: AppColors.textMuted,
                size: AppIconSize.md,
              ),
      ),
    );
  }
}
