import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/main_function/games_list/components/premium_game_card.dart';
import '/main_function/games_list/utils/cancelled_game_handler.dart';
import '/models/game.dart';
import '/providers/provider_extensions.dart';

/// A selector wrapper for PremiumGameCard in the friends-only section.
///
/// Uses fine-grained selector to only rebuild when the pending friend request
/// state changes for this specific game's host. This prevents the entire list
/// from rebuilding when unrelated UserProvider state changes.
class FriendsOnlyCardSelector extends StatelessWidget {
  const FriendsOnlyCardSelector({
    super.key,
    required this.game,
    required this.currentUserReference,
    required this.getCancelledHandling,
    required this.onCancelledGameTap,
    required this.onFriendsOnlyTap,
    required this.onSendFriendRequest,
    required this.animationIndex,
    required this.staggerDelay,
    required this.isLast,
  });

  final Game game;
  final DocumentReference? currentUserReference;
  final CancelledGameHandling? Function(Game game) getCancelledHandling;
  final Future<void> Function(Game game) onCancelledGameTap;
  final Future<void> Function() onFriendsOnlyTap;
  final Future<void> Function(BuildContext context, DocumentReference hostRef)
      onSendFriendRequest;
  final int animationIndex;
  final Duration staggerDelay;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final hostRef = game.userRef;

    // Use selector to only rebuild when this specific host's pending state changes
    final hasPendingRequest = hostRef != null
        ? context.hasPendingOutgoing(hostRef.id)
        : false;

    return PremiumGameCard(
      game: game,
      currentUserReference: currentUserReference,
      isLocked: true,
      hasPendingFriendRequest: hasPendingRequest,
      onAddFriend: hostRef != null
          ? () => onSendFriendRequest(context, hostRef)
          : null,
      getCancelledHandling: getCancelledHandling,
      onCancelledGameTap: onCancelledGameTap,
      onFriendsOnlyTap: onFriendsOnlyTap,
      animationIndex: animationIndex,
      staggerDelay: staggerDelay,
    );
  }
}
