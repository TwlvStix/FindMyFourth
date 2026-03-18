import 'dart:async';

import '../../utils/app_util.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/utils/app_log.dart';
import '/models/notification_receipt_event.dart';
import '/services/notification_audit_service.dart';

import 'notification_navigator.dart';

// Re-export all public symbols for backward compatibility.
export 'notification_payload.dart';
export 'notification_route_resolver.dart';
export 'notification_navigator.dart';
export 'notification_parameters.dart';

class PushNotificationsHandler extends StatefulWidget {
  const PushNotificationsHandler({super.key, required this.child});

  final Widget child;

  @override
  State<PushNotificationsHandler> createState() =>
      _PushNotificationsHandlerState();
}

class _PushNotificationsHandlerState extends State<PushNotificationsHandler> {
  // Static flag to ensure only ONE listener per app session
  static bool _listenerInitialized = false;

  Future<void> handleOpenedPushNotification() async {
    if (isWeb) {
      return;
    }

    // Only initialize the listener once per app session
    if (_listenerInitialized) {
      return;
    }
    _listenerInitialized = true;

    final notification = await FirebaseMessaging.instance.getInitialMessage();
    if (notification != null) {
      AppLog.d('🔔 [DIAG-COLD] Received: type=${notification.data['type']}, '
          'messageId=${notification.messageId}, '
          'data_keys=${notification.data.keys.toList()}');

      // Audit: Record cold start push opened
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        NotificationAuditService.instance.record(
          NotificationReceiptEvent.coldOpened(
            uid: uid,
            messageId: notification.messageId,
            notificationType: notification.data['type'] as String?,
            payloadSummary: summarizePayload(notification.data),
          ),
        );
      }

      // Cold-start delay for bottom-sheet types: give the widget tree time to
      // fully render before attempting showModalBottomSheet.
      final notifType = notification.data['type'];
      if (notifType == 'host_pre_game_confirm' || notifType == 'player_added_by_host') {
        AppLog.d('🔔 [DIAG-COLD] Delaying 500ms for bottom-sheet type: $notifType');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Use global context for cold start - widget context may not be ready
      final navContext = appNavigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        try {
          await handleNotificationNavigation(
            navContext,
            notification.data,
            messageId: notification.messageId,
          );
        } catch (e) {
          AppLog.d('🔔 PushNotificationsHandler: Error handling initial message: $e');
          // Fallback: navigate to home screen so user isn't stuck
          try {
            final fallbackContext = appNavigatorKey.currentContext;
            if (fallbackContext != null && fallbackContext.mounted) {
              fallbackContext.pushNamed('GamesList');
            }
          } catch (fallbackError) {
            AppLog.d('🔔 PushNotificationsHandler: Fallback navigation also failed: $fallbackError');
          }
        }
      } else {
        AppLog.d('🔔 PushNotificationsHandler: No navigator context for initial message');
      }
    }

    // Listen for push notifications opened from background
    // IMPORTANT: Use global navigator context, not widget context, because this
    // listener persists across widget rebuilds and the original widget may be disposed.
    FirebaseMessaging.onMessageOpenedApp.listen(_handlePushNotification);
  }

  Future<void> _handlePushNotification(RemoteMessage message) async {
    AppLog.d('🔔 [DIAG-BG] _handlePushNotification - messageId=${message.messageId}');
    AppLog.d('🔔 [DIAG-BG] data: ${message.data}');

    // Audit: Record background push opened
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      NotificationAuditService.instance.record(
        NotificationReceiptEvent.backgroundOpened(
          uid: uid,
          messageId: message.messageId,
          notificationType: message.data['type'] as String?,
          payloadSummary: summarizePayload(message.data),
        ),
      );
    }

    // Use global navigator context instead of potentially stale widget context.
    // This widget is wrapped around every route page, so the original instance
    // that set up the listener may be disposed when subsequent routes are pushed.
    final navContext = appNavigatorKey.currentContext;
    if (navContext == null) {
      AppLog.d('🔔 PushNotificationsHandler: No navigator context, skipping');
      return;
    }
    if (!navContext.mounted) {
      AppLog.d('🔔 PushNotificationsHandler: Navigator context not mounted, skipping');
      return;
    }

    AppLog.d('🔔 [DIAG-BG] navContext.mounted=${navContext.mounted}');

    try {
      await handleNotificationNavigation(
        navContext,
        message.data,
        messageId: message.messageId,
      );
    } catch (e) {
      AppLog.d('🔔 PushNotificationsHandler: Error handling notification: $e');
      // Fallback: navigate to home screen so user isn't stuck
      try {
        final fallbackContext = appNavigatorKey.currentContext;
        if (fallbackContext != null && fallbackContext.mounted) {
          fallbackContext.pushNamed('GamesList');
        }
      } catch (fallbackError) {
        AppLog.d('🔔 PushNotificationsHandler: Fallback navigation also failed: $fallbackError');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // Hygiene check
      handleOpenedPushNotification();
    });
  }

  @override
  void dispose() {
    // Note: The onMessageOpenedApp listener is not cancelled here as it
    // persists for the app lifetime and is deduplicated by _listenerInitialized.
    // The listener now uses appNavigatorKey.currentContext so it doesn't
    // reference this disposed widget's context.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
