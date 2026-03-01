// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/main_function/create_game/models/create_game_form_data.dart';
import 'package:find_my_fourth/models/course.dart';

class _FakeDocumentReference
    implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this.path);

  @override
  final String path;

  @override
  String get id => path.split('/').last;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CreateGameFormData draft round-trip', () {
    test('persists memberDiscount and selectedCourseRefPath', () {
      final data = CreateGameFormData(
        courseValue: 'Pebble Beach',
        selectedCourseRefPath: 'course/pebble',
        memberDiscount: true,
      );

      final restored = CreateGameFormData.fromDraftString(data.toDraftString());

      expect(restored.memberDiscount, isTrue);
      expect(restored.memberValue, 'Yes');
      expect(restored.selectedCourseRefPath, 'course/pebble');
      expect(restored.courseValue, 'Pebble Beach');
    });

    test('infers memberDiscount from legacy member=Yes draft', () {
      final restored = CreateGameFormData.fromDraftJson({
        'member': 'Yes',
      });

      expect(restored.memberDiscount, isTrue);
      expect(restored.memberValue, 'Yes');
    });
  });

  group('CreateGameFormData course hydration', () {
    test('prefers reference path when course names collide', () {
      final preferredRef = _FakeDocumentReference('course/target');
      final fallbackRef = _FakeDocumentReference('course/fallback');

      final data = CreateGameFormData(
        courseValue: 'Augusta National',
        selectedCourseRefPath: 'course/target',
      );

      data.hydrateSelectedCourse([
        Course(reference: fallbackRef, name: 'Augusta National'),
        Course(reference: preferredRef, name: 'Augusta National'),
      ]);

      expect(data.selectedCourse, isNotNull);
      expect(data.selectedCourse!.reference.path, 'course/target');
      expect(data.selectedCourseRefPath, 'course/target');
    });

    test('toFirestoreMap uses hydrated courseRef and derived member value', () {
      final courseRef = _FakeDocumentReference('course/pebble');
      final userRef = _FakeDocumentReference('users/test-user');
      final data = CreateGameFormData(
        memberDiscount: true,
        is2v2: true,
        selectedGames: {'Skins'},
      );

      data.setSelectedCourse(
          Course(reference: courseRef, name: 'Pebble Beach'));

      final firestore = data.toFirestoreMap(
        uid: 'test-user',
        userRef: userRef,
        chatRef: null,
      );

      expect(firestore['courseRef'], same(courseRef));
      expect(firestore['member_discount'], 'Yes');
      expect(firestore['is_2v2'], isTrue);
      expect(firestore['has_side_games'], isTrue);
    });

    test('toFirestoreMap sets has_side_games false when no side games selected',
        () {
      final userRef = _FakeDocumentReference('users/test-user');
      final data = CreateGameFormData(
        memberDiscount: false,
        is2v2: false,
      );

      final firestore = data.toFirestoreMap(
        uid: 'test-user',
        userRef: userRef,
        chatRef: null,
      );

      expect(firestore['is_2v2'], isFalse);
      expect(firestore['has_side_games'], isFalse);
    });
  });
}
