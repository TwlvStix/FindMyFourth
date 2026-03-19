# External Integrations & Services

## Firebase Services

### Authentication (`firebase_auth` 6.2.0)
- **Providers**: Email/Password, Google Sign-In, Apple Sign-In, Phone SMS, Anonymous, JWT, GitHub
- **Files**:
  - `lib/auth/firebase_auth/firebase_auth_manager.dart`
  - `lib/auth/firebase_auth/google_auth.dart`
  - `lib/auth/firebase_auth/apple_auth.dart`
  - `lib/auth/firebase_auth/email_auth.dart`
  - `lib/auth/firebase_auth/phone_auth.dart`
  - `lib/auth/firebase_auth/anonymous_auth.dart`
  - `lib/auth/firebase_auth/jwt_token_auth.dart`
  - `lib/auth/firebase_auth/github_auth.dart`

### Cloud Firestore (`cloud_firestore` 6.1.3)
- Real-time database with security rules
- Batch operations and transactions
- Region: `us-west2`

### Cloud Functions (`cloud_functions` 6.0.7 / `firebase-functions` 7.0.6)
- HTTPS callable functions
- OnRequest HTTP handlers with OIDC verification
- Event triggers (onCreate, onUpdate, onDelete)
- Region: `us-west2`

**Main Function Modules**:
| Module | Purpose |
|--------|---------|
| `index.js` | Entry point, exports all functions |
| `confirmation_flow.js` | Game confirmation & round job processing |
| `trust_system.js` | Trust score calculations |
| `trust_profile.js` | Trust profile management |
| `game_alerts.js` | Push notifications for new games |
| `streaks.js` | Streak calculation & tracking |
| `challenge_progress.js` | Challenge progress updates |
| `host_add_notifications.js` | Host add notifications |
| `join_request_notifications.js` | Join request notifications |
| `avatar-generator.js` | Initials avatar generation |
| `season_reset.js` | Seasonal resets |
| `cleanup.js` | Data cleanup tasks |

### Firebase Storage (`firebase_storage` 13.1.0)
- User profile photos, game images, avatars, chat attachments
- Bucket: `find-my-fourth.appspot.com`

### Push Notifications (`firebase_messaging` 16.1.2)
- FCM token management per device
- Foreground message handling
- Quiet hours support (Vancouver timezone, default 22:00-07:00)
- Delivery tracking via `notification_receipts` collection
- **Files**:
  - `lib/services/fcm_notification_service.dart`
  - `lib/services/notification_orchestration_service.dart`
  - `lib/services/local_notifications_service.dart`
  - `lib/services/notification_permission_service.dart`
  - `lib/services/notification_audit_service.dart`

### Firebase Crashlytics (`firebase_crashlytics` ^5.0.8)
- Error tracking and crash reporting
- Custom error logging
- Toggle: `CRASHLYTICS_ENABLED` build flag

### Firebase Analytics (`firebase_analytics` ^12.1.3)
- Event and session tracking

### Firebase Remote Config (`firebase_remote_config` ^6.2.0)
- Vibe floor threshold (default: 30)
- Dynamic feature flags
- Cache management with async refresh

### Firebase App Check (`firebase_app_check` ^0.4.1+5)
- Android: PlayIntegrity (prod), Debug provider (dev)
- Apple: AppAttest + DeviceCheck fallback (prod), Debug (dev)
- Web: Intentionally disabled (reCAPTCHA not configured)

### Firebase Performance (`firebase_performance` 0.11.1+5)
- Installed; not actively used for custom traces

---

## External Service Integrations

### SendGrid (`@sendgrid/mail` ^8.0.0)
- Transactional email (signup, welcome)
- Config: `SENDGRID_API_KEY` environment variable
- File: `firebase/functions/index.js`

### Google Cloud Tasks (`@google-cloud/tasks` ^6.2.1)
- Deferred notification scheduling
- Deterministic task naming for idempotency
- Queue: `trust-notification-scheduler`
- Region: `us-west2`
- OIDC token verification
- Service account: `find-my-fourth@appspot.gserviceaccount.com`
- Retries: 3 (10s-300s exponential backoff)
- **Files**:
  - `firebase/functions/notifications/trust/scheduler.js`
  - `firebase/functions/confirmation_flow.js`

### Sharp (`sharp` ^0.33.2)
- Server-side image processing for avatar generation
- File: `firebase/functions/avatar-generator.js`

### LangChain AI Suite
| Package | Version | Provider |
|---------|---------|----------|
| `@langchain/anthropic` | ^0.1.1 | Claude |
| `@langchain/openai` | ^0.3.14 | OpenAI |
| `@langchain/google-genai` | ^0.0.8 | Google AI |
| `@langchain/langgraph` | ^0.2.23 | Agent workflows |
| `@langchain/core` | ^0.3.19 | Core utilities |

### Payment Processing (Installed, Not Active)
- **Stripe** (^8.0.1) — installed, not integrated
- **Razorpay** (^2.8.4) — installed, not integrated
- **Braintree** (^3.6.0) — installed, not integrated

### Other (Installed, Not Active)
- **Mux** (`@mux/mux-node` ^7.3.3) — video processing, not active
- **OneSignal** (`@onesignal/node-onesignal` ^2.0.1-beta2) — legacy, deprecated in favor of FCM

---

## Firestore Collections

### Primary Collections
| Collection | Purpose |
|-----------|---------|
| `users` | User profiles, auth metadata, preferences |
| `games` | Golf game postings |
| `game_participants` | Subcollection: `games/{id}/game_participants/` |
| `chats` | Chat threads (direct and game-based) |
| `messages` | Subcollection: `chats/{id}/messages/` |
| `notifications` | User notifications |
| `alertSubs` | Game alert subscriptions with matching rules |

### Trust & Social
| Collection | Purpose |
|-----------|---------|
| `pair_ratings` | Pairwise player ratings |
| `partner_plays` | Playing history with partners |
| `challenge_history` | Challenge engagement tracking |
| `strikes` | User violation/strike records |

### Game Operations
| Collection | Purpose |
|-----------|---------|
| `round_jobs` | Confirmation flow job queue |
| `round_records` | Game/round history |
| `round_events` | Event log for rounds |
| `pairwiseMatches` | Match compatibility data |
| `participants` | Round participants |
| `feedback` | Post-round feedback |
| `player_rounds` | Denormalized player-round view |
| `join_requests` | Game join request queue |
| `cancellation_records` | Game cancellation history |

### Devices & Communication
| Collection | Purpose |
|-----------|---------|
| `devices` | User device records |
| `fcm_tokens` | FCM token management |
| `user_push_notifications` | Push notification preferences |
| `push_notifications` | Push delivery records |
| `notification_receipts` | Delivery tracking |
| `scheduledNotifications` | Cloud Tasks scheduled queue |
| `notificationLog` | Notification audit log |

### Metadata & Reference
| Collection | Purpose |
|-----------|---------|
| `course` | Golf course database |
| `hometown` | User hometown/location |
| `usernames` | Username uniqueness tracking |
| `metadata` | Chat/game metadata |
| `chatRefs` | Chat reference mappings |
| `posts` | User posts/activity |
| `stats` | User statistics |
| `reports` | User reports/complaints |

### Private Data
- `users/{userId}/private/info` — phone, email

**Total**: 34+ primary collections plus subcollections

---

## Notification Flow

### Channels
1. **Push** — FCM via `firebase_messaging`
2. **Local** — `flutter_local_notifications`
3. **Email** — SendGrid
4. **In-app** — Firestore notification log

### Features
- Quiet hours (configurable per user, default 22:00-07:00 Vancouver)
- Game alert matching (AND across categories, OR within)
- Smart suppression and deduplication
- Delivery tracking via `notification_receipts`

---

## BigQuery Integration

- **Status**: Planned for Phase 3 export
- **File**: `firebase/functions/src/sync.js`
- **Purpose**: Analytics and behavioral dataset export
- **Source**: `round_jobs` collection (flat event log entries)
- **Views**: `player_rounds` for fast trajectory queries

---

## Environment & Deployment

### Firebase Project
- **Project ID**: `find-my-fourth`
- **Region**: `us-west2`
- **Environments**: dev, staging, prod (via `APP_ENV` build flag)

### Required Environment Variables
| Variable | Purpose |
|----------|---------|
| `SENDGRID_API_KEY` | Email delivery |
| `GCLOUD_PROJECT` | Cloud Tasks project (defaults to `find-my-fourth`) |

### Security Rules
- Firestore: `firebase/firestore.rules` (37KB, comprehensive)
- Storage: `firebase/storage.rules`

### Firestore Security Patterns
- `isSignedIn()` auth check
- Role-based access (`isGameOwner`, `isGameParticipantByRef`)
- Chat member validation (`isChatMember`)
- Valid data structure checks
- Self-scoped list updates
