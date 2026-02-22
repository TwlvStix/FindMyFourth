import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/app_theme.dart';
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

class EditGameDetailsBottomSheet extends StatefulWidget {
  final DocumentReference gameRef;
  final DateTime initialDate;
  final String initialCourse;
  final DocumentReference? initialCourseRef;

  const EditGameDetailsBottomSheet({
    super.key,
    required this.gameRef,
    required this.initialDate,
    required this.initialCourse,
    this.initialCourseRef,
  });

  @override
  State<EditGameDetailsBottomSheet> createState() =>
      _EditGameDetailsBottomSheetState();
}

class _EditGameDetailsBottomSheetState
    extends State<EditGameDetailsBottomSheet> {
  DateTime? _selectedDate;
  String? _selectedCourse;
  Course? _selectedCourseRef;
  FormFieldController<String>? _courseController;

  Future<void> _saveChanges() async {
    debugPrint('🎯 Edit Game Details: Starting save');
    debugPrint('🎯 Selected date: $_selectedDate');
    debugPrint('🎯 Selected course: $_selectedCourse');

    if (_selectedDate == null) {
      debugPrint('❌ Edit Game Details: No date selected');
      _showError('Please select a date and time');
      return;
    }
    if (_selectedCourse == null) {
      debugPrint('❌ Edit Game Details: No course selected');
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void initState() {
    super.initState();
    debugPrint('🎯 Edit Game Details Bottom Sheet: Initializing');
    debugPrint('🎯 Game ref: ${widget.gameRef.path}');
    debugPrint('🎯 Initial date: ${widget.initialDate}');
    debugPrint('🎯 Initial course: ${widget.initialCourse}');

    // Pre-populate form fields
    _selectedDate = widget.initialDate;
    _selectedCourse = widget.initialCourse;
    if (widget.initialCourseRef != null) {
      _selectedCourseRef = Course(
        reference: widget.initialCourseRef!,
        name: widget.initialCourse,
      );
    }
    _courseController = FormFieldController<String>(widget.initialCourse);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎯 Edit Game Details Bottom Sheet: Building UI');
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.of(context).primaryBackground,
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
                    color: AppTheme.of(context).accent4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),

              Text(
                'Edit Game Details',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.of(context).primaryText,
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
                      color: AppTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.of(context).primary,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            color: AppTheme.of(context).primary, size: 24),
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
                  debugPrint(
                      '🎯 Course StreamBuilder: hasData=${snapshot.hasData}, hasError=${snapshot.hasError}');

                  if (snapshot.hasError) {
                    debugPrint('❌ Course loading error: ${snapshot.error}');
                    return Center(
                      child: Text(
                        'Error loading courses: ${snapshot.error}',
                        style: TextStyle(color: Colors.red),
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

                  debugPrint(
                      '🎯 Courses loaded: ${snapshot.data!.docs.length} courses');
                  final courses =
                      snapshot.data!.docs.map((doc) => Course.fromDoc(doc)).toList();

                  return AppDropDown<String>(
                    controller: _courseController ??=
                        FormFieldController<String>(null),
                    options: courses.map((e) => e.name).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCourse = val;
                        _selectedCourseRef =
                            courses.firstWhereOrNull((c) => c.name == val);
                      });
                    },
                    width: 300.0,
                    height: 50.0,
                    textStyle: AppTheme.of(context).bodyMedium.override(
                      font: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: AppTheme.of(context).bodyMedium.fontWeight,
                        fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                      ),
                      letterSpacing: 0.0,
                    ),
                    hintText: 'Select a course',
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.of(context).secondaryText,
                      size: 24.0,
                    ),
                    fillColor: AppTheme.of(context).secondaryBackground,
                    elevation: 2.0,
                    borderColor: AppTheme.of(context).primary,
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

              // Save Changes button
              SizedBox(
                width: double.infinity,
                child: AppButtonEnhanced(
                  text: 'Save Changes',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  onPressed: _saveChanges,
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
        color: AppTheme.of(context).secondaryText,
      );
}
