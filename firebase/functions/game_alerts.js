/**
 * Game Alerts Cloud Functions
 *
 * New notification system that matches Create Game categories exactly:
 * - Game Vibe (rulesSetting): 'Competitive', 'Casual'
 * - Stakes (styleGame): 'No Money', 'Low Stakes', 'High Stakes'
 * - Format (gameType): 'Stroke Play', 'Match Play', 'Stableford'
 * - Handicap Use (scoring): 'Gross', 'Net', 'Both'
 * - Course (courseRef ID)
 * - Special: {games: boolean, twoVTwo: boolean, discount: boolean}
 *
 * Matching contract:
 * - Notifications triggered by GAME CREATION
 * - ONE notification per game per user max
 * - AND across categories (all selected must match)
 * - OR within category (any value matches)
 * - Empty category = match-all
 */

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const { scheduleJob } = require("./notifications/trust/scheduler");

const kAlertSubsCollection = "alertSubs";
const kUserNotificationsCollection = "notifications";
const kUserDevicesCollection = "devices";
const VERBOSE_ALERT_DEBUG = false;
const kQuietHoursTimezone = "America/Vancouver";
const firestore = admin.firestore();
const vanWeekdayFormatter = new Intl.DateTimeFormat("en-US", {
  timeZone: kQuietHoursTimezone,
  weekday: "short",
});
const vanDatePartsFormatter = new Intl.DateTimeFormat("en-CA", {
  timeZone: kQuietHoursTimezone,
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
  hour: "2-digit",
  minute: "2-digit",
  hourCycle: "h23",
});
const vanTzOffsetFormatter = new Intl.DateTimeFormat("en-US", {
  timeZone: kQuietHoursTimezone,
  timeZoneName: "shortOffset",
  hour: "2-digit",
  minute: "2-digit",
  hourCycle: "h23",
});

function getVancouverDateParts(now = new Date()) {
  const out = {};
  const parts = vanDatePartsFormatter.formatToParts(now);
  for (const part of parts) {
    if (
      part.type === "year" ||
      part.type === "month" ||
      part.type === "day" ||
      part.type === "hour" ||
      part.type === "minute"
    ) {
      out[part.type] = Number(part.value);
    }
  }
  return out;
}

function getVancouverOffsetMinutes(atUtcDate) {
  const parts = vanTzOffsetFormatter.formatToParts(atUtcDate);
  const tzPart = parts.find((part) => part.type === "timeZoneName");
  if (!tzPart || typeof tzPart.value !== "string") {
    return 0;
  }
  const match = tzPart.value.match(/^GMT([+-])(\d{1,2})(?::?(\d{2}))?$/);
  if (!match) {
    return 0;
  }
  const sign = match[1] === "-" ? -1 : 1;
  const hours = Number(match[2]);
  const minutes = match[3] ? Number(match[3]) : 0;
  return sign * (hours * 60 + minutes);
}

function localVancouverToUtcDate(year, month, day, hour, minute) {
  const baseUtcMs = Date.UTC(year, month - 1, day, hour, minute, 0, 0);
  let utcMs = baseUtcMs;
  for (let i = 0; i < 3; i++) {
    const offsetMinutes = getVancouverOffsetMinutes(new Date(utcMs));
    const nextUtcMs = baseUtcMs - offsetMinutes * 60 * 1000;
    if (nextUtcMs === utcMs) break;
    utcMs = nextUtcMs;
  }
  return new Date(utcMs);
}

function addUtcDays(year, month, day, delta) {
  const d = new Date(Date.UTC(year, month - 1, day, 0, 0, 0, 0));
  d.setUTCDate(d.getUTCDate() + delta);
  return {
    year: d.getUTCFullYear(),
    month: d.getUTCMonth() + 1,
    day: d.getUTCDate(),
  };
}

function getNowHHMMInVancouver(now = new Date()) {
  const vanDate = getVancouverDateParts(now);
  return `${String(vanDate.hour).padStart(2, "0")}:${String(vanDate.minute).padStart(2, "0")}`;
}

/**
 * Check if an alert subscription matches a game
 *
 * Implements exact matching logic:
 * 1. AND across categories: Every category the user selected must match
 * 2. OR within a category: If multiple values selected, any one match passes
 * 3. Empty category = match-all: If category is empty, it doesn't restrict
 */
function doesAlertSubMatchGame(subscription, gameData) {
  // If subscription is disabled, no match
  if (!subscription.enabled) {
    return false;
  }

  const gameVibes = subscription.gameVibes || [];
  const stakes = subscription.stakes || [];
  const formats = subscription.formats || [];
  const handicapUses = subscription.handicapUses || [];
  const courses = subscription.courses || [];
  const special = subscription.special || { games: false, twoVTwo: false, discount: false };

  // If all categories are empty, match all games
  const hasActiveFilters =
    gameVibes.length > 0 ||
    stakes.length > 0 ||
    formats.length > 0 ||
    handicapUses.length > 0 ||
    courses.length > 0 ||
    special.games ||
    special.twoVTwo ||
    special.discount;

  if (!hasActiveFilters) {
    return true;
  }

  // 1. Game Vibe (rules_setting)
  if (gameVibes.length > 0) {
    const gameRulesSetting = gameData.rules_setting || "";
    if (!matchesAny(gameVibes, gameRulesSetting)) {
      return false;
    }
  }

  // 2. Stakes (style_game)
  if (stakes.length > 0) {
    const gameStyleGame = gameData.style_game || "";
    if (!matchesAny(stakes, gameStyleGame)) {
      return false;
    }
  }

  // 3. Format (game_type)
  if (formats.length > 0) {
    const gameType = gameData.game_type || "";
    if (!matchesAny(formats, gameType)) {
      return false;
    }
  }

  // 4. Handicap Use (scoring)
  if (handicapUses.length > 0) {
    const gameScoring = gameData.scoring || "";
    if (!matchesAny(handicapUses, gameScoring)) {
      return false;
    }
  }

  // 5. Course (courseRef ID)
  if (courses.length > 0) {
    const gameCourseId = gameData.courseRef?.id || null;
    if (!gameCourseId || !courses.includes(gameCourseId)) {
      return false;
    }
  }

  // 6. Special options
  if (special.games) {
    if (gameData.has_side_games !== true) {
      return false;
    }
  }

  if (special.twoVTwo) {
    if (gameData.is_2v2 !== true) {
      return false;
    }
  }

  // 7. Discount
  if (special.discount) {
    if (!hasMemberDiscount(gameData.member_discount)) {
      return false;
    }
  }

  // All categories matched
  return true;
}

/**
 * Check if any value in the list matches the target (case-insensitive)
 */
function matchesAny(values, target) {
  if (!target || typeof target !== "string") {
    return false;
  }

  const targetLower = target.toLowerCase().trim();

  for (const value of values) {
    if (typeof value === "string" && value.toLowerCase().trim() === targetLower) {
      return true;
    }
  }

  return false;
}

/**
 * Returns true if member_discount indicates an applied discount.
 */
function hasMemberDiscount(memberDiscount) {
  if (typeof memberDiscount !== "string") {
    return false;
  }

  const normalized = memberDiscount.toLowerCase().trim();
  return normalized === "yes";
}

/**
 * Normalize gender value to canonical form.
 * Accepts common aliases and variations.
 * @param {string|null|undefined} value - Raw gender value
 * @returns {'male'|'female'|null} Canonical gender or null if unknown
 */
function normalizeGender(value) {
  if (!value || typeof value !== "string") {
    return null;
  }

  const normalized = value.toLowerCase().trim();

  // Male aliases
  if (normalized === "male" || normalized === "man" || normalized === "m") {
    return "male";
  }

  // Female aliases
  if (normalized === "female" || normalized === "woman" || normalized === "f") {
    return "female";
  }

  return null;
}

/**
 * Normalize player eligibility value to canonical form.
 * Accepts common aliases and variations (camelCase, Title Case, spaces).
 * @param {string|null|undefined} value - Raw eligibility value
 * @returns {'open_to_all'|'women_only'|'men_only'|null} Canonical eligibility or null if unknown
 */
function normalizePlayerEligibility(value) {
  if (!value || typeof value !== "string") {
    return null;
  }

  const normalized = value.toLowerCase().trim().replace(/[\s_-]+/g, "");

  // open_to_all aliases
  if (normalized === "opentoall" || normalized === "open" || normalized === "all") {
    return "open_to_all";
  }

  // women_only aliases
  if (normalized === "womenonly" || normalized === "femaleonly" || normalized === "ladies" || normalized === "ladiesonly") {
    return "women_only";
  }

  // men_only aliases
  if (normalized === "menonly" || normalized === "maleonly" || normalized === "gentlemen" || normalized === "gentlemenonly") {
    return "men_only";
  }

  return null;
}

/**
 * Check if user is eligible for game based on gender restrictions.
 * Uses normalized values to handle legacy aliases and variations.
 * @param {string|null} userGender - User's gender (e.g. 'Male', 'Female', 'man', 'woman')
 * @param {string|null} playerEligibility - Game's eligibility (e.g. 'open_to_all', 'women_only', 'Women Only')
 * @returns {boolean} Whether user can join this game
 */
function isUserEligibleByGender(userGender, playerEligibility) {
  const normalizedEligibility = normalizePlayerEligibility(playerEligibility);

  // open_to_all, null eligibility, or no restriction - everyone can join
  if (!normalizedEligibility || normalizedEligibility === "open_to_all") {
    return true;
  }

  const normalizedGender = normalizeGender(userGender);

  // women_only - only female users
  if (normalizedEligibility === "women_only") {
    return normalizedGender === "female";
  }

  // men_only - only male users
  if (normalizedEligibility === "men_only") {
    return normalizedGender === "male";
  }

  // Unknown eligibility value after normalization - log warning and allow (fail-open policy)
  console.warn(`[GameAlerts] Unknown eligibility value after normalization: "${playerEligibility}" - allowing access (fail-open)`);
  return true;
}

/**
 * Get user notification preferences from user document
 */
function getUserNotificationPrefs(userData) {
  const prefs = userData.notification_prefs || {};
  const quietHours = prefs.quiet_hours || {};
  const pushEnabled =
    typeof prefs.push_enabled === "boolean" ? prefs.push_enabled : true;
  const gameAlerts = prefs.game_alerts || {};
  const gameAlertsEnabled =
    typeof gameAlerts.enabled === "boolean" ? gameAlerts.enabled : true;
  const socialAlerts = prefs.social_alerts || {};
  const socialAlertsEnabled =
    typeof socialAlerts.enabled === "boolean" ? socialAlerts.enabled : true;

  return {
    pushEnabled,
    gameAlertsEnabled,
    socialAlertsEnabled,
    quietHoursEnabled: quietHours.enabled === true,
    quietHoursStart:
      typeof quietHours.start === "string" ? quietHours.start : "22:00",
    quietHoursEnd: typeof quietHours.end === "string" ? quietHours.end : "07:00",
    quietHoursActiveDays: Array.isArray(quietHours.active_days)
      ? quietHours.active_days
      : [],
    digestMode:
      typeof prefs.digest_mode === "string" ? prefs.digest_mode : "instant",
  };
}

/**
 * Check if quiet hours should apply on the current Vancouver day.
 * @param {number[]} activeDays - ISO days (1=Mon ... 7=Sun)
 * @returns {boolean}
 */
function isActiveDay(activeDays) {
  if (!Array.isArray(activeDays) || activeDays.length === 0) return true;
  const dayStr = vanWeekdayFormatter.format(new Date());
  const dayMap = { Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6, Sun: 7 };
  const isoDay = dayMap[dayStr];
  if (!isoDay) return true;
  return activeDays.some((day) => Number(day) === isoDay);
}

/**
 * Compute the next quiet-hours release instant in UTC from a Vancouver-local HH:MM.
 * @param {string} endHHMM
 * @returns {Date}
 */
function computeReleaseAt(endHHMM) {
  const now = new Date();
  const nowParts = getVancouverDateParts(now);
  const [h, m] = endHHMM.split(":").map(Number);
  let releaseAt = localVancouverToUtcDate(nowParts.year, nowParts.month, nowParts.day, h, m);
  if (releaseAt <= now) {
    const nextDay = addUtcDays(nowParts.year, nowParts.month, nowParts.day, 1);
    releaseAt = localVancouverToUtcDate(nextDay.year, nextDay.month, nextDay.day, h, m);
  }
  return releaseAt;
}

/**
 * Check if current time is within quiet hours
 */
function isWithinQuietHours(start, end, nowValue) {
  if (typeof start !== "string" || typeof end !== "string") {
    return false;
  }
  const startParts = start.split(":");
  const endParts = end.split(":");
  if (startParts.length !== 2 || endParts.length !== 2) {
    return false;
  }
  const startMinutes = parseInt(startParts[0], 10) * 60 + parseInt(startParts[1], 10);
  const endMinutes = parseInt(endParts[0], 10) * 60 + parseInt(endParts[1], 10);
  let nowMinutes;
  if (typeof nowValue === "string") {
    const nowParts = nowValue.split(":");
    if (nowParts.length !== 2) {
      return false;
    }
    nowMinutes = parseInt(nowParts[0], 10) * 60 + parseInt(nowParts[1], 10);
  } else if (nowValue instanceof Date) {
    nowMinutes = nowValue.getHours() * 60 + nowValue.getMinutes();
  } else {
    return false;
  }
  if (isNaN(nowMinutes)) {
    return false;
  }
  if (startMinutes === endMinutes) {
    return false;
  }
  if (startMinutes < endMinutes) {
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }
  return nowMinutes >= startMinutes || nowMinutes < endMinutes;
}

/**
 * Compute the number of open spots in a game.
 * @param {object} gameData - Firestore game document data
 * @returns {number} Available spots (clamped to 0)
 */
function computeSpots(gameData) {
  const maxPlayers = gameData.max_players || gameData.num_players || 4;
  const joinedCount = Array.isArray(gameData.joined_players) ? gameData.joined_players.length : 0;
  const guestCount = gameData.guest_count || 0;
  return Math.max(0, maxPlayers - joinedCount - guestCount);
}

/**
 * Format game date as "Sat, Mar 14 at 2:00 PM" in Vancouver timezone.
 * @param {object} gameData - Firestore game document data
 * @returns {string|null} Formatted date string, or null if unavailable
 */
function formatGameDate(gameData) {
  if (gameData.date && typeof gameData.date.toDate === "function") {
    try {
      const dateObj = gameData.date.toDate();
      return new Intl.DateTimeFormat("en-US", {
        timeZone: kQuietHoursTimezone,
        weekday: "short",
        month: "short",
        day: "numeric",
        hour: "numeric",
        minute: "2-digit",
        hour12: true,
      }).format(dateObj);
    } catch (_) {
      return null;
    }
  }
  return null;
}

/**
 * Build notification content for a game
 */
function buildGameNotificationContent(gameData) {
  const course = gameData.course_play || "";
  const spots = computeSpots(gameData);

  // Title: course-aware + spots-aware
  let title;
  if (spots === 1) {
    title = course ? `Last spot at ${course}` : "Last spot available";
  } else {
    title = course ? `New game at ${course}` : "New game posted";
  }

  // Body: Date · Stakes · N spots left
  const bodyParts = [];
  const dateStr = formatGameDate(gameData);
  if (dateStr) bodyParts.push(dateStr);
  if (gameData.style_game) bodyParts.push(gameData.style_game);
  const spotLabel = spots === 1 ? "1 spot left" : `${spots} spots left`;
  bodyParts.push(spotLabel);

  const body = bodyParts.join(" \u00B7 ");
  return { title, body };
}

/**
 * Build body text for last-spot silent update.
 * @param {object} gameData - Firestore game document data
 * @returns {string} Body text for last-spot notification
 */
function buildLastSpotBody(gameData) {
  const bodyParts = ["Last spot!"];
  const course = gameData.course_play || "";
  if (course) bodyParts.push(course);
  const dateStr = formatGameDate(gameData);
  if (dateStr) bodyParts.push(dateStr);
  bodyParts.push("Join now");
  return bodyParts.join(" \u00B7 ");
}

/**
 * Build notification content for a friend's game posting.
 *
 * @param {object} gameData - Firestore game document data
 * @param {string} creatorDisplayName - Display name of the game creator
 * @returns {{title: string, body: string}}
 */
function buildFriendGameNotificationContent(gameData, creatorDisplayName) {
  const displayName = creatorDisplayName || "A friend";
  const spots = computeSpots(gameData);

  // Spots-aware title
  const title = spots === 1
    ? `${displayName} posted a game \u2014 last spot!`
    : `${displayName} posted a game`;

  const course = gameData.course_play || "";
  const bodyParts = [];
  if (course) bodyParts.push(course);

  const dateStr = formatGameDate(gameData);
  if (dateStr) bodyParts.push(dateStr);

  const spotLabel = spots === 1 ? "1 spot left" : `${spots} spots left`;
  bodyParts.push(spotLabel);

  const body = bodyParts.join(" \u00B7 ");
  return { title, body };
}

/**
 * Send game created notifications using new matching logic
 *
 * Triggered when a new game is created in Firestore.
 * Matches against user alert subscriptions and sends push notifications.
 */
exports.sendGameCreatedNotifications = functions
  .region("us-west2")
  .runWith({
    timeoutSeconds: 540,
    memory: "512MB",
  })
  .firestore.document("games/{gameId}")
  .onCreate(async (snapshot, context) => {
    const gameData = snapshot.data() || {};
    const gameId = context.params.gameId;
    const creatorUid = gameData.userRef?.id || gameData.uid || null;

    const rawEligibility = gameData.player_eligibility;
    const normalizedEligibility = normalizePlayerEligibility(rawEligibility);

    console.log(`[GameAlerts] New game created: ${gameId}`);
    console.log(`[GameAlerts] Game data:`, {
      name: gameData.name_game,
      course: gameData.course_play,
      vibe: gameData.rules_setting,
      stakes: gameData.style_game,
      format: gameData.game_type,
      handicap: gameData.scoring,
      eligibility: rawEligibility,
      eligibilityNormalized: normalizedEligibility,
    });

    try {
      // Get enabled alert subscriptions in paginated batches
      const ALERT_BATCH_SIZE = 500;
      let baseQuery = firestore
        .collection(kAlertSubsCollection)
        .where("enabled", "==", true)
        .limit(ALERT_BATCH_SIZE);

      const now = new Date();
      let matchedCount = 0;
      let notifiedCount = 0;
      let totalProcessed = 0;
      let lastDoc = null;

      // Upfront dedup: fetch all existing game_created notifications for this game
      const existingNotifSnap = await firestore
        .collectionGroup(kUserNotificationsCollection)
        .where("type", "==", "game_created")
        .where("data.gameId", "==", gameId)
        .get();
      const alreadyNotifiedUserIds = new Set(
        existingNotifSnap.docs.map((doc) => doc.ref.parent.parent.id),
      );

      // Also dedup friend_game_created notifications (separate query to avoid
      // needing a composite index with `in` on the type field)
      const existingFriendNotifSnap = await firestore
        .collectionGroup(kUserNotificationsCollection)
        .where("type", "==", "friend_game_created")
        .where("data.gameId", "==", gameId)
        .get();
      for (const doc of existingFriendNotifSnap.docs) {
        alreadyNotifiedUserIds.add(doc.ref.parent.parent.id);
      }

      // ── Friend-posted bypass ──────────────────────────────────────────────
      // Friends of the game creator receive a notification regardless of their
      // alert subscription filters. This block runs before the filter-match
      // loop so that friend-notified users are added to alreadyNotifiedUserIds
      // and don't also receive a generic game_created notification.
      if (creatorUid) {
        const creatorDoc = await firestore.collection("users").doc(creatorUid).get();
        const creatorData = creatorDoc.exists ? creatorDoc.data() || {} : {};
        const creatorDisplayName = creatorData.display_name || "A friend";
        const friendRefs = Array.isArray(creatorData.friends) ? creatorData.friends : [];
        const friendUids = friendRefs
          .filter((ref) => ref && ref.id)
          .map((ref) => ref.id);

        const friendContent = buildFriendGameNotificationContent(gameData, creatorDisplayName);
        let friendNotified = 0;
        let friendSkipped = 0;

        for (const friendUid of friendUids) {
          // Self-reference safety
          if (friendUid === creatorUid) {
            friendSkipped++;
            continue;
          }

          // Dedup
          if (alreadyNotifiedUserIds.has(friendUid)) {
            friendSkipped++;
            continue;
          }

          // Load friend user doc
          const friendRef = firestore.collection("users").doc(friendUid);
          const friendSnap = await friendRef.get();
          if (!friendSnap.exists) {
            friendSkipped++;
            continue;
          }

          const friendData = friendSnap.data() || {};

          // Gender eligibility check
          const friendGender = friendData.gender || null;
          if (!isUserEligibleByGender(friendGender, gameData.player_eligibility)) {
            friendSkipped++;
            continue;
          }

          const friendPrefs = getUserNotificationPrefs(friendData);

          // Push enabled check
          if (!friendPrefs.pushEnabled) {
            friendSkipped++;
            continue;
          }

          // Social alerts check — friend notifications are categorized under
          // SOCIAL, gated by social_alerts.enabled (not game_alerts.enabled)
          if (!friendPrefs.socialAlertsEnabled) {
            friendSkipped++;
            continue;
          }

          // Write in-app notification
          const friendDedupeKey = `friend_game_${gameId}_to_${friendUid}`;
          const friendNotifRef = friendRef
            .collection(kUserNotificationsCollection)
            .doc(friendDedupeKey);

          await friendNotifRef.set({
            type: "friend_game_created",
            title: friendContent.title,
            body: friendContent.body,
            data: {
              gameId,
              creatorUid,
            },
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            dedupeKey: friendDedupeKey,
          });

          // Add to dedup set so the filter-match loop won't also notify this user
          alreadyNotifiedUserIds.add(friendUid);

          // Quiet hours check
          const nowHHMM = getNowHHMMInVancouver(now);
          const friendInQuietHours =
            friendPrefs.quietHoursEnabled &&
            isActiveDay(friendPrefs.quietHoursActiveDays) &&
            isWithinQuietHours(friendPrefs.quietHoursStart, friendPrefs.quietHoursEnd, nowHHMM);

          if (friendInQuietHours) {
            const releaseAt = computeReleaseAt(friendPrefs.quietHoursEnd);
            const deferredEvent = {
              eventId: `friend_game_alert_${gameId}_${friendUid}_${Date.now()}`,
              eventType: "friend_game_alert_deferred",
              recipientUserId: friendUid,
              sourceId: gameId,
              data: {
                title: friendContent.title,
                body: friendContent.body,
                gameId,
                creatorUid,
                initialPageName: "JoinGameDetailed",
              },
              scheduleTime: releaseAt,
              quietHoursBypass: true,
              conditionCheck: "always",
            };
            try {
              const jobId = await scheduleJob(deferredEvent, admin.firestore());
              console.log(`[GameAlerts] Friend ${friendUid} in quiet hours — scheduled for ${releaseAt.toISOString()}, jobId: ${jobId}`);
            } catch (e) {
              console.error(`[GameAlerts] Failed to schedule deferred friend notification for ${friendUid}:`, e.message);
            }
            friendNotified++;
            continue;
          }

          // Fetch devices and send FCM push
          const friendDeviceSnap = await friendRef
            .collection(kUserDevicesCollection)
            .get();

          if (friendDeviceSnap.empty) {
            console.log(`[GameAlerts] Friend ${friendUid} has no devices, skipping push`);
            friendNotified++;
            continue;
          }

          const friendDeviceTokens = [];
          friendDeviceSnap.docs.forEach((doc) => {
            const token = doc.data()?.fcmToken;
            if (typeof token === "string" && token.length > 0) {
              friendDeviceTokens.push({ token, ref: doc.ref });
            }
          });

          if (friendDeviceTokens.length === 0) {
            console.log(`[GameAlerts] Friend ${friendUid} has no valid tokens, skipping push`);
            friendNotified++;
            continue;
          }

          const friendMessage = {
            notification: {
              title: friendContent.title,
              body: friendContent.body,
            },
            data: {
              initialPageName: "JoinGameDetailed",
              parameterData: JSON.stringify({
                gameRef: `games/${gameId}`,
              }),
              type: "friend_game_created",
              gameId,
              creatorUid,
            },
            android: {
              priority: "high",
              notification: {
                channelId: "default",
                sound: "default",
              },
            },
            apns: {
              headers: {
                "apns-push-type": "alert",
                "apns-priority": "10",
              },
              payload: {
                aps: {
                  sound: "default",
                  badge: 1,
                  "mutable-content": 1,
                },
              },
            },
            tokens: friendDeviceTokens.map((entry) => entry.token),
          };

          try {
            const response = await admin.messaging().sendEachForMulticast(friendMessage);
            console.log(`[GameAlerts] Sent friend push to ${friendUid}, success: ${response.successCount}/${response.responses.length}`);

            // Clean up invalid tokens
            const invalidRefs = [];
            response.responses.forEach((resp, index) => {
              if (resp.success) return;
              const code = resp.error?.code || "";
              if (
                code === "messaging/registration-token-not-registered" ||
                code === "messaging/invalid-registration-token"
              ) {
                invalidRefs.push(friendDeviceTokens[index]?.ref);
              }
            });

            if (invalidRefs.length > 0) {
              await Promise.all(
                invalidRefs.filter((ref) => ref).map((ref) => ref.delete()),
              );
            }
          } catch (error) {
            console.error(`[GameAlerts] Failed to send friend push to ${friendUid}:`, error.message);
          }

          friendNotified++;
        }

        console.log(`[GameAlerts] Friend pass complete: ${friendUids.length} friends, ${friendNotified} notified, ${friendSkipped} skipped`);
      }

      let skippedCreator = 0;
      let skippedNoMatch = 0;
      let skippedGender = 0;
      let skippedPushOff = 0;
      let skippedAlertsOff = 0;
      let skippedDigestOff = 0;
      let skippedDedup = 0;
      let skippedNoUser = 0;

      while (true) {
      const currentQuery = lastDoc ? baseQuery.startAfter(lastDoc) : baseQuery;
      const subsSnapshot = await currentQuery.get();

      if (subsSnapshot.empty) break;

      totalProcessed += subsSnapshot.docs.length;
      console.log(`[GameAlerts] Processing batch of ${subsSnapshot.docs.length} subscriptions (${totalProcessed} total)`);

      // Check each subscription for a match
      for (const subDoc of subsSnapshot.docs) {
        const subscription = subDoc.data();
        const userId = subscription.userId;

        // Skip creator
        if (creatorUid && userId === creatorUid) {
          skippedCreator++;
          continue;
        }

        // Check if subscription matches game
        const matches = doesAlertSubMatchGame(subscription, gameData);

        if (VERBOSE_ALERT_DEBUG) {
          console.log(`[GameAlerts][TRACE] Sub ${userId}: ` +
            `stakes=${JSON.stringify(subscription.stakes)}, ` +
            `game_stakes=${gameData.style_game}, ` +
            `match=${matches}`);
        }

        if (!matches) {
          skippedNoMatch++;
          continue;
        }

        matchedCount++;
        console.log(`[GameAlerts] Subscription ${userId} matches game ${gameId}`);

        // Load user document
        const userRef = firestore.collection("users").doc(userId);
        const userSnap = await userRef.get();

        if (!userSnap.exists) {
          console.log(`[GameAlerts] User ${userId} not found, skipping`);
          skippedNoUser++;
          continue;
        }

        const userData = userSnap.data() || {};

        // Check if user is eligible based on gender restrictions
        const userGender = userData.gender || null;
        const playerEligibility = gameData.player_eligibility || "open_to_all";
        if (!isUserEligibleByGender(userGender, playerEligibility)) {
          console.log(`[GameAlerts] User ${userId} (${userGender || "no gender"}) not eligible for ${playerEligibility} game, skipping`);
          skippedGender++;
          continue;
        }

        const prefs = getUserNotificationPrefs(userData);

        // Check if push notifications are enabled
        if (!prefs.pushEnabled) {
          console.log(`[GameAlerts] User ${userId} has push disabled, skipping`);
          skippedPushOff++;
          continue;
        }

        // Check if game alerts are enabled in user preferences
        if (!prefs.gameAlertsEnabled) {
          console.log(`[GameAlerts] User ${userId} has game alerts disabled, skipping`);
          skippedAlertsOff++;
          continue;
        }

        // Check digest mode
        if (prefs.digestMode === "off") {
          console.log(`[GameAlerts] User ${userId} has digest mode off, skipping`);
          skippedDigestOff++;
          continue;
        }

        // Check dedup from upfront query
        if (alreadyNotifiedUserIds.has(userId)) {
          console.log(`[GameAlerts] Notification already sent to ${userId}, skipping`);
          skippedDedup++;
          continue;
        }

        // Create notification document
        const dedupeKey = `game_${gameId}_to_${userId}`;
        const notificationRef = userRef
          .collection(kUserNotificationsCollection)
          .doc(dedupeKey);

        const content = buildGameNotificationContent(gameData);
        await notificationRef.set({
          type: "game_created",
          title: content.title,
          body: content.body,
          data: {
            gameId,
          },
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          dedupeKey,
        });

        // Track in dedup set to prevent intra-batch duplicates
        alreadyNotifiedUserIds.add(userId);

        // Check if we should send push notification now
        const nowHHMM = getNowHHMMInVancouver(now);
        const inQuietHours =
          prefs.quietHoursEnabled &&
          isActiveDay(prefs.quietHoursActiveDays) &&
          isWithinQuietHours(prefs.quietHoursStart, prefs.quietHoursEnd, nowHHMM);

        if (inQuietHours) {
          const releaseAt = computeReleaseAt(prefs.quietHoursEnd);
          const deferredEvent = {
            eventId: `game_alert_${gameId}_${Date.now()}`,
            eventType: "game_alert_deferred",
            recipientUserId: userId,
            sourceId: gameId,
            data: {
              title: content.title,
              body: content.body,
              gameId,
              initialPageName: "JoinGameDetailed",
            },
            scheduleTime: releaseAt,
            quietHoursBypass: true,
            conditionCheck: "always",
          };
          try {
            const jobId = await scheduleJob(deferredEvent, admin.firestore());
            console.log(`[GameAlerts] User ${userId} in quiet hours — scheduled for ${releaseAt.toISOString()}, jobId: ${jobId}`);
          } catch (e) {
            console.error(`[GameAlerts] Failed to schedule deferred notification for ${userId}:`, e.message);
          }
          continue;
        }

        if (prefs.digestMode !== "instant") {
          console.log(`[GameAlerts] User ${userId} digest mode, notification saved but not sent`);
          continue;
        }

        // Get user devices
        const deviceSnap = await userRef
          .collection(kUserDevicesCollection)
          .get();

        if (deviceSnap.empty) {
          console.log(`[GameAlerts] User ${userId} has no devices, skipping push`);
          continue;
        }

        const deviceTokens = [];
        deviceSnap.docs.forEach((doc) => {
          const token = doc.data()?.fcmToken;
          if (typeof token === "string" && token.length > 0) {
            deviceTokens.push({ token, ref: doc.ref });
          }
        });

        if (deviceTokens.length === 0) {
          console.log(`[GameAlerts] User ${userId} has no valid tokens, skipping push`);
          continue;
        }

        // Send push notification
        const message = {
          notification: {
            title: content.title,
            body: content.body,
          },
          data: {
            initialPageName: "JoinGameDetailed",
            parameterData: JSON.stringify({
              gameRef: `games/${gameId}`,
            }),
            type: "game_created",
            gameId,
          },
          android: {
            priority: "high",
            notification: {
              channelId: "default",
              sound: "default",
            },
          },
          apns: {
            headers: {
              "apns-push-type": "alert",
              "apns-priority": "10",
            },
            payload: {
              aps: {
                sound: "default",
                badge: 1,
                "mutable-content": 1,
              },
            },
          },
          tokens: deviceTokens.map((entry) => entry.token),
        };

        try {
          const response = await admin.messaging().sendEachForMulticast(message);
          console.log(`[GameAlerts] Sent push notification to ${userId}, success: ${response.successCount}/${response.responses.length}`);

          notifiedCount++;

          // Record success
          await userRef.update({
            "notification_state.last_send_success": admin.firestore.FieldValue.serverTimestamp(),
          });

          // Clean up invalid tokens
          const invalidRefs = [];
          response.responses.forEach((resp, index) => {
            if (resp.success) {
              return;
            }
            const code = resp.error?.code || "";
            if (
              code === "messaging/registration-token-not-registered" ||
              code === "messaging/invalid-registration-token"
            ) {
              invalidRefs.push(deviceTokens[index]?.ref);
            }
          });

          if (invalidRefs.length > 0) {
            await Promise.all(
              invalidRefs
                .filter((ref) => ref)
                .map((ref) => ref.delete()),
            );
          }
        } catch (error) {
          console.error(`[GameAlerts] Failed to send push to ${userId}:`, error.message);

          // Store error for frontend to read
          await userRef.update({
            "notification_state.last_error": {
              message: error.message || "Failed to send notification",
              code: error.code || "unknown",
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
              type: "notification_send",
            },
          });
        }
      }

      lastDoc = subsSnapshot.docs[subsSnapshot.docs.length - 1];
      if (subsSnapshot.docs.length < ALERT_BATCH_SIZE) break;
      } // end pagination while loop

      console.log(`[GameAlerts] Game ${gameId} complete: ${totalProcessed} subs, ` +
        `${matchedCount} matched, ${notifiedCount} notified | ` +
        `skipped: creator=${skippedCreator} noMatch=${skippedNoMatch} ` +
        `gender=${skippedGender} pushOff=${skippedPushOff} alertsOff=${skippedAlertsOff} ` +
        `digestOff=${skippedDigestOff} dedup=${skippedDedup} noUser=${skippedNoUser}`);
    } catch (error) {
      console.error(`[GameAlerts] Error processing game ${gameId}:`, error);
      throw error;
    }
  });

/**
 * Silent Last-Spot Update
 *
 * Triggered when a game document is updated. When the number of open spots
 * transitions from >=2 to exactly 1, this function silently updates the body
 * of all existing notification documents for this game to reflect "Last spot!".
 *
 * No new push notification is sent, no new notification doc is created,
 * and no badge count changes. A one-shot flag (`last_spot_notified`) prevents
 * re-firing if a player leaves and another joins.
 */
exports.onGameLastSpotUpdate = functions
  .region("us-west2")
  .runWith({
    timeoutSeconds: 120,
    memory: "256MB",
  })
  .firestore.document("games/{gameId}")
  .onUpdate(async (change, context) => {
    const gameId = context.params.gameId;
    const beforeData = change.before.data() || {};
    const afterData = change.after.data() || {};

    const beforeSpots = computeSpots(beforeData);
    const afterSpots = computeSpots(afterData);

    // Only fire when transitioning from >=2 spots to exactly 1
    if (beforeSpots < 2 || afterSpots !== 1) {
      return;
    }

    // One-shot guard
    if (afterData.last_spot_notified === true) {
      console.log(`[GameAlerts] Game ${gameId} already sent last-spot update, skipping`);
      return;
    }

    console.log(`[GameAlerts] Last-spot trigger fired for game ${gameId} (${beforeSpots} → ${afterSpots})`);

    // Set one-shot flag
    await change.after.ref.update({ last_spot_notified: true });

    // Build the updated body
    const lastSpotBody = buildLastSpotBody(afterData);

    // Query existing notification docs for this game (two queries to avoid composite index)
    const [gameCreatedSnap, friendGameCreatedSnap] = await Promise.all([
      firestore
        .collectionGroup(kUserNotificationsCollection)
        .where("type", "==", "game_created")
        .where("data.gameId", "==", gameId)
        .get(),
      firestore
        .collectionGroup(kUserNotificationsCollection)
        .where("type", "==", "friend_game_created")
        .where("data.gameId", "==", gameId)
        .get(),
    ]);

    const allDocs = [...gameCreatedSnap.docs, ...friendGameCreatedSnap.docs];

    if (allDocs.length === 0) {
      console.log(`[GameAlerts] No existing notifications found for game ${gameId}`);
      return;
    }

    // Extract participant UIDs to skip — participants should not see "Last spot!"
    const participantUids = new Set();
    if (Array.isArray(afterData.joined_players)) {
      for (const ref of afterData.joined_players) {
        if (ref && ref.id) participantUids.add(ref.id);
      }
    }
    const creatorUid = afterData.userRef?.id || afterData.uid || null;
    if (creatorUid) participantUids.add(creatorUid);

    // Batch update notification docs, skipping participants (chunk if >500)
    const BATCH_LIMIT = 500;
    let updateCount = 0;
    for (let i = 0; i < allDocs.length; i += BATCH_LIMIT) {
      const chunk = allDocs.slice(i, i + BATCH_LIMIT);
      const batch = firestore.batch();
      let batchOps = 0;
      for (const doc of chunk) {
        // Path: users/{userId}/notifications/{docId}
        const userId = doc.ref.parent.parent.id;
        if (participantUids.has(userId)) {
          continue;
        }
        batch.update(doc.ref, {
          body: lastSpotBody,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        batchOps++;
      }
      if (batchOps > 0) {
        await batch.commit();
      }
      updateCount += batchOps;
    }

    const skipped = allDocs.length - updateCount;
    console.log(`[GameAlerts] Updated ${updateCount} notification docs for game ${gameId} with last-spot body (skipped ${skipped} participants)`);
  });

// Export for testing
module.exports = {
  ...exports,
  // Test helpers
  normalizeGender,
  normalizePlayerEligibility,
  isUserEligibleByGender,
  doesAlertSubMatchGame,
  isWithinQuietHours,
  isActiveDay,
  computeReleaseAt,
  computeSpots,
  formatGameDate,
  buildGameNotificationContent,
  buildFriendGameNotificationContent,
  buildLastSpotBody,
};
