import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/content/report_copy.dart';
import '/core/utils/app_log.dart';

/// Handles report submission to Firestore.
///
/// Reports are write-only from the client. The `reports` collection
/// is reviewed manually via Firestore Console.
class ReportService {
  ReportService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Submit a report against another user.
  ///
  /// [reason] must be one of [ReportReasons.all].
  /// [context] describes where the report originated (e.g. 'profile', 'chat').
  Future<void> submitReport({
    required String reporterUid,
    required String reportedUid,
    required String reason,
    String? details,
    required String reportContext,
    String? chatId,
    String? messageId,
  }) async {
    assert(
      ReportReasons.all.contains(reason),
      'Invalid report reason: $reason',
    );

    try {
      await _firestore.collection('reports').add({
        'reporterUid': reporterUid,
        'reportedUid': reportedUid,
        'reason': reason,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
        'context': reportContext,
        if (chatId != null) 'chatId': chatId,
        if (messageId != null) 'messageId': messageId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      AppLog.d(
          '✅ ReportService.submitReport: $reporterUid reported $reportedUid for $reason');
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ ReportService.submitReport error: ${e.code} - ${e.message}');
      rethrow;
    }
  }
}
