import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/main_function/games_list/models/quick_filter.dart';

/// Sort bar showing game count and sort dropdown.
///
/// Displays the number of visible games and allows users to change
/// the sort order via a dropdown menu.
class GamesSortBar extends StatelessWidget {
  const GamesSortBar({
    super.key,
    required this.gameCount,
    required this.sortOption,
    required this.onSortChanged,
  });

  /// Number of games currently visible
  final int gameCount;

  /// Currently selected sort option
  final GameSortOption sortOption;

  /// Callback when sort option changes
  final ValueChanged<GameSortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Game count
          Text(
            '$gameCount game${gameCount == 1 ? '' : 's'}',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          // Sort dropdown
          _SortDropdown(
            sortOption: sortOption,
            onChanged: onSortChanged,
          ),
        ],
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({
    required this.sortOption,
    required this.onChanged,
  });

  final GameSortOption sortOption;
  final ValueChanged<GameSortOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<GameSortOption>(
      initialValue: sortOption,
      onSelected: onChanged,
      offset: const Offset(0, 36),
      color: AppColors.navy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.navyLight),
      ),
      itemBuilder: (context) => GameSortOption.values.map((option) {
        final isSelected = option == sortOption;
        return PopupMenuItem<GameSortOption>(
          value: option,
          padding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.navyLight : AppColors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Padding(
                    padding: EdgeInsets.only(right: AppSpacing.xs),
                    child: AppIcon(
                      icon: AppPhosphorIcons.check,
                      size: 16,
                      color: AppColors.whiteStrong,
                    ),
                  ),
                Text(
                  option.label,
                  style: AppTypography.bodySmall.copyWith(
                    color:
                        isSelected ? AppColors.whiteStrong : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sortOption.label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: AppSpacing.xxs),
          AppIcon(
            icon: AppPhosphorIcons.chevronDown,
            size: 12,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
