import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/core/utils/app_log.dart';

class HostCheckinParticipant {
  const HostCheckinParticipant({
    required this.key,
    required this.displayName,
    required this.photoUrl,
    required this.isGuest,
    required this.role,
  });

  final String key;
  final String displayName;
  final String photoUrl;
  final bool isGuest;
  final String role;
}

class HostCheckinLoadData {
  const HostCheckinLoadData({
    required this.courseName,
    required this.participants,
    required this.defaultAttendance,
  });

  final String courseName;
  final List<HostCheckinParticipant> participants;
  final Map<String, bool> defaultAttendance;
}

class PeerRatee {
  const PeerRatee({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String photoUrl;
}

class PeerRatingLoadData {
  const PeerRatingLoadData({
    required this.courseName,
    required this.ratees,
    required this.initialRatings,
  });

  final String courseName;
  final List<PeerRatee> ratees;
  final Map<String, bool?> initialRatings;
}

/// Trust flow read service used by host check-in and peer rating screens.
class TrustFlowService {
  TrustFlowService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<HostCheckinLoadData> loadHostCheckinParticipants({
    required DocumentReference gameRef,
  }) async {
    // 1. Read game doc (separate try-catch for diagnostics)
    final DocumentSnapshot gameSnap;
    try {
      gameSnap = await gameRef.get();
    } on FirebaseException catch (e) {
      AppLog.d('❌ TrustFlowService: game read failed: ${e.code} - ${e.message} path=${gameRef.path}');
      rethrow;
    }
    if (!gameSnap.exists) {
      AppLog.d('❌ TrustFlowService: game not found at path=${gameRef.path}');
      throw StateError('game_not_found');
    }
    final gameData = gameSnap.data() as Map<String, dynamic>;
    final courseName = (gameData['course_play'] as String?) ?? 'your course';

    // 2. Query game_participants (separate try-catch for diagnostics)
    final QuerySnapshot<Map<String, dynamic>> participantsSnap;
    try {
      participantsSnap = await _firestore
          .collection('game_participants')
          .where('game_ref', isEqualTo: gameRef)
          .where('status', isEqualTo: 'joined')
          .get();
    } on FirebaseException catch (e) {
      AppLog.d('❌ TrustFlowService: participants query failed: ${e.code} - ${e.message} gameRef=${gameRef.path}');
      rethrow;
    }

    AppLog.d('📖 TrustFlowService: Found ${participantsSnap.docs.length} participant docs for game ${gameRef.id}');

    final participants = <HostCheckinParticipant>[];
    final defaultAttendance = <String, bool>{};

    for (final doc in participantsSnap.docs) {
      final data = doc.data();
      final userRef = data['user_ref'] as DocumentReference?;
      final guestName = data['guest_name'] as String?;
      final role = (data['role'] as String?) ?? 'player';

      if (userRef != null) {
        final profile = await _resolveProfile(
          userRef: userRef,
          snapshotData: data['profile_snapshot'] as Map<String, dynamic>?,
        );
        final key = userRef.id;
        participants.add(
          HostCheckinParticipant(
            key: key,
            displayName: profile.displayName,
            photoUrl: profile.photoUrl,
            isGuest: false,
            role: role,
          ),
        );
        defaultAttendance[key] = true;
        continue;
      }

      if (guestName != null && guestName.isNotEmpty) {
        participants.add(
          HostCheckinParticipant(
            key: guestName,
            displayName: guestName,
            photoUrl: '',
            isGuest: true,
            role: 'guest',
          ),
        );
        defaultAttendance[guestName] = true;
      }
    }

    return HostCheckinLoadData(
      courseName: courseName,
      participants: participants,
      defaultAttendance: defaultAttendance,
    );
  }

  Future<PeerRatingLoadData> loadPeerRatees({
    required DocumentReference gameRef,
  }) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) {
      throw StateError('not_signed_in');
    }

    final gameSnap = await gameRef.get();
    if (!gameSnap.exists) {
      throw StateError('game_not_found');
    }
    final gameData = gameSnap.data() as Map<String, dynamic>;
    final courseName = (gameData['course_play'] as String?) ?? 'your course';

    final attendanceRecords = await _loadAttendanceRecords(gameRef: gameRef);

    final participantsSnap = await _firestore
        .collection('game_participants')
        .where('game_ref', isEqualTo: gameRef)
        .where('status', isEqualTo: 'joined')
        .get();

    final ratees = <PeerRatee>[];
    final initialRatings = <String, bool?>{};

    for (final doc in participantsSnap.docs) {
      final data = doc.data();
      final userRef = data['user_ref'] as DocumentReference?;
      if (userRef == null || userRef.id == currentUid) {
        continue;
      }

      final attendanceStatus = attendanceRecords[userRef.id] as String?;
      if (attendanceStatus == 'no_show') {
        continue;
      }

      final profile = await _resolveProfile(
        userRef: userRef,
        snapshotData: data['profile_snapshot'] as Map<String, dynamic>?,
      );

      ratees.add(
        PeerRatee(
          uid: userRef.id,
          displayName: profile.displayName,
          photoUrl: profile.photoUrl,
        ),
      );
      initialRatings[userRef.id] = null;
    }

    return PeerRatingLoadData(
      courseName: courseName,
      ratees: ratees,
      initialRatings: initialRatings,
    );
  }

  Future<Map<String, dynamic>> _loadAttendanceRecords({
    required DocumentReference gameRef,
  }) async {
    final jobsSnap = await _firestore
        .collection('round_jobs')
        .where('game_ref', isEqualTo: gameRef)
        .limit(1)
        .get();

    if (jobsSnap.docs.isEmpty) {
      return <String, dynamic>{};
    }

    final job = jobsSnap.docs.first.data();
    final roundRef = job['round_ref'] as DocumentReference?;
    if (roundRef == null) {
      return <String, dynamic>{};
    }

    final roundSnap = await roundRef.get();
    if (!roundSnap.exists) {
      return <String, dynamic>{};
    }

    final roundData = roundSnap.data() as Map<String, dynamic>;
    return (roundData['attendance_records'] as Map<String, dynamic>?) ??
        <String, dynamic>{};
  }

  Future<_ProfileProjection> _resolveProfile({
    required DocumentReference userRef,
    required Map<String, dynamic>? snapshotData,
  }) async {
    if (snapshotData != null) {
      final name = (snapshotData['display_name'] as String?) ?? '';
      final photo = (snapshotData['photo_url'] as String?) ?? '';
      return _ProfileProjection(
        displayName: name.isNotEmpty ? name : 'Player',
        photoUrl: photo,
      );
    }

    try {
      final userSnap = await userRef.get();
      if (userSnap.exists) {
        final data = userSnap.data() as Map<String, dynamic>;
        final displayName = (data['display_name'] as String?) ??
            '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
        final photoUrl = (data['photo_url'] as String?) ?? '';
        return _ProfileProjection(
          displayName: displayName.isNotEmpty ? displayName : 'Player',
          photoUrl: photoUrl,
        );
      }
    } catch (_) {
      // Fallback below.
    }

    return const _ProfileProjection(
      displayName: 'Player',
      photoUrl: '',
    );
  }
}

class _ProfileProjection {
  const _ProfileProjection({
    required this.displayName,
    required this.photoUrl,
  });

  final String displayName;
  final String photoUrl;
}
