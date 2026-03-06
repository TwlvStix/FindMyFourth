'use strict';

/**
 * Host Add Player Notification Hooks
 *
 * Handles notifications when a host manually adds a player to their game:
 * - Player added by host (to added player)
 * - Player declined spot (to host when added player can't make it)
 *
 * Uses the same routeNotification pattern as trust system notifications.
 */

const { randomUUID } = require('crypto');
const { routeNotification } = require('./notifications/trust/router');

// ── Host Add Player Notification Hooks ───────────────────────────────────────

/**
 * Called when a host adds a player to their game.
 * Notifies the added player immediately.
 *
 * @param {string} addedPlayerUserId - Player who was added
 * @param {string} hostUserId - Host who added them
 * @param {string} hostName - Display name of host
 * @param {string} gameId - Game the player was added to
 * @param {string} courseName - Course name for display
 * @param {string} gameDate - Formatted game date (e.g., "Saturday, Mar 15 at 10:00 AM")
 * @param {string|null} hostAvatarUrl - Host's avatar URL
 * @param {FirebaseFirestore.Firestore} [db]
 */
async function onPlayerAddedByHost(addedPlayerUserId, hostUserId, hostName, gameId, courseName, gameDate, hostAvatarUrl, db) {
  return routeNotification({
    eventId:         randomUUID(),
    eventType:       'player_added_by_host',
    recipientUserId: addedPlayerUserId,
    sourceId:        `host_add_${gameId}_${addedPlayerUserId}`,
    data: {
      host_name:        hostName,
      host_id:          hostUserId,
      game_id:          gameId,
      course_name:      courseName,
      game_date:        gameDate,
      actor_avatar_url: hostAvatarUrl || null,
    },
  }, db);
}

/**
 * Called when a player declines a spot they were added to by the host.
 * Notifies the host that the spot is back open.
 *
 * @param {string} hostUserId - Host receiving the notification
 * @param {string} playerUserId - Player who declined
 * @param {string} playerName - Display name of declining player
 * @param {string} gameId - Game the player declined
 * @param {string} courseName - Course name for display
 * @param {string|null} playerAvatarUrl - Player's avatar URL
 * @param {FirebaseFirestore.Firestore} [db]
 */
async function onPlayerDeclinedSpot(hostUserId, playerUserId, playerName, gameId, courseName, playerAvatarUrl, db) {
  return routeNotification({
    eventId:         randomUUID(),
    eventType:       'player_declined_spot',
    recipientUserId: hostUserId,
    sourceId:        `decline_${gameId}_${playerUserId}`,
    data: {
      player_name:      playerName,
      player_id:        playerUserId,
      game_id:          gameId,
      course_name:      courseName,
      actor_avatar_url: playerAvatarUrl || null,
    },
  }, db);
}

module.exports = {
  onPlayerAddedByHost,
  onPlayerDeclinedSpot,
};
