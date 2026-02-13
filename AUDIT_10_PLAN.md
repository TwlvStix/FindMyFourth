# Audit #10: Dependency Bloat & Build Health - Implementation Plan

## Execution Strategy
**Principle:** Incremental, testable, reversible changes
**Order:** Safe → Less Safe (unused packages → platform overrides → pod overrides)

---

## Phase 1: Remove Unused Packages (Safest)
**Risk:** LOW | **Reversibility:** Easy | **Test:** flutter pub get

### Step 1.1: Remove Unused Heavy Packages
Remove packages with zero usage in codebase:

```yaml
# REMOVE from pubspec.yaml dependencies:
sqflite: 2.4.2              # Database - unused
sqflite_common: 2.5.6       # Database - unused
```

**Verification:**
```bash
flutter pub get
flutter analyze
```

### Step 1.2: Remove Unused Light Packages
Remove lightweight packages with zero usage:

```yaml
# REMOVE from pubspec.yaml dependencies:
csslib: 1.0.2               # CSS parser - unused
text_search: 1.0.2          # Search - unused
json_path: 0.7.2            # JSON querying - unused
universal_io: 2.3.1         # IO abstraction - unused
xml: 6.5.0                  # XML parser - unused
html: 0.15.6                # HTML parser - unused
```

**Verification:**
```bash
flutter pub get
flutter analyze
```

**Commit Point:** "Remove unused packages (sqflite, csslib, xml, html, etc.)"

---

## Phase 2: Remove Redundant Platform Overrides (Safe)
**Risk:** LOW | **Reversibility:** Easy | **Test:** flutter pub get + platform builds

### Step 2.1: Remove image_picker Platform Packages
These are automatically included by `image_picker: 1.2.1`:

```yaml
# REMOVE from pubspec.yaml dependencies:
image_picker_android: 0.8.13+10
image_picker_for_web: 3.1.1
image_picker_ios: 0.8.13+3
image_picker_linux: 0.2.2
image_picker_macos: 0.2.2+1
image_picker_platform_interface: 2.11.1
image_picker_windows: 0.2.2
```

**Keep:**
```yaml
image_picker: 1.2.1         # Parent package handles all platforms
```

**Verification:**
```bash
flutter pub get
flutter pub deps | grep image_picker
# Should show image_picker with all platform packages as transitive deps
```

### Step 2.2: Remove google_sign_in Platform Packages

```yaml
# REMOVE from pubspec.yaml dependencies:
google_sign_in_android: 7.2.7
google_sign_in_ios: 6.2.4
```

**Keep:**
```yaml
google_sign_in: 7.2.0       # Parent package handles platforms
```

### Step 2.3: Remove path_provider Platform Packages

```yaml
# REMOVE from pubspec.yaml dependencies:
path_provider_android: 2.2.22
path_provider_foundation: 2.5.1
path_provider_linux: 2.2.1
path_provider_windows: 2.3.0
```

**Keep:**
```yaml
path_provider: 2.1.5        # Parent package handles platforms
```

### Step 2.4: Remove shared_preferences Platform Packages

```yaml
# REMOVE from pubspec.yaml dependencies:
shared_preferences_android: 2.4.18
shared_preferences_foundation: 2.5.6
shared_preferences_linux: 2.4.1
shared_preferences_windows: 2.4.1
```

**Keep:**
```yaml
shared_preferences: ^2.5.4  # Parent package handles platforms
```

### Step 2.5: Remove url_launcher Platform Packages

```yaml
# REMOVE from pubspec.yaml dependencies:
url_launcher_android: 6.3.28
url_launcher_ios: 6.3.6
url_launcher_linux: 3.2.2
url_launcher_macos: 3.2.5
url_launcher_windows: 3.1.5
```

**Keep:**
```yaml
url_launcher: 6.3.2         # Parent package handles platforms
```

### Step 2.6: Remove video_player Platform Packages

```yaml
# REMOVE from pubspec.yaml dependencies:
video_player_android: 2.9.1
video_player_avfoundation: 2.8.9
```

**Keep:**
```yaml
video_player: 2.10.1        # Parent package handles platforms
```

### Step 2.7: Remove sign_in_with_apple Platform Packages

```yaml
# REMOVE from pubspec.yaml dependencies:
sign_in_with_apple_platform_interface: 2.0.0
sign_in_with_apple_web: 3.0.0
```

**Keep:**
```yaml
sign_in_with_apple: 7.0.1   # Parent package handles platforms
```

### Step 2.8: Remove Redundant plugin_platform_interface

This is a transitive dependency for all plugins:

```yaml
# REMOVE from pubspec.yaml dependencies:
plugin_platform_interface: 2.1.8
```

**Verification:**
```bash
flutter pub get
flutter pub deps | grep "plugin_platform_interface"
# Should still appear as transitive dependency
```

**Commit Point:** "Remove redundant platform-specific package overrides"

---

## Phase 3: Test Builds After Dart Changes
**Risk:** LOW | **Purpose:** Verify no runtime impact

### Step 3.1: Clean and Rebuild

```bash
# Clean all build artifacts
flutter clean

# Get updated dependencies
flutter pub get

# Run analyzer
flutter analyze

# Check dependency tree
flutter pub deps --no-dev | grep -E "sqflite|image_picker|google_sign_in"
# Should show: NO sqflite, image_picker only as parent with transitive children
```

### Step 3.2: Test Android Build

```bash
flutter build apk --debug
# Should complete successfully
# Compare size with previous build if available
```

### Step 3.3: Test iOS Build

```bash
flutter build ios --debug --no-codesign
# Should complete successfully
```

**Commit Point:** "Verify builds pass after dependency cleanup"

---

## Phase 4: iOS Podfile Firestore Override (Medium Risk)
**Risk:** MEDIUM | **Reversibility:** Easy (git revert) | **Test:** pod install

### Decision Point: Test Then Decide

#### Option A: Remove Override (Recommended - Try First)

**Change to ios/Podfile:**

```diff
target 'Runner' do
  pod 'GoogleUtilities'

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
-  pod 'FirebaseFirestore', :git => 'https://github.com/invertase/firestore-ios-sdk-frameworks.git', :tag => '12.6.0'
end
```

**Test:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
```

**Success Criteria:**
- pod install completes without errors
- No "framework not found" warnings
- Build time < 5 minutes (acceptable)

**If successful:** Commit and keep removed

**If fails:** See Option B

#### Option B: Update Override to Official Version (Fallback)

If removal causes issues, use official version constraint instead of git source:

```ruby
target 'Runner' do
  pod 'GoogleUtilities'

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  # Override Firestore version to match cloud_firestore 6.1.1 compatibility
  # Required due to [specific issue if known, or "pod install performance"]
  pod 'FirebaseFirestore', '~> 12.0'
end
```

#### Option C: Keep Current (Last Resort)

If both fail, keep current override but add documentation:

```ruby
target 'Runner' do
  pod 'GoogleUtilities'

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  # OVERRIDE: Using Invertase precompiled frameworks for faster pod install
  # See: https://github.com/invertase/firestore-ios-sdk-frameworks
  # TODO: Test removal after FlutterFire updates
  pod 'FirebaseFirestore', :git => 'https://github.com/invertase/firestore-ios-sdk-frameworks.git', :tag => '12.6.0'
end
```

### Step 4.1: Execute Chosen Option

Based on test results, implement Option A, B, or C.

### Step 4.2: Full iOS Build Verification

```bash
cd ..  # Back to project root
flutter clean
cd ios && pod install && cd ..
flutter build ios --debug --no-codesign
```

**Commit Point:** "Clean up iOS Podfile Firestore configuration"

---

## Phase 5: Final Verification
**Purpose:** Ensure all changes are stable

### Step 5.1: Dependency Audit

```bash
# Check final dependency count
flutter pub deps --no-dev | grep "├──" | wc -l
# Should be significantly lower than before

# Verify no sqflite
flutter pub deps | grep sqflite
# Should return nothing

# Verify platform packages are transitive
flutter pub deps | grep -A 3 "image_picker "
# Should show platform packages indented under image_picker
```

### Step 5.2: Build Size Check

```bash
# Android
flutter build apk --debug
ls -lh build/app/outputs/flutter-apk/app-debug.apk

# iOS
flutter build ios --debug --no-codesign
# Note: Can't easily check size without signing, but build should succeed
```

### Step 5.3: Analyzer and Tests

```bash
flutter analyze
# Should have zero errors

# Run tests if they exist
flutter test
```

### Step 5.4: iOS Pods Size Check

```bash
du -sh ios/Pods
# Note the size for comparison
# 850MB is baseline; may not change significantly (Firebase is large)
```

**Commit Point:** "Final verification of dependency cleanup"

---

## Rollback Procedures

### If Any Step Fails

**Immediate rollback:**
```bash
git checkout pubspec.yaml
git checkout ios/Podfile
flutter pub get
cd ios && pod install && cd ..
```

**Partial rollback:**
```bash
# Revert specific file
git checkout HEAD~1 -- pubspec.yaml

# Or restore specific package in pubspec.yaml manually
# Then:
flutter pub get
```

---

## Success Metrics

### Before (Current State)
- **Direct dependencies:** ~49 packages
- **Unused packages:** 8
- **Redundant platform overrides:** 26
- **iOS Pods:** 850MB
- **Pubspec clarity:** Low (many unnecessary entries)

### After (Expected State)
- **Direct dependencies:** ~23 packages (47% reduction)
- **Unused packages:** 0
- **Redundant platform overrides:** 0
- **iOS Pods:** ~800-850MB (Firebase is inherently large)
- **Pubspec clarity:** High (only necessary declarations)
- **App size reduction:** 5-8MB Android, 4-6MB iOS
- **Build time:** Slightly faster dependency resolution
- **Maintenance:** Easier (fewer version conflicts)

---

## Timeline Estimate

**Total time:** 30-45 minutes (hands-on)

| Phase | Time | Complexity |
|-------|------|------------|
| Phase 1: Remove unused | 5 min | Low |
| Phase 2: Remove platform overrides | 10 min | Low |
| Phase 3: Test Dart builds | 10 min | Low |
| Phase 4: Podfile cleanup | 10-15 min | Medium |
| Phase 5: Final verification | 5 min | Low |

**Note:** Most time is waiting for builds, not manual work

---

## Next Steps

1. Review this plan
2. Ensure you have git commits to revert if needed
3. Execute Phase 1
4. Execute Phase 2
5. Execute Phase 3
6. Execute Phase 4 (with decision point)
7. Execute Phase 5
8. Document results in AUDIT_10_SUMMARY.md
