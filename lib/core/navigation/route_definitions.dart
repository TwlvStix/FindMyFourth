import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
import '/notification_settings/notification_settings_widget.dart';
import '/notifications/game_alerts_page/game_alerts_page_widget.dart';
import '/notifications/notifications_list/notifications_list_widget.dart';
import '/profile/create_profile/create_profile_widget.dart';
import '/profile/edit_profile/edit_profile_widget.dart';
import '/profile/edit_vibe_importance/edit_vibe_importance_widget.dart';
import '/profile/edit_vibes/edit_vibes_widget.dart';
import '/profile/main_profile/main_profile_widget.dart';
import '/profile/profile_user/profile_user_firebase_widget.dart';
import '/screens/confirmation/fallback_confirmation_screen.dart';
import '/screens/confirmation/host_checkin_screen.dart';
import '/screens/confirmation/peer_rating_screen.dart';
import '/screens/trust/your_standing_screen.dart';
import '/user_auth/recover_password/recover_password_widget.dart';
import '/user_auth/sign_in/sign_in_widget.dart';
import '/user_auth/sign_up_account/sign_up_account_widget.dart';
import '/user_onboarding/cinematic_onboarding_widget.dart';
import '/user_onboarding/progressive_onboarding_widget.dart';
import '/user_onboarding/vibe_onboarding_widget.dart';
import '/vibe/premium_vibe_page/premium_vibe_page_data.dart';
import '/vibe/premium_vibe_page/premium_vibe_page_widget.dart';

import '/core/navigation/app_router.dart'
    show AppStateNotifier, buildRedirect, buildPageWithTransition;
import '/core/navigation/nav_bar_page.dart';
import '/core/navigation/route_param_utils.dart';

/// Builds the complete list of routes for the app router.
///
/// All routes use [buildRedirect] for auth handling and [buildPageWithTransition]
/// for consistent transition behavior.
List<GoRoute> buildRoutes(AppStateNotifier appStateNotifier) => [
      GoRoute(
        name: '_initialize',
        path: '/',
        redirect: buildRedirect(appStateNotifier),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          appStateNotifier.loggedIn ? NavBarPage() : SignInWidget(),
        ),
      ),
      GoRoute(
        name: GamesListWidget.routeName,
        path: GamesListWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          isEmptyStateParams(state)
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
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          CreateGameWidget(),
        ),
      ),
      GoRoute(
        name: CommunityWidget.routeName,
        path: CommunityWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          isEmptyStateParams(state)
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
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) {
          final extra = state.extra;
          String? initialSegment;
          if (extra is Map<String, dynamic>) {
            initialSegment = extra['initialSegment'] as String?;
          }
          return buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            NavBarPage(
              initialPage: 'Golfers',
              page: TabFriendsWidget(initialSegment: initialSegment),
            ),
          );
        },
      ),
      GoRoute(
        name: JoinGameDetailedWidget.routeName,
        path: JoinGameDetailedWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          NavBarPage(
            initialPage: '',
            page: JoinGameDetailedWidget(
              gameRef: gameRefFromState(state),
            ),
          ),
        ),
      ),
      GoRoute(
        name: MainProfileWidget.routeName,
        path: MainProfileWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          isEmptyStateParams(state)
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
        redirect: buildRedirect(appStateNotifier),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          SignUpAccountWidget(),
        ),
      ),
      GoRoute(
        name: SignInWidget.routeName,
        path: SignInWidget.routePath,
        redirect: buildRedirect(appStateNotifier),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          SignInWidget(),
        ),
      ),
      GoRoute(
        name: ProgressiveOnboardingWidget.routeName,
        path: ProgressiveOnboardingWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          ProgressiveOnboardingWidget(),
        ),
      ),
      GoRoute(
        name: CinematicOnboardingWidget.routeName,
        path: CinematicOnboardingWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          CinematicOnboardingWidget(),
        ),
      ),
      GoRoute(
        name: VibeOnboardingWidget.routeName,
        path: VibeOnboardingWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          VibeOnboardingWidget(),
        ),
      ),
      GoRoute(
        name: RecoverPasswordWidget.routeName,
        path: RecoverPasswordWidget.routePath,
        redirect: buildRedirect(appStateNotifier),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          RecoverPasswordWidget(),
        ),
      ),
      GoRoute(
        name: CreateProfileWidget.routeName,
        path: CreateProfileWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          CreateProfileWidget(),
        ),
      ),
      GoRoute(
        name: EditProfileWidget.routeName,
        path: EditProfileWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          EditProfileWidget(),
        ),
      ),
      GoRoute(
        name: EditVibesWidget.routeName,
        path: EditVibesWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          EditVibesWidget(),
        ),
      ),
      GoRoute(
        name: EditVibeImportanceWidget.routeName,
        path: EditVibeImportanceWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          EditVibeImportanceWidget(),
        ),
      ),
      GoRoute(
        name: GamesJoinedWidget.routeName,
        path: GamesJoinedWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          isEmptyStateParams(state)
              ? NavBarPage(initialPage: 'GamesJoined')
              : NavBarPage(
                  initialPage: 'GamesJoined',
                  page: GamesJoinedWidget(),
                ),
        ),
      ),
      GoRoute(
        name: NotificationSettingsWidget.routeName,
        path: NotificationSettingsWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          const NotificationSettingsWidget(),
        ),
      ),
      GoRoute(
        name: GameAlertsPageWidget.routeName,
        path: GameAlertsPageWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          GameAlertsPageWidget(),
        ),
      ),
      GoRoute(
        name: ChatWidget.routeName,
        path: ChatWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          ChatWidget(),
        ),
      ),
      GoRoute(
        name: 'ChatDetails',
        path: '/chat/:chatId',
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
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
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          SuccessPageWidget(),
        ),
      ),
      GoRoute(
        name: SuccessLeaveWidget.routeName,
        path: SuccessLeaveWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          SuccessLeaveWidget(),
        ),
      ),
      GoRoute(
        name: 'PremiumVibePage',
        path: '/premium-vibe/:userId',
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          PremiumVibePageWidget(
            userId: state.pathParameters['userId']!,
            data: state.extra as PremiumVibePageData,
          ),
        ),
      ),
      GoRoute(
        name: PlayerListWidget.routeName,
        path: PlayerListWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          gameRefFromState(state) == null
              ? Scaffold(
                  body: Center(
                    child: Text('Game not found.'),
                  ),
                )
              : PlayerListWidget(
                  gameRef: gameRefFromState(state)!,
                ),
        ),
      ),
      GoRoute(
        name: 'ProfileUser',
        path: '/profileUser',
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) {
          final userRef = userRefFromState(state);
          return buildPageWithTransition(
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
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          NotificationsListWidget(),
        ),
      ),
      GoRoute(
        name: TabFriendsWidget.routeName,
        path: TabFriendsWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) {
          final extra = state.extra;
          String? initialSegment;
          if (extra is Map<String, dynamic>) {
            initialSegment = extra['initialSegment'] as String?;
          }
          return buildPageWithTransition(
            context,
            state,
            appStateNotifier,
            NavBarPage(
              initialPage: 'Golfers',
              page: TabFriendsWidget(initialSegment: initialSegment),
            ),
          );
        },
      ),
      GoRoute(
        name: GameJoinedDetailedWidget.routeName,
        path: GameJoinedDetailedWidget.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          NavBarPage(
            initialPage: '',
            page: GameJoinedDetailedWidget(
              gameRef: gameRefFromState(state),
            ),
          ),
        ),
      ),
      GoRoute(
        name: YourStandingScreen.routeName,
        path: YourStandingScreen.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          const YourStandingScreen(),
        ),
      ),
      GoRoute(
        name: HostCheckinScreen.routeName,
        path: HostCheckinScreen.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          gameRefFromState(state) == null
              ? Scaffold(
                  body: Center(
                    child: Text('Game not found.'),
                  ),
                )
              : HostCheckinScreen(
                  gameRef: gameRefFromState(state)!,
                ),
        ),
      ),
      GoRoute(
        name: PeerRatingScreen.routeName,
        path: PeerRatingScreen.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          gameRefFromState(state) == null
              ? Scaffold(
                  body: Center(
                    child: Text('Game not found.'),
                  ),
                )
              : PeerRatingScreen(
                  gameRef: gameRefFromState(state)!,
                ),
        ),
      ),
      GoRoute(
        name: FallbackConfirmationScreen.routeName,
        path: FallbackConfirmationScreen.routePath,
        redirect: buildRedirect(appStateNotifier, requireAuth: true),
        pageBuilder: (context, state) => buildPageWithTransition(
          context,
          state,
          appStateNotifier,
          gameRefFromState(state) == null
              ? Scaffold(
                  body: Center(
                    child: Text('Game not found.'),
                  ),
                )
              : FallbackConfirmationScreen(
                  gameRef: gameRefFromState(state)!,
                ),
        ),
      ),
    ];
