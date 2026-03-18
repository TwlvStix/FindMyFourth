# Audit: User Home Location Data Exposure

**Date:** 2026-03-17
**Scope:** Audit-only — no code changes. Findings and recommendations.

---

## Summary

The `users` collection stores `hometown_lat`/`hometown_lng` and `home_course_lat`/`home_course_lng` fields readable by any authenticated user via `allow read: if request.auth != null`. This is intentional for nearby-game features. **No privacy policy exists in the codebase.** Coordinates come from predefined reference data (city/course lists), not user-entered addresses, making the risk lower than initially expected.

---

## 1. No Privacy Policy Exists

Searched the entire codebase — **no privacy policy file or link exists anywhere**:

- No `privacy_policy.*`, `privacy-policy.*`, or `PRIVACY_POLICY.*` files
- No `.html` or `.md` files with privacy content
- No URLs referencing a hosted privacy policy
- No in-app links to a privacy policy in Settings or onboarding
- `ios/Runner/PrivacyInfo.xcprivacy` exists but is empty (`<dict/>`)

**The only privacy-related content:**
- iOS `Info.plist` location permission string: "Find My Fourth uses your location to show nearby games."
- Android manifest declares `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION`

---

## 2. What's Stored

| Field | Type | Source | On Document |
|-------|------|--------|-------------|
| `hometown_lat` | `double?` | Denormalized from `hometown/{doc}.location.latitude` | `users/{uid}` |
| `hometown_lng` | `double?` | Denormalized from `hometown/{doc}.location.longitude` | `users/{uid}` |
| `home_course_lat` | `double?` | Denormalized from course record `.location.latitude` | `users/{uid}` |
| `home_course_lng` | `double?` | Denormalized from course record `.location.longitude` | `users/{uid}` |

**Key insight:** Coordinates come from predefined reference data, NOT from the user's actual home address. Users select a hometown from a dropdown (`HometownRecord.fetchAll()`), and the selected city's center coordinates are denormalized onto their user document. Same for home course — selected from a course list.

---

## 3. Are Coordinates Raw or Fuzzed?

**Raw — zero privacy processing.** Full-precision `double` values from reference collections are copied directly with no rounding, fuzzing, geohashing, or precision reduction:

- **Write path:** `edit_profile_widget.dart:152-153` — `hometownLocation?.latitude` passed directly
- **Storage:** `users_record.dart:444-445` — `castToType<double>(snapshotData['hometown_lat'])`
- **Read path:** `user_provider.dart:230-231` — raw double getters
- **Calculation:** `geo_utils.dart` — Haversine with raw doubles

---

## 4. Firestore Security Rules

`firebase/firestore.rules:605-608`:
```javascript
match /users/{document} {
  // Profile fields are intentionally readable by authenticated users for social features
  // (game rosters, friend requests, vibe matching, chat display).
  // Sensitive fields (email, phone) are protected in /users/{uid}/private/*.
  allow read: if request.auth != null;
```

The `hometown/` collection is also readable without authentication (`allow read: if true`).

Sensitive contact fields (email, phone) are already separated into `/users/{uid}/private/` with owner-only access (line 611-616).

---

## 5. Where Coordinates Are Used

| File | Usage |
|------|-------|
| `lib/providers/user_provider.dart:224-241` | Exposes `hometownLat`/`hometownLng`, `homeCourseLat`/`homeCourseLng`, `defaultLocationLat`/`defaultLocationLng` |
| `lib/providers/geo_filter_provider.dart` | Filters games by distance from user's location |
| `lib/games_list/games_list_widget.dart` | Initializes geo-filter with hometown coordinates |
| `lib/core/utils/geo_utils.dart` | Haversine distance calculations |

---

## Recommendations

### A. Create a Privacy Policy (Critical — App Store Requirement)

A formal privacy policy is required for both App Store and Google Play. It should cover:

1. **Location data collection**: "We collect your selected hometown and home golf course locations to enable nearby game discovery."
2. **How location is used**: "Your approximate location is used to show you games and players near you."
3. **Visibility to other users**: "Other registered users may see your general area (city/town and home course) for matchmaking purposes."
4. **What's NOT collected**: "We do not track your real-time GPS location or store your precise home address."

**Recommended paragraph:**

> **Location Information.** When you set up your profile, you select a hometown and home golf course from our directory. We store the geographic coordinates of these selections to enable location-based features such as nearby game discovery and distance-based filtering. Other registered users of Find My Fourth can see your selected city and course as part of the matchmaking experience. We do not continuously track your location or store your precise home address — location data reflects the city or course you chose, not your actual residence.

### B. Coordinate Fuzzing Assessment

**Lower urgency than initially expected.** Since coordinates come from a predefined city/course list:

- **Hometown**: An attacker learns which city a user selected — equivalent to seeing "Vancouver, BC" on a profile. City-center coordinates. **Low additional risk from raw doubles.**
- **Home course**: An attacker learns which golf course a user plays at — already visible as text in the profile. **No additional risk from coordinates.**

**Recommendation**: Fuzzing is **not necessary** given the data source is reference data. However, if you later add features that store actual GPS coordinates (check-in, real-time location), those SHOULD be fuzzed or use geohashing.

### C. Additional Items

1. **Host the privacy policy** on `findmyfourth.com/privacy` and link from:
   - App Settings screen
   - App Store / Google Play listing
   - Sign-up flow (recommended)
2. **Populate `PrivacyInfo.xcprivacy`** — Apple requires this for App Store submissions (currently empty `<dict/>`)
3. **Consider field-level security rules** — instead of `allow read: if request.auth != null` on the entire user document, a `users_public/` sub-collection could separate sensitive fields. This is a larger architectural change and not urgent given existing `/private/` pattern for contact info and the low sensitivity of location data.

---

## Critical Files Referenced

| File | Lines | Relevance |
|------|-------|-----------|
| `firebase/firestore.rules` | 605-616 | Users collection read rules + private sub-collection |
| `lib/backend/schema/users_record.dart` | 256-264, 444-445 | Field definition & initialization |
| `lib/backend/schema/hometown_record.dart` | 28-36 | Source reference data |
| `lib/profile/edit_profile/edit_profile_widget.dart` | 126-153 | Write path (denormalization) |
| `lib/providers/user_provider.dart` | 224-241 | Read/exposure path |
| `lib/providers/geo_filter_provider.dart` | — | Active usage |
| `lib/core/utils/geo_utils.dart` | — | Distance calculations |
| `ios/Runner/PrivacyInfo.xcprivacy` | — | Empty iOS privacy manifest |

---

## Verification

This is an audit-only task. No code changes. Deliverable is this report.
