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

Future<UsersRecord> _createUserRecord(
  FakeFirebaseFirestore firestore,
  String uid, {
  List<DocumentReference>? friends,
  Map<String, dynamic> extra = const {},
}) async {
  await firestore.collection('users').doc(uid).set({
    'display_name': 'User $uid',
    'uid': uid,
    'photo_url': '',
    'friends': friends ?? <DocumentReference>[],
    'friend_requests': <String>[],
    'first_name': '',
    'last_name': '',
    'home_course': '',
    'handicap': 0,
    'golf_canada_number': '',
    'gender': '',
    'hometown_name': '',
    ...extra,
  });
  final doc = await firestore.collection('users').doc(uid).get();
  return UsersRecord.fromSnapshot(doc);
}

void main() {
  group('ProfileUserController mutual friends', () {
    late FakeFirebaseFirestore firestore;
    late ProfileUserController controller;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      controller = ProfileUserController(
        friendService: _FakeFriendService(firestore),
        vibeRepository: _StubVibeRepository(),
      );
    });

    tearDown(() => controller.dispose());

    test('mutualFriends is empty when there is no overlap', () async {
      final userRecord = await _createUserRecord(firestore, 'them',
        friends: [firestore.collection('users').doc('u1')],
      );

      controller.onProfileDataReceived(
        userRecord,
        firestore.collection('users').doc('them'),
        isSelf: false,
        myFriends: [firestore.collection('users').doc('u2')],
      );

      // Allow async work to complete
      await Future<void>.delayed(Duration.zero);

      expect(controller.mutualFriendsLoaded, isTrue);
      expect(controller.mutualFriends, isEmpty);
    });

    test('mutualFriends populates when overlap exists', () async {
      await firestore.collection('users').doc('u2').set({
        'display_name': 'Mutual Friend',
        'uid': 'u2',
      });

      final userRecord = await _createUserRecord(firestore, 'them',
        friends: [
          firestore.collection('users').doc('u2'),
          firestore.collection('users').doc('u3'),
        ],
      );

      controller.onProfileDataReceived(
        userRecord,
        firestore.collection('users').doc('them'),
        isSelf: false,
        myFriends: [firestore.collection('users').doc('u2')],
      );

      // Allow async work to complete
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.mutualFriendsLoaded, isTrue);
      expect(controller.mutualFriends.length, 1);
      expect(controller.mutualFriends.first.reference.id, 'u2');
    });
  });

  group('ProfileUserController vibe match', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;

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

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'me'),
      );
    });

    test('loads vibe match on profile data received', () async {
      await firestore
          .collection('users')
          .doc('me')
          .set(vibeData(pace: 5));
      await firestore.collection('users').doc('them').set({
        ...vibeData(pace: 4),
        'display_name': 'Them',
        'uid': 'them',
        'photo_url': '',
        'friends': <String>[],
        'friend_requests': <String>[],
        'first_name': '',
        'last_name': '',
        'home_course': '',
        'handicap': 0,
        'golf_canada_number': '',
        'gender': '',
        'hometown_name': '',
      });

      final userRecord = await UsersRecord.getDocumentOnce(
        firestore.collection('users').doc('them'),
      );

      final controller = ProfileUserController(
        friendService: _FakeFriendService(firestore),
        vibeRepository: VibeRepository(firestore: firestore, auth: auth),
      );

      controller.onProfileDataReceived(
        userRecord,
        firestore.collection('users').doc('them'),
        isSelf: false,
        myFriends: [],
      );

      // Allow async vibe match loading to complete
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.vibeMatchResult, isNotNull);
      expect(controller.isVibeMatchLoading, isFalse);

      controller.dispose();
    });

    test('vibeMatchResult is null when repository throws', () async {
      await firestore.collection('users').doc('them').set({
        ...vibeData(pace: 4),
        'display_name': 'Them',
        'uid': 'them',
        'photo_url': '',
        'friends': <String>[],
        'friend_requests': <String>[],
        'first_name': '',
        'last_name': '',
        'home_course': '',
        'handicap': 0,
        'golf_canada_number': '',
        'gender': '',
        'hometown_name': '',
      });

      final userRecord = await UsersRecord.getDocumentOnce(
        firestore.collection('users').doc('them'),
      );

      final controller = ProfileUserController(
        friendService: _FakeFriendService(firestore),
        vibeRepository: _ThrowingVibeRepository(),
      );

      controller.onProfileDataReceived(
        userRecord,
        firestore.collection('users').doc('them'),
        isSelf: false,
        myFriends: [],
      );

      // Allow async work to complete
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.vibeMatchResult, isNull);
      expect(controller.isVibeMatchLoading, isFalse);

      controller.dispose();
    });
  });

  group('ProfileUserController.reset', () {
    test('clears all state', () {
      final firestore = FakeFirebaseFirestore();
      final controller = ProfileUserController(
        friendService: _FakeFriendService(firestore),
        vibeRepository: _StubVibeRepository(),
      );

      controller.reset();

      expect(controller.vibeMatchResult, isNull);
      expect(controller.mutualFriends, isEmpty);
      expect(controller.mutualFriendsLoaded, isTrue);
      expect(controller.isVibeMatchLoading, isFalse);

      controller.dispose();
    });
  });

  group('ProfileUserController skips work for self', () {
    test('does not load vibes or mutual friends for own profile', () async {
      final firestore = FakeFirebaseFirestore();
      final userRecord = await _createUserRecord(firestore, 'me');

      final controller = ProfileUserController(
        friendService: _FakeFriendService(firestore),
        vibeRepository: _StubVibeRepository(),
      );

      controller.onProfileDataReceived(
        userRecord,
        firestore.collection('users').doc('me'),
        isSelf: true,
        myFriends: [],
      );

      await Future<void>.delayed(Duration.zero);

      expect(controller.vibeMatchResult, isNull);
      expect(controller.mutualFriends, isEmpty);

      controller.dispose();
    });
  });
}
