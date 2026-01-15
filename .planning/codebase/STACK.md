# Technology Stack

**Analysis Date:** 2026-01-14

## Languages

**Primary:**
- Dart 3.x - All application code (`pubspec.yaml`)

**Secondary:**
- JavaScript/Node.js 20 - Firebase Cloud Functions (`firebase/functions/package.json`)
- Kotlin/Java - Android platform code (`android/app/build.gradle`)
- Swift/Objective-C - iOS platform code (`ios/Podfile`)

## Runtime

**Environment:**
- Flutter Framework - Cross-platform mobile/web development
- Node.js 20 - Firebase Cloud Functions runtime (`firebase/functions/package.json`)
- iOS 15.0+ deployment target (`ios/Podfile`)
- Android SDK 35 (`android/app/build.gradle`)

**Package Manager:**
- Dart Pub - `pubspec.yaml`, `pubspec.lock`
- npm - `firebase/functions/package.json`, `firebase/functions/package-lock.json`
- CocoaPods - `ios/Podfile`, `ios/Podfile.lock` (iOS dependencies)
- Gradle - `android/app/build.gradle` (Android dependencies)

## Frameworks

**Core:**
- Flutter SDK - Mobile app framework (Dart 3.0+)
- Go Router 17.0.1 - Navigation and routing (`lib/core/navigation/app_router.dart`)
- Provider 6.1.5+1 - State management (`lib/main.dart`, `lib/providers/`)
- Material Design - Flutter Material UI components

**Testing:**
- flutter_test - Unit and widget testing (Flutter SDK)

**Build/Dev:**
- Flutter Launcher Icons 0.13.1 - App icon generation
- ESLint - JavaScript linting (`firebase/functions/package.json`)

## Key Dependencies

**Backend/Data:**
- Cloud Firestore 6.1.1 - NoSQL database (`lib/backend/backend.dart`)
- Cloud Functions 6.0.5 - Serverless compute
- Firebase Storage 13.0.5 - File storage
- Firebase Admin SDK 11.11.0 - Server-side Firebase (`firebase/functions/package.json`)
- firebase-functions 4.4.1 - Cloud Functions framework

**Authentication:**
- Firebase Auth 6.1.3 - Authentication service (`lib/auth/firebase_auth/`)
- Google Sign-In 7.2.0 - OAuth authentication (`lib/auth/firebase_auth/google_auth.dart`)
- Sign in with Apple 7.0.1 - Apple OAuth (`lib/auth/firebase_auth/apple_auth.dart`)

**Media & UI:**
- Image Picker 1.2.1 - Image selection
- Video Player 2.10.1 - Video playback
- Chewie 1.13.0 - Video player wrapper
- Cached Network Image 3.4.1 - Image caching
- Google Fonts 7.0.2 - Custom fonts
- Font Awesome Flutter 10.12.0 - Icon library

**UI Components:**
- Flutter Animate 4.5.2 - Animation framework
- Flutter Spinkit 5.2.2 - Loading indicators
- Google Nav Bar 5.0.7 - Bottom navigation
- Page Transition 2.2.1 - Page transitions
- Auto Size Text 3.0.0 - Responsive text

**Notifications:**
- Firebase Messaging 16.1.0 - Push notifications (`lib/backend/push_notifications/`)
- OneSignal SDK 2.0.1-beta2 - Push notification service (`firebase/functions/package.json`)

**Payment Processing (Backend):**
- Stripe 8.0.1 - Payment processing (`firebase/functions/package.json`)
- Braintree 3.6.0 - Payment gateway
- Razorpay 2.8.4 - Payment processor

**AI/LLM Integration (Backend):**
- LangChain Core 0.3.19 - LLM orchestration (`firebase/functions/package.json`)
- LangChain OpenAI 0.3.14 - OpenAI integration
- LangChain Google GenAI 0.0.8 - Google Gemini integration
- LangChain Anthropic 0.1.1 - Anthropic Claude integration

**Media Management (Backend):**
- Mux Node SDK 7.3.3 - Video hosting/streaming (`firebase/functions/package.json`)

**Utilities:**
- Infinite Scroll Pagination 5.1.1 - List pagination
- Shared Preferences 2.5.4 - Local storage
- SQLite 2.4.2 - Local database
- URL Launcher 6.3.2 - External links
- Path Provider 2.1.5 - File system access
- RxDart 0.28.0 - Reactive programming
- Intl 0.20.2 - Internationalization
- Timeago 3.7.1 - Relative time formatting

**Development Dependencies:**
- Flutter Lints 4.0.0 - Lint rules
- Lints 4.0.0 - Standard Dart lints

## Configuration

**Environment:**
- Firebase Configuration - `lib/backend/firebase/firebase_config.dart` (web Firebase options)
- Google Services - `android/app/google-services.json` (Android Firebase config)
- Emulator Support - USE_FIREBASE_EMULATOR flag for local development

**Build:**
- Firestore Security Rules - `firebase/firestore.rules` (role-based access)
- Firestore Indexes - `firebase/firestore.indexes.json` (query optimization)
- Firebase Config - `firebase/firebase.json` (Functions, Hosting setup)

**iOS:**
- Podfile - `ios/Podfile` (CocoaPods dependencies)
- Custom FirebaseFirestore git repo override

## Platform Requirements

**Development:**
- Flutter SDK (compatible with Dart 3.0+)
- iOS development: macOS with Xcode 13+
- Android development: Android Studio with SDK 35

**Production:**
- Web: Firebase Hosting
- iOS: App Store (iOS 15.0+)
- Android: Google Play (SDK 35)
- Backend: Firebase Cloud Functions (Node.js 20)

---

*Stack analysis: 2026-01-14*
*Update after major dependency changes*
