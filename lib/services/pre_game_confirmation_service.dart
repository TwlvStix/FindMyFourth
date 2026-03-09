import 'package:cloud_functions/cloud_functions.dart';

import '/core/utils/app_log.dart';

/// Service for handling host pre-game confirmation decisions.
///
/// When a game is partial (not full) at T-45min before tee time, the host
/// receives a notification asking if the game is still on. This service
/// submits their confirm or cancel response.
class PreGameConfirmationService {
  PreGameConfirmationService({
    FirebaseFunctions? functions,
  }) : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-west2');

  final FirebaseFunctions _functions;

  /// Submits the host's pre-game confirmation decision.
  ///
  /// [confirmed] = true means the game continues as planned.
  /// [confirmed] = false means the host is cancelling the game.
  ///
  /// Returns the response data map which may include:
  /// - `success`: whether the operation succeeded
  /// - `alreadyHandled`: true if the confirmation was already processed
  ///
  /// Throws [FirebaseFunctionsException] if the operation fails.
  Future<Map<String, dynamic>> submitConfirmation({
    required String gameId,
    required bool confirmed,
  }) async {
    AppLog.d(
      '📖 PreGameConfirmationService: Submitting confirmation for game '
      '$gameId (confirmed=$confirmed)',
    );

    try {
      final callable = _functions.httpsCallable('submitPreGameConfirmation');
      final result = await callable.call({
        'gameId': gameId,
        'confirmed': confirmed,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      AppLog.d(
        '✅ PreGameConfirmationService: Confirmation submitted for game '
        '$gameId — result: $data',
      );
      return data;
    } on FirebaseFunctionsException catch (e) {
      AppLog.d(
        '❌ PreGameConfirmationService.submitConfirmation error: '
        '${e.code} - ${e.message}',
      );
      rethrow;
    }
  }
}
