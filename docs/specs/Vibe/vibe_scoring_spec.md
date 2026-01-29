# VIBE Matchmaking & Group Scoring Specification

## 1. Objective (Plain English)

- Optimize for the probability that **all 2–4 golfers enjoy the round**.
- A single bad pairing can ruin a foursome, so **worst-pair and odd-one-out effects must matter**.
- Dealbreakers behave like **constraints**, not numeric score cliffs.
- Imperfect matches degrade **smoothly and explainably**, not collapsing to arbitrary values.

This system must always be able to answer: **“Why is this match ranked here?”**

---

## 2. Scoring Contract (Inputs → Outputs)

### 2.1 Inputs

Each golfer has a `VibeProfile` with categories on a **0–5 scale**.

Per category:
- `value: double` (0–5)
- `tolerance: double` (0–5, higher = more tolerant)
- `weight: double >= 0`
- `dealbreaker: bool`
- `isDefault: bool` (or equivalent unanswered flag)

Global tuning constants:
- Base scoring constants (existing)
- Hard block margin
- Soft risk curve parameters
- Group penalty parameters

---

### 2.2 Outputs (Decision Bundle)

Returned for **both pair and group evaluation**.

Required fields:
- `baseScorePercent: double` (0–100)
- `finalScorePercent: double` (0–100)

- `recommendation: enum`:
  - `Recommended`
  - `Caution`
  - `NotRecommended`

- `hardConflicts: List<HardConflict>`
- `softRisks: List<SoftRisk>`
- `fairnessFlags: List<FairnessFlag>`

- `confidence01: double` (0–1)

---

### 2.3 Output Semantics

- **baseScorePercent**: existing weighted compatibility score before penalties.
- **finalScorePercent**: baseScore adjusted by soft risk and group penalties.
- **recommendation**:
  - `NotRecommended` only from hard blocks
  - `Caution` from accumulated risk or group structure issues
  - `Recommended` otherwise
- **confidence01**: fraction of usable signal in the comparison (see Section 3).

---

## 3. Confidence (Single Definition)

Confidence measures **how much meaningful data was available**, not “truth”.

For each category:
- `answeredPair = A.answered && B.answered`
- `confidenceContribution = weight * (answeredPair ? 1 : defaultPenaltyMultiplier)`

Final:
```
confidence01 = clamp01(sum(confidenceContribution) / sum(weight))
```

Rules:
- `defaultPenaltyMultiplier < 1` (typical 0.4–0.7)
- Same semantics for pairs and groups
- Must align with any existing default-weight logic

---

## 4. Dealbreaker Rules (Hard vs Soft)

### 4.1 Shared Primitives

```
distance = abs(a.value - b.value)

combinedTolerance =
  wMin * min(aTol, bTol) +
  wAvg * ((aTol + bTol) / 2)

overBy = max(0, distance - combinedTolerance)
```

- `wMin + wAvg = 1`
- These semantics must be reused everywhere.

---

### 4.2 Hard Block (Constraint)

A category hard-blocks a pair if:
- At least one side has `dealbreaker == true`
- Both sides answered (not default)
- `distance >= combinedTolerance + hardMargin`

If triggered:
- Pair recommendation = `NotRecommended`
- Add entry to `hardConflicts`
- Score may still be computed for explanation, but ranking treats hard-blocked matches as bottom-tier.

Hard blocks do **not** create numeric cap values.

---

### 4.3 Soft Risk (Continuous Penalty)

If not hard-blocked:
```
severity01 = clamp01((overBy / riskScale) ^ riskCurveP)
```

Aggregate:
```
softRiskPenalty01 = weightedMean(severity01, categoryRiskWeight)
finalScorePercent = baseScorePercent * (1 - softRiskPenalty01)
```

---

### 4.4 Recommendation Thresholds

- `NotRecommended`: any hard block
- `Caution`: softRiskPenalty01 ≥ cautionThreshold OR group penalties high (Section 5)
- `Recommended`: otherwise

---

## 5. Group Objective Function (2–4 Players)

Group size `n` in {2,3,4}. Compute all unordered pair results `R_ij`.

### 5.1 Group Hard Block

```
groupHardBlocked = any(R_ij.recommendation == NotRecommended)
```

If true:
- Group recommendation = `NotRecommended`
- Group hardConflicts = union of pair conflicts (tagged by pair)
- Score may still be computed for explanation.

### 5.2 Group Base Score

```
groupBaseScore = mean(R_ij.baseScorePercent)
```

### 5.3 Group Soft Risk

```
groupSoftRiskPenalty01 = mean(R_ij.softRiskPenalty01)
scoreAfterSoftRisk = groupBaseScore * (1 - groupSoftRiskPenalty01)
```

### 5.4 Worst-Pair Penalty

```
worstPairFinal = min(R_ij.finalScorePercent)

worstPairPenalty01 = clamp01((worstPairFloor - worstPairFinal) / worstPairRange)

scoreAfterWorstPair =
  scoreAfterSoftRisk * (1 - worstPairPenalty01 * worstPairPenaltyMax)
```

Purpose: avoid “one disaster hidden by averages”.

### 5.5 Odd-One-Out Penalty (Fairness)

For each member `k`:
```
avgToOthers(k) = mean(R_kj.finalScorePercent for j != k)
groupAvg = mean(avgToOthers(k))
oddOneOutGap = groupAvg - min(avgToOthers(k))
oddOneOutPenalty01 = clamp01(oddOneOutGap / oddOneOutGapScale)

finalGroupScore =
  scoreAfterWorstPair * (1 - oddOneOutPenalty01 * oddOneOutPenaltyMax)
```

Flag the member with the lowest `avgToOthers`.

### 5.6 Group Recommendation (Non-Hard-Blocked)

`Caution` if any:
- groupSoftRiskPenalty01 ≥ cautionThreshold
- worstPairFinal < worstPairCautionFloor
- oddOneOutPenalty01 ≥ oddOneOutCautionSeverity

Else: `Recommended`

---

## 6. Golden Test Datasets (Required)

- `golden_pairs.json`: 20–30 pair cases with expected ordering and explanations.
- `golden_groups.json`: 20–30 group cases with expected ordering and fairness expectations.

Golden datasets should assert ordering (rank buckets), not exact numeric scores.

---

## 7. Acceptance Criteria

- No unexplained score cliffs.
- Any low score explainable by returned hardConflicts / softRisks / fairnessFlags.
- Group scores correlate with member-level fit; odd-one-out must be flagged.
- Same tolerance semantics everywhere.
- Sorting uses (recommendation tier, finalScorePercent).
- Unit tests cover hard blocks, soft risk curve, group penalties, confidence.
- Golden datasets pass and gate regressions.

---

## 8. Deliverables

- Pair + group scoring engine
- Unified decision bundle output
- Golden datasets (pairs + groups)
- Unit tests
- Tuning constants file with comments
