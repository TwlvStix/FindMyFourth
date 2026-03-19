# Technology Stack

**Analysis Date:** 2026-03-19

## Languages

**Primary:**
- Dart 3.0.0+ - Flutter mobile app (`lib/`)
- JavaScript (Node.js 22) - Firebase Cloud Functions (`firebase/functions/`)

**Secondary:**
- Dart (Firestore rules compilation) - `firebase/firestore.rules`

## Runtime

**Environment:**
- Flutter SDK: >=3.0.0 <4.0.0 (via `pubspec.yaml`)
- Node.js: 22 (defined in `firebase/functions/package.json` engines)
- Dart VM (embedded in Flutter)

**Package Managers:**
- Pub (Dart) - `pubspec.yaml` for Flutter app dependencies
- npm (JavaScript) - `firebase/functions/package.json` for Cloud Functions dependencies
- Lockfiles: `pubspec.lock` (Dart), `package-lock.json` (npm) - both present and tracked

## Frameworks

**Core Mobile:**
- Flutter 3.0.0+ - UI framework for iOS/Android
- Provider 6.1.5+1 - State management with ChangeNotifier pattern
- GoRouter 17.1.0 - Navigation and routing with auth-aware redirects

**Firebase Ecosystem:**
- Firebase Core 4.5.0 - Initialization and configuration
- Cloud Firestore 6.1.3 - Realtime database with security rules
- Firebase Auth 6.2.0 - Authentication with multi-provider support (Google, Apple)
- Cloud Functions 6.0.7 - Serverless compute (region: `us-west2`)
- Firebase Messaging 16.1.2 - Push notifications (FCM)
- Firebase Storage 13.1.0 - File storage with `firebase/functions` integration
- Firebase Crashlytics 5.0.8 - Error tracking and monitoring
- Firebase Analytics 12.1.3 - Usage analytics
- Firebase Performance 0.11.1+5 - Performance monitoring
- Firebase Remote Config 6.2.0 - Feature flags and dynamic configuration
- Firebase App Check 0.4.1+5 - App attestation (Play Integrity/App Attest)

**Testing:**
- test 1.24.0 - Unit testing framework (Dart)
- fake_cloud_firestore 4.0.1 - Firestore mocks for testing
- firebase_auth_mocks 0.15.1 - Auth mocks
- Jest 29.0.0 - Unit/integration testing (Node.js Cloud Functions)

**Build & Dev Tools:**
- Flutter Lints 6.0.0 - Code analysis (strict-casts, strict-raw-types enabled)
- Lints 6.0.0 - Linting rules package
- Flutter Launcher Icons 0.13.1 - App icon generation
- Flutter Native Splash 2.4.7 - Splash screen configuration
- Image 4.8.0 - Image processing utilities
- ESLint 8.57.1 - JavaScript linting (Cloud Functions)
- firebase-functions 7.0.6 - Firebase Cloud Functions SDK (Node.js v1 API)
- firebase-admin 11.11.0 - Firebase Admin SDK for backend operations

## Key Dependencies

**Critical Mobility & State:**
- `provider` 6.1.5+1 - Domain-specific providers (UserProvider, GameProvider, ChatProvider, ProfileProvider, NotificationProvider, TrustProvider)
- `rxdart` 0.28.0 - Reactive streams (switchMap, combineLatestList for Firestore composition)
- `stream_transform` 2.1.1 - Stream utilities
- `go_router` 17.1.0 - Named routing with auth guards and transitions

**UI & Design:**
- `phosphor_flutter` 2.1.0 - Icon system (primary, replaces deprecated SVG icons)
- `flutter_animate` 4.5.2 - Animation library for transitions and micro-interactions
- `flutter_spinkit` 5.2.2 - Loading spinners
- `auto_size_text` 3.0.0 - Responsive text sizing
- `cached_network_image` 3.4.1 - Image caching with network fallback
- `dropdown_button2` 2.3.9 - Enhanced dropdown component
- `google_nav_bar` 5.0.7 - Bottom navigation bar
- `flutter_local_notifications` 21.0.0 - Local notification display (foreground FCM)

**Media & File Handling:**
- `image_picker` 1.2.1 - Photo/video selection from device
- `image_cropper` 11.0.0 - Image crop tool
- `video_player` 2.11.0 - Video playback
- `file_picker` 10.3.10 - File selection dialog
- `chewie` 1.13.0 - Video player wrapper
- `flutter_cache_manager` 3.4.1 - Disk cache for network assets

**Authentication & Social:**
- `google_sign_in` 7.2.0 - Google OAuth sign-in
- `sign_in_with_apple` 7.0.1 - Apple OAuth sign-in
- `firebase_auth` 6.2.0 - Firebase email/auth methods

**Utilities & Helpers:**
- `intl` 0.20.2 - Internationalization (date/time formatting, timezones)
- `timeago` 3.7.1 - Relative time display ("2 hours ago")
- `url_launcher` 6.3.2 - Deep linking and URL opening
- `share_plus` 10.0.0 - Native share sheet
- `easy_debounce` 2.0.3 - Debounce helper for frequent events
- `connectivity_plus` 7.0.0 - Network connectivity detection
- `geolocator` 13.0.0 - Geolocation and distance calculation
- `wakelock_plus` 1.4.0 - Keep screen on during gameplay
- `path_provider` 2.1.5 - System directory access (documents, temp, cache)
- `shared_preferences` 2.5.4 - Local persistent key-value storage
- `infinite_scroll_pagination` 5.1.1 - Paginated list views
- `collection` 1.19.1 - Collection utilities (extension methods)
- `crypto` 3.0.0 - Cryptographic hashing
- `uuid` 4.0.0 (dependency override) - UUID generation (pinned for compatibility with cloud_firestore and firebase_auth)
- `http` 1.4.0 (dependency override) - HTTP client (pinned to ensure consistency across Firebase packages)
- `mime_type` 1.0.1 - MIME type detection
- `from_css_color` 2.0.0 - CSS color string parsing
- `substring_highlight` 1.0.33 - Text highlighting utility
- `app_settings` 7.0.0 - Open app settings screen

**Cloud Functions (Node.js):**
- `firebase-admin` 11.11.0 - Firestore, Auth, Messaging, Storage operations
- `firebase-functions` 7.0.6 - HTTP/event-triggered serverless functions
- `@sendgrid/mail` 8.0.0 - Email delivery (signup confirmation, notifications)
- `@google-cloud/tasks` 6.2.1 - Cloud Tasks for scheduled/deferred notifications
- `google-auth-library` (lazy-required in index.js) - OIDC token verification for Cloud Task auth
- `axios` 1.12.0 - HTTP requests
- `qs` 6.7.0 - Query string parsing/serialization
- `@langchain/core` 0.3.19 - LLM framework core
- `@langchain/anthropic` 0.1.1 - Anthropic Claude integration (avatar generation, content moderation)
- `@langchain/openai` 0.3.14 - OpenAI integration (potential future use)
- `@langchain/google-genai` 0.0.8 - Google AI integration (potential future use)
- `@langchain/langgraph` 0.2.23 - LLM orchestration and workflow
- `sharp` 0.33.2 - Image resizing and optimization
- `@mux/mux-node` 7.3.3 - Video hosting (reserved for video content, currently unused)
- `stripe` 8.0.1 - Payment processing (dependency reserved, not actively used)
- `razorpay` 2.8.4 - Payment gateway (dependency reserved, not actively used)
- `braintree` 3.6.0 - Payment processor (dependency reserved, not actively used)
- `@onesignal/node-onesignal` 2.0.1-beta2 - Push notification service (reserved, not actively used)

## Configuration

**Environment:**
- Build flag system: Dart compile-time constants via `--dart-define`
- Configuration file: `lib/core/config/build_flags.dart` (CLAUDE.md references `APP_ENV={dev|staging|prod}` and `USE_FIREBASE_EMULATOR` flags)
- No `.env` files — all secrets loaded from Firebase console or environment at runtime
- Firebase project: `find-my-fourth` (defined in `firebase_config.dart`)
- Region: `us-west2` for Cloud Functions

**Build Configuration:**
- `pubspec.yaml` - Flutter app manifest with all dependencies, fonts (Manrope, Fraunces, DM Mono), and asset directories
- `firebase.json` - Firebase project configuration
- `firebase/functions/package.json` - Cloud Functions dependencies and scripts
- `analysis_options.yaml` - Dart analyzer configuration (flutter_lints 6.0.0, strict mode enabled)
- `.eslintrc.js` - ESLint rules for Cloud Functions

**Firebase Security:**
- App Check: Production uses Play Integrity (Android) + App Attest (iOS); debug uses debug tokens
- Firestore security rules: `firebase/firestore.rules` (document-level access control)
- FCM: Server-to-client messaging with user-level permissions

## Platform Requirements

**Development:**
- Flutter SDK 3.0.0+
- Dart 3.0.0+
- Node.js 22 (for Cloud Functions)
- npm 10+ (for Cloud Functions dependencies)
- iOS: Xcode 14.0+ with iOS 12.0+ deployment target
- Android: Android SDK 21+ (API level)
- Web: Chrome/Safari support (limited Firebase App Check)

**Production:**
- iOS App Store deployment (via App Store Connect, Testflight builds)
- Google Play Store deployment (Android)
- Firebase hosted backend (`us-west2` region, `find-my-fourth` project)
- FCM infrastructure for push notifications
- Cloud Functions auto-scaling (standard performance)

---

*Stack analysis: 2026-03-19*
