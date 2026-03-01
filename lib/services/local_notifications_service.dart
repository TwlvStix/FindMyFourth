import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '/core/utils/app_log.dart';

/// Service for displaying local notifications.
///
/// Uses the same 'fmm_general' channel as FCM background notifications
/// for consistent notification behavior (importance, sound, etc.).
class LocalNotificationsService {
  // Singleton pattern
  static final LocalNotificationsService _instance =
      LocalNotificationsService._internal();

  factory LocalNotificationsService() => _instance;

  LocalNotificationsService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final _tapController = StreamController<String>.broadcast();

  // Bounded monotonic counter for stable IDs (avoids hashCode collisions)
  int _notificationId = 0;

  bool _initialized = false;

  /// Stream of notification tap payloads for routing.
  Stream<String> get onTapStream => _tapController.stream;

  /// Whether the service has been initialized.
  bool get isInitialized => _initialized;

  // Reuse existing FCM channel for consistency with background notifications.
  // This matches the default_notification_channel_id in AndroidManifest.xml.
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'fmm_general', // Match AndroidManifest.xml default_notification_channel_id
    'General Notifications',
    description: 'General app notifications',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  int _nextNotificationId() {
    _notificationId = (_notificationId + 1) % 100000;
    return _notificationId;
  }

  /// Initialize the local notifications plugin.
  ///
  /// Safe to call multiple times (idempotent).
  Future<void> init() async {
    if (_initialized) {
      AppLog.d('🔔 LocalNotificationsService: Already initialized, skipping');
      return;
    }

    if (kIsWeb) {
      AppLog.d('🔔 LocalNotificationsService: Web platform, skipping');
      _initialized = true;
      return;
    }

    AppLog.d('🔔 LocalNotificationsService: Initializing');

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We handle permission via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create the notification channel on Android
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        AppLog.d('🔔 LocalNotificationsService: Android channel created');
      }
    }

    _initialized = true;
    AppLog.d('🔔 LocalNotificationsService: Initialized successfully');
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      AppLog.d('🔔 LocalNotificationsService: Notification tapped, payload=$payload');
      _tapController.add(payload);
    }
  }

  /// Display a local notification.
  ///
  /// [title] - The notification title.
  /// [body] - The notification body text.
  /// [payload] - JSON-encoded payload for tap handling/routing.
  Future<void> show({
    required String title,
    required String body,
    required String payload,
  }) async {
    AppLog.d('🔔 [DIAG-LOCAL] show() entered - initialized=$_initialized, kIsWeb=$kIsWeb');
    if (!_initialized || kIsWeb) {
      AppLog.d('🔔 LocalNotificationsService: Not initialized or web, skipping show');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: Priority.high,
      playSound: channel.playSound,
      enableVibration: channel.enableVibration,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = _nextNotificationId();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
    AppLog.d('🔔 [DIAG-LOCAL] show() SUCCESS - id=$id');
    AppLog.d('🔔 LocalNotificationsService: Displayed notification id=$id title="$title"');
  }

  /// Dispose the service.
  ///
  /// Note: Does NOT close the StreamController to allow reuse after re-init.
  void dispose() {
    // Only reset initialization flag, don't close controller
    _initialized = false;
    AppLog.d('🔔 LocalNotificationsService: Disposed');
  }
}
