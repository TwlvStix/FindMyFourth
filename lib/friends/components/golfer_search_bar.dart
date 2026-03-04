import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';

/// Slim, persistent search bar for the Golfers page.
/// Stays pinned at the top and filters all views (Discover, Requests, Friends).
class GolferSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onFilterPressed;
  final ValueChanged<String>? onChanged;
  final bool hasActiveFilters;
  final int activeFilterCount;

  const GolferSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.onFilterPressed,
    this.onChanged,
    this.hasActiveFilters = false,
    this.activeFilterCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.navyLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          AppSpacing.horizontalMdBox,
          AppIcon(
            icon: AppPhosphorIcons.search,
            color: AppColors.textMuted,
            size: AppIconSize.md,
          ),
          AppSpacing.horizontalSmBox,
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              cursorColor: AppColors.gold,
              decoration: InputDecoration(
                hintText: 'Search golfers...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          // Filter button
          GestureDetector(
            onTap: onFilterPressed,
            child: Container(
              width: 40,
              height: 40,
              margin: EdgeInsets.only(right: AppSpacing.xs - 2),
              decoration: BoxDecoration(
                color: AppColors.transparent,
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: AppIcon(
                      icon: AppPhosphorIcons.filter,
                      color: AppColors.textMuted,
                      size: AppIconSize.button,
                    ),
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      right: 2,
                      top: 2,
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
            ),
          ),
        ],
      ),
    );
  }
}
