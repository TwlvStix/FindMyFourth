import 'package:flutter/material.dart';

import '/core/utils/state_update.dart';
import '/models/join_request.dart';
import '/utils/app_util.dart';

import 'game_joined_detailed_controller.dart';

/// Callback to update pending requests list in widget state.
typedef OnPendingRequestsChanged = void Function(
  List<JoinRequest> requests,
  String? expandedRequestId,
);

/// Handles join request approval/decline actions and list state management.
///
/// Delegates business logic to [GameJoinedDetailedController], handles UI
/// feedback (snackbars) and state updates.
class GameJoinedRequestActions {
  GameJoinedRequestActions({
    required this.controller,
  });

  final GameJoinedDetailedController controller;

  /// Approves a join request and shows appropriate feedback.
  ///
  /// On success, does not show a snackbar (UI will update via stream).
  /// On game-full error, shows error and notifies requester.
  /// On other errors, shows generic error snackbar.
  Future<void> handleApproveRequest({
    required BuildContext context,
    required State state,
    required JoinRequest request,
  }) async {
    final result = await controller.approveRequest(
      request: request,
    );

    if (!state.mounted || !context.mounted) return;

    if (!result.success && result.message != null) {
      showSnackbar(context, result.message!);
    }
    // Success case: UI updates via stream, no snackbar needed
  }

  /// Declines a join request and shows appropriate feedback.
  ///
  /// On failure, shows error snackbar.
  Future<void> handleDeclineRequest({
    required BuildContext context,
    required State state,
    required JoinRequest request,
  }) async {
    final result = await controller.declineRequest(request);

    if (!state.mounted || !context.mounted) return;

    if (!result.success && result.message != null) {
      showSnackbar(context, result.message!);
    }
  }

  /// Removes a request from the list after approval/decline.
  ///
  /// Updates [pendingRequests] list and [expandedRequestId] in widget state.
  void removeRequestFromList({
    required State state,
    required String requestId,
    required List<JoinRequest> pendingRequests,
    required String? expandedRequestId,
    required OnPendingRequestsChanged onChanged,
  }) {
    if (!state.mounted) return;

    final updatedRequests = List<JoinRequest>.from(pendingRequests)
      ..removeWhere((r) => r.id == requestId);

    String? newExpandedId = expandedRequestId;
    if (expandedRequestId == requestId) {
      newExpandedId =
          updatedRequests.isNotEmpty ? updatedRequests.first.id : null;
    }

    updateState(state, () {
      onChanged(updatedRequests, newExpandedId);
    });
  }

  /// Expands a request card (collapses others).
  ///
  /// Updates [expandedRequestId] in widget state.
  void expandRequest({
    required State state,
    required String requestId,
    required String? currentExpandedId,
    required void Function(String?) onExpandedChanged,
  }) {
    if (currentExpandedId != requestId) {
      updateState(state, () {
        onExpandedChanged(requestId);
      });
    }
  }
}
