import 'package:flutter/material.dart';

/// Vibe archetype accent colors.
///
/// These colors are used for visual representation of golf personality archetypes
/// in the vibe matching system. Each color reflects the personality traits and
/// energy of the archetype.
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     boxShadow: [
///       BoxShadow(
///         color: ArchetypeColors.grinder.withValues(alpha: 0.3),
///         blurRadius: 12,
///       ),
///     ],
///   ),
/// )
/// ```
class ArchetypeColors {
  ArchetypeColors._();

  // ===========================================================================
  // COMPETITIVE ARCHETYPES (Warm/intense tones)
  // ===========================================================================

  /// The Grinder - Intense red-orange (relentless energy)
  static const Color grinder = Color(0xFFE05A3A);

  /// The Shark - Intense red-orange (aggressive competitor)
  static const Color shark = Color(0xFFE05A3A);

  /// The Juggernaut - Bold orange (unstoppable force)
  static const Color juggernaut = Color(0xFFE07B3A);

  // ===========================================================================
  // PREMIUM/HIGH-STAKES ARCHETYPES (Gold tones)
  // ===========================================================================

  /// The Vibe King - Rich gold (party leader)
  static const Color vibeKing = Color(0xFFD4A017);

  /// The DJ - Rich gold (music & vibes)
  static const Color dj = Color(0xFFD4A017);

  /// The High Roller - Rich gold (premium player)
  static const Color highRoller = Color(0xFFD4A017);

  // ===========================================================================
  // SOCIAL ARCHETYPES (Blue tones)
  // ===========================================================================

  /// The Everyman - Friendly blue (easygoing)
  static const Color everyman = Color(0xFF6B8AFF);

  /// The Mayor - Social blue (connector)
  static const Color mayor = Color(0xFF6B8AFF);

  // ===========================================================================
  // RESERVED ARCHETYPES (Cool tones)
  // ===========================================================================

  /// The Purist - Cool slate blue (traditional)
  static const Color purist = Color(0xFF8BAAB5);

  /// The Ghost - Muted steel (quiet confidence)
  static const Color ghost = Color(0xFF7A8BA0);

  // ===========================================================================
  // NATURE/ADVENTURE ARCHETYPES (Green tones)
  // ===========================================================================

  /// The Tourist - Fresh green (adventure seeker)
  static const Color tourist = Color(0xFF6BBF8A);

  /// The Hustler - Money green (strategic player)
  static const Color hustler = Color(0xFF4CAF50);

  // ===========================================================================
  // NEUTRAL ARCHETYPES
  // ===========================================================================

  /// The Warden - Neutral silver (rule enforcer)
  static const Color warden = Color(0xFFB0B0B0);
}
