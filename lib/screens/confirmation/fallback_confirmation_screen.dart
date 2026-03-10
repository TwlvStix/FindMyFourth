import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/utils/state_update.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/backend/cloud_functions/cloud_functions.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/services/trust_flow_service.dart';

/// FallbackConfirmationScreen
///
/// Shown to all app users at T+24h if the host has not confirmed attendance.
/// A simple Yes/No question: "Did you play at [Course] today?"
///
/// If Yes, adds the user to round_records.confirmed_player_refs.
/// If No, records nothing.
///
/// Route name: 'FallbackConfirmation'
/// Parameters: gameRef (DocumentReference)
class FallbackConfirmationScreen extends StatefulWidget {
  const FallbackConfirmationScreen({super.key, required this.gameRef});

  final DocumentReference gameRef;

  static const String routeName = 'FallbackConfirmation';
  static const String routePath = '/fallbackConfirmation';

  @override
  State<FallbackConfirmationScreen> createState() =>
      _FallbackConfirmationScreenState();
}

class _FallbackConfirmationScreenState
    extends State<FallbackConfirmationScreen> {
  final _trustFlowService = TrustFlowService();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  bool? _answered; // true = yes, false = no, null = not answered
  bool _alreadyCompleted = false;
  bool _windowClosed = false;

  String _courseName = '';

  @override
  void initState() {
    super.initState();
    _loadCourseName();
  }

  Future<void> _loadCourseName() async {
    try {
      // Check if already submitted or window closed before showing the form.
      final status = await _trustFlowService.checkFallbackStatus(
        gameRef: widget.gameRef,
      );
      if (!mounted) return;
      if (status == ConfirmationStatus.completed) {
        updateState(this, () {
          _alreadyCompleted = true;
          _loading = false;
        });
        return;
      }
      if (status == ConfirmationStatus.windowClosed) {
        updateState(this, () {
          _windowClosed = true;
          _loading = false;
        });
        return;
      }

      final gameSnap = await widget.gameRef.get();
      if (gameSnap.exists) {
        final data = gameSnap.data() as Map<String, dynamic>;
        _courseName = (data['course_play'] as String?) ?? 'your course';
      }
    } catch (e) {
      AppLog.d('FallbackConfirmationScreen load error: $e');
    }
    if (mounted) updateState(this, () { _loading = false; });
  }

  Future<void> _submit(bool didPlay) async {
    updateState(this, () { _submitting = true; _error = null; });

    try {
      final result = await makeCloudCall('submitFallbackConfirmation', {
        'gameId': widget.gameRef.id,
        'didPlay': didPlay,
      });

      if (result['success'] == true) {
        if (mounted) updateState(this, () { _submitting = false; _answered = didPlay; });
      } else {
        if (mounted) updateState(this, () { _submitting = false; _error = 'Submission failed. Please try again.'; });
      }
    } catch (e) {
      AppLog.d('FallbackConfirmationScreen submit error: $e');
      if (mounted) updateState(this, () { _submitting = false; _error = 'Something went wrong. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.navyDark,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_alreadyCompleted) {
      return Scaffold(
        backgroundColor: AppColors.navyDark,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: AppSpacing.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(AppPhosphorIcons.successFill,
                      color: AppColors.green, size: AppIconSize.hero),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Already confirmed for this round.',
                    style: AppTypography.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  AppButtonEnhanced(
                    onPressed: () => Navigator.of(context).pop(),
                    text: 'Close',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_windowClosed) {
      return Scaffold(
        backgroundColor: AppColors.navyDark,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: AppSpacing.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(AppPhosphorIcons.clock,
                      color: AppColors.textMuted, size: AppIconSize.hero),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'This confirmation window has closed.',
                    style: AppTypography.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  AppButtonEnhanced(
                    onPressed: () => Navigator.of(context).pop(),
                    text: 'Close',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Post-answer confirmation view
    if (_answered != null) {
      return Scaffold(
        backgroundColor: AppColors.navyDark,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: AppSpacing.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(
                    _answered! ? AppPhosphorIcons.successFill : AppPhosphorIcons.cancelFill,
                    color: _answered! ? AppColors.green : AppColors.textSecondary,
                    size: AppIconSize.hero,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    _answered!
                        ? 'Got it — glad you played!'
                        : 'Thanks for letting us know.',
                    style: AppTypography.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  AppButtonEnhanced(
                    onPressed: () => Navigator.of(context).pop(),
                    text: 'Close',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        title: Text('Round Check-in', style: AppTypography.titleMedium),
        centerTitle: true,
        leading: IconButton(
          icon: PhosphorIcon(AppPhosphorIcons.back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PhosphorIcon(
                AppPhosphorIcons.golfCourse,
                color: AppColors.green,
                size: AppIconSize.xxl,
              ),
              SizedBox(height: AppSpacing.xl),
              Text(
                'Did you play at $_courseName today?',
                style: AppTypography.headlineMediumSans,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                "The host hasn't confirmed the round yet. Let us know if it happened.",
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: AppSpacing.xxxl),
              Row(
                children: [
                  Expanded(
                    child: _YesNoButton(
                      label: 'Yes',
                      icon: AppPhosphorIcons.check,
                      color: AppColors.green,
                      onTap: _submitting ? null : () => _submit(true),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _YesNoButton(
                      label: 'No',
                      icon: AppPhosphorIcons.close,
                      color: AppColors.textSecondary,
                      onTap: _submitting ? null : () => _submit(false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YesNoButton extends StatelessWidget {
  const _YesNoButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final PhosphorIconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg - 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.12),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(color: color.withValues(alpha:0.5), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(icon, color: color, size: AppIconSize.lg),
              AppSpacing.verticalXsBox,
              Text(
                label,
                style: AppTypography.titleMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
