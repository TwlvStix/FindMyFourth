import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/utils/app_util.dart';

class RoundRecordsRecord extends FirestoreRecord {
  RoundRecordsRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "game_ref" field.
  DocumentReference? _gameRef;
  DocumentReference? get gameRef => _gameRef;
  bool hasGameRef() => _gameRef != null;

  // "course_ref" field.
  DocumentReference? _courseRef;
  DocumentReference? get courseRef => _courseRef;
  bool hasCourseRef() => _courseRef != null;

  // "tee_time" field.
  DateTime? _teeTime;
  DateTime? get teeTime => _teeTime;
  bool hasTeeTime() => _teeTime != null;

  // "game_type" field.
  String? _gameType;
  String get gameType => _gameType ?? '';
  bool hasGameType() => _gameType != null;

  // "game_settings" field. Denormalized snapshot of game settings at booking.
  Map<String, dynamic>? _gameSettings;
  Map<String, dynamic> get gameSettings => _gameSettings ?? const {};
  bool hasGameSettings() => _gameSettings != null;

  // "participant_snapshots" field.
  // Array of player profile snapshots at booking time (uid, display_name, handicap, badge_level).
  List<Map<String, dynamic>>? _participantSnapshots;
  List<Map<String, dynamic>> get participantSnapshots =>
      _participantSnapshots ?? const [];
  bool hasParticipantSnapshots() => _participantSnapshots != null;

  // "vibe_match_scores" field.
  // Pairwise vibe compatibility scores at booking time, keyed by sorted pair UID
  // string (e.g. "uid1:uid2"). Required for Phase 3 ML — captures the algorithm's
  // prediction at booking so it can be compared to actual "would play again" outcomes.
  Map<String, dynamic>? _vibeMatchScores;
  Map<String, dynamic> get vibeMatchScores => _vibeMatchScores ?? const {};
  bool hasVibeMatchScores() => _vibeMatchScores != null;

  // "verified_at" field. Timestamp when round was verified by 2+ app users.
  DateTime? _verifiedAt;
  DateTime? get verifiedAt => _verifiedAt;
  bool hasVerifiedAt() => _verifiedAt != null;

  // "verification_status" field. 'pending' | 'verified' | 'failed' | 'expired'
  String? _verificationStatus;
  String get verificationStatus => _verificationStatus ?? 'pending';
  bool hasVerificationStatus() => _verificationStatus != null;

  // "host_check_in_at" field. When host submitted attendance confirmation.
  DateTime? _hostCheckInAt;
  DateTime? get hostCheckInAt => _hostCheckInAt;
  bool hasHostCheckInAt() => _hostCheckInAt != null;

  // "confirmed_player_refs" field. App users who confirmed the round happened.
  List<DocumentReference>? _confirmedPlayerRefs;
  List<DocumentReference> get confirmedPlayerRefs =>
      _confirmedPlayerRefs ?? const [];
  bool hasConfirmedPlayerRefs() => _confirmedPlayerRefs != null;

  // "attendance_records" field. Map of uid -> 'present' | 'no_show' | 'pending'
  Map<String, dynamic>? _attendanceRecords;
  Map<String, dynamic> get attendanceRecords => _attendanceRecords ?? const {};
  bool hasAttendanceRecords() => _attendanceRecords != null;

  void _initializeFields() {
    _gameRef = snapshotData['game_ref'] as DocumentReference?;
    _courseRef = snapshotData['course_ref'] as DocumentReference?;
    _teeTime = snapshotData['tee_time'] as DateTime?;
    _gameType = snapshotData['game_type'] as String?;
    final gameSettingsRaw = snapshotData['game_settings'];
    if (gameSettingsRaw is Map) {
      _gameSettings = Map<String, dynamic>.from(gameSettingsRaw);
    }
    final snapshotsRaw = snapshotData['participant_snapshots'];
    if (snapshotsRaw is List) {
      // mapFromFirestore already converts nested Timestamps to DateTime.
      _participantSnapshots = snapshotsRaw
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    final vibeScoresRaw = snapshotData['vibe_match_scores'];
    if (vibeScoresRaw is Map) {
      _vibeMatchScores = Map<String, dynamic>.from(vibeScoresRaw);
    }
    _verifiedAt = snapshotData['verified_at'] as DateTime?;
    _verificationStatus = snapshotData['verification_status'] as String?;
    _hostCheckInAt = snapshotData['host_check_in_at'] as DateTime?;
    final confirmedRaw = snapshotData['confirmed_player_refs'];
    if (confirmedRaw is List) {
      _confirmedPlayerRefs = confirmedRaw
          .map((item) {
            if (item is DocumentReference) return item;
            if (item is String && item.isNotEmpty) {
              return FirebaseFirestore.instance.doc(item);
            }
            return null;
          })
          .whereType<DocumentReference>()
          .toList();
    }
    final attendanceRaw = snapshotData['attendance_records'];
    if (attendanceRaw is Map) {
      _attendanceRecords = Map<String, dynamic>.from(attendanceRaw);
    }
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('round_records');

  static Stream<RoundRecordsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => RoundRecordsRecord.fromSnapshot(s));

  static Future<RoundRecordsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => RoundRecordsRecord.fromSnapshot(s));

  static RoundRecordsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      RoundRecordsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static RoundRecordsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      RoundRecordsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'RoundRecordsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is RoundRecordsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createRoundRecordsRecordData({
  DocumentReference? gameRef,
  DocumentReference? courseRef,
  DateTime? teeTime,
  String? gameType,
  Map<String, dynamic>? gameSettings,
  List<Map<String, dynamic>>? participantSnapshots,
  Map<String, dynamic>? vibeMatchScores,
  DateTime? verifiedAt,
  String? verificationStatus,
  DateTime? hostCheckInAt,
  List<DocumentReference>? confirmedPlayerRefs,
  Map<String, dynamic>? attendanceRecords,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'game_ref': gameRef,
      'course_ref': courseRef,
      'tee_time': teeTime,
      'game_type': gameType,
      'game_settings': gameSettings,
      'participant_snapshots': participantSnapshots,
      'vibe_match_scores': vibeMatchScores,
      'verified_at': verifiedAt,
      'verification_status': verificationStatus,
      'host_check_in_at': hostCheckInAt,
      'confirmed_player_refs': confirmedPlayerRefs,
      'attendance_records': attendanceRecords,
    }.withoutNulls,
  );

  return firestoreData;
}

class RoundRecordsRecordDocumentEquality
    implements Equality<RoundRecordsRecord> {
  const RoundRecordsRecordDocumentEquality();

  @override
  bool equals(RoundRecordsRecord? e1, RoundRecordsRecord? e2) {
    const listEquality = ListEquality();
    const mapEquality = DeepCollectionEquality();
    return e1?.gameRef == e2?.gameRef &&
        e1?.courseRef == e2?.courseRef &&
        e1?.teeTime == e2?.teeTime &&
        e1?.gameType == e2?.gameType &&
        mapEquality.equals(e1?.gameSettings, e2?.gameSettings) &&
        listEquality.equals(e1?.participantSnapshots, e2?.participantSnapshots) &&
        mapEquality.equals(e1?.vibeMatchScores, e2?.vibeMatchScores) &&
        e1?.verifiedAt == e2?.verifiedAt &&
        e1?.verificationStatus == e2?.verificationStatus &&
        e1?.hostCheckInAt == e2?.hostCheckInAt &&
        listEquality.equals(e1?.confirmedPlayerRefs, e2?.confirmedPlayerRefs) &&
        mapEquality.equals(e1?.attendanceRecords, e2?.attendanceRecords);
  }

  @override
  int hash(RoundRecordsRecord? e) => const ListEquality().hash([
        e?.gameRef,
        e?.courseRef,
        e?.teeTime,
        e?.gameType,
        const DeepCollectionEquality().hash(e?.gameSettings),
        e?.participantSnapshots,
        const DeepCollectionEquality().hash(e?.vibeMatchScores),
        e?.verifiedAt,
        e?.verificationStatus,
        e?.hostCheckInAt,
        e?.confirmedPlayerRefs,
        const DeepCollectionEquality().hash(e?.attendanceRecords),
      ]);

  @override
  bool isValidKey(Object? o) => o is RoundRecordsRecord;
}
