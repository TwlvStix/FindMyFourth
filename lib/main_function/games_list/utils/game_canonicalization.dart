import '/models/game.dart';

/// Normalizes game type strings to canonical display values.
///
/// Returns null for empty or unrecognized values.
String? canonicalGameType(String rawValue) {
  final value = rawValue.trim().toLowerCase();
  if (value.isEmpty) {
    return null;
  }
  switch (value) {
    case 'stroke':
    case 'stroke play':
      return 'Stroke Play';
    case 'match play':
    case 'matchplay':
      return 'Match Play';
    case 'stableford':
      return 'Stableford';
    default:
      return null;
  }
}

/// Normalizes vibe strings to canonical display values.
///
/// Returns null for empty or unrecognized values.
String? canonicalVibe(String rawValue) {
  final value = rawValue.trim().toLowerCase();
  if (value.isEmpty) {
    return null;
  }
  switch (value) {
    case 'competitive':
      return 'Competitive';
    case 'casual':
      return 'Casual';
    default:
      return null;
  }
}

/// Normalizes stakes strings to canonical display values.
///
/// Returns null for empty or unrecognized values.
String? canonicalStakes(String rawValue) {
  final value = rawValue.trim().toLowerCase();
  if (value.isEmpty) {
    return null;
  }
  switch (value) {
    case 'no money':
    case 'nomoney':
      return 'No Money';
    case 'low stakes':
    case 'lowstakes':
      return 'Low Stakes';
    case 'high stakes':
    case 'highstakes':
      return 'High Stakes';
    default:
      return null;
  }
}

/// Normalizes handicap/scoring strings to canonical display values.
///
/// Returns null for empty or unrecognized values.
String? canonicalHandicap(String rawValue) {
  final value = rawValue.trim().toLowerCase();
  if (value.isEmpty) {
    return null;
  }
  switch (value) {
    case 'gross':
      return 'Gross';
    case 'net':
      return 'Net';
    case 'both':
    case 'gross + net':
    case 'gross+net':
      return 'Both';
    default:
      return null;
  }
}

/// Extracts and canonicalizes the game type from a Game for filter matching.
String? gameTypeForFilters(Game game) {
  return canonicalGameType(game.gameType);
}

/// Extracts and canonicalizes the vibe from a Game for filter matching.
String? vibeForFilters(Game game) {
  return canonicalVibe(game.rulesSetting);
}

/// Extracts and canonicalizes the stakes from a Game for filter matching.
String? stakesForFilters(Game game) {
  return canonicalStakes(game.styleGame);
}

/// Extracts and canonicalizes the handicap from a Game for filter matching.
String? handicapForFilters(Game game) {
  return canonicalHandicap(game.scoring);
}
