# Lightweight Phase 0 Baseline (Retrospective)

Date: 2026-02-28  
Scope: Post-Phase 1 baseline capture for refactored group vibe integration in:
- `lib/main_function/game_joined_detailed/game_joined_detailed_widget.dart`
- `lib/main_function/join_game_detailed/join_game_detailed_widget.dart`

## Method

Because both screens depend on Firebase-auth initialized globals at import/load time, this lightweight baseline captures:
- Static rebuild-pressure proxies for each screen file
- Contract coverage for refactor wiring
- Runtime for targeted lightweight test suite

Commands used:

```bash
wc -l lib/main_function/game_joined_detailed/game_joined_detailed_widget.dart \
      lib/main_function/join_game_detailed/join_game_detailed_widget.dart

rg -c "setState\(" lib/main_function/game_joined_detailed/game_joined_detailed_widget.dart \
                   lib/main_function/join_game_detailed/join_game_detailed_widget.dart

rg -c "StreamBuilder<" lib/main_function/game_joined_detailed/game_joined_detailed_widget.dart \
                       lib/main_function/join_game_detailed/join_game_detailed_widget.dart

rg -c "FutureBuilder<" lib/main_function/game_joined_detailed/game_joined_detailed_widget.dart \
                       lib/main_function/join_game_detailed/join_game_detailed_widget.dart
```

## Baseline Snapshot

| Metric | game_joined_detailed | join_game_detailed |
|---|---:|---:|
| Lines of code | 2022 | 1511 |
| `setState(` calls | 6 | 4 |
| `StreamBuilder<` count | 1 | 3 |
| `FutureBuilder<` count | 4 | 2 |
| `GroupVibeSummary(` count | 1 | 1 |
| `GroupVibeBreakdownSheet.show(` count | 1 | 1 |

## Lightweight Test Runtime Baseline

Targeted Phase 0 suite:

```bash
flutter test \
  test/providers/group_vibe_provider_test.dart \
  test/widgets/group_vibe_breakdown_sheet_test.dart \
  test/widgets/group_vibe_summary_interaction_test.dart \
  test/refactor_contracts/phase0_group_vibe_wiring_contract_test.dart
```

Observed wall time: ~3.1s (local run)

## Interpretation

- Both refactored screens now have a single provider-driven summary + breakdown hookup.
- Rebuild-pressure proxies are materially lower than pre-refactor vibe duplication paths and are now measurable for regression tracking.
- These values are the comparison point for Phase 2 decomposition changes.
