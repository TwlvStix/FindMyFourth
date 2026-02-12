import 'dart:async';
import 'dart:ui';

import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/firebase/firebase_config.dart';
import '/core/config/build_flags.dart';
import '/core/app_theme.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/icon_size.dart';
import '/utils/app_util.dart';
import '/providers/user_provider.dart';
import '/providers/chat_provider.dart';
import '/providers/game_provider.dart';
import '/providers/profile_provider.dart';
import '/providers/notification_provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:find_my_fourth/friends/tab_friends/tab_friends_widget.dart';
import '/main_function/community/community_widget.dart';
import '/main_function/create_game/create_game_widget.dart';
import '/main_function/games_joined/games_joined_widget.dart';
import '/main_function/games_list/games_list_widget.dart';
import '/profile/main_profile/main_profile_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await runZonedGuarded(() async {
    GoRouter.optionURLReflectsImperativeAPIs = true;
    usePathUrlStrategy();
    await initFirebase();
    await _configureErrorAndLoggingGuards();

    final appState = AppState();
    await appState.initializePersistedState();

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
        ],
        child: MyApp(),
      ),
    );
  }, (error, stackTrace) {
    if (kIsWeb) {
      return;
    }
    FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
  });
}

Future<void> _configureErrorAndLoggingGuards() async {
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

  final shouldCollectCrashReports = kReleaseMode && kCrashlyticsEnabled;
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(shouldCollectCrashReports);
  await FirebaseCrashlytics.instance.setCustomKey('app_env', kAppEnv);
  await FirebaseCrashlytics.instance
      .setCustomKey('allow_internal_crash_test', kAllowInternalCrashTest);
  await FirebaseCrashlytics.instance
      .setCustomKey('enable_dev_ui', kEnableDevUi);

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

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  Timer? _splashFallbackTimer;
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
  late StreamSubscription<BaseAuthUser> _userStreamSub;
  late StreamSubscription<dynamic> _jwtTokenSub;

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

      if (!_initialAuthHandled) {
        _initialAuthHandled = true;
        _splashFallbackTimer?.cancel();
        debugPrint('✅ APP: Stopping splash screen and forcing navigation');
        _appStateNotifier.stopShowingSplashImage();

        // Force GoRouter to refresh by navigating to the appropriate route
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            debugPrint(
                '🚀 APP: Post-frame callback - navigating to ${_appStateNotifier.loggedIn ? "home" : "sign in"}');
            if (_appStateNotifier.loggedIn) {
              _router.go('/gamesList');
            } else {
              _router.go('/signIn');
            }
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
        debugPrint('✅ APP: Stopping splash screen (from error handler)');
        _appStateNotifier.stopShowingSplashImage();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            debugPrint(
                '🚀 APP: Error handler - navigating to ${_appStateNotifier.loggedIn ? "home" : "sign in"}');
            if (_appStateNotifier.loggedIn) {
              _router.go('/gamesList');
            } else {
              _router.go('/signIn');
            }
          }
        });
      }
    });

    _jwtTokenSub = jwtTokenStream.listen((_) {});

    debugPrint('⏱️  APP: Starting 3-second fallback timer');
    _splashFallbackTimer = Timer(const Duration(seconds: 3), () {
      debugPrint(
          '⏰ APP: Fallback timer triggered, _initialAuthHandled=$_initialAuthHandled, mounted=$mounted');
      if (mounted && !_initialAuthHandled) {
        _initialAuthHandled = true;
        _appStateNotifier.update(
          FindMyFourthFirebaseUser(FirebaseAuth.instance.currentUser),
        );
        debugPrint('✅ APP: Stopping splash screen (from fallback timer)');
        _appStateNotifier.stopShowingSplashImage();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            debugPrint(
                '🚀 APP: Fallback timer - navigating to ${_appStateNotifier.loggedIn ? "home" : "sign in"}');
            if (_appStateNotifier.loggedIn) {
              _router.go('/gamesList');
            } else {
              _router.go('/signIn');
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    authUserSub.cancel();
    _userStreamSub.cancel();
    _jwtTokenSub.cancel();
    _splashFallbackTimer?.cancel();
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
        if (!kReleaseMode || !kAllowInternalCrashTest) {
          return appChild;
        }
        return Stack(
          children: [
            appChild,
            const _InternalCrashTestOverlay(),
          ],
        );
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
          background: appColors.primaryBackground,
          onPrimary: appColors.primaryBtnText,
          onSecondary: appColors.primaryText,
          onSurface: appColors.primaryText,
          onBackground: appColors.primaryText,
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
            borderRadius: BorderRadius.circular(16.0),
            onLongPress: triggerInternalCrashForTesting,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16.0),
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

class NavBarPage extends StatefulWidget {
  NavBarPage({
    Key? key,
    this.initialPage,
    this.page,
    this.disableResizeToAvoidBottomInset = false,
  }) : super(key: key);

  final String? initialPage;
  final Widget? page;
  final bool disableResizeToAvoidBottomInset;

  @override
  _NavBarPageState createState() => _NavBarPageState();
}

/// This is the private State class that goes with NavBarPage.
class _NavBarPageState extends State<NavBarPage> {
  String _currentPageName = 'GamesList';
  late Widget? _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = {
      'GamesList': GamesListWidget(),
      'GamesJoined': GamesJoinedWidget(),
      'Golfers': TabFriendsWidget(),
      'Community': CommunityWidget(),
      'Profile': MainProfileWidget(),
    };
    final currentIndex = tabs.keys.toList().indexOf(_currentPageName);

    // Only show FAB on GamesList and GamesJoined (My Games) tabs
    final shouldShowFab =
        _currentPageName == 'GamesList' || _currentPageName == 'GamesJoined';

    return Scaffold(
      resizeToAvoidBottomInset: !widget.disableResizeToAvoidBottomInset,
      body: _currentPage ?? tabs[_currentPageName],
      floatingActionButton: shouldShowFab
          ? FloatingActionButton(
              onPressed: () {
                context.pushNamed(
                  CreateGameWidget.routeName,
                  extra: <String, dynamic>{
                    kTransitionInfoKey: TransitionInfo(
                      hasTransition: true,
                      transitionType: PageTransitionType.fade,
                      enterDuration: Duration(milliseconds: 200),
                      exitDuration: Duration(milliseconds: 170),
                      scaleOnPush: true,
                    ),
                  },
                );
              },
              backgroundColor: AppTheme.of(context).primary,
              elevation: 8.0,
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 28.0,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: GNav(
        selectedIndex: currentIndex,
        onTabChange: (i) {
          if (mounted) {
            setState(() {
              _currentPage = null;
              _currentPageName = tabs.keys.toList()[i];
            });
          }
        },
        backgroundColor: Colors.white,
        color: AppTheme.of(context).tertiary,
        activeColor: AppTheme.of(context).primary,
        tabBackgroundColor: Colors.transparent,
        tabBorderRadius: 0.0,
        tabMargin: EdgeInsets.all(AppSpacing.xxs),
        padding: EdgeInsets.all(AppSpacing.sm),
        gap: 0.0,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        duration:
            Duration.zero, // Instant tab switching per premium motion system
        haptic: false,
        tabs: [
          GButton(
            icon: Icons.golf_course,
            iconSize: AppIconSize.lg,
          ),
          GButton(
            icon: Icons.calendar_today_outlined,
            iconSize: AppIconSize.lg,
          ),
          GButton(
            icon: Icons.people_outline,
            iconSize: AppIconSize.lg,
          ),
          GButton(
            icon: Icons.chat_bubble_outline,
            iconSize: AppIconSize.lg,
          ),
          GButton(
            icon: Icons.person_outline,
            iconSize: AppIconSize.lg,
          )
        ],
      ),
    );
  }
}
