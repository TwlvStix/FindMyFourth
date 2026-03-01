// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/models/alert_subscription.dart';
import 'package:find_my_fourth/models/game.dart';
import 'package:find_my_fourth/models/player_eligibility.dart';
import 'package:find_my_fourth/services/alert_matcher.dart';

class _FakeDocumentReference
    implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this.path);

  @override
  final String path;

  @override
  String get id => path.split('/').last;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  AlertSubscription makeSub({
    bool enabled = true,
    AlertSpecialOptions? special,
  }) {
    return AlertSubscription(
      userId: 'user-1',
      enabled: enabled,
      gameVibes: const [],
      stakes: const [],
      formats: const [],
      handicapUses: const [],
      courses: const [],
      special: special ?? AlertSpecialOptions.defaults(),
    );
  }

  Game makeGame({
    bool hasSideGames = false,
    bool is2v2 = false,
    String memberDiscount = 'No',
  }) {
    return Game(
      reference: _FakeDocumentReference('games/game-1'),
      nameGame: 'Morning Fourball',
      coursePlay: 'Pebble Beach',
      gameType: 'Stroke Play',
      styleGame: 'No Money',
      rulesSetting: 'Casual',
      scoring: 'Net',
      memberDiscount: memberDiscount,
      friendGame: 'Public',
      hasSideGames: hasSideGames,
      is2v2: is2v2,
      numPlayers: 1,
      maxPlayers: 4,
      joinedPlayers: const [],
      guestPlayers: const [],
      isCancelled: false,
      status: 'active',
      date: null,
      createdTime: null,
      chatRef: null,
      courseRef: _FakeDocumentReference('course/course-1'),
      userRef: _FakeDocumentReference('users/user-1'),
      uid: 'user-1',
      scheduleType: 'confirmed',
      isFunGame: false,
      playerEligibility: PlayerEligibility.openToAll,
    );
  }

  group('AlertMatcher special filters', () {
    test('matches all games when no filters are active', () {
      final sub = makeSub();
      final game = makeGame();
      expect(AlertMatcher.doesAlertSubMatchGame(sub, game), isTrue);
    });

    test('requires side games when special.games is enabled', () {
      final sub = makeSub(
        special:
            AlertSpecialOptions(games: true, twoVTwo: false, discount: false),
      );
      expect(
          AlertMatcher.doesAlertSubMatchGame(sub, makeGame(hasSideGames: true)),
          isTrue);
      expect(
          AlertMatcher.doesAlertSubMatchGame(
              sub, makeGame(hasSideGames: false)),
          isFalse);
    });

    test('requires 2v2 when special.twoVTwo is enabled', () {
      final sub = makeSub(
        special:
            AlertSpecialOptions(games: false, twoVTwo: true, discount: false),
      );
      expect(AlertMatcher.doesAlertSubMatchGame(sub, makeGame(is2v2: true)),
          isTrue);
      expect(AlertMatcher.doesAlertSubMatchGame(sub, makeGame(is2v2: false)),
          isFalse);
    });

    test('requires member discount when special.discount is enabled', () {
      final sub = makeSub(
        special:
            AlertSpecialOptions(games: false, twoVTwo: false, discount: true),
      );
      expect(
          AlertMatcher.doesAlertSubMatchGame(
              sub, makeGame(memberDiscount: 'Yes')),
          isTrue);
      expect(
          AlertMatcher.doesAlertSubMatchGame(
              sub, makeGame(memberDiscount: 'No')),
          isFalse);
    });

    test('normalizes case/whitespace for yes discount values', () {
      final sub = makeSub(
        special:
            AlertSpecialOptions(games: false, twoVTwo: false, discount: true),
      );
      expect(
          AlertMatcher.doesAlertSubMatchGame(
              sub, makeGame(memberDiscount: '  yEs  ')),
          isTrue);
    });

    test('does not match truthy-looking non-contract discount strings', () {
      final sub = makeSub(
        special:
            AlertSpecialOptions(games: false, twoVTwo: false, discount: true),
      );
      expect(
          AlertMatcher.doesAlertSubMatchGame(
              sub, makeGame(memberDiscount: 'true')),
          isFalse);
      expect(
          AlertMatcher.doesAlertSubMatchGame(
              sub, makeGame(memberDiscount: '1')),
          isFalse);
    });

    test('requires all enabled special filters to pass', () {
      final sub = makeSub(
        special:
            AlertSpecialOptions(games: true, twoVTwo: true, discount: true),
      );
      final matchingGame = makeGame(
        hasSideGames: true,
        is2v2: true,
        memberDiscount: 'Yes',
      );
      final nonMatchingGame = makeGame(
        hasSideGames: true,
        is2v2: false,
        memberDiscount: 'Yes',
      );

      expect(AlertMatcher.doesAlertSubMatchGame(sub, matchingGame), isTrue);
      expect(AlertMatcher.doesAlertSubMatchGame(sub, nonMatchingGame), isFalse);
    });
  });
}
