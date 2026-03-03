import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/utils/vibe_archetypes.dart';

/// Centralized presentation metadata for vibe archetypes.
///
/// This class provides icons, colors, taglines, distribution percentages,
/// and compatibility data for the archetype reveal experience.
///
/// **Warden rule**: For compatibility lookups (bestWith, watchOutFor),
/// if [VibeArchetypeMatch.isWarden] is true and [VibeArchetypeMatch.baseArchetype]
/// is not null, resolve against the base archetype's name.
/// Identity data (icon, color, tagline, rarity) always uses the match's own name.
class VibeArchetypeMetadata {
  VibeArchetypeMetadata._();

  // ===========================================================================
  // ICON MAPPING
  // ===========================================================================

  /// Maps archetype names to their representative icons.
  static const Map<String, PhosphorIconData> archetypeIcons = {
    'The Grinder': AppPhosphorIcons.target,
    'The Shark': AppPhosphorIcons.lightning,
    'The Purist': AppPhosphorIcons.tree,
    'The Ghost': AppPhosphorIcons.eye,
    'The Tourist': AppPhosphorIcons.binoculars,
    'The Vibe King': AppPhosphorIcons.owner, // crown
    'The Juggernaut': AppPhosphorIcons.flame,
    'The Everyman': AppPhosphorIcons.handshake,
    'The Hustler': AppPhosphorIcons.highStakes, // coins
    'The DJ': AppPhosphorIcons.music, // musicNotes
    'The High Roller': AppPhosphorIcons.diamond,
    'The Mayor': AppPhosphorIcons.megaphone,
    'The Warden': AppPhosphorIcons.shield,
  };

  // ===========================================================================
  // COLOR MAPPING
  // ===========================================================================

  /// Maps archetype names to their accent colors for glow and divider.
  static const Map<String, Color> archetypeColors = {
    'The Grinder': Color(0xFFE05A3A), // Intense red-orange
    'The Shark': Color(0xFFE05A3A), // Intense red-orange
    'The Purist': Color(0xFF8BAAB5), // Cool slate blue
    'The Ghost': Color(0xFF7A8BA0), // Muted steel
    'The Tourist': Color(0xFF6BBF8A), // Fresh green
    'The Vibe King': Color(0xFFD4A017), // Rich gold
    'The Juggernaut': Color(0xFFE07B3A), // Bold orange
    'The Everyman': Color(0xFF6B8AFF), // Friendly blue
    'The Hustler': Color(0xFF4CAF50), // Money green
    'The DJ': Color(0xFFD4A017), // Gold (music)
    'The High Roller': Color(0xFFD4A017), // Gold (premium)
    'The Mayor': Color(0xFF6B8AFF), // Social blue
    'The Warden': Color(0xFFB0B0B0), // Neutral silver
  };

  // ===========================================================================
  // TAGLINES
  // ===========================================================================

  /// Short taglines that capture each archetype's essence.
  static const Map<String, String> archetypeTaglines = {
    'The Grinder': 'Relentless. Focused. Unforgiving.',
    'The Shark': 'Play hard. Talk loud. Win big.',
    'The Purist': 'Just me, the course, and silence.',
    'The Ghost': 'Quiet confidence, loud results.',
    'The Tourist': 'Every hole is a new adventure.',
    'The Vibe King': 'The party starts at the first tee.',
    'The Juggernaut': 'All gas, no brakes.',
    'The Everyman': 'Down for whatever.',
    'The Hustler': 'The math was done before the tee.',
    'The DJ': 'The playlist is as important as the clubs.',
    'The High Roller': 'Big stakes, bigger energy.',
    'The Mayor': 'I know everyone, everywhere.',
    'The Warden': 'My way or the highway.',
  };

  // ===========================================================================
  // DISTRIBUTION (RARITY)
  // ===========================================================================

  /// Estimated percentage of golfers in each archetype.
  /// Used to calculate rarity labels.
  static const Map<String, int> archetypeDistribution = {
    'The Grinder': 4, // LEGENDARY
    'The Shark': 6, // RARE
    'The Purist': 5, // RARE
    'The Ghost': 7, // RARE
    'The Tourist': 8, // RARE
    'The Vibe King': 5, // RARE
    'The Juggernaut': 3, // LEGENDARY
    'The Everyman': 25, // FAN FAVORITE
    'The Hustler': 6, // RARE
    'The DJ': 9, // RARE
    'The High Roller': 4, // LEGENDARY
    'The Mayor': 12, // UNCOMMON
    'The Warden': 6, // RARE
  };

  // ===========================================================================
  // COMPATIBILITY
  // ===========================================================================

  /// The two archetypes each archetype pairs best with.
  static const Map<String, List<String>> bestWith = {
    'The Grinder': ['The Shark', 'The Hustler'],
    'The Shark': ['The Grinder', 'The High Roller'],
    'The Purist': ['The Ghost', 'The Tourist'],
    'The Ghost': ['The Purist', 'The Grinder'],
    'The Tourist': ['The Purist', 'The DJ'],
    'The Vibe King': ['The DJ', 'The Mayor'],
    'The Juggernaut': ['The High Roller', 'The Shark'],
    'The Everyman': ['The Mayor', 'The DJ'],
    'The Hustler': ['The Grinder', 'The Shark'],
    'The DJ': ['The Vibe King', 'The Tourist'],
    'The High Roller': ['The Juggernaut', 'The Shark'],
    'The Mayor': ['The Everyman', 'The Vibe King'],
    'The Warden': ['The Everyman', 'The Purist'],
  };

  /// The archetype each archetype should watch out for (potential friction).
  static const Map<String, String> watchOutFor = {
    'The Grinder': 'The Vibe King',
    'The Shark': 'The Ghost',
    'The Purist': 'The Vibe King',
    'The Ghost': 'The Shark',
    'The Tourist': 'The Grinder',
    'The Vibe King': 'The Grinder',
    'The Juggernaut': 'The Ghost',
    'The Everyman': 'The Warden',
    'The Hustler': 'The Tourist',
    'The DJ': 'The Grinder',
    'The High Roller': 'The Tourist',
    'The Mayor': 'The Ghost',
    'The Warden': 'The Vibe King',
  };

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  /// Returns the icon for an archetype, falling back to handshake (Everyman).
  static PhosphorIconData iconFor(String archetypeName) {
    return archetypeIcons[archetypeName] ?? AppPhosphorIcons.handshake;
  }

  /// Returns the accent color for an archetype, falling back to gold.
  static Color colorFor(String archetypeName) {
    return archetypeColors[archetypeName] ?? AppColorsDark.gold;
  }

  /// Returns the tagline for an archetype, falling back to Everyman's tagline.
  static String taglineFor(String archetypeName) {
    return archetypeTaglines[archetypeName] ?? 'Down for whatever.';
  }

  /// Returns the estimated distribution percentage for an archetype.
  static int distributionFor(String archetypeName) {
    return archetypeDistribution[archetypeName] ?? 25;
  }

  /// Returns the rarity label for an archetype based on distribution.
  static String rarityFor(String archetypeName) {
    final percentage = distributionFor(archetypeName);
    return rarityLabel(percentage);
  }

  /// Converts a distribution percentage to a rarity label.
  ///
  /// - <5%: LEGENDARY
  /// - 5-9%: RARE
  /// - 10-19%: UNCOMMON
  /// - >=20%: FAN FAVORITE
  static String rarityLabel(int percentage) {
    if (percentage < 5) return 'LEGENDARY';
    if (percentage < 10) return 'RARE';
    if (percentage < 20) return 'UNCOMMON';
    return 'FAN FAVORITE';
  }

  /// Returns the two archetypes that pair best with the given archetype.
  ///
  /// For Warden matches, use [VibeArchetypeMatch.baseArchetype.name] if available.
  static List<String> bestWithFor(String archetypeName) {
    return bestWith[archetypeName] ?? ['The Mayor', 'The DJ'];
  }

  /// Returns the archetype to watch out for.
  ///
  /// For Warden matches, use [VibeArchetypeMatch.baseArchetype.name] if available.
  static String watchOutForName(String archetypeName) {
    return watchOutFor[archetypeName] ?? 'The Warden';
  }

  /// Resolves the compatibility lookup name for a match.
  ///
  /// If the match is a Warden with a base archetype, returns the base name.
  /// Otherwise, returns the match's own name.
  static String compatibilityNameFor(VibeArchetypeMatch match) {
    if (match.isWarden && match.baseArchetype != null) {
      return match.baseArchetype!.name;
    }
    return match.name;
  }
}
