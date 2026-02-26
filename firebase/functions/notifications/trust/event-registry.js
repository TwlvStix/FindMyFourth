'use strict';

/**
 * Trust System Notification Event Registry
 *
 * Defines all 17 Trust System notification types, their configurations,
 * message templates, and priority mappings for the push notification router.
 *
 * Convention: event type values use snake_case to match existing types
 * (chat_message, game_created, game_alert).
 */

// ── Enums ────────────────────────────────────────────────────────────────────

const TrustEventType = Object.freeze({
  HOST_CHECKIN_DUE:       'host_checkin_due',
  PLAYER_RATE_DUE:        'player_rate_due',
  HOST_CHECKIN_FALLBACK:  'host_checkin_fallback',
  PLAYER_FALLBACK_CONFIRM:'player_fallback_confirm',
  NO_SHOW_FLAGGED:        'no_show_flagged',
  DISPUTE_RESOLVED:       'dispute_resolved',
  STRIKE_ISSUED:          'strike_issued',
  COOLDOWN_STARTED:       'cooldown_started',
  RESTRICTION_STARTED:    'restriction_started',
  SUSPENSION_STARTED:     'suspension_started',
  RESTRICTION_ENDED:      'restriction_ended',
  BADGE_EARNED:           'badge_earned',
  BADGE_PROGRESS:         'badge_progress',
  GAME_SPOT_OPENED:       'game_spot_opened',
  GAME_CANCELLED:         'game_cancelled',
  FRIEND_REQUEST_RECEIVED:'friend_request_received',
  FRIEND_REQUEST_ACCEPTED:'friend_request_accepted',
});

const NotificationPriority = Object.freeze({
  CRITICAL: 'CRITICAL',
  HIGH:     'HIGH',
  DEFAULT:  'DEFAULT',
  LOW:      'LOW',
});

const TrustCategory = Object.freeze({
  POST_ROUND:   'post_round',
  TRUST_ALERTS: 'trust_alerts',
  BADGES:       'badges',
  GAMES:        'games',
  SOCIAL:       'social',
});

// ── Priority → FCM Delivery Config ───────────────────────────────────────────

/**
 * Maps a NotificationPriority to Android and APNs delivery parameters.
 *
 * Priority rules from spec:
 *   CRITICAL / HIGH → android "high",  apns "10"
 *   DEFAULT         → android "normal", apns "5"
 *   LOW             → android "normal", apns "1"
 *
 * iOS interruption levels:
 *   CRITICAL → "time-sensitive"
 *   HIGH     → "active"
 *   DEFAULT  → "active"
 *   LOW      → "passive"
 */
const PRIORITY_FCM_CONFIG = Object.freeze({
  [NotificationPriority.CRITICAL]: {
    androidPriority:    'high',
    apnsPriority:       '10',
    interruptionLevel:  'time-sensitive',
  },
  [NotificationPriority.HIGH]: {
    androidPriority:    'high',
    apnsPriority:       '10',
    interruptionLevel:  'active',
  },
  [NotificationPriority.DEFAULT]: {
    androidPriority:    'normal',
    apnsPriority:       '5',
    interruptionLevel:  'active',
  },
  [NotificationPriority.LOW]: {
    androidPriority:    'normal',
    apnsPriority:       '1',
    interruptionLevel:  'passive',
  },
});

// ── Event Registry ───────────────────────────────────────────────────────────

/**
 * Full configuration for every Trust System notification event type.
 *
 * Fields:
 *   priority        — NotificationPriority value
 *   category        — TrustCategory value; maps to the user-facing preference toggle
 *   maxDeliveries   — cap on how many times this event may be sent per trigger (1 or 2)
 *   timing          — "immediate" | "scheduled" (scheduled = dispatched via Cloud Tasks)
 *   template        — primary push notification copy
 *   reminderTemplate— optional second delivery copy (host_checkin_due only)
 *   deepLink        — app deep-link URI; {game_id} is interpolated by the router
 *   threadId        — iOS notification group identifier; {game_id} interpolated by router
 *   androidChannelId— one of: "critical" | "important" | "default" | "updates"
 *   icon            — Flutter icon name used by _iconForType() in NotificationsListWidget
 */
const EVENT_REGISTRY = Object.freeze({

  // ── Post-round ─────────────────────────────────────────────────────────────

  [TrustEventType.HOST_CHECKIN_DUE]: {
    priority:        NotificationPriority.HIGH,
    category:        TrustCategory.POST_ROUND,
    maxDeliveries:   2,
    timing:          'scheduled',
    template: {
      title: "How'd it go? \u26F3",
      body:  'Your round at {course_name} \u2014 let us know who showed up. Takes 10 seconds.',
    },
    reminderTemplate: {
      title: 'Quick check-in needed',
      body:  'Tap to confirm attendance for your {course_name} round. Window closes in {hours_remaining}h.',
    },
    deepLink:         'findmyfourth://checkin/{game_id}',
    threadId:         'post_round_{game_id}',
    androidChannelId: 'important',
    icon:             'fact_check',
  },

  [TrustEventType.PLAYER_RATE_DUE]: {
    priority:        NotificationPriority.DEFAULT,
    category:        TrustCategory.POST_ROUND,
    maxDeliveries:   1,
    timing:          'scheduled',
    template: {
      title: 'Rate your round \u26F3',
      body:  'Would you play with your group at {course_name} again? One tap per player.',
    },
    deepLink:         'findmyfourth://rate/{game_id}',
    threadId:         'post_round_{game_id}',
    androidChannelId: 'default',
    icon:             'fact_check',
  },

  [TrustEventType.HOST_CHECKIN_FALLBACK]: {
    priority:        NotificationPriority.HIGH,
    category:        TrustCategory.POST_ROUND,
    maxDeliveries:   1,
    timing:          'scheduled',
    template: {
      title: 'Did you play today?',
      body:  "Your host hasn't checked in yet for {course_name}. Tap to confirm you played.",
    },
    deepLink:         'findmyfourth://fallback/{game_id}',
    threadId:         'post_round_{game_id}',
    androidChannelId: 'important',
    icon:             'fact_check',
  },

  [TrustEventType.PLAYER_FALLBACK_CONFIRM]: {
    priority:        NotificationPriority.DEFAULT,
    category:        TrustCategory.POST_ROUND,
    maxDeliveries:   1,
    timing:          'scheduled',
    template: {
      title: 'Did you play today?',
      body:  "We're confirming attendance for {course_name} on {date}. Did you play?",
    },
    deepLink:         'findmyfourth://fallback/{game_id}',
    threadId:         'post_round_{game_id}',
    androidChannelId: 'default',
    icon:             'fact_check',
  },

  // ── Trust & enforcement ────────────────────────────────────────────────────

  [TrustEventType.NO_SHOW_FLAGGED]: {
    priority:        NotificationPriority.HIGH,
    category:        TrustCategory.TRUST_ALERTS,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: 'Attendance question',
      body:  'The host marked you as not attending {course_name} on {date}. Other players have 48h to confirm. No action needed from you.',
    },
    deepLink:         'findmyfourth://trust/standing',
    threadId:         'trust_alerts',
    androidChannelId: 'important',
    icon:             'warning_amber',
  },

  [TrustEventType.DISPUTE_RESOLVED]: {
    priority:        NotificationPriority.DEFAULT,
    category:        TrustCategory.TRUST_ALERTS,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: "You're all good \u2705",
      body:  'Another player confirmed you attended {course_name} on {date}. The no-show flag has been removed automatically.',
    },
    deepLink:         'findmyfourth://trust/standing',
    threadId:         'trust_alerts',
    androidChannelId: 'default',
    icon:             'check_circle_outline',
  },

  [TrustEventType.STRIKE_ISSUED]: {
    priority:        NotificationPriority.CRITICAL,
    category:        TrustCategory.TRUST_ALERTS,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: 'Reliability notice',
      body:  'A strike has been added to your account for {reason}. View your standing in Settings to see details and expiry date.',
    },
    deepLink:         'findmyfourth://trust/standing',
    threadId:         'trust_alerts',
    androidChannelId: 'critical',
    icon:             'warning_amber',
  },

  [TrustEventType.COOLDOWN_STARTED]: {
    priority:        NotificationPriority.HIGH,
    category:        TrustCategory.TRUST_ALERTS,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: '24-hour cooldown',
      body:  'Due to 2 active strikes, you have a 24-hour cooldown before joining new games. You can still view and chat.',
    },
    deepLink:         'findmyfourth://trust/standing',
    threadId:         'trust_alerts',
    androidChannelId: 'important',
    icon:             'warning_amber',
  },

  [TrustEventType.RESTRICTION_STARTED]: {
    priority:        NotificationPriority.CRITICAL,
    category:        TrustCategory.TRUST_ALERTS,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: 'Account restricted',
      body:  'Your account is restricted for {duration}. You cannot join or create games during this period. View details in Settings.',
    },
    deepLink:         'findmyfourth://trust/standing',
    threadId:         'trust_alerts',
    androidChannelId: 'critical',
    icon:             'warning_amber',
  },

  [TrustEventType.SUSPENSION_STARTED]: {
    priority:        NotificationPriority.CRITICAL,
    category:        TrustCategory.TRUST_ALERTS,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: 'Account suspended',
      body:  "Your account has been suspended pending review. You'll receive an update within 5 business days.",
    },
    deepLink:         'findmyfourth://trust/standing',
    threadId:         'trust_alerts',
    androidChannelId: 'critical',
    icon:             'warning_amber',
  },

  [TrustEventType.RESTRICTION_ENDED]: {
    priority:        NotificationPriority.DEFAULT,
    category:        TrustCategory.TRUST_ALERTS,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: 'Welcome back \u26F3',
      body:  'Your restriction has been lifted. Your next 5 rounds will rebuild your standing. Show up and your strike history will start to fade.',
    },
    deepLink:         'findmyfourth://trust/standing',
    threadId:         'trust_alerts',
    androidChannelId: 'default',
    icon:             'check_circle_outline',
  },

  // ── Badges ─────────────────────────────────────────────────────────────────

  [TrustEventType.BADGE_EARNED]: {
    priority:        NotificationPriority.HIGH,
    category:        TrustCategory.BADGES,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: 'New badge earned! \uD83C\uDFC6',
      body:  "You've reached {badge_name} status. {rounds_count} verified rounds with {unique_players} different players.",
    },
    deepLink:         'findmyfourth://badges',
    threadId:         'badges',
    androidChannelId: 'important',
    icon:             'emoji_events',
  },

  [TrustEventType.BADGE_PROGRESS]: {
    priority:        NotificationPriority.LOW,
    category:        TrustCategory.BADGES,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: 'Almost there',
      body:  "You're {rounds_remaining} rounds away from {next_badge_name}. Keep showing up!",
    },
    deepLink:         'findmyfourth://badges',
    threadId:         'badges',
    androidChannelId: 'updates',
    icon:             'emoji_events',
  },

  // ── Games ──────────────────────────────────────────────────────────────────

  [TrustEventType.GAME_SPOT_OPENED]: {
    priority:        NotificationPriority.HIGH,
    category:        TrustCategory.GAMES,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: 'Spot opened \u26F3',
      body:  'A spot just opened in a {game_date} game at {course_name}. {spots_remaining} spot(s) left.',
    },
    deepLink:         'findmyfourth://game/{game_id}',
    threadId:         'game_{game_id}',
    androidChannelId: 'important',
    icon:             'sports_golf',
  },

  [TrustEventType.GAME_CANCELLED]: {
    priority:        NotificationPriority.HIGH,
    category:        TrustCategory.GAMES,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: 'Game cancelled',
      body:  'The {game_date} game at {course_name} has been cancelled by the host.',
    },
    deepLink:         'findmyfourth://game/{game_id}',
    threadId:         'game_{game_id}',
    androidChannelId: 'important',
    icon:             'sports_golf',
  },

  // ── Social ────────────────────────────────────────────────────────────────

  [TrustEventType.FRIEND_REQUEST_RECEIVED]: {
    priority:        NotificationPriority.DEFAULT,
    category:        TrustCategory.SOCIAL,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: 'New friend request',
      body:  '{sender_name} wants to connect with you.',
    },
    deepLink:         'findmyfourth://golfers/requests',
    threadId:         'social',
    androidChannelId: 'default',
    icon:             'person_add',
  },

  [TrustEventType.FRIEND_REQUEST_ACCEPTED]: {
    priority:        NotificationPriority.DEFAULT,
    category:        TrustCategory.SOCIAL,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: 'Friend request accepted',
      body:  '{acceptor_name} is now connected with you.',
    },
    deepLink:         'findmyfourth://golfers/friends',
    threadId:         'social',
    androidChannelId: 'default',
    icon:             'check_circle',
  },
});

// ── Public API ───────────────────────────────────────────────────────────────

/**
 * Returns the full configuration for a given Trust event type.
 *
 * @param {string} eventType - A TrustEventType value
 * @returns {object} EventConfig
 * @throws {Error} if eventType is not registered
 */
function getEventConfig(eventType) {
  const config = EVENT_REGISTRY[eventType];
  if (!config) {
    throw new Error(`Unknown Trust event type: "${eventType}"`);
  }
  return config;
}

/**
 * Returns the FCM delivery parameters for a given priority level.
 *
 * @param {string} priority - A NotificationPriority value
 * @returns {{androidPriority: string, apnsPriority: string, interruptionLevel: string}}
 * @throws {Error} if priority is not recognised
 */
function getPriorityConfig(priority) {
  const config = PRIORITY_FCM_CONFIG[priority];
  if (!config) {
    throw new Error(`Unknown notification priority: "${priority}"`);
  }
  return config;
}

/**
 * Interpolates {variable} placeholders in a notification template.
 *
 * Replaces every occurrence of `{key}` in the template's title and body with
 * the corresponding value from `data`. After substitution, any placeholder that
 * was not resolved (because the key was absent from `data`) is treated as a
 * missing required variable and causes an error to be thrown.
 *
 * @param {string} eventType  - A TrustEventType value
 * @param {Record<string, string|number>} data - Variable values keyed by placeholder name
 * @param {boolean} [isReminder=false] - If true, uses reminderTemplate instead of template
 * @returns {{title: string, body: string}} Rendered notification copy
 * @throws {Error} if the requested template variant does not exist for this event type
 * @throws {Error} if any required placeholder variables are absent from data
 */
function renderTemplate(eventType, data, isReminder = false) {
  const config = getEventConfig(eventType);
  const template = isReminder ? config.reminderTemplate : config.template;

  if (!template) {
    throw new Error(
      `No ${isReminder ? 'reminder ' : ''}template defined for event type: "${eventType}"`,
    );
  }

  const interpolate = (str) =>
    str.replace(/\{(\w+)\}/g, (match, key) => {
      const value = data[key];
      return value !== undefined && value !== null ? String(value) : match;
    });

  const title = interpolate(template.title);
  const body  = interpolate(template.body);

  const remaining = [
    ...[...title.matchAll(/\{(\w+)\}/g)].map((m) => m[1]),
    ...[...body.matchAll(/\{(\w+)\}/g)].map((m) => m[1]),
  ];
  const missing = [...new Set(remaining)];

  if (missing.length > 0) {
    throw new Error(
      `Missing required template variables for "${eventType}": ${missing.join(', ')}`,
    );
  }

  return { title, body };
}

module.exports = {
  TrustEventType,
  NotificationPriority,
  TrustCategory,
  PRIORITY_FCM_CONFIG,
  getEventConfig,
  getPriorityConfig,
  renderTemplate,
};
