import 'package:flutter/cupertino.dart';
import '/core/utils/state_update.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';

/// Reusable time picker with scrollable wheel picker UI.
///
/// Features:
/// - Hour/minute CupertinoPicker wheels (1-12 hours, 0-59 minutes)
/// - AM/PM toggle buttons
/// - Large time display
/// - Haptic feedback
/// - Optional quick adjust buttons
/// - Optional validation with error display
class AppTimePicker extends StatefulWidget {
  final String title;
  final TimeOfDay initialTime;
  final bool showQuickAdjust;
  final ValueChanged<TimeOfDay> onTimeSelected;
  final bool Function(TimeOfDay)? validator;
  final String? validatorErrorText;

  const AppTimePicker({
    super.key,
    required this.title,
    required this.initialTime,
    this.showQuickAdjust = false,
    required this.onTimeSelected,
    this.validator,
    this.validatorErrorText,
  });

  @override
  State<AppTimePicker> createState() => _AppTimePickerState();
}

class _AppTimePickerState extends State<AppTimePicker> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  bool _isPM = false;
  int _hour = 9;
  int _minute = 0;
  String? _errorMessage;

  // Hours: 1-12
  final List<int> _hours = List.generate(12, (index) => index + 1);

  // Minutes: 0-59 (every minute)
  final List<int> _minutes = List.generate(60, (index) => index);

  @override
  void initState() {
    super.initState();

    // Initialize from initialTime
    final time = widget.initialTime;
    _hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    _minute = time.minute;
    _isPM = time.hour >= 12;

    // Initialize scroll controllers at the correct positions
    _hourController = FixedExtentScrollController(initialItem: _hour - 1);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _adjustTime(int minutesDelta) {
    HapticFeedback.selectionClick();
    int totalMinutes = _hour * 60 + _minute + minutesDelta;

    // Wrap around 12 hours
    if (totalMinutes < 60) totalMinutes = 12 * 60 + totalMinutes;
    if (totalMinutes >= 13 * 60) totalMinutes = totalMinutes - 12 * 60;

    updateState(this, () {
      _hour = (totalMinutes ~/ 60);
      if (_hour == 0) _hour = 12;
      if (_hour > 12) _hour = _hour - 12;
      _minute = totalMinutes % 60;
      _errorMessage = null;
    });

    // Animate to new positions
    _hourController.animateToItem(
      _hour - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    _minuteController.animateToItem(
      _minute,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  TimeOfDay _getCurrentTimeOfDay() {
    // Convert to 24-hour format
    int hour24 = _isPM ? (_hour == 12 ? 12 : _hour + 12) : (_hour == 12 ? 0 : _hour);
    return TimeOfDay(hour: hour24, minute: _minute);
  }

  void _handleDone() {
    final timeOfDay = _getCurrentTimeOfDay();

    // Run validator if provided
    if (widget.validator != null && !widget.validator!(timeOfDay)) {
      updateState(this, () {
        _errorMessage = widget.validatorErrorText ?? 'Invalid time';
      });
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    widget.onTimeSelected(timeOfDay);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppBorderRadius.xxl)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
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
                  borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
                ),
              ),
              SizedBox(height: AppSpacing.sm),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.pure,
                    ),
                  ),
                  IconButton(
                    icon: AppIcon(icon: AppPhosphorIcons.close, color: AppColors.pure, size: AppIconSize.md),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),

              // Current time display
              Text(
                '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} ${_isPM ? 'PM' : 'AM'}',
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.pure,
                  letterSpacing: 0.5,
                ),
              ),

              // Error message
              if (_errorMessage != null) ...[
                SizedBox(height: AppSpacing.xs),
                Text(
                  _errorMessage!,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.error,
                  ),
                ),
              ],

              SizedBox(height: AppSpacing.md),

              // Wheel Pickers
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  border: Border.all(
                    color: AppColors.greenLight.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Hour picker
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xxs),
                            child: Text(
                              'Hour',
                              style: AppTypography.labelMicro.copyWith(
                                color: AppColors.pure,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: _hourController,
                              itemExtent: 44,
                              onSelectedItemChanged: (index) {
                                HapticFeedback.selectionClick();
                                updateState(this, () {
                                  _hour = _hours[index];
                                  _errorMessage = null;
                                });
                              },
                              selectionOverlay: Container(
                                decoration: BoxDecoration(
                                  border: Border.symmetric(
                                    horizontal: BorderSide(
                                      color: AppColors.navy.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              children: _hours.map((hour) {
                                return Center(
                                  child: Text(
                                    hour.toString().padLeft(2, '0'),
                                    style: AppTypography.headlineMediumSans.copyWith(
                                      color: AppColors.pure,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Colon separator
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                      child: Text(
                        ':',
                        style: AppTypography.headlineMediumSans.copyWith(
                          color: AppColors.pure,
                        ),
                      ),
                    ),

                    // Minute picker
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xxs),
                            child: Text(
                              'Minutes',
                              style: AppTypography.labelMicro.copyWith(
                                color: AppColors.pure,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: _minuteController,
                              itemExtent: 44,
                              onSelectedItemChanged: (index) {
                                HapticFeedback.selectionClick();
                                updateState(this, () {
                                  _minute = _minutes[index];
                                  _errorMessage = null;
                                });
                              },
                              selectionOverlay: Container(
                                decoration: BoxDecoration(
                                  border: Border.symmetric(
                                    horizontal: BorderSide(
                                      color: AppColors.navy.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              children: _minutes.map((minute) {
                                return Center(
                                  child: Text(
                                    minute.toString().padLeft(2, '0'),
                                    style: AppTypography.headlineMediumSans.copyWith(
                                      color: AppColors.pure,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSpacing.sm),

              // AM/PM Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(
                    color: AppColors.greenLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          updateState(this, () {
                            _isPM = false;
                            _errorMessage = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: !_isPM
                                ? AppColors.navyDark
                                : AppColors.transparent,
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          ),
                          child: Text(
                            'AM',
                            textAlign: TextAlign.center,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.pure,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          updateState(this, () {
                            _isPM = true;
                            _errorMessage = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: _isPM
                                ? AppColors.navyDark
                                : AppColors.transparent,
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          ),
                          child: Text(
                            'PM',
                            textAlign: TextAlign.center,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.pure,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Quick adjust controls (optional)
              if (widget.showQuickAdjust) ...[
                SizedBox(height: AppSpacing.md),
                Text(
                  'Quick Adjust',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.pure,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAdjustButton('-5 min', -5),
                    SizedBox(width: AppSpacing.xs),
                    _buildAdjustButton('-1 min', -1),
                    SizedBox(width: AppSpacing.sm),
                    _buildAdjustButton('+1 min', 1),
                    SizedBox(width: AppSpacing.xs),
                    _buildAdjustButton('+5 min', 5),
                  ],
                ),
              ],

              SizedBox(height: AppSpacing.lg),

              // Done button
              SizedBox(
                width: double.infinity,
                child: AppButtonEnhanced(
                  text: 'Done',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  onPressed: _handleDone,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdjustButton(String label, int minutesDelta) {
    return InkWell(
      onTap: () => _adjustTime(minutesDelta),
      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          border: Border.all(
            color: AppColors.greenLight.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.pure,
          ),
        ),
      ),
    );
  }
}

/// Helper to show the time picker bottom sheet
Future<void> showAppTimePicker({
  required BuildContext context,
  required String title,
  required TimeOfDay initialTime,
  required ValueChanged<TimeOfDay> onTimeSelected,
  bool showQuickAdjust = false,
  bool Function(TimeOfDay)? validator,
  String? validatorErrorText,
}) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.transparent,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AppTimePicker(
        title: title,
        initialTime: initialTime,
        showQuickAdjust: showQuickAdjust,
        onTimeSelected: onTimeSelected,
        validator: validator,
        validatorErrorText: validatorErrorText,
      ),
    ),
  );
}
