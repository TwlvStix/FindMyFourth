import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/app_theme.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/widgets/app_button_enhanced.dart';

/// Premium tee time picker with masked input
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
  late TextEditingController _timeController;
  bool _isPM = false;
  int _hour = 9;
  int _minute = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Initialize from selectedDateTime if available
    if (widget.selectedDateTime != null) {
      final time = widget.selectedDateTime!;
      _hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
      _minute = time.minute;
      _isPM = time.hour >= 12;
      _timeController = TextEditingController(
        text: '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
      );
    } else {
      // Default to 9:00 AM
      _hour = 9;
      _minute = 0;
      _isPM = false;
      _timeController = TextEditingController(text: '09:00');
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  void _parseTimeInput(String input) {
    setState(() {
      _errorMessage = null;
    });

    // Remove any non-digit characters
    final digits = input.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) {
      return;
    }

    int? hour;
    int? minute;

    // Parse based on length
    if (digits.length <= 2) {
      // Just hours: "9" or "09"
      hour = int.tryParse(digits);
      minute = 0;
    } else if (digits.length == 3) {
      // "930" -> 9:30
      hour = int.tryParse(digits.substring(0, 1));
      minute = int.tryParse(digits.substring(1, 3));
    } else {
      // "1012" -> 10:12
      hour = int.tryParse(digits.substring(0, digits.length - 2));
      minute = int.tryParse(digits.substring(digits.length - 2));
    }

    // Validate
    if (hour == null || hour < 1 || hour > 12) {
      setState(() {
        _errorMessage = 'Hour must be between 1 and 12';
      });
      return;
    }

    if (minute == null || minute < 0 || minute > 59) {
      setState(() {
        _errorMessage = 'Minutes must be between 0 and 59';
      });
      return;
    }

    // Auto-detect AM/PM based on common tee times if not explicitly set
    if (hour >= 5 && hour <= 11) {
      // 5-11 defaults to AM
      _isPM = false;
    } else if (hour == 12) {
      // 12 defaults to PM
      _isPM = true;
    }

    setState(() {
      _hour = hour!;
      _minute = minute!;
      _timeController.text = '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';
      _errorMessage = null;
    });
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
      _timeController.text = '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';
      _errorMessage = null;
    });
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
          padding: EdgeInsets.all(AppSpacing.lg),
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
              SizedBox(height: AppSpacing.md),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Enter Tee Time',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.of(context).primaryText,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.of(context).secondaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),

              // Time input field
              TextField(
                controller: _timeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.of(context).primaryText,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: '10:30',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.of(context).secondaryText.withValues(alpha: 0.3),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _errorMessage != null
                          ? AppColors.error
                          : AppTheme.of(context).primary,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.of(context).accent4.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.of(context).primary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: AppSpacing.lg,
                    horizontal: AppSpacing.md,
                  ),
                ),
                onChanged: _parseTimeInput,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d:]')),
                  LengthLimitingTextInputFormatter(5),
                ],
              ),

              // Error message
              if (_errorMessage != null) ...[
                SizedBox(height: AppSpacing.xs),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              SizedBox(height: AppSpacing.md),

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
                          setState(() => _isPM = false);
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
                            style: GoogleFonts.outfit(
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
                          setState(() => _isPM = true);
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
                            style: GoogleFonts.outfit(
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

              SizedBox(height: AppSpacing.lg),

              // Quick adjust controls
              Text(
                'Quick Adjust',
                style: GoogleFonts.outfit(
                  fontSize: 14,
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

              SizedBox(height: AppSpacing.xl),

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
          vertical: AppSpacing.xs,
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
          style: GoogleFonts.outfit(
            fontSize: 13,
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
