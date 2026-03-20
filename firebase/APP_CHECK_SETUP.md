# Firebase App Check — Console Setup

App Check client-side initialization is handled by the Flutter plugin (`firebase_app_check`).
Server-side enforcement is handled by `requireAppCheck()` in `firebase/functions/utils/app_check.js`.

These steps must be completed in the **Firebase Console** — they cannot be done in code.

---

## 1. Register iOS App

1. Open **Firebase Console → App Check → Apps**
2. Select the iOS app (`find-my-fourth`)
3. Register with **App Attest** provider
   - Team ID: from your Apple Developer account → Membership → Team ID
4. Save

## 2. Register Android App

1. Open **Firebase Console → App Check → Apps**
2. Select the Android app (`find-my-fourth`)
3. Register with **Play Integrity** provider
   - SHA-256 fingerprint: run `keytool -list -v -keystore <your-keystore> -alias <your-alias>`
4. Save

## 3. Add Debug Tokens

For TestFlight, internal testing, and CI:

1. Open **Firebase Console → App Check → Manage debug tokens**
2. Add a debug token for each test device or CI environment
3. Pass the token via `--dart-define=APP_CHECK_DEBUG_TOKEN=<token>` during development builds

## 4. Rollout Checklist

1. **Deploy with `APP_CHECK_ENFORCE = false`** (current default)
   - All callable functions log `[AppCheck]` warnings for missing tokens but do not reject
2. **Monitor Cloud Functions logs** for `[AppCheck]` warnings
   - Filter: `[AppCheck] Missing token`
   - Expect warnings to decrease as users update to App Check-enabled app versions
3. **Confirm all active app versions** have App Check initialized
   - Check minimum deployed version in App Store / Play Store
4. **Flip `APP_CHECK_ENFORCE` to `true`** in `firebase/functions/utils/app_check.js`
5. **Redeploy**: `firebase deploy --only functions`
6. **Monitor** for `REJECTED` entries — these indicate blocked requests

## 5. Follow-Up: Firestore Rules Enforcement

After Cloud Functions enforcement is stable, add App Check to Firestore security rules:

```
allow read, write: if request.auth != null && request.appCheck.token.verified;
```

This provides defense-in-depth for direct Firestore access (bypassing Cloud Functions).
