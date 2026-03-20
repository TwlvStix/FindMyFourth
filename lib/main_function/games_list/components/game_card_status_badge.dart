import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';

/// Shared status badge for game cards (Cancelled / Expired / Owner / Joined).
///
/// Used by both [PremiumGameCard] and [UnifiedGameCard] to avoid duplication.
class GameCardStatusBadge extends StatelessWidget {
  const GameCardStatusBadge({
    super.key,
    required this.isCancelled,
    required this.isExpired,
    required this.isOwner,
    required this.isUserGame,
    this.expiredLabel = 'Expired',
  });

  final bool isCancelled;
  final bool isExpired;
  final bool isOwner;
  final bool isUserGame;

  /// Label shown for expired games. Defaults to 'Expired'.
  /// [UnifiedGameCard] passes 'Played' for its "My Games" context.
  final String expiredLabel;

  @override
  Widget build(BuildContext context) {
    if (isCancelled) {
      return _badge(
        color: AppColors.error,
        bgAlpha: 0.2,
        borderAlpha: 0.3,
        label: 'Cancelled',
      );
    }

    if (isExpired) {
      return _badge(
        color: AppColors.warning,
        bgAlpha: 0.2,
        label: expiredLabel,
      );
    }

    if (isOwner) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon: AppPhosphorIcons.owner,
              color: AppColors.pure,
              size: AppIconSize.xs,
            ),
            SizedBox(width: 4),
            Text(
              'Owner',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.pure,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (!isUserGame) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.stone.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            icon: AppPhosphorIcons.joined,
            color: AppColors.pure,
            size: AppIconSize.xs,
          ),
          SizedBox(width: 4),
          Text(
            'Joined',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.pure,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge({
    required Color color,
    required double bgAlpha,
    double? borderAlpha,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: borderAlpha != null
            ? Border.all(color: color.withValues(alpha: borderAlpha))
            : null,
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
