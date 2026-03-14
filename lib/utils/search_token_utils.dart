/// Generates search tokens (substrings) for substring-based user search.
///
/// Given a display name and optional first/last names, produces all substrings
/// of length >= [minLength] for each word. These tokens are stored in Firestore
/// and queried via `array-contains` for substring matching.
class SearchTokenUtils {
  SearchTokenUtils._();

  /// Generates deduplicated, sorted search tokens from name fields.
  ///
  /// Example: "jshew" → ["ew", "he", "hew", "js", "jsh", "jshe", "jshew", "sh", "she", "shew"]
  static List<String> generateSearchTokens(
    String displayName, {
    String? firstName,
    String? lastName,
    int minLength = 2,
  }) {
    final words = <String>{};

    for (final input in [displayName, firstName, lastName]) {
      if (input == null || input.isEmpty) continue;
      for (final word in input.toLowerCase().split(RegExp(r'\s+'))) {
        final trimmed = word.trim();
        if (trimmed.isNotEmpty) words.add(trimmed);
      }
    }

    final tokens = <String>{};
    for (final word in words) {
      for (var start = 0; start < word.length; start++) {
        for (var end = start + minLength; end <= word.length; end++) {
          tokens.add(word.substring(start, end));
        }
      }
    }

    return tokens.toList()..sort();
  }
}
