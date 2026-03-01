import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '/backend/push_notifications/push_notifications_handler.dart';
import '/core/navigation/app_router.dart';
import '/core/utils/app_log.dart';
import '/services/local_notifications_service.dart';
import '/services/notification_service.dart';

/// FCM notification service for handling foreground push notifications.
///
/// Implements [NotificationService] interface for testability.
/// Listens to [FirebaseMessaging.onMessage] for foreground messages and
/// displays them via [LocalNotificationsService].
class FcmNotificationService implements NotificationService {
  // Singleton pattern
  static final FcmNotificationService _instance =
      FcmNotificationService._internal();

  factory FcmNotificationService() => _instance;

  FcmNotificationService._internal();

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<String>? _onTapSub;
  bool _initialized = false;

  // Broadcast controllers that persist across init/dispose cycles.
  // Do NOT close these in dispose() - they're reused after logout/login.
  final _receivedController =
      StreamController<TestableNotification>.broadcast();
  final _tappedController = StreamController<TestableNotification>.broadcast();

  @override
  Stream<TestableNotification> get onNotificationReceived =>
      _receivedController.stream;

  @override
  Stream<TestableNotification> get onNotificationTapped =>
      _tappedController.stream;

  /// Whether the service has been initialized.
  bool get isInitialized => _initialized;

  /// Initialize the FCM foreground notification service.
  ///
  /// Safe to call multiple times (idempotent).
  Future<void> init() async {
    if (_initialized) {
      AppLog.d('🔔 FcmNotificationService: Already initialized, skipping');
      return;
    }

    if (kIsWeb) {
      AppLog.d('🔔 FcmNotificationService: Web platform, skipping');
      _initialized = true;
      return;
    }

    AppLog.d('🔔 FcmNotificationService: Initializing');

    // Disable iOS system foreground presentation.
    // We show notifications via flutter_local_notifications instead for
    // consistent behavior and smart suppression.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );

    // Listen to foreground messages
    _onMessageSub =
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    AppLog.d('🔔 [DIAG-FCM] onMessage listener SUBSCRIBED');

    // Single global tap subscription (NOT in widget lifecycle to avoid duplicates)
    _onTapSub = LocalNotificationsService().onTapStream.listen(_handleTap);
    AppLog.d('🔔 [DIAG-FCM] onTapStream listener SUBSCRIBED');

    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    AppLog.d('🍎 APNs Token: $apnsToken');

    final token = await FirebaseMessaging.instance.getToken();
    AppLog.d('🔔 FcmNotificationService: FCM Token: $token');

    _initialized = true;
    AppLog.d('🔔 FcmNotificationService: Initialized successfully');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    AppLog.d('🔔 [DIAG-FG] Received: id=${message.messageId}, type=${message.data['type']}');
    AppLog.d('🔔 [DIAG-FG] notification: ${message.notification?.title} / ${message.notification?.body}');
    AppLog.d('🔔 [DIAG-FG] data keys: ${message.data.keys.toList()}');
    AppLog.d(
        '🔔 FcmNotificationService: Received foreground message id=${message.messageId}');

    final notification = message.notification;
    if (notification == null) {
      AppLog.d('🔔 FcmNotificationService: No notification payload, skipping');
      return;
    }

    final title = notification.title ?? '';
    final body = notification.body ?? '';

    if (title.isEmpty && body.isEmpty) {
      AppLog.d('🔔 FcmNotificationService: Empty title and body, skipping');
      return;
    }

    // Create testable notification for stream
    final testableNotification = TestableNotification(
      title: title,
      body: body,
      data: message.data,
    );

    // Emit to received stream
    _receivedController.add(testableNotification);

    // Check if we should suppress this notification
    if (_shouldSuppressNotification(testableNotification)) {
      AppLog.d(
          '🔔 FcmNotificationService: Suppressing notification (user on relevant screen)');
      return;
    }

    // Prepare payload for tap handling
    final payload = <String, dynamic>{
      ...message.data,
      '_messageId': message.messageId,
    };

    // Show local notification
    AppLog.d('🔔 [DIAG-FG] Calling LocalNotificationsService.show(title: $title)');
    LocalNotificationsService().show(
      title: title,
      body: body,
      payload: jsonEncode(payload),
    );
  }

  bool _shouldSuppressNotification(TestableNotification notification) {
    // Get current route using the GoRouter extension
    final context = appNavigatorKey.currentContext;
    if (context == null) {
      return false;
    }

    try {
      final router = GoRouter.of(context);
      final currentLocation = router.getCurrentLocation();
      // Use Uri.path to ignore query params/fragments in route comparison
      final currentPath = Uri.parse(currentLocation).path;
      final type = notification.type;

      // Normalize keys to handle both camelCase and snake_case from backend
      final normalizedData = normalizeNotificationPayload(notification.data);

      // Suppress chat notifications when viewing that chat thread
      if (type == 'chat_message') {
        final chatId = normalizedData['threadId'] ?? normalizedData['chatId'];
        // Route is /chat/:chatId - compare path only (ignore query params)
        if (chatId != null && currentPath == '/chat/$chatId') {
          AppLog.d(
              '🔔 FcmNotificationService: Suppressing chat notification for chatId=$chatId');
          return true;
        }
      }

      // Game suppression deferred to v2 (requires provider tracking of viewed gameId)
      // The game detail route uses state.extra, not URL parameters

      return false;
    } catch (e) {
      AppLog.d('🔔 FcmNotificationService: Error checking suppression: $e');
      return false;
    }
  }

  Future<void> _handleTap(String payload) async {
    AppLog.d('🔔 FcmNotificationService: Handling tap, payload=$payload');

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final normalizedData = normalizeNotificationPayload(data);
      final messageId = normalizedData['_messageId'] as String?;

      // Create testable notification for tapped stream
      final testableNotification = TestableNotification(
        title: '', // Title not available from payload
        body: '', // Body not available from payload
        data: normalizedData,
      );
      _tappedController.add(testableNotification);

      // Use global navigator key for routing (same pattern as PushNotificationsHandler:262)
      final context = appNavigatorKey.currentContext;
      if (context != null) {
        // Await navigation to ensure async errors are caught by this try/catch
        await handleNotificationNavigation(context, normalizedData,
            messageId: messageId);
      } else {
        // Retry once after next frame (context may not be ready during app init)
        AppLog.d(
            '🔔 FcmNotificationService: No navigator context, scheduling retry');
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final retryContext = appNavigatorKey.currentContext;
          if (retryContext != null) {
            try {
              await handleNotificationNavigation(retryContext, normalizedData,
                  messageId: messageId);
            } catch (e) {
              AppLog.d(
                  '🔔 FcmNotificationService: Error in retry navigation: $e');
            }
          } else {
            AppLog.d(
                '🔔 FcmNotificationService: No navigator context after retry, skipping');
          }
        });
      }
    } catch (e) {
      AppLog.d('🔔 FcmNotificationService: Error handling tap: $e');
    }
  }

  @override
  void dispose() {
    AppLog.d('🔔 [DIAG-FCM] dispose() CALLED - cancelling listeners');
    AppLog.d('🔔 [DIAG-FCM] Stack: ${StackTrace.current}');
    // Cancel subscriptions but do NOT close controllers
    // (controllers persist across login/logout cycles)
    _onMessageSub?.cancel();
    _onMessageSub = null;
    _onTapSub?.cancel();
    _onTapSub = null;
    _initialized = false;
    AppLog.d('🔔 FcmNotificationService: Disposed');
  }
}
