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

/// Completion status for post-round confirmation screens.
enum ConfirmationStatus {
  /// Not yet submitted — show the interactive form.
  pending,

  /// Already submitted — show "already completed" state.
  completed,

  /// Confirmation window has closed — show expired message.
  windowClosed,
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
    AppLog.d('📖 loadPeerRatees: starting for ${gameRef.path}');
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) {
      AppLog.d('❌ loadPeerRatees: user not signed in');
      throw StateError('not_signed_in');
    }
    AppLog.d('📖 loadPeerRatees: currentUid=$currentUid');

    final gameSnap = await gameRef.get();
    if (!gameSnap.exists) {
      AppLog.d('❌ loadPeerRatees: game not found at ${gameRef.path}');
      throw StateError('game_not_found');
    }
    final gameData = gameSnap.data() as Map<String, dynamic>;
    final courseName = (gameData['course_play'] as String?) ?? 'your course';
    AppLog.d('📖 loadPeerRatees: game found, course=$courseName');

    Map<String, dynamic> attendanceRecords;
    try {
      attendanceRecords = await _loadAttendanceRecords(gameRef: gameRef);
    } catch (e) {
      AppLog.d(
          '⚠️ loadPeerRatees: attendance load failed, proceeding without no-show filtering: $e');
      attendanceRecords = <String, dynamic>{};
    }
    AppLog.d(
        '📖 loadPeerRatees: attendance records=${attendanceRecords.length} entries: $attendanceRecords');

    final participantsSnap = await _firestore
        .collection('game_participants')
        .where('game_ref', isEqualTo: gameRef)
        .where('status', isEqualTo: 'joined')
        .get();

    AppLog.d(
        '📖 loadPeerRatees: found ${participantsSnap.docs.length} participants with status=joined');

    // Diagnostic: if no joined participants found, check what statuses exist
    if (participantsSnap.docs.isEmpty) {
      final allParticipantsSnap = await _firestore
          .collection('game_participants')
          .where('game_ref', isEqualTo: gameRef)
          .get();
      if (allParticipantsSnap.docs.isNotEmpty) {
        final statuses = allParticipantsSnap.docs.map((d) {
          final data = d.data();
          final uid = (data['user_ref'] as DocumentReference?)?.id ?? 'guest';
          final status = data['status'] ?? 'null';
          final role = data['role'] ?? 'null';
          return '$uid(status=$status, role=$role)';
        }).toList();
        AppLog.d(
            '⚠️ loadPeerRatees: 0 joined but ${allParticipantsSnap.docs.length} total participants: $statuses');
      } else {
        AppLog.d(
            '⚠️ loadPeerRatees: 0 participants found at all for ${gameRef.path}');
      }
    }

    final ratees = <PeerRatee>[];
    final initialRatings = <String, bool?>{};

    for (final doc in participantsSnap.docs) {
      final data = doc.data();
      final userRef = data['user_ref'] as DocumentReference?;
      final role = data['role'] as String? ?? 'unknown';

      if (userRef == null) {
        AppLog.d('📖 loadPeerRatees: skipping doc ${doc.id} — null user_ref (guest), role=$role');
        continue;
      }
      if (userRef.id == currentUid) {
        AppLog.d('📖 loadPeerRatees: skipping ${userRef.id} — current user, role=$role');
        continue;
      }

      final attendanceStatus = attendanceRecords[userRef.id] as String?;
      if (attendanceStatus == 'no_show') {
        AppLog.d('📖 loadPeerRatees: skipping ${userRef.id} — marked no_show, role=$role');
        continue;
      }

      final profile = await _resolveProfile(
        userRef: userRef,
        snapshotData: data['profile_snapshot'] as Map<String, dynamic>?,
      );

      AppLog.d(
          '✅ loadPeerRatees: adding ratee ${userRef.id} (${profile.displayName}), role=$role');

      ratees.add(
        PeerRatee(
          uid: userRef.id,
          displayName: profile.displayName,
          photoUrl: profile.photoUrl,
        ),
      );
      initialRatings[userRef.id] = true;
    }

    AppLog.d('📖 loadPeerRatees: returning ${ratees.length} ratees');

    return PeerRatingLoadData(
      courseName: courseName,
      ratees: ratees,
      initialRatings: initialRatings,
    );
  }

  /// Checks whether the host check-in has already been submitted or the
  /// confirmation window has closed.
  Future<ConfirmationStatus> checkHostCheckinStatus({
    required DocumentReference gameRef,
  }) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return ConfirmationStatus.pending;

    try {
      final currentUserRef = _firestore.collection('users').doc(currentUid);
      final jobsSnap = await _firestore
          .collection('round_jobs')
          .where('game_ref', isEqualTo: gameRef)
          .where('app_user_refs', arrayContains: currentUserRef)
          .limit(1)
          .get();

      if (jobsSnap.docs.isEmpty) return ConfirmationStatus.pending;

      final job = jobsSnap.docs.first.data();

      if (job['closed_at'] != null) return ConfirmationStatus.windowClosed;
      if (job['host_confirmed_at'] != null) return ConfirmationStatus.completed;

      return ConfirmationStatus.pending;
    } on FirebaseException catch (e) {
      AppLog.d('❌ TrustFlowService.checkHostCheckinStatus error: ${e.code} - ${e.message}');
      // On error, allow the form to show (server idempotency protects us).
      return ConfirmationStatus.pending;
    }
  }

  /// Checks whether the current user has already submitted peer ratings for
  /// this game.
  Future<ConfirmationStatus> checkPeerRatingStatus({
    required DocumentReference gameRef,
  }) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return ConfirmationStatus.pending;

    try {
      // Check window first
      final currentUserRef = _firestore.collection('users').doc(currentUid);
      final jobsSnap = await _firestore
          .collection('round_jobs')
          .where('game_ref', isEqualTo: gameRef)
          .where('app_user_refs', arrayContains: currentUserRef)
          .limit(1)
          .get();

      if (jobsSnap.docs.isNotEmpty) {
        final job = jobsSnap.docs.first.data();
        if (job['closed_at'] != null) return ConfirmationStatus.windowClosed;
      }

      // Check for existing pair_ratings
      final ratingsSnap = await _firestore
          .collection('pair_ratings')
          .where('rater_ref', isEqualTo: currentUserRef)
          .where('game_ref', isEqualTo: gameRef)
          .limit(1)
          .get();

      if (ratingsSnap.docs.isNotEmpty) return ConfirmationStatus.completed;

      return ConfirmationStatus.pending;
    } on FirebaseException catch (e) {
      AppLog.d('❌ TrustFlowService.checkPeerRatingStatus error: ${e.code} - ${e.message}');
      return ConfirmationStatus.pending;
    }
  }

  /// Checks whether the current user has already submitted a fallback
  /// confirmation for this game.
  Future<ConfirmationStatus> checkFallbackStatus({
    required DocumentReference gameRef,
  }) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return ConfirmationStatus.pending;

    try {
      // Check window first
      final currentUserRef = _firestore.collection('users').doc(currentUid);
      final jobsSnap = await _firestore
          .collection('round_jobs')
          .where('game_ref', isEqualTo: gameRef)
          .where('app_user_refs', arrayContains: currentUserRef)
          .limit(1)
          .get();

      if (jobsSnap.docs.isNotEmpty) {
        final job = jobsSnap.docs.first.data();
        if (job['closed_at'] != null) return ConfirmationStatus.windowClosed;

        final roundRef = job['round_ref'] as DocumentReference?;
        if (roundRef != null) {
          final roundSnap = await roundRef.get();
          if (roundSnap.exists) {
            final roundData = roundSnap.data() as Map<String, dynamic>;
            final confirmedRefs =
                (roundData['confirmed_player_refs'] as List<dynamic>?) ?? [];
            final currentUserRef =
                _firestore.collection('users').doc(currentUid);
            for (final ref in confirmedRefs) {
              if (ref is DocumentReference && ref.path == currentUserRef.path) {
                return ConfirmationStatus.completed;
              }
            }
          }
        }
      }

      return ConfirmationStatus.pending;
    } on FirebaseException catch (e) {
      AppLog.d('❌ TrustFlowService.checkFallbackStatus error: ${e.code} - ${e.message}');
      return ConfirmationStatus.pending;
    }
  }

  Future<Map<String, dynamic>> _loadAttendanceRecords({
    required DocumentReference gameRef,
  }) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return <String, dynamic>{};

    final currentUserRef = _firestore.collection('users').doc(currentUid);
    final jobsSnap = await _firestore
        .collection('round_jobs')
        .where('game_ref', isEqualTo: gameRef)
        .where('app_user_refs', arrayContains: currentUserRef)
        .limit(1)
        .get();

    if (jobsSnap.docs.isEmpty) {
      AppLog.d('📖 _loadAttendanceRecords: no round_jobs found for ${gameRef.path}');
      return <String, dynamic>{};
    }

    final job = jobsSnap.docs.first.data();
    final roundRef = job['round_ref'] as DocumentReference?;
    if (roundRef == null) {
      AppLog.d('📖 _loadAttendanceRecords: round_jobs doc has no round_ref');
      return <String, dynamic>{};
    }
    AppLog.d('📖 _loadAttendanceRecords: roundRef=${roundRef.path}');

    final roundSnap = await roundRef.get();
    if (!roundSnap.exists) {
      AppLog.d('📖 _loadAttendanceRecords: round doc does not exist at ${roundRef.path}');
      return <String, dynamic>{};
    }

    final roundData = roundSnap.data() as Map<String, dynamic>;
    final records = (roundData['attendance_records'] as Map<String, dynamic>?) ??
        <String, dynamic>{};
    AppLog.d('📖 _loadAttendanceRecords: found ${records.length} records: $records');
    return records;
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
    } catch (e) {
      AppLog.d('⚠️ TrustFlowService._resolveProfile fallback: $e');
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
