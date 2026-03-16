import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/services/rematch_service.dart';
import 'package:find_my_fourth/models/game.dart';
import 'package:find_my_fourth/models/player_eligibility.dart';

void main() {
  late RematchService service;
  late FakeFirebaseFirestore fakeFirestore;
  late DocumentReference gameRef;

  setUp(() async {
    service = RematchService();
    fakeFirestore = FakeFirebaseFirestore();
    gameRef = fakeFirestore.collection('games').doc('test_game_123');
    await gameRef.set({'name_game': 'Test Game'});
  });

  Game buildTestGame({
    String coursePlay = 'Pine Valley',
    String gameType = 'Stroke Play',
    String styleGame = '\$20',
    String rulesSetting = 'Competitive',
    String scoring = 'Net',
    String memberDiscount = 'Yes',
    String friendGame = 'public',
    bool is2v2 = false,
    bool isFunGame = false,
    PlayerEligibility playerEligibility = PlayerEligibility.openToAll,
    List<String> sideGameTags = const ['Nassaus', 'Skins'],
    DocumentReference? courseRef,
  }) {
    return Game(
      reference: gameRef,
      nameGame: 'Test Game',
      coursePlay: coursePlay,
      gameType: gameType,
      styleGame: styleGame,
      rulesSetting: rulesSetting,
      scoring: scoring,
      memberDiscount: memberDiscount,
      friendGame: friendGame,
      hasSideGames: sideGameTags.isNotEmpty,
      sideGameTags: sideGameTags,
      is2v2: is2v2,
      isFunGame: isFunGame,
      playerEligibility: playerEligibility,
      numPlayers: 2,
      maxPlayers: 4,
      joinedPlayers: [],
      guestPlayers: [],
      isCancelled: false,
      status: 'completed',
      date: DateTime(2026, 3, 10),
      createdTime: DateTime(2026, 3, 9),
      chatRef: null,
      courseRef: courseRef ?? fakeFirestore.collection('courses').doc('pv'),
      userRef: fakeFirestore.collection('users').doc('host'),
      uid: 'host',
      scheduleType: 'confirmed',
    );
  }

  group('buildRematchForm', () {
    test('copies all game fields to form data', () {
      final game = buildTestGame();
      final form = service.buildRematchForm(game);

      expect(form.gameTypeValue, 'Stroke Play');
      expect(form.styleGameValue, '\$20');
      expect(form.rulesSetValue, 'Competitive');
      expect(form.scoringValue, 'Net');
      expect(form.friendsValue, 'public');
      expect(form.memberValue, 'Yes');
      expect(form.memberDiscount, true);
      expect(form.is2v2, false);
      expect(form.isJustForFun, false);
      expect(form.playerEligibility, 'open_to_all');
      expect(form.selectedGames, {'Nassaus', 'Skins'});
    });

    test('keeps course for rematch', () {
      final game = buildTestGame();
      final form = service.buildRematchForm(game);

      expect(form.courseValue, 'Pine Valley');
      expect(form.selectedCourseRefPath, isNotNull);
    });

    test('sets rematch metadata', () {
      final game = buildTestGame();
      final form = service.buildRematchForm(game);

      expect(form.createdVia, 'rematch');
      expect(form.sourceGameId, 'test_game_123');
    });

    test('sets schedule to confirmed with no date', () {
      final game = buildTestGame();
      final form = service.buildRematchForm(game);

      expect(form.scheduleType, 'confirmed');
      expect(form.datePicked, isNull);
    });

    test('generates a new game name', () {
      final game = buildTestGame();
      final form = service.buildRematchForm(game);

      expect(form.gameName, isNotEmpty);
      // Should NOT be the original game name
      expect(form.gameName, isNot('Test Game'));
    });

    test('maps women-only eligibility', () {
      final game = buildTestGame(
        playerEligibility: PlayerEligibility.womenOnly,
      );
      final form = service.buildRematchForm(game);

      expect(form.playerEligibility, 'women_only');
    });

    test('handles empty side game tags', () {
      final game = buildTestGame(sideGameTags: []);
      final form = service.buildRematchForm(game);

      expect(form.selectedGames, isEmpty);
    });

    test('handles no member discount', () {
      final game = buildTestGame(memberDiscount: 'No');
      final form = service.buildRematchForm(game);

      expect(form.memberDiscount, false);
      expect(form.memberValue, 'No');
    });
  });

  group('buildSwitchCourseForm', () {
    test('clears course fields', () {
      final game = buildTestGame();
      final form = service.buildSwitchCourseForm(game);

      expect(form.courseValue, isNull);
      expect(form.selectedCourseRefPath, isNull);
    });

    test('keeps all other game fields', () {
      final game = buildTestGame();
      final form = service.buildSwitchCourseForm(game);

      expect(form.gameTypeValue, 'Stroke Play');
      expect(form.styleGameValue, '\$20');
      expect(form.rulesSetValue, 'Competitive');
      expect(form.scoringValue, 'Net');
      expect(form.selectedGames, {'Nassaus', 'Skins'});
    });

    test('sets switch_course metadata', () {
      final game = buildTestGame();
      final form = service.buildSwitchCourseForm(game);

      expect(form.createdVia, 'switch_course');
      expect(form.sourceGameId, 'test_game_123');
    });
  });
}
