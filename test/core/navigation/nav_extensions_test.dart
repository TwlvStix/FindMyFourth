import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/core/navigation/app_router.dart';

void main() {
  testWidgets('pushYourStanding navigates with noTransition by default',
      (tester) async {
    Object? capturedExtra;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.pushYourStanding(),
              child: const Text('go'),
            ),
          ),
        ),
        GoRoute(
          name: AppRouteNames.yourStanding,
          path: '/yourStanding',
          builder: (context, state) {
            capturedExtra = state.extra;
            return const Scaffold(body: Text('standing'));
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('standing'), findsOneWidget);
    expect(capturedExtra, isA<Map<String, dynamic>>());
    final extra = capturedExtra! as Map<String, dynamic>;
    expect(extra[kTransitionInfoKey], TransitionStandards.noTransition);
  });

  testWidgets('pushJoinGameDetailed passes gameRef and detail transition',
      (tester) async {
    Object? capturedExtra;
    final gameRef = FakeFirebaseFirestore().doc('games/test_game');
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.pushJoinGameDetailed(gameRef: gameRef),
              child: const Text('join'),
            ),
          ),
        ),
        GoRoute(
          name: AppRouteNames.joinGameDetailed,
          path: '/joinGameDetailed',
          builder: (context, state) {
            capturedExtra = state.extra;
            return const Scaffold(body: Text('join-screen'));
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('join'));
    await tester.pumpAndSettle();

    expect(find.text('join-screen'), findsOneWidget);
    expect(capturedExtra, isA<Map<String, dynamic>>());
    final extra = capturedExtra! as Map<String, dynamic>;
    expect(extra['gameRef'], gameRef);
    expect(extra[kTransitionInfoKey], TransitionStandards.detailTransition);
  });

  testWidgets('goGamesList navigates to GamesList route', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.goGamesList(),
              child: const Text('games'),
            ),
          ),
        ),
        GoRoute(
          name: AppRouteNames.gamesList,
          path: '/gamesList',
          builder: (context, state) => const Scaffold(body: Text('games-list')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('games'));
    await tester.pumpAndSettle();

    expect(find.text('games-list'), findsOneWidget);
  });

  testWidgets('pushPremiumVibePage passes userId and raw extra data',
      (tester) async {
    Object? capturedExtra;
    String? capturedUserId;
    final payload = Object();

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.pushPremiumVibePage(
                userId: 'user_123',
                data: payload,
              ),
              child: const Text('premium'),
            ),
          ),
        ),
        GoRoute(
          name: AppRouteNames.premiumVibePage,
          path: '/premium/:userId',
          builder: (context, state) {
            capturedExtra = state.extra;
            capturedUserId = state.pathParameters['userId'];
            return const Scaffold(body: Text('premium-screen'));
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('premium'));
    await tester.pumpAndSettle();

    expect(find.text('premium-screen'), findsOneWidget);
    expect(capturedUserId, 'user_123');
    expect(identical(capturedExtra, payload), isTrue);
  });
}
