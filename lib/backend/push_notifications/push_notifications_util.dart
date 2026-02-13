import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'serialization_util.dart';
import '../../auth/firebase_auth/auth_util.dart';
import '../cloud_functions/cloud_functions.dart';

import 'package:flutter/foundation.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

export 'push_notifications_handler.dart';
export 'serialization_util.dart';

const kUserPushNotificationsCollectionName = 'user_push_notifications';

class UserTokenInfo {
  const UserTokenInfo(this.userPath, this.fcmToken);
  final String userPath;
  final String fcmToken;
}

/// Get FCM token stream for initial token retrieval on auth
/// Note: Token refresh is now handled by NotificationPermissionService singleton
/// This stream only gets the initial token when user authenticates
Stream<UserTokenInfo> getFcmTokenStream(String userPath) =>
    Stream.value(!kIsWeb && (Platform.isIOS || Platform.isAndroid))
        .where((shouldGetToken) => shouldGetToken)
        .asyncMap<String?>((_) => _getTokenAfterApnsReady())
        .where((fcmToken) => fcmToken != null && fcmToken.isNotEmpty)
        .map((token) => UserTokenInfo(userPath, token!));

Future<String?> _getTokenAfterApnsReady() async {
  if (!kIsWeb && Platform.isIOS) {
    final deadline = DateTime.now().add(const Duration(seconds: 8));
    while (DateTime.now().isBefore(deadline)) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken != null && apnsToken.isNotEmpty) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }
  return FirebaseMessaging.instance.getToken();
}

final fcmTokenUserStream = authenticatedUserStream
    .where((user) => user != null)
    .map((user) => user!.reference.path)
    .distinct()
    .switchMap(getFcmTokenStream)
    .map(
      (userTokenInfo) => makeCloudCall(
        'addFcmToken',
        {
          'userDocPath': userTokenInfo.userPath,
          'fcmToken': userTokenInfo.fcmToken,
          'deviceType': Platform.isIOS ? 'iOS' : 'Android',
        },
      ),
    );

void triggerPushNotification({
  required String? notificationTitle,
  required String? notificationText,
  String? notificationImageUrl,
  DateTime? scheduledTime,
  String? notificationSound,
  required List<DocumentReference> userRefs,
  required String initialPageName,
  required Map<String, dynamic> parameterData,
}) {
  if ((notificationTitle ?? '').isEmpty || (notificationText ?? '').isEmpty) {
    return;
  }
  final serializedParameterData = serializeParameterData(parameterData);
  final pushNotificationData = {
    'notification_title': notificationTitle,
    'notification_text': notificationText,
    if (notificationImageUrl != null)
      'notification_image_url': notificationImageUrl,
    if (scheduledTime != null) 'scheduled_time': scheduledTime,
    if (notificationSound != null) 'notification_sound': notificationSound,
    'user_refs': userRefs.map((u) => u.path).join(','),
    'initial_page_name': initialPageName,
    'parameter_data': serializedParameterData,
    'sender': currentUserReference,
    'timestamp': DateTime.now(),
  };
  FirebaseFirestore.instance
      .collection(kUserPushNotificationsCollectionName)
      .doc()
      .set(pushNotificationData);
}
