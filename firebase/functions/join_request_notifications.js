'use strict';

/**
 * Join Request Notification Hooks
 *
 * Handles notifications for the vibe floor join request lifecycle:
 * - New request submitted (to owner)
 * - Request approved (to player)
 * - Request declined (to player)
 * - Round filled before approval (to player)
 *
 * Uses the same routeNotification pattern as trust system notifications.
 */

const { randomUUID } = require('crypto');
const { routeNotification } = require('./notifications/trust/router');

// ── Join Request Notification Hooks ───────────────────────────────────────────

/**
 * Called when a player submits a join request.
 * Notifies the game owner immediately.
 *
 * @param {string} ownerUserId - Game owner receiving the notification
 * @param {string} requesterUserId - Player requesting to join
 * @param {string} requesterName - Display name of requester
 * @param {string} gameId - Game being requested
 * @param {string|null} requesterAvatarUrl - Requester's avatar URL (photo or initials)
 * @param {FirebaseFirestore.Firestore} [db]
 */
async function onJoinRequestReceived(ownerUserId, requesterUserId, requesterName, gameId, requesterAvatarUrl, db) {
  return routeNotification({
    eventId:         randomUUID(),
    eventType:       'join_request_new',
    recipientUserId: ownerUserId,
    sourceId:        `join_request_${gameId}_${requesterUserId}`,
    data: {
      requester_name:   requesterName,
      requester_id:     requesterUserId,
      game_id:          gameId,
      actor_avatar_url: requesterAvatarUrl || null,
    },
  }, db);
}

/**
 * Called when the owner approves a join request.
 * Notifies the requesting player.
 *
 * @param {string} playerUserId - Player receiving the notification
 * @param {string} ownerUserId - Owner who approved
 * @param {string} ownerName - Display name of owner
 * @param {string} gameId - Game that was joined
 * @param {string} gameName - Name of the game for display
 * @param {string|null} ownerAvatarUrl - Owner's avatar URL (photo or initials)
 * @param {FirebaseFirestore.Firestore} [db]
 */
async function onJoinRequestApproved(playerUserId, ownerUserId, ownerName, gameId, gameName, ownerAvatarUrl, db) {
  return routeNotification({
    eventId:         randomUUID(),
    eventType:       'join_request_approved',
    recipientUserId: playerUserId,
    sourceId:        `join_request_approved_${gameId}_${playerUserId}`,
    data: {
      owner_name:       ownerName,
      owner_id:         ownerUserId,
      game_id:          gameId,
      game_name:        gameName,
      actor_avatar_url: ownerAvatarUrl || null,
    },
  }, db);
}

/**
 * Called when the owner declines a join request.
 * Notifies the requesting player.
 *
 * @param {string} playerUserId - Player receiving the notification
 * @param {string} gameId - Game that was declined
 * @param {string} gameName - Name of the game for display
 * @param {FirebaseFirestore.Firestore} [db]
 */
async function onJoinRequestDeclined(playerUserId, gameId, gameName, db) {
  return routeNotification({
    eventId:         randomUUID(),
    eventType:       'join_request_declined',
    recipientUserId: playerUserId,
    sourceId:        `join_request_declined_${gameId}_${playerUserId}`,
    data:            {
      game_id:   gameId,
      game_name: gameName,
    },
  }, db);
}

/**
 * Called when the round fills before a pending request could be approved.
 * Notifies the requesting player.
 *
 * @param {string} playerUserId - Player receiving the notification
 * @param {string} gameId - Game that filled
 * @param {string} gameName - Name of the game for display
 * @param {FirebaseFirestore.Firestore} [db]
 */
async function onRoundFilledBeforeApproval(playerUserId, gameId, gameName, db) {
  return routeNotification({
    eventId:         randomUUID(),
    eventType:       'join_request_round_filled',
    recipientUserId: playerUserId,
    sourceId:        `join_request_filled_${gameId}_${playerUserId}`,
    data:            {
      game_id:   gameId,
      game_name: gameName,
    },
  }, db);
}

/**
 * Called when a join request expires because the round has started.
 * Notifies the requesting player that their request was not reviewed in time.
 *
 * @param {string} playerUserId - Player receiving the notification
 * @param {string} gameId - Game that expired
 * @param {string} gameName - Name of the game for display
 * @param {FirebaseFirestore.Firestore} [db]
 */
async function onJoinRequestExpired(playerUserId, gameId, gameName, db) {
  return routeNotification({
    eventId:         randomUUID(),
    eventType:       'join_request_expired',
    recipientUserId: playerUserId,
    sourceId:        `join_request_expired_${gameId}_${playerUserId}`,
    data:            {
      game_id:   gameId,
      game_name: gameName,
    },
  }, db);
}

// ── Exports ───────────────────────────────────────────────────────────────────

module.exports = {
  onJoinRequestReceived,
  onJoinRequestApproved,
  onJoinRequestDeclined,
  onRoundFilledBeforeApproval,
  onJoinRequestExpired,
};
