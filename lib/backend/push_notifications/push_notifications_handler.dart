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
import '/core/design_tokens/colors.dart';
import '/core/widgets/app_premium_dialog.dart';

final _handledMessageIds = <String?>{};

class _PushRoute {
  const _PushRoute({
    required this.pageName,
    required this.parameterData,
  });

  final String pageName;
  final Map<String, dynamic> parameterData;
}

class PushNotificationsHandler extends StatefulWidget {
  const PushNotificationsHandler({Key? key, required this.child})
      : super(key: key);

  final Widget child;

  @override
  _PushNotificationsHandlerState createState() =>
      _PushNotificationsHandlerState();
}

class _PushNotificationsHandlerState extends State<PushNotificationsHandler> {
  bool _loading = false;
  Timer? _loadingTimeout;

  // Static flag to ensure only ONE listener per app session
  static bool _listenerInitialized = false;

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
    return null;
  }

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
      if (error.code == 'permission-denied') {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
    if (data == null) {
      return false;
    }

    final friendGameValue = (data['friendGame'] as String?) ?? '';
    final isFriendsOnly = friendGameValue.trim().toLowerCase() == 'friends';
    if (!isFriendsOnly) {
      return false;
    }

    final ownerRef = data['userRef'];
    if (ownerRef is! DocumentReference) {
      return true;
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

  Future handleOpenedPushNotification() async {
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
      await _handlePushNotification(notification);
    }

    // Listen for push notifications opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handlePushNotification);
  }

  Future _handlePushNotification(RemoteMessage message) async {
    if (_handledMessageIds.contains(message.messageId)) {
      return;
    }
    _handledMessageIds.add(message.messageId);

    if (mounted) {
      setState(() => _loading = true);
      _loadingTimeout?.cancel();
      _loadingTimeout = Timer(const Duration(seconds: 3), () {
        if (mounted && _loading) {
          setState(() => _loading = false);
        }
      });
    }
    try {
      final resolvedRoute = _resolveRouteFromType(message.data);
      final rawPageName = message.data['initialPageName'];
      final initialPageName = resolvedRoute?.pageName ??
          (rawPageName is String && rawPageName.isNotEmpty
              ? rawPageName
              : null);
      final initialParameterData =
          resolvedRoute?.parameterData ?? getInitialParameterData(message.data);
      if (initialPageName == null) {
        return;
      }
      if (initialPageName == 'JoinGameDetailed') {
        final shouldBlock = await _shouldBlockFriendsOnlyGame(
          initialParameterData,
        );
        if (shouldBlock) {
          final dialogContext =
              mounted ? context : appNavigatorKey.currentContext;
          if (dialogContext != null) {
            await _showFriendsOnlyDialog(dialogContext);
          }
          return;
        }
      }
      final parametersBuilder = parametersBuilderMap[initialPageName];
      if (parametersBuilder != null) {
        final parameterData = await parametersBuilder(initialParameterData);
        if (mounted) {
          context.pushNamed(
            initialPageName,
            pathParameters: parameterData.pathParameters,
            extra: parameterData.extra,
          );
        } else {
          appNavigatorKey.currentContext?.pushNamed(
            initialPageName,
            pathParameters: parameterData.pathParameters,
            extra: parameterData.extra,
          );
        }
      }
    } catch (e) {
      AppLog.d('Error: $e');
    } finally {
      _loadingTimeout?.cancel();
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      handleOpenedPushNotification();
    });
  }

  @override
  void dispose() {
    _loadingTimeout?.cancel();
    // Note: The onMessageOpenedApp listener is not cancelled here as it
    // persists for the app lifetime and is deduplicated by _listenerInitialized.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _loading
      ? Container(
          color: AppColors.navyDark,
          child: Image.asset(
            'assets/images/Blackfixed.png',
            fit: BoxFit.contain,
          ),
        )
      : widget.child;
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
  'Tab_Friends': ParameterData.none(),
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
