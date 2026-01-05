import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';

import '/auth/base_auth_user_provider.dart';

import '/backend/push_notifications/push_notifications_handler.dart'
    show PushNotificationsHandler;
import '/main.dart';
import '/core/app_theme.dart';
import '/core/app_util.dart';

import '/chat_group/chat/chat_widget.dart';
import '/chat_group/chat_2_details/chat2_details_widget.dart';
import '/chat_group/chat_2_invite_users/chat2_invite_users_widget.dart';
import '/chat_group/image_details/image_details_widget.dart';
import '/friends/tab_friends/tab_friends_widget.dart';
import '/main_function/create_game/create_game_widget.dart';
import '/main_function/game_joined_detailed/game_joined_detailed_widget.dart';
import '/main_function/games_joined/games_joined_widget.dart';
import '/main_function/games_list/games_list_widget.dart';
import '/main_function/join_game_detailed/join_game_detailed_widget.dart';
import '/main_function/player_list/player_list_widget.dart';
import '/main_function/success_leave/success_leave_widget.dart';
import '/main_function/success_page/success_page_widget.dart';
import '/newsfeed/blog_create/blog_create_widget.dart';
import '/newsfeed/blog_edit/blog_edit_widget.dart';
import '/newsfeed/newsfeed/newsfeed_widget.dart';
import '/notifications/notification_page/notification_page_widget.dart';
import '/notifications/notifications_list/notifications_list_widget.dart';
import '/profile/create_profile/create_profile_widget.dart';
import '/profile/edit_profile/edit_profile_widget.dart';
import '/profile/home/home_widget.dart';
import '/profile/main_profile/main_profile_widget.dart';
import '/profile/profile_user/profile_user_widget.dart';
import '/user_auth/recover_password/recover_password_widget.dart';
import '/user_auth/sign_in/sign_in_widget.dart';
import '/user_auth/sign_up_account/sign_up_account_widget.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

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

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading => user == null || showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
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
    notifyListeners();
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
          redirect: _buildRedirect(appStateNotifier),
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
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            _isEmptyStateParams(state)
                ? NavBarPage(initialPage: 'CreateGame')
                : CreateGameWidget(),
          ),
        ),
        GoRoute(
          name: JoinGameDetailedWidget.routeName,
          path: JoinGameDetailedWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            NavBarPage(
              initialPage: '',
              page: JoinGameDetailedWidget(
                gameRef: _deserializeParam(
                  state,
                  'gameRef',
                  ParamType.DocumentReference,
                  collectionNamePath: ['games'],
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          name: HomeWidget.routeName,
          path: HomeWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            _isEmptyStateParams(state)
                ? NavBarPage(initialPage: 'Home')
                : NavBarPage(
                    initialPage: 'Home',
                    page: HomeWidget(),
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
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            CreateProfileWidget(),
          ),
        ),
        GoRoute(
          name: MainProfileWidget.routeName,
          path: MainProfileWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            NavBarPage(
              initialPage: '',
              page: MainProfileWidget(),
            ),
          ),
        ),
        GoRoute(
          name: EditProfileWidget.routeName,
          path: EditProfileWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            EditProfileWidget(),
          ),
        ),
        GoRoute(
          name: GamesJoinedWidget.routeName,
          path: GamesJoinedWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
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
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            NotificationPageWidget(),
          ),
        ),
        GoRoute(
          name: Chat2DetailsWidget.routeName,
          path: Chat2DetailsWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            FutureBuilder<ChatsRecord?>(
              future: _resolveAsyncParam(
                state,
                'chatRef',
                getDoc(['chats'], ChatsRecord.fromSnapshot),
              ),
              builder: (context, snapshot) => Chat2DetailsWidget(
                chatRef: snapshot.data,
              ),
            ),
          ),
        ),
        GoRoute(
          name: ChatWidget.routeName,
          path: ChatWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            _isEmptyStateParams(state)
                ? NavBarPage(initialPage: 'Chat')
                : ChatWidget(),
          ),
        ),
        GoRoute(
          name: Chat2InviteUsersWidget.routeName,
          path: Chat2InviteUsersWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            FutureBuilder<ChatsRecord?>(
              future: _resolveAsyncParam(
                state,
                'chatRef',
                getDoc(['chats'], ChatsRecord.fromSnapshot),
              ),
              builder: (context, snapshot) => Chat2InviteUsersWidget(
                chatRef: snapshot.data,
              ),
            ),
          ),
        ),
        GoRoute(
          name: ImageDetailsWidget.routeName,
          path: ImageDetailsWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            FutureBuilder<ChatMessagesRecord?>(
              future: _resolveAsyncParam(
                state,
                'chatMessage',
                getDoc(['chat_messages'], ChatMessagesRecord.fromSnapshot),
              ),
              builder: (context, snapshot) => ImageDetailsWidget(
                chatMessage: snapshot.data,
              ),
            ),
          ),
        ),
        GoRoute(
          name: SuccessPageWidget.routeName,
          path: SuccessPageWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            SuccessPageWidget(),
          ),
        ),
        GoRoute(
          name: ProfileUserWidget.routeName,
          path: ProfileUserWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            FutureBuilder<UsersRecord?>(
              future: _resolveAsyncParam(
                state,
                'userRef',
                getDoc(['users'], UsersRecord.fromSnapshot),
              ),
              builder: (context, snapshot) => ProfileUserWidget(
                userRef: snapshot.data,
              ),
            ),
          ),
        ),
        GoRoute(
          name: SuccessLeaveWidget.routeName,
          path: SuccessLeaveWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
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
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            FutureBuilder<GamesRecord?>(
              future: _resolveAsyncParam(
                state,
                'gameRef',
                getDoc(['games'], GamesRecord.fromSnapshot),
              ),
              builder: (context, snapshot) => PlayerListWidget(
                gameRef: snapshot.data,
              ),
            ),
          ),
        ),
        GoRoute(
          name: NotificationsListWidget.routeName,
          path: NotificationsListWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
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
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            NavBarPage(
              initialPage: '',
              page: TabFriendsWidget(),
            ),
          ),
        ),
        GoRoute(
          name: NewsfeedWidget.routeName,
          path: NewsfeedWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            _isEmptyStateParams(state)
                ? NavBarPage(initialPage: 'Newsfeed')
                : NavBarPage(
                    initialPage: 'Newsfeed',
                    page: NewsfeedWidget(),
                  ),
          ),
        ),
        GoRoute(
          name: BlogCreateWidget.routeName,
          path: BlogCreateWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            BlogCreateWidget(),
          ),
        ),
        GoRoute(
          name: BlogEditWidget.routeName,
          path: BlogEditWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            BlogEditWidget(
              postRef: _deserializeParam(
                state,
                'postRef',
                ParamType.DocumentReference,
                collectionNamePath: ['posts'],
              ),
            ),
          ),
        ),
        GoRoute(
          name: GameJoinedDetailedWidget.routeName,
          path: GameJoinedDetailedWidget.routePath,
          redirect: _buildRedirect(appStateNotifier),
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            NavBarPage(
              initialPage: '',
              page: GameJoinedDetailedWidget(
                gameRef: _deserializeParam(
                  state,
                  'gameRef',
                  ParamType.DocumentReference,
                  collectionNamePath: ['games'],
                ),
              ),
            ),
          ),
        ),
      ],
      observers: [routeObserver],
    );

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

GoRouterRedirect _buildRedirect(
  AppStateNotifier appStateNotifier, {
  bool requireAuth = false,
}) {
  return (context, state) {
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

Page<dynamic> _buildPageWithTransition(
  BuildContext context,
  GoRouterState state,
  AppStateNotifier appStateNotifier,
  Widget page,
) {
  fixStatusBarOniOS16AndBelow(context);
  final child = appStateNotifier.loading
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

Future<T?> _resolveAsyncParam<T>(
  GoRouterState state,
  String name,
  Future<T> Function(String) loader,
) {
  final param = _paramValue(state, name);
  if (param == null) {
    return Future.value(null);
  }
  if (param is T) {
    return Future.value(param);
  }
  if (param is! String) {
    return Future.value(param as T?);
  }
  return loader(param).onError((_, __) => null);
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
