# Notifications Settings - Complete Rebuild

## Overview
Complete rebuild of the Notifications Settings screen with hierarchical toggle logic, Game Alerts integration, and premium UX.

**Status:** ✅ Ready for testing and deployment

---

## What Changed

### 1. **Hierarchical Toggle Model (Fixed)**

**Before:** Conflicting toggle states, tri-state logic, unpredictable behavior

**After:** Clear master-submaster hierarchy
```
Push Notifications (MASTER)
├─ When OFF → disables Game Alerts & Chat Alerts sections
├─ When OFF → sets gameAlertsEnabled=false, chatAlertsEnabled=false
└─ Controls everything

  Game Alerts (SUBMASTER)
  ├─ Disabled when Push is OFF
  ├─ When enabled → links to Game Alerts detail page
  └─ Shows live summary of current filters

  Chat Alerts (SUBMASTER)
  ├─ Disabled when Push is OFF
  ├─ Single master toggle (no sub-toggles)
  └─ Simplified from Direct/Group to one toggle
```

### 2. **Game Alerts Filters (Rebuilt)**

**Before:** Old style tokens (money, vegas, competitive, for_fun, friends, member_discount)

**After:** Exact match with Create Game categories
- **Game Vibe:** Competitive, Casual
- **Stakes:** No Money, Low Stakes, High Stakes
- **Format:** Stroke Play, Match Play, Stableford
- **Handicap Use:** Gross, Net, Both (Gross + Net)
- **Courses:** Multi-select course picker
- **Special:** Games toggle, 2v2 toggle

All filters configured in dedicated Game Alerts detail page (game_alerts_page_widget.dart)

### 3. **Chat Alerts (Simplified)**

**Before:** enabled + direct + group (3 toggles)

**After:** enabled only (1 toggle)
- Removed Direct messages toggle
- Removed Group chats toggle
- Single master control

### 4. **Premium UI/UX**

**Added:**
- ✅ Card-like sections with fairway gradient
- ✅ Disabled sections with reduced opacity + pointer blocking
- ✅ Live summary in Game Alerts section
- ✅ Sticky bottom action bar (Save + Reset)
- ✅ Clear visual hierarchy and spacing
- ✅ Loading, success, and error states
- ✅ Navigate to Game Alerts detail page
- ✅ Permission handling integration

**Removed:**
- ❌ Old game style chips/pills
- ❌ Direct/Group chat sub-toggles
- ❌ Conflicting toggle states

---

## Files Changed

### Modified Files

#### 1. **`lib/models/notification_preferences.dart`**
- Simplified `NotificationGameAlerts` class (removed `styles` field)
- Simplified `NotificationChatAlerts` class (removed `direct` and `group` fields)
- Updated defaults (Game Alerts OFF by default)

**Old:**
```dart
class NotificationGameAlerts {
  final bool enabled;
  final List<String> styles; // ← REMOVED
}

class NotificationChatAlerts {
  final bool enabled;
  final bool direct;   // ← REMOVED
  final bool group;    // ← REMOVED
}
```

**New:**
```dart
class NotificationGameAlerts {
  final bool enabled; // Only toggle, filters in AlertSubscription
}

class NotificationChatAlerts {
  final bool enabled; // Single master toggle
}
```

#### 2. **`lib/notifications/notification_page/notification_page_widget_new.dart`**
- Complete rewrite of Notifications Settings screen
- Hierarchical toggle logic implemented
- Integration with Game Alerts detail page
- Sticky bottom bar with Save/Reset
- Premium UI with proper disabled states

### New Files (from previous implementation)

These files were created in the first implementation and are integrated here:

- `lib/models/alert_subscription.dart` - Alert subscription model with new schema
- `lib/services/alert_matcher.dart` - Matching logic
- `lib/services/alert_subscription_service.dart` - Firestore service
- `lib/notifications/game_alerts_page/game_alerts_page_widget.dart` - Detail page
- `firebase/functions/game_alerts.js` - Cloud Function with new matching

---

## Toggle Logic Specification

### Master: Push Notifications

**When toggled ON:**
- Enable push notifications
- Request system permission if needed
- Downstream toggles become interactive
- Does NOT automatically enable Game/Chat alerts

**When toggled OFF:**
- Disable push notifications
- Set `gameAlertsEnabled = false`
- Set `chatAlertsEnabled = false`
- Disable `alertSub.enabled = false`
- Gray out Game Alerts section (opacity 0.5, ignorePointer)
- Gray out Chat Alerts section (opacity 0.5, ignorePointer)

### Submaster: Game Alerts

**When toggled ON:**
- Set `gameAlerts.enabled = true`
- Set `alertSub.enabled = true` (in alertSubs collection)
- Show filter summary
- Show "Configure filters" button
- Clicking "Configure" → navigate to Game Alerts detail page

**When toggled OFF:**
- Set `gameAlerts.enabled = false`
- Set `alertSub.enabled = false`
- Keep filter selections stored (user can re-enable without re-configuring)
- Hide summary and configure button

**Disabled state (when Push is OFF):**
- Cannot interact with toggle
- Gray appearance
- Pointer events ignored

### Submaster: Chat Alerts

**When toggled ON:**
- Set `chatAlerts.enabled = true`

**When toggled OFF:**
- Set `chatAlerts.enabled = false`

**Disabled state (when Push is OFF):**
- Cannot interact with toggle
- Gray appearance
- Pointer events ignored

---

## Data Flow

### Notification Preferences (User Document)

Stored in `users/{userId}.notification_prefs`:
```javascript
{
  push_enabled: boolean,
  game_alerts: {
    enabled: boolean  // Just toggle state
  },
  chat_alerts: {
    enabled: boolean  // Just toggle state
  },
  quiet_hours: {
    enabled: boolean,
    start: "HH:MM",
    end: "HH:MM"
  },
  digest_mode: "instant" | "hourly" | "daily" | "off",
  muted_threads: [threadIds]
}
```

### Alert Subscription (alertSubs Collection)

Stored in `alertSubs/{userId}`:
```javascript
{
  userId: string,
  enabled: boolean,  // Synced with gameAlerts.enabled
  gameVibes: ['Competitive', 'Casual'],
  stakes: ['No Money', 'Low Stakes', 'High Stakes'],
  formats: ['Stroke Play', 'Match Play', 'Stableford'],
  handicapUses: ['Gross', 'Net', 'Both'],
  courses: [courseIds],
  special: {
    games: boolean,
    twoVTwo: boolean
  },
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### Save Flow

When user clicks "Save Settings":

1. **Save notification preferences** to `users/{userId}.notification_prefs`
2. **Save alert subscription** to `alertSubs/{userId}`
3. Both saved in parallel via `Future.wait()`
4. Show success message
5. Pop back to previous screen

### Reset Flow

When user clicks "Reset":

1. Show confirmation dialog
2. If confirmed:
   - Reset `NotificationPreferences` to defaults
   - Reset `AlertSubscription` to defaults
3. Mark as changed
4. User must click "Save" to persist

**Defaults:**
- Push enabled: `true`
- Game alerts enabled: `false`
- Chat alerts enabled: `true`
- All game alert filters: `[]` (empty)
- Quiet hours: disabled
- Digest mode: `instant`

---

## UI Structure

### Sections (in order)

1. **Header** - Description text
2. **Error Banner** (if any)
3. **Push Notifications** (MASTER)
   - Toggle: Enable push notifications
   - Permission status card (if permission denied)
4. **Game Alerts** (SUBMASTER)
   - Toggle: Enable game alerts
   - Summary: "Watching: Competitive • High Stakes • 2 courses"
   - Button: "Configure filters" → navigates to detail page
   - Disabled when Push is OFF
5. **Chat Alerts** (SUBMASTER)
   - Toggle: Enable chat alerts
   - Disabled when Push is OFF
6. **Quiet Hours**
   - Toggle + time pickers
7. **Digest Mode**
   - Chip selector (Instant/Hourly/Daily/Off)
8. **Muted Threads**
   - Navigation row (for future implementation)
9. **Sticky Bottom Bar**
   - Reset button (secondary)
   - Save Settings button (primary, disabled if no changes)

---

## Visual Design

### Card Sections
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.fairway.withValues(alpha: 0.2),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.1),
      width: 1.0,
    ),
  ),
)
```

### Disabled State
```dart
Opacity(
  opacity: 0.5,
  child: IgnorePointer(
    ignoring: true,
    child: /* section content */
  ),
)
```

### Toggle Switches
- Active: Sunset gold track, white thumb
- Inactive: Gray track (alpha: 0.2), semi-transparent thumb

### Sticky Bottom Bar
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.transparent,
        AppColors.fairwayDark.withValues(alpha: 0.95),
        AppColors.fairwayDark,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [0.0, 0.3, 1.0],
    ),
  ),
)
```

---

## Integration Guide

### Step 1: Replace Old Notification Page

**Option A: Direct replacement** (recommended)
```bash
# Backup old file
mv lib/notifications/notification_page/notification_page_widget.dart \
   lib/notifications/notification_page/notification_page_widget_old.dart

# Rename new file
mv lib/notifications/notification_page/notification_page_widget_new.dart \
   lib/notifications/notification_page/notification_page_widget.dart
```

**Option B: Keep both during testing**
- Keep old file as `notification_page_widget_old.dart`
- Use new file as `notification_page_widget.dart`
- Can easily rollback if needed

### Step 2: Update Navigation Routes

Ensure your navigation system includes both pages:
- `NotificationPageWidget` - Main settings (the one we just rebuilt)
- `GameAlertsPageWidget` - Detail page for filters

Routes are already defined in the widget files:
```dart
static String routeName = 'NotificationPage';
static String routePath = '/notificationPage';

static String routeName = 'GameAlertsPage';
static String routePath = '/gameAlertsPage';
```

### Step 3: Clean Up Old Data (Optional)

**Option A: Keep old alertSubs for reference**
- Old documents won't interfere (different schema)
- Can clean up later

**Option B: Delete old alertSubs**
```javascript
// In Firebase Console or via script
db.collection('alertSubs')
  .where('style', '!=', null)  // Old schema had 'style' field
  .get()
  .then(snapshot => {
    snapshot.docs.forEach(doc => doc.ref.delete());
  });
```

### Step 4: Update Cloud Functions

Follow the `INTEGRATION_GUIDE.md` in `firebase/functions/` to:
1. Add `const gameAlerts = require('./game_alerts');`
2. Replace old `sendGameCreatedNotifications` export
3. Deploy function

### Step 5: Test

Run through the test checklist below.

---

## Test Checklist

### Toggle Logic Tests

#### Test 1: Push Master Controls
- [ ] Open Notification Settings
- [ ] Verify: Push enabled by default
- [ ] Verify: Game Alerts section is interactive
- [ ] Verify: Chat Alerts section is interactive
- [ ] Toggle Push OFF
- [ ] Verify: Game Alerts section grayed out (opacity 0.5)
- [ ] Verify: Chat Alerts section grayed out (opacity 0.5)
- [ ] Try to toggle Game Alerts (should not work - pointer ignored)
- [ ] Try to toggle Chat Alerts (should not work - pointer ignored)
- [ ] Toggle Push ON
- [ ] Verify: Sections become interactive again

#### Test 2: Game Alerts Toggle
- [ ] Ensure Push is ON
- [ ] Toggle Game Alerts ON
- [ ] Verify: Summary line appears
- [ ] Verify: "Configure filters" button appears
- [ ] Toggle Game Alerts OFF
- [ ] Verify: Summary disappears
- [ ] Verify: Configure button disappears
- [ ] Toggle ON again
- [ ] Tap "Configure filters"
- [ ] Verify: Navigate to Game Alerts detail page

#### Test 3: Chat Alerts Toggle
- [ ] Ensure Push is ON
- [ ] Toggle Chat Alerts ON
- [ ] Verify: Toggle state changes
- [ ] Toggle Chat Alerts OFF
- [ ] Verify: Toggle state changes
- [ ] Verify: No sub-toggles visible (Direct/Group removed)

### Data Persistence Tests

#### Test 4: Save Settings
- [ ] Make changes to several toggles
- [ ] Verify: Save button becomes enabled (not grayed)
- [ ] Tap "Save Settings"
- [ ] Verify: Loading indicator (if visible)
- [ ] Verify: Success message shown
- [ ] Verify: Navigate back automatically
- [ ] Navigate back to Notification Settings
- [ ] Verify: Changes persisted

#### Test 5: Discard Changes
- [ ] Make changes to several toggles
- [ ] Tap back button WITHOUT saving
- [ ] Navigate back to Notification Settings
- [ ] Verify: Changes discarded, old values restored

#### Test 6: Reset to Defaults
- [ ] Configure some settings
- [ ] Tap "Reset"
- [ ] Verify: Confirmation dialog appears
- [ ] Tap "Cancel"
- [ ] Verify: No changes
- [ ] Tap "Reset" again
- [ ] Tap "Reset" (confirm)
- [ ] Verify: Push ON, Game Alerts OFF, Chat Alerts ON
- [ ] Tap "Save Settings"
- [ ] Verify: Defaults saved to Firestore

### Integration Tests

#### Test 7: Game Alerts Detail Page
- [ ] Enable Push and Game Alerts
- [ ] Tap "Configure filters"
- [ ] Verify: Navigate to Game Alerts page
- [ ] Select some filters
- [ ] Tap "Save Settings"
- [ ] Verify: Navigate back to main settings
- [ ] Verify: Summary updated with selected filters

#### Test 8: Permission Handling
- [ ] System Settings: Deny notification permission
- [ ] Open Notification Settings
- [ ] Verify: Orange permission card shown
- [ ] Tap "Open Settings"
- [ ] Verify: Navigate to system settings
- [ ] Grant permission
- [ ] Return to app
- [ ] Refresh/reload page
- [ ] Verify: Permission card disappears

### Edge Cases

#### Test 9: Offline Mode
- [ ] Disconnect from internet
- [ ] Make changes
- [ ] Tap "Save Settings"
- [ ] Verify: Error message (cannot save offline)
- [ ] Reconnect
- [ ] Tap "Save Settings" again
- [ ] Verify: Success

#### Test 10: Push OFF → Enable Game Alerts
- [ ] Set Push OFF
- [ ] Try to enable Game Alerts (should be blocked)
- [ ] Enable Push
- [ ] Enable Game Alerts
- [ ] Tap "Configure filters"
- [ ] Configure some filters
- [ ] Save
- [ ] Return to main settings
- [ ] Turn Push OFF
- [ ] Verify: Game Alerts section disabled
- [ ] Verify: Save updates gameAlerts.enabled = false AND alertSub.enabled = false

#### Test 11: Firestore Verification
- [ ] Configure Game Alerts with specific filters
- [ ] Save
- [ ] Check Firestore `users/{userId}.notification_prefs`
- [ ] Verify: `game_alerts.enabled` matches toggle state
- [ ] Verify: `chat_alerts.enabled` matches toggle state
- [ ] Check Firestore `alertSubs/{userId}`
- [ ] Verify: `enabled` matches Game Alerts toggle
- [ ] Verify: Filter arrays match configuration

---

## Migration Notes

### From Old System

**Old notification preferences structure:**
```javascript
game_alerts: {
  enabled: boolean,
  styles: ['money', 'vegas', 'competitive', ...]
}

chat_alerts: {
  enabled: boolean,
  direct: boolean,
  group: boolean
}
```

**New notification preferences structure:**
```javascript
game_alerts: {
  enabled: boolean  // Just toggle
}

chat_alerts: {
  enabled: boolean  // Just toggle
}
```

**Migration:**
- Old `styles` field → ignored, moved to `alertSubs` collection
- Old `direct` and `group` → merged into single `enabled`
- No automatic migration needed (users reconfigure)

### Data Cleanup

**Recommended:**
1. Deploy new code
2. Test with a few users
3. After confirming it works:
   - Delete old alertSubs documents (with `style` field)
   - Optional: Clean up old `notification_prefs.game_alerts.styles` fields

---

## Known Limitations

### 1. Chat Alert Sub-Types Removed
**Before:** Could enable/disable Direct messages and Group chats separately
**After:** Single toggle for all chat alerts
**Impact:** Users who wanted different settings for Direct vs Group need to use Muted Threads

**Workaround:** Mute individual group chats in the Muted Threads section

### 2. Migration Not Automatic
**Before:** Old style-based alert subscriptions
**After:** Category-based alert subscriptions
**Impact:** Users must reconfigure their Game Alerts
**Workaround:** None - this is by design (no backward compatibility required)

---

## Future Enhancements

### 1. Smart Defaults for Game Alerts
When user first enables Game Alerts, could auto-populate some sensible defaults based on:
- User's game history
- Popular settings in their area
- User's profile preferences

### 2. Quick Filters
Add preset filter combinations:
- "Competitive player" → Competitive + High Stakes + any format
- "Casual rounds" → Casual + No Money + any format
- "My usual game" → based on user's most-played settings

### 3. Notification Preview
Before saving, show user an example notification:
"You'll be notified for games like: Competitive Stroke Play at Pebble Beach"

### 4. Analytics
Track:
- Most common filter combinations
- Enable/disable patterns
- Which filters lead to most matches

---

## Summary of Changes

✅ **Fixed:** Hierarchical toggle logic (Push > Game/Chat)
✅ **Fixed:** Eliminated conflicting toggle states
✅ **Rebuilt:** Game Alerts filters to match Create Game exactly
✅ **Simplified:** Chat Alerts (single toggle)
✅ **Added:** Premium UI with disabled states
✅ **Added:** Live summary for Game Alerts
✅ **Added:** Sticky bottom bar (Save/Reset)
✅ **Added:** Proper loading/error states
✅ **Updated:** NotificationPreferences model (simplified)
✅ **Integrated:** Game Alerts detail page navigation

**Files created/modified:** 2 models, 2 pages, 1 service, comprehensive docs

**Ready for:**
1. Code review
2. QA testing (use checklist above)
3. Deployment
4. User testing

---

## Questions & Troubleshooting

### Q: What happens to old alertSubs documents?
**A:** They remain in Firestore but are not used. New Cloud Function only queries documents with the new schema. You can delete them after confirming the new system works.

### Q: Can users still get notifications if they disable Game Alerts?
**A:** No. When Game Alerts is OFF, `alertSub.enabled = false`, so the matching function skips them.

### Q: What if Push is ON but Game Alerts is OFF?
**A:** User can still receive chat notifications (if Chat Alerts is ON), but no game notifications.

### Q: Does Reset button require confirmation?
**A:** Yes, it shows a dialog explaining what will be reset before proceeding.

### Q: Can I test without deploying Cloud Functions?
**A:** Yes, you can test all UI/UX and toggle logic. Cloud Function only affects actual game notification delivery.

---

**Implementation completed**
**Ready for deployment**
**Date:** 2026-02-06
