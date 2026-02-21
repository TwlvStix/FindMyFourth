#!/usr/bin/env bash
# setup-trust-monitoring.sh
#
# Creates Cloud Monitoring alert policies for the Trust System push notification
# pipeline. Run once after deploying the trust notification Cloud Functions.
#
# Usage:
#   bash setup-trust-monitoring.sh <project-id> <alert-email>
#
# Requirements:
#   gcloud CLI authenticated with a principal that has roles/monitoring.admin
#   and roles/logging.admin on the project.
#
# What this creates:
#   1. Email notification channel for alerts
#   2. Alert: Delivery success rate < 95% over 15 min
#   3. Alert: FCM error rate > 5% (non-token errors) over 15 min
#   4. Alert: Token invalidation rate > 10% daily
#   5. Alert: Stuck quiet_held entries found by cleanup worker
#
# All alerts use log-based metrics derived from structured logs emitted by
# firebase/functions/notifications/trust/logger.js

set -euo pipefail

PROJECT_ID="${1:?Usage: $0 <project-id> <alert-email>}"
ALERT_EMAIL="${2:?Usage: $0 <project-id> <alert-email>}"

echo "==> Project: ${PROJECT_ID}"
echo "==> Alert email: ${ALERT_EMAIL}"
echo ""

# ── Step 1: Create log-based metrics ─────────────────────────────────────────
#
# Cloud Monitoring alert policies reference log-based metrics by name.
# We create four custom metrics from the trust.notification and trust.fcm_send
# structured log entries emitted by logger.js.

echo "==> Creating log-based metrics..."

# Metric 1: All routed notifications (past dedup + cap gates = pipeline entered)
gcloud logging metrics create trust_notifications_routed \
  --project="${PROJECT_ID}" \
  --description="Count of Trust notifications that entered the delivery pipeline (all statuses)" \
  --log-filter='resource.type="cloud_function"
jsonPayload.eventId!=""
(jsonPayload.status="sent" OR jsonPayload.status="preference_disabled" OR jsonPayload.status="quiet_held" OR jsonPayload.status="no_devices" OR jsonPayload.status="fcm_error")' \
  2>/dev/null || echo "  (metric trust_notifications_routed already exists, skipping)"

# Metric 2: Successfully sent notifications
gcloud logging metrics create trust_notifications_sent \
  --project="${PROJECT_ID}" \
  --description="Count of Trust FCM sends with status=sent" \
  --log-filter='resource.type="cloud_function"
jsonPayload.status="sent"
jsonPayload.eventId!=""' \
  2>/dev/null || echo "  (metric trust_notifications_sent already exists, skipping)"

# Metric 3: FCM sends attempted (all per-device entries from trust.fcm_send)
gcloud logging metrics create trust_fcm_sends_attempted \
  --project="${PROJECT_ID}" \
  --description="Count of all per-device FCM send attempts (trust.fcm_send log entries)" \
  --log-filter='resource.type="cloud_function"
logName=~"trust.fcm_send"
jsonPayload.deviceId!=""' \
  2>/dev/null || echo "  (metric trust_fcm_sends_attempted already exists, skipping)"

# Metric 4: FCM errors (non-token: rate_limit, server_error, invalid_arg, auth_error, unknown)
gcloud logging metrics create trust_fcm_errors_non_token \
  --project="${PROJECT_ID}" \
  --description="Count of FCM send failures where errorCode is present and not a token_invalid error" \
  --log-filter='resource.type="cloud_function"
jsonPayload.status="fcm_error"
jsonPayload.errorCode!=""
NOT jsonPayload.errorCode=("messaging/registration-token-not-registered" OR "messaging/invalid-registration-token")' \
  2>/dev/null || echo "  (metric trust_fcm_errors_non_token already exists, skipping)"

# Metric 5: Token invalidations
gcloud logging metrics create trust_token_invalidations \
  --project="${PROJECT_ID}" \
  --description="Count of FCM sends that failed with a token_invalid error code" \
  --log-filter='resource.type="cloud_function"
jsonPayload.status="fcm_error"
(jsonPayload.errorCode="messaging/registration-token-not-registered" OR jsonPayload.errorCode="messaging/invalid-registration-token")' \
  2>/dev/null || echo "  (metric trust_token_invalidations already exists, skipping)"

# Metric 6: Stuck quiet_held entries found by cleanup worker
gcloud logging metrics create trust_stuck_quiet_held \
  --project="${PROJECT_ID}" \
  --description="Non-zero 'found' counts from trustQuietHoursCleanup runs, indicating stuck quiet_held entries" \
  --log-filter='resource.type="cloud_function"
jsonPayload.found>0
logName=~"trustQuietHoursCleanup"' \
  2>/dev/null || echo "  (metric trust_stuck_quiet_held already exists, skipping)"

echo ""
echo "==> Log-based metrics created."
echo ""

# ── Step 2: Create email notification channel ─────────────────────────────────

echo "==> Creating email notification channel for ${ALERT_EMAIL}..."

CHANNEL_JSON=$(gcloud alpha monitoring channels create \
  --project="${PROJECT_ID}" \
  --display-name="Trust Notifications Alert Email" \
  --type=email \
  --channel-labels="email_address=${ALERT_EMAIL}" \
  --format=json 2>/dev/null) || {
  echo "  Warning: could not create notification channel. Alerts will be created without a channel."
  CHANNEL_NAME=""
}

if [ -n "${CHANNEL_JSON:-}" ]; then
  CHANNEL_NAME=$(echo "${CHANNEL_JSON}" | python3 -c "import sys,json; print(json.load(sys.stdin)['name'])" 2>/dev/null || \
                 echo "${CHANNEL_JSON}" | grep '"name"' | head -1 | sed 's/.*"name": "\(.*\)".*/\1/')
  echo "  Channel: ${CHANNEL_NAME}"
else
  CHANNEL_NAME=""
fi

echo ""

# ── Step 3: Create alert policies ─────────────────────────────────────────────

NOTIFICATION_CHANNELS=""
if [ -n "${CHANNEL_NAME}" ]; then
  NOTIFICATION_CHANNELS="--notification-channels=${CHANNEL_NAME}"
fi

# Helper: create an alert policy from an inline JSON file
create_alert() {
  local name="$1"
  local json_file="$2"
  echo "  Creating alert: ${name}..."
  gcloud alpha monitoring policies create \
    --project="${PROJECT_ID}" \
    --policy-from-file="${json_file}" \
    ${NOTIFICATION_CHANNELS} \
    2>/dev/null || echo "  Warning: alert '${name}' may already exist or failed to create."
}

# ── Alert 1: Delivery success rate < 95% over 15 min ─────────────────────────
cat > /tmp/trust_alert_delivery_rate.json << 'ALERT_JSON'
{
  "displayName": "Trust: Delivery success rate < 95% (15 min)",
  "documentation": {
    "content": "The ratio of trust_notifications_sent / trust_notifications_routed dropped below 95% over a 15-minute window. Investigate preference_disabled, no_devices, or fcm_error spikes in Cloud Logging.",
    "mimeType": "text/markdown"
  },
  "conditions": [
    {
      "displayName": "Delivery success rate < 95%",
      "conditionThreshold": {
        "filter": "metric.type=\"logging.googleapis.com/user/trust_notifications_sent\" resource.type=\"cloud_function\"",
        "denominatorFilter": "metric.type=\"logging.googleapis.com/user/trust_notifications_routed\" resource.type=\"cloud_function\"",
        "comparison": "COMPARISON_LT",
        "thresholdValue": 0.95,
        "duration": "0s",
        "aggregations": [
          {
            "alignmentPeriod": "900s",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "denominatorAggregations": [
          {
            "alignmentPeriod": "900s",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "trigger": {
          "count": 1
        }
      }
    }
  ],
  "alertStrategy": {
    "notificationRateLimit": {
      "period": "1800s"
    }
  },
  "combiner": "OR",
  "enabled": true
}
ALERT_JSON
create_alert "Delivery success rate < 95%" /tmp/trust_alert_delivery_rate.json

# ── Alert 2: FCM error rate > 5% (non-token) over 15 min ────────────────────
cat > /tmp/trust_alert_fcm_error_rate.json << 'ALERT_JSON'
{
  "displayName": "Trust: FCM non-token error rate > 5% (15 min)",
  "documentation": {
    "content": "More than 5% of FCM send attempts are failing with non-token errors (rate_limit, server_error, invalid_arg, auth_error) over a 15-minute window. Check FCM project credentials and quota.",
    "mimeType": "text/markdown"
  },
  "conditions": [
    {
      "displayName": "FCM non-token error rate > 5%",
      "conditionThreshold": {
        "filter": "metric.type=\"logging.googleapis.com/user/trust_fcm_errors_non_token\" resource.type=\"cloud_function\"",
        "denominatorFilter": "metric.type=\"logging.googleapis.com/user/trust_fcm_sends_attempted\" resource.type=\"cloud_function\"",
        "comparison": "COMPARISON_GT",
        "thresholdValue": 0.05,
        "duration": "0s",
        "aggregations": [
          {
            "alignmentPeriod": "900s",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "denominatorAggregations": [
          {
            "alignmentPeriod": "900s",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "trigger": {
          "count": 1
        }
      }
    }
  ],
  "alertStrategy": {
    "notificationRateLimit": {
      "period": "1800s"
    }
  },
  "combiner": "OR",
  "enabled": true
}
ALERT_JSON
create_alert "FCM non-token error rate > 5%" /tmp/trust_alert_fcm_error_rate.json

# ── Alert 3: Token invalidation rate > 10% daily ─────────────────────────────
cat > /tmp/trust_alert_token_invalidation.json << 'ALERT_JSON'
{
  "displayName": "Trust: Token invalidation rate > 10% (24 h)",
  "documentation": {
    "content": "More than 10% of FCM sends are returning token_invalid errors in a 24-hour window. This indicates significant token churn — users may be uninstalling or reinstalling the app at an abnormal rate.",
    "mimeType": "text/markdown"
  },
  "conditions": [
    {
      "displayName": "Token invalidation rate > 10%",
      "conditionThreshold": {
        "filter": "metric.type=\"logging.googleapis.com/user/trust_token_invalidations\" resource.type=\"cloud_function\"",
        "denominatorFilter": "metric.type=\"logging.googleapis.com/user/trust_fcm_sends_attempted\" resource.type=\"cloud_function\"",
        "comparison": "COMPARISON_GT",
        "thresholdValue": 0.10,
        "duration": "0s",
        "aggregations": [
          {
            "alignmentPeriod": "86400s",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "denominatorAggregations": [
          {
            "alignmentPeriod": "86400s",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "trigger": {
          "count": 1
        }
      }
    }
  ],
  "alertStrategy": {
    "notificationRateLimit": {
      "period": "3600s"
    }
  },
  "combiner": "OR",
  "enabled": true
}
ALERT_JSON
create_alert "Token invalidation rate > 10% daily" /tmp/trust_alert_token_invalidation.json

# ── Alert 4: Stuck quiet_held entries found ───────────────────────────────────
cat > /tmp/trust_alert_stuck_quiet_held.json << 'ALERT_JSON'
{
  "displayName": "Trust: Stuck quiet_held entries found",
  "documentation": {
    "content": "The trustQuietHoursCleanup worker found one or more notificationLog entries stuck in quiet_held status past their releaseAt time. This means Cloud Tasks did not release them on schedule. Check Cloud Tasks queue health and the scheduler function.",
    "mimeType": "text/markdown"
  },
  "conditions": [
    {
      "displayName": "Stuck quiet_held count > 0",
      "conditionThreshold": {
        "filter": "metric.type=\"logging.googleapis.com/user/trust_stuck_quiet_held\" resource.type=\"cloud_function\"",
        "comparison": "COMPARISON_GT",
        "thresholdValue": 0,
        "duration": "0s",
        "aggregations": [
          {
            "alignmentPeriod": "900s",
            "perSeriesAligner": "ALIGN_SUM"
          }
        ],
        "trigger": {
          "count": 1
        }
      }
    }
  ],
  "alertStrategy": {
    "notificationRateLimit": {
      "period": "1800s"
    }
  },
  "combiner": "OR",
  "enabled": true
}
ALERT_JSON
create_alert "Stuck quiet_held entries" /tmp/trust_alert_stuck_quiet_held.json

# ── Cleanup temp files ─────────────────────────────────────────────────────────
rm -f /tmp/trust_alert_delivery_rate.json \
      /tmp/trust_alert_fcm_error_rate.json \
      /tmp/trust_alert_token_invalidation.json \
      /tmp/trust_alert_stuck_quiet_held.json

echo ""
echo "==> Done. Verify in Cloud Console:"
echo "    https://console.cloud.google.com/monitoring/alerting?project=${PROJECT_ID}"
echo ""
echo "    Alert policies will show data after the trust notification functions"
echo "    have processed at least one event and emitted structured logs."
