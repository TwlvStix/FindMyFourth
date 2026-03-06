import 'package:cloud_functions/cloud_functions.dart';

import '/core/utils/app_log.dart';

/// Service for handling player responses to being added to a game by a host.
///
/// When a host manually adds a player to their game, the player receives
/// a notification and can either acknowledge or decline the spot.
class PlayerAddedResponseService {
  PlayerAddedResponseService({
    FirebaseFunctions? functions,
  }) : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-west2');

  final FirebaseFunctions _functions;

  /// Declines a spot that the current user was added to by a host.
  ///
  /// This removes the player from the game and notifies the host
  /// that the spot is back open.
  ///
  /// Throws [FirebaseFunctionsException] if the operation fails.
  Future<void> declineAddedSpot({
    required String gameId,
  }) async {
    AppLog.d('📖 PlayerAddedResponseService: Declining spot for game $gameId');

    try {
      final callable = _functions.httpsCallable('declineAddedSpot');
      await callable.call({'gameId': gameId});
      AppLog.d('✅ PlayerAddedResponseService: Declined spot for game $gameId');
    } on FirebaseFunctionsException catch (e) {
      AppLog.d(
        '❌ PlayerAddedResponseService.declineAddedSpot error: '
        '${e.code} - ${e.message}',
      );
      rethrow;
    }
  }
}
