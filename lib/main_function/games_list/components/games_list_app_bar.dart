import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/widgets/app_notification_badge_button.dart';

/// AppBar for the games list screen.
class GamesListAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GamesListAppBar({
    super.key,
    required this.hasActiveFilters,
    required this.activeFilterCount,
    required this.onFilterTap,
    required this.onNotificationTap,
  });

  final bool hasActiveFilters;
  final int activeFilterCount;
  final VoidCallback onFilterTap;
  final VoidCallback onNotificationTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.transparent,
      automaticallyImplyLeading: false,
      title: Text(
        'Find a Game',
        style: AppTypography.headlineMediumSans.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.xs),
          child: AppNotificationBadgeButton(
            onTap: onNotificationTap,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.sm),
          child: AppIconButton(
            borderColor: AppColors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 44.0,
            fillColor: AppColors.transparent,
            tooltip: 'Filter games',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                AppIcon(
                  icon: AppPhosphorIcons.filter,
                  color: AppColors.pure,
                  size: AppIconSize.md,
                ),
                if (hasActiveFilters)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          '$activeFilterCount',
                          style: AppTypography.labelMicro.copyWith(
                            color: AppColors.pure,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: onFilterTap,
          ),
        ),
      ],
      centerTitle: false,
      elevation: 0.0,
    );
  }
}
