# Load Test for Push Notifications Trust System

## Overview

This load test validates the production infrastructure for the Push Notifications Trust System by simulating a Saturday morning peak scenario with 500 games and ~1,500 users.

## Test Scenario

**Simulation:**
- 500 games created over 2-hour window
- ~1,500 unique users (average 3 users per game)
- 1-2 FCM devices per user
- Realistic burst patterns:
  1. Game confirmation (all 500 games marked "played")
  2. Host check-in burst (~80% of hosts confirm within 5 hours)
  3. Rating burst (players submit ratings 30 min after host confirms)

**Measured Metrics:**
- **Latency**: P50/P95/P99 for all operations
- **Error Rate**: Percentage of failed operations
- **Firestore Costs**: Read/write/delete operations and estimated costs
- **Notification Delivery**: Success rate, held, skipped, failed
- **Cloud Tasks**: Created, executed, failed

**Success Criteria:**
- ✅ P99 latency < 5 seconds
- ✅ Error rate < 1%

## Prerequisites

### 1. Cloud Functions Configuration

Ensure your Cloud Functions are configured as 2nd generation with appropriate scaling:

```javascript
// In firebase/functions/index.js or relevant function files
const { onRequest } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');

exports.processScheduledTrustNotification = onRequest({
  maxInstances: 100,
  concurrency: 10,
  timeoutSeconds: 540,
  memory: '512MiB'
}, async (req, res) => {
  // ... handler implementation
});

exports.processConfirmationJobs = onSchedule({
  schedule: 'every 15 minutes',
  timeZone: 'UTC',
  maxInstances: 10,
  concurrency: 1,
  timeoutSeconds: 540,
  memory: '512MiB'
}, async (context) => {
  // ... handler implementation
});
```

### 2. Cloud Tasks Queue

Create the Cloud Tasks queue if not already created:

```bash
gcloud tasks queues create trust-notification-scheduler \
  --location=us-west2 \
  --max-concurrent-dispatches=100 \
  --max-attempts=3 \
  --min-backoff=10s \
  --max-backoff=300s
```

### 3. Firestore Indexes

Ensure all required indexes are deployed:

```bash
cd firebase
firebase deploy --only firestore:indexes
```

Required indexes (from `firestore.indexes.json`):
- `round_jobs`: `(status, scheduled_host_notify_at)`, `(status, scheduled_peer_notify_at)`, `(game_ref, status)`
- `round_records`: `(game_ref, verification_status)`, `(tee_time DESC, verification_status)`
- `scheduledNotifications`: `(gameId, status)`, `(recipientUserId, eventType, status)`
- `notificationLog`: `(eventType, sourceId, recipientUserId, timestamp DESC)`, `(status, releaseAt)`

### 4. Firebase Admin SDK

The load test uses Firebase Admin SDK with default credentials. Ensure you have:

```bash
# Set your Firebase project
export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"

# Or use Firebase CLI login
firebase login
```

### 5. Production Environment

**⚠️ WARNING:** This test creates real Firestore documents and triggers real Cloud Functions. While it uses a `LOADTEST_` prefix for easy cleanup, it's recommended to:

- Run against a **staging/test project** first
- Verify cleanup works correctly
- Monitor costs during the test
- Have backups ready

## Running the Load Test

### Basic Execution

```bash
# Navigate to functions directory
cd firebase/functions

# Install dependencies (if not already done)
npm install

# Run the load test
node test/load-test.js
```

### Custom Configuration

You can modify the configuration at the top of `load-test.js`:

```javascript
const CONFIG = {
  TOTAL_GAMES: 500,              // Number of games to create
  TEST_DURATION_HOURS: 2,        // Spread game creation over this period
  USERS_PER_GAME: 3,             // Average users per game
  HOST_CHECKIN_RATE: 0.80,       // 80% of hosts confirm
  RATING_COMPLETION_RATE: 0.75,  // 75% complete ratings
  P99_THRESHOLD_MS: 5000,        // Pass/fail threshold
  ERROR_RATE_THRESHOLD: 0.01,    // 1% error threshold
};
```

### Smaller Test Run

For a quick smoke test, modify the config:

```javascript
const CONFIG = {
  TOTAL_GAMES: 50,               // Smaller test
  TEST_DURATION_HOURS: 0.5,      // 30 minutes
  // ... other settings
};
```

## Test Phases

The load test executes in these phases:

### Phase 1: Setup (2-5 minutes)
- Creates ~1,000 test users with realistic profiles
- Adds 1-2 FCM device tokens per user
- Sets notification preferences

### Phase 2: Game Creation Burst (2 hours or configured duration)
- Creates 500 games with random hosts and players
- Distributes creation evenly over test duration
- Triggers `onGameParticipantJoin` for vibe score calculation

### Phase 3: Mark Games Played (1 minute)
- Transitions all games to "played" status
- Triggers `onGameStatusToPlayed` which creates `round_jobs`
- Waits 30s for Cloud Functions to process

### Phase 4: Host Check-In Burst (5-10 minutes)
- Simulates 80% of hosts confirming attendance
- Updates `round_jobs` and `round_records`
- Triggers check-in notification pipeline
- Records attendance and no-shows

### Phase 5: Rating Burst (5-10 minutes)
- Players submit "play again" ratings
- Creates `pair_ratings` documents
- Simulates 75% completion rate

### Phase 6: Monitor Notifications (1 minute)
- Waits for notification pipeline to process
- Samples `scheduledNotifications` to check Cloud Tasks
- Samples `notificationLog` to check delivery status

### Phase 7: Generate Report
- Calculates latency percentiles (P50/P95/P99)
- Computes error rate
- Estimates Firestore costs
- Generates pass/fail result
- Saves detailed JSON report

### Phase 8: Cleanup
- Deletes all test data using `LOADTEST_` prefix
- Removes users, games, jobs, records, ratings, notifications
- Cleans up FCM tokens and subcollections

## Understanding the Report

### Sample Report Output

```
================================================================================
LOAD TEST REPORT
================================================================================

Test Duration: 145.32 minutes
Total Operations: 2,847
Total Errors: 12

--- LATENCY METRICS ---

createGame:
  Count: 500
  P50: 234ms
  P95: 678ms
  P99: 1,203ms
  Status: ✓ PASS (P99 < 5000ms)

hostCheckIn:
  Count: 400
  P50: 412ms
  P95: 1,234ms
  P99: 2,456ms
  Status: ✓ PASS (P99 < 5000ms)

submitRatings:
  Count: 380
  P50: 156ms
  P95: 589ms
  P99: 987ms
  Status: ✓ PASS (P99 < 5000ms)

--- ERROR RATE ---
Error Rate: 0.42%
Threshold: 1%
Status: ✓ PASS

--- FIRESTORE COSTS ---
Reads: 45,892 ($0.0028)
Writes: 67,234 ($0.0121)
Deletes: 68,901 ($0.0014)
Total Cost: $0.0163

--- CLOUD TASKS ---
Created: 1,500
Executed: 1,485
Failed: 15

--- NOTIFICATIONS ---
Sent: 2,940
Held: 0
Skipped: 120
Failed: 15

================================================================================
OVERALL RESULT: ✓ PASS
================================================================================

Detailed report saved to: test/load-test-report.json
```

### Key Metrics Explained

**Latency Percentiles:**
- **P50 (median)**: 50% of operations completed within this time
- **P95**: 95% of operations completed within this time
- **P99**: 99% of operations completed within this time (critical for UX)

**Error Rate:**
- Percentage of operations that failed
- Includes Firestore errors, timeout errors, validation failures

**Firestore Costs:**
- Estimated costs based on Google Cloud pricing
- Reads: $0.06 per million
- Writes: $0.18 per million
- Deletes: $0.02 per million

**Cloud Tasks:**
- Created: Tasks scheduled for deferred notification delivery
- Executed: Tasks that completed successfully
- Failed: Tasks that failed after retries

**Notifications:**
- Sent: Successfully delivered to FCM
- Held: Held in quiet hours queue
- Skipped: Filtered by preferences or dedup rules
- Failed: FCM delivery failures

## Detailed Report JSON

The test generates `load-test-report.json` with:

```json
{
  "config": { /* Test configuration */ },
  "metrics": {
    "operations": [
      {
        "name": "createGame",
        "duration": 234,
        "success": true,
        "timestamp": 1708345678000,
        "error": null
      }
      // ... all operations
    ],
    "errors": [ /* Error details */ ],
    "firestoreOps": { /* Operation counts */ },
    "cloudTasks": { /* Task metrics */ },
    "notifications": { /* Delivery metrics */ }
  },
  "summary": {
    "duration": 8719200,
    "durationMinutes": "145.32",
    "latency": { "P50": 267, "P95": 823, "P99": 1456 },
    "errorRate": 0.0042,
    "costs": { /* Detailed cost breakdown */ },
    "passed": true
  }
}
```

## Monitoring During Test

### Cloud Functions Logs

Monitor function execution in real-time:

```bash
# Watch all function logs
firebase functions:log --only processScheduledTrustNotification,onGameStatusToPlayed,processConfirmationJobs

# Or use gcloud
gcloud functions logs read \
  --filter="resource.labels.function_name=processScheduledTrustNotification" \
  --limit=50 \
  --format=json
```

### Firestore Console

Monitor document creation:
1. Open Firebase Console → Firestore
2. Watch these collections:
   - `games` (should see 500 with `LOADTEST_` prefix)
   - `round_jobs` (500 pending jobs)
   - `scheduledNotifications` (tasks being created)
   - `notificationLog` (delivery records)

### Cloud Tasks Console

Monitor queue processing:
1. Open Google Cloud Console → Cloud Tasks
2. Select `trust-notification-scheduler` queue
3. Watch task creation and execution rate

### Costs

Monitor costs in Google Cloud Console → Billing:
- Firestore: Read/write operations
- Cloud Functions: Invocations, CPU time, memory
- Cloud Tasks: Task operations

Typical costs for full test run:
- Firestore: $0.02 - $0.05
- Cloud Functions: $0.10 - $0.25
- Cloud Tasks: < $0.01
- **Total: ~$0.15 - $0.30**

## Troubleshooting

### High Error Rate

**Symptom:** Error rate > 1%

**Possible causes:**
1. Cloud Functions hitting memory limits
2. Firestore write rate limits
3. Cloud Tasks queue throttling
4. FCM token errors

**Solutions:**
- Check Cloud Functions logs for OOM errors
- Increase function memory: `memory: '1GiB'`
- Reduce burst rate (increase `creationIntervalMs`)
- Verify FCM tokens are valid format

### High P99 Latency

**Symptom:** P99 > 5 seconds

**Possible causes:**
1. Cold starts (insufficient pre-warmed instances)
2. Firestore index missing
3. Cloud Tasks queue backlog

**Solutions:**
- Increase `maxInstances` to 100+
- Deploy Firestore indexes: `firebase deploy --only firestore:indexes`
- Check Cloud Tasks console for queue backlog
- Enable Cloud Functions min instances:
  ```javascript
  minInstances: 5  // Keep some instances warm
  ```

### Cleanup Failures

**Symptom:** Test data not fully deleted

**Possible causes:**
1. Subcollections not fully cleaned
2. Batch size limits
3. Permission errors

**Solutions:**
- Run cleanup manually:
  ```bash
  node test/load-test.js --cleanup-only
  ```
- Check Firestore rules allow deletion
- Manually delete from console if needed

### Out of Memory

**Symptom:** Node.js heap out of memory

**Solutions:**
- Run with increased memory:
  ```bash
  node --max-old-space-size=4096 test/load-test.js
  ```
- Reduce `TOTAL_GAMES` for smaller test
- Process in smaller batches

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Load Test

on:
  workflow_dispatch:  # Manual trigger
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday

jobs:
  load-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install dependencies
        run: |
          cd firebase/functions
          npm ci

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}

      - name: Run Load Test
        run: |
          cd firebase/functions
          node test/load-test.js

      - name: Upload Report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: load-test-report
          path: firebase/functions/test/load-test-report.json

      - name: Comment on PR (if failed)
        if: failure()
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '❌ Load test failed. Check artifacts for details.'
            })
```

## Advanced Configuration

### Testing Different Scenarios

**Peak Load (Saturday morning):**
```javascript
TOTAL_GAMES: 500,
TEST_DURATION_HOURS: 2,
HOST_CHECKIN_RATE: 0.80,
```

**Sustained Load (weekday evening):**
```javascript
TOTAL_GAMES: 200,
TEST_DURATION_HOURS: 4,
HOST_CHECKIN_RATE: 0.85,
```

**Stress Test (beyond expected peak):**
```javascript
TOTAL_GAMES: 1000,
TEST_DURATION_HOURS: 1,
HOST_CHECKIN_RATE: 0.90,
```

**Quiet Hours Test:**
```javascript
// Modify generateTestUser to enable quiet hours
quiet_hours: {
  enabled: true,
  start: '22:00',
  end: '08:00'
}
```

### Custom Event Types

To test specific notification types, modify the simulation to trigger:
- `onStrikeIssued` (cancellations, no-shows)
- `onBadgeEarned` (achievement unlocks)
- `onGameCancelled` (cancellation alerts)

Example in `simulateCheckInBurst`:
```javascript
// Mark some players as no-shows to trigger strike notifications
if (Math.random() < 0.1) {  // 10% no-show rate
  await markGhostNoShow({ userId: uid, gameId: game.id });
}
```

## Post-Test Checklist

After running the load test:

- [ ] Review pass/fail results
- [ ] Analyze latency percentiles by operation type
- [ ] Check error logs for patterns
- [ ] Verify Firestore costs are within budget
- [ ] Confirm Cloud Tasks processed successfully
- [ ] Validate notification delivery rate
- [ ] Review Cloud Functions scaling behavior
- [ ] Confirm cleanup removed all test data
- [ ] Save report to version control or monitoring system
- [ ] Update infrastructure if tests revealed bottlenecks

## Next Steps

If load test **passes**:
1. ✅ Mark Session 13 complete
2. Deploy to production with confidence
3. Set up monitoring dashboards
4. Schedule regular load tests

If load test **fails**:
1. Analyze detailed report JSON
2. Identify bottleneck operations
3. Review error patterns
4. Adjust Cloud Functions configuration
5. Optimize hot paths
6. Re-run test to validate fixes

## Support

For issues or questions:
- Check Firebase Console logs
- Review `load-test-report.json` for detailed metrics
- Consult the main spec document: `golf-rep-push-notification-infra-spec-v2.1.docx`
- Verify all infrastructure prerequisites are deployed

---

**Load Test Version:** 1.0
**Compatible with:** Find My Fourth v2.0+
**Last Updated:** 2026-02-19
