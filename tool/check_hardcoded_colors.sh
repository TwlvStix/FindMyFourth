#!/bin/bash

# Hardcoded Color Checker
# Fails if hardcoded colors are found in lib/ outside of allowlisted files.
#
# Usage:
#   ./tool/check_hardcoded_colors.sh        # CI mode: exits 1 on violations
#   ./tool/check_hardcoded_colors.sh report # Report mode: prints findings without failing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ALLOWLIST_FILE="$SCRIPT_DIR/hardcoded_color_allowlist.txt"

# Mode: "ci" (default) or "report"
MODE="${1:-ci}"

# Read allowlist paths (relative to lib/)
ALLOWLIST_PATTERNS=""
if [[ -f "$ALLOWLIST_FILE" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    # Build grep exclude pattern
    ALLOWLIST_PATTERNS="$ALLOWLIST_PATTERNS|$line"
  done < "$ALLOWLIST_FILE"
fi
# Remove leading pipe
ALLOWLIST_PATTERNS="${ALLOWLIST_PATTERNS#|}"

echo "Checking for hardcoded colors in lib/..."
echo ""

# Check for Colors.* patterns (excluding AppColors, ArchetypeColors, appColors, AppThemeColors)
# Also filters out:
#   - Comments (lines starting with // or ///)
#   - Variable names containing "Colors" (e.g., _avatarColors.length)
#   - Debug infrastructure (lib/debug/)
COLORS_VIOLATIONS=$(grep -rn "Colors\." "$PROJECT_ROOT/lib" --include="*.dart" 2>/dev/null \
  | grep -v "AppColors" \
  | grep -v "ArchetypeColors" \
  | grep -v "appColors" \
  | grep -v "AppThemeColors" \
  | grep -v "/lib/debug/" \
  | grep -vE "^\s*//|:\s*//" \
  | grep -vE '[a-zA-Z0-9_]Colors\.' \
  || true)

# Check for Color(0x...) patterns
HEX_VIOLATIONS=$(grep -rn "Color(0x" "$PROJECT_ROOT/lib" --include="*.dart" 2>/dev/null \
  | grep -v "/lib/debug/" \
  | grep -vE "^\s*//|:\s*//" \
  || true)

# Check for Color.fromARGB patterns
ARGB_VIOLATIONS=$(grep -rn "Color\.fromARGB" "$PROJECT_ROOT/lib" --include="*.dart" 2>/dev/null \
  | grep -v "/lib/debug/" \
  | grep -vE "^\s*//|:\s*//" \
  || true)

# Check for Color.fromRGBO patterns
RGBO_VIOLATIONS=$(grep -rn "Color\.fromRGBO" "$PROJECT_ROOT/lib" --include="*.dart" 2>/dev/null \
  | grep -v "/lib/debug/" \
  | grep -vE "^\s*//|:\s*//" \
  || true)

# Filter out allowlisted files
if [[ -n "$ALLOWLIST_PATTERNS" ]]; then
  COLORS_VIOLATIONS=$(echo "$COLORS_VIOLATIONS" | grep -vE "$ALLOWLIST_PATTERNS" || true)
  HEX_VIOLATIONS=$(echo "$HEX_VIOLATIONS" | grep -vE "$ALLOWLIST_PATTERNS" || true)
  ARGB_VIOLATIONS=$(echo "$ARGB_VIOLATIONS" | grep -vE "$ALLOWLIST_PATTERNS" || true)
  RGBO_VIOLATIONS=$(echo "$RGBO_VIOLATIONS" | grep -vE "$ALLOWLIST_PATTERNS" || true)
fi

# Count violations (handle empty strings properly)
if [[ -z "$COLORS_VIOLATIONS" ]]; then
  COLORS_COUNT=0
else
  COLORS_COUNT=$(echo "$COLORS_VIOLATIONS" | wc -l | tr -d ' ')
fi

if [[ -z "$HEX_VIOLATIONS" ]]; then
  HEX_COUNT=0
else
  HEX_COUNT=$(echo "$HEX_VIOLATIONS" | wc -l | tr -d ' ')
fi

if [[ -z "$ARGB_VIOLATIONS" ]]; then
  ARGB_COUNT=0
else
  ARGB_COUNT=$(echo "$ARGB_VIOLATIONS" | wc -l | tr -d ' ')
fi

if [[ -z "$RGBO_VIOLATIONS" ]]; then
  RGBO_COUNT=0
else
  RGBO_COUNT=$(echo "$RGBO_VIOLATIONS" | wc -l | tr -d ' ')
fi

TOTAL_COUNT=$((COLORS_COUNT + HEX_COUNT + ARGB_COUNT + RGBO_COUNT))

# Report findings
if [[ "$COLORS_COUNT" -gt 0 ]]; then
  echo "=== Colors.* violations ($COLORS_COUNT) ==="
  echo "$COLORS_VIOLATIONS"
  echo ""
fi

if [[ "$HEX_COUNT" -gt 0 ]]; then
  echo "=== Color(0x...) violations ($HEX_COUNT) ==="
  echo "$HEX_VIOLATIONS"
  echo ""
fi

if [[ "$ARGB_COUNT" -gt 0 ]]; then
  echo "=== Color.fromARGB violations ($ARGB_COUNT) ==="
  echo "$ARGB_VIOLATIONS"
  echo ""
fi

if [[ "$RGBO_COUNT" -gt 0 ]]; then
  echo "=== Color.fromRGBO violations ($RGBO_COUNT) ==="
  echo "$RGBO_VIOLATIONS"
  echo ""
fi

# Summary
echo "=== Summary ==="
echo "Colors.* violations: $COLORS_COUNT"
echo "Color(0x...) violations: $HEX_COUNT"
echo "Color.fromARGB violations: $ARGB_COUNT"
echo "Color.fromRGBO violations: $RGBO_COUNT"
echo "Total: $TOTAL_COUNT"
echo ""

# Exit based on mode
if [[ "$MODE" == "report" ]]; then
  echo "Report mode: Not failing."
  exit 0
fi

if [[ "$TOTAL_COUNT" -gt 0 ]]; then
  echo "FAILED: Found $TOTAL_COUNT hardcoded color violation(s)."
  echo ""
  echo "Fix by replacing with AppColors tokens from lib/core/design_tokens/colors.dart"
  echo "Or add file to tool/hardcoded_color_allowlist.txt if intentional."
  exit 1
fi

echo "PASSED: No hardcoded color violations found."
exit 0
