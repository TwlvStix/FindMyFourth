import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/utils/app_log.dart';

Future<Map<String, dynamic>> makeCloudCall(
  String callName,
  Map<String, dynamic> input,
) async {
  try {
    final response = await FirebaseFunctions.instanceFor(region: 'us-west2')
        .httpsCallable(callName, options: HttpsCallableOptions())
        .call(input);
    return response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : {};
  } on FirebaseFunctionsException catch (e) {
    AppLog.d(
      'Cloud call error!\n'
      'Call: $callName\n'
      'Code: ${e.code}\n'
      'Details: ${e.details}\n'
      'Message: ${e.message}',
    );
  } catch (e) {
    AppLog.d('Cloud call error:${callName} $e');
  }
  return {};
}

Future<bool> deleteAccount() async {
  try {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        user = await FirebaseAuth.instance
            .authStateChanges()
            .firstWhere((u) => u != null)
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    if (user == null) {
      AppLog.d('deleteAccount error: no current user');
      return false;
    }
    await user.getIdToken(true);
    final token = await user.getIdToken();
    AppLog.d('deleteAccount auth uid: ${user.uid}');
    AppLog.d('deleteAccount auth token length: ${token?.length ?? 0}');
    final response = await FirebaseFunctions.instanceFor(region: 'us-west2')
        .httpsCallable('deleteAccount', options: HttpsCallableOptions())
        .call({'idToken': token});
    final data =
        response.data is Map ? Map<String, dynamic>.from(response.data as Map) : {};
    AppLog.d('deleteAccount response: $data');
    return data['ok'] == true;
  } on FirebaseFunctionsException catch (e) {
    AppLog.d(
      'deleteAccount error!\n'
      'Code: ${e.code}\n'
      'Details: ${e.details}\n'
      'Message: ${e.message}',
    );
    return false;
  } catch (e) {
    AppLog.d('deleteAccount error: $e');
    return false;
  }
}
