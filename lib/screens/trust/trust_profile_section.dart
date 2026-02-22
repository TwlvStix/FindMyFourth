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
          // Unified trust card (badge + progress bar + stats)
          _buildUnifiedTrustCard(),
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
              colors: [AppColors.navy, AppColors.navyDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha:0.3),
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

  /// Badge row for use inside the unified card (no external container decoration)
  /// Includes joined year on the right side
  Widget _buildBadgeRowUnified() {
    final info = _badgeInfo(user.badgeLevel);
    final joinYear = user.createdTime != null
        ? '${user.createdTime!.year}'
        : '—';

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [info.gradientStart, info.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          // Shine overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  colors: [
                    AppColors.glassSurface,
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
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.glassTextTertiary,
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
                        color: AppColors.glassTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Joined year badge on the right
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.glassBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      joinYear,
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'JOINED',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.glassTextSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
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

  // ── Unified Trust Card (badge + progress + stats) ──────────────────────

  Widget _buildUnifiedTrustCard() {
    final isNewMember = user.badgeLevel == 'new' || user.badgeLevel.isEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cloud),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlayDark,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Badge bar (full width, gradient background, rounded top corners, includes joined year)
          _buildBadgeRowUnified(),
          // Progress bar (only for new members)
          if (isNewMember) _buildJourneyProgressBar(),
          // Stats grid (Rounds, Co-Players, Hosted)
          Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatTileCompact(
                    icon: Icons.check_circle_outline_rounded,
                    iconGradient: [AppColors.success, AppColors.navyLight],
                    value: '${user.verifiedRoundCount}',
                    label: 'ROUNDS',
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _buildStatTileCompact(
                    icon: Icons.group_outlined,
                    iconGradient: [AppColors.navyLight, AppColors.navy],
                    value: '${user.uniqueCoPlayers.length}',
                    label: 'CO-PLAYERS',
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _buildStatTileCompact(
                    icon: Icons.sports_golf_outlined,
                    iconGradient: [AppColors.gold, AppColors.goldLight],
                    value: '${user.gamesHosted}',
                    label: 'HOSTED',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact stat tile for use inside unified card
  Widget _buildStatTileCompact({
    required IconData icon,
    required List<Color> iconGradient,
    required String value,
    required String label,
    bool isText = false,
  }) {
    // Show em dash for zero values (premium empty state)
    final isZero = value == '0';
    final displayValue = isZero ? '—' : value;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xxs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: iconGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: iconGradient[0].withValues(alpha:0.25),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            displayValue,
            style: isText
                ? AppTypography.labelSmall.copyWith(
                    color: AppColors.onyx,
                    fontWeight: FontWeight.w600,
                  )
                : isZero
                    ? AppTypography.monoMedium.copyWith(
                        color: AppColors.stone,
                        fontWeight: FontWeight.w300,
                      )
                    : AppTypography.monoMedium.copyWith(
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
              fontSize: 10,
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
        ? [AppColors.success, AppColors.navyLight]
        : rate >= 0.75
            ? [AppColors.warning, AppColors.goldLight]
            : [AppColors.error, AppColors.error];

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cloud),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlayDark,
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
                      color: color.withValues(alpha:0.25),
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
          color: AppColors.warning.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withValues(alpha:0.4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withValues(alpha:0.08),
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
                  colors: [AppColors.warning, AppColors.goldLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warning.withValues(alpha:0.25),
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

  // ── Journey progress bar (new members only) ─────────────────────────────

  Widget _buildJourneyProgressBar() {
    // Calculate progress based on verified rounds (0 = 8%, 5 = 50%, 10+ = 100%)
    final rounds = user.verifiedRoundCount;
    final progress = rounds <= 0
        ? 0.08
        : rounds >= 10
            ? 1.0
            : 0.08 + (rounds / 10) * 0.92;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          // Track bar with nodes
          SizedBox(
            height: 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background track
                Positioned(
                  left: 6,
                  right: 6,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cloud,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Progress fill
                Positioned(
                  left: 6,
                  right: 6,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: constraints.maxWidth * progress,
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.navy, AppColors.navyLight],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Nodes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // First Tee node (always active)
                    _buildProgressNode(isActive: true),
                    // 5 Rounds node
                    _buildProgressNode(isActive: rounds >= 5),
                    // Trusted node
                    _buildProgressNode(isActive: rounds >= 10),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          // Milestone labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'First Tee',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '5 Rounds',
                style: AppTypography.labelSmall.copyWith(
                  color: rounds >= 5 ? AppColors.navy : AppColors.stone,
                  fontWeight: rounds >= 5 ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              Text(
                'Trusted',
                style: AppTypography.labelSmall.copyWith(
                  color: rounds >= 10 ? AppColors.navy : AppColors.stone,
                  fontWeight: rounds >= 10 ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressNode({required bool isActive}) {
    return Container(
      width: isActive ? 12 : 10,
      height: isActive ? 12 : 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.navy : AppColors.cloud,
        border: Border.all(
          color: isActive ? Colors.white : AppColors.cloud,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha:0.4),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
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
          gradientStart: AppColors.navyDark,
          gradientEnd: AppColors.navy,
        );
      case 'starter':
        return (
          label: 'Starter',
          description: 'Trusted regular golfer',
          icon: Icons.flag_rounded,
          gradientStart: AppColors.navy,
          gradientEnd: AppColors.navyLight,
        );
      case 'regular':
        return (
          label: 'Regular',
          description: 'Established member',
          icon: Icons.sports_golf_rounded,
          gradientStart: AppColors.navyLight,
          gradientEnd: AppColors.gold,
        );
      case 'confirmed':
        return (
          label: 'Confirmed',
          description: 'Verified by the community',
          icon: Icons.verified_rounded,
          gradientStart: AppColors.gold,
          gradientEnd: AppColors.goldLight,
        );
      case 'new':
      default:
        return (
          label: 'First Tee',
          description: 'Your story begins here',
          icon: Icons.golf_course_rounded,
          gradientStart: AppColors.goldLight,
          gradientEnd: AppColors.error,
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
