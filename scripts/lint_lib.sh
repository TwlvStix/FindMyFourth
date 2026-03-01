#!/usr/bin/env bash
set -euo pipefail

# Lint gate for lib/ directory
# Fails only on analyzer errors; warnings and infos are reported but don't fail the build.
# This enables incremental lint debt reduction without blocking development.

usage() {
  cat <<'EOF'
Usage:
  scripts/lint_lib.sh [--strict]

Options:
  --strict    Fail on warnings too (for future use once debt is cleared)

Examples:
  scripts/lint_lib.sh           # CI gate: errors only
  scripts/lint_lib.sh --strict  # Strict mode: errors + warnings
EOF
}

strict_mode=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)
      strict_mode=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

echo "Running flutter analyze on lib/..."

if [[ "$strict_mode" == "true" ]]; then
  # Strict mode: fail on errors and warnings
  flutter analyze lib --no-pub --no-fatal-infos
else
  # Default: fail on errors only (CI gate mode)
  flutter analyze lib --no-pub --no-fatal-warnings --no-fatal-infos
fi

echo "Lint check passed."

echo "Running setState budget audit..."
./tool/setstate_audit.sh lib
