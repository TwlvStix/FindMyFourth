# Dead Code Cleanup - Execution Guide

**Project**: Find My Fourth Flutter App
**Generated**: 2026-02-03
**Status**: Ready for execution

---

## 📋 Quick Reference

| Document | Purpose |
|----------|---------|
| `DEAD_CODE_CLEANUP_PLAN.md` | Comprehensive analysis and strategy |
| `BATCH_1_unused_imports_core.patch` | Remove 11 unused imports from core files |
| `BATCH_2_unused_imports_features.patch` | Remove 22 unused imports from features |
| `BATCH_3_unused_variables.patch` | Remove 6 unused variables/fields |
| `BATCH_4_unused_functions.patch` | Remove 4-5 unused methods (~60-80 lines) |
| `BATCH_5_dead_example_files.patch` | Delete 4 example widgets (~1,180 lines) |
| `BATCH_6_unused_schema_records.patch` | Remove 3 unused schemas (~200 lines) - HIGH RISK |
| **THIS FILE** | Step-by-step execution instructions |

---

## 📊 Impact Summary

| Metric | Current | After Cleanup | Improvement |
|--------|---------|---------------|-------------|
| **Dart Files** | 189 | 182 | -7 files (-3.7%) |
| **Lines of Code** | 55,540 | ~54,050 | -1,490 lines (-2.7%) |
| **Analyzer Warnings** | 57 unused items | ~11-15 remaining | -42 to -46 warnings (-74% to -81%) |
| **Build Time** | Baseline | Slightly faster | Fewer files to analyze |

---

## 🎯 Recommended Execution Order

### Phase 1: Quick Wins (Zero Risk) - 30 minutes
1. ✅ Batch 1: Remove unused imports (core) - 5 min
2. ✅ Batch 2: Remove unused imports (features) - 10 min
3. ✅ Batch 3: Remove unused variables - 10 min
4. ✅ Run verification suite - 5 min

**Total Impact**: -39 lines, -39 warnings
**Risk**: ⭐ Very Low

---

### Phase 2: Medium Impact (Low-Medium Risk) - 1 hour
5. ✅ Batch 5: Delete example widget files - 20 min
6. ✅ Batch 4: Remove unused functions - 30 min
7. ✅ Run full test suite + manual testing - 10 min

**Total Impact**: -1,240-1,260 lines, -5 warnings
**Risk**: ⭐⭐ Low to ⭐⭐⭐ Medium

---

### Phase 3: High-Risk Database Cleanup (Optional) - 2-3 hours
8. ⚠️ Batch 6: Verify database usage - 1-2 hours
9. ⚠️ Batch 6: Remove or archive unused schemas - 30 min
10. ⚠️ Monitor production for issues - Ongoing

**Total Impact**: -200 lines, -3 warnings
**Risk**: ⭐⭐⭐⭐ Medium-High

---

## 📝 Step-by-Step Execution

### Prerequisites

```bash
# 1. Ensure you're on main branch and up to date
cd "/Users/ryanandrews/Twlv Stix Golf/Find My Fourth/find_my_fourth"
git checkout main
git pull origin main

# 2. Ensure Flutter is working
flutter --version
flutter analyze
flutter test

# 3. Record baseline metrics
echo "=== BASELINE METRICS ===" > cleanup_log.txt
echo "Date: $(date)" >> cleanup_log.txt
find lib -name "*.dart" | wc -l >> cleanup_log.txt
find lib -name "*.dart" -exec wc -l {} + | tail -1 >> cleanup_log.txt
flutter analyze 2>&1 | grep -c "warning •" >> cleanup_log.txt
```

---

### Batch 1: Core Unused Imports (5 minutes)

```bash
# Create branch
git checkout -b cleanup/batch-1-unused-imports-core

# Apply changes from BATCH_1_unused_imports_core.patch
# Edit the following files and remove specified imports:

# 1. lib/core/custom_functions.dart
#    Remove lines 1-2, 5-10, 13 (dart:convert, dart:math, google_fonts, intl, timeago, models, auth_util)

# 2. lib/core/widgets/fairway_background.dart
#    Remove line 1 (import 'dart:ui';)

# 3. lib/core/widgets/profile_hero_section.dart
#    Remove line 3 (spacing import)

# 4. lib/services/firestore_repository.dart
#    Remove line 3 (app_util import)

# 5. lib/chat_group/empty_state_simple/empty_state_simple_widget.dart
#    Remove line 2 (app_util import)

# 6. lib/main_function/game_joined_detailed/components/premium_hero_section.dart
#    Remove line 6 (app_util import)

# Verify
flutter analyze | grep "unused_import"
# Should show: 11 fewer unused_import warnings

# Commit
git add .
git commit -m "chore(batch-1): remove unused imports from core and utility files"

# Test
flutter test
flutter build apk --debug
```

**Expected Result**: ✅ -11 warnings, -11 lines

---

### Batch 2: Feature Unused Imports (10 minutes)

```bash
# Create branch
git checkout main
git checkout -b cleanup/batch-2-unused-imports-features

# Apply changes from BATCH_2_unused_imports_features.patch
# Edit 11 files as specified in the patch:

# Files to edit:
# 1. lib/friends/components/premium_friend_card.dart (remove 2 imports)
# 2. lib/friends/tab_friends/tab_friends_widget.dart (remove 3 imports)
# 3. lib/main_function/community/community_widget.dart (remove 3 imports)
# 4. lib/main_function/games_joined/games_joined_widget.dart (remove 6 imports)
# 5. lib/main_function/games_list/games_list_widget.dart (remove 4 imports)
# 6-11. Various profile and onboarding widgets (1-2 imports each)

# Verify
flutter analyze | grep "unused_import"
# Should show: 22 fewer unused_import warnings

# Commit
git add .
git commit -m "chore(batch-2): remove unused imports from feature pages"

# Test
flutter test
```

**Expected Result**: ✅ -22 warnings, -22 lines

---

### Batch 3: Unused Variables (10 minutes)

```bash
# Create branch
git checkout main
git checkout -b cleanup/batch-3-unused-variables

# Apply changes from BATCH_3_unused_variables.patch
# Remove 6 lines from 5 files:

# 1. lib/friends/components/swipeable_friend_card.dart
#    Line 42: Remove `late AnimationController _slideAnimation;`
#    Line 129: Remove `final screenWidth = MediaQuery.of(context).size.width;`

# 2. lib/main_function/player_list/player_list_widget.dart
#    Line 319: Remove `final hasOpenSlot = ...`

# 3. lib/profile/edit_vibe_importance/edit_vibe_importance_widget.dart
#    Line 368: Remove `final labelColor = ...`

# 4. lib/providers/user_provider.dart
#    Line 516: Remove `final currentUserPath = ...`

# 5. lib/services/vibe_group_matcher.dart
#    Line 161: Remove `final groupAvgFitScore = ...`

# Verify
flutter analyze | grep "unused_local_variable\|unused_field"
# Should show: 6 fewer warnings

# Commit
git add .
git commit -m "chore(batch-3): remove unused local variables and fields"

# Test
flutter test
flutter build apk --debug
```

**Expected Result**: ✅ -6 warnings, -6 lines

---

### Phase 1 Checkpoint

```bash
# Merge all Phase 1 batches
git checkout main
git merge cleanup/batch-1-unused-imports-core
git merge cleanup/batch-2-unused-imports-features
git merge cleanup/batch-3-unused-variables

# Final verification
flutter analyze
flutter test
flutter build apk --debug

# Record progress
echo "=== PHASE 1 COMPLETE ===" >> cleanup_log.txt
echo "Date: $(date)" >> cleanup_log.txt
flutter analyze 2>&1 | grep -c "warning •" >> cleanup_log.txt
echo "Expected: ~18-21 remaining warnings (57 - 39 = 18)" >> cleanup_log.txt
```

**Checkpoint**: You should have -39 lines, -39 warnings, zero errors.

---

### Batch 5: Delete Example Files (20 minutes)

**Note**: We're doing Batch 5 before Batch 4 because it's lower risk and higher impact.

```bash
# Create branch
git checkout main
git checkout -b cleanup/batch-5-delete-example-files

# Delete the four example files
rm lib/core/widgets/app_button_examples.dart
rm lib/core/widgets/app_card_examples.dart
rm lib/core/widgets/app_list_tile_examples.dart
rm lib/core/widgets/fairway_background_examples.dart

# Verify files are gone
ls lib/core/widgets/*examples.dart 2>&1
# Should show: "No such file or directory"

# Update README.md
# Option 1: Remove references (lines 185-200, checklist entries)
# Option 2: Mark as [REMOVED] with explanation
# See BATCH_5_dead_example_files.patch for specific edits

# Commit
git add .
git commit -m "chore(batch-5): delete unused example/showcase widget files

Remove 4 example widgets not used in production:
- app_button_examples.dart (~250 lines)
- app_card_examples.dart (~280 lines)
- app_list_tile_examples.dart (~200 lines)
- fairway_background_examples.dart (~450 lines)

Impact: -1,180 lines, -2.1% codebase reduction"

# Verify
flutter analyze
flutter test
flutter build apk --debug

# Should see no errors, build succeeds
```

**Expected Result**: ✅ -1,180 lines, -4 files, 0 new warnings

---

### Batch 4: Unused Functions (30 minutes)

```bash
# Create branch
git checkout main
git checkout -b cleanup/batch-4-unused-functions

# Apply changes from BATCH_4_unused_functions.patch

# 1. lib/app_state.dart
#    Remove `_safeInitAsync` method (lines ~138-146)

# 2. lib/profile/edit_vibe_importance/edit_vibe_importance_widget.dart
#    Remove `_canSave` getter (lines ~71-76)

# 3. lib/profile/profile_user/profile_user_firebase_widget.dart
#    Remove `_conflictSummary` method (line ~823)
#    Remove `_stringValue` method (line ~841)
#    Remove `_numValue` method (line ~853)

# 4. lib/user_onboarding/progressive_onboarding_widget.dart
#    First, inspect the dead code:
sed -n '255,270p' lib/user_onboarding/progressive_onboarding_widget.dart
#    Remove unreachable code after return statement (line ~260)

# Verify
flutter analyze | grep "unused_element\|dead_code"
# Should show: 4-5 fewer warnings

# Commit
git add .
git commit -m "chore(batch-4): remove unused methods and dead code"

# Test thoroughly
flutter test
flutter build apk --debug

# Manual testing recommended:
# - Test app initialization
# - Test vibe importance editor
# - Test profile views
# - Test onboarding flow
```

**Expected Result**: ✅ -60-80 lines, -4-5 warnings

---

### Phase 2 Checkpoint

```bash
# Merge Phase 2 batches
git checkout main
git merge cleanup/batch-5-delete-example-files
git merge cleanup/batch-4-unused-functions

# Final verification
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --debug

# Manual smoke test
# - Launch app
# - Navigate to key screens
# - Test critical flows

# Record progress
echo "=== PHASE 2 COMPLETE ===" >> cleanup_log.txt
echo "Date: $(date)" >> cleanup_log.txt
find lib -name "*.dart" | wc -l >> cleanup_log.txt
find lib -name "*.dart" -exec wc -l {} + | tail -1 >> cleanup_log.txt
flutter analyze 2>&1 | grep -c "warning •" >> cleanup_log.txt
echo "Expected: ~11-15 remaining warnings" >> cleanup_log.txt
```

**Checkpoint**: You should have removed ~1,300 lines total, -43-44 warnings, zero errors.

---

### Batch 6: Schema Records (Optional, 2-3 hours)

⚠️ **HIGH RISK** - Only proceed after thorough verification.

```bash
# FIRST: Complete ALL verification steps from BATCH_6_unused_schema_records.patch

# Step 1: Check Firestore Console (15 minutes)
# - Log into Firebase Console
# - Navigate to Firestore Database
# - Check if collections exist: add_players, roles, verification_dash
# - Count documents in each
# - STOP if any collection has documents

# Step 2: Check Security Rules (5 minutes)
cat firebase/firestore.rules | grep -E "(add_players|roles|verification_dash)"
# If found: STOP - collections are referenced in security

# Step 3: Check Cloud Functions (10 minutes)
find firebase/functions -name "*.js" -o -name "*.ts" | xargs grep -E "collection\(['\"]add_players"
find firebase/functions -name "*.js" -o -name "*.ts" | xargs grep -E "collection\(['\"]roles"
find firebase/functions -name "*.js" -o -name "*.ts" | xargs grep -E "collection\(['\"]verification_dash"
# If found: STOP - collections used server-side

# Step 4: Check String References (5 minutes)
grep -r "'add_players'" lib/ --include="*.dart"
grep -r "'roles'" lib/ --include="*.dart" | grep -v "roles_record"
grep -r "'verification_dash'" lib/ --include="*.dart"
# If found: STOP - collections referenced via strings

# Step 5: Team Consultation (30-60 minutes)
# - Ask product/engineering team about these collections
# - Document why they exist
# - Decide: DELETE, ARCHIVE, or KEEP

# IF ALL CHECKS PASS, proceed with ARCHIVE (safer than delete):
git checkout main
git checkout -b cleanup/batch-6-archive-unused-schemas

# Create archive directory
mkdir -p lib/backend/schema/archived

# Move (don't delete) schema files
mv lib/backend/schema/add_players_record.dart lib/backend/schema/archived/
mv lib/backend/schema/roles_record.dart lib/backend/schema/archived/
mv lib/backend/schema/verification_dash_record.dart lib/backend/schema/archived/

# Create README in archived folder
cat > lib/backend/schema/archived/README.md << 'EOF'
# Archived Schema Records
These were archived on 2026-02-03 due to zero usage in codebase.
Firestore collections verified as empty/non-existent.
Can be restored if needed in future.
EOF

# Remove exports from backend.dart
# (Edit lib/backend/backend.dart - remove imports and exports for these 3 records)

# Remove exports from schema/index.dart
# (Edit lib/backend/schema/index.dart - remove 3 export lines)

# Commit
git add .
git commit -m "chore(batch-6): archive unused schema records

Moved to lib/backend/schema/archived/:
- add_players_record.dart
- roles_record.dart
- verification_dash_record.dart

Verification completed:
- Collections empty/non-existent in Firestore
- No security rules references
- No Cloud Functions usage
- No string-based references found

Impact: -~200 lines from active codebase"

# Verify
flutter analyze
flutter test
flutter build apk --debug

# Deploy and monitor
echo "⚠️ IMPORTANT: Monitor production after deploying this change"
echo "- Check Firebase Console > Firestore > Errors"
echo "- Check crash reporting for schema errors"
echo "- Check Cloud Functions logs"
echo "- Monitor for 48 hours before considering successful"
```

**Expected Result**: ✅ -~200 lines (archived, not deleted), -3 warnings, 0 errors
**Risk**: HIGH - Monitor production carefully

---

## ✅ Final Verification Checklist

After completing all batches:

```bash
cd "/Users/ryanandrews/Twlv Stix Golf/Find My Fourth/find_my_fourth"

# 1. Static Analysis
flutter analyze
# Expected: ~11-15 warnings (mostly deprecation warnings for withOpacity)
# Expected: 0 errors
# Expected: -42 to -46 unused_* warnings compared to baseline

# 2. Unit Tests
flutter test
# Expected: All tests pass
# Expected: No new test failures

# 3. Build
flutter clean
flutter pub get
flutter build apk --debug
# Expected: Build succeeds
# Expected: Similar or faster build time

# 4. Code Metrics
echo "=== FINAL METRICS ===" >> cleanup_log.txt
echo "Date: $(date)" >> cleanup_log.txt
find lib -name "*.dart" | wc -l >> cleanup_log.txt
find lib -name "*.dart" -exec wc -l {} + | tail -1 >> cleanup_log.txt
flutter analyze 2>&1 | grep -c "warning •" >> cleanup_log.txt

# 5. Compare Before/After
echo "=== COMPARISON ===" >> cleanup_log.txt
echo "See cleanup_log.txt for before/after metrics"

# 6. Generate Report
cat cleanup_log.txt
```

---

## 📱 Manual Testing Checklist

Test these flows after cleanup to ensure no regressions:

### Critical Paths:
- [ ] App launches successfully
- [ ] User can sign in / sign up
- [ ] User can create a profile
- [ ] User can create a game
- [ ] User can join a game
- [ ] User can view their games
- [ ] User can chat in game chat
- [ ] User can view another user's profile
- [ ] User can edit their profile
- [ ] User can edit vibe settings
- [ ] Onboarding flow works end-to-end

### Secondary Paths:
- [ ] User can search for friends
- [ ] User can view friend requests
- [ ] User can view notifications
- [ ] User can view game details
- [ ] User can leave a game
- [ ] User can view community tab

---

## 🚀 Deployment Strategy

### Option A: All at Once (Recommended for smaller apps)
```bash
# Merge all batches to main
git checkout main
git merge cleanup/batch-1-unused-imports-core
git merge cleanup/batch-2-unused-imports-features
git merge cleanup/batch-3-unused-variables
git merge cleanup/batch-5-delete-example-files
git merge cleanup/batch-4-unused-functions
# git merge cleanup/batch-6-archive-unused-schemas  # Optional

# Final verification
flutter analyze
flutter test
flutter build apk --release

# Deploy
git push origin main
```

### Option B: Phased Rollout (Recommended for larger apps)
```bash
# Week 1: Deploy Phase 1 (zero risk)
git checkout main
git merge cleanup/batch-1-unused-imports-core
git merge cleanup/batch-2-unused-imports-features
git merge cleanup/batch-3-unused-variables
git push origin main
# Deploy to production
# Monitor for 2-3 days

# Week 2: Deploy Phase 2 (low-medium risk)
git checkout main
git merge cleanup/batch-5-delete-example-files
git merge cleanup/batch-4-unused-functions
git push origin main
# Deploy to production
# Monitor for 2-3 days

# Week 3: Deploy Phase 3 (high risk - optional)
# Only if Batch 6 verification passed
git checkout main
git merge cleanup/batch-6-archive-unused-schemas
git push origin main
# Deploy to production
# Monitor closely for 7 days
```

---

## 🔄 Rollback Procedures

### If issues found after deployment:

```bash
# Rollback entire cleanup
git checkout main
git revert <commit-hash-range>
git push origin main

# Or rollback specific batch
git revert <batch-commit-hash>
git push origin main

# Or restore archived schema files (Batch 6 only)
mv lib/backend/schema/archived/*.dart lib/backend/schema/
# Re-add exports to backend.dart and schema/index.dart
git add .
git commit -m "rollback: restore archived schema records"
git push origin main
```

---

## 📈 Success Criteria

### Quantitative:
- ✅ Reduced codebase by ~1,490 lines (2.7%)
- ✅ Removed 7 unused Dart files
- ✅ Reduced analyzer warnings by 74-81%
- ✅ Zero new errors introduced
- ✅ All tests passing
- ✅ Build time same or faster

### Qualitative:
- ✅ Codebase is cleaner and easier to navigate
- ✅ Reduced maintenance burden
- ✅ Faster code search and IDE indexing
- ✅ No behavioral changes
- ✅ No production issues reported

---

## 📞 Support

If you encounter issues:

1. **Check the patch files**: Each batch has detailed verification steps
2. **Review cleanup_log.txt**: Compare before/after metrics
3. **Check git history**: `git log --oneline --graph`
4. **Rollback if needed**: See Rollback Procedures above
5. **Re-run verification**: `flutter analyze && flutter test`

---

## 📝 Notes

- All changes are backward compatible
- No API changes
- No database schema changes (Batch 6 only archives/removes unused schemas)
- No configuration changes
- No dependency changes

---

**Estimated Total Time**:
- Phase 1: 30 minutes
- Phase 2: 1 hour
- Phase 3 (optional): 2-3 hours
- **Total**: 1.5 - 4.5 hours

**Recommended Approach**:
- Do Phase 1 + Phase 2 (Batches 1-5) immediately
- Skip Batch 6 or archive instead of delete
- Total time: ~1.5 hours with immediate value

---

**Ready to begin? Start with Batch 1!** ✨
