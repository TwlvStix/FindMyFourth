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
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.fairway, AppColors.fairwayDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: AppColors.fairway.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(Icons.shield_rounded, color: Colors.white, size: 16),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          'Trust Profile',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.onyx,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Badge row ───────────────────────────────────────────────────────────

  Widget _buildBadgeRow() {
    final info = _badgeInfo(user.badgeLevel);
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [info.gradientStart, info.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: info.gradientStart.withOpacity(0.45),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Shine overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
                child: Icon(info.icon, color: Colors.white, size: 26),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.label,
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
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

    return Column(
      children: [
        // Row 1: Badge card (2/3) + Joined tile (1/3)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: _buildBadgeRow(),
              ),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                flex: 1,
                child: _buildStatTile(
                  icon: Icons.calendar_today_outlined,
                  iconGradient: [AppColors.sunsetPeach, AppColors.sunsetRose],
                  value: joinYear,
                  label: 'Joined',
                  isText: true,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        // Row 2: Rounds, Co-Players, Hosted
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                icon: Icons.check_circle_outline_rounded,
                iconGradient: [AppColors.success, AppColors.fairwayLight],
                value: '${user.verifiedRoundCount}',
                label: 'Rounds',
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildStatTile(
                icon: Icons.group_outlined,
                iconGradient: [AppColors.fairwayLight, AppColors.fairway],
                value: '${user.uniqueCoPlayers.length}',
                label: 'Co-Players',
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildStatTile(
                icon: Icons.sports_golf_outlined,
                iconGradient: [AppColors.sunsetGold, AppColors.sunsetPeach],
                value: '${user.gamesHosted}',
                label: 'Hosted',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required List<Color> iconGradient,
    required String value,
    required String label,
    bool isText = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cloud),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: iconGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: iconGradient[0].withOpacity(0.25),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          SizedBox(height: AppSpacing.xs),
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
    final gradientColors = rate >= 0.9
        ? [AppColors.success, AppColors.fairwayLight]
        : rate >= 0.75
            ? [AppColors.warning, AppColors.sunsetPeach]
            : [AppColors.error, AppColors.sunsetRose];

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cloud),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
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
                      '$denominator game${denominator == 1 ? "" : "s"} played',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.slate,
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
          SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: AppColors.cloud,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.warning, AppColors.sunsetPeach],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warning.withOpacity(0.25),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 20),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cancellation History',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.slate,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Tap for details',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.stone,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.stone,
              size: 20,
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
          icon: Icons.golf_course_rounded,
          gradientStart: AppColors.sunsetPeach,
          gradientEnd: AppColors.sunsetRose,
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
