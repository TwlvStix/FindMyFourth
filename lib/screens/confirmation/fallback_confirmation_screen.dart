import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/cloud_functions/cloud_functions.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_button_enhanced.dart';

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
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  bool? _answered; // true = yes, false = no, null = not answered

  String _courseName = '';

  @override
  void initState() {
    super.initState();
    _loadCourseName();
  }

  Future<void> _loadCourseName() async {
    try {
      final gameSnap = await widget.gameRef.get();
      if (gameSnap.exists) {
        final data = gameSnap.data() as Map<String, dynamic>;
        _courseName = (data['course_play'] as String?) ?? 'your course';
      }
    } catch (e) {
      AppLog.d('FallbackConfirmationScreen load error: $e');
    }
    if (mounted) setState(() { _loading = false; });
  }

  Future<void> _submit(bool didPlay) async {
    setState(() { _submitting = true; _error = null; });

    try {
      final result = await makeCloudCall('submitFallbackConfirmation', {
        'gameId': widget.gameRef.id,
        'didPlay': didPlay,
      });

      if (result['success'] == true) {
        if (mounted) setState(() { _submitting = false; _answered = didPlay; });
      } else {
        if (mounted) setState(() { _submitting = false; _error = 'Submission failed. Please try again.'; });
      }
    } catch (e) {
      AppLog.d('FallbackConfirmationScreen submit error: $e');
      if (mounted) setState(() { _submitting = false; _error = 'Something went wrong. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.navyDarkBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Post-answer confirmation view
    if (_answered != null) {
      return Scaffold(
        backgroundColor: AppColors.navyDarkBackground,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: AppSpacing.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _answered! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: _answered! ? AppColors.navyDark : AppColors.navyText,
                    size: 64,
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
                    variant: AppButtonVariant.gradient,
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
      backgroundColor: AppColors.navyDarkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.navyDarkBackground,
        elevation: 0,
        title: Text('Round Check-in', style: AppTypography.titleMedium),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.navyDarkText),
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
              Icon(
                Icons.golf_course_rounded,
                color: AppColors.navyDark,
                size: 56,
              ),
              SizedBox(height: AppSpacing.xl),
              Text(
                'Did you play at $_courseName today?',
                style: AppTypography.headlineMedium ?? AppTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                "The host hasn't confirmed the round yet. Let us know if it happened.",
                style: AppTypography.bodyMedium.override(
                  font: const TextStyle(fontFamily: 'Manrope'),
                  color: AppColors.navyText,
                ),
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: AppTypography.bodySmall.override(
                    font: const TextStyle(fontFamily: 'Manrope'),
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
                      icon: Icons.check_rounded,
                      color: AppColors.navyDark,
                      onTap: _submitting ? null : () => _submit(true),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _YesNoButton(
                      label: 'No',
                      icon: Icons.close_rounded,
                      color: AppColors.navyText,
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
  final IconData icon;
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
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha:0.5), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTypography.titleMedium.override(
                  font: const TextStyle(fontFamily: 'Manrope'),
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
