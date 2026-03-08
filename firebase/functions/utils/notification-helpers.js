'use strict';

/**
 * Shared notification helper functions.
 *
 * Extracted from index.js so they can be reused by chat_debounce.js
 * and other notification modules without duplication.
 */

function getUserNotificationPrefs(userData) {
  const prefs = userData.notification_prefs || {};
  const gameAlerts = prefs.game_alerts || {};
  const chatAlerts = prefs.chat_alerts || {};
  const quietHours = prefs.quiet_hours || {};
  const pushEnabled =
    typeof prefs.push_enabled === "boolean" ? prefs.push_enabled : true;
  const gameAlertsEnabled =
    typeof gameAlerts.enabled === "boolean" ? gameAlerts.enabled : true;
  const chatAlertsEnabled =
    typeof chatAlerts.enabled === "boolean" ? chatAlerts.enabled : true;
  const chatDirectEnabled =
    typeof chatAlerts.direct === "boolean" ? chatAlerts.direct : true;
  const chatGroupEnabled =
    typeof chatAlerts.group === "boolean" ? chatAlerts.group : true;
  const styles = Array.isArray(gameAlerts.styles)
    ? gameAlerts.styles.filter((style) => typeof style === "string")
    : [];
  const mutedThreads = Array.isArray(prefs.muted_threads)
    ? prefs.muted_threads.filter((threadId) => typeof threadId === "string")
    : [];
  return {
    pushEnabled,
    gameAlertsEnabled,
    chatAlertsEnabled,
    chatDirectEnabled,
    chatGroupEnabled,
    styles,
    mutedThreads,
    quietHoursEnabled: quietHours.enabled === true,
    quietHoursStart:
      typeof quietHours.start === "string" ? quietHours.start : "22:00",
    quietHoursEnd: typeof quietHours.end === "string" ? quietHours.end : "07:00",
    digestMode:
      typeof prefs.digest_mode === "string" ? prefs.digest_mode : "instant",
  };
}

function isWithinQuietHours(start, end, now) {
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
  const nowMinutes = now.getHours() * 60 + now.getMinutes();
  if (startMinutes === endMinutes) {
    return false;
  }
  if (startMinutes < endMinutes) {
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }
  return nowMinutes >= startMinutes || nowMinutes < endMinutes;
}

function getUserDisplayName(userData) {
  if (!userData) {
    return "";
  }
  const displayName = userData.display_name;
  if (typeof displayName === "string" && displayName.trim().length > 0) {
    return displayName.trim();
  }
  const firstName =
    typeof userData.first_name === "string" ? userData.first_name.trim() : "";
  const lastName =
    typeof userData.last_name === "string" ? userData.last_name.trim() : "";
  const combined = `${firstName} ${lastName}`.trim();
  return combined;
}

function buildChatMessagePreview(messageData) {
  const text = typeof messageData.text === "string" ? messageData.text.trim() : "";
  if (text.length > 0) {
    return text.length > 160 ? `${text.slice(0, 157)}...` : text;
  }
  const imageUrl =
    typeof messageData.imageUrl === "string" ? messageData.imageUrl.trim() : "";
  if (imageUrl.length > 0) {
    return "Sent a photo";
  }
  const videoUrl =
    typeof messageData.videoUrl === "string" ? messageData.videoUrl.trim() : "";
  if (videoUrl.length > 0) {
    return "Sent a video";
  }
  return "Sent a message";
}

module.exports = {
  getUserNotificationPrefs,
  isWithinQuietHours,
  getUserDisplayName,
  buildChatMessagePreview,
};
