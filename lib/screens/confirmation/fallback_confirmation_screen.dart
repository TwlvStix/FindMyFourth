import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/utils/state_update.dart';
import 'package:flutter/material.dart';

import '/backend/cloud_functions/cloud_functions.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/services/trust_flow_service.dart';
import 'components/fallback_header.dart';
import 'components/fallback_status_view.dart';
import 'components/fallback_toggle.dart';

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
    extends State<FallbackConfirmationScreen>
    with SingleTickerProviderStateMixin {
  final _trustFlowService = TrustFlowService();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  bool _selection = true; // toggle state: true = yes, false = no
  bool _submitted = false; // post-submit
  bool _alreadyCompleted = false;
  bool _windowClosed = false;

  String _courseName = '';

  // Entrance animation
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _loadCourseName();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
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
    if (mounted) {
      updateState(this, () { _loading = false; });
      _entranceController.forward();
    }
  }

  Future<void> _submit() async {
    updateState(this, () { _submitting = true; _error = null; });

    try {
      final result = await makeCloudCall('submitFallbackConfirmation', {
        'gameId': widget.gameRef.id,
        'didPlay': _selection,
      });

      if (result['success'] == true) {
        if (mounted) updateState(this, () { _submitting = false; _submitted = true; });
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
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.green,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    void pop() => Navigator.of(context).pop();

    if (_alreadyCompleted) {
      return FallbackStatusView(
        icon: AppPhosphorIcons.successFill,
        iconColor: AppColors.green,
        message: 'Already confirmed for this round.',
        onDone: pop,
      );
    }

    if (_windowClosed) {
      return FallbackStatusView(
        icon: AppPhosphorIcons.clock,
        iconColor: AppColors.textMuted,
        message: 'This confirmation window has closed.',
        onDone: pop,
      );
    }

    if (_submitted) {
      return FallbackStatusView(
        icon: _selection ? AppPhosphorIcons.successFill : AppPhosphorIcons.cancelFill,
        iconColor: _selection ? AppColors.green : AppColors.textSecondary,
        message: _selection ? 'Got it — glad you played!' : 'Thanks for letting us know.',
        onDone: pop,
      );
    }

    return _buildFormView();
  }

  Widget _buildFormView() {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        title: Text('Round Check-in', style: AppTypography.titleMedium),
        centerTitle: true,
        leading: IconButton(
          icon: AppIcon(icon: AppPhosphorIcons.back, color: AppColors.textPrimary, size: AppIconSize.md),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(flex: 1),
                      FallbackHeader(courseName: _courseName),
                      SizedBox(height: AppSpacing.xxxl),
                      Center(child: AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) => Opacity(
                          opacity: _fadeAnimation.value,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: child,
                          ),
                        ),
                        child: FallbackToggle(
                          selection: _selection,
                          onSelect: (val) {
                            updateState(this, () {
                              _selection = val;
                              _error = null;
                            });
                          },
                        ),
                      )),
                      const Spacer(flex: 1),
                      if (_error != null)
                        Padding(
                          padding: AppSpacing.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.sm),
                          child: Text(
                            _error!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Center(
                        child: Padding(
                          padding: AppSpacing.only(
                              left: AppSpacing.xl,
                              right: AppSpacing.xl,
                              bottom: AppSpacing.xxl,
                              top: AppSpacing.lg),
                          child: AppButtonEnhanced(
                            onPressed: _submitting ? null : _submit,
                            text: _submitting ? 'Submitting...' : 'Confirm',
                            variant: AppButtonVariant.primary,
                            size: AppButtonSize.large,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

}
