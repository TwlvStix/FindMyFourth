import 'dart:async';
import 'dart:ui';

import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/firebase/firebase_config.dart';
import '/core/config/build_flags.dart';
import '/core/app_theme.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/border_radius.dart';
import '/utils/app_util.dart';
import '/providers/user_provider.dart';
import '/providers/chat_provider.dart';
import '/providers/game_provider.dart';
import '/providers/group_vibe_provider.dart';
import '/providers/join_request_provider.dart';
import '/providers/profile_provider.dart';
import '/providers/notification_provider.dart';
import '/providers/trust_provider.dart';
import '/services/notification_orchestration_service.dart';
import '/services/remote_config_service.dart';

Future<void> main() async {
  // 🚀 STARTUP TIMING: Record start time (debug only)
  final startTime = kDebugMode ? DateTime.now() : null;

  await runZonedGuarded(() async {
    // ✅ CRITICAL: Must be in same zone as runApp
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    GoRouter.optionURLReflectsImperativeAPIs = true;
    usePathUrlStrategy();

    // ✅ CRITICAL: Must complete before runApp
    await initFirebase();

    // ✅ CRITICAL: Set up error handlers immediately (synchronous)
    _setupErrorHandlers();

    // ✅ CRITICAL: Create AppState instance (but don't load persisted state yet)
    final appState = AppState();

    // 🚀 OPTIMIZATION: Show first frame ASAP
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>(create: (_) => appState),
          ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
          ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider()),
          ChangeNotifierProvider<GameProvider>(create: (_) => GameProvider()),
          ChangeNotifierProvider<ProfileProvider>(
              create: (_) => ProfileProvider()),
          ChangeNotifierProvider<NotificationProvider>(
              create: (_) => NotificationProvider()),
          ChangeNotifierProvider<TrustProvider>(create: (_) => TrustProvider()),
          ChangeNotifierProvider<JoinRequestProvider>(
              create: (_) => JoinRequestProvider()),
          ChangeNotifierProvider<GroupVibeProvider>(
              create: (_) => GroupVibeProvider()),
        ],
        child: MyApp(),
      ),
    );

    // 🔄 POST-FRAME: Non-critical initialization after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 🚀 STARTUP TIMING: Log time to first frame (debug only)
      if (kDebugMode && startTime != null) {
        final timeToFirstFrame = DateTime.now().difference(startTime);
        debugPrint(
          '⚡ STARTUP TIMING: Time to first frame: ${timeToFirstFrame.inMilliseconds}ms',
        );
      }

      // Start non-critical background work
      _initializeNonCriticalServices(appState);
    });
  }, (error, stackTrace) {
    if (kIsWeb) {
      return;
    }
    FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
  });
}

/// Set up error handlers immediately (synchronous, no await)
/// This ensures errors are captured from the start, but doesn't block first frame
void _setupErrorHandlers() {
  if (kReleaseMode) {
    debugPrint = (String? _, {int? wrapWidth}) {};
  }

  if (kReleaseMode && kEnableDevUi) {
    throw StateError(
      'Release build cannot enable dev-only UI. Set ENABLE_DEV_UI=false.',
    );
  }

  if (kIsWeb) {
    return;
  }

  // Set up error handlers immediately (synchronous)
  final previousFlutterErrorHandler = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    previousFlutterErrorHandler?.call(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    return true;
  };
}

/// Initialize non-critical services after first frame
/// This includes Crashlytics metadata and persisted state
/// Note: Notification service is initialized by the auth stream listener
Future<void> _initializeNonCriticalServices(AppState appState) async {
  try {
    // Load persisted state in background (doesn't block UI)
    await appState.initializePersistedState();

    // Set Crashlytics metadata (just metadata, not critical)
    await _configureCrashlyticsMetadata();

    // Initialize Remote Config (non-blocking, uses defaults if fails)
    await RemoteConfigService.instance.initialize();
  } catch (error, stackTrace) {
    debugPrint('⚠️  Non-critical initialization failed: $error');
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Non-critical post-frame initialization failed',
      );
    }
  }
}

/// Configure Crashlytics metadata (non-critical, can happen after first frame)
Future<void> _configureCrashlyticsMetadata() async {
  if (kIsWeb) {
    return;
  }

  final shouldCollectCrashReports = kReleaseMode && kCrashlyticsEnabled;
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(shouldCollectCrashReports);
  await FirebaseCrashlytics.instance.setCustomKey('app_env', kAppEnv);
  await FirebaseCrashlytics.instance
      .setCustomKey('allow_internal_crash_test', kAllowInternalCrashTest);
  await FirebaseCrashlytics.instance
      .setCustomKey('enable_dev_ui', kEnableDevUi);
}

void triggerInternalCrashForTesting() {
  if (!kReleaseMode || !kAllowInternalCrashTest || kIsWeb) {
    return;
  }
  FirebaseCrashlytics.instance.crash();
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MyAppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  final NotificationOrchestrationService _notificationOrchestrationService =
      NotificationOrchestrationService();

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  Timer? _splashFallbackTimer;
  bool _nativeSplashRemoved = false;
  bool _startupRevealTriggered = false;
  bool _startupOverlayVisible = true;
  bool _startupOverlayDisposed = false;
  String getRoute([RouteMatchBase? routeMatch]) {
    final RouteMatchBase lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  late Stream<BaseAuthUser> userStream;
  bool _initialAuthHandled = false;

  final authUserSub = authenticatedUserStream.listen((_) {});
  final privateDataSub = privateUserDataStream.listen((_) {});
  late StreamSubscription<BaseAuthUser> _userStreamSub;
  late StreamSubscription<dynamic> _jwtTokenSub;

  void _removeNativeSplashIfNeeded() {
    if (_nativeSplashRemoved) {
      return;
    }
    _nativeSplashRemoved = true;
    FlutterNativeSplash.remove();
    _startStartupRevealIfNeeded();
  }

  void _startStartupRevealIfNeeded() {
    if (_startupRevealTriggered || !mounted) {
      return;
    }
    _startupRevealTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 180), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _startupOverlayVisible = false;
        });
      });
    });
  }

  void _navigateFromStartup() {
    final targetPath = _appStateNotifier.loggedIn ? '/gamesList' : '/signIn';
    _router.go(
      targetPath,
      extra: <String, dynamic>{
        kTransitionInfoKey: const TransitionInfo(
          hasTransition: true,
          transitionType: AppTransitionType.fade,
          enterDuration: Duration(milliseconds: 260),
          exitDuration: Duration(milliseconds: 220),
          scaleOnPush: false,
        ),
      },
    );
  }

  @override
  void initState() {
    super.initState();

    debugPrint('🚀 APP: Initializing app state');
    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    userStream = findMyFourthFirebaseUserStream();

    debugPrint('👂 APP: Setting up auth stream listener');
    _userStreamSub = userStream.listen((user) {
      debugPrint('👤 APP: Auth stream emitted user: ${user.uid ?? "null"}');

      debugPrint('📝 APP: Calling update() first');
      _appStateNotifier.update(user);
      debugPrint(
          '📊 APP: update() completed, authStateReady=${_appStateNotifier.authStateReady}');

      final newUid = user.loggedIn ? user.uid : null;
      debugPrint('🔔 APP: Delegating notification lifecycle for uid=$newUid');
      unawaited(_notificationOrchestrationService.onUserChanged(newUid));

      if (!_initialAuthHandled) {
        _initialAuthHandled = true;
        _splashFallbackTimer?.cancel();
        debugPrint('✅ APP: Removing native splash and forcing navigation');
        _removeNativeSplashIfNeeded();

        // Force GoRouter to refresh by navigating to the appropriate route
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            debugPrint(
                '🚀 APP: Post-frame callback - navigating to ${_appStateNotifier.loggedIn ? "home" : "sign in"}');
            _navigateFromStartup();
          }
        });
      }
    }, onError: (error, stackTrace) {
      debugPrint('❌ APP: Auth stream error: $error');
      if (!_initialAuthHandled) {
        _initialAuthHandled = true;
        _splashFallbackTimer?.cancel();
        _appStateNotifier.update(
          FindMyFourthFirebaseUser(FirebaseAuth.instance.currentUser),
        );
        debugPrint('✅ APP: Removing native splash (from error handler)');
        _removeNativeSplashIfNeeded();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            debugPrint(
                '🚀 APP: Error handler - navigating to ${_appStateNotifier.loggedIn ? "home" : "sign in"}');
            _navigateFromStartup();
          }
        });
      }
    });

    _jwtTokenSub = jwtTokenStream.listen(
      (_) {},
      onError: (error, stackTrace) {
        debugPrint('⚠️ APP: JWT token stream error: $error');
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

    debugPrint('⏱️  APP: Starting 3-second fallback timer');
    _splashFallbackTimer = Timer(const Duration(seconds: 3), () {
      debugPrint(
          '⏰ APP: Fallback timer triggered, _initialAuthHandled=$_initialAuthHandled, mounted=$mounted');
      if (mounted && !_initialAuthHandled) {
        _initialAuthHandled = true;
        _appStateNotifier.update(
          FindMyFourthFirebaseUser(FirebaseAuth.instance.currentUser),
        );
        debugPrint('✅ APP: Removing native splash (from fallback timer)');
        _removeNativeSplashIfNeeded();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            debugPrint(
                '🚀 APP: Fallback timer - navigating to ${_appStateNotifier.loggedIn ? "home" : "sign in"}');
            _navigateFromStartup();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    authUserSub.cancel();
    privateDataSub.cancel();
    _userStreamSub.cancel();
    _jwtTokenSub.cancel();
    _notificationOrchestrationService.dispose();
    _splashFallbackTimer?.cancel();
    _removeNativeSplashIfNeeded();
    super.dispose();
  }

  void setThemeMode(ThemeMode mode) {
    if (mounted) {
      setState(() {
        _themeMode = mode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const appColors = AppThemeColors.light;
    final textTheme = AppTypography.createTextTheme().apply(
      bodyColor: appColors.primaryText,
      displayColor: appColors.primaryText,
    );
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Find My Fourth',
      scrollBehavior: MyAppScrollBehavior(),
      scaffoldMessengerKey: scaffoldMessengerKey,
      builder: (context, child) {
        final appChild = child ?? const SizedBox.shrink();
        final startupOverlay = _startupOverlayDisposed
            ? const SizedBox.shrink()
            : IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _startupOverlayVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeInOutCubic,
                  onEnd: () {
                    if (!_startupOverlayVisible &&
                        !_startupOverlayDisposed &&
                        mounted) {
                      setState(() {
                        _startupOverlayDisposed = true;
                      });
                    }
                  },
                  child: ColoredBox(color: appColors.primaryBackground),
                ),
              );

        final children = <Widget>[
          appChild,
          Positioned.fill(child: startupOverlay),
        ];

        if (kReleaseMode && kAllowInternalCrashTest) {
          children.add(const _InternalCrashTestOverlay());
        }

        return Stack(children: children);
      },
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        extensions: const [AppThemeColors.light],
        textTheme: textTheme,
        primaryTextTheme: textTheme,
        scaffoldBackgroundColor: appColors.primaryBackground,
        colorScheme: ColorScheme.light(
          primary: appColors.primary,
          secondary: appColors.secondary,
          error: appColors.error,
          surface: appColors.secondaryBackground,
          onPrimary: appColors.primaryBtnText,
          onSecondary: appColors.primaryText,
          onSurface: appColors.primaryText,
          onError: appColors.info,
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: WidgetStateProperty.all(false),
          thickness: WidgetStateProperty.all(5.0),
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.dragged)) {
              return Color(4282393936);
            }
            if (states.contains(WidgetState.hovered)) {
              return Color(4282393936);
            }
            return Color(4282393936);
          }),
        ),
        useMaterial3: false,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}

class _InternalCrashTestOverlay extends StatelessWidget {
  const _InternalCrashTestOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppSpacing.md,
      bottom: AppSpacing.md,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            onLongPress: triggerInternalCrashForTesting,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: const Text(
                'Hold to Crash Test',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
