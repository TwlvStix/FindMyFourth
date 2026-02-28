import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:find_my_fourth/services/notification_orchestration_service.dart';

class _RecordingPermissionCoordinator
    implements NotificationPermissionCoordinator {
  _RecordingPermissionCoordinator({
    required this.events,
    this.onInit,
  });

  final List<String> events;
  final Future<void> Function(String uid)? onInit;

  int initCalls = 0;
  int resetCalls = 0;

  @override
  Future<void> init(String uid) async {
    initCalls++;
    events.add('permission.init:$uid');
    if (onInit != null) {
      await onInit!(uid);
    }
  }

  @override
  void reset() {
    resetCalls++;
    events.add('permission.reset');
  }
}

class _RecordingLocalCoordinator implements LocalNotificationCoordinator {
  _RecordingLocalCoordinator({
    required this.events,
    this.onInit,
  });

  final List<String> events;
  final Future<void> Function()? onInit;

  int initCalls = 0;
  int disposeCalls = 0;

  @override
  Future<void> init() async {
    initCalls++;
    events.add('local.init');
    if (onInit != null) {
      await onInit!();
    }
  }

  @override
  void dispose() {
    disposeCalls++;
    events.add('local.dispose');
  }
}

class _RecordingFcmCoordinator implements FcmNotificationCoordinator {
  _RecordingFcmCoordinator({required this.events});

  final List<String> events;

  int initCalls = 0;
  int disposeCalls = 0;

  @override
  Future<void> init() async {
    initCalls++;
    events.add('fcm.init');
  }

  @override
  void dispose() {
    disposeCalls++;
    events.add('fcm.dispose');
  }
}

void main() {
  group('NotificationOrchestrationService', () {
    late List<String> events;
    late String? currentUid;
    late _RecordingPermissionCoordinator permissionCoordinator;
    late _RecordingLocalCoordinator localCoordinator;
    late _RecordingFcmCoordinator fcmCoordinator;
    late NotificationOrchestrationService service;

    setUp(() {
      events = <String>[];
      currentUid = null;
      permissionCoordinator = _RecordingPermissionCoordinator(events: events);
      localCoordinator = _RecordingLocalCoordinator(events: events);
      fcmCoordinator = _RecordingFcmCoordinator(events: events);
      service = NotificationOrchestrationService(
        permissionCoordinator: permissionCoordinator,
        localCoordinator: localCoordinator,
        fcmCoordinator: fcmCoordinator,
        currentUidProvider: () => currentUid,
      );
    });

    tearDown(() {
      service.dispose();
    });

    test(
        'initial login initializes services in order and deduplicates same uid',
        () async {
      currentUid = 'u1';

      await service.onUserChanged('u1');

      expect(events, ['permission.init:u1', 'local.init', 'fcm.init']);

      await service.onUserChanged('u1');
      expect(events, ['permission.init:u1', 'local.init', 'fcm.init']);
    });

    test('uid switch shuts down old user and initializes new user', () async {
      currentUid = 'u1';
      await service.onUserChanged('u1');
      events.clear();

      currentUid = 'u2';
      await service.onUserChanged('u2');

      expect(events, [
        'fcm.dispose',
        'local.dispose',
        'permission.reset',
        'permission.init:u2',
        'local.init',
        'fcm.init',
      ]);
    });

    test('logout shuts down notification services', () async {
      currentUid = 'u1';
      await service.onUserChanged('u1');
      events.clear();

      currentUid = null;
      await service.onUserChanged(null);

      expect(events, ['fcm.dispose', 'local.dispose', 'permission.reset']);
    });

    test('stale initialization is aborted after rapid account switch',
        () async {
      final permissionGate = Completer<void>();
      permissionCoordinator = _RecordingPermissionCoordinator(
        events: events,
        onInit: (uid) async {
          if (uid == 'u1') {
            await permissionGate.future;
          }
        },
      );
      service = NotificationOrchestrationService(
        permissionCoordinator: permissionCoordinator,
        localCoordinator: localCoordinator,
        fcmCoordinator: fcmCoordinator,
        currentUidProvider: () => currentUid,
      );

      currentUid = 'u1';
      final firstInit = service.onUserChanged('u1');
      await Future<void>.delayed(Duration.zero);

      currentUid = 'u2';
      final secondInit = service.onUserChanged('u2');
      await secondInit;

      permissionGate.complete();
      await firstInit;

      expect(events.where((e) => e == 'permission.init:u1').length, 1);
      expect(events.where((e) => e == 'permission.init:u2').length, 1);
      expect(events.where((e) => e == 'local.init').length, 1);
      expect(events.where((e) => e == 'fcm.init').length, 1);
    });

    test('failed initialization can recover on next onUserChanged call',
        () async {
      var failOnce = true;
      localCoordinator = _RecordingLocalCoordinator(
        events: events,
        onInit: () async {
          if (failOnce) {
            failOnce = false;
            throw StateError('local init failed');
          }
        },
      );
      service = NotificationOrchestrationService(
        permissionCoordinator: permissionCoordinator,
        localCoordinator: localCoordinator,
        fcmCoordinator: fcmCoordinator,
        currentUidProvider: () => currentUid,
      );

      currentUid = 'u1';
      await service.onUserChanged('u1');
      expect(events, ['permission.init:u1', 'local.init']);

      events.clear();
      await service.onUserChanged('u1');
      expect(events, ['permission.init:u1', 'local.init', 'fcm.init']);
    });
  });
}
