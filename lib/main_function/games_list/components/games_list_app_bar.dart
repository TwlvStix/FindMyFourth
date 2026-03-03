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
    required this.onFilterTap,
    required this.onNotificationTap,
  });

  final bool hasActiveFilters;
  final VoidCallback onFilterTap;
  final VoidCallback onNotificationTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Text(
        'Game List',
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
            borderColor: hasActiveFilters
                ? AppColors.navy.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: 30.0,
            borderWidth: hasActiveFilters ? 2.0 : 1.0,
            buttonSize: 44.0,
            fillColor: hasActiveFilters
                ? AppColors.navy.withValues(alpha: 0.12)
                : Colors.transparent,
            tooltip: 'Filter games',
            icon: AppIcon(
              icon: AppPhosphorIcons.filter,
              color: hasActiveFilters ? AppColors.navy : AppColors.pure,
              size: AppIconSize.md,
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
