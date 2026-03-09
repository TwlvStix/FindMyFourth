import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'transition_standards.dart';

/// Canonical route-name constants for typed navigation helpers.
class AppRouteNames {
  AppRouteNames._();

  static const String gamesList = 'GamesList';
  static const String createGame = 'CreateGame';
  static const String joinGameDetailed = 'JoinGameDetailed';
  static const String gameJoinedDetailed = 'GameJoinedDetailed';
  static const String gamesJoined = 'GamesJoined';
  static const String playerList = 'PlayerList';
  static const String profileUser = 'ProfileUser';
  static const String premiumVibePage = 'PremiumVibePage';
  static const String notificationsList = 'NotificationsList';
  static const String notificationSettings = 'NotificationSettings';
  static const String locationSettings = 'LocationSettings';
  static const String yourStanding = 'YourStanding';
  static const String mainProfile = 'MainProfile';
  static const String editProfile = 'EditProfile';
  static const String editVibes = 'EditVibes';
  static const String editVibeImportance = 'EditVibeImportance';
  static const String golfers = 'Golfers';
  static const String chatDetails = 'ChatDetails';
  static const String createProfile = 'CreateProfile';
  static const String vibeOnboarding = 'VibeOnboarding';
  static const String signUpAccount = 'SignUpAccount';
  static const String recoverPassword = 'RecoverPassword';
  static const String successPage = 'success_page';
  static const String successLeave = 'success_leave';
  static const String signIn = 'SignIn';
  static const String vibeArchetypeReveal = 'VibeArchetypeReveal';
  static const String hostCheckin = 'HostCheckin';
  static const String peerRating = 'PeerRating';
  static const String fallbackConfirmation = 'FallbackConfirmation';
}

/// Route-specific typed navigation helpers for widget call sites.
extension AppNavigationExtensions on BuildContext {
  void pushNotifications({
    TransitionInfo transition = TransitionStandards.detailTransition,
  }) {
    pushWithTransition(
      AppRouteNames.notificationsList,
      transition: transition,
    );
  }

  void pushNotificationSettings({
    TransitionInfo transition = TransitionStandards.detailTransition,
  }) {
    pushWithTransition(
      AppRouteNames.notificationSettings,
      transition: transition,
    );
  }

  void pushLocationSettings({
    TransitionInfo transition = TransitionStandards.detailTransition,
  }) {
    pushWithTransition(
      AppRouteNames.locationSettings,
      transition: transition,
    );
  }

  void pushYourStanding({
    TransitionInfo transition = TransitionStandards.noTransition,
  }) {
    pushWithTransition(
      AppRouteNames.yourStanding,
      transition: transition,
    );
  }

  void pushMainProfile({
    TransitionInfo transition = TransitionStandards.noTransition,
  }) {
    pushWithTransition(
      AppRouteNames.mainProfile,
      transition: transition,
    );
  }

  void pushEditProfile({
    TransitionInfo transition = TransitionStandards.flatFadeTransition,
  }) {
    pushWithTransition(
      AppRouteNames.editProfile,
      transition: transition,
    );
  }

  void pushEditVibes({
    TransitionInfo transition = TransitionStandards.flatFadeTransition,
  }) {
    pushWithTransition(
      AppRouteNames.editVibes,
      transition: transition,
    );
  }

  void pushTabFriends({
    String? initialSegment,
    TransitionInfo transition = TransitionStandards.detailTransition,
  }) {
    final extra = <String, dynamic>{};
    if (initialSegment != null && initialSegment.isNotEmpty) {
      extra['initialSegment'] = initialSegment;
    }
    pushWithTransition(
      AppRouteNames.golfers,
      extra: extra.isEmpty ? null : extra,
      transition: transition,
    );
  }

  void pushChatDetails({
    required String chatId,
    TransitionInfo transition = TransitionStandards.detailTransition,
  }) {
    pushWithTransition(
      AppRouteNames.chatDetails,
      pathParameters: <String, String>{'chatId': chatId},
      transition: transition,
    );
  }

  void pushProfileUser({
    required DocumentReference userRef,
    TransitionInfo transition = TransitionStandards.detailTransition,
  }) {
    pushWithTransition(
      AppRouteNames.profileUser,
      extra: <String, dynamic>{'userRef': userRef},
      transition: transition,
    );
  }

  void pushJoinGameDetailed({
    required DocumentReference gameRef,
    bool skipFriendsOnlyCheck = false,
    TransitionInfo transition = TransitionStandards.detailTransition,
  }) {
    pushWithTransition(
      AppRouteNames.joinGameDetailed,
      extra: <String, dynamic>{
        'gameRef': gameRef,
        'skipFriendsOnlyCheck': skipFriendsOnlyCheck,
      },
      transition: transition,
    );
  }

  void goGameJoinedDetailed({
    required DocumentReference gameRef,
    TransitionInfo transition = TransitionStandards.detailTransition,
  }) {
    goWithTransition(
      AppRouteNames.gameJoinedDetailed,
      extra: <String, dynamic>{'gameRef': gameRef},
      transition: transition,
    );
  }

  void pushGameJoinedDetailed({
    required DocumentReference gameRef,
    TransitionInfo transition = TransitionStandards.detailTransition,
  }) {
    pushWithTransition(
      AppRouteNames.gameJoinedDetailed,
      extra: <String, dynamic>{'gameRef': gameRef},
      transition: transition,
    );
  }

  void pushCreateGame({
    TransitionInfo transition = TransitionStandards.modalTransition,
  }) {
    pushWithTransition(
      AppRouteNames.createGame,
      transition: transition,
    );
  }

  void pushGamesList({
    TransitionInfo transition = TransitionStandards.noTransition,
  }) {
    pushWithTransition(
      AppRouteNames.gamesList,
      transition: transition,
    );
  }

  void goGamesList({
    TransitionInfo transition = TransitionStandards.noTransition,
  }) {
    goWithTransition(
      AppRouteNames.gamesList,
      transition: transition,
    );
  }

  void pushPlayerList({
    required DocumentReference gameRef,
    bool isEditMode = false,
    TransitionInfo transition = TransitionStandards.flatFadeTransition,
  }) {
    pushWithTransition(
      AppRouteNames.playerList,
      extra: <String, dynamic>{
        'gameRef': gameRef,
        'isEditMode': isEditMode,
      },
      transition: transition,
    );
  }

  void goGamesJoined({
    TransitionInfo transition = TransitionStandards.noTransition,
  }) {
    goWithTransition(
      AppRouteNames.gamesJoined,
      transition: transition,
    );
  }

  void goMainProfile({
    TransitionInfo transition = TransitionStandards.noTransition,
  }) {
    goWithTransition(
      AppRouteNames.mainProfile,
      transition: transition,
    );
  }

  void pushSignIn({
    TransitionInfo transition = TransitionStandards.modalTransition,
  }) {
    pushWithTransition(
      AppRouteNames.signIn,
      transition: transition,
    );
  }

  void goSignIn({
    TransitionInfo transition = TransitionStandards.noTransition,
  }) {
    goWithTransition(
      AppRouteNames.signIn,
      transition: transition,
    );
  }

  void pushSignUpAccount({
    TransitionInfo transition = TransitionStandards.modalTransition,
  }) {
    pushWithTransition(
      AppRouteNames.signUpAccount,
      transition: transition,
    );
  }

  void pushRecoverPassword({
    TransitionInfo transition = TransitionStandards.modalTransition,
  }) {
    pushWithTransition(
      AppRouteNames.recoverPassword,
      transition: transition,
    );
  }

  void pushCreateProfile({
    TransitionInfo transition = TransitionStandards.modalTransition,
  }) {
    pushWithTransition(
      AppRouteNames.createProfile,
      transition: transition,
    );
  }

  void goCreateProfile({
    String? next,
    TransitionInfo transition = TransitionStandards.modalTransition,
  }) {
    final queryParameters = <String, dynamic>{};
    if (next != null && next.isNotEmpty) {
      queryParameters['next'] = next;
    }
    goWithTransition(
      AppRouteNames.createProfile,
      queryParameters: queryParameters,
      transition: transition,
    );
  }

  void goVibeOnboarding({
    String? next,
    TransitionInfo transition = TransitionStandards.modalTransition,
  }) {
    final queryParameters = <String, dynamic>{};
    if (next != null && next.isNotEmpty) {
      queryParameters['next'] = next;
    }
    goWithTransition(
      AppRouteNames.vibeOnboarding,
      queryParameters: queryParameters,
      transition: transition,
    );
  }

  void pushEditVibeImportance({
    TransitionInfo transition = TransitionStandards.modalTransition,
  }) {
    pushWithTransition(
      AppRouteNames.editVibeImportance,
      transition: transition,
    );
  }

  void pushSuccessPage({
    TransitionInfo transition = TransitionStandards.dismissalTransition,
  }) {
    pushWithTransition(
      AppRouteNames.successPage,
      transition: transition,
    );
  }

  void pushSuccessLeave({
    TransitionInfo transition = TransitionStandards.dismissalTransition,
  }) {
    pushWithTransition(
      AppRouteNames.successLeave,
      transition: transition,
    );
  }

  void pushPremiumVibePage({
    required String userId,
    required Object data,
  }) {
    GoRouter.of(this).pushNamed(
      AppRouteNames.premiumVibePage,
      pathParameters: <String, String>{'userId': userId},
      extra: data,
    );
  }

  void pushHostCheckin({
    required DocumentReference gameRef,
    TransitionInfo transition = TransitionStandards.detailTransition,
  }) {
    pushWithTransition(
      AppRouteNames.hostCheckin,
      extra: <String, dynamic>{'gameRef': gameRef},
      transition: transition,
    );
  }

  void pushPeerRating({
    required DocumentReference gameRef,
    TransitionInfo transition = TransitionStandards.detailTransition,
  }) {
    pushWithTransition(
      AppRouteNames.peerRating,
      extra: <String, dynamic>{'gameRef': gameRef},
      transition: transition,
    );
  }

  void pushFallbackConfirmation({
    required DocumentReference gameRef,
    TransitionInfo transition = TransitionStandards.detailTransition,
  }) {
    pushWithTransition(
      AppRouteNames.fallbackConfirmation,
      extra: <String, dynamic>{'gameRef': gameRef},
      transition: transition,
    );
  }

  void pushVibeArchetypeReveal({
    required Object match,
    String? next,
    TransitionInfo transition = TransitionStandards.dismissalTransition,
  }) {
    final queryParameters = <String, dynamic>{};
    if (next != null && next.isNotEmpty) {
      queryParameters['next'] = next;
    }
    pushWithTransition(
      AppRouteNames.vibeArchetypeReveal,
      extra: <String, dynamic>{'match': match},
      queryParameters: queryParameters,
      transition: transition,
    );
  }
}
