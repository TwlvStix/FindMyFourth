import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/backend/cloud_functions/cloud_functions.dart';

enum NotificationPermissionStatus {
  granted,
  denied,
  unsupported,
  noUser,
  error,
}

class NotificationPermissionService {
  NotificationPermissionService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
    SharedPreferences? prefs,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance,
        _prefs = prefs;

  static const String _deviceIdKey = 'notification_device_id';
  static const String _appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: 'unknown',
  );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  SharedPreferences? _prefs;
  StreamSubscription<String>? _tokenRefreshSub;

  Future<NotificationPermissionStatus> requestPermissionAndRegister() async {
    if (kIsWeb) {
      return NotificationPermissionStatus.unsupported;
    }
    final user = _auth.currentUser;
    if (user == null) {
      return NotificationPermissionStatus.noUser;
    }

    try {
      final settings = await _messaging.requestPermission();
      final authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!authorized) {
        await _markPermissionDenied(user.uid);
        return NotificationPermissionStatus.denied;
      }

      _listenForTokenRefresh(user.uid);
      try {
        final token = await _messaging.getToken();
        if (token != null && token.isNotEmpty) {
          await _upsertDeviceToken(user.uid, token);
        }
      } catch (_) {
        // Token fetch can fail transiently; permissions are still granted.
      }
      return NotificationPermissionStatus.granted;
    } catch (_) {
      return NotificationPermissionStatus.error;
    }
  }

  void _listenForTokenRefresh(String uid) {
    _tokenRefreshSub ??= _messaging.onTokenRefresh.listen((token) {
      if (token.isEmpty) {
        return;
      }
      _upsertDeviceToken(uid, token);
    });
  }

  Future<void> _upsertDeviceToken(String uid, String token) async {
    final deviceId = await _getOrCreateDeviceId();
    final deviceRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId);

    final deviceSnapshot = await deviceRef.get();
    final data = <String, dynamic>{
      'fcmToken': token,
      'platform': _platformLabel(),
      'appVersion': _appVersion,
      'lastSeenAt': FieldValue.serverTimestamp(),
    };
    if (!deviceSnapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await deviceRef.set(data, SetOptions(merge: true));

    // Keep legacy token storage active for existing Cloud Functions.
    await makeCloudCall(
      'addFcmToken',
      {
        'userDocPath': 'users/$uid',
        'fcmToken': token,
        'deviceType': _platformLabel(),
      },
    );
  }

  Future<void> _markPermissionDenied(String uid) async {
    await _firestore.collection('users').doc(uid).set(
      {
        'notify_off': true,
        'notification_prefs': {
          'push_enabled': false,
        },
      },
      SetOptions(merge: true),
    );
  }

  Future<String> _getOrCreateDeviceId() async {
    _prefs ??= await SharedPreferences.getInstance();
    final existing = _prefs?.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final random = Random.secure();
    final id =
        '${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1 << 32)}';
    await _prefs?.setString(_deviceIdKey, id);
    return id;
  }

  String _platformLabel() {
    if (kIsWeb) {
      return 'web';
    }
    if (Platform.isIOS) {
      return 'iOS';
    }
    if (Platform.isAndroid) {
      return 'Android';
    }
    return 'unknown';
  }
}
