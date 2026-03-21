Before committing, verify the following. Do not modify files — only report issues.

Scope: Only check files modified in this commit (staged + unstaged changes).

## Gate Checks (must all pass)

1. Run `flutter analyze` — must pass with zero warnings
2. Run `flutter test` — all tests must pass
3. Check that no modified `.dart` files contain `print()` or `debugPrint()` calls — must use `AppLog.d()` (exclude `lib/core/utils/app_log.dart` which is the logger itself)
4. Check that no modified `*_widget.dart` files exceed 300 lines AND no modified `*_controller.dart` files exceed 300 lines (see `.claude/Rules/widgets.md` for grace zone and legacy exceptions)
5. Check that no modified widget, controller, or provider files contain direct `FirebaseFirestore.instance` or `FirebaseAuth.instance` calls — these belong in `lib/services/` and `lib/auth/firebase_auth/` only (see `.claude/Rules/services.md`)
6. Verify all `setState` calls after `await` have `if (!mounted) return;` guards — check after EACH await in multi-await methods, not just the first
7. Check that no modified files introduce hardcoded colors: `Color(0x...)`, `Colors.` (excluding AppColors/ArchetypeColors/appColors/AppThemeColors), `Color.fromARGB()`, or `Color.fromRGBO()` — use `AppColors` tokens. See `tool/hardcoded_color_allowlist.txt` for exemptions. Also exclude comments and variable names containing "Colors".
8. Verify any new `StreamSubscription` has a corresponding `cancel()` in `dispose()`
9. Check that no modified files use `import 'package:find_my_fourth/...'` — must use `import '/...'` for project files
10. Check that no modified files contain empty `setState(() {})` closures (including comment-only closures like `setState(() { // comment })`)
11. Check that no modified files use `BorderRadius.circular()` with a hardcoded numeric literal (e.g., `BorderRadius.circular(12)`) — must use `AppBorderRadius` tokens (e.g., `BorderRadius.circular(AppBorderRadius.card)`). Exclude `lib/core/design_tokens/`.

## Reporting

Report each check as:
- PASS — no issues found
- FAIL — issue found, list file(s) and line(s)

If all pass: **"Ready to commit."**
If any fail: List what needs to be fixed before committing.
