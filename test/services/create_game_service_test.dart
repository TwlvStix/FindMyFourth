// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/main_function/create_game/models/create_game_form_data.dart';
import 'package:find_my_fourth/services/create_game_service.dart';

class _FakeDocumentReference
    implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this.path, {this.onSet});

  @override
  final String path;

  final Future<void> Function(Map<String, dynamic> data)? onSet;

  @override
  String get id => path.split('/').last;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (onSet != null) {
      await onSet!(data);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CreateGameService', () {
    test('createGameWithRef writes payload to provided reference', () async {
      final service = CreateGameService();
      Map<String, dynamic>? captured;

      final gameRef = _FakeDocumentReference(
        'games/game-123',
        onSet: (data) async {
          captured = data;
        },
      );
      final userRef = _FakeDocumentReference('users/u1');
      final chatRef = _FakeDocumentReference('chats/c1');

      final returnedRef = await service.createGameWithRef(
        gameRef: gameRef,
        formData: CreateGameFormData(
          gameName: 'Service Test',
          scheduleType: 'confirmed',
          datePicked: DateTime(2026, 1, 1, 10),
          friendsValue: 'Public',
        ),
        uid: 'u1',
        userRef: userRef,
        chatRef: chatRef,
      );

      expect(returnedRef, same(gameRef));
      expect(captured, isNotNull);
      expect(captured!['uid'], 'u1');
      expect(captured!['chatRef'], same(chatRef));
      expect(captured!['userRef'], same(userRef));
      expect(captured!['name_game'], 'Service Test');
    });
  });
}
