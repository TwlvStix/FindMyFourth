import 'package:flutter/material.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_drop_down.dart';
import '/core/form_field_controller.dart';
import '/main_function/create_game/create_game_constants.dart';

enum GameDateRange {
  any,
  today,
  tomorrow,
  next7Days,
}

class GameListFilters {
  GameListFilters({
    Set<String>? selectedGameTypes,
    Set<String>? selectedVibes,
    Set<String>? selectedStakes,
    Set<String>? selectedHandicaps,
    Set<String>? selectedEligibility,
    this.selectedCourse,
    this.selectedDateRange = GameDateRange.any,
  })  : selectedGameTypes = selectedGameTypes ?? <String>{},
        selectedVibes = selectedVibes ?? <String>{},
        selectedStakes = selectedStakes ?? <String>{},
        selectedHandicaps = selectedHandicaps ?? <String>{},
        selectedEligibility = selectedEligibility ?? <String>{};

  Set<String> selectedGameTypes;
  Set<String> selectedVibes;
  Set<String> selectedStakes;
  Set<String> selectedHandicaps;
  Set<String> selectedEligibility;
  String? selectedCourse;
  GameDateRange selectedDateRange;

  GameListFilters copy() {
    return GameListFilters(
      selectedGameTypes: {...selectedGameTypes},
      selectedVibes: {...selectedVibes},
      selectedStakes: {...selectedStakes},
      selectedHandicaps: {...selectedHandicaps},
      selectedEligibility: {...selectedEligibility},
      selectedCourse: selectedCourse,
      selectedDateRange: selectedDateRange,
    );
  }

  bool get hasActiveFilters =>
      selectedGameTypes.isNotEmpty ||
      selectedVibes.isNotEmpty ||
      selectedStakes.isNotEmpty ||
      selectedHandicaps.isNotEmpty ||
      selectedEligibility.isNotEmpty ||
      (selectedCourse != null && selectedCourse!.trim().isNotEmpty) ||
      selectedDateRange != GameDateRange.any;
}

class GameListFilterBottomSheet extends StatefulWidget {
  const GameListFilterBottomSheet({
    super.key,
    required this.currentFilters,
    required this.availableGameTypes,
    required this.availableVibes,
    required this.availableStakes,
    required this.availableHandicaps,
    required this.availableCourses,
    required this.availableEligibilities,
  });

  final GameListFilters currentFilters;
  final Set<String> availableGameTypes;
  final Set<String> availableVibes;
  final Set<String> availableStakes;
  final Set<String> availableHandicaps;
  final Set<String> availableCourses;
  final Set<String> availableEligibilities;

  @override
  State<GameListFilterBottomSheet> createState() =>
      _GameListFilterBottomSheetState();
}

class _GameListFilterBottomSheetState
    extends State<GameListFilterBottomSheet> {
  static final List<String> _typeOrder = kCreateGamePrimaryFormatOptions
      .map((option) => option['value'] as String)
      .toList(growable: false);

  late GameListFilters _filters;
  FormFieldController<String>? _courseController;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters.copy();
    _courseController = FormFieldController<String>(_filters.selectedCourse);
  }

  List<String> get _orderedAvailableTypes {
    return _typeOrder
        .where(widget.availableGameTypes.contains)
        .toList(growable: false);
  }

  List<Map<String, dynamic>> get _orderedAvailableVibes {
    return kCreateGameVibeOptions
        .where(
          (option) =>
              widget.availableVibes.contains(option['value'] as String),
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> get _orderedAvailableStakes {
    return kCreateGameStakesOptions
        .where(
          (option) =>
              widget.availableStakes.contains(option['value'] as String),
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> get _orderedAvailableHandicaps {
    return kCreateGameHandicapOptions
        .where(
          (option) =>
              widget.availableHandicaps.contains(option['value'] as String),
        )
        .toList(growable: false);
  }

  List<String> get _orderedAvailableCourses {
    final courses = widget.availableCourses.toList()..sort();
    return courses;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppBorderRadius.xxl)),
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
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: Icon(AppPhosphorIcons.close, size: AppIconSize.md),
                        color: AppColors.pure,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        'Filter Games',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.pure,
                        ),
                      ),
                    ],
                  ),
                  AppButtonEnhanced(
                    text: 'Clear All',
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.small,
                    onPressed: () {
                      setState(() {
                        _filters = GameListFilters();
                        _courseController?.value = null;
                      });
                    },
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
                    SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Game Vibe'),
                    SizedBox(height: AppSpacing.sm),
                    _buildVibes(),
                    SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Stakes'),
                    SizedBox(height: AppSpacing.sm),
                    _buildStakes(),
                    SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Format'),
                    SizedBox(height: AppSpacing.sm),
                    _buildGameTypes(),
                    SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Handicap Use'),
                    SizedBox(height: AppSpacing.sm),
                    _buildHandicaps(),
                    SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Course'),
                    SizedBox(height: AppSpacing.sm),
                    _buildCourse(),
                    SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Date Range'),
                    SizedBox(height: AppSpacing.sm),
                    _buildDateRange(),
                    SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Who Can Join'),
                    SizedBox(height: AppSpacing.sm),
                    _buildEligibility(),
                    SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.navyDark,
                border: Border(
                  top: BorderSide(
                    color: AppColors.navyLight,
                    width: 1,
                  ),
                ),
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
        color: AppColors.pure,
      ),
    );
  }

  Widget _buildGameTypes() {
    final types = _orderedAvailableTypes;
    if (types.isEmpty) {
      return Text(
        'No formats available.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }
    final options = kCreateGamePrimaryFormatOptions
        .where((option) => types.contains(option['value'] as String))
        .toList(growable: false);
    return _buildOptionChips(options, _filters.selectedGameTypes);
  }

  Widget _buildOptionChips(
    List<Map<String, dynamic>> options,
    Set<String> selectedValues,
  ) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: options.map((option) {
        final value = option['value'] as String;
        final label = option['label'] as String? ?? value;
        final isSelected = selectedValues.contains(value);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedValues.remove(value);
              } else {
                selectedValues.add(value);
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
                  ? AppColors.green.withValues(alpha:0.15)
                  : AppColors.navy.withValues(alpha:0.3),
              border: Border.all(
                color: isSelected ? AppColors.green : AppColors.navyLight,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected ? AppColors.green : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVibes() {
    final options = _orderedAvailableVibes;
    if (options.isEmpty) {
      return Text(
        'No game vibes available.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }
    return _buildOptionChips(options, _filters.selectedVibes);
  }

  Widget _buildStakes() {
    final options = _orderedAvailableStakes;
    if (options.isEmpty) {
      return Text(
        'No stakes available.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }
    return _buildOptionChips(options, _filters.selectedStakes);
  }

  Widget _buildHandicaps() {
    final options = _orderedAvailableHandicaps;
    if (options.isEmpty) {
      return Text(
        'No handicap options available.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }
    return _buildOptionChips(options, _filters.selectedHandicaps);
  }

  Widget _buildCourse() {
    final courses = _orderedAvailableCourses;
    if (courses.isEmpty) {
      return Text(
        'No courses available.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }
    _courseController ??=
        FormFieldController<String>(_filters.selectedCourse);
    return AppDropDown<String>(
      controller: _courseController,
      options: courses,
      onChanged: (val) {
        setState(() {
          _filters.selectedCourse = val;
        });
      },
      hintText: 'All courses',
      textStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.pure,
      ),
      elevation: 2.0,
      borderWidth: 1.0,
      borderRadius: 12.0,
      borderColor: AppColors.navyLight,
      margin: EdgeInsetsDirectional.zero,
      fillColor: AppColors.navy,
      hidesUnderline: true,
      isOverButton: true,
      isSearchable: true,
      isMultiSelect: false,
      height: 50.0,
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
              ? AppColors.green.withValues(alpha:0.15)
              : AppColors.navy.withValues(alpha:0.3),
          border: Border.all(
            color: isSelected ? AppColors.green : AppColors.navyLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isSelected ? AppColors.green : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEligibility() {
    final eligibilities = widget.availableEligibilities;
    if (eligibilities.isEmpty) {
      return Text(
        'No eligibility options available.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }
    // Map Firestore values to display labels
    final options = kCreateGameEligibilityOptions
        .where((option) => eligibilities.contains(option['value'] as String))
        .toList(growable: false);
    return _buildOptionChips(options, _filters.selectedEligibility);
  }
}
