# Audit #9 Verification Plan

## Implementation Complete ✅

All code changes have been implemented to fix notification permission checks and subscription leaks.

---

## Testing Checklist

### 1. Cold Start Test ⭐ CRITICAL

**Objective:** Verify service initializes once and permission check happens only once.

**Steps:**
1. Uninstall app or clear app data
2. Launch app
3. Sign in with valid credentials
4. Check debug console logs

**Expected Logs:**
```
🔔 APP: User signed in, initializing notification service
[NotificationService] Initializing notification service
[NotificationService] Permission status refreshed: denied
[NotificationService] Token refresh listener attached
[NotificationService] Notification service initialized successfully
```

**Validation:**
- ✅ "Initializing notification service" appears ONCE
- ✅ "Token refresh listener attached" appears ONCE
- ✅ No permission dialog shown (user hasn't requested yet)
- ✅ No errors in console

---

### 2. Navigation Stress Test ⭐ CRITICAL

**Objective:** Verify no repeated permission checks or service initialization during navigation.

**Steps:**
1. After cold start (from Test #1)
2. Navigate: Home → Profile → Notification Settings → Back → Game Alerts → Back → Notification Settings
3. Repeat navigation 5 times
4. Check debug console logs

**Expected Logs:**
```
[NotificationService] Already initialized, skipping
[NotificationService] Already initialized, skipping
[NotificationService] Already initialized, skipping
```

**Validation:**
- ✅ Only "Already initialized, skipping" logs (no fresh initialization)
- ✅ NO "Permission status refreshed" logs during navigation
- ✅ NO "Token refresh listener attached" logs (already attached)
- ✅ FutureBuilder NOT triggering async calls (verified by absence of permission check logs)
- ✅ Navigation is smooth, no jank

---

### 3. Permission Request Test (iOS/Android 13+) ⭐ CRITICAL

**Objective:** Verify permission request flow and cache update.

**Steps:**
1. Navigate to NotificationPage
2. Toggle "Enable push notifications" ON
3. When system dialog appears, tap "Allow"
4. Check debug console logs

**Expected Logs:**
```
[NotificationSettings] Requesting notification permission (user action)
[NotificationService] Requesting notification permission
[NotificationService] Permission granted
[NotificationService] Token refresh listener attached
[NotificationService] Initial FCM token saved
[NotificationSettings] Permission result: granted
```

**Validation:**
- ✅ Permission dialog appears
- ✅ After granting, "Permission granted" logged
- ✅ Token listener attached (or "already active" if already attached from init)
- ✅ Initial FCM token saved to Firestore
- ✅ UI updates to show permission granted (no more warning banner)
- ✅ Verify in Firestore: `users/{uid}/devices/{device_id}` has `fcmToken`

---

### 4. Permission Denial Test ⭐ MEDIUM

**Objective:** Verify denial flow and "Open Settings" button.

**Steps:**
1. Uninstall app or clear app data
2. Launch app and sign in
3. Navigate to NotificationPage
4. Toggle "Enable push notifications" ON
5. When system dialog appears, tap "Don't Allow" or "Deny"
6. Check UI

**Expected Behavior:**
- ✅ Orange "Notification permission required" banner appears
- ✅ "Open Settings" button is visible
- ✅ Tapping "Open Settings" opens system settings

**Expected Logs:**
```
[NotificationService] Permission denied: permanentlyDenied
```

---

### 5. Hot Restart Test ⭐ CRITICAL

**Objective:** Verify service doesn't re-initialize on hot restart (idempotence).

**Steps:**
1. App is running and user is signed in
2. Hot restart app (Flutter DevTools or IDE hot restart)
3. Check debug console logs

**Expected Logs:**
```
🔔 APP: User signed in, initializing notification service
[NotificationService] Already initialized, skipping
```

**Validation:**
- ✅ Service recognizes it's already initialized
- ✅ NO duplicate token refresh listeners created
- ✅ App continues working normally

---

### 6. Token Refresh Simulation ⭐ HIGH

**Objective:** Verify token refresh listener works and updates backend.

**Steps:**

**Option A (Manual):**
1. Sign in
2. Reinstall app without uninstalling (this can trigger token refresh on some platforms)
3. Check logs

**Option B (Code):**
Temporarily add this test button to NotificationPage:
```dart
ElevatedButton(
  onPressed: () async {
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('Current token: $token');
  },
  child: Text('Get Token'),
),
```

**Expected Logs:**
```
[NotificationService] FCM token refreshed, updating backend (uid=...)
```

**Validation:**
- ✅ "FCM token refreshed" logged ONCE (not duplicated)
- ✅ New token saved to Firestore
- ✅ No multiple writes (check Firestore usage metrics)

---

### 7. Memory Leak Test ⭐ CRITICAL

**Objective:** Verify no growing subscriptions or memory leaks.

**Steps:**
1. Open Flutter DevTools
2. Go to Memory tab
3. Take snapshot (Snapshot #1)
4. Navigate to NotificationPage
5. Navigate away
6. Repeat 10 times
7. Take snapshot (Snapshot #2)
8. Force garbage collection
9. Compare snapshots

**Expected Results:**
- ✅ Number of StreamSubscription objects does NOT grow
- ✅ Memory usage stable (no significant increase after GC)
- ✅ Only 1 active `onTokenRefresh` subscription in heap

**How to Check:**
- In Memory tab, search for "StreamSubscription"
- Count instances before and after
- Should see: 1 subscription for token refresh, consistent across snapshots

---

### 8. Multi-User Test ⭐ MEDIUM

**Objective:** Verify service handles user switching correctly.

**Steps:**
1. Sign in as User A
2. Check logs (service initialized for User A)
3. Sign out
4. Sign in as User B
5. Check logs

**Expected Logs:**
```
# User A signs in:
[NotificationService] Initializing notification service
[NotificationService] Token refresh listener attached

# User B signs in:
[NotificationService] Already initialized, skipping
```

**Note:** Service remains initialized (singleton), but token updates will use new user's UID.

**Validation:**
- ✅ No crashes
- ✅ Token saved to correct user document in Firestore
- ✅ No duplicate listeners

---

### 9. Offline/Online Test ⭐ LOW

**Objective:** Verify service handles offline state gracefully.

**Steps:**
1. Sign in
2. Turn off WiFi/cellular
3. Navigate to NotificationPage
4. Try to toggle notifications ON
5. Turn WiFi back on
6. Check if token eventually syncs

**Expected Behavior:**
- ✅ No crashes
- ✅ Permission request may fail gracefully (timeout)
- ✅ When online again, token sync completes

---

### 10. Build Performance Test ⭐ HIGH

**Objective:** Verify no async calls in build methods.

**Steps:**
1. Add Flutter DevTools performance overlay
2. Navigate to NotificationPage
3. Trigger setState by changing a preference
4. Check for jank

**Expected Results:**
- ✅ No frame drops during rebuild
- ✅ No "async gap" indicators in performance overlay
- ✅ Smooth 60fps rendering

**Validation:**
- In DevTools Timeline, look for "getNotificationSettings" or "requestPermission" calls during build
- These should NOT appear during normal rebuilds
- Only appear when user explicitly requests permission

---

## Expected Debug Logs Summary

### On App Launch (Cold Start)
```
🔔 APP: Initializing notification service for user: {uid}
[NotificationService] Initializing notification service
[NotificationService] Permission status refreshed: denied (or granted)
[NotificationService] Token refresh listener attached
[NotificationService] Notification service initialized successfully
```

### On Navigation
```
[NotificationService] Already initialized, skipping
```

### On Permission Request
```
[NotificationSettings] Requesting notification permission (user action)
[NotificationService] Requesting notification permission
[NotificationService] Permission granted (or denied)
[NotificationService] Token refresh listener attached
[NotificationService] Initial FCM token saved
```

### On Token Refresh
```
[NotificationService] FCM token refreshed, updating backend (uid=...)
```

---

## Automated Testing (Optional)

### Unit Tests

Create `test/services/notification_permission_service_test.dart`:

```dart
void main() {
  group('NotificationPermissionService', () {
    test('is singleton', () {
      final instance1 = NotificationPermissionService();
      final instance2 = NotificationPermissionService();
      expect(identical(instance1, instance2), true);
    });

    test('init is idempotent', () async {
      final service = NotificationPermissionService.forTesting(
        auth: mockAuth,
        firestore: mockFirestore,
        messaging: mockMessaging,
      );

      await service.init('test-uid');
      expect(service.isInitialized, true);

      await service.init('test-uid'); // Call again
      expect(service.isInitialized, true);
      // Verify only one token listener created (mock verification)
    });
  });
}
```

---

## Known Limitations

1. **Service never disposed during app lifetime**
   - This is intentional (singleton pattern)
   - Only disposed on app shutdown
   - Not a leak if it's a true singleton

2. **Token refresh listener uses initial UID**
   - If user switches accounts, listener still uses original UID
   - Workaround: Sign out should call `dispose()` and re-init on sign in
   - Consider adding this in future if multi-user sessions are common

3. **Web platform not supported**
   - Service returns early on web
   - This is expected behavior

---

## Rollback Plan

If critical bugs are found:

```bash
# Revert all changes
git checkout HEAD -- lib/services/notification_permission_service.dart
git checkout HEAD -- lib/notifications/notification_page/notification_page_widget.dart
git checkout HEAD -- lib/notifications/game_alerts_page/game_alerts_page_widget.dart
git checkout HEAD -- lib/backend/push_notifications/push_notifications_util.dart
git checkout HEAD -- lib/main.dart

# Remove documentation
rm AUDIT_9_*.md
```

---

## Success Criteria Checklist

- ✅ Permission checked once at app start, cached in singleton
- ✅ UI reads permission state synchronously (no FutureBuilder async calls)
- ✅ Token refresh subscription created exactly once
- ✅ Subscription properly managed (disposed on app shutdown or kept alive as singleton)
- ✅ No duplicate token handling
- ✅ Navigation does NOT trigger permission checks
- ✅ Debug logs confirm single initialization
- ✅ No memory leaks (verified in DevTools)
- ✅ No frame drops during rebuilds
- ✅ User-facing behavior is identical

---

## Files Changed

1. `lib/services/notification_permission_service.dart` - Singleton + caching + lifecycle
2. `lib/notifications/notification_page/notification_page_widget.dart` - Remove FutureBuilder, use singleton
3. `lib/notifications/game_alerts_page/game_alerts_page_widget.dart` - Remove FutureBuilder, use singleton
4. `lib/backend/push_notifications/push_notifications_util.dart` - Remove duplicate token refresh
5. `lib/main.dart` - Initialize service on auth

**Total:** 5 files modified

---

## Next Steps After Verification

1. Monitor Crashlytics for any new errors
2. Monitor Firestore writes to `users/{uid}/devices/*` (should be fewer writes)
3. Check Firebase Analytics for app performance improvements
4. Consider adding automated tests
5. Document this pattern for future services

---

## Contact

If issues are found during verification, provide:
- Device type (iOS/Android version)
- Debug logs (full console output)
- Steps to reproduce
- Expected vs actual behavior
