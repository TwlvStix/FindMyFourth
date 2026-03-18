import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/core/utils/app_log.dart';

enum NotificationPermissionStatus {
  granted,
  provisional,
  denied,
  permanentlyDenied,
  unsupported,
  noUser,
  error,
}

class NotificationPermissionService {
  // Singleton pattern
  static final NotificationPermissionService _instance =
      NotificationPermissionService._internal();

  factory NotificationPermissionService() => _instance;

  NotificationPermissionService._internal({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
    SharedPreferences? prefs,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance,
        _prefs = prefs;

  // Allow dependency injection for testing
  NotificationPermissionService.forTesting({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseMessaging messaging,
    SharedPreferences? prefs,
  })  : _auth = auth,
        _firestore = firestore,
        _messaging = messaging,
        _prefs = prefs;

  static const String _deviceIdKey = 'notification_device_id';
  static const String _permissionAskedKey = 'notification_permission_asked';
  static const String _appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: 'unknown',
  );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  SharedPreferences? _prefs;
  StreamSubscription<String>? _tokenRefreshSub;

  // Cached state
  NotificationPermissionStatus? _cachedStatus;
  NotificationSettings? _cachedSettings;
  DateTime? _lastCheckedAt;
  bool _initialized = false;

  /// Synchronous access to cached permission status
  NotificationPermissionStatus get cachedStatus =>
      _cachedStatus ?? NotificationPermissionStatus.denied;

  /// Synchronous access to cached notification settings
  NotificationSettings? get cachedSettings => _cachedSettings;

  /// Whether the service has been initialized
  bool get isInitialized => _initialized;

  /// Last time permission status was checked
  DateTime? get lastCheckedAt => _lastCheckedAt;

  /// Initialize the notification service (idempotent - safe to call multiple times)
  /// Should be called once after user authentication
  Future<void> init(String uid) async {
    if (_initialized) {
      AppLog.d('[NotificationService] Already initialized, skipping');
      return;
    }

    if (kIsWeb) {
      AppLog.d('[NotificationService] Web platform, skipping initialization');
      _initialized = true;
      _cachedStatus = NotificationPermissionStatus.unsupported;
      return;
    }

    AppLog.d('[NotificationService] Initializing notification service');
    _initialized = true;

    // Check current status first
    await refreshPermissionStatus();

    if (_cachedStatus == NotificationPermissionStatus.granted ||
        _cachedStatus == NotificationPermissionStatus.provisional) {
      // Already authorized — fetch and persist FCM token
      try {
        final token = await _getMessagingToken();
        if (token != null && token.isNotEmpty) {
          await _upsertDeviceToken(uid, token);
          AppLog.d('[NotificationService] ✅ FCM token persisted on init');
        }
      } on FirebaseException catch (e) {
        AppLog.d(
            '❌ [NotificationService] Failed to persist token on init: ${e.code} - ${e.message}');
      }
    } else if (_cachedStatus == NotificationPermissionStatus.denied) {
      // Not yet granted — request permission (triggers iOS prompt)
      await requestPermissionAndRegister();
    }

    // Set up token refresh listener (only once)
    _setupTokenRefreshListener(uid);

    AppLog.d(
        '[NotificationService] Notification service initialized successfully');
  }

  /// Refresh permission status from system and update cache
  Future<NotificationPermissionStatus> refreshPermissionStatus() async {
    if (kIsWeb) {
      _cachedStatus = NotificationPermissionStatus.unsupported;
      _lastCheckedAt = DateTime.now();
      return _cachedStatus!;
    }

    final user = _auth.currentUser;
    if (user == null) {
      _cachedStatus = NotificationPermissionStatus.noUser;
      _lastCheckedAt = DateTime.now();
      return _cachedStatus!;
    }

    try {
      final settings = await _messaging.getNotificationSettings();
      _cachedSettings = settings;
      _lastCheckedAt = DateTime.now();

      NotificationPermissionStatus status;
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          status = NotificationPermissionStatus.granted;
          break;
        case AuthorizationStatus.provisional:
          status = NotificationPermissionStatus.provisional;
          break;
        case AuthorizationStatus.denied:
          // Check if we've asked before
          _prefs ??= await SharedPreferences.getInstance();
          final hasAsked = _prefs?.getBool(_permissionAskedKey) ?? false;
          status = hasAsked
              ? NotificationPermissionStatus.permanentlyDenied
              : NotificationPermissionStatus.denied;
          break;
        case AuthorizationStatus.notDetermined:
          status = NotificationPermissionStatus.denied;
          break;
      }

      _cachedStatus = status;
      AppLog.d('[NotificationService] Permission status refreshed: $status');
      return status;
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ [NotificationService] Error getting notification permission status: ${e.code} - ${e.message}');
      _cachedStatus = NotificationPermissionStatus.error;
      return _cachedStatus!;
    }
  }

  /// Get detailed notification permission status (DEPRECATED - use cachedStatus or refreshPermissionStatus)
  @Deprecated(
      'Use cachedStatus for synchronous access or refreshPermissionStatus() to update cache')
  Future<NotificationPermissionStatus> getDetailedStatus() async {
    return refreshPermissionStatus();
  }

  /// Open system settings for the app
  Future<void> openSystemSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } catch (e) {
      AppLog.d('Error opening system settings: $e');
    }
  }

  Future<NotificationPermissionStatus> requestPermissionAndRegister() async {
    if (kIsWeb) {
      return NotificationPermissionStatus.unsupported;
    }
    final user = _auth.currentUser;
    if (user == null) {
      return NotificationPermissionStatus.noUser;
    }

    try {
      AppLog.d('[NotificationService] Requesting notification permission');

      // Mark that we've asked for permission
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setBool(_permissionAskedKey, true);

      final settings = await _messaging.requestPermission();
      final authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      // Update cache immediately
      _cachedSettings = settings;
      _lastCheckedAt = DateTime.now();

      if (!authorized) {
        await _markPermissionDenied(user.uid);
        final status =
            settings.authorizationStatus == AuthorizationStatus.denied
                ? NotificationPermissionStatus.permanentlyDenied
                : NotificationPermissionStatus.denied;
        _cachedStatus = status;
        AppLog.d('[NotificationService] Permission denied: $status');
        return status;
      }

      // Return provisional or granted based on status
      if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        _cachedStatus = NotificationPermissionStatus.provisional;
        AppLog.d('[NotificationService] Permission granted (provisional)');
        return NotificationPermissionStatus.provisional;
      }

      _cachedStatus = NotificationPermissionStatus.granted;
      AppLog.d('[NotificationService] Permission granted');

      // Set up token refresh listener if not already set up
      _setupTokenRefreshListener(user.uid);

      // Get and save initial token
      try {
        final token = await _getMessagingToken();
        if (token != null && token.isNotEmpty) {
          await _upsertDeviceToken(user.uid, token);
          AppLog.d('[NotificationService] Initial FCM token saved');
        }
      } on FirebaseException catch (e) {
        // Token fetch can fail transiently; permissions are still granted.
        AppLog.d('❌ [NotificationService] Failed to get initial token: ${e.code} - ${e.message}');
      }

      // Ensure push_enabled is true and alertSub exists so backend can notify this user
      await _markPermissionGranted(user.uid);

      return NotificationPermissionStatus.granted;
    } on FirebaseException catch (e) {
      AppLog.d('❌ [NotificationService] Error requesting permission: ${e.code} - ${e.message}');
      _cachedStatus = NotificationPermissionStatus.error;
      return NotificationPermissionStatus.error;
    }
  }

  /// Set up token refresh listener (idempotent - safe to call multiple times)
  void _setupTokenRefreshListener(String uid) {
    if (_tokenRefreshSub != null) {
      AppLog.d(
          '[NotificationService] Token refresh listener already active, skipping');
      return;
    }

    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
      if (token.isEmpty) return;
      AppLog.d(
          '[NotificationService] FCM token refreshed, updating backend (uid=$uid)');
      try {
        await _upsertDeviceToken(uid, token);
      } catch (e) {
        AppLog.d(
            '❌ [NotificationService] Token refresh write failed (uid=$uid, token=${token.substring(0, 10)}...): $e');
      }
    });

    AppLog.d('[NotificationService] Token refresh listener attached');
  }

  Future<String?> _getMessagingToken() async {
    if (!kIsWeb && Platform.isIOS) {
      final hasApnsToken = await _waitForApnsToken();
      if (!hasApnsToken) {
        return null;
      }
    }
    return _messaging.getToken();
  }

  Future<bool> _waitForApnsToken() async {
    final deadline = DateTime.now().add(const Duration(seconds: 8));
    while (DateTime.now().isBefore(deadline)) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null && apnsToken.isNotEmpty) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return false;
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

  Future<void> _markPermissionGranted(String uid) async {
    try {
      // Enable push notifications on the user document
      await _firestore.collection('users').doc(uid).set(
        {
          'notify_off': false,
          'notification_prefs': {
            'push_enabled': true,
          },
        },
        SetOptions(merge: true),
      );

      // Create alertSub document if it doesn't exist yet.
      // enabled=true with no filters means the backend will notify this user for ALL games.
      final alertSubRef = _firestore.collection('alertSubs').doc(uid);
      final existing = await alertSubRef.get();
      if (!existing.exists) {
        await alertSubRef.set({
          'userId': uid,
          'enabled': true,
          'gameVibes': [],
          'stakes': [],
          'formats': [],
          'handicapUses': [],
          'courses': [],
          'special': {'games': false, 'twoVTwo': false},
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        AppLog.d('[NotificationService] Default alertSub created for $uid');
      }
    } catch (e) {
      // Non-fatal — user can still receive push, alertSub will be created when they visit settings
      AppLog.d(
          '[NotificationService] Failed to write permission granted state: $e');
    }
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

  /// Remove this device's FCM token from Firestore and unregister it.
  /// Call BEFORE FirebaseAuth.signOut() while uid is still available.
  Future<void> removeDeviceToken(String uid) async {
    try {
      final deviceId = await _getOrCreateDeviceId();
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(deviceId)
          .delete();
      AppLog.d('[NotificationService] ✅ Device token removed from Firestore');
    } catch (e) {
      AppLog.d(
          '[NotificationService] ⚠️ Failed to remove device token from Firestore: $e');
    }

    try {
      await _messaging.deleteToken();
      AppLog.d('[NotificationService] ✅ FCM token unregistered');
    } catch (e) {
      AppLog.d(
          '[NotificationService] ⚠️ Failed to unregister FCM token: $e');
    }
  }

  /// Reset the service for account switch.
  ///
  /// This cancels the token refresh subscription (which was bound to the
  /// previous user's UID) and clears cached state. Call this when the user
  /// logs out or switches accounts, before calling [init] for the new user.
  void reset() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _initialized = false;
    _cachedStatus = null;
    _cachedSettings = null;
    _lastCheckedAt = null;
    AppLog.d('[NotificationService] Reset for account switch');
  }

  /// Dispose the service and cancel all subscriptions
  /// Only needed for app shutdown or testing. Singleton lives for app lifetime.
  void dispose() {
    AppLog.d('[NotificationService] Disposing notification service');
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _initialized = false;
    _cachedStatus = null;
    _cachedSettings = null;
    _lastCheckedAt = null;
  }
}
