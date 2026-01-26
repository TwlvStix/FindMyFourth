import 'package:flutter/material.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';

enum GameDateRange {
  any,
  today,
  tomorrow,
  next7Days,
}

class GameListFilters {
  GameListFilters({
    Set<String>? selectedGameTypes,
    this.selectedDateRange = GameDateRange.any,
  }) : selectedGameTypes = selectedGameTypes ?? <String>{};

  Set<String> selectedGameTypes;
  GameDateRange selectedDateRange;

  GameListFilters copy() {
    return GameListFilters(
      selectedGameTypes: {...selectedGameTypes},
      selectedDateRange: selectedDateRange,
    );
  }

  bool get hasActiveFilters =>
      selectedGameTypes.isNotEmpty || selectedDateRange != GameDateRange.any;
}

class GameListFilterBottomSheet extends StatefulWidget {
  const GameListFilterBottomSheet({
    super.key,
    required this.currentFilters,
    required this.availableGameTypes,
  });

  final GameListFilters currentFilters;
  final Set<String> availableGameTypes;

  @override
  State<GameListFilterBottomSheet> createState() =>
      _GameListFilterBottomSheetState();
}

class _GameListFilterBottomSheetState
    extends State<GameListFilterBottomSheet> {
  static const List<String> _typeOrder = [
    'Stroke',
    'Match Play',
    'Skins',
    'Money',
    'Casual',
    'Fun',
  ];

  late GameListFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters.copy();
  }

  List<String> get _orderedAvailableTypes {
    return _typeOrder
        .where(widget.availableGameTypes.contains)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.cloud,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Games',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filters = GameListFilters();
                      });
                    },
                    child: Text(
                      'Clear All',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.fairway,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Game Type'),
                    SizedBox(height: AppSpacing.sm),
                    _buildGameTypes(),
                    SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Date Range'),
                    SizedBox(height: AppSpacing.sm),
                    _buildDateRange(),
                    SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: AppButtonEnhanced(
                onPressed: () {
                  Navigator.of(context).pop(_filters);
                },
                text: 'Apply Filters',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.labelLarge.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.onyx,
      ),
    );
  }

  Widget _buildGameTypes() {
    final types = _orderedAvailableTypes;
    if (types.isEmpty) {
      return Text(
        'No game types available.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.stone,
        ),
      );
    }
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: types.map(_buildGameTypeChip).toList(),
    );
  }

  Widget _buildGameTypeChip(String label) {
    final isSelected = _filters.selectedGameTypes.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _filters.selectedGameTypes.remove(label);
          } else {
            _filters.selectedGameTypes.add(label);
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.fairway.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.fairway : AppColors.cloud,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: isSelected ? AppColors.fairway : AppColors.stone,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDateRange() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDateChip('Any', GameDateRange.any),
            ),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildDateChip('Today', GameDateRange.today),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _buildDateChip('Tomorrow', GameDateRange.tomorrow),
            ),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildDateChip('Next 7 Days', GameDateRange.next7Days),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateChip(String label, GameDateRange range) {
    final isSelected = _filters.selectedDateRange == range;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filters.selectedDateRange = range;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.fairway.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.fairway : AppColors.cloud,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isSelected ? AppColors.fairway : AppColors.stone,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
