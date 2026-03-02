import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/auth/base_auth_user_provider.dart';
import '/backend/push_notifications/push_notifications_handler.dart'
    show PushNotificationsHandler;
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/user_auth/sign_in/sign_in_widget.dart';
import '/utils/app_util.dart';

import '/core/navigation/nav_bar_page.dart';
import '/core/navigation/route_definitions.dart';

export 'package:go_router/go_router.dart';
export '/utils/serialization_util.dart';
export '/core/navigation/nav_extensions.dart';
export '/core/navigation/route_param_utils.dart';
export '/core/navigation/transition_standards.dart';

// Re-export kTransitionInfoKey for backward compatibility
// (now defined in transition_standards.dart)
export '/core/navigation/transition_standards.dart' show kTransitionInfoKey;

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  String? _redirectLocation;
  bool _authStateReady = false;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading => !_authStateReady;
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
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: kDebugMode,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) =>
          appStateNotifier.loggedIn ? NavBarPage() : SignInWidget(),
      routes: buildRoutes(appStateNotifier),
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

/// Builds the redirect handler for a route.
///
/// Set [requireAuth] to true for routes that require authentication.
/// Unauthenticated users will be redirected to /signIn.
GoRouterRedirect buildRedirect(
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

/// Builds a page with consistent transition handling.
///
/// Wraps the page in [PushNotificationsHandler] and applies transitions
/// based on [TransitionInfo] from route state.
Page<dynamic> buildPageWithTransition(
  BuildContext context,
  GoRouterState state,
  AppStateNotifier appStateNotifier,
  Widget page,
) {
  fixStatusBarOniOS16AndBelow(context);
  final child = PushNotificationsHandler(child: page);

  final transitionInfo = transitionInfoFromState(state);

  if (!transitionInfo.hasTransition) {
    return MaterialPage(key: state.pageKey, child: child);
  }

  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: transitionInfo.getEnterDuration(),
    reverseTransitionDuration: transitionInfo.getExitDuration(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final isReverse = animation.status == AnimationStatus.reverse;

      Widget result = child;

      // Apply micro-scale on push only (if enabled and not in reduced motion mode)
      if (transitionInfo.scaleOnPush &&
          !isReverse &&
          ReducedMotionService.shouldScale) {
        final scaleAnimation = Tween<double>(
          begin: MotionTokens.pageScaleStart,
          end: MotionTokens.pageScaleEnd,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: MotionTokens.curveEnter,
        ));

        result = ScaleTransition(
          scale: scaleAnimation,
          child: result,
        );
      }

      // Apply fade transition
      return FadeTransition(
        opacity: animation,
        child: result,
      );
    },
  );
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
