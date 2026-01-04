import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/push_notifications/push_notifications_util.dart';
import 'backend/firebase/firebase_config.dart';
import '/core/app_theme.dart';
import '/core/app_util.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await initFirebase();

  final appState = AppState();
  await appState.initializePersistedState();

  runApp(ChangeNotifierProvider<AppState>(
    create: (context) => appState,
    child: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

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
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
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

  final authUserSub = authenticatedUserStream.listen((_) {});
  final fcmTokenSub = fcmTokenUserStream.listen((_) {});

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    userStream = findMyFourthFirebaseUserStream()
      ..listen((user) {
        _appStateNotifier.update(user);
      });
    jwtTokenStream.listen((_) {});
    Future.delayed(
      Duration(milliseconds: 1000),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
  }

  @override
  void dispose() {
    authUserSub.cancel();
    fcmTokenSub.cancel();
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
    final textTheme = GoogleFonts.outfitTextTheme().apply(
      bodyColor: appColors.primaryText,
      displayColor: appColors.primaryText,
    );
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Find My Fourth',
      scrollBehavior: MyAppScrollBehavior(),
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
  String _currentPageName = 'Home';
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
      'CreateGame': CreateGameWidget(),
      'Home': HomeWidget(),
      'GamesJoined': GamesJoinedWidget(),
      'Chat': ChatWidget(),
      'Newsfeed': NewsfeedWidget(),
    };
    final currentIndex = tabs.keys.toList().indexOf(_currentPageName);

    return Scaffold(
      resizeToAvoidBottomInset: !widget.disableResizeToAvoidBottomInset,
      body: _currentPage ?? tabs[_currentPageName],
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
        color: AppTheme.of(context).primary,
        activeColor: Color(0xFF402550),
        tabBackgroundColor: AppTheme.of(context).primaryBtnText,
        tabBorderRadius: 100.0,
        tabMargin: EdgeInsets.all(6.0),
        padding: EdgeInsets.all(6.0),
        gap: 0.0,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        duration: Duration(milliseconds: 500),
        haptic: false,
        tabs: [
          GButton(
            icon: Icons.list_alt,
            text: 'Games List',
            iconSize: 24.0,
            backgroundColor: AppTheme.of(context).primaryBackground,
          ),
          GButton(
            icon: FontAwesomeIcons.plus,
            text: 'Add Game',
            iconSize: 24.0,
            backgroundColor: Color(0xFFE0E0DB),
          ),
          GButton(
            icon: Icons.home_outlined,
            text: '',
            iconSize: 24.0,
          ),
          GButton(
            icon: Icons.calendar_month,
            text: 'Scheduled',
            iconSize: 24.0,
          ),
          GButton(
            icon: Icons.forum_outlined,
            text: '__',
            iconSize: 24.0,
          ),
          GButton(
            icon: Icons.newspaper,
            text: 'NewsFeed',
            iconSize: 24.0,
          )
        ],
      ),
    );
  }
}
