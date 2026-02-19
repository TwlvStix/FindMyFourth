import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/fairway_background.dart';

/// YourStandingScreen
///
/// Private "Your Standing" view showing the current user's:
/// - Active strikes with reasons and expiry dates
/// - Show-up rate and cancellation rate
/// - Badge progress (weighted rounds toward next tier)
/// - Next badge requirements
///
/// Data is fetched fresh via the `getMyStanding` cloud function.
class YourStandingScreen extends StatefulWidget {
  const YourStandingScreen({super.key});

  static const String routeName = 'YourStanding';
  static const String routePath = '/yourStanding';

  @override
  State<YourStandingScreen> createState() => _YourStandingScreenState();
}

class _YourStandingScreenState extends State<YourStandingScreen> {
  bool _loading = true;
  String? _error;
  bool _isEmpty = false;
  Map<String, dynamic>? _standing;

  @override
  void initState() {
    super.initState();
    _loadStanding();
  }

  Future<void> _loadStanding() async {
    final uid = currentUserUid;
    if (uid.isEmpty) {
      if (mounted) setState(() { _loading = false; _error = 'Not signed in.'; });
      return;
    }
    try {
      final result = await makeCloudCall('getMyStanding', {'userId': uid});
      if (mounted) {
        setState(() {
          _loading = false;
          if (result.isNotEmpty) {
            _standing = result;
            _isEmpty = false;
            _error = null;
          } else {
            _standing = null;
            _isEmpty = true;
            _error = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load your standing. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FairwayBackgroundDark(
      showOrganic: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _loading
                    ? _buildLoader()
                    : _error != null
                        ? _buildError()
                        : _isEmpty
                            ? _buildEmpty()
                            : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Text(
            'Your Standing',
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading / Error states ──────────────────────────────────────────────────

  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.sunsetGold),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.white.withOpacity(0.5), size: 48),
            SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
            _RetryButton(onTap: () {
              HapticFeedback.lightImpact();
              setState(() { _loading = true; _error = null; });
              _loadStanding();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.sports_golf_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'No activity yet',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Once you play your first verified round, your standing details will appear here — including your show-up rate, badge progress, and strike history.',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Main content ───────────────────────────────────────────────────────────

  Widget _buildContent() {
    final s = _standing!;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadgeProgressCard(s),
          SizedBox(height: AppSpacing.md),
          _buildStrikesSection(s),
          SizedBox(height: AppSpacing.md),
          _buildRatesSection(s),
          SizedBox(height: AppSpacing.md),
          _buildNextBadgeSection(s),
        ],
      ),
    );
  }

  // ── Badge Progress Card ────────────────────────────────────────────────────

  Widget _buildBadgeProgressCard(Map<String, dynamic> s) {
    final currentBadge = (s['currentBadge'] as String?) ?? 'new';
    final nextBadge = s['nextBadge'] as String?;
    final weighted = (s['weightedRounds'] as num?)?.toDouble() ?? 0.0;
    final info = _badgeInfo(currentBadge);
    final nextInfo = nextBadge != null ? _badgeInfo(nextBadge) : null;

    // Progress toward next badge (weighted rounds component)
    final nextReqs = s['nextBadgeRequirements'] as Map<String, dynamic>?;
    final roundsNeeded = (nextReqs?['weightedRounds'] as num?)?.toDouble() ?? 0.0;
    final progress = roundsNeeded > 0
        ? (weighted / (weighted + roundsNeeded)).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [info.gradientStart, info.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: info.gradientStart.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(info.icon, color: Colors.white, size: 24),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.label,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Current badge',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${weighted.toStringAsFixed(1)}',
                style: AppTypography.monoMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (nextInfo != null) ...[
            SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress to ${nextInfo.label}',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
            if (nextReqs != null) ...[
              SizedBox(height: AppSpacing.sm),
              _buildProgressGaps(nextReqs, s),
            ],
          ] else ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              'Top tier — you\'re an Anchor.',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressGaps(
      Map<String, dynamic> nextReqs, Map<String, dynamic> s) {
    final parts = <String>[];
    final rw = (nextReqs['weightedRounds'] as num?)?.toDouble() ?? 0.0;
    final ru = (nextReqs['uniqueCoPlayers'] as num?)?.toInt() ?? 0;
    final rh = (nextReqs['gamesHosted'] as num?)?.toInt() ?? 0;
    if (rw > 0) parts.add('${rw.toStringAsFixed(1)} more weighted rounds');
    if (ru > 0) parts.add('$ru more unique co-players');
    if (rh > 0) parts.add('$rh more hosted games');
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: AppTypography.labelSmall.copyWith(
        color: Colors.white.withOpacity(0.75),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ── Strikes Section ────────────────────────────────────────────────────────

  Widget _buildStrikesSection(Map<String, dynamic> s) {
    final strikes = (s['strikes'] as List<dynamic>?) ?? [];
    final activeCount = (s['activeStrikeCount'] as num?)?.toInt() ?? 0;
    final nextThreshold = s['nextThreshold'] as int?;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded,
                  color: activeCount > 0 ? AppColors.warning : AppColors.success,
                  size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Active Strikes',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.onyx,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: activeCount > 0
                      ? AppColors.warning.withOpacity(0.15)
                      : AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$activeCount',
                  style: AppTypography.labelSmall.copyWith(
                    color: activeCount > 0 ? AppColors.warning : AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (nextThreshold != null && activeCount < nextThreshold) ...[
            SizedBox(height: AppSpacing.xs),
            Text(
              '${nextThreshold - activeCount} more until: ${_thresholdLabel(nextThreshold)}',
              style: AppTypography.labelSmall.copyWith(color: AppColors.stone),
            ),
          ],
          if (strikes.isEmpty) ...[
            SizedBox(height: AppSpacing.md),
            Text(
              'No active strikes.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.stone),
            ),
          ] else ...[
            SizedBox(height: AppSpacing.md),
            ...strikes.map((strike) {
              final map = strike as Map<String, dynamic>;
              return _StrikeRow(strike: map);
            }),
          ],
        ],
      ),
    );
  }

  String _thresholdLabel(int threshold) {
    switch (threshold) {
      case 1: return '24-hour cooldown';
      case 2: return '48-hour cooldown';
      case 3: return '1-week cooldown';
      case 4: return '2-week cooldown';
      default: return 'Game restriction';
    }
  }

  // ── Rates Section ──────────────────────────────────────────────────────────

  Widget _buildRatesSection(Map<String, dynamic> s) {
    final showUpRate = (s['showUpRate'] as num?)?.toDouble();
    final showUpDenom = (s['showUpRateDenominator'] as num?)?.toInt() ?? 0;
    final cancelRate = (s['cancellationRate'] as num?)?.toDouble();
    final cancelNum = (s['cancellationRateNumerator'] as num?)?.toInt() ?? 0;
    final cancelDenom = (s['cancellationRateDenominator'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        Expanded(
          child: _SectionCard(
            child: _buildRateTile(
              label: 'Show-Up Rate',
              icon: Icons.check_circle_rounded,
              rate: showUpRate,
              denominator: showUpDenom,
              highIsGood: true,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SectionCard(
            child: _buildRateTile(
              label: 'Cancel Rate',
              icon: Icons.cancel_outlined,
              rate: cancelRate,
              numerator: cancelNum,
              denominator: cancelDenom,
              highIsGood: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRateTile({
    required String label,
    required IconData icon,
    required double? rate,
    int? numerator,
    required int denominator,
    required bool highIsGood,
  }) {
    Color color;
    if (rate == null) {
      color = AppColors.stone;
    } else if (highIsGood) {
      color = rate >= 0.9
          ? AppColors.success
          : rate >= 0.75
              ? AppColors.warning
              : AppColors.error;
    } else {
      color = rate <= 0.10
          ? AppColors.success
          : rate <= 0.20
              ? AppColors.warning
              : AppColors.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                    color: AppColors.stone),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        rate == null
            ? Text(
                'N/A',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.stone,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Text(
                '${(rate * 100).toStringAsFixed(0)}%',
                style: AppTypography.monoMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
        SizedBox(height: AppSpacing.xxs),
        Text(
          rate == null
              ? 'Need 5+ rounds'
              : '$denominator game${denominator == 1 ? "" : "s"}',
          style: AppTypography.labelSmall.copyWith(color: AppColors.stone),
        ),
      ],
    );
  }

  // ── Next Badge Requirements ────────────────────────────────────────────────

  Widget _buildNextBadgeSection(Map<String, dynamic> s) {
    final nextBadge = s['nextBadge'] as String?;
    if (nextBadge == null) return const SizedBox.shrink();

    final nextReqs = s['nextBadgeRequirements'] as Map<String, dynamic>?;
    if (nextReqs == null) return const SizedBox.shrink();

    final weighted = (s['weightedRounds'] as num?)?.toDouble() ?? 0.0;
    final unique = (s['uniqueCoPlayers'] as num?)?.toInt() ?? 0;
    final hosted = (s['gamesHosted'] as num?)?.toInt() ?? 0;
    final cancelRate = (s['cancellationRate'] as num?)?.toDouble();

    final nextInfo = _badgeInfo(nextBadge);

    // Determine full requirements for next badge from BADGE_TIERS logic
    // We infer requirements from what gaps remain
    final rwNeeded = (nextReqs['weightedRounds'] as num?)?.toDouble() ?? 0.0;
    final ruNeeded = (nextReqs['uniqueCoPlayers'] as num?)?.toInt() ?? 0;
    final rhNeeded = (nextReqs['gamesHosted'] as num?)?.toInt() ?? 0;
    final maxCancelRate = (nextReqs['maxCancelRate'] as num?)?.toDouble();

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(nextInfo.icon, color: AppColors.sunsetGold, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Next: ${nextInfo.label}',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.onyx,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _buildRequirementRow(
            label: 'Weighted rounds',
            current: weighted,
            needed: weighted + rwNeeded,
            met: rwNeeded == 0,
            format: (v) => v.toStringAsFixed(1),
          ),
          SizedBox(height: AppSpacing.xs),
          _buildRequirementRow(
            label: 'Unique co-players',
            current: unique.toDouble(),
            needed: (unique + ruNeeded).toDouble(),
            met: ruNeeded == 0,
            format: (v) => v.toInt().toString(),
          ),
          if (rhNeeded > 0 || hosted > 0) ...[
            SizedBox(height: AppSpacing.xs),
            _buildRequirementRow(
              label: 'Games hosted',
              current: hosted.toDouble(),
              needed: (hosted + rhNeeded).toDouble(),
              met: rhNeeded == 0,
              format: (v) => v.toInt().toString(),
            ),
          ],
          if (maxCancelRate != null) ...[
            SizedBox(height: AppSpacing.xs),
            _buildCancelRateRequirementRow(
              cancelRate: cancelRate,
              maxCancelRate: maxCancelRate,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequirementRow({
    required String label,
    required double current,
    required double needed,
    required bool met,
    required String Function(double) format,
  }) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: met ? AppColors.success : AppColors.cloud,
          size: 18,
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.slate),
          ),
        ),
        Text(
          '${format(current)} / ${format(needed)}',
          style: AppTypography.labelSmall.copyWith(
            color: met ? AppColors.success : AppColors.stone,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelRateRequirementRow({
    required double? cancelRate,
    required double maxCancelRate,
  }) {
    final met = cancelRate != null && cancelRate <= maxCancelRate;
    final pct = cancelRate != null
        ? '${(cancelRate * 100).toStringAsFixed(0)}%'
        : 'N/A';
    final maxPct = '${(maxCancelRate * 100).toStringAsFixed(0)}%';
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: met ? AppColors.success : AppColors.cloud,
          size: 18,
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Cancel rate',
            style: AppTypography.bodySmall.copyWith(color: AppColors.slate),
          ),
        ),
        Text(
          '$pct (max $maxPct)',
          style: AppTypography.labelSmall.copyWith(
            color: met ? AppColors.success : AppColors.stone,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Badge metadata ─────────────────────────────────────────────────────────

  ({
    String label,
    IconData icon,
    Color gradientStart,
    Color gradientEnd,
  }) _badgeInfo(String badgeLevel) {
    switch (badgeLevel) {
      case 'anchor':
        return (
          label: 'Anchor',
          icon: Icons.anchor_rounded,
          gradientStart: AppColors.fairwayDark,
          gradientEnd: AppColors.fairway,
        );
      case 'starter':
        return (
          label: 'Starter',
          icon: Icons.flag_rounded,
          gradientStart: AppColors.fairway,
          gradientEnd: AppColors.fairwayLight,
        );
      case 'regular':
        return (
          label: 'Regular',
          icon: Icons.sports_golf_rounded,
          gradientStart: AppColors.fairwayLight,
          gradientEnd: AppColors.sunsetGold,
        );
      case 'confirmed':
        return (
          label: 'Confirmed',
          icon: Icons.verified_rounded,
          gradientStart: AppColors.sunsetGold,
          gradientEnd: AppColors.sunsetPeach,
        );
      case 'new':
      default:
        return (
          label: 'New Member',
          icon: Icons.person_outline_rounded,
          gradientStart: AppColors.stone,
          gradientEnd: AppColors.slate,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Strike Row
// ─────────────────────────────────────────────────────────────────────────────

class _StrikeRow extends StatelessWidget {
  const _StrikeRow({required this.strike});

  final Map<String, dynamic> strike;

  @override
  Widget build(BuildContext context) {
    final reason = strike['reason'] as String? ?? '';
    final expiresAtMs = (strike['expiresAt'] as num?)?.toInt();

    final label = _reasonLabel(reason);
    final expiryText = expiresAtMs != null
        ? _formatExpiry(DateTime.fromMillisecondsSinceEpoch(expiresAtMs))
        : '';

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.bolt_rounded,
                color: AppColors.warning, size: 16),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onyx,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (expiryText.isNotEmpty)
                  Text(
                    'Expires $expiryText',
                    style: AppTypography.labelSmall.copyWith(
                        color: AppColors.stone),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'day_of_cancel':
        return 'Same-day cancellation';
      case 'late_cancel_pattern':
        return 'Late cancellation pattern (3 in 90 days)';
      case 'ghost_no_show':
        return 'No-show (ghost)';
      default:
        return reason;
    }
  }

  String _formatExpiry(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.inDays > 0) {
      return 'in ${diff.inDays} day${diff.inDays == 1 ? "" : "s"}';
    } else if (diff.inHours > 0) {
      return 'in ${diff.inHours} hour${diff.inHours == 1 ? "" : "s"}';
    } else {
      return 'soon';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Card
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onyx.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Retry Button
// ─────────────────────────────────────────────────────────────────────────────

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.sunsetGold,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Try Again',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.onyx,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
