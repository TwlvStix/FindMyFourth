import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '/core/utils/app_log.dart';
import '/services/fcm_notification_service.dart';
import '/services/local_notifications_service.dart';
import '/services/notification_permission_service.dart';

abstract class NotificationPermissionCoordinator {
  Future<void> init(String uid);
  Future<void> removeDeviceToken(String uid);
  void reset();
}

abstract class LocalNotificationCoordinator {
  Future<void> init();
  void dispose();
}

abstract class FcmNotificationCoordinator {
  Future<void> init();
  void dispose();
}

class _DefaultPermissionCoordinator
    implements NotificationPermissionCoordinator {
  _DefaultPermissionCoordinator(this._service);

  final NotificationPermissionService _service;

  @override
  Future<void> init(String uid) => _service.init(uid);

  @override
  Future<void> removeDeviceToken(String uid) => _service.removeDeviceToken(uid);

  @override
  void reset() => _service.reset();
}

class _DefaultLocalCoordinator implements LocalNotificationCoordinator {
  _DefaultLocalCoordinator(this._service);

  final LocalNotificationsService _service;

  @override
  Future<void> init() => _service.init();

  @override
  void dispose() => _service.dispose();
}

class _DefaultFcmCoordinator implements FcmNotificationCoordinator {
  _DefaultFcmCoordinator(this._service);

  final FcmNotificationService _service;

  @override
  Future<void> init() => _service.init();

  @override
  void dispose() => _service.dispose();
}

/// Coordinates notification lifecycle across auth changes.
class NotificationOrchestrationService {
  NotificationOrchestrationService({
    NotificationPermissionCoordinator? permissionCoordinator,
    LocalNotificationCoordinator? localCoordinator,
    FcmNotificationCoordinator? fcmCoordinator,
    String? Function()? currentUidProvider,
  })  : _permissionCoordinator = permissionCoordinator ??
            _DefaultPermissionCoordinator(NotificationPermissionService()),
        _localCoordinator = localCoordinator ??
            _DefaultLocalCoordinator(LocalNotificationsService()),
        _fcmCoordinator =
            fcmCoordinator ?? _DefaultFcmCoordinator(FcmNotificationService()),
        _currentUidProvider = currentUidProvider ??
            (() => FirebaseAuth.instance.currentUser?.uid);

  final NotificationPermissionCoordinator _permissionCoordinator;
  final LocalNotificationCoordinator _localCoordinator;
  final FcmNotificationCoordinator _fcmCoordinator;
  final String? Function() _currentUidProvider;

  int _generation = 0;
  String? _activeUid;
  String? _initializingUid;
  bool _disposed = false;

  Future<void> onUserChanged(String? uid) async {
    AppLog.d('[DIAG-ORCH] onUserChanged: uid=$uid, activeUid=$_activeUid, initializingUid=$_initializingUid, disposed=$_disposed');

    if (_disposed) {
      AppLog.d('[DIAG-ORCH] onUserChanged: SKIPPED - disposed');
      return;
    }

    final normalizedUid = uid?.trim();
    if (normalizedUid == null || normalizedUid.isEmpty) {
      AppLog.d('[DIAG-ORCH] onUserChanged: calling shutdown (null/empty uid)');
      shutdown();
      return;
    }

    if (_activeUid == normalizedUid || _initializingUid == normalizedUid) {
      AppLog.d(
        '[NotificationOrchestration] User unchanged ($normalizedUid), skipping',
      );
      return;
    }

    if (_activeUid != null || _initializingUid != null) {
      AppLog.d('[DIAG-ORCH] onUserChanged: calling shutdown before initialize (switching users)');
      shutdown();
    }

    await initialize(normalizedUid);
  }

  Future<void> initialize(String uid) async {
    if (_disposed || uid.trim().isEmpty) {
      AppLog.d('[DIAG-ORCH] initialize: SKIPPED - disposed=$_disposed, uid="${uid.trim()}"');
      return;
    }
    final normalizedUid = uid.trim();
    if (_activeUid == normalizedUid || _initializingUid == normalizedUid) {
      AppLog.d('[DIAG-ORCH] initialize: SKIPPED - already active/initializing');
      return;
    }

    final generation = ++_generation;
    _initializingUid = normalizedUid;

    AppLog.d('[DIAG-ORCH] initialize: starting for uid=$normalizedUid, generation=$generation');

    try {
      await _permissionCoordinator.init(normalizedUid);
      if (_shouldAbort(generation, normalizedUid, 'permission init')) {
        return;
      }

      await _localCoordinator.init();
      if (_shouldAbort(generation, normalizedUid, 'local init')) {
        return;
      }

      await _fcmCoordinator.init();
      if (_shouldAbort(generation, normalizedUid, 'fcm init')) {
        return;
      }

      _activeUid = normalizedUid;
      AppLog.d(
          '[NotificationOrchestration] Initialized for uid=$normalizedUid');
    } catch (error) {
      AppLog.d(
        '[NotificationOrchestration] Initialization failed for uid=$normalizedUid: $error',
      );
    } finally {
      if (_initializingUid == normalizedUid) {
        _initializingUid = null;
      }
    }
  }

  bool _shouldAbort(int generation, String expectedUid, String phase) {
    final currentUid = _currentUidProvider();
    AppLog.d('[DIAG-ORCH] _shouldAbort: phase=$phase, disposed=$_disposed, generation=$generation vs $_generation, expectedUid=$expectedUid vs currentUid=$currentUid');

    if (_disposed) {
      AppLog.d(
        '[NotificationOrchestration] Aborting $phase for uid=$expectedUid: disposed',
      );
      return true;
    }
    if (generation != _generation) {
      AppLog.d(
        '[NotificationOrchestration] Aborting $phase for uid=$expectedUid: stale generation',
      );
      return true;
    }

    if (currentUid != expectedUid) {
      AppLog.d(
        '[NotificationOrchestration] Aborting $phase for uid=$expectedUid: current uid=$currentUid',
      );
      return true;
    }

    return false;
  }

  void shutdown() {
    AppLog.d('[DIAG-ORCH] shutdown: activeUid=$_activeUid, initializingUid=$_initializingUid');

    if (_activeUid == null && _initializingUid == null) {
      AppLog.d('[DIAG-ORCH] shutdown: SKIPPED - no active or initializing uid');
      return;
    }

    final previousUid = _activeUid ?? _initializingUid;
    _generation++;
    _activeUid = null;
    _initializingUid = null;

    // Best-effort FCM token cleanup — fire-and-forget so shutdown stays sync
    if (previousUid != null) {
      unawaited(_permissionCoordinator.removeDeviceToken(previousUid));
    }

    AppLog.d('[DIAG-ORCH] shutdown: calling fcmCoordinator.dispose()');
    _fcmCoordinator.dispose();
    AppLog.d('[DIAG-ORCH] shutdown: calling localCoordinator.dispose()');
    _localCoordinator.dispose();
    AppLog.d('[DIAG-ORCH] shutdown: calling permissionCoordinator.reset()');
    _permissionCoordinator.reset();

    AppLog.d(
        '[NotificationOrchestration] Shutdown complete for uid=$previousUid');
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    shutdown();
    _disposed = true;
  }
}
