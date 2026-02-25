/// Resolves flexible game week values to concrete date ranges.
///
/// Week boundary: Monday 00:00:00 to Sunday 23:59:59 (ISO 8601).
/// Weekend boundary: Saturday 00:00:00 to Sunday 23:59:59.
class FlexibleWeekResolver {
  /// Resolves a flexibleWeek value to a concrete date range.
  ///
  /// Returns:
  /// - 'this_week' → Monday-Sunday of current week
  /// - 'next_week' → Monday-Sunday of next week
  /// - 'next_2_weeks' → Monday of this week to Sunday of next week (14 days)
  /// - 'this_weekend' → Saturday-Sunday of current/upcoming weekend
  /// - 'flexible' or null → Returns null (30-day window, no concrete dates)
  static ({DateTime start, DateTime end})? resolveWeekDates(
    String? flexibleWeek, {
    DateTime? referenceDate,
  }) {
    if (flexibleWeek == null || flexibleWeek == 'flexible') {
      return null;
    }

    final now = referenceDate ?? DateTime.now();

    switch (flexibleWeek) {
      case 'this_week':
        return _getWeekRange(now);
      case 'next_week':
        return _getWeekRange(now.add(const Duration(days: 7)));
      case 'next_2_weeks':
        return _getTwoWeekRange(now);
      case 'this_weekend':
        return _getWeekendRange(now);
      default:
        return null;
    }
  }

  /// Returns dynamic hint based on whether dates match current/next week/weekend.
  ///
  /// Returns '(this week)', '(next week)', '(this weekend)', or null if
  /// the dates don't match any current relative period.
  static String? getRelativeWeekHint(DateTime? start, DateTime? end) {
    if (start == null || end == null) return null;

    final now = DateTime.now();

    // Check if it's a weekend range (2-day span, Sat-Sun)
    final isWeekendRange = end.difference(start).inDays <= 1 &&
        start.weekday == DateTime.saturday &&
        end.weekday == DateTime.sunday;

    if (isWeekendRange) {
      final thisWeekend = _getWeekendRange(now);
      if (_isSameDay(start, thisWeekend.start) &&
          _isSameDay(end, thisWeekend.end)) {
        return '(this weekend)';
      }
      return null;
    }

    // Check for week ranges
    final thisWeek = _getWeekRange(now);
    final nextWeek = _getWeekRange(now.add(const Duration(days: 7)));

    if (_isSameDay(start, thisWeek.start) && _isSameDay(end, thisWeek.end)) {
      return '(this week)';
    }
    if (_isSameDay(start, nextWeek.start) && _isSameDay(end, nextWeek.end)) {
      return '(next week)';
    }

    return null;
  }

  /// Returns Monday of this week to Sunday of next week (14 days).
  static ({DateTime start, DateTime end}) _getTwoWeekRange(DateTime date) {
    final thisWeek = _getWeekRange(date);
    final nextWeek = _getWeekRange(date.add(const Duration(days: 7)));
    return (start: thisWeek.start, end: nextWeek.end);
  }

  /// Returns Monday 00:00:00 to Sunday 23:59:59 for the week containing [date].
  ///
  /// Uses ISO 8601 week definition where Monday is day 1 and Sunday is day 7.
  static ({DateTime start, DateTime end}) _getWeekRange(DateTime date) {
    // Dart weekday: Monday=1, Sunday=7 (ISO 8601)
    final daysSinceMonday = date.weekday - 1;
    final monday = DateTime(
      date.year,
      date.month,
      date.day - daysSinceMonday,
      0,
      0,
      0,
    );
    final sunday = DateTime(
      monday.year,
      monday.month,
      monday.day + 6,
      23,
      59,
      59,
    );
    return (start: monday, end: sunday);
  }

  /// Returns Saturday 00:00:00 to Sunday 23:59:59 for the current/upcoming weekend.
  ///
  /// Edge cases:
  /// - If today is Saturday, returns this Sat-Sun
  /// - If today is Sunday, returns this Sun only (start=end=Sunday)
  /// - Otherwise, returns the upcoming Sat-Sun
  static ({DateTime start, DateTime end}) _getWeekendRange(DateTime date) {
    // Dart weekday: Monday=1, Saturday=6, Sunday=7
    final today = DateTime(date.year, date.month, date.day);

    if (date.weekday == DateTime.sunday) {
      // Today is Sunday - return just today
      return (
        start: today,
        end: DateTime(today.year, today.month, today.day, 23, 59, 59),
      );
    }

    if (date.weekday == DateTime.saturday) {
      // Today is Saturday - return Sat-Sun
      final saturday = today;
      final sunday = DateTime(
        saturday.year,
        saturday.month,
        saturday.day + 1,
        23,
        59,
        59,
      );
      return (start: saturday, end: sunday);
    }

    // Weekday (Mon-Fri) - return upcoming Sat-Sun
    final daysUntilSaturday = DateTime.saturday - date.weekday;
    final saturday = DateTime(
      date.year,
      date.month,
      date.day + daysUntilSaturday,
      0,
      0,
      0,
    );
    final sunday = DateTime(
      saturday.year,
      saturday.month,
      saturday.day + 1,
      23,
      59,
      59,
    );
    return (start: saturday, end: sunday);
  }

  /// Compares two dates ignoring time components.
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
