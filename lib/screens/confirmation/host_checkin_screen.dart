import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/utils/state_update.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/motion/animated_entrance.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/main_function/games_joined/games_joined_widget.dart';
import 'components/checkin_participant_entry.dart';
import 'components/checkin_participant_row.dart';
import 'components/checkin_status_view.dart';
import 'controllers/host_checkin_controller.dart';

/// HostCheckinScreen
///
/// Allows the game host to confirm attendance for all participants
/// (app users and guests) after the round. Opened via push notification
/// at T+5h or T+24h (reminder).
///
/// Route name: 'HostCheckin'
/// Parameters: gameRef (DocumentReference)
class HostCheckinScreen extends StatefulWidget {
  const HostCheckinScreen({super.key, required this.gameRef});

  final DocumentReference gameRef;

  static const String routeName = 'HostCheckin';
  static const String routePath = '/hostCheckin';

  @override
  State<HostCheckinScreen> createState() => _HostCheckinScreenState();
}

class _HostCheckinScreenState extends State<HostCheckinScreen> {
  final _controller = HostCheckinController();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String? _successMessage;
  bool _alreadyCompleted = false;
  bool _windowClosed = false;

  String _courseName = '';
  final List<CheckinParticipantEntry> _participants = [];
  final Map<String, bool> _attendance = {};

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  void _navigateToMyGames({String? message}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    context.go(GamesJoinedWidget.routePath);
    if (message != null) {
      messenger.showSnackBar(SnackBar(
        content: Text(message,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.success,
        duration: const Duration(milliseconds: 3000),
      ));
    }
  }

  Future<void> _loadParticipants() async {
    final result =
        await _controller.loadParticipants(widget.gameRef);
    if (!mounted) return;

    switch (result) {
      case HostCheckinAlreadyCompleted():
        updateState(this, () {
          _alreadyCompleted = true;
          _loading = false;
        });
      case HostCheckinWindowClosed():
        updateState(this, () {
          _windowClosed = true;
          _loading = false;
        });
      case HostCheckinLoadError(:final message):
        updateState(this, () {
          _error = message;
          _loading = false;
        });
      case HostCheckinReady(
          :final courseName,
          :final participants,
          :final defaultAttendance,
        ):
        updateState(this, () {
          _courseName = courseName;
          _participants.addAll(participants);
          _attendance.addAll(defaultAttendance);
          _loading = false;
        });
    }
  }

  Future<void> _submit() async {
    updateState(this, () {
      _submitting = true;
      _error = null;
    });

    final result = await _controller.submitAttendance(
      gameId: widget.gameRef.id,
      attendance: _attendance,
    );
    if (!mounted) return;

    switch (result) {
      case HostCheckinSubmitSuccess():
        updateState(this, () {
          _submitting = false;
          _successMessage = 'Attendance confirmed. Thanks!';
        });
      case HostCheckinSubmitError(:final message):
        updateState(this, () {
          _submitting = false;
          _error = message;
        });
    }
  }

  void _retryLoad() {
    updateState(this, () {
      _error = null;
      _loading = true;
      _participants.clear();
      _attendance.clear();
    });
    _loadParticipants();
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

    if (_alreadyCompleted) {
      return CheckinStatusView(
        icon: AppPhosphorIcons.successFill,
        iconColor: AppColors.green,
        message: 'Attendance already confirmed.',
        onDone: () => _navigateToMyGames(),
      );
    }

    if (_windowClosed) {
      return CheckinStatusView(
        icon: AppPhosphorIcons.clock,
        iconColor: AppColors.textMuted,
        message: 'This confirmation window has closed.',
        onDone: () => _navigateToMyGames(),
      );
    }

    if (_successMessage != null) {
      return CheckinStatusView(
        icon: AppPhosphorIcons.successFill,
        iconColor: AppColors.green,
        message: _successMessage!,
        onDone: () => _navigateToMyGames(),
      );
    }

    return _buildForm();
  }

  Widget _buildForm() {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        title: Text('Confirm Attendance', style: AppTypography.titleMedium),
        centerTitle: true,
        leading: IconButton(
          icon: AppIcon(
            icon: AppPhosphorIcons.back,
            color: AppColors.textPrimary,
            size: AppIconSize.md,
          ),
          onPressed: () => _navigateToMyGames(),
          tooltip: 'Back to My Games',
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  _buildHeader(),
                  SizedBox(height: AppSpacing.xxxl),
                  Padding(
                    padding: AppSpacing.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: Column(
                      children: [
                        for (int i = 0;
                            i < _participants.length;
                            i++) ...[
                          if (i > 0) SizedBox(height: AppSpacing.xxs),
                          _buildParticipantRow(i),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(flex: 1),
                  if (_error != null)
                    Padding(
                      padding: AppSpacing.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.sm),
                      child: Column(
                        children: [
                          Text(
                            _error!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppSpacing.sm),
                          AppButtonEnhanced(
                            text: 'Try again',
                            variant: AppButtonVariant.secondary,
                            size: AppButtonSize.small,
                            onPressed: _retryLoad,
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: AppSpacing.only(
                        left: AppSpacing.xl,
                        right: AppSpacing.xl,
                        bottom: AppSpacing.xxl,
                        top: AppSpacing.lg),
                    child: AppButtonEnhanced(
                      onPressed: _submitting ? null : _submit,
                      text: 'Confirm Attendance',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      isLoading: _submitting,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantRow(int i) {
    final p = _participants[i];
    final isPresent = _attendance[p.key] ?? true;

    return AnimatedEntrance(
      animationIndex: i,
      child: CheckinParticipantRow(
        participant: p,
        isPresent: isPresent,
        onToggle: (val) {
          updateState(this, () {
            _attendance[p.key] = val;
          });
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: AppSpacing.only(
        top: AppSpacing.xxl,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: AppSpacing.xl,
      ),
      child: Semantics(
        header: true,
        label: 'Confirm attendance for $_courseName. Who played today?',
        child: Column(
          children: [
            AppIcon(
              icon: AppPhosphorIcons.golfCourse,
              color: AppColors.textSecondary,
              size: AppIconSize.xxl,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              _courseName,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Who played today?',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
