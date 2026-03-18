import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/utils/app_log.dart';
import '/core/utils/state_update.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_time_picker.dart';
import '/models/course.dart';
import '/models/game.dart';
import '/providers/provider_extensions.dart';
import '/services/course_service.dart';
import '/services/rebook_service.dart';

/// Bottom sheet for the "Change Course" rebook flow.
///
/// Full-height scrollable sheet with course search, inline calendar,
/// time picker, and confirm button. Creates a new game with the
/// selected course but same settings and players as the source game.
class RebookChangeCourseSheet extends StatefulWidget {
  const RebookChangeCourseSheet({
    super.key,
    required this.sourceGame,
    this.onGameCreated,
  });

  final Game sourceGame;
  final VoidCallback? onGameCreated;

  @override
  State<RebookChangeCourseSheet> createState() =>
      _RebookChangeCourseSheetState();
}

class _RebookChangeCourseSheetState extends State<RebookChangeCourseSheet> {
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  bool _isLoadingCourses = true;

  Course? _selectedCourse;
  DateTime? _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isSubmitting = false;
  String? _errorMessage;

  final _searchController = TextEditingController();

  DateTime get _today => DateTime.now();
  DateTime get _tomorrow => DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await CourseService().loadAllCourses();
      if (!mounted) return;
      updateState(this, () {
        _allCourses = courses;
        _filteredCourses = courses;
        _isLoadingCourses = false;
      });
    } catch (e) {
      AppLog.d('❌ RebookChangeCourseSheet: Failed to load courses');
      if (!mounted) return;
      updateState(this, () {
        _isLoadingCourses = false;
        _errorMessage = 'Could not load courses.';
      });
    }
  }

  void _onSearchChanged(String query) {
    final lower = query.toLowerCase().trim();
    updateState(this, () {
      _filteredCourses = lower.isEmpty
          ? _allCourses
          : _allCourses
              .where((c) => c.name.toLowerCase().contains(lower))
              .toList();
    });
  }

  DateTime? _buildSelectedDateTime() {
    if (_selectedDate == null) return null;
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  bool get _canSubmit =>
      _selectedCourse != null && _selectedDate != null && !_isSubmitting;

  Future<void> _onSubmit() async {
    final dateTime = _buildSelectedDateTime();
    if (dateTime == null || _selectedCourse == null || _isSubmitting) return;

    updateState(this, () {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await RebookService().rebookGame(
      widget.sourceGame,
      dateTime,
      overrideCourse: _selectedCourse,
    );

    if (!mounted) return;

    if (!result.success) {
      updateState(this, () {
        _isSubmitting = false;
        _errorMessage = result.errorMessage ?? 'Something went wrong.';
      });
      return;
    }

    context.gameProvider.invalidateAllGameCache();

    Navigator.pop(context);
    widget.onGameCreated?.call();
  }

  void _showTimePicker() {
    showAppTimePicker(
      context: context,
      title: 'Tee Time',
      initialTime: _selectedTime,
      onTimeSelected: (time) {
        updateState(this, () {
          _selectedTime = time;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppBorderRadius.xxl)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Fixed header
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.xxs),
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),

                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Change Course',
                        style: AppTypography.headlineMediumSans.copyWith(
                          color: AppColors.pure,
                        ),
                      ),
                      IconButton(
                        icon: AppIcon(
                          icon: AppPhosphorIcons.close,
                          color: AppColors.pure,
                          size: AppIconSize.md,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),

                  // Info row: game type
                  if (widget.sourceGame.gameType.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                        horizontal: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.md),
                      ),
                      child: Text(
                        widget.sourceGame.gameType,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  // Course search
                  _buildCourseSearchField(),
                  SizedBox(height: AppSpacing.xs),

                  // Course list
                  _buildCourseList(),
                  SizedBox(height: AppSpacing.md),

                  // Calendar
                  Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: AppColors.green,
                        onPrimary: AppColors.pure,
                        surface: AppColors.navyDark,
                        onSurface: AppColors.pure,
                        onSurfaceVariant: AppColors.pure,
                      ),
                    ),
                    child: CalendarDatePicker(
                      initialDate: _tomorrow,
                      firstDate: _today,
                      lastDate: DateTime(2050),
                      onDateChanged: (date) {
                        HapticFeedback.selectionClick();
                        updateState(this, () {
                          _selectedDate = date;
                          _errorMessage = null;
                        });
                      },
                    ),
                  ),

                  // Time picker trigger
                  InkWell(
                    onTap: _showTimePicker,
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                        horizontal: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.md),
                        border: Border.all(
                          color: AppColors.greenLight.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          AppIcon(
                            icon: AppPhosphorIcons.clock,
                            color: AppColors.pure,
                            size: AppIconSize.button,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            _selectedTime.format(context),
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.pure,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          AppIcon(
                            icon: AppPhosphorIcons.edit,
                            color: AppColors.textSecondary,
                            size: AppIconSize.sm,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Error message
                  if (_errorMessage != null) ...[
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      _errorMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],

                  SizedBox(height: AppSpacing.lg),

                  // Create Game button
                  SizedBox(
                    width: double.infinity,
                    child: AppButtonEnhanced(
                      text: 'Create Game',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      isLoading: _isSubmitting,
                      onPressed: _canSubmit ? _onSubmit : null,
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.pure),
      decoration: InputDecoration(
        hintText: 'Search courses',
        hintStyle:
            AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.xs),
          child: AppIcon(
            icon: AppPhosphorIcons.search,
            color: AppColors.textSecondary,
            size: AppIconSize.sm,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: AppColors.navy,
        contentPadding: EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: BorderSide(color: AppColors.navyLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: BorderSide(color: AppColors.navyLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: BorderSide(color: AppColors.green),
        ),
      ),
    );
  }

  Widget _buildCourseList() {
    if (_isLoadingCourses) {
      return SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.green,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_filteredCourses.isEmpty) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Text(
            'No courses found.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _filteredCourses.length,
        separatorBuilder: (_, __) => SizedBox(height: AppSpacing.xxs),
        itemBuilder: (context, index) {
          final course = _filteredCourses[index];
          final isSelected =
              _selectedCourse?.reference.path == course.reference.path;

          return InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              updateState(this, () {
                _selectedCourse = course;
                _errorMessage = null;
              });
            },
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.navy : AppColors.transparent,
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                border: Border.all(
                  color: isSelected ? AppColors.green : AppColors.navyLight,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      course.name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.pure,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    AppIcon(
                      icon: AppPhosphorIcons.check,
                      color: AppColors.green,
                      size: AppIconSize.sm,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
