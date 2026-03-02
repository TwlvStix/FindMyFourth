import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/backend/schema/course_record.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/form_field_controller.dart';
import '/core/utils/formatting_utils.dart';
import '/core/widgets/app_count_controller.dart';
import '/core/widgets/app_drop_down.dart';
import '/core/widgets/app_text_field.dart';

/// The golf profile section of the create profile form.
///
/// Contains fields for: home course, handicap, and Golf Canada number.
class GolfProfileSection extends StatelessWidget {
  const GolfProfileSection({
    super.key,
    required this.courses,
    required this.isLoadingCourses,
    required this.coursesValue,
    required this.coursesValueController,
    required this.handicapValue,
    required this.golfCanadaController,
    required this.onCourseChanged,
    required this.onHandicapChanged,
  });

  /// List of available courses, fetched by parent widget.
  final List<CourseRecord> courses;

  /// Whether courses are still loading.
  final bool isLoadingCourses;

  /// Currently selected course name.
  final String? coursesValue;

  /// Controller for the course dropdown.
  final FormFieldController<String>? coursesValueController;

  /// Current handicap value.
  final int? handicapValue;

  /// Controller for Golf Canada number input.
  final TextEditingController golfCanadaController;

  /// Callback when course selection changes.
  final ValueChanged<String?> onCourseChanged;

  /// Callback when handicap changes.
  final ValueChanged<int> onHandicapChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Golf Profile',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Home Course Dropdown
          _buildCourseDropdown(),
          SizedBox(height: AppSpacing.md),

          // Handicap
          _buildHandicapField(),
          SizedBox(height: AppSpacing.md),

          // Golf Canada #
          AppTextField(
            label: 'Golf Canada #',
            controller: golfCanadaController,
            variant: AppTextFieldVariant.filledDark,
            prefixIcon: AppPhosphorIcons.verified,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseDropdown() {
    if (isLoadingCourses) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: AppColors.inputBorderIdle),
        ),
        alignment: Alignment.center,
        child: CircularProgressIndicator(
          color: AppColors.textPrimary,
          strokeWidth: 2,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.inputBorderIdle),
      ),
      child: AppDropDown<String>(
        controller: coursesValueController ?? FormFieldController<String>(null),
        options: courses.map((c) => c.name).toList(),
        onChanged: onCourseChanged,
        width: double.infinity,
        height: 56,
        textStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        hintText: 'Select Home Course',
        icon: Icon(
          AppPhosphorIcons.golfCourse,
          color: AppColors.textMuted,
          size: AppIconSize.md,
        ),
        fillColor: AppColors.inputBackground,
        elevation: 0,
        borderColor: Colors.transparent,
        borderWidth: 0,
        borderRadius: AppBorderRadius.card,
        margin: EdgeInsetsDirectional.only(start: AppSpacing.md),
      ),
    );
  }

  Widget _buildHandicapField() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.inputBorderIdle),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gold, AppColors.goldLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Icon(
              AppPhosphorIcons.flagCheckered,
              color: AppColors.pure,
              size: AppIconSize.button,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Handicap',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  'Your official handicap index',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppCountController(
            decrementIconBuilder: (enabled) => _buildCounterButton(
              icon: AppPhosphorIcons.minus,
              enabled: enabled,
            ),
            incrementIconBuilder: (enabled) => _buildCounterButton(
              icon: AppPhosphorIcons.plus,
              enabled: enabled,
            ),
            countBuilder: (value) => Container(
              constraints: BoxConstraints(minWidth: 56),
              alignment: Alignment.center,
              child: Text(
                formatHandicap(value),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                textAlign: TextAlign.center,
                style: AppTypography.monoLarge.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            count: handicapValue ?? 0,
            updateCount: onHandicapChanged,
            stepSize: 1,
            minimum: -5,
            maximum: 54,
            editable: true,
            formatValue: formatHandicap,
            parseValue: (text) {
              final trimmed = text.trim();
              if (trimmed.startsWith('+')) {
                final num = int.tryParse(trimmed.substring(1));
                return num != null ? -num : null;
              }
              return int.tryParse(trimmed);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required bool enabled,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.navyLight
            : AppColors.navyLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Icon(
        icon,
        color: enabled ? AppColors.textPrimary : AppColors.textMuted,
        size: AppIconSize.button,
      ),
    );
  }
}
