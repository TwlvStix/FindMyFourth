import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/main_function/create_game/components/premium_date_picker.dart';
import '/main_function/create_game/components/tee_time_picker.dart';
import '/models/course.dart';
import '/core/widgets/app_drop_down.dart';
import '/core/form_field_controller.dart';
import '/utils/app_util.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:collection/collection.dart';

class FirmItUpBottomSheet extends StatefulWidget {
  final DocumentReference gameRef;

  const FirmItUpBottomSheet({super.key, required this.gameRef});

  @override
  State<FirmItUpBottomSheet> createState() => _FirmItUpBottomSheetState();
}

class _FirmItUpBottomSheetState extends State<FirmItUpBottomSheet> {
  DateTime? _selectedDate;
  String? _selectedCourse;
  Course? _selectedCourseRef;
  FormFieldController<String>? _courseController;

  Future<void> _confirmFirmUp() async {
    debugPrint('🎯 Firm It Up: Starting confirmation');
    debugPrint('🎯 Selected date: $_selectedDate');
    debugPrint('🎯 Selected course: $_selectedCourse');

    if (_selectedDate == null) {
      debugPrint('❌ Firm It Up: No date selected');
      _showError('Please select a date and time');
      return;
    }
    if (_selectedCourse == null) {
      debugPrint('❌ Firm It Up: No course selected');
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
    debugPrint('🎯 Firm It Up Bottom Sheet: Initializing');
    debugPrint('🎯 Game ref: ${widget.gameRef.path}');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎯 Firm It Up Bottom Sheet: Building UI');
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyDarkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),

              Text(
                'Set Tee Time & Course',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyDarkText,
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
                      color: AppColors.navyBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.navyDark,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                          color: AppColors.navyDark, size: 24),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          dateTimeFormat("jm", _selectedDate),
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('course')
                    .orderBy('name')
                    .snapshots(),
                builder: (context, snapshot) {
                  debugPrint('🎯 Course StreamBuilder: hasData=${snapshot.hasData}, hasError=${snapshot.hasError}');

                  if (snapshot.hasError) {
                    debugPrint('❌ Course loading error: ${snapshot.error}');
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
                        color: AppColors.gold,
                        size: 30.0,
                      ),
                    );
                  }

                  debugPrint('🎯 Courses loaded: ${snapshot.data!.docs.length} courses');
                  final courses = snapshot.data!.docs
                      .map((doc) => Course.fromDoc(doc))
                      .toList();

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
                    textStyle: AppTypography.bodyMedium.override(
                      font: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: AppTypography.bodyMedium.fontWeight,
                        fontStyle: AppTypography.bodyMedium.fontStyle,
                      ),
                      letterSpacing: 0.0,
                    ),
                    hintText: 'Select a course',
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.navyText,
                      size: 24.0,
                    ),
                    fillColor: AppColors.navyBackground,
                    elevation: 2.0,
                    borderColor: AppColors.navyDark,
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

  TextStyle _labelStyle(BuildContext context) => TextStyle(
    fontFamily: 'Manrope',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.navyText,
  );
}
