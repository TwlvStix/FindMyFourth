import 'package:flutter/material.dart';
import '/core/widgets/app_time_picker.dart';

/// Premium tee time picker - wrapper around AppTimePicker that handles DateTime conversion
/// and past-time validation for tee time selection.
class TeeTimePicker extends StatelessWidget {
  final DateTime? selectedDateTime;
  final Function(DateTime) onTimeSelected;

  const TeeTimePicker({
    super.key,
    required this.selectedDateTime,
    required this.onTimeSelected,
  });

  TimeOfDay _getInitialTime() {
    if (selectedDateTime != null) {
      return TimeOfDay.fromDateTime(selectedDateTime!);
    }
    // Default to 9:00 AM
    return const TimeOfDay(hour: 9, minute: 0);
  }

  bool _isValidForToday(TimeOfDay time) {
    if (selectedDateTime == null) return true;

    final now = DateTime.now();
    final selected = selectedDateTime!;

    // Only validate if selected date is today
    if (selected.year == now.year &&
        selected.month == now.month &&
        selected.day == now.day) {
      final selectedMinutes = time.hour * 60 + time.minute;
      final nowMinutes = now.hour * 60 + now.minute;
      return selectedMinutes > nowMinutes;
    }

    return true;
  }

  void _handleTimeSelected(TimeOfDay time) {
    // Create new DateTime with the selected time
    final baseDate = selectedDateTime ?? DateTime.now();
    final newDateTime = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      time.hour,
      time.minute,
    );
    onTimeSelected(newDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return AppTimePicker(
      title: 'Enter Tee Time',
      initialTime: _getInitialTime(),
      showQuickAdjust: true,
      validator: _isValidForToday,
      validatorErrorText: 'Tee time cannot be in the past',
      onTimeSelected: _handleTimeSelected,
    );
  }
}

/// Helper to show the tee time picker bottom sheet
Future<void> showTeeTimePicker({
  required BuildContext context,
  required DateTime? selectedDateTime,
  required Function(DateTime) onTimeSelected,
}) {
  final initialTime = selectedDateTime != null
      ? TimeOfDay.fromDateTime(selectedDateTime)
      : const TimeOfDay(hour: 9, minute: 0);

  bool isValidForToday(TimeOfDay time) {
    if (selectedDateTime == null) return true;

    final now = DateTime.now();
    final selected = selectedDateTime;

    // Only validate if selected date is today
    if (selected.year == now.year &&
        selected.month == now.month &&
        selected.day == now.day) {
      final selectedMinutes = time.hour * 60 + time.minute;
      final nowMinutes = now.hour * 60 + now.minute;
      return selectedMinutes > nowMinutes;
    }

    return true;
  }

  return showAppTimePicker(
    context: context,
    title: 'Enter Tee Time',
    initialTime: initialTime,
    showQuickAdjust: true,
    validator: isValidForToday,
    validatorErrorText: 'Tee time cannot be in the past',
    onTimeSelected: (time) {
      final baseDate = selectedDateTime ?? DateTime.now();
      final newDateTime = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        time.hour,
        time.minute,
      );
      onTimeSelected(newDateTime);
    },
  );
}
