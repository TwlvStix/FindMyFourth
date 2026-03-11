import 'dart:async';

import 'serialization_util.dart';
import '/backend/backend.dart';
import '/core/utils/app_log.dart';
import '../../utils/app_util.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/models/notification_receipt_event.dart';
import '/notifications/components/player_added_bottom_sheet.dart';
import '/notifications/components/pre_game_confirm_bottom_sheet.dart';
import '/services/notification_audit_service.dart';

/// TTL-based deduplication cache with 5-minute expiry.
/// Prevents duplicate navigation while allowing legitimate taps to same destination.
final _handledMessageCache = <String, DateTime>{};

/// Prune stale entries from deduplication cache (older than 5 minutes).
void _pruneStaleDedupeEntries() {
  final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
  _handledMessageCache.removeWhere((_, timestamp) => timestamp.isBefore(cutoff));
}

/// Compute a content-based hash for deduplication when messageId is null.
///
/// Uses only deterministic payload fields (type + IDs) to create a unique key.
/// This prevents duplicate navigation if the same notification is received twice
/// without a messageId. Note: Two genuinely different notifications with the
/// same type and IDs will be deduped, but this is acceptable since they would
/// navigate to the same screen anyway.
String _computeContentHash(Map<String, dynamic> data) {
  final type = data['type'] ?? '';
  final gameId = data['gameId'] ?? data['game_id'] ?? '';
  final chatId = data['chatId'] ?? data['chat_id'] ?? data['threadId'] ?? data['thread_id'] ?? '';
  final gameRef = data['gameRef'] ?? data['game_ref'] ?? '';
  // Use deterministic fields only - no timestamp
  return 'content_${type}_${gameId}_${chatId}_$gameRef';
}

/// Normalize payload keys to handle both camelCase (legacy) and snake_case (backend).
///
/// This function ensures routing works regardless of which key format the
/// backend sends. Original keys are preserved, then normalized versions override.
///
/// Bridges Trust system payloads (event_type) with legacy payloads (type).
Map<String, dynamic> normalizeNotificationPayload(Map<String, dynamic> data) {
  return {
    // Pass through all original keys FIRST
    ...data,

    // Then override with normalized versions (these take precedence)
    // Bridge event_type (Trust system) → type (legacy/routing)
    'type': data['type'] ?? data['event_type'],
    'initialPageName': data['initialPageName'] ?? data['initial_page_name'],
    'parameterData': data['parameterData'] ?? data['parameter_data'],

    // Game keys
    'gameId': data['gameId'] ?? data['game_id'],
    'gameRef': data['gameRef'] ?? data['game_ref'],

    // Chat keys
    'chatId': data['chatId'] ?? data['chat_id'],
    'threadId': data['threadId'] ?? data['thread_id'],

    // Trust system keys preserved for reference
    'eventId': data['eventId'] ?? data['event_id'],

    // Internal tracking
    '_messageId': data['_messageId'],
  };
}

/// Handle notification navigation from both background taps and foreground taps.
///
/// This is the shared routing logic used by both [PushNotificationsHandler] (for
/// background/terminated taps) and [FcmNotificationService] (for foreground taps).
///
/// [context] - A valid BuildContext for navigation.
/// [rawData] - The raw notification data (will be normalized).
/// [messageId] - Optional message ID for deduplication.
Future<void> handleNotificationNavigation(
  BuildContext context,
  Map<String, dynamic> rawData, {
  required String? messageId,
}) async {
  // Prune stale entries and check for duplicates
  _pruneStaleDedupeEntries();
  final dedupeKey = messageId ?? _computeContentHash(rawData);

  AppLog.d('🔔 [DIAG-BG] handleNotificationNavigation - messageId=$messageId');
  AppLog.d('🔔 [DIAG-BG] dedupeKey=$dedupeKey, alreadyHandled=${_handledMessageCache.containsKey(dedupeKey)}');

  if (_handledMessageCache.containsKey(dedupeKey)) {
    AppLog.d('🔔 [DIAG-BG] BLOCKED by deduplication');
    return;
  }
  _handledMessageCache[dedupeKey] = DateTime.now();

  // Normalize keys BEFORE routing
  final data = normalizeNotificationPayload(rawData);

  // Intercept player_added_by_host to show bottom sheet
  final type = data['type'];
  if (type == 'player_added_by_host') {
    final gameId = data['game_id'] ?? data['gameId'];
    final hostName = data['host_name'] ?? data['hostName'] ?? 'A host';
    final courseName = data['course_name'] ?? data['courseName'] ?? 'a course';
    final gameDate = data['game_date'] ?? data['gameDate'] ?? 'an upcoming game';

    if (gameId is String && gameId.isNotEmpty && context.mounted) {
      await showPlayerAddedBottomSheet(
        context: context,
        gameId: gameId,
        hostName: hostName.toString(),
        courseName: courseName.toString(),
        gameDate: gameDate.toString(),
        onGotIt: () {
          // Navigate to game details after acknowledging
          final navContext = appNavigatorKey.currentContext;
          if (navContext != null && navContext.mounted) {
            navContext.pushNamed(
              'GameJoinedDetailed',
              extra: {
                'gameRef': FirebaseFirestore.instance.doc('games/$gameId'),
              },
            );
          }
        },
        onDeclined: () {
          // Navigate to games list after declining
          final navContext = appNavigatorKey.currentContext;
          if (navContext != null && navContext.mounted) {
            navContext.pushNamed('GamesList');
          }
        },
      );
      return; // Exit after handling bottom sheet
    }
  }

  // Intercept host_pre_game_confirm to show confirmation bottom sheet
  if (type == 'host_pre_game_confirm') {
    AppLog.d('🔔 [DIAG-NAV] host_pre_game_confirm intercept: gameId=${data['game_id'] ?? data['gameId']}, mounted=${context.mounted}');
    final gameId = data['game_id'] ?? data['gameId'];
    final courseName =
        data['course_name'] ?? data['courseName'] ?? 'your course';
    final gameDate =
        data['game_date'] ?? data['gameDate'] ?? 'your upcoming round';

    if (gameId is String && gameId.isNotEmpty && context.mounted) {
      await showPreGameConfirmBottomSheet(
        context: context,
        gameId: gameId,
        courseName: courseName.toString(),
        gameDate: gameDate.toString(),
        onConfirmed: () {
          final navContext = appNavigatorKey.currentContext;
          if (navContext != null && navContext.mounted) {
            navContext.pushNamed(
              'GameJoinedDetailed',
              extra: {
                'gameRef': FirebaseFirestore.instance.doc('games/$gameId'),
              },
            );
          }
        },
        onCancelled: () {
          final navContext = appNavigatorKey.currentContext;
          if (navContext != null && navContext.mounted) {
            navContext.pushNamed('GamesList');
          }
        },
      );
      return; // Exit after handling bottom sheet
    }
  }

  final resolvedRoute = _resolveRouteFromType(data);
  final rawPageName = data['initialPageName'];
  final initialPageName = resolvedRoute?.pageName ??
      (rawPageName is String && rawPageName.isNotEmpty ? rawPageName : null);

  AppLog.d('🔔 [DIAG-NAV] Routing: type=${data['type']} → '
      'page=$initialPageName, params=${resolvedRoute?.parameterData ?? {}}');

  if (initialPageName == null) {
    AppLog.d('🔔 [DIAG-NAV] No page name resolved, skipping navigation');
    return;
  }

  final initialParameterData =
      resolvedRoute?.parameterData ?? getInitialParameterData(data);

  // Friends-only check (works with any context)
  if (initialPageName == 'JoinGameDetailed') {
    final shouldBlock = await _shouldBlockFriendsOnlyGame(initialParameterData);
    if (shouldBlock) {
      // ignore: use_build_context_synchronously - mounted check handles this safely
      final dialogContext =
          context.mounted ? context : appNavigatorKey.currentContext;
      if (dialogContext != null && dialogContext.mounted) {
        await _showFriendsOnlyDialog(dialogContext);
      }
      return;
    }
  }

  // Navigate (no loading UI for foreground taps - instant)
  final parametersBuilder = parametersBuilderMap[initialPageName];
  if (parametersBuilder != null) {
    final parameterData = await parametersBuilder(initialParameterData);
    final navContext = context.mounted ? context : appNavigatorKey.currentContext;
    navContext?.pushNamed(
      initialPageName,
      pathParameters: parameterData.pathParameters,
      extra: parameterData.extra,
    );
  }
}

// Top-level routing resolution (extracted from widget)
_PushRoute? _resolveRouteFromType(Map<String, dynamic> data) {
  final type = data['type'];
  if (type is! String || type.isEmpty) {
    return null;
  }
  if (type == 'game_created' || type == 'game_alert') {
    final gameId = data['gameId'] ?? data['game_id'];
    if (gameId is String && gameId.isNotEmpty) {
      return _PushRoute(
        pageName: 'JoinGameDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }
  if (type == 'chat_message') {
    final chatId = data['threadId'] ?? data['chatId'];
    if (chatId is String && chatId.isNotEmpty) {
      return _PushRoute(
        pageName: 'ChatDetails',
        parameterData: {'chatId': chatId},
      );
    }
  }
  if (type == 'host_checkin') {
    final gameRef = data['gameRef'];
    if (gameRef is String && gameRef.isNotEmpty) {
      return _PushRoute(
        pageName: 'HostCheckin',
        parameterData: {'gameRef': gameRef},
      );
    }
  }
  if (type == 'peer_rating') {
    final gameRef = data['gameRef'];
    if (gameRef is String && gameRef.isNotEmpty) {
      return _PushRoute(
        pageName: 'PeerRating',
        parameterData: {'gameRef': gameRef},
      );
    }
  }
  if (type == 'fallback_confirmation') {
    final gameRef = data['gameRef'];
    if (gameRef is String && gameRef.isNotEmpty) {
      return _PushRoute(
        pageName: 'FallbackConfirmation',
        parameterData: {'gameRef': gameRef},
      );
    }
  }
  // Join request notifications (vibe floor)
  // Host receives new request - route to their game view
  if (type == 'join_request_new') {
    final gameId = data['game_id'] ?? data['gameId'];
    if (gameId is String && gameId.isNotEmpty) {
      return _PushRoute(
        pageName: 'GameJoinedDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }
  // User approved - they're now a participant, show their game view
  if (type == 'join_request_approved') {
    final gameId = data['game_id'] ?? data['gameId'];
    if (gameId is String && gameId.isNotEmpty) {
      return _PushRoute(
        pageName: 'GameJoinedDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }
  // User declined - show game details with disabled button
  if (type == 'join_request_declined') {
    final gameId = data['game_id'] ?? data['gameId'];
    if (gameId is String && gameId.isNotEmpty) {
      return _PushRoute(
        pageName: 'JoinGameDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }
  if (type == 'join_request_round_filled') {
    // Round is full, navigate to games list instead
    return const _PushRoute(
      pageName: 'GamesList',
      parameterData: {},
    );
  }
  // Friend request notifications
  if (type == 'friend_request_received') {
    return const _PushRoute(
      pageName: 'Tab_Friends',
      parameterData: {'initialSegment': 'requests'},
    );
  }
  if (type == 'friend_request_accepted') {
    return const _PushRoute(
      pageName: 'Tab_Friends',
      parameterData: {'initialSegment': 'friends'},
    );
  }
  // Streak notifications
  if (type == 'streak_weekend_nudge') {
    return const _PushRoute(
      pageName: 'GamesList',
      parameterData: {},
    );
  }
  if (type == 'streak_freeze_unlocked' ||
      type == 'streak_freeze_prompt' ||
      type == 'streak_milestone_reached' ||
      type == 'streak_broken') {
    return const _PushRoute(
      pageName: 'MainProfile',
      parameterData: {},
    );
  }
  // Host-added player notification - route to game details
  // The bottom sheet is shown via handleNotificationNavigation intercept
  if (type == 'player_added_by_host') {
    final gameId = data['game_id'] ?? data['gameId'];
    if (gameId is String && gameId.isNotEmpty) {
      return _PushRoute(
        pageName: 'GameJoinedDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }
  // Host notification when player declines - route to their game
  if (type == 'player_declined_spot') {
    final gameId = data['game_id'] ?? data['gameId'];
    if (gameId is String && gameId.isNotEmpty) {
      return _PushRoute(
        pageName: 'GameJoinedDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }

  // ===== Trust System Type Aliases =====
  // Map Trust event names to their routing destinations

  // Post-round Trust types (aliases for legacy routes)
  if (type == 'host_checkin_due') {
    final gameRef = data['gameRef'] ?? data['game_ref'];
    final gameId = data['gameId'] ?? data['game_id'];
    final ref = gameRef ?? (gameId != null ? 'games/$gameId' : null);
    if (ref is String && ref.isNotEmpty) {
      return _PushRoute(
        pageName: 'HostCheckin',
        parameterData: {'gameRef': ref},
      );
    }
  }
  if (type == 'host_checkin_fallback') {
    final gameRef = data['gameRef'] ?? data['game_ref'];
    final gameId = data['gameId'] ?? data['game_id'];
    final ref = gameRef ?? (gameId != null ? 'games/$gameId' : null);
    if (ref is String && ref.isNotEmpty) {
      return _PushRoute(
        pageName: 'FallbackConfirmation',
        parameterData: {'gameRef': ref},
      );
    }
  }
  if (type == 'player_rate_due') {
    final gameRef = data['gameRef'] ?? data['game_ref'];
    final gameId = data['gameId'] ?? data['game_id'];
    final ref = gameRef ?? (gameId != null ? 'games/$gameId' : null);
    if (ref is String && ref.isNotEmpty) {
      return _PushRoute(
        pageName: 'PeerRating',
        parameterData: {'gameRef': ref},
      );
    }
  }
  if (type == 'player_fallback_confirm') {
    final gameRef = data['gameRef'] ?? data['game_ref'];
    final gameId = data['gameId'] ?? data['game_id'];
    final ref = gameRef ?? (gameId != null ? 'games/$gameId' : null);
    if (ref is String && ref.isNotEmpty) {
      return _PushRoute(
        pageName: 'FallbackConfirmation',
        parameterData: {'gameRef': ref},
      );
    }
  }

  // Game Trust types
  if (type == 'game_spot_opened' || type == 'game_cancelled') {
    final gameId = data['gameId'] ?? data['game_id'];
    if (gameId is String && gameId.isNotEmpty) {
      return _PushRoute(
        pageName: 'JoinGameDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }
  if (type == 'game_alert_deferred') {
    final gameId = data['gameId'] ?? data['game_id'];
    if (gameId is String && gameId.isNotEmpty) {
      return _PushRoute(
        pageName: 'JoinGameDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }

  // Join request expired
  if (type == 'join_request_expired') {
    return const _PushRoute(
      pageName: 'GamesList',
      parameterData: {},
    );
  }

  // Trust account notifications → YourStanding
  if (type == 'no_show_flagged' ||
      type == 'dispute_resolved' ||
      type == 'strike_issued' ||
      type == 'cooldown_started' ||
      type == 'restriction_started' ||
      type == 'suspension_started' ||
      type == 'restriction_ended') {
    return const _PushRoute(
      pageName: 'YourStanding',
      parameterData: {},
    );
  }

  // Badge notifications → MainProfile
  if (type == 'badge_earned' || type == 'badge_progress') {
    return const _PushRoute(
      pageName: 'MainProfile',
      parameterData: {},
    );
  }

  // Pre-game confirmation (host confirms/cancels partial game)
  if (type == 'host_pre_game_confirm') {
    final gameId = data['gameId'] ?? data['game_id'];
    if (gameId is String && gameId.isNotEmpty) {
      return _PushRoute(
        pageName: 'GameJoinedDetailed',
        parameterData: {'gameRef': 'games/$gameId'},
      );
    }
  }

  return null;
}

// Top-level friends-only check (extracted from widget)
Future<bool> _shouldBlockFriendsOnlyGame(
  Map<String, dynamic> initialParameterData,
) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    return false;
  }

  final gameRef =
      getParameter<DocumentReference>(initialParameterData, 'gameRef');
  if (gameRef == null) {
    return false;
  }

  Map<String, dynamic>? data;
  try {
    final gameSnap = await gameRef.get();
    data = gameSnap.data() as Map<String, dynamic>?;
  } on FirebaseException catch (error) {
    AppLog.d(
      '❌ _shouldBlockFriendsOnlyGame: ${error.code} - ${error.message}',
    );
    // Don't block on permission-denied — let game detail widget handle it.
    // This prevents hosts from being blocked when Firestore rules reject
    // the read (e.g., stale auth token, rules not yet deployed).
    return false;
  } catch (_) {
    return false;
  }
  if (data == null) {
    return false;
  }

  final friendGameValue = (data['friendGame'] as String?) ?? '';
  final isFriendsOnly = friendGameValue == 'friends';
  if (!isFriendsOnly) {
    return false;
  }

  final ownerRef = data['userRef'];
  if (ownerRef is! DocumentReference) {
    return true;
  }

  // Host can always access their own game
  if (ownerRef.id == currentUser.uid) {
    return false;
  }

  final currentUserRef =
      FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
  final userSnap = await currentUserRef.get();
  final userData = userSnap.data() ?? {};
  final friends = userData['friends'];
  if (friends is List) {
    return !friends.any((entry) {
      if (entry is DocumentReference) {
        return entry.id == ownerRef.id;
      }
      if (entry is String) {
        if (entry.contains('/')) {
          final parts = entry.split('/');
          return parts.isNotEmpty && parts.last == ownerRef.id;
        }
        return entry == ownerRef.id;
      }
      return false;
    });
  }
  return true;
}

// Top-level friends-only dialog (extracted from widget)
Future<void> _showFriendsOnlyDialog(BuildContext context) async {
  await showPremiumDialog(
    context: context,
    variant: PremiumDialogVariant.informational,
    icon: PhosphorIconsRegular.lock,
    title: 'Friends Only Game',
    body: 'This game is visible to friends only. Add the host as a friend to view details.',
    actionLabel: 'Got It',
  );
}

class _PushRoute {
  const _PushRoute({
    required this.pageName,
    required this.parameterData,
  });

  final String pageName;
  final Map<String, dynamic> parameterData;
}

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
