import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Event types for notification receipt audit.
enum NotificationReceiptEventType {
  /// Foreground push received from FCM
  fgReceived,

  /// Local notification shown to user
  fgLocalShown,

  /// User tapped local notification banner
  fgLocalTap,

  /// User tapped push notification while app was in background
  bgOpened,

  /// User tapped push notification to launch app from terminated state
  coldOpened,
}

/// Extension to convert event type to Firestore string.
extension NotificationReceiptEventTypeX on NotificationReceiptEventType {
  String get firestoreValue {
    switch (this) {
      case NotificationReceiptEventType.fgReceived:
        return 'fg_received';
      case NotificationReceiptEventType.fgLocalShown:
        return 'fg_local_shown';
      case NotificationReceiptEventType.fgLocalTap:
        return 'fg_local_tap';
      case NotificationReceiptEventType.bgOpened:
        return 'bg_opened';
      case NotificationReceiptEventType.coldOpened:
        return 'cold_opened';
    }
  }

  static NotificationReceiptEventType fromFirestore(String value) {
    switch (value) {
      case 'fg_received':
        return NotificationReceiptEventType.fgReceived;
      case 'fg_local_shown':
        return NotificationReceiptEventType.fgLocalShown;
      case 'fg_local_tap':
        return NotificationReceiptEventType.fgLocalTap;
      case 'bg_opened':
        return NotificationReceiptEventType.bgOpened;
      case 'cold_opened':
        return NotificationReceiptEventType.coldOpened;
      default:
        return NotificationReceiptEventType.fgReceived;
    }
  }
}

/// App state at time of notification event.
enum NotificationAppState {
  foreground,
  backgroundOpen,
  terminatedOpen,
}

extension NotificationAppStateX on NotificationAppState {
  String get firestoreValue {
    switch (this) {
      case NotificationAppState.foreground:
        return 'foreground';
      case NotificationAppState.backgroundOpen:
        return 'background_open';
      case NotificationAppState.terminatedOpen:
        return 'terminated_open';
    }
  }

  static NotificationAppState fromFirestore(String value) {
    switch (value) {
      case 'foreground':
        return NotificationAppState.foreground;
      case 'background_open':
        return NotificationAppState.backgroundOpen;
      case 'terminated_open':
        return NotificationAppState.terminatedOpen;
      default:
        return NotificationAppState.foreground;
    }
  }
}

/// Audit event for tracking notification receipt on device.
///
/// Used to verify push notification delivery during TestFlight testing
/// by comparing with backend notificationLog sends.
class NotificationReceiptEvent {
  NotificationReceiptEvent({
    required this.eventType,
    required this.uid,
    required this.eventAt,
    required this.platform,
    required this.appState,
    this.messageId,
    this.notificationType,
    this.dedupeKey,
    this.appVersion,
    this.buildNumber,
    this.payloadSummary,
  });

  /// Type of event (fg_received, bg_opened, etc.)
  final NotificationReceiptEventType eventType;

  /// User ID who received the notification
  final String uid;

  /// Client-side timestamp when event occurred
  final DateTime eventAt;

  /// Platform: 'iOS', 'Android', or 'web'
  final String platform;

  /// App state at time of event
  final NotificationAppState appState;

  /// FCM message ID if available
  final String? messageId;

  /// Notification type from payload (game_created, chat_message, etc.)
  final String? notificationType;

  /// Content-based dedupe key when messageId unavailable
  final String? dedupeKey;

  /// App version string
  final String? appVersion;

  /// Build number string
  final String? buildNumber;

  /// Summary of payload (data keys, title/body presence)
  final Map<String, dynamic>? payloadSummary;

  /// App version from environment variable.
  static const String _envAppVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: 'unknown',
  );

  /// Build number from environment variable.
  static const String _envBuildNumber = String.fromEnvironment(
    'BUILD_NUMBER',
    defaultValue: 'unknown',
  );

  /// Get current platform label.
  static String _currentPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    return 'unknown';
  }

  /// Factory for foreground push received event.
  factory NotificationReceiptEvent.foregroundReceived({
    required String uid,
    String? messageId,
    String? notificationType,
    String? dedupeKey,
    Map<String, dynamic>? payloadSummary,
  }) {
    return NotificationReceiptEvent(
      eventType: NotificationReceiptEventType.fgReceived,
      uid: uid,
      eventAt: DateTime.now(),
      platform: _currentPlatform(),
      appState: NotificationAppState.foreground,
      messageId: messageId,
      notificationType: notificationType,
      dedupeKey: dedupeKey,
      appVersion: _envAppVersion,
      buildNumber: _envBuildNumber,
      payloadSummary: payloadSummary,
    );
  }

  /// Factory for local notification shown event.
  factory NotificationReceiptEvent.foregroundLocalShown({
    required String uid,
    String? messageId,
    String? notificationType,
    String? dedupeKey,
  }) {
    return NotificationReceiptEvent(
      eventType: NotificationReceiptEventType.fgLocalShown,
      uid: uid,
      eventAt: DateTime.now(),
      platform: _currentPlatform(),
      appState: NotificationAppState.foreground,
      messageId: messageId,
      notificationType: notificationType,
      dedupeKey: dedupeKey,
      appVersion: _envAppVersion,
      buildNumber: _envBuildNumber,
    );
  }

  /// Factory for local notification tap event.
  factory NotificationReceiptEvent.foregroundLocalTap({
    required String uid,
    String? messageId,
    String? notificationType,
    String? dedupeKey,
  }) {
    return NotificationReceiptEvent(
      eventType: NotificationReceiptEventType.fgLocalTap,
      uid: uid,
      eventAt: DateTime.now(),
      platform: _currentPlatform(),
      appState: NotificationAppState.foreground,
      messageId: messageId,
      notificationType: notificationType,
      dedupeKey: dedupeKey,
      appVersion: _envAppVersion,
      buildNumber: _envBuildNumber,
    );
  }

  /// Factory for background push opened event.
  factory NotificationReceiptEvent.backgroundOpened({
    required String uid,
    String? messageId,
    String? notificationType,
    String? dedupeKey,
    Map<String, dynamic>? payloadSummary,
  }) {
    return NotificationReceiptEvent(
      eventType: NotificationReceiptEventType.bgOpened,
      uid: uid,
      eventAt: DateTime.now(),
      platform: _currentPlatform(),
      appState: NotificationAppState.backgroundOpen,
      messageId: messageId,
      notificationType: notificationType,
      dedupeKey: dedupeKey,
      appVersion: _envAppVersion,
      buildNumber: _envBuildNumber,
      payloadSummary: payloadSummary,
    );
  }

  /// Factory for cold start push opened event.
  factory NotificationReceiptEvent.coldOpened({
    required String uid,
    String? messageId,
    String? notificationType,
    String? dedupeKey,
    Map<String, dynamic>? payloadSummary,
  }) {
    return NotificationReceiptEvent(
      eventType: NotificationReceiptEventType.coldOpened,
      uid: uid,
      eventAt: DateTime.now(),
      platform: _currentPlatform(),
      appState: NotificationAppState.terminatedOpen,
      messageId: messageId,
      notificationType: notificationType,
      dedupeKey: dedupeKey,
      appVersion: _envAppVersion,
      buildNumber: _envBuildNumber,
      payloadSummary: payloadSummary,
    );
  }

  /// Convert to Firestore document data.
  Map<String, dynamic> toFirestore() {
    return {
      'event_type': eventType.firestoreValue,
      'event_at': Timestamp.fromDate(eventAt),
      'platform': platform,
      'app_state': appState.firestoreValue,
      if (messageId != null) 'message_id': messageId,
      if (notificationType != null) 'notification_type': notificationType,
      if (dedupeKey != null) 'dedupe_key': dedupeKey,
      if (appVersion != null) 'app_version': appVersion,
      if (buildNumber != null) 'build_number': buildNumber,
      if (payloadSummary != null) 'payload_summary': payloadSummary,
    };
  }

  /// Create from Firestore document.
  factory NotificationReceiptEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String uid,
  ) {
    final data = doc.data()!;
    return NotificationReceiptEvent(
      eventType: NotificationReceiptEventTypeX.fromFirestore(
        data['event_type'] as String? ?? 'fg_received',
      ),
      uid: uid,
      eventAt: (data['event_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      platform: data['platform'] as String? ?? 'unknown',
      appState: NotificationAppStateX.fromFirestore(
        data['app_state'] as String? ?? 'foreground',
      ),
      messageId: data['message_id'] as String?,
      notificationType: data['notification_type'] as String?,
      dedupeKey: data['dedupe_key'] as String?,
      appVersion: data['app_version'] as String?,
      buildNumber: data['build_number'] as String?,
      payloadSummary: data['payload_summary'] as Map<String, dynamic>?,
    );
  }

  /// Compute a composite key for deduplication.
  String get compositeKey =>
      '${eventType.firestoreValue}_${messageId ?? dedupeKey ?? 'no_id'}';
}

/// Helper to summarize a notification payload for audit logging.
Map<String, dynamic> summarizePayload(Map<String, dynamic>? data) {
  if (data == null) return {};
  return {
    'data_keys': data.keys.toList(),
    'has_type': data.containsKey('type'),
    'has_game_id': data.containsKey('gameId') || data.containsKey('game_id'),
    'has_chat_id': data.containsKey('chatId') ||
        data.containsKey('chat_id') ||
        data.containsKey('threadId'),
  };
}
