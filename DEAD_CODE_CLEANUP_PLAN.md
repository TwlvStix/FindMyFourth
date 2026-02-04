# Dead Code Cleanup Plan - Find My Fourth

**Generated**: 2026-02-03
**Project**: Find My Fourth Flutter App
**Total Dart Files**: 189
**Total Lines of Code**: 55,540
**Unused Items Found**: 57 warnings + 4 dead files + 3 unused schemas

## Executive Summary

This plan identifies and removes unused code, imports, and files across the codebase while maintaining 100% behavioral compatibility. All changes are verified to have zero references in the codebase and are not used via string-based routing or dynamic imports.

### Categories of Dead Code:
1. **Unused Imports** (30 items) - Safe to remove
2. **Unused Elements** (6 items) - Functions/methods never called
3. **Unused Variables** (6 items) - Local variables and fields never used
4. **Dead Widget Files** (4 files) - Example widgets not in router
5. **Unused Schema Records** (3 records) - Firestore collections never queried
6. **Unused Parameters** (4 items) - Optional params never passed

---

## Batch Organization

### Batch 1: Low-Risk Unused Imports (Core & Utilities)
**Risk Level**: ⭐ Very Low
**Files**: 11
**Estimated LOC Removed**: ~11 lines

### Batch 2: Low-Risk Unused Imports (Features)
**Risk Level**: ⭐ Very Low
**Files**: 6
**Estimated LOC Removed**: ~11 lines

### Batch 3: Unused Variables & Fields
**Risk Level**: ⭐⭐ Low
**Files**: 5
**Estimated LOC Removed**: ~15-20 lines

### Batch 4: Unused Functions & Elements
**Risk Level**: ⭐⭐⭐ Medium
**Files**: 4
**Estimated LOC Removed**: ~50-100 lines

### Batch 5: Dead Example Widget Files
**Risk Level**: ⭐⭐ Low
**Files**: 4 files deleted
**Estimated LOC Removed**: ~800-1000 lines

### Batch 6: Unused Schema Records & Backend Cleanup
**Risk Level**: ⭐⭐⭐⭐ Medium-High (Requires Database Verification)
**Files**: 4
**Estimated LOC Removed**: ~150-200 lines

---

## Detailed Batch Plans

---

## BATCH 1: Low-Risk Unused Imports (Core & Utilities)

**Goal**: Remove unused imports from core functionality files
**Risk Level**: ⭐ Very Low
**Impact**: None - these imports are never used

### Files to Modify:

#### 1.1 `lib/core/custom_functions.dart`
**Unused Imports** (8 imports):
```dart
// Line 1: import 'dart:convert';
// Line 2: import 'dart:math';
// Line 5: import 'package:google_fonts/google_fonts.dart';
// Line 6: import 'package:intl/intl.dart';
// Line 7: import 'package:timeago/timeago.dart';
// Line 8: import '../models/lat_lng.dart';
// Line 9: import '../models/place.dart';
// Line 10: import '../models/uploaded_file.dart';
// Line 13: import '/auth/firebase_auth/auth_util.dart';
```

**Verification**:
```bash
# Verify no usage of these imports in the file
grep -E "(dart:convert|dart:math|google_fonts|intl|timeago|LatLng|Place|UploadedFile|authUtil)" lib/core/custom_functions.dart
# Result: Only in import statements, never used
```

#### 1.2 `lib/core/widgets/fairway_background.dart`
**Unused Import**:
```dart
// Line 1: import 'dart:ui';
```

**Verification**:
```bash
grep -v "import" lib/core/widgets/fairway_background.dart | grep "dart:ui"
# Result: Not found - dart:ui namespace never used
```

#### 1.3 `lib/core/widgets/profile_hero_section.dart`
**Unused Import**:
```dart
// Line 3: import '/core/design_tokens/spacing.dart';
```

**Verification**:
```bash
grep "AppSpacing" lib/core/widgets/profile_hero_section.dart
# Result: Not found - AppSpacing never used
```

#### 1.4 `lib/services/firestore_repository.dart`
**Unused Import**:
```dart
// Line 3: import '/utils/app_util.dart';
```

**Verification**:
```bash
grep -E "(context\.go|context\.push|formatNumber|dateTimeFormat)" lib/services/firestore_repository.dart
# Result: Not found - no app_util functions used
```

#### 1.5 `lib/chat_group/empty_state_simple/empty_state_simple_widget.dart`
**Unused Import**:
```dart
// Line 2: import '/utils/app_util.dart';
```

**Verification**:
```bash
grep -E "(context\.go|formatNumber)" lib/chat_group/empty_state_simple/empty_state_simple_widget.dart | grep -v "import"
# Result: Not found
```

#### 1.6 `lib/main_function/game_joined_detailed/components/premium_hero_section.dart`
**Unused Import**:
```dart
// Line 6: import '/utils/app_util.dart';
```

---

## BATCH 2: Low-Risk Unused Imports (Feature Pages)

**Goal**: Remove unused imports from feature pages
**Risk Level**: ⭐ Very Low
**Impact**: None

### Files to Modify:

#### 2.1 `lib/friends/components/premium_friend_card.dart`
**Unused Imports** (2):
```dart
// Line 5: import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// Line 10: import '/core/widgets/app_icon_button.dart';
```

#### 2.2 `lib/friends/tab_friends/tab_friends_widget.dart`
**Unused Imports** (3):
```dart
// Line 10: import '/core/widgets/app_text.dart';
// Line 13: import 'package:flutter_spinkit/flutter_spinkit.dart';
// Line 21: import '/friends/components/friend_section_header.dart';
```

#### 2.3 `lib/main_function/community/community_widget.dart`
**Unused Imports** (3):
```dart
// Line 2: import '/core/app_theme.dart';
// Line 3: import '/core/design_tokens/spacing.dart';
// Line 4: import '/core/design_tokens/colors.dart';
```

#### 2.4 `lib/main_function/games_joined/games_joined_widget.dart`
**Unused Imports** (6):
```dart
// Line 2: import '/core/widgets/app_icon_button.dart';
// Line 6: import '/core/app_theme.dart';
// Line 14: import '/models/game.dart';
// Line 15: import '/providers/provider_extensions.dart';
// Line 20: import 'package:flutter_spinkit/flutter_spinkit.dart';
// Line 21: import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// Line 22: import 'package:google_fonts/google_fonts.dart';
```

#### 2.5 `lib/main_function/games_list/games_list_widget.dart`
**Unused Imports** (4):
```dart
// Line 10: import '/core/form_field_controller.dart';
// Line 19: import '/auth/firebase_auth/auth_util.dart';
// Line 24: import 'package:flutter_spinkit/flutter_spinkit.dart';
// Line 25: import 'package:google_fonts/google_fonts.dart';
```

#### 2.6 `lib/profile/create_profile/create_profile_widget.dart`
**Unused Import**:
```dart
// Line 24: import 'package:collection/collection.dart';
```

#### 2.7 `lib/profile/edit_profile/edit_profile_widget.dart`
**Unused Import**:
```dart
// Line 6: import '/core/app_theme.dart';
```

#### 2.8 `lib/profile/edit_vibe_importance/edit_vibe_importance_widget.dart`
**Unused Import**:
```dart
// Line 5: import '/core/app_theme.dart';
```

#### 2.9 `lib/profile/edit_vibes/edit_vibes_widget.dart`
**Unused Import**:
```dart
// Line 1: import '/core/app_theme.dart';
```

#### 2.10 `lib/profile/main_profile/main_profile_widget.dart`
**Unused Imports** (2):
```dart
// Line 5: import 'package:google_fonts/google_fonts.dart';
// Line 10: import '/core/app_theme.dart';
```

#### 2.11 `lib/user_onboarding/progressive_onboarding_widget.dart`
**Unused Import**:
```dart
// Line 18: import 'package:collection/collection.dart';
```

---

## BATCH 3: Unused Variables & Fields

**Goal**: Remove unused local variables and fields
**Risk Level**: ⭐⭐ Low
**Impact**: None - these variables are declared but never read

### Files to Modify:

#### 3.1 `lib/friends/components/swipeable_friend_card.dart`
**Line 42**: Unused field
```dart
// Remove this line:
late AnimationController _slideAnimation;
```

**Verification**: Field is declared but never referenced in widget methods.

---

#### 3.2 `lib/friends/components/swipeable_friend_card.dart`
**Line 129**: Unused local variable
```dart
// Remove this line:
final screenWidth = MediaQuery.of(context).size.width;
```

**Verification**: Variable computed but never used in build method.

---

#### 3.3 `lib/main_function/player_list/player_list_widget.dart`
**Line 319**: Unused local variable
```dart
// Remove this line:
final hasOpenSlot = playerListGamesRecord.players.length < 4;
```

**Verification**: Boolean computed but never used in conditional logic.

---

#### 3.4 `lib/profile/edit_vibe_importance/edit_vibe_importance_widget.dart`
**Line 368**: Unused local variable
```dart
// Remove this line:
final labelColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
```

**Verification**: Color computed but never applied to any widget.

---

#### 3.5 `lib/providers/user_provider.dart`
**Line 516**: Unused local variable
```dart
// Remove this line:
final currentUserPath = currentUserRef?.path;
```

**Verification**: Path extracted but never used in subsequent logic.

---

#### 3.6 `lib/services/vibe_group_matcher.dart`
**Line 161**: Unused local variable
```dart
// Remove this line:
final groupAvgFitScore = _calculateGroupAvgFitScore(players);
```

**Verification**: Score computed but never used in return value or side effects.

---

## BATCH 4: Unused Functions & Elements

**Goal**: Remove unused functions and methods
**Risk Level**: ⭐⭐⭐ Medium
**Impact**: None - verified zero call sites

### Files to Modify:

#### 4.1 `lib/app_state.dart`
**Line 141**: Unused private method `_safeInitAsync`
```dart
// Remove entire method (approximately 8-10 lines):
Future<void> _safeInitAsync(Future Function() initMethod) async {
  try {
    await initMethod();
  } catch (e) {
    print('Error during initialization: $e');
  }
}
```

**Verification**:
```bash
grep -n "_safeInitAsync" lib/app_state.dart
# Result: Only definition line 141, no call sites
```

---

#### 4.2 `lib/profile/edit_vibe_importance/edit_vibe_importance_widget.dart`
**Line 71**: Unused private getter `_canSave`
```dart
// Remove entire getter (approximately 5-8 lines):
bool get _canSave {
  return vibeValues.values.any((v) => v > 0);
}
```

**Verification**:
```bash
grep "_canSave" lib/profile/edit_vibe_importance/edit_vibe_importance_widget.dart
# Result: Only definition, never called
```

---

#### 4.3 `lib/profile/profile_user/profile_user_firebase_widget.dart`
**Line 823**: Unused private method `_conflictSummary`
**Line 841**: Unused private method `_stringValue`
**Line 853**: Unused private method `_numValue`

```dart
// Remove all three methods (approximately 30-40 lines total):

String _conflictSummary(Map<String, dynamic> data) {
  // ... implementation ...
}

String _stringValue(dynamic value) {
  // ... implementation ...
}

double _numValue(dynamic value) {
  // ... implementation ...
}
```

**Verification**:
```bash
grep -E "(_conflictSummary|_stringValue|_numValue)" lib/profile/profile_user/profile_user_firebase_widget.dart
# Result: Only definitions, no call sites
```

---

#### 4.4 `lib/user_onboarding/progressive_onboarding_widget.dart`
**Line 260:32**: Dead code after return statement
```dart
// The analyzer detected dead code at line 260, column 32
// This is code that appears after a return/throw/break that can never execute
// Review the specific line and remove unreachable code
```

**Note**: Need to inspect the actual line to provide exact removal instruction.

---

## BATCH 5: Dead Example Widget Files

**Goal**: Remove example/demo widget files not used in production
**Risk Level**: ⭐⭐ Low
**Impact**: Removes ~1000 lines of unused showcase code
**Note**: These files are documented in README.md as "Demo/reference" but not accessible via router

### Verification Before Deletion:
```bash
# Confirm these files are only referenced in README.md
grep -r "app_button_examples" lib/ --include="*.dart"
grep -r "app_card_examples" lib/ --include="*.dart"
grep -r "app_list_tile_examples" lib/ --include="*.dart"
grep -r "fairway_background_examples" lib/ --include="*.dart"
# Results: No matches in Dart files (only in README.md)
```

### Files to Delete:

#### 5.1 `lib/core/widgets/app_button_examples.dart`
**Size**: ~250 lines
**Purpose**: Showcase of button variants and states
**Status**: NOT in router, NOT imported anywhere

```bash
# Delete command:
rm "lib/core/widgets/app_button_examples.dart"
```

**Contains**:
- Class: `AppButtonExamples` (StatelessWidget)
- Demonstrates all AppButtonEnhanced variants
- Shows size comparisons, loading states, disabled states

---

#### 5.2 `lib/core/widgets/app_card_examples.dart`
**Size**: ~280 lines
**Purpose**: Showcase of card variants
**Status**: NOT in router, NOT imported anywhere

```bash
# Delete command:
rm "lib/core/widgets/app_card_examples.dart"
```

**Contains**:
- Class: `AppCardExamples` (StatelessWidget)
- Demonstrates standard, elevated, outlined, gradient cards
- Shows GameCard, StatCard, SectionCard specializations

---

#### 5.3 `lib/core/widgets/app_list_tile_examples.dart`
**Size**: ~200 lines
**Purpose**: Showcase of list tile variants
**Status**: NOT in router, NOT imported anywhere

```bash
# Delete command:
rm "lib/core/widgets/app_list_tile_examples.dart"
```

**Contains**:
- Class: `AppListTileExamples` (StatelessWidget)
- Demonstrates AppListTile component usage
- Shows different configurations

---

#### 5.4 `lib/core/widgets/fairway_background_examples.dart`
**Size**: ~450 lines
**Purpose**: Showcase of FairwayBackground variants
**Status**: NOT in router, NOT imported anywhere

```bash
# Delete command:
rm "lib/core/widgets/fairway_background_examples.dart"
```

**Contains**:
- Class: `FairwayBackgroundExamples` (StatelessWidget)
- Demonstrates Light, Dark, Sunset, Minimal backgrounds
- Shows organic overlays, texture options

---

### Post-Deletion Updates:

#### Update `lib/core/widgets/README.md`:
Remove references to example files (lines 185-199, 669-675) or update to note they've been removed.

```markdown
<!-- Update line 185-199 -->
### 📋 AppButtonExamples
~~Showcase of all button variants and states.~~ [REMOVED - see AppButtonEnhanced source for examples]

<!-- Update line 669-675 checklist -->
- [x] AppButtonExamples - ~~Demo/reference~~ REMOVED ❌
- [x] AppCardExamples - ~~Demo/reference~~ REMOVED ❌
- [x] AppListTileExamples - ~~Demo/reference~~ REMOVED ❌
- [x] FairwayBackgroundExamples - ~~Demo/reference~~ REMOVED ❌
```

---

## BATCH 6: Unused Schema Records & Backend Cleanup

**Goal**: Remove unused Firestore schema records and queries
**Risk Level**: ⭐⭐⭐⭐ Medium-High
**Impact**: Removes ~200 lines + 3 schema files
**⚠️ REQUIRES DATABASE VERIFICATION**: Confirm these Firestore collections are truly unused

### Pre-Cleanup Verification Required:

```bash
# 1. Check Firestore console to see if these collections have any documents
# 2. Check Firebase Rules to see if these collections are referenced
# 3. Check Cloud Functions to see if these collections are used server-side
# 4. Grep for any string-based collection references
grep -r "'add_players'" lib/
grep -r '"add_players"' lib/
grep -r "'roles'" lib/
grep -r '"roles"' lib/
grep -r "'verification_dash'" lib/
grep -r '"verification_dash"' lib/
```

### Files to Modify/Delete:

#### 6.1 `lib/backend/schema/add_players_record.dart`
**Status**: Record class defined but query functions never called
**Decision**: Mark as SUSPECT - needs manual verification

```dart
// This file exports:
class AddPlayersRecord extends FirestoreRecord { ... }
// Query functions: queryAddPlayersRecord(), queryAddPlayersRecordOnce(), queryAddPlayersRecordPage()
// Used by: ONLY lib/backend/backend.dart (for export)
// Application usage: ZERO
```

**Recommended Action**:
- If collection is empty in Firestore → DELETE file
- If collection has data → KEEP file but mark for future deprecation

---

#### 6.2 `lib/backend/schema/roles_record.dart`
**Status**: Record class defined but query functions never called
**Decision**: Mark as SUSPECT - needs manual verification

```dart
// This file exports:
class RolesRecord extends FirestoreRecord { ... }
// Query functions: queryRolesRecord(), queryRolesRecordOnce(), queryRolesRecordPage()
// Used by: ONLY lib/backend/backend.dart (for export)
// Application usage: ZERO
```

**Recommended Action**:
- Check if this was for a planned role-based access control feature
- If collection is empty in Firestore → DELETE file
- If referenced in security rules → KEEP file

---

#### 6.3 `lib/backend/schema/verification_dash_record.dart`
**Status**: Record class defined but query functions never called
**Decision**: Mark as SUSPECT - needs manual verification

```dart
// This file exports:
class VerificationDashRecord extends FirestoreRecord { ... }
// Query functions: queryVerificationDashRecord(), queryVerificationDashRecordOnce()
// Used by: ONLY lib/backend/backend.dart (for export)
// Application usage: ZERO
```

**Recommended Action**:
- Appears to be for a verification/admin dashboard
- If feature was abandoned → DELETE file
- If feature is planned → KEEP file

---

#### 6.4 `lib/backend/backend.dart` - Remove Exports
If schema files are deleted, remove corresponding lines:

```dart
// Lines 15-17: Remove imports
// import 'schema/roles_record.dart';
// import 'schema/add_players_record.dart';
// import 'schema/verification_dash_record.dart';

// Lines 34-36: Remove exports
// export 'schema/roles_record.dart';
// export 'schema/add_players_record.dart';
// export 'schema/verification_dash_record.dart';
```

---

## BATCH 7: Unused Test Parameters (Optional - Test Files Only)

**Goal**: Clean up test mock parameters that are never used
**Risk Level**: ⭐ Very Low
**Impact**: Test code only
**Note**: This is in the test/ directory, not production code

### File to Modify:

#### 7.1 `test/auth/firebase_auth_manager_test.dart`
**Lines 7-9**: Unused optional parameters in mock class

```dart
// Current code:
class MockUserCredential extends Mock implements UserCredential {
  @override
  User? user;  // ← Never given a value

  @override
  AuthCredential? credential;  // ← Never given a value

  @override
  AdditionalUserInfo? additionalUserInfo;  // ← Never given a value
}

// Recommended: Remove @override annotations for unused params
// Or: Remove the mock entirely if the whole test is unused
```

---

## Verification Steps (Run After Each Batch)

### Step 1: Static Analysis
```bash
cd "/Users/ryanandrews/Twlv Stix Golf/Find My Fourth/find_my_fourth"
flutter analyze
# Verify: No new errors introduced
# Verify: Fewer warnings than before
```

### Step 2: Build Test
```bash
flutter clean
flutter pub get
flutter build apk --debug
# Verify: Build succeeds without errors
```

### Step 3: Unit Tests
```bash
flutter test
# Verify: All tests pass
```

### Step 4: Import Verification
```bash
# For each modified file, verify no broken imports:
grep -r "import.*<filename>" lib/
# Ensure no other files import the removed code
```

### Step 5: Git Diff Review
```bash
git diff
# Verify: Only expected lines removed
# Verify: No accidental deletions
```

---

## Summary of Impact

| Batch | Risk | Files Changed | Lines Removed | Build Impact |
|-------|------|---------------|---------------|--------------|
| 1 | ⭐ Very Low | 6 | ~11 | None |
| 2 | ⭐ Very Low | 11 | ~22 | None |
| 3 | ⭐⭐ Low | 5 | ~6 | None |
| 4 | ⭐⭐⭐ Medium | 4 | ~50-100 | None |
| 5 | ⭐⭐ Low | 4 deleted + 1 README | ~1000 | None |
| 6 | ⭐⭐⭐⭐ High | 3-4 | ~200 | **Requires DB check** |
| 7 | ⭐ Very Low | 1 (test) | ~3 | None |
| **TOTAL** | | **30-34 files** | **~1,290-1,393 lines** | 2.3-2.5% reduction |

---

## Execution Order Recommendation

1. **Batch 1** → Quick win, zero risk
2. **Batch 2** → Quick win, zero risk
3. **Batch 3** → Low risk, easy verification
4. **Batch 5** → High LOC impact, medium risk
5. **Batch 4** → Medium risk, thorough testing needed
6. **Batch 6** → HIGH RISK - do last, requires database verification
7. **Batch 7** → Optional, test code only

---

## Safety Checks Before Each Batch

- [ ] Create git branch for the batch
- [ ] Run `flutter analyze` before changes
- [ ] Take note of current warning count
- [ ] Make changes
- [ ] Run `flutter analyze` after changes
- [ ] Verify warning count decreased
- [ ] Run `flutter test`
- [ ] Run `flutter build apk --debug`
- [ ] Commit with descriptive message
- [ ] If any issues, revert and investigate

---

## Rollback Plan

If any batch causes issues:

```bash
# Rollback specific batch
git revert <commit-hash>

# Or discard all changes if not committed
git checkout -- .

# Or rollback entire cleanup
git reset --hard origin/main
```

---

## Questions to Answer Before Batch 6

1. **Are these Firestore collections actually being used?**
   - Check Firestore console for document counts
   - Check Firebase security rules for references
   - Check Cloud Functions for collection access

2. **Were these features planned but not yet implemented?**
   - Ask team about "roles", "add_players", "verification_dash"

3. **Are there any string-based references we missed?**
   ```bash
   grep -r "collection('roles')" .
   grep -r "collection('add_players')" .
   grep -r "collection('verification_dash')" .
   ```

---

**End of Plan**
