import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '/core/config/build_flags.dart';
import '/core/utils/app_log.dart';

const int _authEmulatorPort =
    int.fromEnvironment('FIREBASE_AUTH_EMULATOR_PORT', defaultValue: 9099);
const int _firestoreEmulatorPort =
    int.fromEnvironment('FIRESTORE_EMULATOR_PORT', defaultValue: 8080);
const int _functionsEmulatorPort =
    int.fromEnvironment('FIREBASE_FUNCTIONS_EMULATOR_PORT', defaultValue: 5001);
const int _storageEmulatorPort =
    int.fromEnvironment('FIREBASE_STORAGE_EMULATOR_PORT', defaultValue: 9199);

const Set<String> _validAppEnvironments = {'dev', 'staging', 'prod'};

Future<void> initFirebase() async {
  if (!_validAppEnvironments.contains(kAppEnv)) {
    throw StateError(
        'Invalid APP_ENV value "$kAppEnv". Expected one of: dev, staging, prod.');
  }

  if (kReleaseMode) {
    if (kAppEnv != 'prod') {
      throw StateError(
          'Release builds must use APP_ENV=prod. Current value: $kAppEnv.');
    }
    if (kUseFirebaseEmulator) {
      throw StateError(
        'USE_FIREBASE_EMULATOR must be false for release builds.',
      );
    }
  }

  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyAS8KAaxk5jb-2whEYphr4T1_VsIN2WwF4",
            authDomain: "find-my-fourth.firebaseapp.com",
            projectId: "find-my-fourth",
            storageBucket: "find-my-fourth.appspot.com",
            messagingSenderId: "357406229935",
            appId: "1:357406229935:web:2e7fb49282aad25ce9db5a"));
  } else {
    await Firebase.initializeApp();
  }

  await _initAppCheck();

  if (kDebugMode && kUseFirebaseEmulator) {
    final emulatorHost = _getEmulatorHost();
    FirebaseAuth.instance.useAuthEmulator(emulatorHost, _authEmulatorPort);
    FirebaseFirestore.instance
        .useFirestoreEmulator(emulatorHost, _firestoreEmulatorPort);
    FirebaseFunctions.instanceFor(region: 'us-west2')
        .useFunctionsEmulator(emulatorHost, _functionsEmulatorPort);
    FirebaseStorage.instance
        .useStorageEmulator(emulatorHost, _storageEmulatorPort);
  }
}

Future<void> _initAppCheck() async {
  if (kIsWeb) {
    // ── App Check on Web — intentionally skipped ──────────────────────
    // Why: reCAPTCHA Enterprise has not been configured for this project.
    //      Activating App Check without a valid provider would cause all
    //      web requests to be rejected by Firebase.
    //
    // Risk: Without App Check, automated abuse from authenticated web
    //       sessions is theoretically possible.  However, all Firestore
    //       and Storage security rules still enforce auth + ownership
    //       checks, so the blast radius is limited to actions the
    //       authenticated user is already allowed to perform.
    //
    // TODO: To enable App Check on web:
    //   1. Set up reCAPTCHA Enterprise in the Google Cloud console.
    //   2. Register the site key in Firebase Console → App Check.
    //   3. Uncomment and update the activation code below:
    //
    //   await FirebaseAppCheck.instance.activate(
    //     providerWeb: ReCaptchaEnterpriseProvider('YOUR_SITE_KEY'),
    //   );
    // ──────────────────────────────────────────────────────────────────
    AppLog.d('ℹ️ App Check skipped on web (no reCAPTCHA provider configured).');
    return;
  }

  if (kUseFirebaseEmulator) {
    AppLog.d('ℹ️ App Check skipped while using Firebase emulators.');
    return;
  }

  final useProductionProviders = kReleaseMode && kAppEnv == 'prod';
  final debugToken = kAppCheckDebugToken.trim();

  try {
    if (useProductionProviders) {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidPlayIntegrityProvider(),
        providerApple: const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
      AppLog.d('✅ App Check activated with production providers.');
    } else {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: debugToken.isEmpty
            ? const AndroidDebugProvider()
            : AndroidDebugProvider(debugToken: debugToken),
        providerApple: debugToken.isEmpty
            ? const AppleDebugProvider()
            : AppleDebugProvider(debugToken: debugToken),
      );
      AppLog.d('✅ App Check activated with debug providers.');
    }

    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  } catch (error) {
    AppLog.d('⚠️ App Check activation failed: $error');
  }
}

String _getEmulatorHost() {
  if (kIsWeb) {
    return 'localhost';
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return '10.0.2.2';
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return 'localhost';
  }
}
