import 'package:cloud_functions/cloud_functions.dart';

import '/core/utils/app_log.dart';

/// Service for calling test harness Cloud Functions.
///
/// Provides methods to send test notifications and generate delivery reports
/// for iOS notification verification testing.
class NotificationTestService {
  NotificationTestService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-west2');

  final FirebaseFunctions _functions;

  /// Send a test notification of any type to a specific user.
  ///
  /// Uses the full notification pipeline (dedup, prefs, quiet hours, FCM).
  Future<Map<String, dynamic>> sendTestNotification({
    required String eventType,
    required String recipientUserId,
    Map<String, dynamic>? testData,
  }) async {
    AppLog.d('📖 NotificationTestService: Sending test $eventType '
        'to $recipientUserId');

    try {
      final callable = _functions.httpsCallable('sendTestNotification');
      final result = await callable.call<Map<String, dynamic>>({
        'eventType': eventType,
        'recipientUserId': recipientUserId,
        if (testData != null) 'testData': testData,
      });

      final data = Map<String, dynamic>.from(result.data);
      AppLog.d('✅ NotificationTestService: Test send result: '
          '${data['result']}');
      return data;
    } on FirebaseFunctionsException catch (e) {
      AppLog.d('❌ NotificationTestService.sendTestNotification error: '
          '${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Generate a delivery report correlating server sends with client receipts.
  Future<Map<String, dynamic>> generateDeliveryReport({
    required String userId,
    DateTime? since,
    int limit = 100,
  }) async {
    AppLog.d('📖 NotificationTestService: Generating delivery report '
        'for $userId');

    try {
      final callable = _functions.httpsCallable('generateDeliveryReport');
      final result = await callable.call<Map<String, dynamic>>({
        'userId': userId,
        if (since != null) 'since': since.toIso8601String(),
        'limit': limit,
      });

      final data = Map<String, dynamic>.from(result.data);
      AppLog.d('✅ NotificationTestService: Report generated - '
          '${data['summary']}');
      return data;
    } on FirebaseFunctionsException catch (e) {
      AppLog.d('❌ NotificationTestService.generateDeliveryReport error: '
          '${e.code} - ${e.message}');
      rethrow;
    }
  }
}
