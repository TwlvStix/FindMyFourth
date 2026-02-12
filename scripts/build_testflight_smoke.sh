#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/build_testflight_smoke.sh <internal|external> <build-name> <build-number>

Examples:
  scripts/build_testflight_smoke.sh internal 1.0.1 2
  scripts/build_testflight_smoke.sh external 1.0.1 3
EOF
}

if [[ $# -ne 3 ]]; then
  usage
  exit 1
fi

mode="$1"
build_name="$2"
build_number="$3"

allow_internal_crash_test="false"
case "$mode" in
  internal)
    allow_internal_crash_test="true"
    ;;
  external)
    allow_internal_crash_test="false"
    ;;
  *)
    echo "Invalid mode: $mode"
    usage
    exit 1
    ;;
esac

flutter build ipa --release \
  --build-name="$build_name" \
  --build-number="$build_number" \
  --dart-define=APP_ENV=prod \
  --dart-define=CRASHLYTICS_ENABLED=true \
  --dart-define=USE_FIREBASE_EMULATOR=false \
  --dart-define=ENABLE_DEV_UI=false \
  --dart-define=ALLOW_INTERNAL_CRASH_TEST="$allow_internal_crash_test"
