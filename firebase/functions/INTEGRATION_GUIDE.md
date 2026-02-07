# Cloud Functions Integration Guide

## Integrating New Game Alerts Function

To activate the new Game Alerts notification system, you need to update `index.js` to use the new function.

---

## Step 1: Update `index.js`

Add this at the **top** of `firebase/functions/index.js` (after existing requires):

```javascript
// New Game Alerts system
const gameAlerts = require('./game_alerts');
```

---

## Step 2: Replace Old Function

Find the old `sendGameCreatedNotifications` export (around line 357) and **comment it out**:

```javascript
// OLD FUNCTION - COMMENTED OUT
// exports.sendGameCreatedNotifications = functions
//   .region("us-west2")
//   .runWith(kPushNotificationRuntimeOpts)
//   .firestore.document("games/{gameId}")
//   .onCreate(async (snapshot, context) => {
//     ... (keep commented for reference)
//   });
```

---

## Step 3: Add New Export

Add this line after the commented-out old function:

```javascript
// NEW GAME ALERTS SYSTEM
exports.sendGameCreatedNotifications = gameAlerts.sendGameCreatedNotifications;
```

---

## Step 4: Optional - Remove Old Sync Function

The old `syncNotificationPreferencesToAlertSubs` function (around line 554) is no longer needed since we're using the new alertSubs schema directly.

**You can either:**

**Option A: Comment it out**
```javascript
// OLD SYNC FUNCTION - NO LONGER NEEDED
// exports.syncNotificationPreferencesToAlertSubs = functions...
```

**Option B: Keep it**
- It won't interfere with the new system
- Can remove in future cleanup

---

## Complete Example

Here's what the relevant section of `index.js` should look like:

```javascript
// ... existing code ...

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// ... existing constants and helpers ...

// NEW GAME ALERTS SYSTEM
const gameAlerts = require('./game_alerts');

// ... existing functions ...

// OLD FUNCTION - COMMENTED OUT (for reference)
// exports.sendGameCreatedNotifications = functions
//   .region("us-west2")
//   .runWith(kPushNotificationRuntimeOpts)
//   .firestore.document("games/{gameId}")
//   .onCreate(async (snapshot, context) => {
//     ... old code ...
//   });

// NEW GAME ALERTS SYSTEM
exports.sendGameCreatedNotifications = gameAlerts.sendGameCreatedNotifications;

// OLD SYNC FUNCTION - NO LONGER NEEDED (optional to comment out)
// exports.syncNotificationPreferencesToAlertSubs = functions
//   .region("us-west2")
//   .firestore.document("users/{userId}")
//   .onWrite(async (change, context) => {
//     ... old code ...
//   });

// ... rest of existing functions ...
```

---

## Step 5: Deploy

```bash
cd firebase/functions

# Install dependencies (if needed)
npm install

# Deploy only the game notifications function
firebase deploy --only functions:sendGameCreatedNotifications

# Or deploy all functions
firebase deploy --only functions
```

---

## Testing the Integration

### 1. Check Deployment
```bash
firebase functions:log --only sendGameCreatedNotifications
```

### 2. Create Test Game
- Log in as User A
- Create a new game
- Check Firebase Functions logs

### 3. Expected Log Output
```
[GameAlerts] New game created: abc123
[GameAlerts] Game data: {...}
[GameAlerts] Found 5 enabled subscriptions
[GameAlerts] Subscription user456 matches game abc123
[GameAlerts] Sent push notification to user456, success: 1/1
[GameAlerts] Game abc123 complete: 1 matched, 1 notified
```

### 4. Check Firestore
- `alertSubs/{userId}` documents should be queried
- `users/{userId}/notifications/{dedupeKey}` should be created
- `users/{userId}.notification_state.last_game_alert` should be updated

---

## Rollback Plan

If you need to rollback to the old system:

### 1. Uncomment Old Function
```javascript
exports.sendGameCreatedNotifications = functions
  .region("us-west2")
  .runWith(kPushNotificationRuntimeOpts)
  .firestore.document("games/{gameId}")
  .onCreate(async (snapshot, context) => {
    // ... original code ...
  });
```

### 2. Comment Out New Function
```javascript
// exports.sendGameCreatedNotifications = gameAlerts.sendGameCreatedNotifications;
```

### 3. Redeploy
```bash
firebase deploy --only functions:sendGameCreatedNotifications
```

---

## Common Issues

### Issue: "Cannot find module './game_alerts'"
**Solution:** Make sure `game_alerts.js` is in the same directory as `index.js`

### Issue: Function not triggering
**Solution:**
- Check Firebase Console > Functions for errors
- Verify the function was deployed: `firebase functions:list`
- Check Firestore trigger is correct: `games/{gameId}` onCreate

### Issue: No logs appearing
**Solution:**
- Check Firebase Console > Functions > Logs
- Verify logging is enabled for your project
- Use `firebase functions:log` command

### Issue: Old alertSubs documents not working
**Solution:**
- Old schema had `uid` and `style` fields
- New schema has `userId`, `enabled`, and category arrays
- You need to migrate or reset user subscriptions (see GAME_ALERTS_IMPLEMENTATION.md)

---

## Next Steps

After successful integration:

1. ✅ Run through Manual Test Checklist (see GAME_ALERTS_IMPLEMENTATION.md)
2. ✅ Monitor logs for first 24-48 hours
3. ✅ Clean up old alertSubs documents (migration)
4. ✅ Add `has_side_games` and `is_2v2` to Game model
5. ✅ Uncomment special options matching in `game_alerts.js`
6. ✅ Consider removing old `syncNotificationPreferencesToAlertSubs` function

---

**Questions or issues?** Check the main implementation doc: `GAME_ALERTS_IMPLEMENTATION.md`
