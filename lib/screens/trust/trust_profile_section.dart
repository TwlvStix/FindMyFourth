import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/schema/users_record.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/motion_helpers.dart';

/// TrustProfileSection
///
/// Displays the public-facing trust profile for a user: badge, stats,
/// show-up rate, and cancellation warning. Used on both the own profile
/// screen (MainProfile) and the other-user profile screen (ProfileUser).
///
/// Parameters:
///   user         - the UsersRecord to display
///   isOwnProfile - when true, warning detail uses more personal wording
class TrustProfileSection extends StatelessWidget {
  const TrustProfileSection({
    super.key,
    required this.user,
    this.isOwnProfile = false,
  });

  final UsersRecord user;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          SizedBox(height: AppSpacing.md),
          _buildBadgeRow(),
          SizedBox(height: AppSpacing.sm),
          _buildStatsGrid(),
          if (user.showUpRate != null) ...[
            SizedBox(height: AppSpacing.sm),
            _buildShowUpRateRow(),
          ],
          if (user.cancellationWarning) ...[
            SizedBox(height: AppSpacing.sm),
            _buildWarningRow(context),
          ],
        ],
      ),
    );
  }

  // ── Section header ──────────────────────────────────────────────────────

  Widget _buildSectionHeader() {
    return Text(
      'Trust Profile',
      style: AppTypography.titleMedium.copyWith(
        color: AppColors.onyx,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ── Badge row ───────────────────────────────────────────────────────────

  Widget _buildBadgeRow() {
    final info = _badgeInfo(user.badgeLevel);
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [info.gradientStart, info.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: info.gradientStart.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(info.icon, color: Colors.white, size: 22),
          ),
          SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.label,
                style: AppTypography.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSpacing.xxs),
              Text(
                info.description,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats grid ──────────────────────────────────────────────────────────

  Widget _buildStatsGrid() {
    final joinYear = user.createdTime != null
        ? '${user.createdTime!.year}'
        : '—';

    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.success,
            value: '${user.verifiedRoundCount}',
            label: 'Rounds',
          ),
        ),
        SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _buildStatTile(
            icon: Icons.group_outlined,
            iconColor: AppColors.fairway,
            value: '${user.uniqueCoPlayers.length}',
            label: 'Co-Players',
          ),
        ),
        SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _buildStatTile(
            icon: Icons.sports_golf_outlined,
            iconColor: AppColors.sunsetGold,
            value: '${user.gamesHosted}',
            label: 'Hosted',
          ),
        ),
        SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _buildStatTile(
            icon: Icons.calendar_today_outlined,
            iconColor: AppColors.sunsetPeach,
            value: joinYear,
            label: 'Joined',
            isText: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    bool isText = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cloud),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: isText
                ? AppTypography.labelSmall.copyWith(
                    color: AppColors.onyx,
                    fontWeight: FontWeight.w600,
                  )
                : AppTypography.monoLarge.copyWith(
                    color: AppColors.onyx,
                    fontWeight: FontWeight.w700,
                  ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.stone,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Show-up rate row ────────────────────────────────────────────────────

  Widget _buildShowUpRateRow() {
    final rate = user.showUpRate!;
    final denominator = user.showUpRateDenominator;
    final pct = (rate * 100).toStringAsFixed(0);
    final color = rate >= 0.9
        ? AppColors.success
        : rate >= 0.75
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cloud),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.check_circle_rounded, color: color, size: 20),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Show-Up Rate',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.stone,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  '$pct% · ${denominator} game${denominator == 1 ? "" : "s"}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onyx,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$pct%',
            style: AppTypography.monoLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Warning row ─────────────────────────────────────────────────────────

  Widget _buildWarningRow(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showWarningBottomSheet(context);
      },
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 22,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Cancellation history — tap for details',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.slate,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.stone,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showWarningBottomSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => _WarningDetailSheet(
        warningCount: user.cancellationWarningCount,
        isOwnProfile: isOwnProfile,
      ),
    );
  }

  // ── Badge metadata ──────────────────────────────────────────────────────

  ({
    String label,
    String description,
    IconData icon,
    Color gradientStart,
    Color gradientEnd,
  }) _badgeInfo(String badgeLevel) {
    switch (badgeLevel) {
      case 'anchor':
        return (
          label: 'Anchor',
          description: 'Cornerstone of the community',
          icon: Icons.anchor_rounded,
          gradientStart: AppColors.fairwayDark,
          gradientEnd: AppColors.fairway,
        );
      case 'starter':
        return (
          label: 'Starter',
          description: 'Trusted regular golfer',
          icon: Icons.flag_rounded,
          gradientStart: AppColors.fairway,
          gradientEnd: AppColors.fairwayLight,
        );
      case 'regular':
        return (
          label: 'Regular',
          description: 'Established member',
          icon: Icons.sports_golf_rounded,
          gradientStart: AppColors.fairwayLight,
          gradientEnd: AppColors.sunsetGold,
        );
      case 'confirmed':
        return (
          label: 'Confirmed',
          description: 'Verified by the community',
          icon: Icons.verified_rounded,
          gradientStart: AppColors.sunsetGold,
          gradientEnd: AppColors.sunsetPeach,
        );
      case 'new':
      default:
        return (
          label: 'New Member',
          description: 'Just getting started',
          icon: Icons.person_outline_rounded,
          gradientStart: AppColors.stone,
          gradientEnd: AppColors.slate,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Warning Detail Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _WarningDetailSheet extends StatelessWidget {
  const _WarningDetailSheet({
    required this.warningCount,
    required this.isOwnProfile,
  });

  final int warningCount;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final countLabel = warningCount == 1
        ? '1 late or same-day cancellation'
        : '$warningCount late or same-day cancellations';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pure,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cloud,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 24),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Cancellation Notice',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.onyx,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            '$countLabel in the last 90 days.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onyx,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            isOwnProfile
                ? 'Late cancellations and no-shows in the last 90 days trigger this notice. '
                    'It clears automatically once the 90-day window passes.'
                : 'This player has had recent late or same-day cancellations. '
                    'This notice clears automatically once the 90-day window passes.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.slate,
            ),
          ),
          SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
