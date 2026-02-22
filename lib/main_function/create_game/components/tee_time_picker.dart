import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/app_theme.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/widgets/app_button_enhanced.dart';

/// Premium tee time picker with iOS-style wheel picker
class TeeTimePicker extends StatefulWidget {
  final DateTime? selectedDateTime;
  final Function(DateTime) onTimeSelected;

  const TeeTimePicker({
    super.key,
    required this.selectedDateTime,
    required this.onTimeSelected,
  });

  @override
  State<TeeTimePicker> createState() => _TeeTimePickerState();
}

class _TeeTimePickerState extends State<TeeTimePicker> {
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

    // Initialize from selectedDateTime if available
    if (widget.selectedDateTime != null) {
      final time = widget.selectedDateTime!;
      _hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
      _minute = time.minute;
      _isPM = time.hour >= 12;
    } else {
      // Default to 9:00 AM
      _hour = 9;
      _minute = 0;
      _isPM = false;
    }

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
    if (totalMinutes < 60) totalMinutes = 12 * 60 + totalMinutes; // Wrap to 12:xx
    if (totalMinutes >= 13 * 60) totalMinutes = totalMinutes - 12 * 60; // Wrap after 12:59

    setState(() {
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

  bool _isValidForToday() {
    if (widget.selectedDateTime == null) return true;

    final now = DateTime.now();
    final selected = widget.selectedDateTime!;

    // Only validate if selected date is today
    if (selected.year == now.year &&
        selected.month == now.month &&
        selected.day == now.day) {
      // Convert to 24-hour format
      int hour24 = _isPM ? (_hour == 12 ? 12 : _hour + 12) : (_hour == 12 ? 0 : _hour);
      final selectedTime = TimeOfDay(hour: hour24, minute: _minute);
      final nowTime = TimeOfDay(hour: now.hour, minute: now.minute);

      // Compare times
      final selectedMinutes = selectedTime.hour * 60 + selectedTime.minute;
      final nowMinutes = nowTime.hour * 60 + nowTime.minute;

      return selectedMinutes > nowMinutes;
    }

    return true;
  }

  void _handleDone() {
    if (!_isValidForToday()) {
      setState(() {
        _errorMessage = 'Tee time cannot be in the past';
      });
      HapticFeedback.heavyImpact();
      return;
    }

    // Convert to 24-hour format
    int hour24 = _isPM ? (_hour == 12 ? 12 : _hour + 12) : (_hour == 12 ? 0 : _hour);

    // Create new DateTime with the selected time
    final baseDate = widget.selectedDateTime ?? DateTime.now();
    final newDateTime = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      hour24,
      _minute,
    );

    HapticFeedback.mediumImpact();
    widget.onTimeSelected(newDateTime);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.of(context).primaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: AppTheme.of(context).accent4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: AppSpacing.sm),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Enter Tee Time',
                    style: TextStyle(fontFamily: 'Manrope',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.of(context).primaryText,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.of(context).secondaryText),
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
                style: TextStyle(fontFamily: 'Manrope',
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.of(context).primaryText,
                  letterSpacing: 0.5,
                ),
              ),

              // Error message
              if (_errorMessage != null) ...[
                SizedBox(height: AppSpacing.xs),
                Text(
                  _errorMessage!,
                  style: TextStyle(fontFamily: 'Manrope',
                    fontSize: 13,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              SizedBox(height: AppSpacing.md),

              // Wheel Pickers
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.of(context).accent4.withValues(alpha: 0.2),
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
                            padding: EdgeInsets.only(top: AppSpacing.xs, bottom: 4),
                            child: Text(
                              'Hour',
                              style: TextStyle(fontFamily: 'Manrope',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.of(context).secondaryText,
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
                                setState(() {
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
                                    style: TextStyle(fontFamily: 'Manrope',
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.of(context).primaryText,
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
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        ':',
                        style: TextStyle(fontFamily: 'Manrope',
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.of(context).primaryText,
                        ),
                      ),
                    ),

                    // Minute picker
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: AppSpacing.xs, bottom: 4),
                            child: Text(
                              'Minutes',
                              style: TextStyle(fontFamily: 'Manrope',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.of(context).secondaryText,
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
                                setState(() {
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
                                    style: TextStyle(fontFamily: 'Manrope',
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.of(context).primaryText,
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
                  color: AppTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.of(context).accent4.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _isPM = false;
                            _errorMessage = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: !_isPM
                                ? AppTheme.of(context).primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'AM',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Manrope',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: !_isPM
                                  ? AppTheme.of(context).primaryBtnText
                                  : AppTheme.of(context).secondaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _isPM = true;
                            _errorMessage = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: _isPM
                                ? AppTheme.of(context).primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'PM',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Manrope',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _isPM
                                  ? AppTheme.of(context).primaryBtnText
                                  : AppTheme.of(context).secondaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSpacing.md),

              // Quick adjust controls
              Text(
                'Quick Adjust',
                style: TextStyle(fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.of(context).secondaryText,
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.of(context).accent4.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.of(context).primaryText,
          ),
        ),
      ),
    );
  }
}

/// Helper to show the tee time picker bottom sheet
Future<void> showTeeTimePicker({
  required BuildContext context,
  required DateTime? selectedDateTime,
  required Function(DateTime) onTimeSelected,
}) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: TeeTimePicker(
        selectedDateTime: selectedDateTime,
        onTimeSelected: onTimeSelected,
      ),
    ),
  );
}
