import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/main_function/games_list/models/quick_filter.dart';

/// Horizontal scrolling filter chips for quick game filtering.
///
/// Single-select chips that allow users to quickly filter the games list
/// by common criteria. Selected chip shows green fill; unselected shows
/// glass surface.
class QuickFilterChips extends StatelessWidget {
  const QuickFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.padding,
  });

  /// Currently selected filter
  final QuickFilter selectedFilter;

  /// Callback when filter selection changes
  final ValueChanged<QuickFilter> onFilterChanged;

  /// Optional padding around the chip row
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.sm,
          ),
      child: Row(
        children: QuickFilter.values.where((f) => f != QuickFilter.nearMe).map((filter) {
          final isSelected = filter == selectedFilter;
          return Padding(
            padding: EdgeInsets.only(
              right: filter != QuickFilter.values.last ? AppSpacing.sm : 0,
            ),
            child: _FilterChip(
              filter: filter,
              isSelected: isSelected,
              onTap: () => onFilterChanged(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  final QuickFilter filter;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: _isPressed
            ? (Matrix4.identity()..setEntry(0, 0, 0.96)..setEntry(1, 1, 0.96))
            : Matrix4.identity(),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppColors.green
              : AppColors.glassSurface,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: widget.isSelected
                ? AppColors.green
                : AppColors.glassBorder,
            width: 1.5,
          ),
        ),
        child: Text(
          widget.filter.displayLabel,
          style: AppTypography.labelMedium.copyWith(
            color: widget.isSelected
                ? AppColors.pure
                : AppColors.whiteStrong,
            fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
