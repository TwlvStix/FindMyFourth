# Load Test Quick Start — Session 13

## Overview

This load test exercises the **real production entry points** of the Trust System:

| Phase | Handler | What It Does |
|-------|---------|--------------|
| 3 | `_onGameStatusToPlayedHandler()` | Creates `round_jobs`, `round_records`, schedules Trust notifications via `onGameConfirmed()` |
| 4 | `_submitHostCheckinHandler()` | Calls `onHostCheckinCompleted()`, sends no-show notifications via `routeNotification()` |
| 5 | `_submitPeerRatingsHandler()` | Creates `pair_ratings`, records verification signals |

## Prerequisites

```bash
cd firebase/functions
export GOOGLE_APPLICATION_CREDENTIALS="./service-account-key.json"
```

## Run the Test

```bash
# Small config (50 games, ~100 users) — first run validation
node test/load-test.js
```

## Expected Output

```
================================================================================
TRUST SYSTEM LOAD TEST — Session 13
Saturday Morning Peak Validation
================================================================================

Configuration:
  Games: 50
  Users per Game: ~3
  Total Users: ~100
  Host Check-in Rate: 80%
  Player Present Rate: 85%
  Rating Completion Rate: 75%

Thresholds:
  P99 Latency: < 5000ms
  Error Rate: < 1%

Note: FCM sends will fail (fake tokens) — expected. Measuring pipeline throughput.

[Phase 1] Creating 100 test users...
  Created 100/100 users
  ✓ Created 100 users in 1234ms

[Phase 2] Creating 50 test games with participants...
  Created 50/50 games
  ✓ Created 50 games in 5678ms

[Phase 3] Calling _onGameStatusToPlayedHandler() for 50 games...
  Processed 50/50 games
  ✓ onGameStatusToPlayed: 50 success, 0 errors, avg 234ms

[Phase 4] Calling _submitHostCheckinHandler() for 40 games (80%)...
  Processed 40/40 check-ins
  ✓ submitHostCheckin: 40 success, 0 errors, avg 345ms

[Phase 5] Calling _submitPeerRatingsHandler() for present players...
  ✓ submitPeerRatings: 85 success, 0 errors, 170 ratings, avg 123ms

[Phase 6] Verifying Firestore document counts...
  round_jobs: 50 documents
  round_records: 50 documents
  pair_ratings: 170 documents
  scheduledNotifications: 200 documents

================================================================================
LOAD TEST REPORT — Trust System Session 13
================================================================================

Test Duration: 1.23 minutes
Total Operations: 175
Total Errors: 0

--- LATENCY METRICS ---

onGameStatusToPlayed:
  Count: 50 (50 success)
  P50: 200ms
  P95: 400ms
  P99: 500ms
  Error Rate: 0.00%
  Status: ✓ PASS

submitHostCheckin:
  Count: 40 (40 success)
  P50: 300ms
  P95: 500ms
  P99: 600ms
  Error Rate: 0.00%
  Status: ✓ PASS

submitPeerRatings:
  Count: 85 (85 success)
  P50: 100ms
  P95: 200ms
  P99: 250ms
  Error Rate: 0.00%
  Status: ✓ PASS

--- DOCUMENT COUNTS ---
  round_jobs: 50
  round_records: 50
  pair_ratings: 170
  scheduledNotifications: 200

--- FIRESTORE COSTS ---
  Reads: 1,234 ($0.0001)
  Writes: 5,678 ($0.0010)
  Deletes: 456 ($0.0000)
  Total Cost: $0.0011

================================================================================
OVERALL RESULT: ✓ PASS
================================================================================

Detailed report saved to: test/load-test-report.json

[Phase 7] Cleaning up test data...
  users: deleted 100 documents
  games: deleted 50 documents
  ...
  ✓ Cleanup complete: 500 documents deleted
```

## Success Criteria

| Metric | Threshold | What It Means |
|--------|-----------|---------------|
| P99 Latency | < 5000ms | 99th percentile response time |
| Error Rate | < 1% | Percentage of failed operations |

## Scaling Up

To run the full Saturday morning peak simulation, edit `CONFIG` in `load-test.js`:

```javascript
const CONFIG = {
  TOTAL_GAMES: 500,           // 500 games
  USERS_PER_GAME_AVG: 3,      // ~1,500 users
  // ... rest unchanged
};
```

## Cloud Functions Configuration

For production deployment, configure 2nd gen Cloud Functions:

```javascript
// In index.js
exports.onGameStatusToPlayed = functions
  .region('us-west2')
  .runWith({
    maxInstances: 100,
    concurrency: 10,
    memory: '512MB',
    timeoutSeconds: 60,
  })
  .firestore.document('games/{gameId}')
  .onUpdate(/* ... */);
```

## What the Test Exercises

### Phase 1: Create Test Users
- Creates `LOADTEST_user_XXXX` documents in `users` collection
- Each user gets 1-2 FCM tokens (fake, will fail delivery — expected)
- Sets up notification prefs with Trust categories enabled

### Phase 2: Create Test Games + Participants
- Creates `LOADTEST_game_XXXX` documents with status `filled`
- Creates `game_participants` with pre-computed `profile_snapshot` and `vibe_scores_with_others`
- Tee times set 5 hours in the past (simulates post-round timing)

### Phase 3: onGameStatusToPlayed Burst
- Calls the raw handler directly (bypasses Firestore trigger)
- Creates `round_jobs` and `round_records`
- Schedules Trust System notifications via `onGameConfirmed()`
- Creates `scheduledNotifications` documents for Cloud Tasks

### Phase 4: submitHostCheckin Burst
- Simulates 80% of hosts confirming attendance
- 85% of players marked present, 15% no-show
- Calls `onHostCheckinCompleted()` to cancel pending notifications
- Sends `no_show_flagged` notifications via `routeNotification()`

### Phase 5: submitPeerRatings Burst
- 75% of present players submit ratings
- Creates `pair_ratings` documents
- Records verification signals on `round_records`

### Phase 6: Document Count Verification
- Queries each collection to verify expected document counts
- Confirms pipeline created the right number of records

### Phase 7: Cleanup
- Deletes all `LOADTEST_*` documents
- Cleans subcollections (fcm_tokens, etc.)

## Troubleshooting

### "Error: No Firebase credentials found"
```bash
firebase login
# OR set service account key
export GOOGLE_APPLICATION_CREDENTIALS="path/to/key.json"
```

### "Error: Cloud Tasks queue not found"
The test will log errors from `scheduleJob()` but continue. Cloud Tasks scheduling is non-blocking. To fix:
```bash
gcloud tasks queues create trust-notification-scheduler \
  --location=us-west2 \
  --max-concurrent-dispatches=100
```

### High error rate in onGameStatusToPlayed
- Check that `game_participants` documents exist with `profile_snapshot`
- Verify `vibe_scores_with_others` is populated

### Cleanup doesn't remove all data
```bash
# Run the test again — it will clean up before creating new data
node test/load-test.js

# Or manually delete from Firestore console
# Filter by document ID starting with LOADTEST_
```

## Files

```
firebase/functions/test/
├── load-test.js                  # Main test script
├── LOAD_TEST_QUICK_START.md      # This file
├── LOAD_TEST_README.md           # Detailed documentation
└── load-test-report.json         # Generated after test runs
```

---

**Session:** 13 - Load Testing
**Last Updated:** 2026-02-19
