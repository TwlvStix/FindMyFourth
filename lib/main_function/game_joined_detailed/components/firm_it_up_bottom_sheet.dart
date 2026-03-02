import 'package:flutter/material.dart';
import '/core/utils/app_log.dart';
import '/services/course_service.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/main_function/create_game/components/premium_date_picker.dart';
import '/main_function/create_game/components/tee_time_picker.dart';
import '/models/course.dart';
import '/core/widgets/app_drop_down.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/form_field_controller.dart';
import '/utils/app_util.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:collection/collection.dart';

class FirmItUpBottomSheet extends StatefulWidget {
  final DocumentReference gameRef;
  final CourseService _courseService;

  FirmItUpBottomSheet({
    super.key,
    required this.gameRef,
    CourseService? courseService,
  }) : _courseService = courseService ?? CourseService();

  @override
  State<FirmItUpBottomSheet> createState() => _FirmItUpBottomSheetState();
}

class _FirmItUpBottomSheetState extends State<FirmItUpBottomSheet> {
  DateTime? _selectedDate;
  String? _selectedCourse;
  Course? _selectedCourseRef;
  FormFieldController<String>? _courseController;

  Future<void> _confirmFirmUp() async {
    AppLog.d('🎯 Firm It Up: Starting confirmation');
    AppLog.d('🎯 Selected date: $_selectedDate');
    AppLog.d('🎯 Selected course: $_selectedCourse');

    if (_selectedDate == null) {
      AppLog.d('❌ Firm It Up: No date selected');
      _showError('Please select a date and time');
      return;
    }
    if (_selectedCourse == null) {
      AppLog.d('❌ Firm It Up: No course selected');
      _showError('Please select a course');
      return;
    }

    // Close the bottom sheet immediately
    Navigator.pop(context, {
      'date': _selectedDate,
      'course': _selectedCourse,
      'courseRef': _selectedCourseRef?.reference,
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  void initState() {
    super.initState();
    AppLog.d('🎯 Firm It Up Bottom Sheet: Initializing');
    AppLog.d('🎯 Game ref: ${widget.gameRef.path}');
  }

  @override
  Widget build(BuildContext context) {
    AppLog.d('🎯 Firm It Up Bottom Sheet: Building UI');
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppBorderRadius.xxl)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),

              Text(
                'Set Tee Time & Course',
                style: AppTypography.headlineMediumSans.copyWith(
                  fontSize: 22,
                  color: AppColors.pure,
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              // Date picker
              Text('Date', style: _labelStyle(context)),
              SizedBox(height: AppSpacing.xs),
              PremiumDatePicker(
                selectedDate: _selectedDate,
                onDateSelected: (date) => setState(() => _selectedDate = date),
              ),

              // Tee time (shown after date)
              if (_selectedDate != null) ...[
                SizedBox(height: AppSpacing.md),
                Text('Tee Time', style: _labelStyle(context)),
                SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: () {
                    showTeeTimePicker(
                      context: context,
                      selectedDateTime: _selectedDate,
                      onTimeSelected: (dt) => setState(() => _selectedDate = dt),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      border: Border.all(
                        color: AppColors.navyDark,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        AppIcon(icon: AppPhosphorIcons.teeTime,
                          color: AppColors.textSecondary, size: AppIconSize.md),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          dateTimeFormat("jm", _selectedDate),
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              SizedBox(height: AppSpacing.md),

              // Course selector
              Text('Course', style: _labelStyle(context)),
              SizedBox(height: AppSpacing.xs),
              StreamBuilder<List<Course>>(
                stream: widget._courseService.streamAllCourses(),
                builder: (context, snapshot) {
                  AppLog.d('🎯 Course StreamBuilder: hasData=${snapshot.hasData}, hasError=${snapshot.hasError}');

                  if (snapshot.hasError) {
                    AppLog.d('❌ Course loading error: ${snapshot.error}');
                    return Center(
                      child: Text(
                        'Error loading courses: ${snapshot.error}',
                        style: TextStyle(color: AppColors.error),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return Center(
                      child: SpinKitWanderingCubes(
                        color: AppColors.green,
                        size: 30.0,
                      ),
                    );
                  }

                  final courses = snapshot.data!;
                  AppLog.d('🎯 Courses loaded: ${courses.length} courses');

                  return AppDropDown<String>(
                    controller: _courseController ??=
                        FormFieldController<String>(null),
                    options: courses.map((e) => e.name).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCourse = val;
                        _selectedCourseRef = courses
                            .firstWhereOrNull((c) => c.name == val);
                      });
                    },
                    width: 300.0,
                    height: 50.0,
                    textStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    hintText: 'Select a course',
                    searchHintText: 'Search courses...',
                    searchTextStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    searchHintTextStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    searchCursorColor: AppColors.green,
                    icon: AppIcon(
                      icon: AppPhosphorIcons.chevronDown,
                      color: AppColors.textSecondary,
                      size: AppIconSize.md,
                    ),
                    fillColor: AppColors.navy,
                    elevation: 2.0,
                    borderColor: AppColors.navyLight,
                    borderWidth: 1.0,
                    borderRadius: 10.0,
                    margin: EdgeInsetsDirectional.only(start: 0),
                    hidesUnderline: true,
                    isOverButton: true,
                    isSearchable: true,
                  );
                },
              ),

              SizedBox(height: AppSpacing.xl),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: AppButtonEnhanced(
                  text: 'Confirm Tee Time',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  onPressed: _confirmFirmUp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle(BuildContext context) => AppTypography.labelSmall.copyWith(
    fontSize: 13,
    color: AppColors.pure,
  );
}
