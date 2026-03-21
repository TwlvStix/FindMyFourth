import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/utils/state_update.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/models/course.dart';

/// Course picker bottom sheet for alert subscriptions.
///
/// Displays a searchable list of courses with multi-select capability.
class AlertCoursesPickerSheet extends StatefulWidget {
  const AlertCoursesPickerSheet({
    super.key,
    required this.allCourses,
    required this.selectedCourses,
  });

  final List<Course> allCourses;
  final List<Course> selectedCourses;

  @override
  State<AlertCoursesPickerSheet> createState() =>
      _AlertCoursesPickerSheetState();
}

class _AlertCoursesPickerSheetState extends State<AlertCoursesPickerSheet> {
  late List<Course> _selected;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedCourses);
  }

  List<Course> get _filteredCourses {
    if (_searchQuery.isEmpty) {
      return widget.allCourses;
    }

    final query = _searchQuery.toLowerCase();
    return widget.allCourses
        .where((course) => course.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppBorderRadius.xxl)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildSearchBar(),
          SizedBox(height: AppSpacing.md),
          Expanded(child: _buildCoursesList()),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: EdgeInsets.only(top: AppSpacing.sm),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.whiteHandle,
        borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Select Courses',
              style: AppTypography.headlineSmallSans.copyWith(
                color: AppColors.pure,
              ),
            ),
          ),
          AppButtonEnhanced(
            text: 'Done',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.small,
            onPressed: () => Navigator.pop(context, _selected),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: TextField(
        onChanged: (value) => updateState(this, () => _searchQuery = value),
        style: AppTypography.bodyMedium.copyWith(color: AppColors.pure),
        decoration: InputDecoration(
          hintText: 'Search courses...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.glassTextTertiary,
          ),
          prefixIcon: AppIcon(
            icon: AppPhosphorIcons.search,
            color: AppColors.textMuted,
            size: AppIconSize.md,
          ),
          filled: true,
          fillColor: AppColors.glassSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesList() {
    if (_filteredCourses.isEmpty) {
      return Center(
        child: Text(
          'No courses found',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.glassTextTertiary,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredCourses.length,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemBuilder: (context, index) {
        final course = _filteredCourses[index];
        final isSelected =
            _selected.any((c) => c.reference.id == course.reference.id);

        return _buildCourseItem(course, isSelected);
      },
    );
  }

  Widget _buildCourseItem(Course course, bool isSelected) {
    return InkWell(
      onTap: () {
        updateState(this, () {
          if (isSelected) {
            _selected
                .removeWhere((c) => c.reference.id == course.reference.id);
          } else {
            _selected.add(course);
          }
        });
      },
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.green.withValues(alpha: 0.2)
              : AppColors.whiteSubtle,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.green : AppColors.glassSurface,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            AppIcon(
              icon: isSelected
                  ? AppPhosphorIcons.success
                  : AppPhosphorIcons.circle,
              color: isSelected ? AppColors.green : AppColors.textMuted,
              size: AppIconSize.md,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                course.name,
                style: isSelected
                    ? AppTypography.titleMedium.copyWith(
                        color: AppColors.pure,
                      )
                    : AppTypography.bodyLarge.copyWith(
                        color: AppColors.pure,
                        fontWeight: AppTypography.medium,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
