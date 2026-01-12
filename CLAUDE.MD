# Find My Fourth (v1) Engineering Spec

## High-Level Project Goals (v1)

### Core promise
- Let golfers quickly find the exact kind of round they want (money, competitive, social, new-in-town).
- Make it easy to create a game, fill it, confirm it, and coordinate it.

### Users supported (v1)
- Solo golfer looking to join a game
- 2–3 golfers looking to fill remaining spots
- Organizer/captain running recurring games and inviting a circle

### Region + planning window
- Initial region: Okanagan Valley
- Typical usage:
  - Find a game: next day
  - Fill a game: up to 1 week out

### Trust and transparency (non-negotiable)
- Real names required
- Usernames required
- Profile includes handicap and “vibe” preferences

### Growth-first business goal
- No monetization in v1
- Optimize for retention + referrals

### Visibility + gating (v1 decision)
- Default visibility: public but gated
- Joining is request-to-join
- Host approves/declines
- Vibe system is a soft filter (warn host, do not auto-block)

### Reviews stance (v1)
- No public star ratings in v1
- Trust signals in v1:
  - real name + username
  - gamesPlayed counter
- Optional later (not v1): private “would play again” + no-show/cancel tracking

---

## Architecture Decisions (v1)

### Overall architecture
- Feature-first structure with Clean-ish layering inside each feature:
  - presentation/ (UI)
  - application/ (Riverpod controllers, use-cases)
  - domain/ (entities, policies)
  - data/ (Firestore/Auth implementations, DTOs, mappers)

### State management + routing
- State + DI: Riverpod
- Routing: go_router

### Backend strategy
- Firebase-first (serverless) for v1:
  - Firestore as source of truth + realtime
  - Firebase Auth for sign-in
  - Cloud Functions for side effects (notifications, counters, anti-abuse)
  - FCM for push notifications

### Data model strategy
- Denormalize intentionally for list/query performance.
- Use request “snapshots” for host review (stable + fast).

---

## Tech Stack (v1)

### Core
- Flutter (stable)
- Firebase:
  - firebase_core
  - firebase_auth
  - cloud_firestore
  - firebase_messaging
  - cloud_functions

### Recommended from day 1
- firebase_crashlytics
- firebase_analytics
- firebase_app_check
- (optional) firebase_performance

### Auth providers
- Email/password
- Phone (SMS)
- Google
- Apple

### Codegen + models (required standard)
- freezed + freezed_annotation
- json_serializable + json_annotation
- build_runner

### Linting
- flutter_lints
- `flutter format` and `flutter analyze` must be clean

---

## Coding Standards (v1)

### Core rules
- No `dynamic` in app code
- Immutable models for anything persisted or shared across layers
- UI is dumb; business logic lives in domain/use-cases
- No Firestore calls in widgets

### Model rules
- Domain models use Freezed
- Firestore DTOs use JsonSerializable
- UI uses domain models only (no DTOs in UI)

### Error handling
- Repositories return Result<T> (Success / Err(Failure))
- Controllers map failures to user-facing messages
- Log unexpected exceptions (no PII)

### Routing
- Routes declared in one place (`app/router.dart`)
- No navigation logic in repositories/data layer

### Observability
- Crashlytics enabled
- Analytics events for key funnel steps:
  - create_game
  - request_join
  - approve_request
  - join_confirmed
  - message_sent (optional)

---

## Visibility + “Vibe” System (v1)

### Visibility
- Games are discoverable by region/time window
- Join is request-to-join
- Host approves/declines

### Vibe sliders (profile)
Categories:
- Music
- Drinking
- Smoking
- Gambling
- Pace of play
- Competitiveness (recommended)

Usage:
- Used as soft compatibility signals
- Host sees:
  - Great match / OK / Potential mismatch
  - Highlight mismatching categories
- No automatic blocking in v1

---

## Suggested Firestore Collections (high level)

- users/{uid}
  - realName (required)
  - username (required, unique)
  - handicap
  - vibePrefs
  - counters: gamesPlayed (v1), cancelsLate/noShows (later)
  - createdAt, updatedAt

- games/{gameId}
  - hostId
  - regionId
  - startTime
  - visibility: public_gated (default)
  - status: open | filled | cancelled | completed
  - counts: spotsTotal, spotsFilled, pendingRequests
  - createdAt, updatedAt

- games/{gameId}/requests/{requesterUid}
  - requesterId
  - status: pending | approved | declined | cancelled
  - snapshot fields for host review:
    - displayName, username, handicap, vibePrefs, gamesPlayed
  - createdAt, updatedAt

- friends/{uid}/edges/{otherUid}
  - status: pending | accepted | blocked
  - createdAt, updatedAt

- chats/{chatId}
  - type: game | dm
  - members: [uid]
  - relatedGameId (if game chat)
  - lastMessageAt, lastMessagePreview

- chats/{chatId}/messages/{messageId}
  - senderId, text, createdAt

---

## Security Rules (must-haves)

- Users can only edit their own profile
- Only host can approve/decline requests for their game
- Only host + accepted players can read game chat
- Friend edges writable only by involved users
- Blocked users cannot request/join/chat

---

## Starter Template Checklist (implementation order)

1) App bootstrap + router + Riverpod
2) Auth (email, phone, Google, Apple) with account linking
3) Profile creation gate (real name + username required)
4) Username uniqueness enforcement (recommended: claim doc)
5) Game list query (region + next-day to +7 days)
6) Game create flow
7) Join requests (request/approve/decline) + request snapshot fields
8) Game chat for accepted members
9) Notifications via Cloud Functions + FCM
10) Security rules + indexes

---

## Build Runner

One-time build:
- `flutter pub run build_runner build --delete-conflicting-outputs`

During development:
- `flutter pub run build_runner watch --delete-conflicting-outputs`
