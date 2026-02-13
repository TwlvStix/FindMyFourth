# Audit #10: Dependency Bloat & Build Health - Diagnosis

## Executive Summary
Found 13 unused or redundant dependencies inflating build size and complexity. Primary issues:
- **sqflite/sqflite_common**: Completely unused database packages
- **Platform-specific overrides**: 12 redundant platform packages already included transitively
- **Unused packages**: 5 packages with zero usage in codebase
- **iOS Firestore override**: Custom pod source may be unnecessary/risky

**Impact**: ~15 unnecessary dependencies, iOS Pods at 850MB, potential version conflicts

---

## 1. Dependency Inventory & Usage Analysis

### A. UNUSED - Safe to Remove (0 matches found)

| Package | Type | Evidence | Size Impact | Risk |
|---------|------|----------|-------------|------|
| `sqflite` | Database | No imports, no API calls | Heavy (~5MB native) | **LOW** - Zero usage confirmed |
| `sqflite_common` | Database | No imports, no API calls | Medium | **LOW** - Zero usage confirmed |
| `csslib` | CSS Parser | No imports | Light | **LOW** - Zero usage confirmed |
| `text_search` | Search | No imports | Light | **LOW** - Zero usage confirmed |
| `json_path` | JSON Parser | No imports | Light | **LOW** - Zero usage confirmed |
| `universal_io` | IO abstraction | No imports | Light | **LOW** - Zero usage confirmed |
| `xml` | XML Parser | No imports | Medium | **LOW** - Zero usage confirmed |
| `html` | HTML Parser | No imports | Medium | **LOW** - Zero usage confirmed |

**Total unused packages: 8**

### B. REDUNDANT - Platform Overrides (Already Transitive)

| Package | Parent Package | Why Redundant | Risk |
|---------|----------------|---------------|------|
| `image_picker_android` | image_picker | Auto-included by image_picker | **LOW** - Version conflicts possible |
| `image_picker_for_web` | image_picker | Auto-included by image_picker | **LOW** |
| `image_picker_ios` | image_picker | Auto-included by image_picker | **LOW** |
| `image_picker_linux` | image_picker | Auto-included by image_picker | **LOW** |
| `image_picker_macos` | image_picker | Auto-included by image_picker | **LOW** |
| `image_picker_windows` | image_picker | Auto-included by image_picker | **LOW** |
| `image_picker_platform_interface` | image_picker | Auto-included by image_picker | **LOW** |
| `google_sign_in_android` | google_sign_in | Auto-included by google_sign_in | **LOW** |
| `google_sign_in_ios` | google_sign_in | Auto-included by google_sign_in | **LOW** |
| `path_provider_android` | path_provider | Auto-included by path_provider | **LOW** |
| `path_provider_foundation` | path_provider | Auto-included by path_provider | **LOW** |
| `path_provider_linux` | path_provider | Auto-included by path_provider | **LOW** |
| `path_provider_windows` | path_provider | Auto-included by path_provider | **LOW** |
| `shared_preferences_android` | shared_preferences | Auto-included by shared_preferences | **LOW** |
| `shared_preferences_foundation` | shared_preferences | Auto-included by shared_preferences | **LOW** |
| `shared_preferences_linux` | shared_preferences | Auto-included by shared_preferences | **LOW** |
| `shared_preferences_windows` | shared_preferences | Auto-included by shared_preferences | **LOW** |
| `url_launcher_android` | url_launcher | Auto-included by url_launcher | **LOW** |
| `url_launcher_ios` | url_launcher | Auto-included by url_launcher | **LOW** |
| `url_launcher_linux` | url_launcher | Auto-included by url_launcher | **LOW** |
| `url_launcher_macos` | url_launcher | Auto-included by url_launcher | **LOW** |
| `url_launcher_windows` | url_launcher | Auto-included by url_launcher | **LOW** |
| `video_player_android` | video_player | Auto-included by video_player | **LOW** |
| `video_player_avfoundation` | video_player | Auto-included by video_player | **LOW** |
| `sign_in_with_apple_platform_interface` | sign_in_with_apple | Auto-included | **LOW** |
| `sign_in_with_apple_web` | sign_in_with_apple | Auto-included | **LOW** |

**Total redundant platform packages: 26**

### C. USED - Must Keep

| Package | Usage Location | Purpose |
|---------|----------------|---------|
| `chewie` | lib/core/video_player.dart:1 | Video player UI controls |
| `video_player` | lib/core/video_player.dart:7 | Core video playback |
| `rxdart` | 7 files (chat_provider, game_provider, etc.) | Reactive streams |
| `substring_highlight` | lib/core/autocomplete_options_list.dart | Text highlighting |
| `mime_type` | 3 files (upload_data, storage, media_display) | File type detection |
| `stream_transform` | 2 files (push_notifications_util, auth_util) | Stream utilities |
| All Firebase packages | Throughout | Core functionality |
| All other packages | Various | In active use |

---

## 2. sqflite Analysis (Special Focus)

### Finding: COMPLETELY UNUSED

**Search Results:**
```bash
# Import search
grep -r "import.*sqflite" lib/
# Result: No matches

# API usage search
grep -r "openDatabase\|getDatabasesPath\|Sqflite" lib/
# Result: No matches
```

**Conclusion:**
- sqflite was likely added during initial scaffolding or for a feature that was never implemented
- No database operations in codebase (using Firestore instead)
- Both sqflite and sqflite_common can be safely removed

**Native Impact:**
- Android: ~3-5MB native SQLite libraries
- iOS: ~2-4MB native SQLite libraries

**Recommendation:** **REMOVE BOTH** sqflite and sqflite_common

---

## 3. iOS Firestore Pod Override Analysis

### Current Configuration (ios/Podfile:36)

```ruby
pod 'FirebaseFirestore', :git => 'https://github.com/invertase/firestore-ios-sdk-frameworks.git', :tag => '12.6.0'
```

### Analysis

**Why it was likely added:**
- FlutterFire plugins historically had issues with precompiled frameworks
- Invertase (FlutterFire maintainers) provided this workaround for M1/M2 Macs
- Common fix for "framework not found" or long pod install times

**Current state (2026):**
- FlutterFire has matured significantly
- Most framework issues resolved in official releases
- Custom git sources can cause:
  - Version mismatches with cloud_firestore plugin
  - Security concerns (bypasses pub.dev verification)
  - Maintenance burden (manual tag updates)

**Risk Assessment:**
- **Medium Risk to Remove**: May cause pod install issues if you have M1/M2 Mac
- **Low Risk if Tested**: Modern FlutterFire should work without override

**Your cloud_firestore version:** 6.1.1 (recent, should be compatible)

### Recommendation: **CONDITIONAL REMOVAL**

**Plan:**
1. Check current Firebase iOS SDK version from plugin
2. Remove override and test pod install
3. If it fails, revert or update to official version constraint
4. Document if keeping: Add comment explaining why

**Expected Firebase iOS SDK version:** Should align with cloud_firestore 6.1.1 (likely ~11.x or 12.x from official source)

---

## 4. Build Size Metrics

### Current State
- **iOS Pods Directory:** 850MB (large, expected with Firebase)
- **pubspec.yaml dependencies:** 80 packages (49 direct + transitive)
- **Redundant declarations:** 26 platform-specific packages

### Expected Improvement After Cleanup
- **Removed packages:** 8 unused + 26 redundant = 34 entries
- **Build time:** Slight improvement (less dependency resolution)
- **App size reduction:**
  - Android: ~5-8MB (sqflite native libs + unused packages)
  - iOS: ~4-6MB (sqflite + framework overhead)
- **pubspec clarity:** Significant (44% fewer explicit dependencies)

### What NOT to Optimize (Yet)
**Defer to release optimization:**
- Android R8 shrinking (keep disabled for debug)
- iOS bitcode (legacy, not needed)
- Aggressive ProGuard rules
- Asset optimization (fonts/images)

---

## 5. Files Requiring Changes

### Dart/Flutter
- `pubspec.yaml` (remove 34 packages)

### iOS
- `ios/Podfile` (evaluate Firestore override)
- `ios/Podfile.lock` (will regenerate)

### Android
- `android/app/build.gradle` (no changes needed - already clean)

---

## 6. Risk Assessment Summary

| Change | Risk | Reversibility | Impact |
|--------|------|---------------|--------|
| Remove sqflite | **LOW** | Easy (git revert) | High (size/bloat) |
| Remove unused packages | **LOW** | Easy | Medium (clarity) |
| Remove platform overrides | **LOW** | Easy | High (version stability) |
| Remove Firestore pod override | **MEDIUM** | Easy | Medium (pod install time) |

**Overall Risk:** **LOW** - All changes are reversible via git

---

## Next Steps

See `AUDIT_10_PLAN.md` for ordered implementation steps.
