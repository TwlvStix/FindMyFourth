// Route parameter construction for push notification navigation.

import 'dart:convert';

import 'serialization_util.dart';
import '/backend/backend.dart';
import '/core/utils/app_log.dart';

/// Typed route parameter container with path and extra parameters.
class ParameterData {
  const ParameterData(
      {this.requiredParams = const {}, this.allParams = const {}});
  final Map<String, String?> requiredParams;
  final Map<String, dynamic> allParams;

  Map<String, String> get pathParameters => Map.fromEntries(
        requiredParams.entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
  Map<String, dynamic> get extra => Map.fromEntries(
        allParams.entries.where((e) => e.value != null),
      );

  static Future<ParameterData> Function(Map<String, dynamic>) none() =>
      (data) async => ParameterData();
}

/// Map of page names to their parameter builder functions.
final parametersBuilderMap =
    <String, Future<ParameterData> Function(Map<String, dynamic>)>{
  'GamesList': ParameterData.none(),
  'CreateGame': ParameterData.none(),
  'JoinGameDetailed': (data) async => ParameterData(
        allParams: {
          'gameRef': getParameter<DocumentReference>(data, 'gameRef'),
        },
      ),
  'Home': ParameterData.none(),
  'SignUpAccount': ParameterData.none(),
  'SignIn': ParameterData.none(),
  'RecoverPassword': ParameterData.none(),
  'CreateProfile': ParameterData.none(),
  'MainProfile': ParameterData.none(),
  'EditProfile': ParameterData.none(),
  'GamesJoined': ParameterData.none(),
  'NotificationSettings': ParameterData.none(),
  'Chat': ParameterData.none(),
  'success_page': ParameterData.none(),
  'ProfileUser': (data) async => ParameterData(
        allParams: {
          'userRef': getParameter<DocumentReference>(data, 'userRef'),
        },
      ),
  'success_leave': ParameterData.none(),
  'PlayerList': (data) async => ParameterData(
        allParams: {
          'gameRef': await getDocumentParameter<GamesRecord>(
              data, 'gameRef', GamesRecord.fromSnapshot),
        },
      ),
  'NotificationsList': ParameterData.none(),
  'Tab_Friends': (data) async => ParameterData(
        allParams: {
          'initialSegment': getParameter<String>(data, 'initialSegment'),
        },
      ),
  'GameJoinedDetailed': (data) async => ParameterData(
        allParams: {
          'gameRef': getParameter<DocumentReference>(data, 'gameRef'),
        },
      ),
  'ChatDetails': (data) async => ParameterData(
        requiredParams: {
          'chatId': getParameter<String>(data, 'chatId'),
        },
      ),
  'HostCheckin': (data) async => ParameterData(
        allParams: {
          'gameRef': getParameter<DocumentReference>(data, 'gameRef'),
        },
      ),
  'PeerRating': (data) async => ParameterData(
        allParams: {
          'gameRef': getParameter<DocumentReference>(data, 'gameRef'),
        },
      ),
  'FallbackConfirmation': (data) async => ParameterData(
        allParams: {
          'gameRef': getParameter<DocumentReference>(data, 'gameRef'),
        },
      ),
  'YourStanding': ParameterData.none(),
};

/// Parse initial parameter data from a notification payload's JSON string.
Map<String, dynamic> getInitialParameterData(Map<String, dynamic> data) {
  try {
    final parameterDataStr = data['parameterData'];
    if (parameterDataStr == null ||
        parameterDataStr is! String ||
        parameterDataStr.isEmpty) {
      return {};
    }
    return jsonDecode(parameterDataStr) as Map<String, dynamic>;
  } catch (e) {
    AppLog.d('Error parsing parameter data: $e');
    return {};
  }
}
