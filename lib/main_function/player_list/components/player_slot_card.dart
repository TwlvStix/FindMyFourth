import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';
import '/main_function/player_list/controller/player_list_controller.dart';

class PlayerSlotCard extends StatelessWidget {
  const PlayerSlotCard({
    super.key,
    required this.slotLabel,
    required this.playerData,
    required this.onTapAdd,
    required this.onTapRemove,
  });

  final String slotLabel;
  final PlayerSlotSelection? playerData;
  final VoidCallback onTapAdd;
  final VoidCallback onTapRemove;

  @override
  Widget build(BuildContext context) {
    if (playerData == null) {
      return GestureDetector(
        onTap: onTapAdd,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.navyLight,
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Row(
            children: [
              Container(
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
                child: AppIcon(
                  icon: AppPhosphorIcons.addPlayer,
                  color: AppColors.textMuted,
                  size: AppIconSize.md,
                ),
              ),
              AppSpacing.horizontalSmBox,
              Expanded(
                child: Text(
                  slotLabel,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.navyDark,
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Text(
                  'Add',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isGuest = playerData!.isGuest;
    final photoUrl = playerData!.photoUrl;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.navyLight.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
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
              child: (!isGuest && photoUrl != null && photoUrl.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      width: 48,
                      height: 48,
                      memCacheWidth: 144,
                      memCacheHeight: 144,
                      fit: BoxFit.cover,
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
          ),
          AppSpacing.horizontalSmBox,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  playerData!.name,
                  style: AppTypography.labelMedium.copyWith(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isGuest ? 'Guest' : 'Member',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTapRemove,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: AppIcon(
                icon: AppPhosphorIcons.close,
                color: AppColors.textPrimary,
                size: AppIconSize.button,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
