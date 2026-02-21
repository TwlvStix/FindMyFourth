'use strict';

/**
 * Trust System Preferences Service — Unit Tests
 *
 * Verifies that getUserPreferences() correctly reads and defaults
 * notification_prefs from the user document.
 *
 * Run: npx jest test/preferences-service.test.js
 */

// ── Mock firebase-admin BEFORE requiring the module under test ────────────────

let mockDocData = null;
let mockDocExists = true;

jest.mock('firebase-admin', () => ({
  firestore: () => ({
    collection: () => ({
      doc: () => ({
        get: async () => ({
          exists: mockDocExists,
          data: () => mockDocData,
        }),
      }),
    }),
  }),
}));

const { getUserPreferences } = require('../notifications/trust/preferences-service');

// ── Helpers ───────────────────────────────────────────────────────────────────

function setUserDoc(notificationPrefs) {
  mockDocExists = true;
  mockDocData = notificationPrefs !== undefined
    ? { notification_prefs: notificationPrefs }
    : {};
}

function setUserDocMissing() {
  mockDocExists = false;
  mockDocData = null;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe('getUserPreferences', () => {

  // ── Defaults when data is absent ─────────────────────────────────────────

  test('user doc missing entirely → all-true defaults, quietHours disabled', async () => {
    setUserDocMissing();
    const prefs = await getUserPreferences('user123');
    expect(prefs.pushEnabled).toBe(true);
    expect(prefs.trustCategories.postRound).toBe(true);
    expect(prefs.trustCategories.trustAlerts).toBe(true);
    expect(prefs.trustCategories.badges).toBe(true);
    expect(prefs.quietHours.enabled).toBe(false);
    expect(prefs.quietHours.start).toBe('22:00');
    expect(prefs.quietHours.end).toBe('07:00');
  });

  test('notification_prefs field absent from user doc → all-true defaults', async () => {
    mockDocExists = true;
    mockDocData = { display_name: 'Golfer' }; // no notification_prefs key
    const prefs = await getUserPreferences('user123');
    expect(prefs.pushEnabled).toBe(true);
    expect(prefs.trustCategories.postRound).toBe(true);
    expect(prefs.trustCategories.trustAlerts).toBe(true);
    expect(prefs.trustCategories.badges).toBe(true);
  });

  test('notification_prefs is null → all-true defaults', async () => {
    setUserDoc(null);
    const prefs = await getUserPreferences('user123');
    expect(prefs.pushEnabled).toBe(true);
    expect(prefs.trustCategories.postRound).toBe(true);
  });

  test('trust_categories field absent from existing prefs → all-true defaults', async () => {
    setUserDoc({
      push_enabled: true,
      // no trust_categories key
    });
    const prefs = await getUserPreferences('user123');
    expect(prefs.trustCategories.postRound).toBe(true);
    expect(prefs.trustCategories.trustAlerts).toBe(true);
    expect(prefs.trustCategories.badges).toBe(true);
  });

  // ── Correct parsing when data is present ─────────────────────────────────

  test('push_enabled: false is returned correctly', async () => {
    setUserDoc({ push_enabled: false });
    const prefs = await getUserPreferences('user123');
    expect(prefs.pushEnabled).toBe(false);
  });

  test('push_enabled: true is returned correctly', async () => {
    setUserDoc({ push_enabled: true });
    const prefs = await getUserPreferences('user123');
    expect(prefs.pushEnabled).toBe(true);
  });

  test('individual trust category post_round: false parsed correctly', async () => {
    setUserDoc({
      push_enabled: true,
      trust_categories: { post_round: false, trust_alerts: true, badges: true },
    });
    const prefs = await getUserPreferences('user123');
    expect(prefs.trustCategories.postRound).toBe(false);
    expect(prefs.trustCategories.trustAlerts).toBe(true);
    expect(prefs.trustCategories.badges).toBe(true);
  });

  test('individual trust category trust_alerts: false parsed correctly', async () => {
    setUserDoc({
      trust_categories: { post_round: true, trust_alerts: false, badges: true },
    });
    const prefs = await getUserPreferences('user123');
    expect(prefs.trustCategories.trustAlerts).toBe(false);
    expect(prefs.trustCategories.postRound).toBe(true);
    expect(prefs.trustCategories.badges).toBe(true);
  });

  test('individual trust category badges: false parsed correctly', async () => {
    setUserDoc({
      trust_categories: { post_round: true, trust_alerts: true, badges: false },
    });
    const prefs = await getUserPreferences('user123');
    expect(prefs.trustCategories.badges).toBe(false);
  });

  test('all trust categories disabled', async () => {
    setUserDoc({
      trust_categories: { post_round: false, trust_alerts: false, badges: false },
    });
    const prefs = await getUserPreferences('user123');
    expect(prefs.trustCategories.postRound).toBe(false);
    expect(prefs.trustCategories.trustAlerts).toBe(false);
    expect(prefs.trustCategories.badges).toBe(false);
  });

  test('quiet hours enabled with custom times parsed correctly', async () => {
    setUserDoc({
      quiet_hours: { enabled: true, start: '23:00', end: '06:30' },
    });
    const prefs = await getUserPreferences('user123');
    expect(prefs.quietHours.enabled).toBe(true);
    expect(prefs.quietHours.start).toBe('23:00');
    expect(prefs.quietHours.end).toBe('06:30');
  });

  test('quiet hours disabled with default times', async () => {
    setUserDoc({
      quiet_hours: { enabled: false, start: '22:00', end: '07:00' },
    });
    const prefs = await getUserPreferences('user123');
    expect(prefs.quietHours.enabled).toBe(false);
    expect(prefs.quietHours.start).toBe('22:00');
    expect(prefs.quietHours.end).toBe('07:00');
  });

  // ── Default fallbacks for non-boolean/non-string values ──────────────────

  test('push_enabled is null → defaults to true', async () => {
    setUserDoc({ push_enabled: null });
    const prefs = await getUserPreferences('user123');
    expect(prefs.pushEnabled).toBe(true);
  });

  test('push_enabled is a string → defaults to true', async () => {
    setUserDoc({ push_enabled: 'yes' });
    const prefs = await getUserPreferences('user123');
    expect(prefs.pushEnabled).toBe(true);
  });

  test('trust_categories is not an object → all-true defaults', async () => {
    setUserDoc({ trust_categories: 'enabled' });
    const prefs = await getUserPreferences('user123');
    expect(prefs.trustCategories.postRound).toBe(true);
    expect(prefs.trustCategories.trustAlerts).toBe(true);
    expect(prefs.trustCategories.badges).toBe(true);
  });

  test('trust_categories.post_round is not a boolean → defaults to true', async () => {
    setUserDoc({
      trust_categories: { post_round: 'yes', trust_alerts: true, badges: true },
    });
    const prefs = await getUserPreferences('user123');
    expect(prefs.trustCategories.postRound).toBe(true);
  });

  test('quiet_hours is not an object → default times and disabled', async () => {
    setUserDoc({ quiet_hours: true });
    const prefs = await getUserPreferences('user123');
    expect(prefs.quietHours.enabled).toBe(false);
    expect(prefs.quietHours.start).toBe('22:00');
    expect(prefs.quietHours.end).toBe('07:00');
  });

  test('quiet_hours.start is not a string → defaults to 22:00', async () => {
    setUserDoc({
      quiet_hours: { enabled: true, start: 2200, end: '07:00' },
    });
    const prefs = await getUserPreferences('user123');
    expect(prefs.quietHours.start).toBe('22:00');
    expect(prefs.quietHours.end).toBe('07:00');
  });

  // ── Return shape ──────────────────────────────────────────────────────────

  test('returned object has exactly the expected top-level keys', async () => {
    setUserDoc({});
    const prefs = await getUserPreferences('user123');
    expect(Object.keys(prefs).sort()).toEqual(['pushEnabled', 'quietHours', 'trustCategories']);
  });

  test('trustCategories has exactly postRound, trustAlerts, badges', async () => {
    setUserDoc({});
    const prefs = await getUserPreferences('user123');
    expect(Object.keys(prefs.trustCategories).sort()).toEqual(['badges', 'postRound', 'trustAlerts']);
  });

  test('quietHours has exactly enabled, start, end', async () => {
    setUserDoc({});
    const prefs = await getUserPreferences('user123');
    expect(Object.keys(prefs.quietHours).sort()).toEqual(['enabled', 'end', 'start']);
  });

  // ── Full prefs round-trip ─────────────────────────────────────────────────

  test('full prefs document parsed correctly end-to-end', async () => {
    setUserDoc({
      push_enabled: true,
      game_alerts: { enabled: true },
      chat_alerts: { enabled: false },
      quiet_hours: { enabled: true, start: '21:30', end: '08:00' },
      digest_mode: 'hourly',
      muted_threads: ['thread1'],
      trust_categories: { post_round: true, trust_alerts: false, badges: true },
    });
    const prefs = await getUserPreferences('user123');
    expect(prefs.pushEnabled).toBe(true);
    expect(prefs.trustCategories.postRound).toBe(true);
    expect(prefs.trustCategories.trustAlerts).toBe(false);
    expect(prefs.trustCategories.badges).toBe(true);
    expect(prefs.quietHours.enabled).toBe(true);
    expect(prefs.quietHours.start).toBe('21:30');
    expect(prefs.quietHours.end).toBe('08:00');
  });
});
