import '/models/game.dart';

/// Stakes level for color-coded visual treatment.
enum StakesLevel {
  /// No money involved - muted appearance
  noMoney,
  /// Low stakes - warm gold tone
  lowStakes,
  /// High stakes - hot red/orange tone
  highStakes,
}

/// Represents a tag to display in Row 3 of flexible game cards.
class GameTag {
  const GameTag({
    required this.label,
    this.stakesLevel,
    this.isFormatFallback = false,
  });

  /// Display label for the tag (e.g., "LOW STAKES", "Stroke Play")
  final String label;

  /// Stakes level for color-coded styling. Null if not a stakes tag.
  final StakesLevel? stakesLevel;

  /// True if this tag is a format fallback (shown only when no stakes data)
  final bool isFormatFallback;

  /// Whether this tag represents stakes (as opposed to format)
  bool get isStakesTag => stakesLevel != null;
}

/// Returns tags for Row 3 of flexible game cards.
///
/// Priority:
/// 1. Stakes tag (if stakes data exists)
/// 2. Format tag as fallback (if no stakes data)
///
/// The returned list will have at most one tag currently (stakes or format).
/// When side games are added to the data model, this can be extended.
List<GameTag> getRow3Tags(Game game) {
  return getRow3TagsFromRaw(
    styleGame: game.styleGame,
    gameType: game.gameType,
  );
}

/// Lower-level function for testing and reuse.
List<GameTag> getRow3TagsFromRaw({
  required String styleGame,
  required String gameType,
}) {
  final tags = <GameTag>[];

  // Try to get stakes tag
  final stakesTag = _parseStakesTag(styleGame);
  if (stakesTag != null) {
    tags.add(stakesTag);
    return tags;
  }

  // Fallback to format tag if no stakes
  final formatTag = _parseFormatTag(gameType);
  if (formatTag != null) {
    tags.add(formatTag);
  }

  return tags;
}

/// Parse stakes from styleGame field.
GameTag? _parseStakesTag(String styleGame) {
  final value = styleGame.trim().toLowerCase();
  if (value.isEmpty) return null;

  switch (value) {
    case 'no money':
    case 'nomoney':
      return const GameTag(
        label: 'NO MONEY',
        stakesLevel: StakesLevel.noMoney,
      );
    case 'low stakes':
    case 'lowstakes':
      return const GameTag(
        label: 'LOW STAKES',
        stakesLevel: StakesLevel.lowStakes,
      );
    case 'high stakes':
    case 'highstakes':
    case 'money game':
      return const GameTag(
        label: 'HIGH STAKES',
        stakesLevel: StakesLevel.highStakes,
      );
    default:
      return null;
  }
}

/// Parse format from gameType field.
GameTag? _parseFormatTag(String gameType) {
  final value = gameType.trim().toLowerCase();
  if (value.isEmpty) return null;

  final label = _formatGameType(value);
  return GameTag(
    label: label.toUpperCase(),
    isFormatFallback: true,
  );
}

/// Format game type to display label.
String _formatGameType(String gameType) {
  switch (gameType.toLowerCase()) {
    case 'stroke':
      return 'Stroke Play';
    case 'match_play':
      return 'Match Play';
    case 'stableford':
      return 'Stableford';
    case 'scramble':
      return 'Scramble';
    case 'best_ball':
      return 'Best Ball';
    case 'skins':
      return 'Skins';
    default:
      return gameType;
  }
}
