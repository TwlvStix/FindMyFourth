import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/models/game.dart';
import '/providers/group_vibe_provider.dart';
import '/services/vibe_group_matcher.dart';
import 'player_list_section.dart';

/// Wrapper that selects memberMatchesById from provider and passes to PlayerListSection.
/// Isolates rebuilds - only this subtree rebuilds when member data changes.
class PlayerListSectionSelector extends StatelessWidget {
  const PlayerListSectionSelector({
    super.key,
    required this.game,
    required this.groupVibeCacheKey,
    required this.hasAnimated,
    required this.isOwner,
    this.onRemovePlayer,
    required this.onPlayerTap,
    this.onMatchChipTap,
  });

  final Game game;
  final String? groupVibeCacheKey;
  final bool hasAnimated;
  final bool isOwner;

  /// Called when owner wants to remove a player. Null hides remove buttons.
  final void Function({
    required String playerName,
    required DocumentReference? playerRef,
    required bool isGuest,
    String? guestName,
  })? onRemovePlayer;

  final void Function(DocumentReference userRef) onPlayerTap;

  /// Called when vibe match chip is tapped. Null makes chips non-interactive.
  final void Function(
    DocumentReference userRef,
    String displayName,
    String photoUrl,
    GroupVibeMemberResult? memberMatch,
  )? onMatchChipTap;

  @override
  Widget build(BuildContext context) {
    final memberMatchesById =
        context.select<GroupVibeProvider, Map<String, GroupVibeMemberResult>>(
      (provider) => groupVibeCacheKey == null
          ? const <String, GroupVibeMemberResult>{}
          : provider.getMemberMatchesById(groupVibeCacheKey!),
    );

    return PlayerListSection(
      game: game,
      memberMatchesById: memberMatchesById,
      hasAnimated: hasAnimated,
      isOwner: isOwner,
      onRemovePlayer: onRemovePlayer,
      onPlayerTap: onPlayerTap,
      onMatchChipTap: onMatchChipTap,
    );
  }
}
