import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/fairway_background.dart';
import 'components/badge_progress_card.dart';
import 'components/strikes_section.dart';
import 'components/rates_section.dart';
import 'components/next_badge_section.dart';

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
        backgroundColor: AppColors.transparent,
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
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: AppIcon(
                icon: AppPhosphorIcons.back,
                color: AppColors.pure,
                size: AppIconSize.button,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Text(
            'Your Standing',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.pure,
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
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
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
            AppIcon(
              icon: AppPhosphorIcons.error,
              color: AppColors.glassTextTertiary,
              size: AppIconSize.xxl,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.glassTextSecondary),
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
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              ),
              child: AppIcon(
                icon: AppPhosphorIcons.golfCourse,
                color: AppColors.pure,
                size: AppIconSize.lg,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'No activity yet',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.pure,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Once you play your first verified round, your standing details will appear here — including your show-up rate, badge progress, and strike history.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.glassTextSecondary,
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
          BadgeProgressCard(standing: s),
          SizedBox(height: AppSpacing.md),
          StrikesSection(standing: s),
          SizedBox(height: AppSpacing.md),
          RatesSection(standing: s),
          SizedBox(height: AppSpacing.md),
          NextBadgeSection(standing: s),
        ],
      ),
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
          color: AppColors.green,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Text(
          'Try Again',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
