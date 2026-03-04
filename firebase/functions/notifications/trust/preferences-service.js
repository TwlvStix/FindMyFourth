'use strict';

/**
 * Trust System Notification Preferences Service
 *
 * Reads user notification preferences from the `notification_prefs` field on
 * the user document — the same field the Flutter client reads and writes.
 *
 * This service is READ-ONLY on the backend. All preference writes are owned
 * by the client via the NotificationPageWidget settings screen.
 *
 * Firestore path: users/{userId}.notification_prefs
 *
 * Field names in Firestore use snake_case (matching NotificationPreferences.toFirestore()):
 *   push_enabled, quiet_hours, trust_categories
 *   trust_categories.post_round, trust_categories.trust_alerts, trust_categories.badges
 */

const admin = require('firebase-admin');

/**
 * Retrieves and normalises notification preferences for a user.
 *
 * All fields default gracefully when absent so the router can safely call this
 * for any user, including those created before Trust System preferences existed.
 *
 * @param {string} userId
 * @returns {Promise<{
 *   pushEnabled: boolean,
 *   trustCategories: { postRound: boolean, trustAlerts: boolean, badges: boolean },
 *   quietHours: { enabled: boolean, start: string, end: string }
 * }>}
 */
async function getUserPreferences(userId) {
  const doc = await admin.firestore().collection('users').doc(userId).get();

  const raw = doc.exists ? doc.data() : {};
  const prefs = (raw.notification_prefs && typeof raw.notification_prefs === 'object')
    ? raw.notification_prefs
    : {};

  const tc = (prefs.trust_categories && typeof prefs.trust_categories === 'object')
    ? prefs.trust_categories
    : {};

  const qh = (prefs.quiet_hours && typeof prefs.quiet_hours === 'object')
    ? prefs.quiet_hours
    : {};

  return {
    pushEnabled: typeof prefs.push_enabled === 'boolean' ? prefs.push_enabled : true,
    trustCategories: {
      postRound:      typeof tc.post_round      === 'boolean' ? tc.post_round      : true,
      trustAlerts:    typeof tc.trust_alerts    === 'boolean' ? tc.trust_alerts    : true,
      badges:         typeof tc.badges          === 'boolean' ? tc.badges          : true,
      weeklyActivity: typeof tc.weekly_activity === 'boolean' ? tc.weekly_activity : true,
    },
    quietHours: {
      enabled: typeof qh.enabled === 'boolean' ? qh.enabled : false,
      start:   typeof qh.start   === 'string'  ? qh.start   : '22:00',
      end:     typeof qh.end     === 'string'  ? qh.end     : '07:00',
    },
  };
}

module.exports = { getUserPreferences };
