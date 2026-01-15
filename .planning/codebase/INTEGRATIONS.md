# External Integrations

**Analysis Date:** 2026-01-14

## APIs & External Services

**Firebase Ecosystem:**
- Firebase Project ID: `find-my-fourth` - `android/app/google-services.json`, `lib/backend/firebase/firebase_config.dart`
- Firebase Realtime Database URL: `https://find-my-fourth-default-rtdb.firebaseio.com`
- Firebase Storage Bucket: `find-my-fourth.appspot.com`
- Firebase Project Number: `357406229935`

**Push Notifications:**
- Firebase Cloud Messaging (FCM) - Push notification service - `firebase/functions/index.js`, `lib/backend/push_notifications/push_notifications_handler.dart`
- OneSignal - Alternative push notification service - `firebase/functions/package.json`
- iOS Firebase Messaging Pod - Native iOS messaging - `ios/Podfile`

**Payment Gateways:**
- Stripe - Card payments, subscriptions - `firebase/functions/package.json`
- Braintree - PayPal, card, alternative payments - `firebase/functions/package.json`
- Razorpay - Indian payment processor - `firebase/functions/package.json`

**AI/LLM Services:**
- OpenAI - ChatGPT API integration - `firebase/functions/package.json`
- Google Gemini API - Google generative AI - `firebase/functions/package.json`
- Anthropic Claude - Claude AI models - `firebase/functions/package.json`
- LangGraph - Agent orchestration framework - `firebase/functions/package.json`

**Video & Media:**
- Mux - Video hosting, transcoding, streaming - `firebase/functions/package.json`

## Data Storage

**Databases:**
- Firebase Cloud Firestore - Primary database
  - Connection: `lib/backend/firebase/firebase_config.dart`
  - Client: Firebase SDK for Flutter
  - Collections: users, games, chats, messages (subcollection), friend_request, course, fcm_tokens, push_notifications, notifications, usernames
  - Security: `firebase/firestore.rules` (role-based access control)
  - Indexes: `firebase/firestore.indexes.json`

**File Storage:**
- Firebase Storage - User uploads (profile images, game photos)
  - SDK: Firebase Storage Flutter plugin
  - Bucket: `find-my-fourth.appspot.com`
  - Implementation: `lib/backend/firebase_storage/storage.dart`

**Caching:**
- SQLite - Local caching for offline support
- Shared Preferences - Local user settings storage

## Authentication & Identity

**Auth Provider:**
- Firebase Auth - Multi-provider authentication
  - Implementation: `lib/auth/firebase_auth/firebase_auth_manager.dart`
  - User stream: `lib/auth/firebase_auth/firebase_user_provider.dart`
  - Token management: JWT refresh via `jwtTokenStream`
  - Session: httpOnly cookies for web, secure storage for mobile

**OAuth Integrations:**
- Google OAuth - Social sign-in
  - Implementation: `lib/auth/firebase_auth/google_auth.dart`
  - Client ID: `357406229935-b80gfcvite6up8auvsclnp7o5u8vf67p.apps.googleusercontent.com`
  - Scopes: email, profile

- Apple Sign-In - OAuth integration
  - Implementation: `lib/auth/firebase_auth/apple_auth.dart`

- GitHub OAuth - Web-only OAuth
  - Implementation: `lib/auth/firebase_auth/github_auth.dart`

- Email/Password - Native Firebase auth
  - Implementation: `lib/auth/firebase_auth/email_auth.dart`

- Anonymous Auth - Testing/fallback auth
  - Implementation: `lib/auth/firebase_auth/anonymous_auth.dart`

## Monitoring & Observability

**Error Tracking:**
- Not detected (no Sentry or similar integration found)

**Analytics:**
- Not detected (no Mixpanel, Google Analytics, or similar found)

**Logs:**
- Firebase Console - Cloud Functions logs
- Client-side: debugPrint() to console (development only)

## CI/CD & Deployment

**Hosting:**
- Firebase Hosting - Web app deployment
  - Configuration: `firebase/firebase.json`
  - Deployment: Manual via Firebase CLI

**CI Pipeline:**
- Not detected (no GitHub Actions, GitLab CI, or similar workflows found)

**Cloud Functions:**
- Firebase Cloud Functions - Serverless backend
  - Runtime: Node.js 20
  - Memory: 2GB configuration
  - Functions: sendPushNotificationsTrigger, notification preferences management

## Environment Configuration

**Development:**
- Required env vars: USE_FIREBASE_EMULATOR (optional, for local testing)
- Emulator ports: 9099 (Auth), 8080 (Firestore), 5001 (Functions), 9199 (Storage)
- Configuration: `lib/backend/firebase/firebase_config.dart`

**Staging:**
- Not detected (no separate staging environment configuration found)

**Production:**
- Firebase project: find-my-fourth
- Web API Key: Hardcoded in `lib/backend/firebase/firebase_config.dart`
- Platform-specific configs: `android/app/google-services.json` for Android

## Webhooks & Callbacks

**Incoming:**
- Not detected (no webhook endpoints found in cloud functions)

**Outgoing:**
- Firebase Cloud Functions triggers:
  - Firestore writes trigger push notifications
  - sendPushNotificationsTrigger - `firebase/functions/index.js`
  - User notification preferences - `firebase/functions/index.js`

## Real-Time Features

**Live Chat:**
- Firestore subcollections (`chats/{chatId}/messages`) with real-time listeners
- Implementation: `lib/services/chat_service.dart`
- Streams: `lib/providers/chat_provider.dart`

**Game Alerts:**
- FCM push notifications triggered by Firestore writes
- Implementation: `firebase/functions/index.js`
- Client handling: `lib/backend/push_notifications/push_notifications_handler.dart`

**Notification Preferences:**
- User-customized notification rules - `firebase/functions/index.js`
- Quiet hours support (time-based notification suppression)

---

*Integration audit: 2026-01-14*
*Update when adding/removing external services*
