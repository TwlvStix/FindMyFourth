# Cloud Functions Configuration for Load Testing

## Overview

This document provides the required Cloud Functions 2nd generation configuration for the Push Notifications Trust System to handle production load (500 games, ~1,500 users on Saturday morning peak).

## Required Configuration Updates

### 1. HTTP Functions (Notification Handlers)

Update `processScheduledTrustNotification` in `notifications/trust/scheduler.js`:

```javascript
const { onRequest } = require('firebase-functions/v2/https');

exports.processScheduledTrustNotification = onRequest({
  // Scaling
  maxInstances: 100,        // Allow up to 100 concurrent instances
  concurrency: 10,          // Each instance handles 10 concurrent requests
  minInstances: 0,          // Auto-scale down to 0 when idle (cost optimization)

  // Resources
  memory: '512MiB',         // Sufficient for notification processing
  timeoutSeconds: 540,      // 9 minutes (max for 2nd gen)

  // Runtime
  cpu: 1,                   // 1 vCPU per instance

  // Region
  region: 'us-west2',       // Match Cloud Tasks queue location

  // IMPORTANT: Remove authentication for Cloud Tasks
  // Cloud Tasks will use OIDC authentication automatically
}, async (req, res) => {
  // ... existing handler implementation
});
```

### 2. Scheduled Functions (Background Jobs)

Update `processConfirmationJobs` in `confirmation_flow.js`:

```javascript
const { onSchedule } = require('firebase-functions/v2/scheduler');

exports.processConfirmationJobs = onSchedule({
  // Schedule
  schedule: 'every 15 minutes',
  timeZone: 'UTC',

  // Scaling
  maxInstances: 10,         // Limit concurrent job processors
  concurrency: 1,           // Sequential processing per instance
  minInstances: 0,          // Auto-scale down when idle

  // Resources
  memory: '512MiB',
  timeoutSeconds: 540,      // 9 minutes
  cpu: 1,

  // Region
  region: 'us-west2',
}, async (context) => {
  // ... existing implementation
});
```

Update `trustTokenHygieneJob` in `notifications/trust/workers.js`:

```javascript
const { onSchedule } = require('firebase-functions/v2/scheduler');

exports.trustTokenHygieneJob = onSchedule({
  // Schedule
  schedule: '0 3 * * *',    // Daily at 3 AM UTC
  timeZone: 'UTC',

  // Scaling
  maxInstances: 1,          // Only need 1 instance for hygiene
  concurrency: 1,
  minInstances: 0,

  // Resources
  memory: '256MiB',         // Lightweight cleanup task
  timeoutSeconds: 300,      // 5 minutes
  cpu: 1,

  // Region
  region: 'us-west2',
}, async (context) => {
  // ... existing implementation
});
```

Update `trustQuietHoursCleanup` in `notifications/trust/workers.js`:

```javascript
const { onSchedule } = require('firebase-functions/v2/scheduler');

exports.trustQuietHoursCleanup = onSchedule({
  // Schedule
  schedule: 'every 15 minutes',
  timeZone: 'UTC',

  // Scaling
  maxInstances: 1,          // Single instance sufficient
  concurrency: 1,
  minInstances: 0,

  // Resources
  memory: '256MiB',
  timeoutSeconds: 300,
  cpu: 1,

  // Region
  region: 'us-west2',
}, async (context) => {
  // ... existing implementation
});
```

### 3. Firestore Triggers

Update `onGameStatusToPlayed` in `confirmation_flow.js`:

```javascript
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');

exports.onGameStatusToPlayed = onDocumentUpdated({
  // Document path
  document: 'games/{gameId}',

  // Scaling
  maxInstances: 100,        // Handle burst of 500 games
  concurrency: 10,
  minInstances: 0,

  // Resources
  memory: '512MiB',
  timeoutSeconds: 60,       // Fast processing for each game
  cpu: 1,

  // Region
  region: 'us-west2',
}, async (event) => {
  // ... existing implementation
});
```

Update `onGameParticipantJoin` in `confirmation_flow.js`:

```javascript
const { onDocumentCreated } = require('firebase-functions/v2/firestore');

exports.onGameParticipantJoin = onDocumentCreated({
  // Document path
  document: 'games/{gameId}/game_participants/{participantId}',

  // Scaling
  maxInstances: 100,
  concurrency: 10,
  minInstances: 0,

  // Resources
  memory: '256MiB',         // Lightweight vibe calculation
  timeoutSeconds: 60,
  cpu: 1,

  // Region
  region: 'us-west2',
}, async (event) => {
  // ... existing implementation
});
```

## Migration from 1st Gen to 2nd Gen

### Key Differences

| Aspect | 1st Gen | 2nd Gen |
|--------|---------|---------|
| Import | `require('firebase-functions')` | `require('firebase-functions/v2/...')` |
| HTTP | `functions.https.onRequest` | `onRequest` from `v2/https` |
| Schedule | `functions.pubsub.schedule` | `onSchedule` from `v2/scheduler` |
| Firestore | `functions.firestore.document().onCreate` | `onDocumentCreated` from `v2/firestore` |
| Concurrency | 1 request per instance | Up to 1000 per instance |
| Max Instances | Default 3000 | Default 100 |
| Timeout | 60s (540s for HTTP) | 60s (540s configurable) |
| Memory | 256MB default | 256MiB default |

### Migration Example

**Before (1st Gen):**
```javascript
const functions = require('firebase-functions');

exports.myFunction = functions.https.onRequest((req, res) => {
  // handler
});
```

**After (2nd Gen):**
```javascript
const { onRequest } = require('firebase-functions/v2/https');

exports.myFunction = onRequest({
  maxInstances: 100,
  concurrency: 10,
  memory: '512MiB',
  timeoutSeconds: 540,
  region: 'us-west2'
}, async (req, res) => {
  // handler
});
```

## Cloud Tasks Queue Configuration

Create the queue with appropriate settings:

```bash
gcloud tasks queues create trust-notification-scheduler \
  --location=us-west2 \
  --max-concurrent-dispatches=100 \
  --max-dispatches-per-second=500 \
  --max-attempts=3 \
  --min-backoff=10s \
  --max-backoff=300s \
  --max-doublings=3
```

**Explanation:**
- `max-concurrent-dispatches=100`: Up to 100 tasks executing simultaneously
- `max-dispatches-per-second=500`: Rate limit to avoid overwhelming Cloud Functions
- `max-attempts=3`: Retry failed tasks up to 3 times
- `min-backoff=10s`: Start retry delay at 10 seconds
- `max-backoff=300s`: Cap retry delay at 5 minutes
- `max-doublings=3`: Exponential backoff (10s → 20s → 40s → 80s)

## Firestore Indexes

Deploy all required indexes from `firestore.indexes.json`:

```bash
firebase deploy --only firestore:indexes
```

### Critical Indexes for Load Test

**round_jobs:**
```json
{
  "collectionGroup": "round_jobs",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "scheduled_host_notify_at", "order": "ASCENDING" }
  ]
}
```

**scheduledNotifications:**
```json
{
  "collectionGroup": "scheduledNotifications",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "gameId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" }
  ]
}
```

**notificationLog:**
```json
{
  "collectionGroup": "notificationLog",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "releaseAt", "order": "ASCENDING" }
  ]
}
```

## Monitoring Configuration

### Cloud Functions Dashboard

Set up alerts for:

1. **Execution Time** → Alert if P99 > 5s
2. **Error Rate** → Alert if > 1%
3. **Active Instances** → Monitor scaling behavior
4. **Memory Usage** → Alert if > 80%

### Example Alert (gcloud)

```bash
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="Cloud Functions P99 Latency" \
  --condition-display-name="P99 > 5s" \
  --condition-threshold-value=5000 \
  --condition-threshold-duration=300s \
  --aggregation-reducer="REDUCE_PERCENTILE_99" \
  --metric-type="cloudfunctions.googleapis.com/function/execution_times"
```

## Cost Estimation

### Production Load (500 games, Saturday peak)

**Cloud Functions:**
- Invocations: ~10,000 (game triggers + notifications + jobs)
- CPU time: ~15 GB-seconds per invocation average
- Memory: 512MiB
- **Cost:** ~$0.20/day

**Cloud Tasks:**
- Task operations: ~3,000 (2 notifications per game average)
- **Cost:** ~$0.01/day

**Firestore:**
- Reads: ~100,000 (user prefs, devices, dedup checks)
- Writes: ~20,000 (jobs, records, logs)
- **Cost:** ~$0.10/day

**Total Daily Cost (Peak):** ~$0.31/day

**Monthly Cost (4 Saturdays):** ~$1.24/month

### Load Test Cost

**Full Test (500 games):**
- One-time cost: ~$0.30

**Small Test (50 games):**
- One-time cost: ~$0.05

## Performance Tuning

### If P99 > 5s

1. **Increase max instances:**
   ```javascript
   maxInstances: 200  // Double capacity
   ```

2. **Enable min instances (keep warm):**
   ```javascript
   minInstances: 5  // Pre-warmed instances
   ```

3. **Increase memory:**
   ```javascript
   memory: '1GiB'  // More memory = faster CPU
   ```

4. **Optimize database queries:**
   - Ensure all queries have indexes
   - Use `.limit()` on large collections
   - Cache frequently-read data

### If Error Rate > 1%

1. **Check for OOM errors:**
   - Increase memory allocation
   - Profile memory usage in logs

2. **Handle transient errors:**
   - Add retry logic with exponential backoff
   - Implement circuit breakers

3. **Validate data:**
   - Add input validation
   - Handle missing/malformed data gracefully

4. **Monitor external dependencies:**
   - FCM errors → validate tokens, handle expired
   - Cloud Tasks errors → check queue limits

## Deployment

### Deploy All Functions

```bash
cd firebase
firebase deploy --only functions
```

### Deploy Specific Function

```bash
firebase deploy --only functions:processScheduledTrustNotification
```

### Deploy with Force (override protections)

```bash
firebase deploy --only functions --force
```

## Rollback Plan

If production issues occur after deployment:

1. **Immediate rollback:**
   ```bash
   firebase functions:delete processScheduledTrustNotification
   firebase deploy --only functions:processScheduledTrustNotification
   ```

2. **Restore previous version:**
   ```bash
   git checkout <previous-commit>
   firebase deploy --only functions
   ```

3. **Disable Cloud Scheduler (stop automated jobs):**
   ```bash
   gcloud scheduler jobs pause processConfirmationJobs --location=us-west2
   ```

4. **Pause Cloud Tasks queue:**
   ```bash
   gcloud tasks queues pause trust-notification-scheduler --location=us-west2
   ```

## Pre-Deployment Checklist

- [ ] All functions migrated to 2nd gen
- [ ] `maxInstances: 100` set on notification handlers
- [ ] `concurrency: 10` set on all HTTP functions
- [ ] Cloud Tasks queue created with correct settings
- [ ] Firestore indexes deployed and built (check Firebase Console)
- [ ] Monitoring alerts configured
- [ ] Load test passed on staging environment
- [ ] Rollback plan documented and tested
- [ ] Team notified of deployment window

## Post-Deployment Validation

After deploying to production:

1. **Check function deployment:**
   ```bash
   firebase functions:list
   ```

2. **Test one notification manually:**
   ```bash
   # Trigger a test notification
   firebase functions:shell
   > processScheduledTrustNotification({...testEvent})
   ```

3. **Monitor logs:**
   ```bash
   firebase functions:log --only processScheduledTrustNotification
   ```

4. **Verify Cloud Tasks:**
   - Check queue in Cloud Console
   - Confirm tasks are executing

5. **Run smoke test:**
   ```bash
   cd firebase/functions
   npm run load-test:small
   ```

---

**Configuration Version:** 1.0
**Compatible with:** Firebase Functions 2nd Gen, Node.js 20
**Last Updated:** 2026-02-19
