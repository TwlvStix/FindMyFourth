import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/backend/schema/users_record.dart';
import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/profile/profile_user/controller/profile_user_controller.dart';
import 'package:find_my_fourth/services/friend_service.dart';
import 'package:find_my_fourth/services/vibe_repository.dart';

class _ThrowingVibeRepository extends VibeRepository {
  _ThrowingVibeRepository()
      : super(
          firestore: FakeFirebaseFirestore(),
          auth: MockFirebaseAuth(),
        );

  @override
  Future<VibeProfile> getMyVibesCached({bool forceRefresh = false}) {
    throw StateError('boom');
  }
}

class _StubVibeRepository extends VibeRepository {
  _StubVibeRepository()
      : super(
          firestore: FakeFirebaseFirestore(),
          auth: MockFirebaseAuth(),
        );
}

class _FakeFriendService extends FriendService {
  _FakeFriendService(this._firestore) : super(firestore: _firestore);

  final FakeFirebaseFirestore _firestore;

  @override
  Future<List<UsersRecord>> getMutualFriends({
    required List<DocumentReference> myFriends,
    required List<DocumentReference> theirFriends,
  }) async {
    final myUids = myFriends.map((r) => r.id).toSet();
    final theirUids = theirFriends.map((r) => r.id).toSet();
    final mutualUids = myUids.intersection(theirUids);

    if (mutualUids.isEmpty) {
      return <UsersRecord>[];
    }

    final futures = mutualUids.map(
      (uid) => UsersRecord.getDocumentOnce(
          _firestore.collection('users').doc(uid)),
    );
    return Future.wait(futures);
  }
}

void main() {
  group('ProfileUserController.fetchMutualFriends', () {
    late FakeFirebaseFirestore firestore;
    late ProfileUserController controller;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      controller = ProfileUserController(
        friendService: _FakeFriendService(firestore),
        vibeRepository: _StubVibeRepository(),
      );
    });

    test('returns empty loaded result when there is no overlap', () async {
      final result = await controller.fetchMutualFriends(
        theirFriends: [firestore.collection('users').doc('u1')],
        myFriends: [firestore.collection('users').doc('u2')],
      );

      expect(result.loaded, isTrue);
      expect(result.friends, isEmpty);
    });

    test('returns fetched mutual users when overlap exists', () async {
      await firestore.collection('users').doc('u2').set({
        'display_name': 'Mutual Friend',
        'uid': 'u2',
      });

      final result = await controller.fetchMutualFriends(
        theirFriends: [
          firestore.collection('users').doc('u2'),
          firestore.collection('users').doc('u3'),
        ],
        myFriends: [firestore.collection('users').doc('u2')],
      );

      expect(result.loaded, isTrue);
      expect(result.friends.length, 1);
      expect(result.friends.first.reference.id, 'u2');
      expect(result.friends.first.displayName, 'Mutual Friend');
    });
  });

  group('ProfileUserController.loadVibeMatch', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'me'),
      );
    });

    Map<String, dynamic> vibeData({required int pace}) {
      return {
        'vibe_profile': {
          'prefs': {
            'pace': {'value': pace, 'dealbreaker': false, 'is_default': false},
            'competitive': {
              'value': 3,
              'dealbreaker': false,
              'is_default': false,
            },
            'drinking': {
              'value': 3,
              'dealbreaker': false,
              'is_default': false,
            },
            'chat': {'value': 3, 'dealbreaker': false, 'is_default': false},
            'money': {'value': 3, 'dealbreaker': false, 'is_default': false},
            'music': {'value': 3, 'dealbreaker': false, 'is_default': false},
          },
        },
      };
    }

    test('returns match and profiles on success', () async {
      await firestore.collection('users').doc('me').set(vibeData(pace: 5));
      await firestore.collection('users').doc('them').set(vibeData(pace: 4));
      final snapshot = await firestore.collection('users').doc('them').get();

      final controller = ProfileUserController(
        friendService: _FakeFriendService(firestore),
        vibeRepository: VibeRepository(firestore: firestore, auth: auth),
      );

      final result = await controller.loadVibeMatch(snapshot);

      expect(result.profileId, 'them');
      expect(result.match, isNotNull);
      expect(result.myVibes, isNotNull);
      expect(result.theirVibes, isNotNull);
      expect(result.isLoading, isFalse);
    });

    test('returns null-safe result when repository throws', () async {
      await firestore.collection('users').doc('them').set(vibeData(pace: 4));
      final snapshot = await firestore.collection('users').doc('them').get();

      final controller = ProfileUserController(
        friendService: _FakeFriendService(firestore),
        vibeRepository: _ThrowingVibeRepository(),
      );

      final result = await controller.loadVibeMatch(snapshot);

      expect(result.profileId, 'them');
      expect(result.match, isNull);
      expect(result.myVibes, isNull);
      expect(result.theirVibes, isNull);
      expect(result.isLoading, isFalse);
    });
  });

  group('ProfileUserController.shouldLoadVibeMatch', () {
    test('returns false when loading is in progress', () async {
      final firestore = FakeFirebaseFirestore();
      final controller = ProfileUserController(
        friendService: _FakeFriendService(firestore),
        vibeRepository: _StubVibeRepository(),
      );
      await firestore
          .collection('users')
          .doc('them')
          .set({'display_name': 'T'});
      final snapshot = await firestore.collection('users').doc('them').get();

      expect(
        controller.shouldLoadVibeMatch(
          isLoading: true,
          existingMatch: null,
          loadedUserId: null,
          snapshot: snapshot,
        ),
        isFalse,
      );
    });
  });
}
