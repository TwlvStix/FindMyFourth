import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/cloud_functions/cloud_functions.dart';
import '/core/utils/app_log.dart';
import '/screens/confirmation/components/checkin_participant_entry.dart';
import '/services/trust_flow_service.dart';

// ── Load result types ─────────────────────────────────────────────────────

sealed class HostCheckinLoadResult {}

class HostCheckinReady extends HostCheckinLoadResult {
  HostCheckinReady({
    required this.courseName,
    required this.participants,
    required this.defaultAttendance,
  });

  final String courseName;
  final List<CheckinParticipantEntry> participants;
  final Map<String, bool> defaultAttendance;
}

class HostCheckinAlreadyCompleted extends HostCheckinLoadResult {}

class HostCheckinWindowClosed extends HostCheckinLoadResult {}

class HostCheckinLoadError extends HostCheckinLoadResult {
  HostCheckinLoadError(this.message);
  final String message;
}

// ── Submit result types ───────────────────────────────────────────────────

sealed class HostCheckinSubmitResult {}

class HostCheckinSubmitSuccess extends HostCheckinSubmitResult {}

class HostCheckinSubmitError extends HostCheckinSubmitResult {
  HostCheckinSubmitError(this.message);
  final String message;
}

// ── Controller ────────────────────────────────────────────────────────────

class HostCheckinController {
  HostCheckinController({TrustFlowService? trustFlowService})
      : _trustFlowService = trustFlowService ?? TrustFlowService();

  final TrustFlowService _trustFlowService;

  /// Loads participant data for the host check-in form.
  Future<HostCheckinLoadResult> loadParticipants(
      DocumentReference gameRef) async {
    try {
      final status = await _trustFlowService.checkHostCheckinStatus(
        gameRef: gameRef,
      );
      if (status == ConfirmationStatus.completed) {
        return HostCheckinAlreadyCompleted();
      }
      if (status == ConfirmationStatus.windowClosed) {
        return HostCheckinWindowClosed();
      }

      final data = await _trustFlowService.loadHostCheckinParticipants(
        gameRef: gameRef,
      );
      final entries = data.participants
          .map(CheckinParticipantEntry.fromServiceModel)
          .toList(growable: false);

      return HostCheckinReady(
        courseName: data.courseName,
        participants: entries,
        defaultAttendance: data.defaultAttendance,
      );
    } on StateError catch (e) {
      final code = e.message;
      return HostCheckinLoadError(
        code == 'game_not_found'
            ? 'Game not found.'
            : 'Failed to load participants. Please try again.',
      );
    } catch (e) {
      AppLog.d('❌ HostCheckinController load error: $e '
          'gameRef=${gameRef.path}');
      return HostCheckinLoadError(
          'Failed to load participants. Please try again.');
    }
  }

  /// Submits attendance to the cloud function.
  Future<HostCheckinSubmitResult> submitAttendance({
    required String gameId,
    required Map<String, bool> attendance,
  }) async {
    try {
      final result = await makeCloudCall('submitHostCheckin', {
        'gameId': gameId,
        'attendance': Map<String, dynamic>.from(
          attendance.map((k, v) => MapEntry(k, v)),
        ),
      });

      if (result['success'] == true) {
        return HostCheckinSubmitSuccess();
      }
      return HostCheckinSubmitError('Submission failed. Please try again.');
    } catch (e) {
      AppLog.d('❌ HostCheckinController submit error: $e');
      return HostCheckinSubmitError('Something went wrong. Please try again.');
    }
  }

}
