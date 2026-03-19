'use strict';

/**
 * Chat Content Moderation — Word Filter
 *
 * Provides a simple profanity/slur filter for chat messages.
 * Uses a static blocklist with leetspeak normalization and whole-word matching.
 *
 * Public API:
 *   filterMessage(text) → { flagged: boolean, reason: string | null }
 */

// ── Leetspeak normalization ──────────────────────────────────────────────────

const LEET_MAP = {
  '@': 'a',
  '0': 'o',
  '1': 'i',
  '3': 'e',
  '$': 's',
  '5': 's',
  '7': 't',
  '4': 'a',
  '+': 't',
};

function normalizeLeetspeak(text) {
  let result = text.toLowerCase();
  for (const [char, replacement] of Object.entries(LEET_MAP)) {
    // Escape special regex characters
    const escaped = char.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    result = result.replace(new RegExp(escaped, 'g'), replacement);
  }
  return result;
}

// ── Blocked words ────────────────────────────────────────────────────────────

const BLOCKED_WORDS = new Set([
  // Profanity
  'fuck', 'fack', 'fucker', 'fuckers', 'fucking', 'fucked', 'fucks',
  'motherfucker', 'motherfuckers', 'motherfucking',
  'shit', 'shits', 'shitty', 'shitting', 'bullshit', 'horseshit',
  'ass', 'asshole', 'assholes', 'asses', 'arsehole', 'arseholes',
  'bitch', 'bitches', 'bitchy', 'bitching',
  'damn', 'damned', 'dammit', 'goddamn', 'goddamnit',
  'hell', 'hellhole',
  'crap', 'crappy',
  'dick', 'dicks', 'dickhead', 'dickheads',
  'cock', 'cocks', 'cocksucker', 'cocksuckers',
  'cunt', 'cunts',
  'bastard', 'bastards',
  'piss', 'pissed', 'pissing',
  'whore', 'whores',
  'slut', 'sluts', 'slutty',
  'twat', 'twats',
  'wanker', 'wankers',
  'tosser', 'tossers',
  'bollocks',
  'bugger', 'buggers',
  'prick', 'pricks',
  'douche', 'douchebag', 'douchebags',
  'jackass', 'jackasses',

  // Slurs and hate speech
  'nigger', 'niggers', 'nigga', 'niggas',
  'faggot', 'faggots', 'fag', 'fags',
  'dyke', 'dykes',
  'tranny', 'trannies',
  'retard', 'retards', 'retarded',
  'spic', 'spics',
  'wetback', 'wetbacks',
  'kike', 'kikes',
  'chink', 'chinks',
  'gook', 'gooks',
  'beaner', 'beaners',
  'coon', 'coons',
  'darkie', 'darkies',
  'honky', 'honkies',
  'cracker', 'crackers',
  'redneck', 'rednecks',
  'zipperhead', 'zipperheads',
  'raghead', 'ragheads',
  'towelhead', 'towelheads',
  'camel jockey',
  'sandnigger', 'sandniggers',
  'spook', 'spooks',
  'jigaboo', 'jigaboos',
  'porchmonkey',
  'sambo',

  // Sexual / explicit
  'blowjob', 'blowjobs',
  'handjob', 'handjobs',
  'dildo', 'dildos',
  'jerkoff',
  'cumshot',
  'cum', 'cumming',
  'orgasm', 'orgasms',
  'masturbate', 'masturbating', 'masturbation',
  'pussy', 'pussies',
  'vagina', 'vaginas',
  'penis', 'penises',
  'boobs', 'boobies',
  'tits', 'titties',
  'anal',
  'anus',
  'fellatio',
  'cunnilingus',
  'ejaculate', 'ejaculation',
  'erection',
  'horny',
  'milf',
  'pornography', 'porn', 'porno',

  // Threats / violence
  'killyourself',
  'killyoself',

  // Compound slurs
  'shithead', 'shitheads',
  'fuckface', 'fuckfaces',
  'asswipe', 'asswipes',
  'dipshit', 'dipshits',
  'nutjob',
  'scumbag', 'scumbags',
]);

// ── Public API ───────────────────────────────────────────────────────────────

/**
 * Checks a message for blocked words.
 *
 * @param {string} text - The message text to check
 * @returns {{ flagged: boolean, reason: string | null }}
 */
function filterMessage(text) {
  if (typeof text !== 'string' || text.length === 0) {
    return { flagged: false, reason: null };
  }

  const normalized = normalizeLeetspeak(text);
  const words = normalized.split(/[^a-z]+/).filter(Boolean);

  for (const word of words) {
    if (BLOCKED_WORDS.has(word)) {
      return { flagged: true, reason: 'profanity' };
    }
  }

  return { flagged: false, reason: null };
}

module.exports = { filterMessage, normalizeLeetspeak, BLOCKED_WORDS };
