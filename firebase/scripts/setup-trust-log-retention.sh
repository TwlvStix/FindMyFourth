#!/usr/bin/env bash
# setup-trust-log-retention.sh
#
# Sets Cloud Logging retention to 90 days for the project's _Default log bucket.
# Cloud Functions logs (including the trust.notification and trust.fcm_send
# structured entries from logger.js) stream into this bucket automatically.
#
# Usage:
#   bash setup-trust-log-retention.sh <project-id>
#
# Requirements:
#   gcloud CLI authenticated with roles/logging.admin on the project.
#
# Notes:
#   - The _Default bucket location is 'global'. If your project uses a regional
#     bucket, change --location below to match (e.g. us-west2).
#   - This command is idempotent — re-running it with the same retention value
#     is safe and produces no side effects.
#   - Google Cloud's minimum billable retention period is 1 day; 90 days keeps
#     logs for the required audit window without incurring long-term storage cost.

set -euo pipefail

PROJECT_ID="${1:?Usage: $0 <project-id>}"

echo "==> Project: ${PROJECT_ID}"
echo ""

# ── Show current retention ────────────────────────────────────────────────────

echo "==> Current _Default bucket retention:"
gcloud logging buckets describe _Default \
  --location=global \
  --project="${PROJECT_ID}" \
  --format="value(retentionDays)" 2>/dev/null \
  | xargs -I{} echo "    {} days" \
  || echo "    (could not read current retention)"

echo ""

# ── Set 90-day retention ──────────────────────────────────────────────────────

echo "==> Setting _Default bucket retention to 90 days..."
gcloud logging buckets update _Default \
  --location=global \
  --retention-days=90 \
  --project="${PROJECT_ID}"

echo ""
echo "==> Retention updated. Verify:"
gcloud logging buckets describe _Default \
  --location=global \
  --project="${PROJECT_ID}" \
  --format="value(retentionDays)" \
  | xargs -I{} echo "    _Default retention: {} days"

echo ""
echo "==> Done."
echo ""
echo "    Logs older than 90 days will be automatically deleted."
echo "    To view retention settings in the console:"
echo "    https://console.cloud.google.com/logs/storage?project=${PROJECT_ID}"
