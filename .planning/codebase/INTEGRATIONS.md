# External Integrations

**Analysis Date:** 2026-03-19

## APIs & External Services

**Authentication & Identity:**
- Google OAuth 2.0 - User sign-in via Google Account
  - SDK: `google_sign_in` 7.2.0 (Flutter)
  - Scope: email, profile, ID token
  - Configured in Firebase Console with Android/iOS credentials

- Apple OAuth 2.0 - User sign-in via Apple ID
  - SDK: `sign_in_with_apple` 7.0.1 (Flutter)
  - Scope: email, fullName (if available)
  - Requires App ID + Sign in with Apple capability

**Push Notifications & Messaging:**
- Firebase Cloud Messaging (FCM) - Push notification delivery
  - SDK: `firebase_messaging` 16.1.2 (Flutter), Firebase Admin SDK (Node.js)
  - Flow: Cloud Functions send to FCM → FCM delivers to device
  - Local display: `flutter_local_notifications` 21.0.0 (foreground handling)
  - Collections: `fcm_tokens` (token storage), `push_notifications` (notification log)
  - Quiet hours support: Timezone-aware scheduling (`America/Vancouver`)

- Cloud Tasks - Scheduled notification delivery
  - SDK: `@google-cloud/tasks` 6.2.1 (Node.js)
  - Purpose: Deferred notification scheduling with OIDC auth verification
  - Configuration: OIDC token validation from App Engine default service account

**Content & Moderation:**
- Anthropic Claude (LLM) - Avatar generation and content filtering
  - SDK: `@langchain/anthropic` 0.1.1 (Node.js)
  - Framework: `@langchain/langgraph` 0.2.23 (LLM orchestration)
  - Core: `@langchain/core` 0.3.19
  - Usage: `firebase/functions/avatar-generator.js`, moderation in `firebase/functions/index.js` (lazy-required `moderation/word_filter`)
  - Model: Text generation (avatar descriptions), content filtering

**Media & Video:**
- Mux - Video hosting platform (reserved, not currently active)
  - SDK: `@mux/mux-node` 7.3.3 (Node.js)
  - Purpose: Video content delivery (future-proofed in dependencies)

**Payment Processing:**
- Stripe - Payment processing (reserved, not currently active)
  - SDK: `stripe` 8.0.1 (Node.js)
  - Purpose: Transactions for premium features (future-proofed)

- Razorpay - Payment gateway (reserved, not currently active)
  - SDK: `razorpay` 2.8.4 (Node.js)
  - Purpose: Alternative payment processor (future-proofed)

- Braintree - Payment processor (reserved, not currently active)
  - SDK: `braintree` 3.6.0 (Node.js)
  - Purpose: PayPal + credit card processing (future-proofed)

**Push Notification Services (Alternative):**
- OneSignal - Multi-channel notification service (reserved, not currently active)
  - SDK: `@onesignal/node-onesignal` 2.0.1-beta2 (Node.js)
  - Purpose: Alternative notification provider (future-proofed)

**Email Delivery:**
- SendGrid - Transactional email service
  - SDK: `@sendgrid/mail` 8.0.0 (Node.js)
  - Usage: Signup confirmation emails, password resets, notifications
  - Configuration: API key in Firebase environment or Cloud Function secret manager
  - Test coverage: `firebase/functions/test/signup-email.test.js`

**Geographic & Location:**
- Geolocation API - Device location services
  - SDK: `geolocator` 13.0.0 (Flutter)
  - Purpose: Course/venue location filtering, distance calculation
  - Permissions: Requires location permission on device

**Other HTTP Services:**
- Generic HTTP/REST APIs
  - SDK: `axios` 1.12.0 (Node.js Cloud Functions)
  - Config: `firebase/functions/api_manager.js` (route handler, currently empty callMap)

## Data Storage

**Databases:**
- Firestore (Cloud Firestore) - Primary NoSQL document database
  - Client: `cloud_firestore` 6.1.3 (Flutter)
  - Admin: `firebase-admin` (Node.js)
  - Collections: `users`, `games`, `chats`, `alertSubs`, `round_jobs`, `notifications`, `push_notifications`, `devices`, `fcm_tokens`, `user_push_notifications`, `cancellations`, `strikes`
  - Subcollections: `games/{gameId}/game_participants`, `chats/{chatId}/messages`, `chats/{chatId}/typing_users`, `chats/{chatId}/reactions`
  - Security: Document-level access control via Firestore security rules (`firebase/firestore.rules`)
  - Transactions: Used for concurrent-safe operations (reactions, chat creation, game join)

**Local Storage:**
- SharedPreferences - Local key-value persistence
  - SDK: `shared_preferences` 2.5.4 (Flutter)
  - Usage: User preferences, onboarding flags, cancelled game state (`lib/app_state.dart`)

- Device filesystem - Local file cache
  - Providers: `path_provider` 2.1.5 (system directories)
  - Use: Temporary downloads, image cache (`flutter_cache_manager` 3.4.1)

**File Storage:**
- Firebase Storage - Cloud object storage
  - Client: `firebase_storage` 13.1.0 (Flutter)
  - Admin: `firebase-admin` (Node.js)
  - Purpose: User profile images, game photos, video content
  - Integration: `firebase/functions` uses `sharp` 0.33.2 for image resizing

**Caching:**
- Runtime cache in providers - In-memory Firestore result caching
  - Pattern: TTL-based invalidation (typically 5 minutes) via timestamp maps in providers
  - Example: `UserProvider`, `GameProvider`, `ChatProvider` cache strategies

- Flutter Cache Manager - HTTP asset cache
  - SDK: `flutter_cache_manager` 3.4.1
  - Purpose: Cached network image storage (`cached_network_image` 3.4.1)

## Authentication & Identity

**Auth Provider:**
- Firebase Authentication - Multi-provider authentication
  - Implementation: `lib/backend/firebase/firebase_config.dart` initializes Firebase Auth
  - Providers configured:
    - Email/password (native Firebase)
    - Google OAuth (via `google_sign_in`)
    - Apple OAuth (via `sign_in_with_apple`)
  - Token management: Automatic Firebase token refresh
  - Service: `lib/providers/user_provider.dart` manages current user state

## Monitoring & Observability

**Error Tracking:**
- Firebase Crashlytics - Crash reporting and error tracking
  - SDK: `firebase_crashlytics` 5.0.8 (Flutter)
  - Purpose: Production error monitoring and stack trace collection

**Performance Monitoring:**
- Firebase Performance - App performance metrics
  - SDK: `firebase_performance` 0.11.1+5 (Flutter)
  - Purpose: Frame drops, screen render times, network latency

**Logging:**
- Custom logging - Application-level logging
  - Service: `lib/core/utils/app_log.dart` (AppLog.d() method used throughout)
  - Cloud Functions logging: `console.log()`, `console.warn()` (captured by Cloud Functions logs)
  - View: `npm run logs` in Cloud Functions directory

**Analytics:**
- Firebase Analytics - Usage analytics and events
  - SDK: `firebase_analytics` 12.1.3 (Flutter)
  - Purpose: User behavior tracking, funnel analysis

## CI/CD & Deployment

**Hosting:**
- Firebase (GCP) - Backend infrastructure
  - Project: `find-my-fourth` (`us-west2` region)
  - Services: Firestore, Auth, Functions, Storage, Messaging, Crashlytics, Analytics, Remote Config, App Check

**Firebase Deployment:**
- Firestore Rules: `firebase deploy --only firestore:rules`
- Firestore Indexes: `firebase deploy --only firestore:indexes`
- Cloud Functions: `firebase deploy --only functions` (or specific: `firebase deploy --only functions:functionName`)
- All services: `firebase deploy`

**App Distribution:**
- iOS: App Store, TestFlight (via App Store Connect)
- Android: Google Play Store, internal testing

**Development & Testing:**
- Firebase Emulator Suite - Local development
  - Services: Auth emulator (port 9099), Firestore (8080), Functions (5001), Storage (9199)
  - Activation: `USE_FIREBASE_EMULATOR=true` build flag in debug mode
  - Command: `npm run serve` (Cloud Functions emulator start)

## Environment Configuration

**Required Environment Variables:**
- Firebase credentials (automatic from GoogleService-Info.plist / google-services.json on native platforms)
- SendGrid API key - `SENDGRID_API_KEY` (for email delivery in Cloud Functions)
- Anthropic API key - `ANTHROPIC_API_KEY` (for avatar generation and moderation)
- Cloud Tasks project - `GCLOUD_PROJECT` (defaults to "find-my-fourth")
- Build flags: `APP_ENV={dev|staging|prod}`, `USE_FIREBASE_EMULATOR={true|false}`, `APP_CHECK_DEBUG_TOKEN` (optional, for debug builds)

**Secrets Location:**
- Firebase project console: Service accounts, API keys, environment variables
- Cloud Functions runtime: Injected via build flags and Cloud Function secrets
- Local development: Firebase emulator (no real credentials needed)
- Production: GCP Secret Manager integration via Firebase Cloud Functions

## Webhooks & Callbacks

**Incoming (to Cloud Functions):**
- Cloud Task HTTP callbacks - Notification scheduling system
  - Endpoint: `sendTrustNotification` handler (validates OIDC token from Cloud Tasks)
  - Purpose: Deliver trust-based notifications after delay
  - Auth: OIDC token verification from App Engine service account

- Firestore Triggers - Event-driven functions
  - `onGameCreate` - Triggers on new game creation (validates app users)
  - `onChatMessageWrite` - Triggers on chat message creation (debounces notifications, applies moderation)
  - Chat member sync - Triggered on game join/leave (non-critical, errors swallowed)

**Outgoing (from Cloud Functions):**
- FCM push notifications - Sent to user devices via Firebase Messaging
  - Targets: User-specific, topic-based, or condition-based subscriptions
  - Flow: Cloud Function → Firebase Messaging API → FCM → Device

- SendGrid email - Transactional email delivery
  - Recipients: Signup confirmation, notifications, alerts
  - Flow: Cloud Function → SendGrid API → Email provider → User inbox

- Anthropic Claude API - Content generation and filtering
  - Flow: Cloud Function → Anthropic API → Claude model → Response

**Real-time Listeners (not webhooks):**
- Firestore listeners - Client-side reactive streams
  - Services: `lib/services/*_service.dart` use `firestore.collection().snapshots()` for live updates
  - Providers: Wrap streams with `StreamRequestManager` for BehaviorSubject caching
  - Example: `GameProvider.listenToMyGames()`, `ChatProvider.listenToChats()`

---

*Integration audit: 2026-03-19*
