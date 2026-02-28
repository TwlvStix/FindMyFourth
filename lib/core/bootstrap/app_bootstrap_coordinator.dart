import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '/auth/firebase_auth/firebase_user_provider.dart';
import '/core/navigation/app_router.dart';
import '/core/utils/app_log.dart';
import '/services/notification_orchestration_service.dart';

class AppBootstrapCoordinator {
  AppBootstrapCoordinator({
    required AppStateNotifier appStateNotifier,
    required NotificationOrchestrationService notificationOrchestrationService,
    required Stream<BaseAuthUser> userStream,
    required Stream<dynamic> jwtTokenStream,
    required void Function() removeNativeSplash,
    required void Function() navigateFromStartup,
    FirebaseAuth? auth,
  })  : _appStateNotifier = appStateNotifier,
        _notificationOrchestrationService = notificationOrchestrationService,
        _userStream = userStream,
        _jwtTokenStream = jwtTokenStream,
        _removeNativeSplash = removeNativeSplash,
        _navigateFromStartup = navigateFromStartup,
        _auth = auth ?? FirebaseAuth.instance;

  final AppStateNotifier _appStateNotifier;
  final NotificationOrchestrationService _notificationOrchestrationService;
  final Stream<BaseAuthUser> _userStream;
  final Stream<dynamic> _jwtTokenStream;
  final void Function() _removeNativeSplash;
  final void Function() _navigateFromStartup;
  final FirebaseAuth _auth;

  StreamSubscription<BaseAuthUser>? _userStreamSub;
  StreamSubscription<dynamic>? _jwtTokenSub;
  Timer? _splashFallbackTimer;
  bool _initialAuthHandled = false;
  bool _disposed = false;

  void start() {
    if (_disposed || _userStreamSub != null) {
      return;
    }

    _userStreamSub = _userStream.listen(
      (user) {
        _appStateNotifier.update(user);
        final newUid = user.loggedIn ? user.uid : null;
        unawaited(_notificationOrchestrationService.onUserChanged(newUid));
        _completeStartupOnce();
      },
      onError: (error, stackTrace) {
        AppLog.d('❌ APP: Auth stream error: $error');
        _appStateNotifier.update(
          FindMyFourthFirebaseUser(_auth.currentUser),
        );
        _completeStartupOnce();
      },
    );

    _jwtTokenSub = _jwtTokenStream.listen(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        AppLog.d('⚠️ APP: JWT token stream error: $error');
        if (!kIsWeb) {
          FirebaseCrashlytics.instance.recordError(
            error,
            stackTrace,
            reason: 'JWT token stream listener error',
            fatal: false,
          );
        }
      },
    );

    _splashFallbackTimer = Timer(const Duration(seconds: 3), () {
      if (_disposed || _initialAuthHandled) {
        return;
      }
      _appStateNotifier.update(
        FindMyFourthFirebaseUser(_auth.currentUser),
      );
      _completeStartupOnce();
    });
  }

  void _completeStartupOnce() {
    if (_initialAuthHandled || _disposed) {
      return;
    }
    _initialAuthHandled = true;
    _splashFallbackTimer?.cancel();
    _removeNativeSplash();
    _navigateFromStartup();
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _splashFallbackTimer?.cancel();
    _userStreamSub?.cancel();
    _jwtTokenSub?.cancel();
  }
}
