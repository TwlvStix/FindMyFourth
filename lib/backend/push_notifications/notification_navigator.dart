// Notification navigation orchestration.
//
// Ties payload normalization, route resolution, and parameter building together.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'notification_parameters.dart';
import 'notification_payload.dart';
import 'notification_route_resolver.dart';
import 'serialization_util.dart';
import '../../utils/app_util.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/notifications/components/player_added_bottom_sheet.dart';
import '/notifications/components/pre_game_confirm_bottom_sheet.dart';
import '/services/app_badge_service.dart';

/// Handle notification navigation from both background taps and foreground taps.
///
/// This is the shared routing logic used by both [PushNotificationsHandler] (for
/// background/terminated taps) and [FcmNotificationService] (for foreground taps).
///
/// [context] - A valid BuildContext for navigation.
/// [rawData] - The raw notification data (will be normalized).
/// [messageId] - Optional message ID for deduplication.
Future<void> handleNotificationNavigation(
  BuildContext context,
  Map<String, dynamic> rawData, {
  required String? messageId,
}) async {
  // Prune stale entries and check for duplicates
  pruneStaleDedupeEntries();
  final dedupeKey = messageId ?? computeContentHash(rawData);

  AppLog.d('🔔 [DIAG-BG] handleNotificationNavigation - messageId=$messageId');
  AppLog.d('🔔 [DIAG-BG] dedupeKey=$dedupeKey, alreadyHandled=${handledMessageCache.containsKey(dedupeKey)}');

  if (handledMessageCache.containsKey(dedupeKey)) {
    AppLog.d('🔔 [DIAG-BG] BLOCKED by deduplication');
    return;
  }
  handledMessageCache[dedupeKey] = DateTime.now();

  // Clear OS-level app badge on notification tap
  AppBadgeService().clearBadge();

  // Normalize keys BEFORE routing
  final data = normalizeNotificationPayload(rawData);

  // Intercept player_added_by_host to show bottom sheet
  final type = data['type'];
  if (type == 'player_added_by_host') {
    final gameId = data['game_id'] ?? data['gameId'];
    final hostName = data['host_name'] ?? data['hostName'] ?? 'A host';
    final courseName = data['course_name'] ?? data['courseName'] ?? 'a course';
    final gameDate = data['game_date'] ?? data['gameDate'] ?? 'an upcoming game';

    if (gameId is String && gameId.isNotEmpty) {
      final shown = await showBottomSheetWithRetry(
        showSheet: (ctx) => showPlayerAddedBottomSheet(
          context: ctx,
          gameId: gameId,
          hostName: hostName.toString(),
          courseName: courseName.toString(),
          gameDate: gameDate.toString(),
          onGotIt: () {
            final navContext = appNavigatorKey.currentContext;
            if (navContext != null && navContext.mounted) {
              navContext.pushNamed(
                'GameJoinedDetailed',
                extra: {
                  'gameRef': FirebaseFirestore.instance.doc('games/$gameId'),
                },
              );
            }
          },
          onDeclined: () {
            final navContext = appNavigatorKey.currentContext;
            if (navContext != null && navContext.mounted) {
              navContext.pushNamed('GamesList');
            }
          },
        ),
      );
      if (shown) return; // Exit after handling bottom sheet
      AppLog.d('🔔 [DIAG-NAV] player_added_by_host bottom sheet failed, falling back to game detail page');
      // Fall through to resolveRouteFromType → GameJoinedDetailed
    }
  }

  // Intercept host_pre_game_confirm to show confirmation bottom sheet
  if (type == 'host_pre_game_confirm') {
    AppLog.d('🔔 [DIAG-NAV] host_pre_game_confirm intercept: gameId=${data['game_id'] ?? data['gameId']}');
    final gameId = data['game_id'] ?? data['gameId'];
    final courseName =
        data['course_name'] ?? data['courseName'] ?? 'your course';
    final gameDate =
        data['game_date'] ?? data['gameDate'] ?? 'your upcoming round';

    if (gameId is String && gameId.isNotEmpty) {
      // Check if confirmation is still relevant
      final shouldSkip = await _shouldSkipPreGameConfirmation(gameId);
      if (shouldSkip) {
        AppLog.d('🔔 [DIAG-NAV] host_pre_game_confirm: stale, navigating to game detail');
        final navContext = context.mounted ? context : appNavigatorKey.currentContext;
        if (navContext != null && navContext.mounted) {
          navContext.pushNamed(
            'GameJoinedDetailed',
            extra: {
              'gameRef': FirebaseFirestore.instance.doc('games/$gameId'),
            },
          );
        }
        return;
      }

      final shown = await showBottomSheetWithRetry(
        showSheet: (ctx) => showPreGameConfirmBottomSheet(
          context: ctx,
          gameId: gameId,
          courseName: courseName.toString(),
          gameDate: gameDate.toString(),
          onConfirmed: () {
            final navContext = appNavigatorKey.currentContext;
            if (navContext != null && navContext.mounted) {
              navContext.pushNamed(
                'GameJoinedDetailed',
                extra: {
                  'gameRef': FirebaseFirestore.instance.doc('games/$gameId'),
                },
              );
            }
          },
          onCancelled: () {
            final navContext = appNavigatorKey.currentContext;
            if (navContext != null && navContext.mounted) {
              navContext.pushNamed('GamesList');
            }
          },
        ),
      );
      if (shown) return; // Exit after handling bottom sheet
      AppLog.d('🔔 [DIAG-NAV] host_pre_game_confirm bottom sheet failed, falling back to game detail page');
      // Fall through to resolveRouteFromType → GameJoinedDetailed
    }
  }

  final resolvedRoute = resolveRouteFromType(data);
  final rawPageName = data['initialPageName'];
  final initialPageName = resolvedRoute?.pageName ??
      (rawPageName is String && rawPageName.isNotEmpty ? rawPageName : null);

  AppLog.d('🔔 [DIAG-NAV] Routing: type=${data['type']} → '
      'page=$initialPageName, params=${resolvedRoute?.parameterData ?? {}}');

  if (initialPageName == null) {
    AppLog.d('🔔 [DIAG-NAV] No page name resolved, skipping navigation');
    return;
  }

  final initialParameterData =
      resolvedRoute?.parameterData ?? getInitialParameterData(data);

  // Friends-only check (works with any context)
  if (initialPageName == 'JoinGameDetailed') {
    final shouldBlock = await shouldBlockFriendsOnlyGame(initialParameterData);
    if (shouldBlock) {
      // ignore: use_build_context_synchronously - mounted check handles this safely
      final dialogContext =
          context.mounted ? context : appNavigatorKey.currentContext;
      if (dialogContext != null && dialogContext.mounted) {
        await showFriendsOnlyDialog(dialogContext);
      }
      return;
    }
  }

  // Navigate (no loading UI for foreground taps - instant)
  final parametersBuilder = parametersBuilderMap[initialPageName];
  if (parametersBuilder != null) {
    final parameterData = await parametersBuilder(initialParameterData);
    final navContext = context.mounted ? context : appNavigatorKey.currentContext;
    navContext?.pushNamed(
      initialPageName,
      pathParameters: parameterData.pathParameters,
      extra: parameterData.extra,
    );
  }
}

/// Check if a friends-only game should block the current user from viewing it.
Future<bool> shouldBlockFriendsOnlyGame(
  Map<String, dynamic> initialParameterData,
) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    return false;
  }

  final gameRef =
      getParameter<DocumentReference>(initialParameterData, 'gameRef');
  if (gameRef == null) {
    return false;
  }

  Map<String, dynamic>? data;
  try {
    final gameSnap = await gameRef.get();
    data = gameSnap.data() as Map<String, dynamic>?;
  } on FirebaseException catch (error) {
    AppLog.d(
      '❌ shouldBlockFriendsOnlyGame: ${error.code} - ${error.message}',
    );
    // Don't block on permission-denied — let game detail widget handle it.
    // This prevents hosts from being blocked when Firestore rules reject
    // the read (e.g., stale auth token, rules not yet deployed).
    return false;
  } catch (_) {
    return false;
  }
  if (data == null) {
    return false;
  }

  final friendGameValue = (data['friendGame'] as String?) ?? '';
  final isFriendsOnly = friendGameValue == 'friends';
  if (!isFriendsOnly) {
    return false;
  }

  final ownerRef = data['userRef'];
  if (ownerRef is! DocumentReference) {
    return true;
  }

  // Host can always access their own game
  if (ownerRef.id == currentUser.uid) {
    return false;
  }

  final currentUserRef =
      FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
  final userSnap = await currentUserRef.get();
  final userData = userSnap.data() ?? {};
  final friends = userData['friends'];
  if (friends is List) {
    return !friends.any((entry) {
      if (entry is DocumentReference) {
        return entry.id == ownerRef.id;
      }
      if (entry is String) {
        if (entry.contains('/')) {
          final parts = entry.split('/');
          return parts.isNotEmpty && parts.last == ownerRef.id;
        }
        return entry == ownerRef.id;
      }
      return false;
    });
  }
  return true;
}

/// Wraps a bottom sheet call with retry logic for cold-start resilience.
///
/// On cold start, the Navigator/Overlay may not be ready when the first attempt
/// runs. Each iteration fetches a fresh context from [appNavigatorKey], so a
/// context that becomes invalid during the delay is replaced on the next attempt.
/// Returns `true` if the sheet opened successfully, `false` otherwise.
Future<bool> showBottomSheetWithRetry({
  required Future<void> Function(BuildContext context) showSheet,
  int maxAttempts = 2,
  Duration retryDelay = const Duration(milliseconds: 300),
}) async {
  for (int attempt = 0; attempt < maxAttempts; attempt++) {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      AppLog.d('🔔 showBottomSheetWithRetry: attempt ${attempt + 1} — no valid context');
      if (attempt < maxAttempts - 1) {
        await Future.delayed(retryDelay);
        continue;
      }
      return false;
    }
    try {
      await showSheet(ctx);
      AppLog.d('🔔 showBottomSheetWithRetry: bottom sheet opened successfully');
      return true;
    } catch (e) {
      AppLog.d('🔔 showBottomSheetWithRetry: attempt ${attempt + 1} failed: $e');
      if (attempt < maxAttempts - 1) {
        await Future.delayed(retryDelay);
      }
    }
  }
  return false;
}

/// Returns true if the pre-game confirmation is stale (already handled or
/// tee time passed). Returns false on failure (fail-open).
Future<bool> _shouldSkipPreGameConfirmation(String gameId) async {
  try {
    final gameSnap = await FirebaseFirestore.instance
        .collection('games')
        .doc(gameId)
        .get();

    if (!gameSnap.exists) return true;
    final data = gameSnap.data();
    if (data == null) return true;

    // Already resolved (timeout, confirmed, or cancelled)
    final hostConfirmation = data['hostConfirmation'] as String?;
    if (hostConfirmation != null && hostConfirmation != 'pending') {
      AppLog.d('🔔 _shouldSkipPreGameConfirmation: game $gameId hostConfirmation=$hostConfirmation');
      return true;
    }

    // Tee time has passed
    final dateTimestamp = data['date'] as Timestamp?;
    if (dateTimestamp != null && DateTime.now().isAfter(dateTimestamp.toDate())) {
      AppLog.d('🔔 _shouldSkipPreGameConfirmation: game $gameId tee time passed');
      return true;
    }

    return false;
  } on FirebaseException catch (e) {
    AppLog.d('❌ _shouldSkipPreGameConfirmation: ${e.code} - ${e.message}');
    return false; // Fail-open
  } catch (_) {
    return false; // Fail-open
  }
}

/// Show the friends-only game blocking dialog.
Future<void> showFriendsOnlyDialog(BuildContext context) async {
  await showPremiumDialog(
    context: context,
    variant: PremiumDialogVariant.informational,
    icon: PhosphorIconsRegular.lock,
    title: 'Friends Only Game',
    body: 'This game is visible to friends only. Add the host as a friend to view details.',
    actionLabel: 'Got It',
  );
}
