# VIBE Tuning Guide (Knobs, Intent, Safe Ranges)

This doc explains every tunable parameter in the VIBE engine, what it is *for*, and how changing it will affect behavior.
Goal: prevent “cargo cult tuning” and make changes reversible and testable.

## 1) Core principle

- **Hard blocks** are constraints. They should be rare and obvious.
- **Soft risk** shapes ranking among imperfect matches. It should be smooth (no cliffs).
- **Group penalties** protect against “one bad pairing ruins the foursome” and “odd one out” situations.

Any tuning change must:
1) keep unit tests passing
2) keep golden datasets passing *or* intentionally update golden ordering with a written rationale

---

## 2) Tolerance blending

### `wMin`, `wAvg` (must sum to 1)
Used in:
- mismatch semantics
- soft risk severity
- hard block thresholding
- explanations

Meaning:
- `wMin` increases strictness when one person is strict.
- `wAvg` makes tolerance more “shared”.

Behavior:
- Increase `wMin`: more “strict person dominates”, more risk/hard blocks.
- Increase `wAvg`: more forgiving, fewer risk penalties.

Safe ranges (0–5 scale):
- `wMin`: 0.35–0.70
- `wAvg`: 0.30–0.65

---

## 3) Hard block parameters

### `hardMargin`
Hard block triggers when:
`distance >= combinedTolerance + hardMargin`

Meaning:
- Adds a buffer so dealbreakers behave like constraints *only when mismatch is clearly beyond tolerance*.

Behavior:
- Increase: fewer hard blocks (more things become soft risk instead)
- Decrease: more hard blocks (system becomes stricter)

Safe range:
- 1.5–2.5 (on 0–5 scale)

Watch-outs:
- Too low = many NotRecommended results, less useful matchmaking
- Too high = dealbreakers feel ignored

---

## 4) Soft risk curve parameters

### `riskScale`
Used in:
`severity01 = clamp01((overBy / riskScale) ^ riskCurveP)`

Meaning:
- Sets how quickly risk grows once you are beyond tolerance.

Behavior:
- Increase: more forgiving (need larger overBy to get the same severity)
- Decrease: harsher penalties sooner

Safe range:
- 1.25–2.25

### `riskCurveP`
Exponent for curvature.

Behavior:
- Increase: small overBy barely hurts, large overBy gets punished heavily (more “S-curve” feel)
- Decrease: penalty is more linear

Safe range:
- 1.4–2.6

### `riskMaxDefault` (if using per-category multipliers)
If you implement `severity -> multiplier` via `1 - severity * riskMax`, this caps the max per-category impact.

Behavior:
- Increase: mismatches can drop scores more
- Decrease: mismatches become “soft suggestions”

Safe range:
- 0.35–0.60

---

## 5) Recommendation thresholds

### `cautionThreshold` (softRiskPenalty01)
Behavior:
- Decrease: more “Caution” labels (more sensitive)
- Increase: fewer cautions (more optimistic)

Safe range:
- 0.20–0.35

### `worstPairCautionFloor`
Triggers caution if the worst pair is too low.

Safe range:
- 55–70

### `oddOneOutCautionSeverity`
Triggers caution if one member is notably mismatched.

Safe range:
- 0.45–0.75

---

## 6) Group penalties

### Worst-pair penalty
- `worstPairFloor`
- `worstPairRange`
- `worstPairPenaltyMax`

Intent:
- Protect the group from a single bad pairing being hidden by averages.

Behavior:
- Raise `worstPairPenaltyMax`: groups with one bad pair fall more
- Raise `worstPairFloor`: penalty triggers sooner

Safe ranges:
- `worstPairFloor`: 60–70
- `worstPairRange`: 25–45
- `worstPairPenaltyMax`: 0.20–0.45

### Odd-one-out penalty
- `oddOneOutGapScale`
- `oddOneOutPenaltyMax`

Intent:
- Penalize groups where one person’s average-to-others is meaningfully lower.

Behavior:
- Lower `oddOneOutGapScale`: triggers stronger penalties more often
- Raise `oddOneOutPenaltyMax`: bigger impact when odd-one-out is detected

Safe ranges:
- `oddOneOutGapScale`: 15–30
- `oddOneOutPenaltyMax`: 0.15–0.30

---

## 7) Defaults / unanswered handling

### `defaultPenaltyMultiplier`
Used in confidence, and should match how you down-weight default answers in scoring.

Behavior:
- Lower: default answers reduce confidence more (UI should reflect lower certainty)
- Higher: defaults matter less

Safe range:
- 0.4–0.8

Guideline:
- Defaults should reduce confidence and influence, but should **not** hard block.

---

## 8) How to tune safely (workflow)

1) Decide what “feels wrong”:
- too many NotRecommended?
- too many Caution?
- scores too clustered?
- odd-one-out not punished enough?

2) Change only one knob at a time.

3) Run:
- unit tests
- golden datasets

4) If you intentionally change behavior:
- update golden ordering
- add a short rationale note in the git commit

---

## 9) Quick symptom → knob mapping

- “Too many NotRecommended”: increase `hardMargin` or increase `wAvg`
- “Dealbreakers feel ignored”: decrease `hardMargin`
- “Scores barely move among imperfect matches”: decrease `riskScale` or increase `riskCurveP`
- “Small mismatches punished too hard”: increase `riskScale` or increase `riskCurveP`
- “One bad pair not tanking group enough”: increase `worstPairPenaltyMax` or raise `worstPairFloor`
- “Odd one out not detected”: lower `oddOneOutGapScale` or increase `oddOneOutPenaltyMax`
- “Everything is Caution”: increase `cautionThreshold` or increase `riskScale`
