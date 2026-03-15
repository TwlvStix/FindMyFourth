import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/core/design_tokens/spacing.dart';
import '/main_function/games_list/components/mutual_card_actions.dart';
import '/main_function/games_list/components/mutual_game_card.dart';
import '/main_function/games_list/components/unified_game_card.dart';
import '/models/game.dart';

/// Sliver list of joinable games rendered as [UnifiedGameCard]s.
class JoinableGamesSliverList extends StatelessWidget {
  const JoinableGamesSliverList({
    super.key,
    required this.games,
    required this.currentUserReference,
    required this.vibeScores,
    this.hasMutualGames = false,
  });

  final List<Game> games;
  final DocumentReference? currentUserReference;
  final Map<String, double> vibeScores;
  final bool hasMutualGames;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final game = games[index];
            final isLast = index == games.length - 1;
            return Padding(
              padding: EdgeInsets.only(
                bottom: isLast && !hasMutualGames
                    ? AppSpacing.md
                    : AppSpacing.sm,
              ),
              child: UnifiedGameCard(
                game: game,
                currentUserReference: currentUserReference,
                vibeScore: vibeScores[game.reference.id],
                animationIndex: index,
                showStatusBadge: true,
              ),
            );
          },
          childCount: games.length,
        ),
      ),
    );
  }
}

/// Sliver list of mutual-friend games rendered as [MutualGameCard]s.
class MutualGamesSliverList extends StatelessWidget {
  const MutualGamesSliverList({
    super.key,
    required this.games,
    required this.firstMutualFriendName,
    required this.mutualFriendsMap,
    required this.chatActionStates,
    required this.friendActionStates,
    required this.joinableGameCount,
    this.onAskToChat,
    this.onAddFriendFromMutual,
  });

  final List<Game> games;
  final Map<String, String> firstMutualFriendName;
  final Map<String, List<String>> mutualFriendsMap;
  final Map<String, MutualActionState> chatActionStates;
  final Map<String, MutualActionState> friendActionStates;
  final int joinableGameCount;
  final Future<void> Function(DocumentReference)? onAskToChat;
  final Future<void> Function(DocumentReference)? onAddFriendFromMutual;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final game = games[index];
            final hostId = game.userRef?.id ?? game.uid;
            final mutualName = firstMutualFriendName[hostId] ?? 'a friend';
            final mutualCount =
                (mutualFriendsMap[hostId]?.length ?? 1) - 1;
            final animationIndex = joinableGameCount + index;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < games.length - 1
                    ? AppSpacing.sm
                    : AppSpacing.md,
              ),
              child: MutualGameCard(
                game: game,
                mutualFriendName: mutualName,
                additionalMutualCount: mutualCount,
                chatState: chatActionStates[hostId] ?? MutualActionState.idle,
                friendState:
                    friendActionStates[hostId] ?? MutualActionState.idle,
                animationIndex: animationIndex,
                onAskToChat: () {
                  if (onAskToChat != null && game.userRef != null) {
                    onAskToChat!(game.userRef!);
                  }
                },
                onAddFriend: () {
                  if (onAddFriendFromMutual != null && game.userRef != null) {
                    onAddFriendFromMutual!(game.userRef!);
                  }
                },
              ),
            );
          },
          childCount: games.length,
        ),
      ),
    );
  }
}
