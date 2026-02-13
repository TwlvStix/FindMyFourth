# TestFlight Readiness Checklist
**Post-Audit Remaining Work**

Generated: 2026-02-13
Status: 7 items remaining (1 blocker, 6 quick wins)

---

## ✅ Already Completed (Reference)

These were identified in the Codex audit but you've already fixed them:

- ✅ Passive listeners removed (main.dart:217, 291) - DEAD_CODE_CLEANUP
- ✅ Notification singleton + cached state - AUDIT #9
- ✅ N+1 profile fetches in chat messages - AUDIT #5
- ✅ Dependency bloat cleanup (34 packages removed, 80% iOS size reduction) - AUDIT #10
- ✅ Polling/timer cleanup - DEAD_CODE_CLEANUP
- ✅ Unused code removal (~540 lines) - DEAD_CODE_CLEANUP

---

## 🔴 P0: Blocker (Fix First)

### 1. Android Release Build Failure ⚠️ BLOCKS ALL TESTING

**Problem:** `flutter build apk --release` fails with sqflite_android compile errors
```
error: cannot find symbol Build.VERSION_CODES.BAKLAVA
error: cannot find symbol Locale.of(String,String,String)
error: cannot find symbol thread.threadId()
```

**Root Cause:** JVM target 1.8 but sqflite_android uses Java 21 APIs

**Fix:**
```gradle
// android/app/build.gradle:40-41
sourceCompatibility JavaVersion.VERSION_21
targetCompatibility JavaVersion.VERSION_21

// android/app/build.gradle:45
jvmTarget = '21'

// android/build.gradle:15
jvmTarget = "21"
```

**Commands:**
```bash
# 1. Edit the 3 lines above in build.gradle files
# 2. Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release --target-platform=android-arm64

# Expected: Build succeeds
```

**Estimated Time:** 10 minutes
**Impact:** CRITICAL - Blocks release builds and size analysis
**Risk:** Low - JDK 21 is already installed (flutter doctor confirms)

**Verification:**
- [ ] `flutter build apk --release` succeeds
- [ ] No sqflite compile errors
- [ ] APK file generated in build/app/outputs/flutter-apk/

---

## 🔴 P0: Performance Blocker

### 2. Chat List N+1 Realtime Listeners

**Problem:** One Firestore `.snapshots()` listener per chat document (20 chats = 20 active listeners)

**Current Code:** `lib/services/chat_service.dart:43-63`
```dart
return query.snapshots().switchMap((snapshot) {
  final chatIds = snapshot.docs.map((doc) => doc.id).toList();

  // ❌ Creates one listener per chat
  final streams = chatIds.map(
    (chatId) => _firestore.collection('chats').doc(chatId).snapshots()
  );

  return Rx.combineLatestList<Chat?>(streams);
});
```

**Fix:** Batch with `whereIn` (max 10 per query)
```dart
return query.snapshots().switchMap((snapshot) {
  final chatIds = snapshot.docs.map((doc) => doc.id).toList();
  if (chatIds.isEmpty) return Stream.value(<Chat>[]);

  // ✅ Batch into chunks of 10
  final batches = <List<String>>[];
  for (var i = 0; i < chatIds.length; i += 10) {
    batches.add(chatIds.sublist(i, min(i + 10, chatIds.length)));
  }

  final streams = batches.map((batch) =>
    _firestore
      .collection('chats')
      .where(FieldPath.documentId, whereIn: batch)
      .snapshots()
      .map((snap) => snap.docs.map((d) => Chat.fromDoc(d)).toList())
  );

  return Rx.combineLatestList(streams).map((pages) {
    final allChats = pages.expand((p) => p).toList();
    allChats.sort((a,b) => (b.lastMessageAt ?? DateTime(1970))
        .compareTo(a.lastMessageAt ?? DateTime(1970)));
    return allChats;
  });
});
```

**⚠️ CRITICAL: Test Firestore Security Rules**
Verify your rules allow reading chats by document ID:
```javascript
match /chats/{chatId} {
  allow read: if request.auth.uid in resource.data.memberIds;
}
```

**Estimated Time:** 30 minutes + 30 minutes testing
**Impact:** HIGH - 10-20x reduction in active listeners, better battery life
**Risk:** MEDIUM - Must verify security rules and sort order

**Verification:**
- [ ] DevTools Network tab shows 1-3 listeners instead of 20
- [ ] Chat list still updates in realtime
- [ ] Chat order is correct (newest first)
- [ ] No permission denied errors
- [ ] Test with 0 chats, 5 chats, 25 chats

---

## 🟡 P1: Quick Wins (1-20 min each)

### 3. Remove .DS_Store Files from Assets

**Problem:** 9 macOS metadata files packaged in release build

**Fix:**
```bash
# 1. Delete all .DS_Store files
find assets -name ".DS_Store" -delete

# 2. Prevent future commits
echo ".DS_Store" >> .gitignore

# 3. Verify clean
find assets -name ".DS_Store"  # Should return nothing

# 4. Rebuild to confirm size reduction
flutter clean
flutter build apk --release --analyze-size
```

**Estimated Time:** 30 seconds
**Impact:** LOW - ~50KB savings, cleaner assets
**Risk:** NONE

**Verification:**
- [ ] No .DS_Store files in `find assets -name ".DS_Store"` output
- [ ] `.gitignore` contains `.DS_Store` entry
- [ ] `git status` shows deleted files ready to commit

---

### 4. Audit Gotham Font Weights

**Problem:** 16 font files (100, 200, 300, 400, 500, 600, 700, 900 weights + italics)

**Fix:**
```bash
# 1. Check which font weights are actually used
grep -r "FontWeight\." lib/ | grep -oE "FontWeight\.[a-z0-9]+" | sort -u

# 2. Identify unused weights in pubspec.yaml:126-165

# 3. Common usage pattern - you likely only need:
# - 400 (normal/Book)
# - 600 (semibold/Black)
# - 700 (bold)
# Rarely need: 100, 200, 300, 500, 900

# 4. Remove unused font entries from pubspec.yaml
# 5. Delete unused .otf files from assets/fonts/

# 6. Rebuild
flutter clean
flutter pub get
flutter build apk --release --analyze-size
```

**Estimated Time:** 5 minutes
**Impact:** MEDIUM - Potentially 1-2MB savings if many weights unused
**Risk:** LOW - Easy to revert if text looks wrong

**Verification:**
- [ ] App runs without font errors
- [ ] All text renders correctly (check bold, semibold usage)
- [ ] APK size reduced (check with `--analyze-size`)

---

### 5. Tab Page Recreation Fix

**Problem:** Tab widgets recreated on every navigation (main.dart:473-479)

**Current Code:**
```dart
final tabs = {
  'GamesList': GamesListWidget(),
  'GamesJoined': GamesJoinedWidget(),
  // ... recreated on every build()
};
body: _currentPage ?? tabs[_currentPageName],
```

**Fix:**
```dart
class _NavBarPageState extends State<NavBarPage> {
  int _currentIndex = 0;

  // ✅ Create once in initState or as late final
  late final List<Widget> _tabs = [
    GamesListWidget(),
    GamesJoinedWidget(),
    TabFriendsWidget(),
    CommunityWidget(),
    MainProfileWidget(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Use IndexedStack to preserve state
      body: _currentPage ?? IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: GNav(
        selectedIndex: _currentIndex,
        onTabChange: (i) {
          if (mounted) {
            setState(() {
              _currentPage = null;
              _currentIndex = i;
            });
          }
        },
        // ... rest of GNav config
      ),
    );
  }
}
```

**Estimated Time:** 15 minutes
**Impact:** MEDIUM - Smoother tab switching, preserves scroll position
**Risk:** LOW - Easy to test

**File:** `lib/main.dart:460-560`

**Verification:**
- [ ] Tab switching is smooth (no rebuild flicker)
- [ ] Scroll position preserved when switching tabs
- [ ] FAB still shows on correct tabs
- [ ] DevTools shows tabs build once, not on every switch

---

### 6. Remove Empty Post-Frame setState

**Problem:** 20 occurrences of `addPostFrameCallback(() => setState(() {}))`

**Current Code:** `lib/main_function/games_list/games_list_widget.dart:132-136`
```dart
@override
void initState() {
  super.initState();

  // ❌ Forces extra rebuild for no reason
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      setState(() {});
    }
  });
}
```

**Fix:** Delete the entire block (lines 132-136)

**Search Pattern:**
```bash
# Find all occurrences
grep -rn "addPostFrameCallback.*setState.*{}" lib/ --include="*.dart"
```

**Estimated Time:** 10 minutes
**Impact:** LOW-MEDIUM - One less rebuild per screen open (20 screens affected)
**Risk:** LOW - This pattern does nothing useful

**Files to Check:**
- lib/main_function/games_list/games_list_widget.dart:132
- lib/main_function/player_list/player_list_widget.dart:89
- lib/main_function/join_game_detailed/join_game_detailed_widget.dart:62
- (+ 17 more - grep will find them)

**Verification:**
- [ ] No compile errors
- [ ] Screens still render correctly
- [ ] No functional changes
- [ ] DevTools shows 1 build instead of 2 on screen open

---

### 7. Image Decode Size Hints

**Problem:** Avatar images decode at full network size (waste CPU/memory)

**Current Code:** `lib/main_function/player_list/player_list_widget.dart:520`
```dart
Image.network(
  photoUrl ?? 'default.png',
  width: 40.0,
  height: 40.0,
  fit: BoxFit.cover,
)
```

**Fix:** Add cache hints
```dart
Image.network(
  photoUrl ?? 'default.png',
  width: 40.0,
  height: 40.0,
  fit: BoxFit.cover,
  cacheWidth: 120,  // 3x for high-DPI (40 * 3 = 120)
  cacheHeight: 120,
)
```

**Files to Update:**
- lib/main_function/player_list/player_list_widget.dart:520
- lib/main_function/join_game_detailed/join_game_detailed_widget.dart:1075
- lib/main_function/game_joined_detailed/game_joined_detailed_widget.dart:690
- Any other 40x40 or 50x50 avatar Image.network calls

**Search Pattern:**
```bash
grep -rn "Image\.network" lib/ --include="*.dart" | grep -E "(40|50)\.0"
```

**Estimated Time:** 20 minutes
**Impact:** MEDIUM - 10x less memory per image, faster scrolling
**Risk:** NONE - Only affects cache size, visual output unchanged

**Verification:**
- [ ] Images still look sharp (no pixelation)
- [ ] DevTools Memory > "Image" shows smaller cache sizes
- [ ] List scroll feels smoother (profile mode)

---

## 📊 Summary

| # | Item | Priority | Time | Risk | Impact |
|---|------|----------|------|------|--------|
| 1 | Android build fix | P0 | 10m | Low | CRITICAL |
| 2 | Chat list N+1 | P0 | 60m | Med | HIGH |
| 3 | .DS_Store cleanup | P1 | 30s | None | LOW |
| 4 | Font audit | P1 | 5m | Low | MED |
| 5 | Tab IndexedStack | P1 | 15m | Low | MED |
| 6 | Empty setState | P1 | 10m | Low | MED |
| 7 | Image hints | P1 | 20m | None | MED |

**Total Time:** ~2 hours (1h critical, 1h improvements)

---

## Execution Order

1. **Item #1 (Android build)** - Do this FIRST, blocks everything else
2. **Item #3 (.DS_Store)** - 30 seconds, instant win
3. **Item #4 (Font audit)** - 5 minutes, size reduction
4. **Item #6 (setState removal)** - 10 minutes, easy
5. **Item #7 (Image hints)** - 20 minutes, safe
6. **Item #5 (Tab fix)** - 15 minutes, noticeable UX improvement
7. **Item #2 (Chat N+1)** - Last, requires careful testing

---

## Testing After All Fixes

### Build Health
```bash
flutter clean
flutter pub get
flutter analyze  # Should pass
flutter test     # Should pass
flutter build apk --release --analyze-size  # Should succeed
```

### Performance Validation
```bash
# Profile mode for frame timing
flutter run --profile -d <device>

# Open DevTools (press 'P' in terminal)
# Check:
# - Performance > Frame times (< 16ms p95)
# - Network > Active listeners (should be low)
# - Memory > Image cache size (should be reasonable)
```

### Key Metrics (Before/After)
- Active Firestore listeners when chat list open: 20 → 2-3
- .DS_Store files in assets: 9 → 0
- Font files: 16 → 6-8 (estimated)
- Unnecessary rebuilds: ~20 screens → 0
- Image decode memory: 10x reduction
- Android release build: FAIL → PASS

---

## Commit Strategy

**Option 1: Single Commit (Recommended)**
```bash
git add .
git commit -m "Performance audit fixes: Android build + N+1 + quick wins

- Fix Android JVM target (1.8 → 21) for sqflite compatibility
- Batch chat list listeners (20 → 2-3 active streams)
- Remove .DS_Store files from assets (9 files)
- Audit and remove unused Gotham font weights
- Fix tab recreation with IndexedStack
- Remove empty post-frame setState (20 occurrences)
- Add image decode size hints for 40x40 avatars

Impact: Release builds working, ~10-20x listener reduction,
        smoother tab switching, smaller binary size"
```

**Option 2: Separate Commits**
```bash
# Commit #1: Blocker fix
git add android/
git commit -m "Fix Android release build: JVM target 1.8 → 21"

# Commit #2: Performance fix
git add lib/services/chat_service.dart
git commit -m "Fix chat list N+1: batch listeners with whereIn"

# Commit #3: Quick wins
git add .
git commit -m "Performance quick wins: assets, fonts, tabs, setState, images"
```

---

## Questions / Issues?

If you hit any blockers:

1. **Android build still fails** → Check `java --version` (should be 21+)
2. **Chat whereIn fails** → Check Firestore security rules allow doc ID queries
3. **Fonts break** → Revert pubspec.yaml font section
4. **Tabs lose state** → Verify IndexedStack keys are correct
5. **Images pixelated** → Increase cacheWidth/Height multiplier

**Next Steps After Checklist:**
- Run full QA pass on physical devices (iOS + Android)
- Monitor Crashlytics for new errors
- Check Firestore usage dashboard (reads should drop)
- Prepare TestFlight build with release notes
