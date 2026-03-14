/**
 * Generates search tokens (substrings) for substring-based user search.
 *
 * Given a display name and optional first/last names, produces all substrings
 * of length >= minLength for each word. Tokens are stored in Firestore and
 * queried via `array-contains` for substring matching.
 *
 * @param {string} displayName
 * @param {string} [firstName]
 * @param {string} [lastName]
 * @param {number} [minLength=2]
 * @returns {string[]} Deduplicated, sorted tokens
 */
function generateSearchTokens(displayName, firstName, lastName, minLength = 2) {
  const words = new Set();

  for (const input of [displayName, firstName, lastName]) {
    if (!input) continue;
    for (const word of input.toLowerCase().split(/\s+/)) {
      const trimmed = word.trim();
      if (trimmed) words.add(trimmed);
    }
  }

  const tokens = new Set();
  for (const word of words) {
    for (let start = 0; start < word.length; start++) {
      for (let end = start + minLength; end <= word.length; end++) {
        tokens.add(word.substring(start, end));
      }
    }
  }

  return Array.from(tokens).sort();
}

module.exports = { generateSearchTokens };
