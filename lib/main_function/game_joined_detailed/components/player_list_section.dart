import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '/backend/backend.dart';
import '/backend/schema/trust_profile.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/widgets/trust/luxury_player_card.dart';
import '/models/game.dart';
import '/providers/profile_provider.dart';
import '/providers/provider_extensions.dart';
import '/providers/trust_provider.dart';
import '/services/vibe_group_matcher.dart';
import 'player_match_chip.dart';

/// Displays the players list for a game.
///
/// Shows registered players with trust badges and vibe match chips,
/// plus guest players. Includes remove buttons for game owner.
///
/// Reusable across game_joined_detailed and join_game_detailed.
class PlayerListSection extends StatefulWidget {
  const PlayerListSection({
    super.key,
    required this.game,
    required this.memberMatchesById,
    required this.groupVibeCacheKey,
    required this.hasAnimated,
    required this.isOwner,
    this.onRemovePlayer,
    required this.onPlayerTap,
    required this.onMatchChipTap,
  });

  final Game game;
  final Map<String, GroupVibeMemberResult> memberMatchesById;
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
  final void Function(
    DocumentReference userRef,
    String displayName,
    String photoUrl,
    GroupVibeMemberResult? memberMatch,
  ) onMatchChipTap;

  @override
  State<PlayerListSection> createState() => _PlayerListSectionState();
}

class _PlayerListSectionState extends State<PlayerListSection> {
  Future<_PlayerListData>? _playerDataFuture;
  String _playerIdsKey = '';

  @override
  void initState() {
    super.initState();
    _refreshPlayerDataFuture();
  }

  @override
  void didUpdateWidget(PlayerListSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_buildPlayerIdsKey(oldWidget.game.joinedPlayers) !=
        _buildPlayerIdsKey(widget.game.joinedPlayers)) {
      _refreshPlayerDataFuture(force: true);
    }
  }

  String _buildPlayerIdsKey(List<DocumentReference> joinedPlayers) =>
      joinedPlayers.map((ref) => ref.id).join('|');

  void _refreshPlayerDataFuture({bool force = false}) {
    final newKey = _buildPlayerIdsKey(widget.game.joinedPlayers);
    if (!force && _playerDataFuture != null && newKey == _playerIdsKey) {
      return;
    }
    _playerIdsKey = newKey;
    _playerDataFuture = _loadPlayerData(widget.game.joinedPlayers);
  }

  Future<_PlayerListData> _loadPlayerData(
    List<DocumentReference> joinedPlayers,
  ) async {
    if (joinedPlayers.isEmpty) return const _PlayerListData.empty();

    final uniqueIds = joinedPlayers.map((ref) => ref.id).toSet().toList();
    final profileProvider = context.read<ProfileProvider>();
    final trustProvider = context.read<TrustProvider>();

    final results = await Future.wait<Object>([
      profileProvider.batchGetProfiles(uniqueIds),
      _fetchTrustProfiles(trustProvider, uniqueIds),
    ]);

    return _PlayerListData(
      profileMap: results[0] as Map<String, UsersRecord>,
      trustProfilesById: results[1] as Map<String, TrustProfile?>,
    );
  }

  Future<Map<String, TrustProfile?>> _fetchTrustProfiles(
    TrustProvider trustProvider,
    List<String> userIds,
  ) async {
    final entries = await Future.wait(
      userIds.map((userId) async {
        final profile = await trustProvider.fetchTrustProfile(userId);
        return MapEntry(userId, profile);
      }),
    );

    return {
      for (final entry in entries) entry.key: entry.value,
    };
  }

  @override
  Widget build(BuildContext context) {
    final groupVibeProvider = context.watchGroupVibeProvider;
    final groupPlayers = widget.game.joinedPlayers.toList();

    // Sort players by vibe match if available
    if (widget.memberMatchesById.isNotEmpty && widget.groupVibeCacheKey != null) {
      groupPlayers.sort(
        (a, b) => groupVibeProvider.compareMemberIds(
          cacheKey: widget.groupVibeCacheKey!,
          aId: a.id,
          bId: b.id,
        ),
      );
    }

    final guestPlayers = widget.game.guestPlayers
        .where((name) => name.trim().isNotEmpty)
        .toList();
    final gameOwner = widget.game.userRef;

    // Note: Section header is rendered separately in parent widget
    // This component only renders the player cards
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: FutureBuilder<_PlayerListData>(
        future: _playerDataFuture,
        builder: (context, sectionDataSnapshot) {
          final sectionData = sectionDataSnapshot.data ?? const _PlayerListData.empty();
          final profileMap = sectionData.profileMap;
          final trustProfilesById = sectionData.trustProfilesById;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Registered players
              ...List.generate(groupPlayers.length, (index) {
                final playerRef = groupPlayers[index];
                final isPlayerOwner = gameOwner != null && playerRef == gameOwner;
                final profile = profileMap[playerRef.id];
                final displayName = (profile?.displayName ?? '').trim().isNotEmpty
                    ? profile!.displayName
                    : 'Golfer';
                final userRef = profile?.reference ?? playerRef;
                final photoUrl = profile?.photoUrl ?? '';

                return _RegisteredPlayerCard(
                  playerRef: playerRef,
                  displayName: displayName,
                  photoUrl: photoUrl,
                  userRef: userRef,
                  isPlayerOwner: isPlayerOwner,
                  isViewerOwner: widget.isOwner,
                  memberMatch: widget.memberMatchesById[playerRef.id],
                  trustProfile: trustProfilesById[playerRef.id],
                  staggerIndex: index,
                  hasAnimated: widget.hasAnimated,
                  onRemove: widget.onRemovePlayer != null
                      ? () => widget.onRemovePlayer!(
                            playerName: displayName,
                            playerRef: playerRef,
                            isGuest: false,
                          )
                      : null,
                  onTap: () => widget.onPlayerTap(userRef),
                  onMatchChipTap: () => widget.onMatchChipTap(
                    userRef,
                    displayName,
                    photoUrl,
                    widget.memberMatchesById[playerRef.id],
                  ),
                );
              }),

              // Guest players
              ...guestPlayers.asMap().entries.map((entry) {
                final guestIndex = entry.key;
                final guestName = entry.value;
                final combinedIndex = groupPlayers.length + guestIndex;

                return _GuestPlayerCard(
                  guestName: guestName,
                  isViewerOwner: widget.isOwner,
                  staggerIndex: combinedIndex,
                  hasAnimated: widget.hasAnimated,
                  onRemove: widget.onRemovePlayer != null
                      ? () => widget.onRemovePlayer!(
                            playerName: guestName,
                            playerRef: null,
                            isGuest: true,
                            guestName: guestName,
                          )
                      : null,
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

/// Registered player card with trust badge and vibe match
class _RegisteredPlayerCard extends StatelessWidget {
  const _RegisteredPlayerCard({
    required this.playerRef,
    required this.displayName,
    required this.photoUrl,
    required this.userRef,
    required this.isPlayerOwner,
    required this.isViewerOwner,
    required this.memberMatch,
    required this.trustProfile,
    required this.staggerIndex,
    required this.hasAnimated,
    this.onRemove,
    required this.onTap,
    required this.onMatchChipTap,
  });

  final DocumentReference playerRef;
  final String displayName;
  final String photoUrl;
  final DocumentReference userRef;
  final bool isPlayerOwner;
  final bool isViewerOwner;
  final GroupVibeMemberResult? memberMatch;
  final TrustProfile? trustProfile;
  final int staggerIndex;
  final bool hasAnimated;
  final VoidCallback? onRemove;
  final VoidCallback onTap;
  final VoidCallback onMatchChipTap;

  @override
  Widget build(BuildContext context) {
    final clampedIndex = staggerIndex < MotionTokens.staggerMaxItems
        ? staggerIndex
        : MotionTokens.staggerMaxItems - 1;
    final staggerDelay = ReducedMotionService.shouldStagger
        ? MotionTokens.staggerDelay * clampedIndex
        : Duration.zero;

    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: AppSpacing.sm),
      child: LuxuryPlayerCard(
        name: displayName,
        avatarUrl: photoUrl,
        tier: trustProfile?.currentBadge ?? BadgeTier.newPlayer,
        isFavorite: isPlayerOwner,
        status: 'Ready',
        percentWidget: PlayerMatchChip(
          name: displayName,
          memberMatch: memberMatch,
          onTap: onMatchChipTap,
        ),
        trailingWidget: isViewerOwner && onRemove != null
            ? AppIconButton(
                icon: AppIcon(
                  icon: AppPhosphorIcons.remove,
                  color: AppColors.error,
                  size: AppIconSize.md,
                ),
                borderRadius: 20.0,
                buttonSize: 40.0,
                fillColor: Colors.transparent,
                tooltip: 'Remove player',
                onPressed: onRemove,
              )
            : AppIcon(
                icon: AppPhosphorIcons.joined,
                color: AppColors.green,
                size: AppIconSize.md,
              ),
        onTap: onTap,
      ),
    )
        .animate(target: hasAnimated ? 1 : 0)
        .fadeIn(
          delay: staggerDelay,
          duration: ReducedMotionService.adjust(MotionTokens.contentReveal),
          curve: MotionTokens.curveEnter,
        )
        .slideY(
          delay: staggerDelay,
          begin: 0.1,
          end: 0,
          duration: ReducedMotionService.adjust(MotionTokens.contentReveal),
          curve: MotionTokens.curveEnter,
        );
  }
}

/// Guest player card with simpler styling
class _GuestPlayerCard extends StatelessWidget {
  const _GuestPlayerCard({
    required this.guestName,
    required this.isViewerOwner,
    required this.staggerIndex,
    required this.hasAnimated,
    this.onRemove,
  });

  final String guestName;
  final bool isViewerOwner;
  final int staggerIndex;
  final bool hasAnimated;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final clampedIndex = staggerIndex < MotionTokens.staggerMaxItems
        ? staggerIndex
        : MotionTokens.staggerMaxItems - 1;
    final staggerDelay = ReducedMotionService.shouldStagger
        ? MotionTokens.staggerDelay * clampedIndex
        : Duration.zero;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.navy.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: AppColors.navyLight.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar placeholder
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: AppColors.navyLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2.0,
                ),
              ),
              child: Center(
                child: Text(
                  'G',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            // Name and guest label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    guestName,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Guest',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Remove button for owner
            if (isViewerOwner && onRemove != null)
              AppIconButton(
                icon: AppIcon(
                  icon: AppPhosphorIcons.remove,
                  color: AppColors.error,
                  size: AppIconSize.md,
                ),
                borderRadius: 20.0,
                buttonSize: 40.0,
                fillColor: Colors.transparent,
                tooltip: 'Remove guest',
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    )
        .animate(target: hasAnimated ? 1 : 0)
        .fadeIn(
          delay: staggerDelay,
          duration: ReducedMotionService.adjust(MotionTokens.contentReveal),
          curve: MotionTokens.curveEnter,
        )
        .slideY(
          delay: staggerDelay,
          begin: 0.1,
          end: 0,
          duration: ReducedMotionService.adjust(MotionTokens.contentReveal),
          curve: MotionTokens.curveEnter,
        );
  }
}

class _PlayerListData {
  const _PlayerListData({
    required this.profileMap,
    required this.trustProfilesById,
  });

  const _PlayerListData.empty()
      : profileMap = const <String, UsersRecord>{},
        trustProfilesById = const <String, TrustProfile?>{};

  final Map<String, UsersRecord> profileMap;
  final Map<String, TrustProfile?> trustProfilesById;
}
