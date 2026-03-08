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
  HOST_CHECKIN_DUE:         'host_checkin_due',
  PLAYER_RATE_DUE:          'player_rate_due',
  HOST_CHECKIN_FALLBACK:    'host_checkin_fallback',
  PLAYER_FALLBACK_CONFIRM:  'player_fallback_confirm',
  NO_SHOW_FLAGGED:          'no_show_flagged',
  DISPUTE_RESOLVED:         'dispute_resolved',
  STRIKE_ISSUED:            'strike_issued',
  COOLDOWN_STARTED:         'cooldown_started',
  RESTRICTION_STARTED:      'restriction_started',
  SUSPENSION_STARTED:       'suspension_started',
  RESTRICTION_ENDED:        'restriction_ended',
  BADGE_EARNED:             'badge_earned',
  BADGE_PROGRESS:           'badge_progress',
  GAME_SPOT_OPENED:         'game_spot_opened',
  GAME_CANCELLED:           'game_cancelled',
  GAME_ALERT_DEFERRED:      'game_alert_deferred',
  FRIEND_REQUEST_RECEIVED:  'friend_request_received',
  FRIEND_REQUEST_ACCEPTED:  'friend_request_accepted',
  // Join request events (vibe floor)
  JOIN_REQUEST_NEW:         'join_request_new',
  JOIN_REQUEST_APPROVED:    'join_request_approved',
  JOIN_REQUEST_DECLINED:    'join_request_declined',
  JOIN_REQUEST_ROUND_FILLED:'join_request_round_filled',
  JOIN_REQUEST_EXPIRED:     'join_request_expired',
  // Weekly streak events
  STREAK_WEEKEND_NUDGE:     'streak_weekend_nudge',
  STREAK_FREEZE_UNLOCKED:   'streak_freeze_unlocked',
  STREAK_FREEZE_PROMPT:     'streak_freeze_prompt',
  STREAK_MILESTONE_REACHED: 'streak_milestone_reached',
  STREAK_BROKEN:            'streak_broken',
  // Host-add-player events
  PLAYER_ADDED_BY_HOST:     'player_added_by_host',
  PLAYER_DECLINED_SPOT:     'player_declined_spot',
  // Pre-game confirmation (partial games only)
  HOST_PRE_GAME_CONFIRM:    'host_pre_game_confirm',
});

const NotificationPriority = Object.freeze({
  CRITICAL: 'CRITICAL',
  HIGH:     'HIGH',
  DEFAULT:  'DEFAULT',
  LOW:      'LOW',
});

const TrustCategory = Object.freeze({
  POST_ROUND:       'post_round',
  TRUST_ALERTS:     'trust_alerts',
  BADGES:           'badges',
  GAMES:            'games',
  SOCIAL:           'social',
  WEEKLY_ACTIVITY:  'weekly_activity',
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

  [TrustEventType.GAME_ALERT_DEFERRED]: {
    priority:        NotificationPriority.DEFAULT,
    category:        TrustCategory.GAMES,
    maxDeliveries:   1,
    timing:          'scheduled',
    template: {
      title: '{title}',
      body:  '{body}',
    },
    deepLink:         'findmyfourth://game/{gameId}',
    threadId:         'game_alerts',
    androidChannelId: 'default',
    icon:             'sports_golf',
  },

  [TrustEventType.PLAYER_ADDED_BY_HOST]: {
    priority:        NotificationPriority.DEFAULT,
    category:        TrustCategory.GAMES,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: "You've been added to a game",
      body:  '{host_name} added you to {course_name} on {game_date}.',
    },
    deepLink:         'findmyfourth://game/{game_id}',
    threadId:         'game_{game_id}',
    androidChannelId: 'default',
    icon:             'person_add',
  },

  [TrustEventType.PLAYER_DECLINED_SPOT]: {
    priority:        NotificationPriority.DEFAULT,
    category:        TrustCategory.GAMES,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: 'Spot back open',
      body:  "{player_name} can't make it to your game at {course_name}.",
    },
    deepLink:         'findmyfourth://game/{game_id}',
    threadId:         'game_{game_id}',
    androidChannelId: 'default',
    icon:             'sports_golf',
  },

  [TrustEventType.HOST_PRE_GAME_CONFIRM]: {
    priority:        NotificationPriority.HIGH,
    category:        TrustCategory.GAMES,
    maxDeliveries:   1,
    timing:          'scheduled',
    template: {
      title: 'Is your game still on?',
      body:  'Your {course_name} game starts in 45 minutes. Tap to confirm or cancel.',
    },
    deepLink:         'findmyfourth://game/{game_id}/confirm',
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

  // ── Join Requests (Vibe Floor) ──────────────────────────────────────────────

  [TrustEventType.JOIN_REQUEST_NEW]: {
    priority:        NotificationPriority.DEFAULT,
    category:        TrustCategory.SOCIAL,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: 'New join request',
      body:  '{requester_name} wants to join your round.',
    },
    deepLink:         'findmyfourth://game/{game_id}/requests',
    threadId:         'social',
    androidChannelId: 'default',
    icon:             'person_add',
  },

  [TrustEventType.JOIN_REQUEST_APPROVED]: {
    priority:        NotificationPriority.DEFAULT,
    category:        TrustCategory.SOCIAL,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: "You're in!",
      body:  '{owner_name} approved your request to join {game_name}.',
    },
    deepLink:         'findmyfourth://game/{game_id}',
    threadId:         'social',
    androidChannelId: 'default',
    icon:             'check_circle',
  },

  [TrustEventType.JOIN_REQUEST_DECLINED]: {
    priority:        NotificationPriority.DEFAULT,
    category:        TrustCategory.SOCIAL,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: 'Request not approved',
      body:  'Your request to join {game_name} was not approved this time.',
    },
    deepLink:         'findmyfourth://games',
    threadId:         'social',
    androidChannelId: 'default',
    icon:             'info',
  },

  [TrustEventType.JOIN_REQUEST_ROUND_FILLED]: {
    priority:        NotificationPriority.DEFAULT,
    category:        TrustCategory.SOCIAL,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: 'Round filled',
      body:  '{game_name} filled up before your request could be reviewed.',
    },
    deepLink:         'findmyfourth://games',
    threadId:         'social',
    androidChannelId: 'default',
    icon:             'info',
  },

  [TrustEventType.JOIN_REQUEST_EXPIRED]: {
    priority:        NotificationPriority.DEFAULT,
    category:        TrustCategory.SOCIAL,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: 'Request expired',
      body:  'Your request to join {game_name} expired as the round has started.',
    },
    deepLink:         'findmyfourth://games',
    threadId:         'social',
    androidChannelId: 'default',
    icon:             'info',
  },

  // ── Weekly Streaks ────────────────────────────────────────────────────────

  [TrustEventType.STREAK_WEEKEND_NUDGE]: {
    priority:        NotificationPriority.DEFAULT,
    category:        TrustCategory.WEEKLY_ACTIVITY,
    maxDeliveries:   1,
    timing:          'scheduled',
    template: {
      title: 'Keep your streak alive',
      body:  "You haven't played this week yet. Find a game to maintain your {current_weeks}-week streak.",
    },
    deepLink:         'findmyfourth://games',
    threadId:         'streak',
    androidChannelId: 'default',
    icon:             'local_fire_department',
  },

  [TrustEventType.STREAK_FREEZE_UNLOCKED]: {
    priority:        NotificationPriority.HIGH,
    category:        TrustCategory.WEEKLY_ACTIVITY,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: 'Freeze unlocked',
      body:  "You've reached {current_weeks} consecutive weeks. You now have a freeze to protect your streak if you miss a week.",
    },
    deepLink:         'findmyfourth://profile',
    threadId:         'streak',
    androidChannelId: 'important',
    icon:             'ac_unit',
  },

  [TrustEventType.STREAK_FREEZE_PROMPT]: {
    priority:        NotificationPriority.HIGH,
    category:        TrustCategory.WEEKLY_ACTIVITY,
    maxDeliveries:   1,
    timing:          'scheduled',
    template: {
      title: 'Use your freeze?',
      body:  "You haven't played this week. Use your freeze before midnight to protect your {current_weeks}-week streak.",
    },
    deepLink:         'findmyfourth://profile',
    threadId:         'streak',
    androidChannelId: 'important',
    icon:             'ac_unit',
  },

  [TrustEventType.STREAK_MILESTONE_REACHED]: {
    priority:        NotificationPriority.HIGH,
    category:        TrustCategory.WEEKLY_ACTIVITY,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: '{milestone}-week streak!',
      body:  "You've played {current_weeks} consecutive weeks this season. Keep it going.",
    },
    deepLink:         'findmyfourth://profile',
    threadId:         'streak',
    androidChannelId: 'important',
    icon:             'local_fire_department',
  },

  [TrustEventType.STREAK_BROKEN]: {
    priority:        NotificationPriority.DEFAULT,
    category:        TrustCategory.WEEKLY_ACTIVITY,
    maxDeliveries:   1,
    timing:          'immediate',
    template: {
      title: 'Streak ended',
      body:  'Your {previous_weeks}-week streak has ended. Start a new one with your next round.',
    },
    deepLink:         'findmyfourth://games',
    threadId:         'streak',
    androidChannelId: 'default',
    icon:             'local_fire_department',
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
