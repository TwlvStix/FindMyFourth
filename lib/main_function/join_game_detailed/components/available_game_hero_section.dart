import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_expandable_text.dart';
import '/core/widgets/app_icon.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/navigation/nav_extensions.dart';
import '/models/game.dart';
import '/utils/availability_text_helper.dart';
import '/providers/profile_provider.dart';
import 'package:provider/provider.dart';

/// Hero section for available games (join_game_detailed screen)
/// Similar to PremiumHeroSection but without status badge and Message Group button.
/// Host name is tappable to navigate to their profile.
class AvailableGameHeroSection extends StatefulWidget {
  const AvailableGameHeroSection({
    super.key,
    required this.game,
  });

  final Game game;

  @override
  State<AvailableGameHeroSection> createState() =>
      _AvailableGameHeroSectionState();
}

class _AvailableGameHeroSectionState extends State<AvailableGameHeroSection> {
  bool _isDateExpanded = false;

  Game get game => widget.game;
  bool get isFlexible => game.isFlexible;
  bool get hasCourse => game.coursePlay.isNotEmpty;

  int get spotsLeft =>
      game.maxPlayers - (game.joinedPlayers.length + game.guestPlayers.length);
  bool get isFull => spotsLeft <= 0;

  String get _weekHint => getWeekHintOnly(game);

  String get _timeSummary =>
      formatTimeOfDay(game.flexibleTimeOfDay, joiner: ' & ') ?? 'Anytime';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navy.withValues(alpha: 0.4),
            AppColors.navyDark.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
        border: Border.all(
          color: AppColors.navyLight,
          width: 1,
        ),
        boxShadow: [AppElevation.xl],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course row with host info
          _buildCourseRow(),
          SizedBox(height: AppSpacing.md),
          // Date/time row
          _buildDateTimeRow(),
        ],
      ),
    );
  }

  void _handleHostTap() {
    final hostRef = game.userRef;
    if (hostRef == null) return;
    HapticFeedback.lightImpact();
    context.pushProfileUser(userRef: hostRef);
  }

  Widget _buildCourseRow() {
    return Row(
      children: [
        // Circular pin icon container
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navyLight, AppColors.navy],
            ),
            shape: BoxShape.circle,
            boxShadow: [AppElevation.md],
          ),
          child: Center(
            child: AppIcon(
              icon: AppPhosphorIcons.course,
              color: AppColors.gold,
              size: AppIconSize.md,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppExpandableText(
                text: hasCourse ? game.coursePlay : 'Course TBD',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
              ),
              Text(
                hasCourse ? game.nameGame : 'Location pending confirmation',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSpacing.xs),
              // Hosted by [Name] with chevron - tappable
              Selector<ProfileProvider, String?>(
                selector: (_, provider) => game.userRef != null
                    ? provider.getCachedProfile(game.userRef!.id)?.displayName
                    : null,
                builder: (context, hostName, _) {
                  final displayName = hostName ?? 'Host';
                  return GestureDetector(
                    onTap: _handleHostTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hosted by $displayName',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: AppSpacing.xxs),
                        AppIcon(
                          icon: AppPhosphorIcons.chevronRight,
                          size: AppIconSize.xs,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeRow() {
    if (isFlexible) {
      return _buildFlexibleDateRow();
    }
    return _buildFixedDateRow();
  }

  Widget _buildFlexibleDateRow() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isDateExpanded = !_isDateExpanded;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.navy.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Calendar icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.navyLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: Center(
                    child: AppIcon(
                      icon: AppPhosphorIcons.calendarCheck,
                      color: AppColors.textSecondary,
                      size: AppIconSize.button,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                // Week + time text
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _weekHint,
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: '  ·  $_timeSummary',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // SPOTS badge
                _buildSpotsBadge(),
                SizedBox(width: AppSpacing.xs),
                // Chevron
                AnimatedRotation(
                  duration: ReducedMotionService.adjust(MotionTokens.routeEnter),
                  curve: MotionTokens.curveEnter,
                  turns: _isDateExpanded ? 0.5 : 0.0,
                  child: AppIcon(
                    icon: AppPhosphorIcons.chevronDown,
                    size: AppIconSize.sm,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            // Expanded details
            _buildExpandedDateDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedDateDetails() {
    return AnimatedSize(
      duration: ReducedMotionService.adjust(MotionTokens.routeEnter),
      curve: MotionTokens.curveEnter,
      child: _isDateExpanded
          ? Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: Column(
                children: [
                  Divider(
                    color: AppColors.navyLight.withValues(alpha: 0.3),
                    height: 1,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  _buildDetailGrid(),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildDetailGrid() {
    final dateRange = _getDateRangeValue();
    final days = _getDaysDetailValue();
    final time = _getTimeDetailValue();
    final group = _getGroupValue();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailColumn('DATES', dateRange),
        _buildDetailColumn('DAYS', days),
        _buildDetailColumn('TIME', time),
        _buildDetailColumn('GROUP', group),
      ],
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelMicro.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getDateRangeValue() {
    if (game.flexibleStartDate != null && game.flexibleEndDate != null) {
      final start = game.flexibleStartDate!;
      final end = game.flexibleEndDate!;
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[start.month - 1]} ${start.day} - ${months[end.month - 1]} ${end.day}';
    }
    return '—';
  }

  String _getDaysDetailValue() {
    final days = game.flexibleDays;
    if (days == null || days.isEmpty) return 'Any Day';
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final sorted = days.toList()..sort();
    return sorted.map((d) => dayNames[d]).join(', ');
  }

  String _getTimeDetailValue() =>
      formatTimeOfDay(game.flexibleTimeOfDay) ?? 'Anytime';

  String _getGroupValue() {
    final joined = game.joinedPlayers.length + game.guestPlayers.length;
    return '$joined of ${game.maxPlayers}\njoined';
  }

  Widget _buildFixedDateRow() {
    final date = game.date;
    String dateStr = 'Date TBD';
    String timeStr = '';

    if (date != null) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      dateStr = '${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}';
      final hour = date.hour;
      final minute = date.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      timeStr = '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          // Calendar icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.navyLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Center(
              child: AppIcon(
                icon: AppPhosphorIcons.calendarCheck,
                color: AppColors.textSecondary,
                size: AppIconSize.button,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          // Date + time text
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: dateStr,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (timeStr.isNotEmpty)
                    TextSpan(
                      text: '  ·  $timeStr',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // SPOTS badge
          _buildSpotsBadge(),
        ],
      ),
    );
  }

  Widget _buildSpotsBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isFull
            ? AppColors.gold.withValues(alpha: 0.15)
            : AppColors.navyLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: isFull
              ? AppColors.gold.withValues(alpha: 0.4)
              : AppColors.glassBorder,
        ),
      ),
      child: Text(
        isFull ? 'FULL' : '$spotsLeft SPOTS',
        style: AppTypography.labelSmall.copyWith(
          color: isFull ? AppColors.gold : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
