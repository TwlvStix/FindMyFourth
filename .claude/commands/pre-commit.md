Before committing, verify the following. Do not modify files — only report issues.

1. Run `flutter analyze` — must pass with zero warnings
2. Run `flutter test` — all tests must pass
3. Check that no files I modified contain `print()` or `debugPrint()` — must use `AppLog.d()`
4. Check that no widget files I modified exceed 300 lines
5. Check that no widget or controller files I modified contain direct Firestore/Auth calls
6. Verify all `setState` calls after `await` have `if (!mounted) return;` guards
7. Check that no modified files introduce hardcoded `Color(0x...)` or `Colors.` — use `AppColors` tokens
8. Verify any new `StreamSubscription` has a corresponding `cancel()` in `dispose()`

Report pass/fail for each check. If all pass, say "Ready to commit." If any fail, list what needs to be fixed.
