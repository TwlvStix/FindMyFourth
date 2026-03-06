import 'package:flutter/material.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/typography.dart';
import '../design_tokens/border_radius.dart';

/// Data class representing a member in the group avatar.
class GroupAvatarMember {
  const GroupAvatarMember({
    required this.name,
    this.photoUrl,
  });

  final String name;
  final String? photoUrl;
}

/// Avatar widget for chat list cards displaying 1-4 members.
///
/// Layouts:
/// - 1 member: Full rounded square with centered initials
/// - 2 members: Vertical split (left|right)
/// - 3 members: Left half full height, right half split top/bottom
/// - 4 members: 2x2 grid
///
/// Uses design tokens exclusively - no hardcoded colors, sizes, or radii.
class ChatGroupAvatar extends StatelessWidget {
  const ChatGroupAvatar({
    super.key,
    required this.members,
    this.size = 50,
  });

  /// List of members to display (1-4 members supported).
  final List<GroupAvatarMember> members;

  /// Total dimension of the avatar (width and height).
  final double size;

  /// Avatar background color palette from design tokens.
  /// These colors are chosen to have good contrast with white text.
  static const List<Color> _avatarColors = [
    AppColors.greenDark,
    AppColors.gold,
    AppColors.info,
    AppColors.green,
    AppColors.goldDark,
    AppColors.greenLight,
    AppColors.navyLight,
    AppColors.navy,
  ];

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return _buildEmptyAvatar();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppBorderRadius.card),
      child: SizedBox(
        width: size,
        height: size,
        child: _buildLayout(),
      ),
    );
  }

  Widget _buildLayout() {
    // Get unique colors for each member position
    final colors = _getUniqueColors(members.length);
    final memberCount = members.length.clamp(1, 4);

    switch (memberCount) {
      case 1:
        return _buildSingleMember(members[0], colors[0]);
      case 2:
        return _buildTwoMembers(colors);
      case 3:
        return _buildThreeMembers(colors);
      default:
        return _buildFourMembers(colors);
    }
  }

  /// Generate unique colors for each position, ensuring no adjacent colors match.
  List<Color> _getUniqueColors(int count) {
    if (count == 0) return [];
    if (count == 1) {
      return [colorFromName(members[0].name)];
    }

    final colors = <Color>[];
    final usedIndices = <int>{};

    for (int i = 0; i < count && i < 4; i++) {
      final baseIndex = members[i].name.hashCode.abs() % _avatarColors.length;

      // Find a color that hasn't been used yet
      var colorIndex = baseIndex;
      var attempts = 0;
      while (usedIndices.contains(colorIndex) &&
          attempts < _avatarColors.length) {
        colorIndex = (colorIndex + 1) % _avatarColors.length;
        attempts++;
      }

      usedIndices.add(colorIndex);
      colors.add(_avatarColors[colorIndex]);
    }

    return colors;
  }

  /// Single member: full square with centered initials.
  Widget _buildSingleMember(GroupAvatarMember member, Color color) {
    return _MemberSegment(
      member: member,
      color: color,
      useSmallText: false,
    );
  }

  /// Two members: vertical split (left|right).
  Widget _buildTwoMembers(List<Color> colors) {
    return Row(
      children: [
        Expanded(
          child: _MemberSegment(
            member: members[0],
            color: colors[0],
            useSmallText: false,
          ),
        ),
        const SizedBox(width: 1),
        Expanded(
          child: _MemberSegment(
            member: members[1],
            color: colors[1],
            useSmallText: false,
          ),
        ),
      ],
    );
  }

  /// Three members: left half full height, right half split top/bottom.
  Widget _buildThreeMembers(List<Color> colors) {
    return Row(
      children: [
        Expanded(
          child: _MemberSegment(
            member: members[0],
            color: colors[0],
            useSmallText: false,
          ),
        ),
        const SizedBox(width: 1),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: _MemberSegment(
                  member: members[1],
                  color: colors[1],
                  useSmallText: true,
                ),
              ),
              const SizedBox(height: 1),
              Expanded(
                child: _MemberSegment(
                  member: members[2],
                  color: colors[2],
                  useSmallText: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Four members: 2x2 grid.
  Widget _buildFourMembers(List<Color> colors) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _MemberSegment(
                  member: members[0],
                  color: colors[0],
                  useSmallText: true,
                ),
              ),
              const SizedBox(width: 1),
              Expanded(
                child: _MemberSegment(
                  member: members[1],
                  color: colors[1],
                  useSmallText: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 1),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _MemberSegment(
                  member: members[2],
                  color: colors[2],
                  useSmallText: true,
                ),
              ),
              const SizedBox(width: 1),
              Expanded(
                child: _MemberSegment(
                  member: members[3],
                  color: colors[3],
                  useSmallText: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
      ),
    );
  }

  /// Get background color for a name using hash.
  static Color colorFromName(String name) {
    if (name.isEmpty) return _avatarColors[0];
    final index = name.hashCode.abs() % _avatarColors.length;
    return _avatarColors[index];
  }

  /// Get initials from a name.
  /// - Single word: first letter
  /// - Multiple words: first letter of first and second word
  static String getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '';
  }
}

/// Internal widget for a single member segment within the avatar.
class _MemberSegment extends StatelessWidget {
  const _MemberSegment({
    required this.member,
    required this.color,
    required this.useSmallText,
  });

  final GroupAvatarMember member;
  final Color color;
  final bool useSmallText;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = member.photoUrl != null && member.photoUrl!.isNotEmpty;

    if (hasPhoto) {
      // Show profile photo with initials fallback on error
      return SizedBox.expand(
        child: Image.network(
          member.photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialsFallback(),
        ),
      );
    }

    // No photo - show initials + color
    return _buildInitialsFallback();
  }

  Widget _buildInitialsFallback() {
    final initials = ChatGroupAvatar.getInitials(member.name);
    final textStyle = useSmallText
        ? AppTypography.labelSmall
        : AppTypography.labelMedium;

    return SizedBox.expand(
      child: ColoredBox(
        color: color,
        child: Center(
          child: Text(
            initials,
            style: textStyle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
