# Notification Settings - Troubleshooting Guide

## Issue: "Failed to load settings" Error

If you're seeing "Failed to load settings" on the Notification Settings page, follow these steps to diagnose and fix the issue.

---

## Quick Fixes Applied

### 1. Enhanced Error Handling
✅ Added comprehensive debug logging
✅ Graceful fallback to default settings if loading fails
✅ Better error messages showing what actually failed
✅ Retry button to reload settings

### 2. Fixed Default Values
✅ Changed `pushEnabled` default from `false` to `true`
✅ Matches requirements: Push ON, Game Alerts OFF, Chat Alerts ON

### 3. Improved Error Display
✅ Shows the actual error message
✅ Provides a Retry button
✅ Visual error icon and formatting

---

## Diagnostic Steps

### Step 1: Check Debug Console

Run the app and navigate to Notification Settings. Check the debug console for logs:

```
[NotificationSettings] Loading data for user: <userId>
[NotificationSettings] Loading notification prefs...
[NotificationSettings] User doc exists: true/false
[NotificationSettings] User data keys: [...]
[NotificationSettings] Prefs data exists: true/false
[NotificationSettings] Loaded notification prefs: {...}
[NotificationSettings] Loaded alert subscription: exists/null
[NotificationSettings] Successfully loaded all settings
```

If you see an error, it will show:
```
[NotificationSettings] Error loading prefs, using defaults: <error>
[NotificationSettings] Error loading alert sub, using defaults: <error>
```

### Step 2: Verify User Authentication

The most common issue is the user not being authenticated properly.

**Check:**
```dart
print('currentUserUid: $currentUserUid');
print('currentUserReference: $currentUserReference');
```

**Expected:**
- `currentUserUid` should be a non-null string (user ID)
- `currentUserReference` should be a Firestore DocumentReference

**If null:**
- User is not authenticated
- Sign in again
- Check Firebase Auth configuration

### Step 3: Check Firestore Structure

Verify your Firestore structure:

#### User Document
```
users/{userId}
  └─ notification_prefs: {
       push_enabled: boolean,
       game_alerts: {
         enabled: boolean
       },
       chat_alerts: {
         enabled: boolean
       },
       quiet_hours: {...},
       digest_mode: "instant",
       muted_threads: []
     }
```

#### Alert Subscription Document
```
alertSubs/{userId}
  └─ {
       userId: string,
       enabled: boolean,
       gameVibes: [],
       stakes: [],
       formats: [],
       handicapUses: [],
       courses: [],
       special: {
         games: false,
         twoVTwo: false
       }
     }
```

### Step 4: Check Firestore Rules

Ensure users can read their own documents:

```javascript
// Firestore Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can read their own notification prefs
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Users can read/write their own alert subscriptions
    match /alertSubs/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Step 5: Test with Fresh User

If the issue persists, test with a brand new user account:

1. Create a new test user
2. Sign in
3. Navigate to Notification Settings
4. Should see defaults (Push ON, Game Alerts OFF, Chat Alerts ON)
5. Configure settings
6. Save
7. Navigate away and back
8. Verify settings persisted

---

## Common Error Messages

### Error: "User not authenticated"

**Cause:** `currentUserUid` is null

**Fix:**
1. Ensure user is signed in
2. Check Firebase Auth initialization
3. Verify `currentUserUid` is set after sign-in

### Error: "Could not load settings. Using defaults."

**Cause:** Exception during data loading

**Fix:**
1. Check debug logs for specific error
2. Verify Firestore rules allow read access
3. Verify user document exists
4. If this is a new user, the app will create defaults automatically

### Error: "permission-denied"

**Cause:** Firestore security rules blocking access

**Fix:**
1. Check Firestore rules (see Step 4 above)
2. Ensure user ID matches authenticated user
3. Verify rules are deployed

### Error: "not-found"

**Cause:** User document or alertSubs document doesn't exist

**Fix:**
- This is normal for new users
- The app will use defaults
- Tap "Save Settings" to create the documents

---

## Expected Behavior

### For New Users (No Data)
1. Page loads with defaults:
   - Push Notifications: ON
   - Game Alerts: OFF
   - Chat Alerts: ON
   - Quiet Hours: OFF
   - Digest Mode: Instant
2. No error message shown
3. User can configure and save

### For Existing Users (Has Data)
1. Page loads with saved settings
2. No error message shown
3. User can modify and save

### For Users with Loading Errors
1. Page shows error message with details
2. "Retry" button available
3. Falls back to defaults if retry fails
4. User can still configure and save (will create new data)

---

## Manual Fix: Create Default Documents

If loading continues to fail, manually create the documents in Firestore:

### 1. Create notification_prefs in User Document

```javascript
// In Firestore Console: users/{userId}
{
  notification_prefs: {
    push_enabled: true,
    game_alerts: {
      enabled: false
    },
    chat_alerts: {
      enabled: true
    },
    quiet_hours: {
      enabled: false,
      start: "22:00",
      end: "07:00"
    },
    digest_mode: "instant",
    muted_threads: []
  }
}
```

### 2. Create Alert Subscription Document

```javascript
// In Firestore Console: alertSubs/{userId}
{
  userId: "{userId}",
  enabled: false,
  gameVibes: [],
  stakes: [],
  formats: [],
  handicapUses: [],
  courses: [],
  special: {
    games: false,
    twoVTwo: false
  },
  createdAt: <Firestore timestamp>,
  updatedAt: <Firestore timestamp>
}
```

---

## Testing Checklist

After applying fixes, verify:

- [ ] App builds and runs without errors
- [ ] Notification Settings page loads (no "Failed to load" error)
- [ ] Page shows correct default values for new users
- [ ] Page loads saved settings for existing users
- [ ] Debug logs show successful loading
- [ ] Push toggle works (enables/disables sections)
- [ ] Game Alerts toggle works
- [ ] Chat Alerts toggle works
- [ ] Save button works and persists data
- [ ] Navigate away and back - settings still there
- [ ] Reset button works and restores defaults

---

## Code Changes Made

### 1. Enhanced _loadData() Method

**Before:**
- Simple try-catch, threw error on any failure
- No fallback to defaults

**After:**
- Comprehensive error handling
- Debug logging at each step
- Falls back to defaults if anything fails
- User can still use the page even if loading fails

### 2. Fixed Default Values

**Before:**
```dart
pushEnabled: false
```

**After:**
```dart
pushEnabled: true  // Per requirements
```

### 3. Better Error Display

**Before:**
- Simple text: "Failed to load settings"

**After:**
- Icon + heading
- Actual error message in styled container
- Retry button

---

## Still Having Issues?

### Enable Verbose Logging

Add this to see even more details:

```dart
// At the top of notification_page_widget.dart
import 'package:flutter/foundation.dart';

// In _loadData():
if (kDebugMode) {
  print('=== NOTIFICATION SETTINGS DEBUG ===');
  print('currentUserUid: $currentUserUid');
  print('currentUserReference: $currentUserReference');
  // ... more debug info
}
```

### Check Network Connection

Ensure device has internet connection:
- Try loading other Firestore data
- Check Firebase Console for connection issues
- Verify Firestore is not in offline mode

### Clear App Data

Sometimes cached data causes issues:

**iOS:**
```bash
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*
flutter run
```

**Android:**
```bash
flutter clean
flutter run
```

### Verify Flutter Dependencies

Ensure all packages are up to date:
```bash
flutter pub get
flutter pub upgrade
```

---

## Success Indicators

When everything is working correctly, you should see:

1. **Debug Console:**
   ```
   [NotificationSettings] Successfully loaded all settings
   ```

2. **UI:**
   - Page loads instantly
   - No error message
   - All toggles interactive
   - Settings match saved values (or defaults for new users)

3. **Firestore:**
   - `users/{userId}.notification_prefs` exists after first save
   - `alertSubs/{userId}` exists after first save
   - Both documents update when you tap "Save Settings"

---

## Contact & Support

If you're still seeing issues after following this guide:

1. Share the debug console logs
2. Share the specific error message
3. Confirm:
   - User is authenticated
   - Firestore rules are correct
   - User document exists
4. Try with a fresh user account

---

**Last Updated:** 2026-02-06
**Fixes Applied:** Enhanced error handling, default values, error display
