import 'package:flutter_app_badger/flutter_app_badger.dart';

import '/core/utils/app_log.dart';

/// Lightweight service to manage the OS-level app icon badge.
///
/// Wraps [FlutterAppBadger] with error handling so badge operations
/// never crash the app (badge support varies by platform/OEM).
class AppBadgeService {
  AppBadgeService._();
  static final AppBadgeService instance = AppBadgeService._();
  factory AppBadgeService() => instance;

  /// Remove the app icon badge. Safe to call on any platform.
  Future<void> clearBadge() async {
    try {
      final supported = await FlutterAppBadger.isAppBadgeSupported();
      if (supported) {
        await FlutterAppBadger.removeBadge();
        AppLog.d('✅ AppBadgeService: Badge cleared');
      }
    } catch (e) {
      // Non-critical — log and continue
      AppLog.d('⚠️ AppBadgeService.clearBadge failed: $e');
    }
  }

  /// Set the app icon badge to [count]. Safe to call on any platform.
  Future<void> updateBadge(int count) async {
    try {
      final supported = await FlutterAppBadger.isAppBadgeSupported();
      if (supported) {
        await FlutterAppBadger.updateBadgeCount(count);
      }
    } catch (e) {
      AppLog.d('⚠️ AppBadgeService.updateBadge failed: $e');
    }
  }
}
