// Automatic imports
import '/backend/backend.dart';
import '/backend/cloud_functions/cloud_functions.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<List<DocumentReference>> fetchReceiptants(GamesRecord game) async {
  final response = await makeCloudCall('fetchReceiptants', {
    'style_game': game.styleGame,
    'game_type': game.gameType,
    'rules_setting': game.rulesSetting,
    'friend_game': game.friendGame,
    'member_discount': game.memberDiscount,
  });

  final userRefs = response['user_refs'];
  if (userRefs is List) {
    return userRefs
        .whereType<String>()
        .map((ref) => toRef(ref))
        .toList();
  }

  return [];
}
