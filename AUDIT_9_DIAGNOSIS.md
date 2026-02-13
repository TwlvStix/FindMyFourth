# Audit #9 Diagnosis: Notification Permission Checks & Subscription Leaks

## Executive Summary

**Critical Issues Found:**
1. ✅ FutureBuilder in build method triggers async permission checks on every rebuild
2. ✅ NotificationPermissionService instantiated multiple times without singleton pattern
3. ✅ Token refresh subscription never disposed (memory leak)
4. ✅ Duplicate/overlapping token refresh handling across multiple files
5. ✅ No permission state caching - fresh async calls every time

## Detailed Findings

### 1. Permission Checks in Build Method ⚠️ CRITICAL

**Location:** `lib/notifications/notification_page/notification_page_widget.dart:995-1064`

```dart
FutureBuilder<NotificationPermissionStatus>(
  future: _notificationPermissionService.getDetailedStatus(),  // ❌ ASYNC IN BUILD
  builder: (context, snapshot) {
    // ... UI based on permission status
  },
)
```

**Problem:**
- Every time the widget rebuilds (state changes, navigation, etc.), `getDetailedStatus()` is called
- This triggers: `await _messaging.getNotificationSettings()` (line 61 of service)
- Async permission checks are expensive and cause jank
- No caching - fresh Firebase call every rebuild

**Impact:** High - causes performance issues and unnecessary Firebase API calls

---

### 2. Service Instantiation Without Singleton ⚠️ CRITICAL

**Locations:**
- `lib/notifications/notification_page/notification_page_widget.dart:40-41`
- `lib/notifications/game_alerts_page/game_alerts_page_widget.dart:33-34`
- `lib/notifications/notification_page/notification_page_widget_old.dart:31-32`

```dart
final NotificationPermissionService _notificationPermissionService =
    NotificationPermissionService();  // ❌ NEW INSTANCE EVERY TIME
```

**Problem:**
- Each widget creates its own service instance
- No shared state between instances
- Multiple subscriptions created (see #3)

**Impact:** High - leads to subscription leaks and wasted memory

---

### 3. Token Refresh Subscription Never Disposed ⚠️ CRITICAL LEAK

**Location:** `lib/services/notification_permission_service.dart:138-145`

```dart
void _listenForTokenRefresh(String uid) {
  _tokenRefreshSub ??= _messaging.onTokenRefresh.listen((token) {
    if (token.isEmpty) {
      return;
    }
    _upsertDeviceToken(uid, token);
  });
  // ❌ NO DISPOSE METHOD - SUBSCRIPTION NEVER CANCELLED
}
```

**Problem:**
- Line 47: `StreamSubscription<String>? _tokenRefreshSub;` is stored
- But NotificationPermissionService has NO `dispose()` method
- Subscription is never cancelled
- Each widget that creates a service instance creates a new subscription
- Navigation away from widget doesn't clean up

**Lifecycle:**
1. User opens NotificationPage → Service instance created → Subscription #1 created
2. User navigates to GameAlertsPage → Service instance created → Subscription #2 created
3. User navigates back to NotificationPage → Service instance created → Subscription #3 created
4. Result: 3 active subscriptions, all listening to the same event

**Impact:** CRITICAL - Memory leak, duplicate token updates to backend

---

### 4. Duplicate Token Refresh Handling ⚠️ HIGH

**Locations:**

**A) NotificationPermissionService** (`lib/services/notification_permission_service.dart:139`)
```dart
_tokenRefreshSub ??= _messaging.onTokenRefresh.listen((token) {
  _upsertDeviceToken(uid, token);
});
```

**B) push_notifications_util.dart** (`lib/backend/push_notifications/push_notifications_util.dart:24-37, 53-67`)
```dart
Stream<UserTokenInfo> getFcmTokenStream(String userPath) =>
    Stream.value(!kIsWeb && (Platform.isIOS || Platform.isAndroid))
        .where((shouldGetToken) => shouldGetToken)
        .asyncMap<String?>(
            (_) => FirebaseMessaging.instance.requestPermission().then(  // ❌ DUPLICATE PERMISSION REQUEST
                  (settings) => settings.authorizationStatus ==
                          AuthorizationStatus.authorized
                      ? _getTokenAfterApnsReady()
                      : null,
                ))
        .switchMap((fcmToken) => Stream.value(fcmToken)
            .merge(FirebaseMessaging.instance.onTokenRefresh))  // ❌ DUPLICATE TOKEN REFRESH LISTENER
        .where((fcmToken) => fcmToken != null && fcmToken.isNotEmpty)
        .map((token) => UserTokenInfo(userPath, token!));

final fcmTokenUserStream = authenticatedUserStream  // ❌ GLOBAL STREAM
    .where((user) => user != null)
    .map((user) => user!.reference.path)
    .distinct()
    .switchMap(getFcmTokenStream)
    .map((userTokenInfo) => makeCloudCall(...));  // ❌ DUPLICATE TOKEN SAVE
```

**Problem:**
- Two completely separate systems handling token refresh
- Both save tokens to backend (different code paths)
- Both listen to `onTokenRefresh`
- push_notifications_util.dart ALSO requests permission (duplicate request)

**Impact:** High - Wasted resources, duplicate backend writes, confusion

---

### 5. PushNotificationsHandler Repeated Init Checks ⚠️ MEDIUM

**Location:** `lib/backend/push_notifications/push_notifications_handler.dart:161-179, 246-252`

```dart
class _PushNotificationsHandlerState extends State<PushNotificationsHandler> {
  static StreamSubscription<RemoteMessage>? _messageSubscription;
  static bool _listenerInitialized = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      handleOpenedPushNotification();  // ❌ CALLED ON EVERY ROUTE
    });
  }

  Future handleOpenedPushNotification() async {
    if (_listenerInitialized) {  // ✅ GUARD PREVENTS DUPLICATE LISTENERS
      return;
    }
    _listenerInitialized = true;
    // ...
  }
}
```

**Context:** `lib/core/navigation/app_router.dart:618`
```dart
PushNotificationsHandler(child: page);  // ✅ Wraps EVERY route
```

**Problem:**
- PushNotificationsHandler wraps every page
- Every navigation creates a new widget instance
- `initState` runs on every navigation
- `handleOpenedPushNotification()` called repeatedly (though guarded by static flag)

**Impact:** Medium - Unnecessary function calls on every navigation (mitigated by guard)

---

### 6. No Permission State Caching ⚠️ HIGH

**Problem:**
- Every call to `getDetailedStatus()` makes fresh Firebase API call
- No in-memory cache
- UI cannot read permission state synchronously
- Forces FutureBuilder pattern in UI (see issue #1)

**Impact:** High - Forces async calls in build, degrades performance

---

## Root Cause Analysis

1. **Architecture:** Service designed as stateless utility, not stateful singleton
2. **Lifecycle:** No disposal/cleanup mechanism
3. **State Management:** No cached state, everything is async fetch
4. **Duplication:** Multiple overlapping systems (legacy + new) not cleaned up

---

## Files Affected

### Critical (Must Fix)
- ✅ `lib/services/notification_permission_service.dart` - Add singleton, caching, dispose
- ✅ `lib/notifications/notification_page/notification_page_widget.dart` - Remove FutureBuilder, use singleton
- ✅ `lib/notifications/game_alerts_page/game_alerts_page_widget.dart` - Use singleton
- ✅ `lib/backend/push_notifications/push_notifications_util.dart` - Remove duplicate token handling

### Medium Priority (Cleanup)
- `lib/notifications/notification_page/notification_page_widget_old.dart` - Legacy file, should update if still used

### Low Priority (Already Safe)
- `lib/backend/push_notifications/push_notifications_handler.dart` - Already has static guards
- `lib/providers/notification_provider.dart` - Only handles preferences, not permissions

---

## Success Criteria

After fixes:
1. ✅ Permission checked once at app start, cached in singleton
2. ✅ UI reads permission state synchronously (no FutureBuilder)
3. ✅ Token refresh subscription created exactly once
4. ✅ Subscription properly disposed on app shutdown (or kept alive as singleton)
5. ✅ No duplicate token handling
6. ✅ Navigation does NOT trigger permission checks
7. ✅ Debug logs confirm single initialization

---

## Next Steps

See `AUDIT_9_PLAN.md` for implementation plan.
