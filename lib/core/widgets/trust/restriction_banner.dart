import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/backend/schema/player_standing.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RestrictionBanner
// ─────────────────────────────────────────────────────────────────────────────

/// Prominent banner shown when a player has an active account restriction.
///
/// Rendered at the top of:
///   - YourStandingScreen
///   - Games tab (GamesListWidget)
///   - Game creation flow
///   - Join game flow
///
/// Includes a "View your standing →" footer for all types except suspended,
/// which instead shows a "Contact Support" button.
class RestrictionBanner extends StatelessWidget {
  const RestrictionBanner({
    super.key,
    required this.restriction,
    this.onViewStanding,
  });

  final Restriction restriction;

  /// Called when the user taps "View your standing →". Typically:
  ///   context.push('/yourStanding')
  final VoidCallback? onViewStanding;

  @override
  Widget build(BuildContext context) {
    final config = _configForType(restriction.type);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border(
          left: BorderSide(color: config.accentColor, width: 4),
        ),
        boxShadow: [AppElevation.md],
      ),
      padding: EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(config.icon, color: config.accentColor, size: AppIconSize.md),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.title,
                      style: AppTypography.titleSmall.copyWith(
                        fontFamily: AppTypography.displayFamily,
                        color: AppColors.onyx,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      config.body(restriction),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (restriction.type == RestrictionType.suspended) ...[
            SizedBox(height: AppSpacing.md),
            AppButtonEnhanced(
              text: 'Contact Support',
              variant: AppButtonVariant.secondary,
              onPressed: () {
                // Launch support email or URL — handled by caller if needed
              },
            ),
          ] else if (onViewStanding != null) ...[
            SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: onViewStanding,
              child: Text(
                'View your standing →',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static _RestrictionConfig _configForType(RestrictionType type) {
    switch (type) {
      case RestrictionType.cooldown24h:
        return _RestrictionConfig(
          accentColor: AppColors.goldLight,
          icon: Icons.hourglass_top_rounded,
          title: '24-Hour Cooldown',
          body: (r) => r.endsAt != null
              ? 'You can join games again after ${_formatTime(r.endsAt!)}.'
              : 'You are in a 24-hour cooldown period.',
        );
      case RestrictionType.restricted7d:
        return _RestrictionConfig(
          accentColor: AppColors.error,
          icon: Icons.pause_circle_outline_rounded,
          title: '7-Day Restriction',
          body: (r) => r.endsAt != null
              ? "You can't join or create games until ${_formatDate(r.endsAt!)}.\n"
                  'Show up for your next 5 rounds to rebuild your standing.'
              : "You're in a 7-day restriction period.",
        );
      case RestrictionType.restricted30d:
        return _RestrictionConfig(
          accentColor: AppColors.error,
          icon: Icons.block_rounded,
          title: '30-Day Restriction',
          body: (r) => r.endsAt != null
              ? 'Your account is restricted until ${_formatDate(r.endsAt!)} and has been flagged for review.'
              : 'Your account is restricted and has been flagged for review.',
        );
      case RestrictionType.suspended:
        return _RestrictionConfig(
          accentColor: AppColors.error,
          icon: Icons.gpp_bad_rounded,
          title: 'Account Suspended',
          body: (_) =>
              'Your account is under review. Contact support for reinstatement.',
        );
    }
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month]} ${dt.day} at $h:$m';
  }

  static String _formatDate(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ComebackBanner
// ─────────────────────────────────────────────────────────────────────────────

/// Welcome-back card shown once after a restriction ends.
///
/// Dismissible. Dismissal is persisted in SharedPreferences using the
/// key pattern: `'comeback_banner_dismissed_<uid>'`.
///
/// Usage:
///   ComebackBanner(userId: currentUserUid)
class ComebackBanner extends StatefulWidget {
  const ComebackBanner({super.key, required this.userId});

  final String userId;

  @override
  State<ComebackBanner> createState() => _ComebackBannerState();
}

class _ComebackBannerState extends State<ComebackBanner> {
  bool _dismissed = false;
  bool _loaded = false;

  String get _prefKey => 'comeback_banner_dismissed_${widget.userId}';

  @override
  void initState() {
    super.initState();
    _checkDismissed();
  }

  Future<void> _checkDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _dismissed = prefs.getBool(_prefKey) ?? false;
        _loaded = true;
      });
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _dismissed) return const SizedBox.shrink();

    return AppCard(
      variant: AppCardVariant.gradientAccent,
      padding: EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Welcome back!',
                  style: AppTypography.titleSmall.copyWith(
                    fontFamily: AppTypography.displayFamily,
                    color: AppColors.onyx,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _dismiss,
                child: Icon(
                  Icons.close_rounded,
                  size: AppIconSize.button,
                  color: AppColors.stone,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Your next 5 rounds will rebuild your standing. '
            "Show up and your strike history will start to fade.",
            style: AppTypography.bodySmall.copyWith(color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal config
// ─────────────────────────────────────────────────────────────────────────────

class _RestrictionConfig {
  const _RestrictionConfig({
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.body,
  });

  final Color accentColor;
  final IconData icon;
  final String title;
  final String Function(Restriction) body;
}
