import '/services/trust_flow_service.dart';

/// Data class for a participant in the host check-in roster.
///
/// Wraps [HostCheckinParticipant] from the service layer for UI consumption.
class CheckinParticipantEntry {
  const CheckinParticipantEntry({
    required this.key,
    required this.displayName,
    required this.photoUrl,
    required this.isGuest,
    required this.role,
  });

  factory CheckinParticipantEntry.fromServiceModel(
      HostCheckinParticipant p) {
    return CheckinParticipantEntry(
      key: p.key,
      displayName: p.displayName,
      photoUrl: p.photoUrl,
      isGuest: p.isGuest,
      role: p.role,
    );
  }

  final String key;
  final String displayName;
  final String photoUrl;
  final bool isGuest;
  final String role;
}
