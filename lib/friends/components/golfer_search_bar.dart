import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';

/// Slim, persistent search bar for the Golfers page.
/// Stays pinned at the top and filters all views (Discover, Requests, Friends).
class GolferSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onFilterPressed;
  final ValueChanged<String>? onChanged;
  final bool hasActiveFilters;

  const GolferSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.onFilterPressed,
    this.onChanged,
    this.hasActiveFilters = false,
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
          Icon(
            Icons.search_rounded,
            color: AppColors.pure.withValues(alpha: 0.5),
            size: AppIconSize.md,
          ),
          AppSpacing.horizontalSmBox,
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              cursorColor: AppColors.gold,
              decoration: InputDecoration(
                hintText: 'Search golfers...',
                hintStyle: AppTypography.bodySmall.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.4),
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
                color: hasActiveFilters
                    ? AppColors.navyLight.withValues(alpha: 0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: hasActiveFilters
                    ? AppColors.pure.withValues(alpha: 0.9)
                    : AppColors.pure.withValues(alpha: 0.5),
                size: AppIconSize.button,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
