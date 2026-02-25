import '/models/game.dart';
import '/utils/flexible_date_formatter.dart';
import '/utils/flexible_week_resolver.dart';

/// Formats flexible game availability with intelligent day collapsing.
///
/// Examples:
/// - "Mar 3 - 9 (this week) · Weekdays · Afternoon"
/// - "Weekend · Morning"
/// - "Next Week · Tue–Thu"
/// - "Mon, Wed, Fri"
/// - "Flexible"
String formatFlexibleAvailability(Game game) {
  if (!game.isFlexible) return '';

  // Prefer concrete dates when available
  if (game.flexibleStartDate != null && game.flexibleEndDate != null) {
    return _formatAvailabilityWithDates(
      flexibleStartDate: game.flexibleStartDate!,
      flexibleEndDate: game.flexibleEndDate!,
      flexibleDays: game.flexibleDays,
      flexibleTimeOfDay: game.flexibleTimeOfDay,
    );
  }

  // Fallback for legacy games without concrete dates
  return formatAvailabilityFromRaw(
    flexibleWeek: game.flexibleWeek,
    flexibleDays: game.flexibleDays,
    flexibleTimeOfDay: game.flexibleTimeOfDay,
  );
}

/// Formats availability using concrete start/end dates.
String _formatAvailabilityWithDates({
  required DateTime flexibleStartDate,
  required DateTime flexibleEndDate,
  List<int>? flexibleDays,
  String? flexibleTimeOfDay,
}) {
  final parts = <String>[];

  // Add date range with optional hint
  parts.add(FlexibleDateFormatter.formatWithHint(
    flexibleStartDate,
    flexibleEndDate,
  ));

  // Add collapsed day representation
  final dayPart = formatDays(flexibleDays);
  if (dayPart != null) {
    parts.add(dayPart);
  }

  // Add time of day
  final timePart = formatTimeOfDay(flexibleTimeOfDay);
  if (timePart != null) {
    parts.add(timePart);
  }

  return parts.join(' · ');
}

/// Lower-level function for testing and reuse.
/// Takes raw availability fields and returns formatted string.
String formatAvailabilityFromRaw({
  String? flexibleWeek,
  List<int>? flexibleDays,
  String? flexibleTimeOfDay,
}) {
  final parts = <String>[];

  // Add week context if not "flexible" (30-day window)
  final weekPart = formatWeek(flexibleWeek);
  if (weekPart != null) {
    parts.add(weekPart);
  }

  // Add collapsed day representation
  final dayPart = formatDays(flexibleDays);
  if (dayPart != null) {
    parts.add(dayPart);
  }

  // Add time of day
  final timePart = formatTimeOfDay(flexibleTimeOfDay);
  if (timePart != null) {
    parts.add(timePart);
  }

  return parts.isEmpty ? 'Flexible' : parts.join(' · ');
}

/// Formats week value into display label.
String? formatWeek(String? flexibleWeek) {
  switch (flexibleWeek) {
    case 'this_week':
      return 'This Week';
    case 'this_weekend':
      return 'This Weekend';
    case 'next_week':
      return 'Next Week';
    case 'next_2_weeks':
      return 'Next 2 Weeks';
    case 'flexible':
      // 30-day window, don't show week prefix
      return null;
    default:
      return null;
  }
}

/// Returns relative week label without date range.
///
/// Uses hint from dates if available, otherwise falls back to flexibleWeek enum.
/// Examples: "This Week", "Next Week", "This Weekend", "Flexible"
String getWeekHintOnly(Game game) {
  // Try to derive from dates first
  if (game.flexibleStartDate != null && game.flexibleEndDate != null) {
    final hint = FlexibleWeekResolver.getRelativeWeekHint(
      game.flexibleStartDate,
      game.flexibleEndDate,
    );
    if (hint != null) {
      // Strip parentheses and capitalize: "(next week)" → "Next Week"
      final cleaned = hint.replaceAll(RegExp(r'[()]'), '').trim();
      return cleaned
          .split(' ')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');
    }
  }
  // Fall back to enum value
  return formatWeek(game.flexibleWeek) ?? 'Flexible';
}

/// Formats day indices into collapsed display string.
/// Handles patterns like "Weekdays", "Weekend", "Any Day", contiguous ranges.
String? formatDays(List<int>? days) {
  if (days == null || days.isEmpty) return null;

  final sorted = List<int>.from(days)..sort();

  // Check for special patterns
  if (_isAllDays(sorted)) return 'Any Day';
  if (_isWeekdays(sorted)) return 'Weekdays';
  if (_isWeekend(sorted)) return 'Weekend';

  // Check for contiguous range (3+ days)
  if (sorted.length >= 3 && _isContiguous(sorted)) {
    return '${_dayName(sorted.first)}–${_dayName(sorted.last)}';
  }

  // List individual days
  return sorted.map(_dayName).join(', ');
}

/// Formats time of day values into display labels.
/// Use [joiner] to customize how multiple times are joined (default: ', ').
String? formatTimeOfDay(String? timeOfDay, {String joiner = ', '}) {
  if (timeOfDay == null || timeOfDay.isEmpty) return null;

  // Handle comma-separated multi-select values
  final times = timeOfDay.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

  if (times.isEmpty) return null;

  // If only 'anytime', return Anytime
  if (times.length == 1 && times.first == 'anytime') {
    return 'Anytime';
  }

  // Filter out 'anytime' if present with other values (shouldn't happen but handle gracefully)
  final specificTimes = times.where((t) => t != 'anytime').toList();
  if (specificTimes.isEmpty) return 'Anytime';

  // Map each time to its label in order
  final labels = <String>[];
  if (specificTimes.contains('morning')) labels.add('Morning');
  if (specificTimes.contains('afternoon')) labels.add('Afternoon');
  if (specificTimes.contains('twilight')) labels.add('Twilight');

  return labels.isEmpty ? null : labels.join(joiner);
}

/// Check if all 7 days are selected (0-6)
bool _isAllDays(List<int> sorted) {
  if (sorted.length != 7) return false;
  for (int i = 0; i < 7; i++) {
    if (!sorted.contains(i)) return false;
  }
  return true;
}

/// Check if exactly Mon-Fri (1-5) are selected
bool _isWeekdays(List<int> sorted) {
  if (sorted.length != 5) return false;
  const weekdays = [1, 2, 3, 4, 5];
  return sorted.every((d) => weekdays.contains(d)) &&
      weekdays.every((d) => sorted.contains(d));
}

/// Check if exactly Sat+Sun (0, 6) are selected
bool _isWeekend(List<int> sorted) {
  if (sorted.length != 2) return false;
  return sorted.contains(0) && sorted.contains(6);
}

/// Check if days form a contiguous sequence
bool _isContiguous(List<int> sorted) {
  for (int i = 1; i < sorted.length; i++) {
    if (sorted[i] != sorted[i - 1] + 1) return false;
  }
  return true;
}

/// Get short day name from day index (0=Sun, 1=Mon, etc.)
String _dayName(int day) {
  const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  return names[day.clamp(0, 6)];
}
