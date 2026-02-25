import 'package:intl/intl.dart';

import '/utils/flexible_week_resolver.dart';

/// Formats flexible game date ranges for display.
///
/// Examples:
/// - "Mar 3 - 9" (same month)
/// - "Feb 28 - Mar 6" (cross-month)
/// - "Mar 8" (single day)
/// - "Mar 8 - 9 (this weekend)" (with hint)
class FlexibleDateFormatter {
  static final _monthDayFormat = DateFormat('MMM d');

  /// Formats a date range as "MMM d - d" or "MMM d - MMM d".
  ///
  /// Examples:
  /// - Same month: "Mar 3 - 9"
  /// - Cross-month: "Feb 28 - Mar 6"
  /// - Single day: "Mar 8"
  static String formatDateRange(DateTime start, DateTime end) {
    // Single day (or same day)
    if (_isSameDay(start, end)) {
      return _monthDayFormat.format(start);
    }

    final startMonth = DateFormat('MMM').format(start);
    final endMonth = DateFormat('MMM').format(end);

    if (startMonth == endMonth) {
      // Same month: "Mar 3 - 9"
      return '$startMonth ${start.day} - ${end.day}';
    } else {
      // Cross-month: "Feb 28 - Mar 6"
      return '${_monthDayFormat.format(start)} - ${_monthDayFormat.format(end)}';
    }
  }

  /// Returns formatted date range with optional relative hint.
  ///
  /// Examples:
  /// - "Mar 8 - 9 (this weekend)"
  /// - "Mar 3 - 9 (this week)"
  /// - "Mar 10 - 16 (next week)"
  /// - "Mar 3 - 9" (no hint if not current/next period)
  static String formatWithHint(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '';

    final dateRange = formatDateRange(start, end);
    final hint = FlexibleWeekResolver.getRelativeWeekHint(start, end);

    if (hint != null) {
      return '$dateRange $hint';
    }
    return dateRange;
  }

  /// Compares two dates ignoring time components.
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
