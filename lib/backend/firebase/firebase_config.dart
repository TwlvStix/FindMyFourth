import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
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
}
