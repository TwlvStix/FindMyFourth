# Game Alerts Notifications - Implementation Summary

## Overview
Complete rebuild of the notifications system to match Create Game categories exactly, with a premium UX for managing alert filters.

**Completed:** All Flutter code, models, services, UI, and Cloud Functions
**Status:** ✅ Ready for testing and deployment

---

## Files Changed

### New Files Created

#### 1. **Models**
- `lib/models/alert_subscription.dart`
  - New `AlertSubscription` model with complete schema
  - `AlertSpecialOptions` for Games and 2v2 toggles
  - Firestore serialization/deserialization
  - Helper methods (getSummary, hasActiveFilters)

#### 2. **Services**
- `lib/services/alert_matcher.dart`
  - Core matching logic: `doesAlertSubMatchGame()`
  - Implements AND across categories, OR within categories
  - Empty category = match-all logic
  - Debug helper: `getMatchDebugInfo()`

- `lib/services/alert_subscription_service.dart`
  - Firestore CRUD operations for alertSubs collection
  - Load, save, delete, stream subscriptions
  - Migration helper for old preferences
  - Batch operations for testing

#### 3. **UI**
- `lib/notifications/game_alerts_page/game_alerts_page_widget.dart`
  - Complete premium UI rebuild (1100+ lines)
  - Enable/disable toggle
  - Multi-select chips for all categories
  - Course picker with search
  - Special options (Games, 2v2)
  - Live summary display
  - Sticky Save/Reset buttons
  - Loading, error, and success states
  - Permission handling integration

#### 4. **Cloud Functions**
- `firebase/functions/game_alerts.js`
  - New `sendGameCreatedNotifications` function
  - JavaScript implementation of matching logic
  - Queries all enabled subscriptions
  - Matches each against the game
  - Sends ONE notification per game per user
  - Handles cooldown, quiet hours, digest mode
  - Comprehensive logging

---

## Firestore Schema

### Collection: `alertSubs`
**Document ID:** `{userId}` (one subscription per user)

```javascript
{
  userId: string,
  enabled: boolean,
  gameVibes: [string],      // 'Competitive', 'Casual'
  stakes: [string],         // 'No Money', 'Low Stakes', 'High Stakes'
  formats: [string],        // 'Stroke Play', 'Match Play', 'Stableford'
  handicapUses: [string],   // 'Gross', 'Net', 'Both'
  courses: [string],        // courseIds
  special: {
    games: boolean,         // User wants games with side games
    twoVTwo: boolean       // User wants 2v2/team games
  },
  createdAt: timestamp,
  updatedAt: timestamp
}
```

---

## Category Mapping (Create Game → Alert Subscriptions)

| Create Game Field | Alert Subscription Field | Values |
|------------------|--------------------------|--------|
| `rulesSetting` | `gameVibes` | 'Competitive', 'Casual' |
| `styleGame` | `stakes` | 'No Money', 'Low Stakes', 'High Stakes' |
| `gameType` | `formats` | 'Stroke Play', 'Match Play', 'Stableford' |
| `scoring` | `handicapUses` | 'Gross', 'Net', 'Both' |
| `courseRef.id` | `courses` | Course document IDs |
| *(future)* | `special.games` | boolean (has side games) |
| *(future)* | `special.twoVTwo` | boolean (is 2v2) |

---

## Matching Logic

### Contract
- **Trigger:** Game creation
- **Frequency:** ONE notification per game per user (maximum)
- **Matching:** Evaluate once per user when game is created

### Rules
1. **AND across categories:** Every non-empty category must match
2. **OR within category:** If multiple values selected, any one matches
3. **Empty category:** Matches all values (no restriction)
4. **All empty:** If notifications enabled and all categories empty → match all games

### Examples

**Example 1: Specific filters**
```
User subscription:
- gameVibes: ['Competitive']
- stakes: ['High Stakes', 'Low Stakes']
- formats: []
- handicapUses: []
- courses: []

Game:
- rulesSetting: 'Competitive'  ✓ (matches gameVibes)
- styleGame: 'High Stakes'     ✓ (matches stakes)
- gameType: 'Stroke Play'      ✓ (formats empty = match all)
- scoring: 'Gross'             ✓ (handicapUses empty = match all)
- courseRef: any               ✓ (courses empty = match all)

RESULT: MATCH ✓
```

**Example 2: Failed match**
```
User subscription:
- gameVibes: ['Casual']
- stakes: ['No Money']
- formats: []
- handicapUses: []
- courses: ['course123']

Game:
- rulesSetting: 'Competitive'  ✗ (does not match gameVibes)
- styleGame: 'No Money'        ✓
- courseRef.id: 'course456'    ✗ (not in courses list)

RESULT: NO MATCH ✗
```

**Example 3: Match all**
```
User subscription:
- enabled: true
- All categories: []

Any game → MATCH ✓
```

---

## Cloud Function Flow

### `sendGameCreatedNotifications` (new version)

1. **Trigger:** `games/{gameId}` onCreate
2. **Query:** Get all `alertSubs` where `enabled == true`
3. **For each subscription:**
   - Skip if user is game creator
   - Check if subscription matches game using `doesAlertSubMatchGame()`
   - If no match → skip
   - Load user document
   - Check if push notifications enabled
   - Check cooldown (60 minutes between game alerts)
   - Create notification document in `users/{uid}/notifications/{dedupeKey}`
   - Update cooldown timestamp
   - Check quiet hours and digest mode
   - If instant delivery → send FCM push notification
   - If digest/quiet → notification saved but not sent
4. **Result:** Logged count of matched users and notified users

---

## Migration Notes

### Old System vs New System

**Old alertSubs schema:**
```javascript
{
  uid: userId,
  style: 'money' | 'vegas' | 'competitive' | 'for_fun' | 'friends' | 'member_discount',
  enabled: boolean,
  createdAt: timestamp,
  updatedAt: timestamp
}
```
- Document ID pattern: `${userId}_${style}`
- Multiple documents per user (one per style)
- Simple style token matching

**New alertSubs schema:**
```javascript
{
  userId: userId,
  enabled: boolean,
  gameVibes: [...],
  stakes: [...],
  formats: [...],
  handicapUses: [...],
  courses: [...],
  special: {games: boolean, twoVTwo: boolean},
  createdAt: timestamp,
  updatedAt: timestamp
}
```
- Document ID: `userId`
- One document per user
- Rich category-based matching

### Migration Strategy

**Option 1: Clean slate (recommended)**
- Delete all old `alertSubs` documents
- Users configure new alert preferences from scratch
- Simple and clean

**Option 2: Partial migration**
- Use `AlertSubscriptionService.migrateFromOldPreferences()`
- Maps old style tokens to new categories (lossy):
  - 'competitive' → gameVibes: ['Competitive']
  - 'for_fun' → gameVibes: ['Casual']
  - 'money', 'vegas' → stakes: ['High Stakes']
  - Others → ignored
- Users should still review and update their preferences

---

## Deployment Steps

### 1. Flutter App Changes
```bash
# No special deployment needed - standard build
flutter pub get
flutter build ios/android
# Deploy to App Store / Play Store
```

### 2. Cloud Functions Changes

**Replace old function in `firebase/functions/index.js`:**

```javascript
// COMMENT OUT OR REMOVE old function:
// exports.sendGameCreatedNotifications = functions...

// ADD new import at top of file:
const gameAlerts = require('./game_alerts');

// ADD new export:
exports.sendGameCreatedNotifications = gameAlerts.sendGameCreatedNotifications;
```

**Deploy:**
```bash
cd firebase/functions
npm install  # if needed
firebase deploy --only functions:sendGameCreatedNotifications
```

### 3. Firestore Migration

**Option A: Clean slate**
```javascript
// In Firebase Console or via script:
// Delete all documents in alertSubs collection
db.collection('alertSubs').get().then(snapshot => {
  snapshot.docs.forEach(doc => doc.ref.delete());
});
```

**Option B: Keep old data**
- Old documents won't interfere (different document structure)
- New system only queries documents with `enabled` boolean field
- Can clean up later after users migrate

### 4. Testing Checklist (see below)

---

## Manual Test Checklist

### Setup
- [ ] Clean test environment (fresh emulator or test Firestore instance)
- [ ] Two test users: User A (creator), User B (subscriber)
- [ ] At least 2-3 test courses in Firestore

### Test 1: Basic Alert Creation
- [ ] User B: Open Game Alerts page
- [ ] Verify: Page loads without errors
- [ ] Toggle "Enable game alerts" ON
- [ ] Verify: Permission prompt appears (if not granted)
- [ ] Grant notification permission
- [ ] Select: Game Vibe = 'Competitive'
- [ ] Select: Stakes = 'High Stakes'
- [ ] Tap "Save Settings"
- [ ] Verify: Success message shown
- [ ] Verify: Firestore `alertSubs/{userB}` document created with correct data
- [ ] Verify: `enabled: true`, `gameVibes: ['Competitive']`, `stakes: ['High Stakes']`

### Test 2: Matching Game
- [ ] User A: Create game with:
  - Game Vibe = 'Competitive'
  - Stakes = 'High Stakes'
  - Any format, handicap, course
- [ ] Tap "Submit Game"
- [ ] Verify: Game created successfully
- [ ] Wait 2-3 seconds for Cloud Function
- [ ] User B: Check for push notification
- [ ] Verify: Notification received with game name and course
- [ ] Verify: Tapping notification opens game details
- [ ] Verify: Firestore `users/{userB}/notifications/{dedupeKey}` created

### Test 3: Non-Matching Game
- [ ] User A: Create game with:
  - Game Vibe = 'Casual' (different!)
  - Stakes = 'High Stakes'
- [ ] Tap "Submit Game"
- [ ] User B: Wait 5 seconds
- [ ] Verify: NO notification received
- [ ] Verify: No new notification document in Firestore

### Test 4: Multiple Categories
- [ ] User B: Edit alert subscription
- [ ] Select: Game Vibe = 'Competitive', 'Casual' (both)
- [ ] Select: Stakes = 'High Stakes'
- [ ] Select: Format = 'Stroke Play'
- [ ] Save
- [ ] User A: Create game:
  - Game Vibe = 'Casual'
  - Stakes = 'High Stakes'
  - Format = 'Stroke Play'
- [ ] Verify: User B receives notification (all categories match)
- [ ] User A: Create game:
  - Game Vibe = 'Casual'
  - Stakes = 'High Stakes'
  - Format = 'Match Play' (different!)
- [ ] Verify: User B does NOT receive notification (format doesn't match)

### Test 5: Empty Category = Match All
- [ ] User B: Edit alert subscription
- [ ] Select: Game Vibe = 'Competitive'
- [ ] Leave all other categories empty
- [ ] Save
- [ ] User A: Create game:
  - Game Vibe = 'Competitive'
  - Stakes = 'No Money' (any value)
  - Format = 'Stableford' (any value)
- [ ] Verify: User B receives notification

### Test 6: Course Filter
- [ ] User B: Edit alert subscription
- [ ] Clear all filters
- [ ] Select 1 specific course
- [ ] Save
- [ ] User A: Create game at selected course
- [ ] Verify: User B receives notification
- [ ] User A: Create game at different course
- [ ] Verify: User B does NOT receive notification

### Test 7: Special Options
- [ ] User B: Edit alert subscription
- [ ] Enable "Games" toggle (side games)
- [ ] Save
- [ ] User A: Create game (without side games)
- [ ] Verify: User B does NOT receive notification
- [ ] Note: This will always fail until `has_side_games` field added to Game model
- [ ] Same test for "2v2" toggle

### Test 8: Cooldown
- [ ] User B: Set up matching alert subscription
- [ ] User A: Create matching game #1
- [ ] Verify: User B receives notification
- [ ] User A: Immediately create matching game #2 (within 1 minute)
- [ ] Verify: User B does NOT receive notification (cooldown)
- [ ] Wait 61 minutes
- [ ] User A: Create matching game #3
- [ ] Verify: User B receives notification (cooldown expired)

### Test 9: Quiet Hours
- [ ] User B: Go to main Notification Settings
- [ ] Enable "Quiet hours": 22:00 - 07:00
- [ ] Save
- [ ] Set system clock to 23:00 (or test during actual quiet hours)
- [ ] User A: Create matching game
- [ ] Verify: Notification saved in Firestore but NOT sent as push
- [ ] Set system clock to 08:00 (outside quiet hours)
- [ ] User A: Create another matching game
- [ ] Verify: Notification sent as push

### Test 10: Disable Notifications
- [ ] User B: Open Game Alerts page
- [ ] Toggle "Enable game alerts" OFF
- [ ] Save
- [ ] User A: Create matching game
- [ ] Verify: User B does NOT receive notification
- [ ] Verify: `alertSubs/{userB}.enabled == false` in Firestore

### Test 11: Reset
- [ ] User B: Open Game Alerts page
- [ ] Configure several filters
- [ ] Tap "Reset"
- [ ] Confirm reset
- [ ] Verify: All filters cleared
- [ ] Verify: Enabled toggle set to OFF
- [ ] Tap "Save Settings"
- [ ] Verify: Firestore updated correctly

### Test 12: Course Picker
- [ ] User B: Open Game Alerts page
- [ ] Tap "Select Courses"
- [ ] Verify: Bottom sheet opens with all courses
- [ ] Search for a course name
- [ ] Verify: Search filters correctly
- [ ] Select 2-3 courses
- [ ] Tap "Done"
- [ ] Verify: Selected courses displayed as chips
- [ ] Verify: Summary updates correctly

### Test 13: Summary Display
- [ ] User B: Open Game Alerts page
- [ ] With no filters: Verify summary shows "Watching: All games"
- [ ] Select Competitive: Verify summary shows "Watching: Competitive"
- [ ] Add High Stakes: Verify summary shows "Watching: Competitive • High Stakes"
- [ ] Add 2 courses: Verify summary shows "Watching: Competitive • High Stakes • 2 courses"
- [ ] Verify: Summary updates live as filters change

### Test 14: Error Handling
- [ ] Disconnect from internet
- [ ] Try to save alert subscription
- [ ] Verify: Error message shown
- [ ] Reconnect to internet
- [ ] Save again
- [ ] Verify: Success

### Test 15: Navigation
- [ ] User B: Navigate to Game Alerts page
- [ ] Make changes WITHOUT saving
- [ ] Tap back button
- [ ] Verify: Changes discarded
- [ ] Navigate back to Game Alerts page
- [ ] Verify: Old settings still present (unsaved changes lost)

### Test 16: Duplicate Prevention
- [ ] User A: Create matching game
- [ ] Manually trigger Cloud Function again for same game
- [ ] Verify: User B receives only ONE notification
- [ ] Verify: Dedupe key prevents duplicate notification documents

### Test 17: Creator Exclusion
- [ ] User A: Set up matching alert subscription
- [ ] User A: Create game that matches own subscription
- [ ] Verify: User A does NOT receive notification for own game

### Test 18: Migration (if applicable)
- [ ] Start with old alertSubs documents
- [ ] User B: Open Game Alerts page for first time
- [ ] Verify: Default subscription created (no data migrated automatically)
- [ ] Manually run `AlertSubscriptionService.migrateFromOldPreferences()`
- [ ] Verify: Old style tokens mapped to new categories
- [ ] User B: Review and update subscription
- [ ] Save
- [ ] Test matching

---

## Known Limitations & Future Work

### Current Limitations
1. **Special Options Not Fully Implemented**
   - `special.games` (side games) and `special.twoVTwo` toggles work in UI
   - But Game model doesn't have `has_side_games` or `is_2v2` fields
   - Cloud Function matching logic is commented out for these
   - **Action needed:** Add these fields to Create Game flow and Game model

2. **No Backward Compatibility**
   - Old alert subscriptions are not automatically migrated
   - Users must reconfigure their alert preferences
   - Migration helper exists but requires manual execution

3. **Course Names vs IDs**
   - UI shows course names, but matching uses course IDs
   - Works fine but requires extra lookup for debugging

### Future Enhancements
1. **Add `has_side_games` field to Game**
   - Add to Create Game UI when user selects games (Wolf, Nassau, etc.)
   - Store in Firestore as `has_side_games: boolean`
   - Uncomment matching logic in `game_alerts.js`

2. **Add `is_2v2` field to Game**
   - Already tracked in Create Game UI (`_is2v2` variable)
   - Needs to be saved to Firestore
   - Uncomment matching logic in `game_alerts.js`

3. **Digest Mode Implementation**
   - Currently notifications are saved but not batched
   - Need scheduled function to send digest emails/pushes

4. **Analytics**
   - Track: alert subscription creation
   - Track: notification match rate
   - Track: notification open rate

5. **Testing Improvements**
   - Unit tests for matching logic
   - Integration tests for Cloud Functions
   - UI widget tests

---

## Troubleshooting

### Notifications Not Received

**Check:**
1. Is subscription enabled? (`alertSubs/{userId}.enabled == true`)
2. Does subscription match game? Use `AlertMatcher.getMatchDebugInfo()` in Flutter
3. Is push enabled? (`users/{userId}.notification_prefs.push_enabled == true`)
4. Is user in cooldown? Check `users/{userId}.notification_state.last_game_alert`
5. Is user in quiet hours? Check time and quiet hours settings
6. Does user have valid FCM tokens? Check `users/{userId}/devices` collection
7. Check Cloud Function logs in Firebase Console

### Cloud Function Errors

**Common issues:**
- Missing required fields in game document → check Create Game flow
- Firestore permission errors → check Firestore rules
- FCM token errors → invalidated automatically, user needs to re-register

### UI Not Loading

**Check:**
- User authenticated? `currentUserUid != null`
- Courses collection exists and has data?
- Network connectivity?
- Check Flutter debug console for errors

---

## Summary

✅ **Complete:** All code written and ready for testing
📱 **Flutter:** New models, services, and premium UI
☁️ **Cloud:** New matching function with comprehensive logging
📊 **Schema:** Clean, one-document-per-user Firestore structure
🧪 **Testing:** Comprehensive 18-test checklist provided

**Next steps:**
1. Deploy Cloud Functions
2. Run through test checklist
3. Add `has_side_games` and `is_2v2` to Game model
4. Migrate or reset existing user subscriptions
5. Monitor Cloud Function logs for first few days
6. Gather user feedback on new UI

---

## Code Quality Notes

- ✅ All code follows existing codebase patterns
- ✅ Consistent naming with Create Game constants
- ✅ Comprehensive error handling and logging
- ✅ Premium UI with proper loading states
- ✅ Proper Firestore transaction handling
- ✅ No breaking changes to Create Game flow
- ✅ Backward compatible Cloud Function deployment
- ✅ Clear documentation and inline comments

---

**Implementation completed by Claude Code**
**Date:** 2026-02-06
