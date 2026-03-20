import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/form_field_controller.dart';
import '/core/motion/animation_helpers.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_drop_down.dart';
import '/core/widgets/app_icon.dart';
import '/models/course.dart';
import '/services/course_service.dart';
import '../models/create_game_form_data.dart';
import 'create_game_form_sections.dart';
import 'section_header.dart';

class CreateGameCourseSection extends StatelessWidget {
  const CreateGameCourseSection({
    super.key,
    required this.formData,
    required this.courseService,
    required this.courseValueController,
    required this.hasAnimated,
    required this.updateFormState,
    required this.saveDraft,
    this.courseStreamKey,
    this.onCourseRetry,
  });

  final CreateGameFormData formData;
  final CourseService courseService;
  final FormFieldController<String> courseValueController;
  final bool hasAnimated;
  final FormStateUpdater updateFormState;
  final VoidCallback saveDraft;
  final Key? courseStreamKey;
  final VoidCallback? onCourseRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildAnimatedSection(
          sectionIndex: 5,
          hasAnimated: hasAnimated,
          child: SectionHeader(
            phosphorIcon: AppPhosphorIcons.course,
            title: 'Course',
          ),
        ),
        Align(
          alignment: AlignmentDirectional(-1.0, 0.0),
          child: Padding(
            padding: EdgeInsets.only(top: AppSpacing.xxs),
            child: StreamBuilder<List<Course>>(
              key: courseStreamKey,
              stream: courseService.streamAllCourses(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildCourseErrorState();
                }
                if (!snapshot.hasData) {
                  return Center(
                    child: SizedBox(
                      width: 50.0,
                      height: 50.0,
                      child: SpinKitWanderingCubes(
                        color: AppColors.gold,
                        size: 50.0,
                      ),
                    ),
                  );
                }
                final courses = snapshot.data!;
                if (courses.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withValues(alpha: 0.2),
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.md),
                      border: Border.all(
                        color: AppColors.navyLight.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        AppIcon(
                          icon: AppPhosphorIcons.golfCourse,
                          size: AppIconSize.xl,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          'No courses available',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.glassTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                formData.hydrateSelectedCourse(courses);
                if (courseValueController.value != formData.courseValue) {
                  courseValueController.value = formData.courseValue;
                }

                return AppDropDown<String>(
                  controller: courseValueController,
                  options: courses.map((e) => e.name).toList(),
                  onChanged: (val) {
                    updateFormState(() {
                      formData.courseValue = val;
                    });
                    formData.setSelectedCourse(
                      courses
                          .firstWhereOrNull((course) => course.name == val),
                    );
                    saveDraft();
                  },
                  width: 300.0,
                  height: 50.0,
                  searchHintTextStyle: AppTypography.labelMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                  searchTextStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  searchCursorColor: AppColors.green,
                  textStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  hintText: 'Where are you playing?',
                  searchHintText: 'Find your course',
                  icon: AppIcon(
                    icon: AppPhosphorIcons.chevronDown,
                    color: AppColors.textSecondary,
                    size: AppIconSize.md,
                  ),
                  fillColor: AppColors.inputBackground,
                  elevation: 2.0,
                  borderColor: AppColors.inputBorderIdle,
                  borderWidth: 1.0,
                  borderRadius: 10.0,
                  margin: EdgeInsetsDirectional.only(start: AppSpacing.md),
                  hidesUnderline: true,
                  isOverButton: true,
                  isSearchable: true,
                  isMultiSelect: false,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseErrorState() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.navyLight.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          AppIcon(
            icon: AppPhosphorIcons.warning,
            size: AppIconSize.xl,
            color: AppColors.textMuted,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Unable to load courses',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.glassTextSecondary,
            ),
          ),
          if (onCourseRetry != null) ...[
            SizedBox(height: AppSpacing.md),
            AppButtonEnhanced(
              text: 'Try again',
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.small,
              onPressed: onCourseRetry,
            ),
          ],
        ],
      ),
    );
  }
}
