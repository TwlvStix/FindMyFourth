import 'dart:async';
import 'dart:ui';

import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/firebase/firebase_config.dart';
import '/core/config/build_flags.dart';
import '/core/bootstrap/app_bootstrap_coordinator.dart';
import '/core/app_theme.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/border_radius.dart';
import '/utils/app_util.dart';
import '/core/utils/app_log.dart';
import '/providers/user_provider.dart';
import '/providers/chat_provider.dart';
import '/providers/game_provider.dart';
import '/providers/group_vibe_provider.dart';
import '/providers/join_request_provider.dart';
import '/providers/profile_provider.dart';
import '/providers/notification_provider.dart';
import '/providers/notification_list_provider.dart';
import '/providers/streak_provider.dart';
import '/providers/trust_provider.dart';
import '/services/notification_audit_service.dart';
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

    // ✅ CRITICAL: Create AppState instance and load persisted state
    final appState = AppState();
    try {
      await appState.initializePersistedState();
    } catch (e, stackTrace) {
      AppLog.d('⚠️ AppState.initializePersistedState failed: $e');
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          e,
          stackTrace,
          reason: 'AppState.initializePersistedState failed at startup',
        );
      }
      // Continue with in-memory defaults - app still works
    }

    // ✅ CRITICAL: Set Remote Config defaults before any UI can trigger joins
    // This is a local operation (<1ms) and guarantees safe vibe floor fallback
    await RemoteConfigService.instance.ensureDefaults();

    // 🚀 Show first frame
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
          ChangeNotifierProvider<NotificationListProvider>(
              create: (_) => NotificationListProvider()),
          ChangeNotifierProvider<TrustProvider>(create: (_) => TrustProvider()),
          ChangeNotifierProvider<StreakProvider>(
              create: (_) => StreakProvider()),
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
        AppLog.d(
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
/// This includes Crashlytics metadata and Remote Config network fetch
/// Note: Remote Config defaults already set before runApp() via ensureDefaults()
/// Note: Notification service is initialized by the auth stream listener
Future<void> _initializeNonCriticalServices(AppState appState) async {
  try {
    // Set Crashlytics metadata (just metadata, not critical)
    await _configureCrashlyticsMetadata();

    // Fetch remote config values (defaults already set before runApp)
    await RemoteConfigService.instance.initialize();
  } catch (error, stackTrace) {
    AppLog.d('⚠️ Non-critical initialization failed: $error');
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
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => MyAppState();

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;
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

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.system;
  final NotificationOrchestrationService _notificationOrchestrationService =
      NotificationOrchestrationService();

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  late AppBootstrapCoordinator _bootstrapCoordinator;
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

  final authUserSub = authenticatedUserStream.listen((_) {});
  final privateDataSub = privateUserDataStream.listen((_) {});

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

    // Register lifecycle observer for notification audit flush
    WidgetsBinding.instance.addObserver(this);

    AppLog.d('🚀 APP: Initializing app state');
    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);

    _bootstrapCoordinator = AppBootstrapCoordinator(
      appStateNotifier: _appStateNotifier,
      notificationOrchestrationService: _notificationOrchestrationService,
      userStream: findMyFourthFirebaseUserStream(),
      jwtTokenStream: jwtTokenStream,
      removeNativeSplash: _removeNativeSplashIfNeeded,
      navigateFromStartup: () {
        if (!mounted) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _navigateFromStartup();
          }
        });
      },
    );
    _bootstrapCoordinator.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    authUserSub.cancel();
    privateDataSub.cancel();
    _bootstrapCoordinator.dispose();
    _notificationOrchestrationService.dispose();
    _removeNativeSplashIfNeeded();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Flush notification audit events when app goes to background
    if (state == AppLifecycleState.paused) {
      NotificationAuditService.instance.flush();
    }
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
          thumbColor: WidgetStateProperty.all(AppColors.scrollbarThumb),
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
          color: AppColors.transparent,
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
              child: Text(
                'Hold to Crash Test',
                style: TextStyle(
                  color: AppColors.pure,
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
