# Audit #10: Dependency Cleanup - Verification Guide

This document provides step-by-step verification commands to validate the dependency cleanup changes.

---

## Quick Verification (2 minutes)

Run these commands to quickly verify everything works:

```bash
# 1. Verify dependencies resolve
flutter pub get

# 2. Check for errors
flutter analyze

# 3. Verify iOS Pods size improvement
du -sh ios/Pods
# Expected: ~164MB (was 850MB before)
```

**Expected result:** All commands succeed with no errors.

---

## Detailed Verification (10 minutes)

### 1. Verify Removed Packages Are Truly Gone

Check that unused packages were removed:

```bash
# Search for sqflite in direct dependencies (should find nothing)
grep "sqflite:" pubspec.yaml
# Expected: No output

# Verify sqflite is now transitive (through flutter_cache_manager)
flutter pub deps | grep -B 5 "sqflite 2.4.2" | grep "flutter_cache_manager"
# Expected: Should show flutter_cache_manager as parent

# Check other unused packages are gone
grep -E "csslib:|html:|xml:|json_path:|text_search:|universal_io:" pubspec.yaml
# Expected: No output (all removed)
```

### 2. Verify Platform Packages Are Transitive

Check that platform-specific packages are now managed by parent packages:

```bash
# image_picker platforms should be transitive
flutter pub deps | grep -A 10 "image_picker 1.2.1" | grep "image_picker_"
# Expected: Shows image_picker_android, image_picker_ios, etc. indented (transitive)

# Verify they're not in pubspec as direct dependencies
grep "image_picker_" pubspec.yaml
# Expected: Only "image_picker: 1.2.1", no platform-specific versions

# Same check for other platform packages
grep -E "google_sign_in_android|google_sign_in_ios" pubspec.yaml
# Expected: No output

grep -E "path_provider_android|path_provider_foundation|path_provider_linux|path_provider_windows" pubspec.yaml
# Expected: No output

grep -E "shared_preferences_android|shared_preferences_foundation" pubspec.yaml
# Expected: No output

grep -E "url_launcher_android|url_launcher_ios|url_launcher_macos" pubspec.yaml
# Expected: No output

grep -E "video_player_android|video_player_avfoundation" pubspec.yaml
# Expected: No output
```

### 3. Verify iOS Podfile Changes

Check that Firestore override was removed:

```bash
# Should NOT contain custom git source
grep "invertase" ios/Podfile
# Expected: No output

# Should still have flutter_install_all_ios_pods
grep "flutter_install_all_ios_pods" ios/Podfile
# Expected: flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

# Verify Firebase SDK version from pod install
cd ios && pod install 2>&1 | grep "Using Firebase SDK version"
# Expected: Using Firebase SDK version '12.6.0' defined in 'firebase_core'
```

### 4. Check Pods Size

```bash
# Current size
du -sh ios/Pods
# Expected: ~164M

# Check total pod count
cat ios/Podfile.lock | grep "PODS:" -A 100 | grep "  -" | wc -l
# Expected: ~69 pods
```

### 5. Dependency Count Comparison

```bash
# Count direct dependencies in pubspec.yaml
grep "^  [a-z]" pubspec.yaml | grep -v "^  #" | grep -v "flutter:" | wc -l
# Expected: ~46 packages (was ~80 before)

# Count all dependencies (including transitive)
flutter pub deps --no-dev | grep "├──" | wc -l
# Expected: Similar total, but cleaner structure
```

---

## Build Verification (15 minutes)

### 1. Clean Build Environment

```bash
# Clean Flutter build
flutter clean

# Clean iOS Pods (if you want to start fresh)
cd ios
rm -rf Pods Podfile.lock .symlinks
pod install
cd ..
```

### 2. Verify Flutter Analysis

```bash
flutter analyze
```

**Expected output:**
- No new errors related to missing packages
- Pre-existing warnings (e.g., deprecated APIs) may still appear
- Overall: "No issues found!" or only warnings unrelated to dependencies

### 3. Test Android Debug Build

```bash
flutter build apk --debug
```

**Expected result:**
- Build completes successfully
- No dependency resolution errors
- APK created at: `build/app/outputs/flutter-apk/app-debug.apk`

**Optional - Check APK size:**
```bash
ls -lh build/app/outputs/flutter-apk/app-debug.apk
# Note the size for future comparison
```

### 4. Test iOS Debug Build

```bash
flutter build ios --debug --no-codesign
```

**Expected result:**
- Build completes successfully
- No CocoaPods errors
- No Firebase framework errors
- Build succeeds with official Firebase SDK 12.6.0

**Note:** You may see a warning about Crashlytics project path - this is unrelated to our changes.

### 5. Test App Runtime

**On iOS Simulator/Device:**
```bash
flutter run -d <ios-device-id>
```

**Test these features to ensure nothing broke:**
- ✅ App launches successfully
- ✅ User authentication (sign in/sign out)
- ✅ Firestore data loading (games, chats, profiles)
- ✅ Image picking (profile pictures, chat images)
- ✅ Video playback (if app uses videos)
- ✅ Firebase messaging (push notifications)
- ✅ File uploads to Firebase Storage
- ✅ Google Sign In
- ✅ Sign in with Apple

**On Android Emulator/Device:**
```bash
flutter run -d <android-device-id>
```

**Test same features as iOS above.**

---

## Verification Checklist

Use this checklist to track verification progress:

### Dependency Verification
- [ ] `flutter pub get` succeeds
- [ ] `flutter analyze` shows no new errors
- [ ] Unused packages removed from pubspec.yaml
- [ ] Platform packages are now transitive (not direct)
- [ ] sqflite is transitive under flutter_cache_manager

### iOS Verification
- [ ] Podfile has no custom Firestore git source
- [ ] `pod install` succeeds
- [ ] iOS Pods directory is ~164MB (was 850MB)
- [ ] Firebase SDK 12.6.0 installed from official source
- [ ] iOS debug build succeeds

### Android Verification
- [ ] Android debug build succeeds
- [ ] No dependency resolution errors

### Runtime Verification
- [ ] App launches on iOS
- [ ] App launches on Android
- [ ] Authentication works
- [ ] Firestore reads/writes work
- [ ] Image picker works
- [ ] Video playback works (if applicable)
- [ ] Push notifications work
- [ ] Firebase Storage uploads work

### Documentation
- [ ] AUDIT_10_DIAGNOSIS.md created
- [ ] AUDIT_10_PLAN.md created
- [ ] AUDIT_10_SUMMARY.md created
- [ ] AUDIT_10_VERIFICATION.md created (this file)

---

## Common Issues & Troubleshooting

### Issue: "Package XYZ not found"

**Cause:** Package was removed but still imported in code

**Solution:**
```bash
# Search for usage
grep -r "import.*package:XYZ" lib/

# If found, this means the package is actually used and should be restored
# Add back to pubspec.yaml and run:
flutter pub get
```

### Issue: iOS pod install fails

**Symptoms:** `pod install` fails with framework errors

**Solution 1 - Clean and retry:**
```bash
cd ios
rm -rf Pods Podfile.lock .symlinks
pod deintegrate
pod repo update
pod install
cd ..
```

**Solution 2 - If still failing, temporarily restore Firestore override:**
```bash
git checkout ios/Podfile
cd ios && pod install && cd ..
# Then investigate the specific error
```

### Issue: Platform package not found at runtime

**Symptoms:** Error like "MissingPluginException" or platform implementation not found

**Solution:**
```bash
# Verify the parent package is in pubspec.yaml
grep "image_picker:" pubspec.yaml
# Should show: image_picker: 1.2.1

# Clean and rebuild
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### Issue: Build size didn't decrease

**Cause:** Build artifacts not cleaned

**Solution:**
```bash
flutter clean
rm -rf build/
rm -rf ios/Pods ios/Podfile.lock
cd ios && pod install && cd ..
flutter build apk --debug
# Check size again
```

---

## Performance Metrics

Track these metrics before and after to measure improvement:

### Build Times

**Measure dependency resolution:**
```bash
time flutter pub get
```

**Measure iOS pod install:**
```bash
time (cd ios && pod install)
```

**Measure full build:**
```bash
time flutter build apk --debug
time flutter build ios --debug --no-codesign
```

### Size Metrics

**iOS Pods:**
```bash
du -sh ios/Pods
# Before: 850M
# After: 164M
# Improvement: 80.6% reduction
```

**Android APK (debug):**
```bash
ls -lh build/app/outputs/flutter-apk/app-debug.apk
# Note size for future reference
```

**Dependency count:**
```bash
# Direct dependencies
grep "^  [a-z]" pubspec.yaml | grep -v "^  #" | grep -v "flutter:" | wc -l
# Before: ~80
# After: ~46
# Improvement: 42.5% reduction
```

---

## Success Criteria

✅ **All checks pass if:**

1. **No errors** in `flutter pub get`
2. **No new errors** in `flutter analyze`
3. **iOS Pods ~164MB** (down from 850MB)
4. **All builds succeed** (iOS and Android)
5. **App runs normally** on both platforms
6. **All features work** (auth, Firestore, storage, etc.)
7. **No runtime exceptions** related to missing plugins

---

## Final Confirmation

After completing all verification steps, confirm:

1. ✅ I have run `flutter pub get` successfully
2. ✅ I have run `flutter analyze` with no new errors
3. ✅ I have verified iOS Pods size reduced to ~164MB
4. ✅ I have tested iOS debug build
5. ✅ I have tested Android debug build
6. ✅ I have run the app on iOS and verified core features
7. ✅ I have run the app on Android and verified core features

**If all confirmed:** Changes are safe to commit! 🎉

**If any failed:** Review troubleshooting section or rollback:
```bash
git checkout pubspec.yaml ios/Podfile
flutter pub get
cd ios && pod install && cd ..
```

---

**Document Version:** 1.0
**Last Updated:** 2026-02-12
**Related Files:** AUDIT_10_DIAGNOSIS.md, AUDIT_10_PLAN.md, AUDIT_10_SUMMARY.md
