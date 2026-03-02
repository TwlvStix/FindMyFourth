import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '/backend/schema/course_record.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/form_field_controller.dart';
import '/core/widgets/app_count_controller.dart';
import '/core/widgets/app_drop_down.dart';
import '/core/widgets/app_icon.dart';

/// Data contract for GolfInfoStep props.
class GolfInfoStepData {
  const GolfInfoStepData({
    required this.courses,
    required this.isLoadingCourses,
    required this.homeCourseValue,
    required this.handicapValue,
    required this.onHomeCourseChanged,
    required this.onHandicapChanged,
    required this.homeCourseController,
  });

  /// List of available courses. Null if still loading.
  final List<CourseRecord>? courses;

  /// Whether courses are still being loaded.
  final bool isLoadingCourses;

  /// Currently selected home course name.
  final String? homeCourseValue;

  /// Current handicap value.
  final int handicapValue;

  /// Callback when home course selection changes.
  final ValueChanged<String?> onHomeCourseChanged;

  /// Callback when handicap changes.
  final ValueChanged<int> onHandicapChanged;

  /// Form field controller for the dropdown.
  final FormFieldController<String> homeCourseController;
}

/// Golf info step of progressive onboarding.
///
/// Collects home course and handicap.
class ProgressiveGolfInfoStep extends StatelessWidget {
  const ProgressiveGolfInfoStep({
    super.key,
    required this.data,
  });

  final GolfInfoStepData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your golf profile',
            style: AppTypography.headlineMediumSans.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.0,
            ),
          ),
          Padding(
            padding: AppSpacing.only(top: AppSpacing.xs),
            child: Text(
              'Help us match you with the right players and games.',
              style: AppTypography.bodyMedium,
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          // Home Course
          _buildCoursesDropdown(),
          SizedBox(height: AppSpacing.xl),
          // Handicap
          Text(
            'Handicap',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: AppColors.cloud,
                width: 2.0,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: AppCountController(
                decrementIconBuilder: (enabled) => AppIcon(
                  icon: AppPhosphorIcons.minus,
                  color: enabled ? AppColors.navyDark : AppColors.pure,
                  size: AppIconSize.button,
                ),
                incrementIconBuilder: (enabled) => AppIcon(
                  icon: AppPhosphorIcons.plus,
                  color: enabled ? AppColors.navyDark : AppColors.pure,
                  size: AppIconSize.button,
                ),
                countBuilder: (value) => Text(
                  value < 0 ? '+${value.abs()}' : value.toString(),
                  style: AppTypography.headlineSmallSans.copyWith(
                    letterSpacing: 0.0,
                  ),
                ),
                count: data.handicapValue,
                updateCount: data.onHandicapChanged,
                stepSize: 1,
                minimum: -5,
                maximum: 54,
                editable: true,
                formatValue: (value) =>
                    value < 0 ? '+${value.abs()}' : value.toString(),
                parseValue: (text) {
                  final trimmed = text.trim();
                  if (trimmed.startsWith('+')) {
                    final num = int.tryParse(trimmed.substring(1));
                    return num != null ? -num : null;
                  }
                  return int.tryParse(trimmed);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesDropdown() {
    if (data.isLoadingCourses || data.courses == null) {
      return Center(
        child: SizedBox(
          // Intentional fixed size for loading spinner
          width: 40.0,
          height: 40.0,
          child: SpinKitWanderingCubes(
            color: AppColors.navyDark,
            size: 40.0,
          ),
        ),
      );
    }

    final sortedCourses = List<CourseRecord>.from(data.courses!)
      ..sort((a, b) => a.name.compareTo(b.name));

    return AppDropDown<String>(
      controller: data.homeCourseController,
      options: sortedCourses.map((e) => e.name).toList(),
      onChanged: data.onHomeCourseChanged,
      width: double.infinity,
      // Intentional fixed height for standard input
      height: 56.0,
      textStyle: AppTypography.bodyMedium,
      hintText: 'Select your home course',
      icon: AppIcon(
        icon: AppPhosphorIcons.chevronDown,
        color: AppColors.pure,
        size: AppIconSize.md,
      ),
      fillColor: AppColors.inputBackground,
      elevation: 2.0,
      borderColor: AppColors.cloud,
      borderWidth: 2.0,
      borderRadius: AppBorderRadius.card,
      // Keep directional insets for RTL support
      margin: const EdgeInsetsDirectional.fromSTEB(16.0, 4.0, 16.0, 4.0),
      hidesUnderline: true,
      isOverButton: true,
      isSearchable: false,
      isMultiSelect: false,
    );
  }
}
