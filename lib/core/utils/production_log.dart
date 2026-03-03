import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '/core/utils/app_log.dart';

/// Production-safe logger for critical pipeline diagnostics.
///
/// In debug builds, logs via [AppLog.d].
/// In release builds, logs as Crashlytics breadcrumbs (non-fatal).
///
/// Use for diagnosing issues that are invisible in release builds,
/// such as stream lifecycle events, timeouts, and auth transitions.
class ProductionLog {
  const ProductionLog._();

  /// Log a diagnostic message.
  ///
  /// - Debug: prints via AppLog.d
  /// - Release: records as Crashlytics breadcrumb
  ///
  /// Do NOT log PII payloads - only IDs, counts, error codes.
  static void log(String message) {
    // Always log in debug
    AppLog.d(message);

    // In release, add to Crashlytics breadcrumbs
    if (kReleaseMode && !kIsWeb) {
      FirebaseCrashlytics.instance.log(message);
    }
  }
}
