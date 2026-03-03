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
const kGameAlertCooldownMinutes = 60;
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
 * Check if user is eligible for game based on gender restrictions
 * @param {string|null} userGender - User's gender ('Male' or 'Female')
 * @param {string|null} playerEligibility - Game's eligibility ('open_to_all', 'women_only', 'men_only')
 * @returns {boolean} Whether user can join this game
 */
function isUserEligibleByGender(userGender, playerEligibility) {
  // open_to_all or no restriction - everyone can join
  if (!playerEligibility || playerEligibility === "open_to_all") {
    return true;
  }
  // women_only - only Female users
  if (playerEligibility === "women_only") {
    return userGender === "Female";
  }
  // men_only - only Male users
  if (playerEligibility === "men_only") {
    return userGender === "Male";
  }
  // Unknown eligibility value - default to allowing
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

  return {
    pushEnabled,
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
 * Build notification content for a game
 */
function buildGameNotificationContent(gameData) {
  const name = gameData.name_game || "New game";
  const course = gameData.course_play || "";
  const title = "New game posted";

  // Build a nice summary
  const parts = [];
  if (gameData.style_game) parts.push(gameData.style_game);
  if (gameData.game_type) parts.push(gameData.game_type);
  if (gameData.rules_setting) parts.push(gameData.rules_setting);

  const suffix = parts.length > 0 ? ` • ${parts.join(' • ')}` : "";
  const body = course ? `${name} at ${course}${suffix}` : `${name}${suffix}`;

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
    memory: "2GB",
  })
  .firestore.document("games/{gameId}")
  .onCreate(async (snapshot, context) => {
    const gameData = snapshot.data() || {};
    const gameId = context.params.gameId;
    const creatorUid = gameData.userRef?.id || gameData.uid || null;

    console.log(`[GameAlerts] New game created: ${gameId}`);
    console.log(`[GameAlerts] Game data:`, {
      name: gameData.name_game,
      course: gameData.course_play,
      vibe: gameData.rules_setting,
      stakes: gameData.style_game,
      format: gameData.game_type,
      handicap: gameData.scoring,
      eligibility: gameData.player_eligibility,
    });

    try {
      // Get all enabled alert subscriptions
      const subsSnapshot = await firestore
        .collection(kAlertSubsCollection)
        .where("enabled", "==", true)
        .get();

      console.log(`[GameAlerts] Found ${subsSnapshot.docs.length} enabled subscriptions`);

      if (subsSnapshot.empty) {
        console.log(`[GameAlerts] No enabled subscriptions, skipping`);
        return;
      }

      const now = new Date();
      let matchedCount = 0;
      let notifiedCount = 0;

      // Check each subscription for a match
      for (const subDoc of subsSnapshot.docs) {
        const subscription = subDoc.data();
        const userId = subscription.userId;

        // Skip creator
        if (creatorUid && userId === creatorUid) {
          continue;
        }

        // Check if subscription matches game
        const matches = doesAlertSubMatchGame(subscription, gameData);

        if (!matches) {
          continue;
        }

        matchedCount++;
        console.log(`[GameAlerts] Subscription ${userId} matches game ${gameId}`);

        // Load user document
        const userRef = firestore.collection("users").doc(userId);
        const userSnap = await userRef.get();

        if (!userSnap.exists) {
          console.log(`[GameAlerts] User ${userId} not found, skipping`);
          continue;
        }

        const userData = userSnap.data() || {};

        // Check if user is eligible based on gender restrictions
        const userGender = userData.gender || null;
        const playerEligibility = gameData.player_eligibility || "open_to_all";
        if (!isUserEligibleByGender(userGender, playerEligibility)) {
          console.log(`[GameAlerts] User ${userId} (${userGender || "no gender"}) not eligible for ${playerEligibility} game, skipping`);
          continue;
        }

        const prefs = getUserNotificationPrefs(userData);

        // Check if push notifications are enabled
        if (!prefs.pushEnabled) {
          console.log(`[GameAlerts] User ${userId} has push disabled, skipping`);
          continue;
        }

        // Check digest mode
        if (prefs.digestMode === "off") {
          console.log(`[GameAlerts] User ${userId} has digest mode off, skipping`);
          continue;
        }

        // Check cooldown (60 minutes between game alerts)
        const state = userData.notification_state || {};
        const lastGameAlert = state.last_game_alert;
        if (lastGameAlert?.toDate) {
          const lastDate = lastGameAlert.toDate();
          const cooldownMs = kGameAlertCooldownMinutes * 60 * 1000;
          if (now - lastDate < cooldownMs) {
            console.log(`[GameAlerts] User ${userId} in cooldown, skipping`);
            continue;
          }
        }

        // Create notification document (deduplicated)
        const dedupeKey = `game_${gameId}_to_${userId}`;
        const notificationRef = userRef
          .collection(kUserNotificationsCollection)
          .doc(dedupeKey);

        const existing = await notificationRef.get();
        if (existing.exists) {
          console.log(`[GameAlerts] Notification already sent to ${userId}, skipping`);
          continue;
        }

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

        // Update cooldown timestamp
        await userRef.set(
          {
            notification_state: {
              last_game_alert: admin.firestore.FieldValue.serverTimestamp(),
            },
          },
          { merge: true },
        );

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

      console.log(`[GameAlerts] Game ${gameId} complete: ${matchedCount} matched, ${notifiedCount} notified`);
    } catch (error) {
      console.error(`[GameAlerts] Error processing game ${gameId}:`, error);
      throw error;
    }
  });

// Export for testing
module.exports = {
  ...exports,
  // Test helpers
  isUserEligibleByGender,
  doesAlertSubMatchGame,
  isWithinQuietHours,
  isActiveDay,
  computeReleaseAt,
};
