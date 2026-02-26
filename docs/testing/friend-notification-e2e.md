# Friend Request Notification — Manual E2E Testing Guide

This document provides a step-by-step protocol for manually testing the friend request notification flow on real devices.

## Prerequisites

1. **Two test accounts** with valid profiles
2. **Two physical devices** (or simulator + device) with the app installed
3. **Push notifications enabled** on both devices
4. **Firebase environment**: Staging or production (not emulator, as FCM requires real Firebase)

## Test Account Setup

Before testing, ensure:
- Both accounts have push notifications enabled in Settings > Notifications
- Both accounts have "Social Alerts" enabled (this is the default)
- Both accounts have valid FCM tokens registered

## Test Cases

### Test Case 1: Friend Request Notification Delivery

**Objective:** Verify that when User A sends a friend request to User B, User B receives a push notification.

**Steps:**

1. **User A** (Device 1):
   - Navigate to User B's profile (via search or from a game participant list)
   - Tap "Add Friend" button
   - Confirm the friend request is sent (button changes to "Requested")

2. **User B** (Device 2):
   - Wait for push notification (should arrive within 5-10 seconds)
   - Verify notification content:
     - **Title:** "New friend request"
     - **Body:** "{User A's display name} wants to connect with you."

**Expected Result:**
- Push notification arrives on Device 2
- Notification badge/count increments
- In-app notifications list shows the friend request

---

### Test Case 2: Friend Request Notification Tap → Navigation

**Objective:** Verify that tapping the notification navigates to the correct screen and tab.

**Steps:**

1. **User B** (Device 2):
   - With the app in background (or closed)
   - Receive the friend request notification from Test Case 1
   - Tap the notification in the notification shade

2. **Verify navigation:**
   - App opens to the Friends screen
   - The "Requests" tab is selected
   - User A's friend request is visible in the list

**Expected Result:**
- Deep link `findmyfourth://golfers/requests` is handled correctly
- Requests tab is shown (not Friends tab)

---

### Test Case 3: Friend Accepted Notification

**Objective:** Verify that when User B accepts the request, User A receives a notification.

**Steps:**

1. **User B** (Device 2):
   - Navigate to Friends > Requests tab
   - Find User A's friend request
   - Tap "Accept"

2. **User A** (Device 1):
   - Wait for push notification
   - Verify notification content:
     - **Title:** "Friend request accepted"
     - **Body:** "{User B's display name} is now connected with you."

**Expected Result:**
- Push notification arrives on Device 1
- Both users now appear in each other's Friends lists

---

### Test Case 4: Friend Accepted Notification Tap → Navigation

**Objective:** Verify that tapping the accepted notification navigates to Friends tab.

**Steps:**

1. **User A** (Device 1):
   - With the app in background
   - Receive the "Friend request accepted" notification
   - Tap the notification

2. **Verify navigation:**
   - App opens to the Friends screen
   - The "Friends" tab is selected (not Requests)
   - User B is visible in the friends list

**Expected Result:**
- Deep link `findmyfourth://golfers/friends` is handled correctly
- Friends tab is shown

---

### Test Case 5: Disabled Social Alerts

**Objective:** Verify that when social alerts are disabled, no friend notifications are sent.

**Steps:**

1. **User B** (Device 2):
   - Go to Settings > Notifications
   - Toggle OFF "Social Alerts" (or the relevant social notifications toggle)
   - Confirm the setting is saved

2. **Clear any existing friend relationship:**
   - If already friends with User A, remove friend first
   - Wait for any pending notifications to clear

3. **User A** (Device 1):
   - Send a new friend request to User B

4. **User B** (Device 2):
   - Wait 30 seconds
   - Check notification shade
   - Check in-app notifications list

**Expected Result:**
- NO push notification received on Device 2
- In-app notification list may or may not show the request (depends on implementation)
- Backend logs show `preference_disabled` result for the notification

---

### Test Case 6: Quiet Hours

**Objective:** Verify that friend notifications respect quiet hours.

**Steps:**

1. **User B** (Device 2):
   - Go to Settings > Notifications > Quiet Hours
   - Enable quiet hours
   - Set the current time to be within the quiet window (e.g., set 22:00-07:00 and test at 23:00 UTC)

2. **User A** (Device 1):
   - Send a friend request to User B

3. **User B** (Device 2):
   - Verify no immediate push notification
   - Wait until quiet hours end
   - Verify notification arrives after quiet hours window closes

**Expected Result:**
- Notification is held during quiet hours
- Notification is delivered when quiet hours end
- Backend logs show `quiet_held` with `releaseAt` timestamp

---

## Verification Checklist

For each test case, verify:

- [ ] Push notification content is correct (title, body)
- [ ] Notification tap navigates to correct screen
- [ ] Notification tap navigates to correct tab (Requests vs Friends)
- [ ] In-app notification list updates correctly
- [ ] No duplicate notifications are sent
- [ ] Preference toggles work as expected

## Troubleshooting

### No Notifications Received

1. **Check FCM token registration:**
   ```
   firebase firestore:get users/{userId}/devices
   ```
   Verify device has valid `fcm_token` field.

2. **Check user preferences:**
   ```
   firebase firestore:get users/{userId}
   ```
   Verify `notification_prefs.social_alerts.enabled` is not `false`.

3. **Check Cloud Function logs:**
   ```
   firebase functions:log --only notifyFriendRequestSent
   ```
   Look for `preference_disabled`, `quiet_held`, or error messages.

### Wrong Navigation

1. **Check deep link handling:**
   - Verify `_resolveRouteFromType` in `push_notifications_handler.dart` handles `friend_request_received` and `friend_request_accepted` types.

2. **Check event registry:**
   - Verify `deepLink` field in `event-registry.js` for friend notification types.

### Notification Delayed

1. **Check quiet hours:**
   - Verify user's quiet hours settings
   - Check `notificationLog` collection for `quiet_held` status

2. **Check FCM delivery:**
   - FCM delivery can have natural latency (up to 30 seconds)
   - Check Firebase Console > Cloud Messaging for delivery reports

## Backend Verification Commands

```bash
# Check notification log for a specific user
firebase firestore:query notificationLog \
  --where recipientUserId=="{userId}" \
  --where eventType==friend_request_received \
  --orderBy timestamp desc \
  --limit 10

# Check recent friend notification function invocations
firebase functions:log --only notifyFriendRequestSent --limit 20

# Check router decision log
firebase functions:log | grep "friend_request"
```

## Related Tests

- **Backend unit tests:** `firebase/functions/test/hooks.test.js` (onFriendRequestReceived, onFriendRequestAccepted)
- **Backend router tests:** `firebase/functions/test/router.test.js` (social_alerts check)
- **Backend callable tests:** `firebase/functions/test/friend-callable.test.js`
- **Flutter unit tests:** `test/services/fake_notification_service_test.dart`
- **Flutter integration tests:** `integration_test/friend_notifications_test.dart`
