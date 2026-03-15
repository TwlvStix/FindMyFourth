import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/main_function/games_list/models/quick_filter.dart';

/// Horizontal scrolling filter chips for quick game filtering.
///
/// Single-select chips that allow users to quickly filter the games list
/// by common criteria. Selected chip shows green fill; unselected shows
/// glass surface.
class QuickFilterChips extends StatefulWidget {
  const QuickFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.padding,
    this.trailing,
  });

  /// Currently selected filter
  final QuickFilter selectedFilter;

  /// Callback when filter selection changes
  final ValueChanged<QuickFilter> onFilterChanged;

  /// Optional padding around the chip row
  final EdgeInsetsGeometry? padding;

  /// Optional trailing widget appended after the filter chips (e.g. NearMeChip)
  final Widget? trailing;

  @override
  State<QuickFilterChips> createState() => _QuickFilterChipsState();
}

class _QuickFilterChipsState extends State<QuickFilterChips> {
  final ScrollController _scrollController = ScrollController();
  static bool _hasAnimated = false;
  bool _showScrollIndicator = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (!_hasAnimated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateScrollHint();
      });
    }
  }

  void _onScroll() {
    if (_showScrollIndicator && _scrollController.offset > 10) {
      setState(() => _showScrollIndicator = false);
    }
  }

  Future<void> _animateScrollHint() async {
    if (!mounted || _hasAnimated) return;
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.maxScrollExtent <= 0) return;

    _hasAnimated = true;
    await _scrollController.animateTo(
      30,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chips = QuickFilter.values
        .where((f) => f != QuickFilter.nearMe)
        .map((filter) {
      final isSelected = filter == widget.selectedFilter;
      return Padding(
        padding: EdgeInsets.only(right: AppSpacing.sm),
        child: _FilterChip(
          filter: filter,
          isSelected: isSelected,
          onTap: () => widget.onFilterChanged(filter),
        ),
      );
    }).toList();

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.pure,
                AppColors.pure,
                AppColors.pure,
                AppColors.pure.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.85, 0.92, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: widget.padding ??
                EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.sm,
                ),
            child: Row(
              children: [
                ...chips,
                if (widget.trailing != null) widget.trailing!,
                // Extra space so last chip isn't hidden by fade
                SizedBox(width: AppSpacing.md),
              ],
            ),
          ),
        ),
        // Scroll indicator chevron — fades out once user scrolls
        Positioned(
          right: AppSpacing.xs,
          child: AnimatedOpacity(
            opacity: _showScrollIndicator ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: AppIcon(
              icon: AppPhosphorIcons.chevronRight,
              size: AppIconSize.xs,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
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
