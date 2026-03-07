import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/design_tokens/colors.dart';
import '/core/navigation/nav_extensions.dart';
import '/core/utils/app_log.dart';
import '/core/utils/state_update.dart';
import '/main_function/games_list/components/mutual_card_actions.dart';
import '/providers/chat_provider.dart';
import '/providers/user_provider.dart';

/// Handles action callbacks for mutual friend game cards.
///
/// Manages the "Ask to Chat" and "Add Friend" actions including loading states,
/// error handling, and snackbar feedback.
class GamesListMutualActionHandler {
  GamesListMutualActionHandler({
    required State state,
  }) : _state = state;

  final State _state;

  // Track action states for mutual cards: hostId -> state
  final Map<String, MutualActionState> chatActionStates = {};
  final Map<String, MutualActionState> friendActionStates = {};

  /// Handle "Ask to Chat" action for a mutual friend game.
  Future<void> handleAskToChat(DocumentReference hostRef) async {
    final hostId = hostRef.id;
    if (chatActionStates[hostId] == MutualActionState.completed) return;

    updateState(_state, () {
      chatActionStates[hostId] = MutualActionState.loading;
    });

    try {
      final context = _state.context;
      final currentUserId = context.read<UserProvider>().currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      // Create or get existing DM chat
      final chatProvider = context.read<ChatProvider>();
      final chatRef = await chatProvider.createOrGetDirectChat(
        currentUid: currentUserId,
        otherUid: hostId,
      );

      if (!_state.mounted) return;

      updateState(_state, () {
        chatActionStates[hostId] = MutualActionState.completed;
      });

      // Navigate to chat
      _state.context.pushChatDetails(chatId: chatRef.id);
    } catch (e) {
      AppLog.d('❌ GamesListMutualActionHandler.handleAskToChat error: $e');
      if (!_state.mounted) return;

      updateState(_state, () {
        chatActionStates[hostId] = MutualActionState.idle;
      });

      ScaffoldMessenger.of(_state.context).showSnackBar(
        SnackBar(
          content: Text('Could not open chat. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Handle "Add Friend" action for a mutual friend game.
  Future<void> handleAddFriendFromMutual(DocumentReference hostRef) async {
    final hostId = hostRef.id;
    if (friendActionStates[hostId] == MutualActionState.completed) return;

    updateState(_state, () {
      friendActionStates[hostId] = MutualActionState.loading;
    });

    try {
      await _state.context.read<UserProvider>().sendFriendRequest(hostRef);

      if (!_state.mounted) return;

      updateState(_state, () {
        friendActionStates[hostId] = MutualActionState.completed;
      });

      ScaffoldMessenger.of(_state.context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      AppLog.d(
          '❌ GamesListMutualActionHandler.handleAddFriendFromMutual error: $e');
      if (!_state.mounted) return;

      updateState(_state, () {
        friendActionStates[hostId] = MutualActionState.idle;
      });

      ScaffoldMessenger.of(_state.context).showSnackBar(
        SnackBar(
          content: Text('Failed to send friend request. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
