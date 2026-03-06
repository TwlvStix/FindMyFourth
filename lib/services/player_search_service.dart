import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/models/user_profile.dart';

class PlayerSearchPage {
  const PlayerSearchPage({
    required this.results,
    required this.lastDocument,
    required this.hasMoreResults,
  });

  final List<UserProfile> results;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMoreResults;
}

/// Encapsulates player search and add-to-game writes for PlayerList UI.
class PlayerSearchService {
  PlayerSearchService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUserId => _auth.currentUser?.uid;

  DocumentReference userRefForUid(String uid) =>
      _firestore.collection('users').doc(uid);

  Future<PlayerSearchPage> searchPlayers({
    required String query,
    required int pageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> request = _firestore
        .collection('users')
        .orderBy('display_name_lowercase')
        .startAt([query]).endAt(['$query\uf8ff']).limit(pageSize);

    if (startAfter != null) {
      request = request.startAfterDocument(startAfter);
    }

    final snapshot = await request.get();
    final currentUid = currentUserId;
    final results = snapshot.docs
        .map(UserProfile.fromDoc)
        .where((profile) => profile.uid != currentUid)
        .toList();

    return PlayerSearchPage(
      results: results,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : startAfter,
      hasMoreResults: snapshot.docs.length == pageSize,
    );
  }

  Future<void> addPlayersToGame({
    required DocumentReference gameRef,
    required List<String> joinedPlayerUids,
    required List<String> guestPlayers,
  }) async {
    if (joinedPlayerUids.isEmpty && guestPlayers.isEmpty) {
      return;
    }

    final joinedRefs = joinedPlayerUids
        .map((uid) => userRefForUid(uid))
        .toList(growable: false);

    await gameRef.update(<String, dynamic>{
      if (joinedRefs.isNotEmpty)
        'joined_players': FieldValue.arrayUnion(joinedRefs),
      if (joinedPlayerUids.isNotEmpty)
        // Track host-added players for notification trigger (UIDs, not refs)
        'host_added_players': FieldValue.arrayUnion(joinedPlayerUids),
      if (guestPlayers.isNotEmpty)
        'guest_players': FieldValue.arrayUnion(guestPlayers),
    });
  }
}
