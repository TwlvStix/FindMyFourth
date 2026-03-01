# setState Budget Policy

## Goals
- Keep widget rebuild scope small and predictable.
- Prevent regressions from broad or no-op `setState` usage.
- Maintain measurable limits that can be enforced in CI.

## Rules
- Total `setState(` occurrences in `lib/**/*.dart` must stay at or below `150`.
- Empty or comment-only closures are not allowed:
  - `setState(() {})`
  - `setState(() { /* no mutation */ })`
- Prefer `updateState(this, ...)` from `lib/core/utils/state_update.dart` when updating local state in `State` classes.

## Preferred Patterns
- For isolated local UI state, use `ValueNotifier` + `ValueListenableBuilder`.
- For app/shared state, use Provider selectors (`context.select`, `Selector`) to reduce rebuild scope.
- Keep async/network orchestration outside presentation-heavy widgets when possible.

## Enforcement
- Local/CI command: `./tool/setstate_audit.sh lib`
- Lint gate command: `./scripts/lint_lib.sh`

`scripts/lint_lib.sh` runs analyzer checks and then the setState budget audit.
