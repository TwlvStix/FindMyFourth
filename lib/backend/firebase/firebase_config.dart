import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '/core/config/build_flags.dart';

const int _authEmulatorPort =
    int.fromEnvironment('FIREBASE_AUTH_EMULATOR_PORT', defaultValue: 9099);
const int _firestoreEmulatorPort =
    int.fromEnvironment('FIRESTORE_EMULATOR_PORT', defaultValue: 8080);
const int _functionsEmulatorPort =
    int.fromEnvironment('FIREBASE_FUNCTIONS_EMULATOR_PORT', defaultValue: 5001);
const int _storageEmulatorPort =
    int.fromEnvironment('FIREBASE_STORAGE_EMULATOR_PORT', defaultValue: 9199);

const Set<String> _validAppEnvironments = {'dev', 'staging', 'prod'};

Future initFirebase() async {
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
