# Audit #9 Implementation Plan: Fix Permission Checks & Subscription Leaks

## Strategy

Convert NotificationPermissionService to a **singleton with cached state** and remove all async permission checks from build methods.

### Key Decisions

1. **Singleton pattern** - Service lives for entire app lifetime
2. **Cached permission state** - Store in-memory, expose synchronously
3. **Single token refresh subscription** - Created once, never duplicated
4. **Idempotent init** - Safe to call init() multiple times
5. **Keep push_notifications_util.dart** - But remove duplicate token refresh handling
6. **No dispose** - Service is app-lifetime singleton (never disposed)

---

## Implementation Steps

### Step 1: Refactor NotificationPermissionService to Singleton

**File:** `lib/services/notification_permission_service.dart`

**Changes:**

1.1. Add singleton instance and private constructor
```dart
class NotificationPermissionService {
  static final NotificationPermissionService _instance = NotificationPermissionService._internal();
  factory NotificationPermissionService() => _instance;
  NotificationPermissionService._internal({...});

  // Allow DI for testing
  NotificationPermissionService.forTesting({...});
}
```

1.2. Add cached state fields
```dart
NotificationPermissionStatus? _cachedStatus;
NotificationSettings? _cachedSettings;
DateTime? _lastCheckedAt;
bool _initialized = false;
```

1.3. Add init() method (idempotent)
```dart
Future<void> init(String uid) async {
  if (_initialized) {
    AppLog.d('[NotificationService] Already initialized, skipping');
    return;
  }
  _initialized = true;

  AppLog.d('[NotificationService] Initializing notification service');

  // Load current permission status
  await refreshPermissionStatus();

  // Set up token refresh listener (only once)
  _setupTokenRefreshListener(uid);

  AppLog.d('[NotificationService] Notification service initialized');
}
```

1.4. Add synchronous state accessors
```dart
NotificationPermissionStatus get cachedStatus =>
    _cachedStatus ?? NotificationPermissionStatus.denied;

NotificationSettings? get cachedSettings => _cachedSettings;

bool get isInitialized => _initialized;
```

1.5. Convert getDetailedStatus() to refreshPermissionStatus()
```dart
Future<NotificationPermissionStatus> refreshPermissionStatus() async {
  if (kIsWeb) {
    _cachedStatus = NotificationPermissionStatus.unsupported;
    return _cachedStatus!;
  }

  // ... existing logic ...

  _cachedStatus = status;
  _cachedSettings = settings;
  _lastCheckedAt = DateTime.now();

  AppLog.d('[NotificationService] Permission status refreshed: $status');

  return status;
}
```

1.6. Rename _listenForTokenRefresh to _setupTokenRefreshListener (called once)
```dart
void _setupTokenRefreshListener(String uid) {
  if (_tokenRefreshSub != null) {
    AppLog.d('[NotificationService] Token refresh listener already active');
    return;
  }

  _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
    if (token.isEmpty) return;
    AppLog.d('[NotificationService] Token refreshed, updating backend (uid=$uid)');
    _upsertDeviceToken(uid, token);
  });

  AppLog.d('[NotificationService] Token refresh listener attached');
}
```

1.7. Add dispose method (for app shutdown if needed)
```dart
void dispose() {
  AppLog.d('[NotificationService] Disposing notification service');
  _tokenRefreshSub?.cancel();
  _tokenRefreshSub = null;
  _initialized = false;
}
```

---

### Step 2: Initialize Service in Main App

**File:** `lib/main.dart`

**Changes:**

2.1. Add initialization after auth is ready
```dart
Future<void> _initializeNonCriticalServices(AppState appState) async {
  try {
    // Load persisted state in background
    await appState.initializePersistedState();

    // Initialize notification service when user is authenticated
    if (FirebaseAuth.instance.currentUser != null) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await NotificationPermissionService().init(uid);
    }

    // Set Crashlytics metadata
    await _configureCrashlyticsMetadata();
  } catch (error, stackTrace) {
    // ... existing error handling ...
  }
}
```

2.2. Add auth state listener to init service on sign-in
```dart
// In _MyAppState or appropriate location
FirebaseAuth.instance.authStateChanges().listen((user) {
  if (user != null) {
    NotificationPermissionService().init(user.uid);
  }
});
```

---

### Step 3: Remove FutureBuilder from NotificationPage

**File:** `lib/notifications/notification_page/notification_page_widget.dart`

**Changes:**

3.1. Remove FutureBuilder (lines 995-1064), replace with synchronous check
```dart
// OLD:
FutureBuilder<NotificationPermissionStatus>(
  future: _notificationPermissionService.getDetailedStatus(),
  builder: (context, snapshot) { ... }
)

// NEW:
Builder(
  builder: (context) {
    final status = NotificationPermissionService().cachedStatus;

    if (status == NotificationPermissionStatus.permanentlyDenied) {
      return Container(/* ... same UI ... */);
    }

    return SizedBox.shrink();
  },
)
```

3.2. Update _ensureNotificationPermission to refresh cache
```dart
Future<bool> _ensureNotificationPermission() async {
  final status = await NotificationPermissionService().requestPermissionAndRegister();

  // Refresh cache after permission change
  await NotificationPermissionService().refreshPermissionStatus();

  setState(() {}); // Trigger rebuild with new cached state

  return status == NotificationPermissionStatus.granted ||
      status == NotificationPermissionStatus.provisional;
}
```

3.3. Remove instance field (line 40-41)
```dart
// REMOVE:
final NotificationPermissionService _notificationPermissionService =
    NotificationPermissionService();
```

3.4. Use singleton everywhere
```dart
// Replace all _notificationPermissionService with NotificationPermissionService()
NotificationPermissionService().requestPermissionAndRegister();
NotificationPermissionService().openSystemSettings();
```

---

### Step 4: Update GameAlertsPage

**File:** `lib/notifications/game_alerts_page/game_alerts_page_widget.dart`

**Changes:**

4.1. Remove instance field (lines 33-34)
4.2. Use singleton in _ensureNotificationPermission (line 206)

---

### Step 5: Clean Up push_notifications_util.dart

**File:** `lib/backend/push_notifications/push_notifications_util.dart`

**Changes:**

5.1. Remove duplicate permission request from getFcmTokenStream (line 28)
```dart
// OLD:
.asyncMap<String?>(
    (_) => FirebaseMessaging.instance.requestPermission().then(...)
)

// NEW:
.asyncMap<String?>((_) => _getTokenAfterApnsReady())
```

5.2. Remove token refresh listener (handled by service now)
```dart
// OLD:
.switchMap((fcmToken) => Stream.value(fcmToken)
    .merge(FirebaseMessaging.instance.onTokenRefresh))

// NEW:
.map((fcmToken) => fcmToken)
```

5.3. Keep fcmTokenUserStream but simplify it
```dart
// This stream now just gets initial token on auth
// Token refresh is handled by NotificationPermissionService singleton
```

**Rationale:** We keep push_notifications_util.dart for initial token retrieval on auth,
but remove duplicate token refresh handling (now centralized in service).

---

### Step 6: Add Debug Logging

**Files:** All modified files

**Changes:**

6.1. Add logs to NotificationPermissionService:
- "Initializing notification service"
- "Already initialized, skipping"
- "Permission status refreshed: {status}"
- "Token refresh listener attached"
- "Token refreshed, updating backend (uid={uid})"
- "Disposing notification service"

6.2. Add logs to NotificationPage:
- "Permission check: using cached status {status}"
- "Requesting permission (user action)"
- "Permission granted: {status}"

---

## Testing Plan

### Manual Verification Steps

1. **Cold Start Test**
   - Clear app data
   - Launch app
   - Sign in
   - Expected logs:
     ```
     [NotificationService] Initializing notification service
     [NotificationService] Permission status refreshed: denied
     [NotificationService] Token refresh listener attached
     ```
   - Navigate to NotificationPage
   - Expected: NO additional permission checks logged

2. **Navigation Test**
   - Navigate: Home → NotificationPage → GameAlertsPage → Back → NotificationPage
   - Expected logs: NO repeated "Initializing" or "Permission status refreshed"
   - Expected: Only ONE "Token refresh listener attached" in entire session

3. **Permission Request Test**
   - On NotificationPage, toggle "Enable push notifications" ON
   - Expected logs:
     ```
     [NotificationPage] Requesting permission (user action)
     [NotificationService] Permission status refreshed: granted
     [NotificationPage] Permission granted: granted
     ```
   - Verify permission dialog appears (iOS/Android 13+)

4. **Hot Restart Test**
   - Hot restart app (don't kill)
   - Expected logs:
     ```
     [NotificationService] Already initialized, skipping
     ```
   - No duplicate listeners created

5. **Token Refresh Test**
   - Trigger token refresh (reinstall app, clear data, etc.)
   - Expected logs:
     ```
     [NotificationService] Token refreshed, updating backend (uid=...)
     ```
   - Verify only ONE log entry (not duplicated)

6. **Memory Leak Test**
   - Navigate to NotificationPage 10 times
   - Check Flutter DevTools → Memory
   - Expected: No growing list of StreamSubscriptions
   - Expected: Only 1 active onTokenRefresh subscription

---

## Rollback Plan

If issues occur:
1. Revert all changes: `git checkout HEAD -- lib/`
2. Original code has no breaking changes
3. User-facing behavior is identical

---

## Assumptions

1. **App lifetime singleton is acceptable** - Service never needs to be disposed except on app shutdown
2. **Permission state can be cached** - It's safe to cache permission status and refresh on demand
3. **Single token refresh listener is sufficient** - No need for multiple listeners
4. **Existing NotificationProvider is separate** - It handles preferences, not permissions (no conflict)
5. **push_notifications_util.dart is used somewhere** - Keep it but remove duplication

---

## Files Changed Summary

1. ✅ `lib/services/notification_permission_service.dart` - Singleton + caching + lifecycle
2. ✅ `lib/notifications/notification_page/notification_page_widget.dart` - Remove FutureBuilder
3. ✅ `lib/notifications/game_alerts_page/game_alerts_page_widget.dart` - Use singleton
4. ✅ `lib/backend/push_notifications/push_notifications_util.dart` - Remove duplicates
5. ✅ `lib/main.dart` - Initialize service post-frame

Total: 5 files changed
