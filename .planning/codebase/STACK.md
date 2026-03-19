# Technology Stack

## Languages & Versions

| Language | Version | Usage |
|----------|---------|-------|
| **Dart** | >= 3.0.0 < 4.0.0 | Flutter mobile app |
| **JavaScript (Node.js)** | 22 | Cloud Functions runtime |
| **Swift** | (via CocoaPods) | iOS native layer |
| **Kotlin** | JVM 17 target | Android native layer |

### Platform Targets
- **iOS**: Minimum 15.0
- **Android**: Min SDK 24, Target SDK 36, Compile SDK 36
- **Web**: Supported via Flutter web plugins (limited use)

---

## Frameworks & Core

| Package | Version | Purpose |
|---------|---------|---------|
| **Flutter SDK** | >= 3.0.0 < 4.0.0 | UI framework |
| **firebase_core** | 4.5.0 | Firebase initialization |
| **provider** | 6.1.5+1 | State management |
| **go_router** | 17.1.0 | Navigation & routing |
| **rxdart** | 0.28.0 | Reactive stream composition |
| **stream_transform** | 2.1.1 | Stream utilities |

---

## Firebase Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| **firebase_auth** | 6.2.0 | Authentication |
| **cloud_firestore** | 6.1.3 | Database |
| **cloud_functions** | 6.0.7 | Callable functions |
| **firebase_storage** | 13.1.0 | File storage |
| **firebase_messaging** | 16.1.2 | Push notifications (FCM) |
| **firebase_crashlytics** | ^5.0.8 | Crash reporting |
| **firebase_analytics** | ^12.1.3 | Event tracking |
| **firebase_remote_config** | ^6.2.0 | Runtime config/feature flags |
| **firebase_performance** | 0.11.1+5 | Performance monitoring |
| **firebase_app_check** | ^0.4.1+5 | App integrity verification |

---

## Authentication Providers

| Package | Version | Purpose |
|---------|---------|---------|
| **google_sign_in** | 7.2.0 | Google OAuth |
| **sign_in_with_apple** | 7.0.1 | Apple Sign-In |
| (firebase_auth built-in) | — | Email/Password, Phone SMS, Anonymous, JWT, GitHub |

---

## UI & Design Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| **phosphor_flutter** | 2.1.0 | Icon system (primary) |
| **flutter_animate** | 4.5.2 | Animation framework |
| **flutter_spinkit** | 5.2.2 | Loading indicators |
| **cached_network_image** | 3.4.1 | Image caching |
| **auto_size_text** | 3.0.0 | Responsive text sizing |
| **dropdown_button2** | 2.3.9 | Dropdown components |
| **google_nav_bar** | 5.0.7 | Bottom navigation |
| **infinite_scroll_pagination** | 5.1.1 | Paginated lists |
| **substring_highlight** | 1.0.33 | Text search highlighting |

---

## Media & File Handling

| Package | Version | Purpose |
|---------|---------|---------|
| **image_picker** | 1.2.1 | Photo selection |
| **image_cropper** | ^11.0.0 | Image cropping |
| **file_picker** | 10.3.10 | File selection |
| **video_player** | 2.11.0 | Video playback |
| **chewie** | 1.13.0 | Video player UI |

---

## Local & Device Features

| Package | Version | Purpose |
|---------|---------|---------|
| **flutter_local_notifications** | ^21.0.0 | Local push notifications |
| **shared_preferences** | ^2.5.4 | Key-value storage |
| **path_provider** | 2.1.5 | File system paths |
| **geolocator** | ^13.0.0 | GPS location |
| **connectivity_plus** | ^7.0.0 | Network state |
| **wakelock_plus** | 1.4.0 | Screen wake lock |
| **flutter_app_badger** | ^1.5.0 | App badge count |
| **app_settings** | ^7.0.0 | Open device settings |

---

## Utilities

| Package | Version | Purpose |
|---------|---------|---------|
| **intl** | 0.20.2 | Date/number formatting |
| **timeago** | 3.7.1 | Relative time display |
| **url_launcher** | 6.3.2 | Open URLs |
| **share_plus** | ^10.0.0 | Share sheet |
| **easy_debounce** | 2.0.3 | Debounce utility |
| **collection** | 1.19.1 | Collection utilities |
| **crypto** | ^3.0.0 | Hashing |
| **flutter_cache_manager** | 3.4.1 | Cache management |
| **from_css_color** | 2.0.0 | CSS color parsing |
| **mime_type** | 1.0.1 | MIME type detection |

---

## Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| **flutter_lints** | 6.0.0 | Lint rules |
| **test** | ^1.24.0 | Test framework |
| **fake_cloud_firestore** | ^4.0.1 | Firestore mocking |
| **firebase_auth_mocks** | ^0.15.1 | Auth mocking |
| **flutter_launcher_icons** | 0.13.1 | App icon generation |

---

## Dependency Overrides

```yaml
http: 1.4.0          # Pinned for Firebase compatibility
uuid: ^4.0.0         # Pinned for cloud_firestore and firebase_auth
```

---

## Cloud Functions Dependencies (`firebase/functions/package.json`)

### Core
| Package | Version | Purpose |
|---------|---------|---------|
| **firebase-admin** | ^11.11.0 | Firebase Admin SDK |
| **firebase-functions** | ^7.0.6 | Cloud Functions framework |

### External Services
| Package | Version | Purpose |
|---------|---------|---------|
| **@sendgrid/mail** | ^8.0.0 | Transactional email |
| **@google-cloud/tasks** | ^6.2.1 | Cloud Tasks scheduling |
| **axios** | 1.12.0 | HTTP client |
| **sharp** | ^0.33.2 | Image processing (avatars) |

### AI/LLM (LangChain)
| Package | Version | Purpose |
|---------|---------|---------|
| **@langchain/anthropic** | ^0.1.1 | Claude API |
| **@langchain/openai** | ^0.3.14 | OpenAI API |
| **@langchain/google-genai** | ^0.0.8 | Google AI |
| **@langchain/langgraph** | ^0.2.23 | Agent workflows |
| **@langchain/core** | ^0.3.19 | Core utilities |

### Payment (Installed, Not Active)
| Package | Version | Status |
|---------|---------|--------|
| **stripe** | ^8.0.1 | Not integrated |
| **razorpay** | ^2.8.4 | Not integrated |
| **braintree** | ^3.6.0 | Not integrated |

### Other
| Package | Version | Purpose |
|---------|---------|---------|
| **@mux/mux-node** | ^7.3.3 | Video processing (not active) |
| **@onesignal/node-onesignal** | ^2.0.1-beta2 | Legacy notification (deprecated) |
| **qs** | ^6.7.0 | Query string parsing |

### Dev
| Package | Version | Purpose |
|---------|---------|---------|
| **jest** | ^29.0.0 | Test framework |
| **eslint** | ^8.57.1 | Linting |

---

## Build Configuration

### Analysis Options (`analysis_options.yaml`)
- Base: `flutter_lints` 6.0.0
- Strict mode: `strict-casts`, `strict-raw-types` enabled
- Warnings: `use_build_context_synchronously`, `cancel_subscriptions`
- Excluded: `lib/custom_code/**`

### Build Flags (`lib/core/config/build_flags.dart`)
| Flag | Default | Purpose |
|------|---------|---------|
| `APP_ENV` | `'dev'` | Environment (dev/staging/prod) |
| `CRASHLYTICS_ENABLED` | `true` | Crash reporting toggle |
| `ALLOW_INTERNAL_CRASH_TEST` | `false` | Debug crash testing |
| `ENABLE_DEV_UI` | `false` | Dev-only UI elements |
| `USE_FIREBASE_EMULATOR` | `false` | Local emulator toggle |
| `APP_CHECK_DEBUG_TOKEN` | `''` | Debug App Check token |

### Firebase Emulator Ports
| Service | Port |
|---------|------|
| Auth | 9099 |
| Firestore | 8080 |
| Functions | 5001 |
| Storage | 9199 |

### Key Config Files
- Flutter: `pubspec.yaml`
- Cloud Functions: `firebase/functions/package.json`
- Firebase init: `lib/backend/firebase/firebase_config.dart`
- Build flags: `lib/core/config/build_flags.dart`
- Linting: `analysis_options.yaml`
- Android: `android/app/build.gradle`
- iOS: `ios/Podfile`
