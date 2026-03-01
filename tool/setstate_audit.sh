#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-lib}"
SETSTATE_BUDGET="${SETSTATE_BUDGET:-150}"

count_matches() {
  local pattern="$1"
  (rg -nUP --glob "*.dart" "$pattern" "$ROOT_DIR" 2>/dev/null || true) | wc -l | tr -d ' '
}

total_setstate="$(count_matches 'setState\s*\(')"
empty_or_comment_only="$(count_matches 'setState\s*\(\s*\(\s*\)\s*\{\s*(?:(?://[^\n]*\n)|\s)*\}\s*\)')"
empty_single_line="$(count_matches 'setState\s*\(\s*\(\s*\)\s*\{\s*\}\s*\)')"

echo "setState audit (root: ${ROOT_DIR})"
echo "  budget: ${SETSTATE_BUDGET}"
echo "  total setState occurrences: ${total_setstate}"
echo "  empty/comment-only setState occurrences: ${empty_or_comment_only}"
echo "  one-line empty setState occurrences: ${empty_single_line}"
echo
echo "Top files by setState count:"
rg -n --glob "*.dart" "setState\\s*\\(" "$ROOT_DIR" 2>/dev/null \
  | awk -F: '{count[$1]++} END {for (f in count) printf "%4d %s\n", count[f], f}' \
  | sort -nr \
  | head -20

if [[ "${total_setstate}" -gt "${SETSTATE_BUDGET}" ]]; then
  echo
  echo "FAIL: setState count (${total_setstate}) exceeds budget (${SETSTATE_BUDGET})." >&2
  exit 1
fi

if [[ "${empty_or_comment_only}" -gt 0 ]]; then
  echo
  echo "FAIL: empty/comment-only setState closures are not allowed." >&2
  exit 1
fi

echo
echo "PASS: setState budget and empty-closure checks passed."
