/// Cancellation tier utility.
///
/// Determines the penalty tier for a cancellation based on how much time
/// remains before the scheduled tee time.

enum CancellationType {
  /// 36+ hours before tee time — no penalty
  early,

  /// 12–36 hours before tee time — tracked, 3 within 90 days = strike
  late,

  /// Under 12 hours before tee time — immediate 1 strike
  dayOf,
}

/// Derives the cancellation tier from the current time and tee time.
///
/// - 36+ hours before → early (no penalty)
/// - 12–36 hours before → late (tracked)
/// - Under 12 hours before → dayOf (1 strike)
CancellationType getCancellationType(DateTime now, DateTime teeTime) {
  final hoursUntilTee = teeTime.difference(now).inHours;
  if (hoursUntilTee >= 36) return CancellationType.early;
  if (hoursUntilTee >= 12) return CancellationType.late;
  return CancellationType.dayOf;
}
