'use strict';

const { filterMessage } = require('../moderation/word_filter');

describe('word_filter — filterMessage', () => {
  // ── Clean messages pass unflagged ──────────────────────────────────────────

  test('clean message returns unflagged', () => {
    const result = filterMessage('Hey, want to play 18 holes tomorrow?');
    expect(result).toEqual({ flagged: false, reason: null });
  });

  test('golf terminology is safe', () => {
    expect(filterMessage('Nice birdie on the par 5!')).toEqual({ flagged: false, reason: null });
    expect(filterMessage('I bogeyed the back nine')).toEqual({ flagged: false, reason: null });
    expect(filterMessage('Great drive off the tee')).toEqual({ flagged: false, reason: null });
  });

  // ── Exact profanity matches are caught ─────────────────────────────────────

  test('exact profanity match is flagged', () => {
    const result = filterMessage('what the fuck');
    expect(result).toEqual({ flagged: true, reason: 'profanity' });
  });

  test('slur is flagged', () => {
    const result = filterMessage('you are a faggot');
    expect(result).toEqual({ flagged: true, reason: 'profanity' });
  });

  test('profanity with punctuation is caught', () => {
    const result = filterMessage('holy shit!');
    expect(result).toEqual({ flagged: true, reason: 'profanity' });
  });

  // ── Case insensitivity ─────────────────────────────────────────────────────

  test('uppercase profanity is caught', () => {
    expect(filterMessage('FUCK this')).toEqual({ flagged: true, reason: 'profanity' });
  });

  test('mixed case profanity is caught', () => {
    expect(filterMessage('ShIt')).toEqual({ flagged: true, reason: 'profanity' });
  });

  // ── Leetspeak variants ─────────────────────────────────────────────────────

  test('leetspeak $h1t is caught', () => {
    expect(filterMessage('$h1t')).toEqual({ flagged: true, reason: 'profanity' });
  });

  test('leetspeak f@ck is caught', () => {
    expect(filterMessage('f@ck')).toEqual({ flagged: true, reason: 'profanity' });
  });

  test('leetspeak a$$ is caught', () => {
    expect(filterMessage('what an a$$')).toEqual({ flagged: true, reason: 'profanity' });
  });

  // ── Word boundary safety (no false positives) ─────────────────────────────

  test('"class" does NOT flag "ass"', () => {
    expect(filterMessage('I have a class at 3pm')).toEqual({ flagged: false, reason: null });
  });

  test('"Scunthorpe" is safe', () => {
    expect(filterMessage('I live in Scunthorpe')).toEqual({ flagged: false, reason: null });
  });

  test('"classic" does not flag "ass"', () => {
    expect(filterMessage('That was a classic shot')).toEqual({ flagged: false, reason: null });
  });

  test('"assistant" does not flag', () => {
    expect(filterMessage('The golf assistant was helpful')).toEqual({ flagged: false, reason: null });
  });

  test('"cockatoo" does not flag', () => {
    expect(filterMessage('I saw a cockatoo at the course')).toEqual({ flagged: false, reason: null });
  });

  test('"shitake" does not flag as whole word', () => {
    // "shitake" as one word won't split into "shit" — it stays as "shitake"
    expect(filterMessage('shitake mushrooms')).toEqual({ flagged: false, reason: null });
  });

  test('"therapist" does not flag', () => {
    expect(filterMessage('My therapist said I should golf more')).toEqual({ flagged: false, reason: null });
  });

  // ── Empty / null / edge cases ──────────────────────────────────────────────

  test('empty string returns unflagged', () => {
    expect(filterMessage('')).toEqual({ flagged: false, reason: null });
  });

  test('null input returns unflagged', () => {
    expect(filterMessage(null)).toEqual({ flagged: false, reason: null });
  });

  test('undefined input returns unflagged', () => {
    expect(filterMessage(undefined)).toEqual({ flagged: false, reason: null });
  });

  test('number input returns unflagged', () => {
    expect(filterMessage(42)).toEqual({ flagged: false, reason: null });
  });

  test('whitespace-only returns unflagged', () => {
    expect(filterMessage('   ')).toEqual({ flagged: false, reason: null });
  });

  // ── Does not echo the word ─────────────────────────────────────────────────

  test('reason is generic, does not echo the blocked word', () => {
    const result = filterMessage('fuck');
    expect(result.reason).toBe('profanity');
    expect(result.reason).not.toContain('fuck');
  });
});
