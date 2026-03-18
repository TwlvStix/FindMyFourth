import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/providers/profile_provider.dart';

/// Overlapping avatar stack showing game participants with host name.
///
/// Displays up to [maxAvatars] player avatars in an overlapping stack,
/// followed by "hosted by {name}" text.
class GameCardAvatarStack extends StatelessWidget {
  const GameCardAvatarStack({
    super.key,
    required this.playerRefs,
    required this.hostRef,
    this.maxAvatars = 3,
  });

  /// References to joined players (includes host)
  final List<DocumentReference> playerRefs;

  /// Reference to the game host/owner
  final DocumentReference? hostRef;

  /// Maximum number of avatars to display
  final int maxAvatars;

  static const double _avatarSize = 26.0;
  static const double _overlap = 8.0;
  static const double _borderWidth = 2.0;

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.read<ProfileProvider>();

    // Get all unique player refs (include host if not in players)
    final allPlayers = <DocumentReference>{
      if (hostRef != null) hostRef!,
      ...playerRefs,
    }.toList();

    // Take only maxAvatars for display
    final displayPlayers = allPlayers.take(maxAvatars).toList();

    // Get host display name
    final hostProfile = hostRef != null
        ? profileProvider.getCachedProfile(hostRef!.id)
        : null;
    final hostName = hostProfile?.displayName ?? 'Host';
    final hostFirstName = hostName.split(' ').first;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar stack
        if (displayPlayers.isNotEmpty)
          SizedBox(
            width: _avatarSize + (_overlap * (displayPlayers.length - 1)),
            height: _avatarSize,
            child: Stack(
              children: displayPlayers.asMap().entries.map((entry) {
                final index = entry.key;
                final playerRef = entry.value;
                final profile = profileProvider.getCachedProfile(playerRef.id);

                return Positioned(
                  left: index * (_avatarSize - _overlap),
                  child: _StackedAvatar(
                    imageUrl: profile?.photoUrl,
                    initials: _getInitials(profile?.displayName),
                    backgroundColor: _getAvatarColor(index),
                  ),
                );
              }).toList(),
            ),
          ),
        SizedBox(width: AppSpacing.xs),
        // Host name
        Flexible(
          child: Text(
            'hosted by $hostFirstName',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getInitials(String? displayName) {
    if (displayName == null || displayName.isEmpty) return '?';
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  Color _getAvatarColor(int index) {
    // Cycle through distinct colors for visual variety
    final colors = [
      AppColors.green,
      AppColors.greenDark,
      AppColors.navyLight,
    ];
    return colors[index % colors.length];
  }
}

class _StackedAvatar extends StatelessWidget {
  const _StackedAvatar({
    this.imageUrl,
    required this.initials,
    required this.backgroundColor,
  });

  final String? imageUrl;
  final String initials;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final hasValidImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      width: GameCardAvatarStack._avatarSize,
      height: GameCardAvatarStack._avatarSize,
      decoration: BoxDecoration(
        color: hasValidImage ? null : backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.navy, // Match card background
          width: GameCardAvatarStack._borderWidth,
        ),
        image: hasValidImage
            ? DecorationImage(
                image: CachedNetworkImageProvider(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: !hasValidImage
          ? Center(
              child: Text(
                initials,
                style: AppTypography.labelMicro.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.pure,
                  letterSpacing: 0.02,
                ),
              ),
            )
          : null,
    );
  }
}
