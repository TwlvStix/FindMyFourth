import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';

import '/auth/base_auth_user_provider.dart';

import '/backend/push_notifications/push_notifications_handler.dart'
    show PushNotificationsHandler;
import '/main.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/utils/serialization_util.dart';

import '/chat_group/chat/chat_widget.dart';
import '/chat_group/game_chat_details/game_chat_details_widget.dart';
import '/friends/tab_friends/tab_friends_widget.dart';
import '/main_function/community/community_widget.dart';
import '/main_function/create_game/create_game_widget.dart';
import '/main_function/game_joined_detailed/game_joined_detailed_widget.dart';
import '/main_function/games_joined/games_joined_widget.dart';
import '/main_function/games_list/games_list_widget.dart';
import '/main_function/join_game_detailed/join_game_detailed_widget.dart';
import '/main_function/player_list/player_list_widget.dart';
import '/main_function/success_leave/success_leave_widget.dart';
import '/main_function/success_page/success_page_widget.dart';
import '/notifications/notification_page/notification_page_widget.dart';
import '/notifications/notifications_list/notifications_list_widget.dart';
import '/profile/create_profile/create_profile_widget.dart';
import '/profile/edit_profile/edit_profile_widget.dart';
import '/profile/edit_vibe_importance/edit_vibe_importance_widget.dart';
import '/profile/edit_vibes/edit_vibes_widget.dart';
import '/profile/main_profile/main_profile_widget.dart';
import '/profile/profile_user/profile_user_firebase_widget.dart';
import '/user_auth/recover_password/recover_password_widget.dart';
import '/user_auth/sign_in/sign_in_widget.dart';
import '/user_auth/sign_up_account/sign_up_account_widget.dart';
import '/user_onboarding/progressive_onboarding_widget.dart';
import '/user_onboarding/user_onboarding_widget.dart';
import '/user_onboarding/vibe_onboarding_widget.dart';

export 'package:go_router/go_router.dart';
export '/utils/serialization_util.dart';
export 'transition_standards.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;
  bool _authStateReady = false;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading {
    final result = !_authStateReady || showSplashImage;
    return result;
  }
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  bool get authStateReady => _authStateReady;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() {
    _redirectLocation = null;
  }

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    _authStateReady = true;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    // Note: We don't call notifyListeners() here because update() will call it
    // immediately after, and that single call will reflect the showSplashImage=false state
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) =>
          appStateNotifier.loggedIn ? NavBarPage() : SignInWidget(),
      routes: [
        GoRoute(
          name: '_initialize',
          path: '/',
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            appStateNotifier.loggedIn ? NavBarPage() : SignInWidget(),
          ),
        ),
        GoRoute(
          name: GamesListWidget.routeName,
          path: GamesListWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            _isEmptyStateParams(state)
                ? NavBarPage(initialPage: 'GamesList')
                : NavBarPage(
                    initialPage: 'GamesList',
                    page: GamesListWidget(),
                  ),
          ),
        ),
        GoRoute(
          name: CreateGameWidget.routeName,
          path: CreateGameWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            CreateGameWidget(),
          ),
        ),
        GoRoute(
          name: CommunityWidget.routeName,
          path: CommunityWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            _isEmptyStateParams(state)
                ? NavBarPage(initialPage: 'Community')
                : NavBarPage(
                    initialPage: 'Community',
                    page: CommunityWidget(),
                  ),
          ),
        ),
        GoRoute(
          name: 'Golfers',
          path: '/golfers',
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            _isEmptyStateParams(state)
                ? NavBarPage(
                    initialPage: 'Golfers',
                    page: TabFriendsWidget(),
                  )
                : NavBarPage(
                    initialPage: 'Golfers',
                    page: TabFriendsWidget(),
                  ),
          ),
        ),
        GoRoute(
          name: JoinGameDetailedWidget.routeName,
          path: JoinGameDetailedWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            NavBarPage(
              initialPage: '',
              page: JoinGameDetailedWidget(
                gameRef: _gameRefFromState(state),
              ),
            ),
          ),
        ),
        GoRoute(
          name: MainProfileWidget.routeName,
          path: MainProfileWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            _isEmptyStateParams(state)
                ? NavBarPage(initialPage: 'Profile')
                : NavBarPage(
                    initialPage: 'Profile',
                    page: MainProfileWidget(),
                  ),
          ),
        ),
        GoRoute(
          name: SignUpAccountWidget.routeName,
          path: SignUpAccountWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            SignUpAccountWidget(),
          ),
        ),
        GoRoute(
          name: SignInWidget.routeName,
          path: SignInWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            SignInWidget(),
          ),
        ),
        GoRoute(
          name: ProgressiveOnboardingWidget.routeName,
          path: ProgressiveOnboardingWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            ProgressiveOnboardingWidget(),
          ),
        ),
        GoRoute(
          name: UserOnboardingWidget.routeName,
          path: UserOnboardingWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            UserOnboardingWidget(),
          ),
        ),
        GoRoute(
          name: VibeOnboardingWidget.routeName,
          path: VibeOnboardingWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            VibeOnboardingWidget(),
          ),
        ),
        GoRoute(
          name: RecoverPasswordWidget.routeName,
          path: RecoverPasswordWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            RecoverPasswordWidget(),
          ),
        ),
        GoRoute(
          name: CreateProfileWidget.routeName,
          path: CreateProfileWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            CreateProfileWidget(),
          ),
        ),
        GoRoute(
          name: EditProfileWidget.routeName,
          path: EditProfileWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            EditProfileWidget(),
          ),
        ),
        GoRoute(
          name: EditVibesWidget.routeName,
          path: EditVibesWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            EditVibesWidget(),
          ),
        ),
        GoRoute(
          name: EditVibeImportanceWidget.routeName,
          path: EditVibeImportanceWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            EditVibeImportanceWidget(),
          ),
        ),
        GoRoute(
          name: GamesJoinedWidget.routeName,
          path: GamesJoinedWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            _isEmptyStateParams(state)
                ? NavBarPage(initialPage: 'GamesJoined')
                : NavBarPage(
                    initialPage: 'GamesJoined',
                    page: GamesJoinedWidget(),
                  ),
          ),
        ),
        GoRoute(
          name: NotificationPageWidget.routeName,
          path: NotificationPageWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            NotificationPageWidget(),
          ),
        ),
        GoRoute(
          name: ChatWidget.routeName,
          path: ChatWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            ChatWidget(),
          ),
        ),
        GoRoute(
          name: 'ChatDetails',
          path: '/chat/:chatId',
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            GameChatDetailsWidget(
              chatId: state.pathParameters['chatId']!,
            ),
          ),
        ),
        GoRoute(
          name: SuccessPageWidget.routeName,
          path: SuccessPageWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            SuccessPageWidget(),
          ),
        ),
        GoRoute(
          name: SuccessLeaveWidget.routeName,
          path: SuccessLeaveWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            SuccessLeaveWidget(),
          ),
        ),
        GoRoute(
          name: PlayerListWidget.routeName,
          path: PlayerListWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            _gameRefFromState(state) == null
                ? Scaffold(
                    body: Center(
                      child: Text('Game not found.'),
                    ),
                  )
                : PlayerListWidget(
                    gameRef: _gameRefFromState(state)!,
                  ),
          ),
        ),
        GoRoute(
          name: 'ProfileUser',
          path: '/profileUser',
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) {
            final userRef = _userRefFromState(state);
            return _buildPageWithTransition(
              context,
              state,
              appStateNotifier,
              userRef == null
                  ? Scaffold(
                      body: Center(
                        child: Text('User not found.'),
                      ),
                    )
                  : ProfileUserFirebaseWidget(userRef: userRef),
            );
          },
        ),
        GoRoute(
          name: NotificationsListWidget.routeName,
          path: NotificationsListWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            NotificationsListWidget(),
          ),
        ),
        GoRoute(
          name: TabFriendsWidget.routeName,
          path: TabFriendsWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            _isEmptyStateParams(state)
                ? NavBarPage(
                    initialPage: 'Golfers',
                    page: TabFriendsWidget(),
                  )
                : NavBarPage(
                    initialPage: 'Golfers',
                    page: TabFriendsWidget(),
                  ),
          ),
        ),
        GoRoute(
          name: GameJoinedDetailedWidget.routeName,
          path: GameJoinedDetailedWidget.routePath,
          redirect: _buildRedirect(appStateNotifier, requireAuth: true),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            NavBarPage(
              initialPage: '',
              page: GameJoinedDetailedWidget(
                gameRef: _gameRefFromState(state),
              ),
            ),
          ),
        ),
      ],
      observers: [routeObserver],
    );

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) {
    if (appState.hasRedirect() && !ignoreRedirect) {
      return;
    }
    appState.updateNotifyOnAuthChange(false);
  }

  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();

  void clearRedirectLocation() {
    appState.clearRedirectLocation();
    appState.updateNotifyOnAuthChange(true);
  }

  void setRedirectLocationIfUnset(String location) {
    if (appState.hasRedirect()) {
      return;
    }
    appState.setRedirectLocationIfUnset(location);
    appState.updateNotifyOnAuthChange(false);
  }
}

GoRouterRedirect _buildRedirect(
  AppStateNotifier appStateNotifier, {
  bool requireAuth = false,
}) {
  return (context, state) {
    if (!appStateNotifier.authStateReady) {
      return null;
    }

    if (appStateNotifier.shouldRedirect) {
      final redirectLocation = appStateNotifier.getRedirectLocation();
      appStateNotifier.clearRedirectLocation();
      return redirectLocation;
    }

    if (requireAuth && !appStateNotifier.loggedIn) {
      appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
      return '/signIn';
    }

    return null;
  };
}

DocumentReference? _gameRefFromState(GoRouterState state) {
  final extra = state.extra;
  if (extra is DocumentReference) {
    return extra;
  }
  if (extra is Map && extra['gameRef'] is DocumentReference) {
    return extra['gameRef'] as DocumentReference;
  }
  final fromQuery = _deserializeParam(
    state,
    'gameRef',
    ParamType.DocumentReference,
    collectionNamePath: ['games'],
  );
  if (fromQuery is DocumentReference) {
    return fromQuery;
  }
  return null;
}

DocumentReference? _userRefFromState(GoRouterState state) {
  final extra = state.extra;
  if (extra is DocumentReference) {
    return extra;
  }
  if (extra is Map && extra['userRef'] is DocumentReference) {
    return extra['userRef'] as DocumentReference;
  }
  final fromQuery = _deserializeParam(
    state,
    'userRef',
    ParamType.DocumentReference,
    collectionNamePath: ['users'],
  );
  if (fromQuery is DocumentReference) {
    return fromQuery;
  }
  return null;
}

Page<dynamic> _buildPageWithTransition(
  BuildContext context,
  GoRouterState state,
  AppStateNotifier appStateNotifier,
  Widget page,
) {
  fixStatusBarOniOS16AndBelow(context);
  final isLoading = appStateNotifier.loading;

  final child = isLoading
      ? Container(
          color: AppTheme.of(context).primaryBackground,
          child: Image.asset(
            'assets/images/Blackfixed.png',
            fit: BoxFit.contain,
          ),
        )
      : PushNotificationsHandler(child: page);

  final transitionInfo = _transitionInfo(state);
  return transitionInfo.hasTransition
      ? CustomTransitionPage(
          key: state.pageKey,
          child: child,
          transitionDuration: transitionInfo.duration,
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) =>
                  PageTransition(
            type: transitionInfo.transitionType,
            duration: transitionInfo.duration,
            reverseDuration: transitionInfo.duration,
            alignment: transitionInfo.alignment,
            child: child,
          ).buildTransitions(
            context,
            animation,
            secondaryAnimation,
            child,
          ),
        )
      : MaterialPage(key: state.pageKey, child: child);
}

Map<String, dynamic> _allParams(GoRouterState state) {
  final params = <String, dynamic>{}
    ..addAll(state.pathParameters)
    ..addAll(state.uri.queryParameters);
  if (state.extra is Map<String, dynamic>) {
    params.addAll(state.extra as Map<String, dynamic>);
  }
  return params;
}

dynamic _paramValue(GoRouterState state, String name) => _allParams(state)[name];

T? _deserializeParam<T>(
  GoRouterState state,
  String name,
  ParamType type, {
  bool isList = false,
  List<String>? collectionNamePath,
}) {
  final param = _paramValue(state, name);
  if (param == null) {
    return null;
  }
  if (param is! String) {
    return param as T?;
  }
  return deserializeParam<T>(
    param,
    type,
    isList,
    collectionNamePath: collectionNamePath,
  );
}

bool _isEmptyStateParams(GoRouterState state) {
  final params = _allParams(state);
  if (params.isEmpty) {
    return true;
  }
  return params.length == 1 && params.containsKey(kTransitionInfoKey);
}

TransitionInfo _transitionInfo(GoRouterState state) {
  final extra = state.extra;
  if (extra is Map<String, dynamic> && extra.containsKey(kTransitionInfoKey)) {
    return extra[kTransitionInfoKey] as TransitionInfo;
  }
  return TransitionInfo.appDefault();
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  /// Default transition (no transition).
  ///
  /// For standard transitions, use constants from [TransitionStandards]:
  /// - [TransitionStandards.modalTransition] - Modal-like screens (create, edit)
  /// - [TransitionStandards.detailTransition] - Detail views (game details, profiles)
  /// - [TransitionStandards.dismissalTransition] - Success/dismissal screens
  /// - [TransitionStandards.tabTransition] - Tab navigation
  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
