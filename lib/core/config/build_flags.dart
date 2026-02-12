const String kAppEnv = String.fromEnvironment('APP_ENV', defaultValue: 'prod');

const bool kCrashlyticsEnabled =
    bool.fromEnvironment('CRASHLYTICS_ENABLED', defaultValue: true);

const bool kAllowInternalCrashTest =
    bool.fromEnvironment('ALLOW_INTERNAL_CRASH_TEST', defaultValue: false);

const bool kEnableDevUi =
    bool.fromEnvironment('ENABLE_DEV_UI', defaultValue: false);

const bool kUseFirebaseEmulator =
    bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
