import 'dart:math';

import '/models/vibe_profile.dart';
import '/vibe/vibe_tuning.dart';

class AppliedRule {
  const AppliedRule({
    required this.ruleId,
    required this.category,
    required this.bonus,
    required this.reason,
    required this.debugSnapshot,
  });

  final String ruleId;
  final VibeCategory category;
  final double bonus;
  final String reason;
  final Map<String, double> debugSnapshot;
}

class AdjustmentResult {
  const AdjustmentResult({
    required this.bonusTotal,
    required this.reasons,
    required this.appliedRules,
  });

  final double bonusTotal;
  final List<String> reasons;
  final List<AppliedRule> appliedRules;
}

/// Phase 1: removed hardcoded _interactionBonusCap = 0.12.
/// Now uses VibeTuning.interactionBonusCap (0.04).

AdjustmentResult interactionAdjustments(
  Map<VibeCategory, double> scoresByCategory,
  Map<VibeCategory, bool> mismatchedByCategory, {
  bool enableInteractionLayer = true,
}) {
  if (!enableInteractionLayer) {
    return const AdjustmentResult(
      bonusTotal: 0,
      reasons: [],
      appliedRules: [],
    );
  }

  double scoreOf(VibeCategory category) {
    return (scoresByCategory[category] ?? 0).clamp(0, 1).toDouble();
  }

  bool isMismatched(VibeCategory category) {
    return mismatchedByCategory[category] ?? false;
  }

  final appliedRules = <AppliedRule>[];
  final reasons = <String>[];
  var bonusTotal = 0.0;

  void applyRule({
    required String ruleId,
    required VibeCategory category,
    required double bonus,
    required String reason,
    required Map<String, double> debugSnapshot,
  }) {
    if (!isMismatched(category)) {
      return;
    }
    final remaining = VibeTuning.interactionBonusCap - bonusTotal;
    if (remaining <= 0) {
      return;
    }
    final appliedBonus = min(bonus, remaining).clamp(0, 1).toDouble();
    if (appliedBonus <= 0) {
      return;
    }
    bonusTotal += appliedBonus;
    appliedRules.add(
      AppliedRule(
        ruleId: ruleId,
        category: category,
        bonus: appliedBonus,
        reason: reason,
        debugSnapshot: debugSnapshot,
      ),
    );
    reasons.add(reason);
  }

  final pace = scoreOf(VibeCategory.pace);
  final chat = scoreOf(VibeCategory.chat);
  final competitive = scoreOf(VibeCategory.competitive);
  final money = scoreOf(VibeCategory.money);

  // Phase 1: tightened trigger thresholds — bonuses should only
  // apply when the supporting categories are genuinely strong matches,
  // not just "okay." Individual bonus amounts also reduced since the
  // total cap is now 0.04.

  if (pace >= 0.90 && chat >= 0.85) {
    applyRule(
      ruleId: 'drinking_pace_chat',
      category: VibeCategory.drinking,
      bonus: 0.02,
      reason:
          'Drinking difference is likely fine because you both match strongly on pace and conversation.',
      debugSnapshot: {
        'pace': pace,
        'chat': chat,
      },
    );
  }

  if (competitive >= 0.90 || chat <= 0.30) {
    applyRule(
      ruleId: 'music_competitive_or_quiet',
      category: VibeCategory.music,
      bonus: 0.02,
      reason:
          'Music preferences are less important here because your play style is focused or you both prefer a quieter round.',
      debugSnapshot: {
        'competitive': competitive,
        'chat': chat,
      },
    );
  }

  if (competitive <= 0.30) {
    applyRule(
      ruleId: 'chat_casual_competitive',
      category: VibeCategory.chat,
      bonus: 0.02,
      reason:
          'Different chat levels can work because you both seem to prefer a more casual round.',
      debugSnapshot: {
        'competitive': competitive,
      },
    );
  }

  if (money >= 0.85 && pace >= 0.85) {
    applyRule(
      ruleId: 'competitive_pace_money',
      category: VibeCategory.competitive,
      bonus: 0.02,
      reason:
          'Different competitiveness can still work because you align on pace and shared expectations around the round.',
      debugSnapshot: {
        'money': money,
        'pace': pace,
      },
    );
  }

  final clampedBonus = clampDouble(
    bonusTotal,
    0,
    VibeTuning.interactionBonusCap,
  );

  return AdjustmentResult(
    bonusTotal: clampedBonus,
    reasons: reasons,
    appliedRules: appliedRules,
  );
}

double clampDouble(double value, double minValue, double maxValue) {
  return value.clamp(minValue, maxValue).toDouble();
}
