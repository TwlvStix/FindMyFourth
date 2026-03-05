import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model for a cancellation record.
///
/// This is a pure Dart model (not a schema record). It wraps Firestore data
/// with typed fields and provides a computed [tier] property that re-derives
/// the cancellation tier from the stored [hoursBeforeTeeTime] float,
/// mirroring the logic in the Cloud Function [calculateCancellationTier].
class CancellationRecord {
  CancellationRecord({
    required this.reference,
    required this.playerRef,
    required this.gameRef,
    required this.cancelledAt,
    required this.teeTime,
    required this.hoursBeforeTeeTime,
    required this.gameType,
    required this.isGhost,
    this.storedTier,
  });

  final DocumentReference reference;
  final DocumentReference playerRef;
  final DocumentReference gameRef;
  final DateTime cancelledAt;
  final DateTime teeTime;

  /// Hours between cancellation time and tee time.
  /// Positive value means the cancellation happened before the tee time.
  /// Stored by the Cloud Function at write time.
  final double hoursBeforeTeeTime;

  /// The tier value as stored by the Cloud Function.
  /// The computed [tier] getter is the authoritative value for display —
  /// it re-derives from [hoursBeforeTeeTime] so it always matches
  /// the Cloud Function's calculation, even if storedTier is absent.
  final String? storedTier;
  final String gameType;
  final bool isGhost;

  /// Computed cancellation tier — mirrors Cloud Function calculateCancellationTier().
  ///
  /// 36+ hours before tee time  → 'early'
  /// 12-36 hours before         → 'late'
  /// under 12 hours before      → 'day_of'
  String get tier {
    if (hoursBeforeTeeTime >= 36.0) return 'early';
    if (hoursBeforeTeeTime >= 12.0) return 'late';
    return 'day_of';
  }

  /// Human-readable label for the tier.
  String get tierLabel {
    switch (tier) {
      case 'early':
        return 'Early cancellation';
      case 'late':
        return 'Late cancellation';
      case 'day_of':
        return 'Day-of cancellation';
      default:
        return 'Cancellation';
    }
  }

  /// Creates a CancellationRecord from a Firestore document.
  ///
  /// Accepts optional [firestore] parameter for testability and to avoid
  /// direct FirebaseFirestore.instance calls in the model layer.
  static CancellationRecord fromDoc(
    DocumentSnapshot doc, {
    FirebaseFirestore? firestore,
  }) {
    final fs = firestore ?? FirebaseFirestore.instance;
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    final cancelledAt =
        (data['cancelled_at'] as Timestamp?)?.toDate() ?? DateTime.now();
    final teeTime =
        (data['tee_time'] as Timestamp?)?.toDate() ?? DateTime.now();

    // hours_before_tee_time is stored by the Cloud Function.
    // If absent (legacy data), derive from stored timestamps as fallback.
    double hours;
    final storedHours = data['hours_before_tee_time'];
    if (storedHours is num) {
      hours = storedHours.toDouble();
    } else {
      // teeTime.difference(cancelledAt) is positive when cancelled before tee time.
      hours = teeTime.difference(cancelledAt).inMinutes / 60.0;
    }

    return CancellationRecord(
      reference: doc.reference,
      playerRef: data['player_ref'] as DocumentReference? ??
          fs.collection('users').doc('unknown'),
      gameRef: data['game_ref'] as DocumentReference? ??
          fs.collection('games').doc('unknown'),
      cancelledAt: cancelledAt,
      teeTime: teeTime,
      hoursBeforeTeeTime: hours,
      storedTier: data['tier'] as String?,
      gameType: (data['game_type'] as String?) ?? '',
      isGhost: (data['is_ghost'] as bool?) ?? false,
    );
  }
}
