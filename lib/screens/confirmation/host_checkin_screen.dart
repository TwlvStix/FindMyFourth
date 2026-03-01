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
import '/core/widgets/app_avatar.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/services/trust_flow_service.dart';

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
  final _trustFlowService = TrustFlowService();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String? _successMessage;

  String _courseName = '';

  // All participants (app users + guests)
  final List<_ParticipantEntry> _participants = [];

  // Attendance map: uid or guestName → isPresent
  final Map<String, bool> _attendance = {};

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    try {
      final data = await _trustFlowService.loadHostCheckinParticipants(
        gameRef: widget.gameRef,
      );
      final entries = data.participants
          .map(
            (participant) => _ParticipantEntry(
              key: participant.key,
              displayName: participant.displayName,
              photoUrl: participant.photoUrl,
              isGuest: participant.isGuest,
              role: participant.role,
            ),
          )
          .toList(growable: false);

      if (mounted) {
        updateState(this, () {
          _courseName = data.courseName;
          _participants.addAll(entries);
          _attendance.addAll(data.defaultAttendance);
          _loading = false;
        });
      }
    } on StateError catch (e) {
      final code = e.message;
      if (mounted) {
        updateState(this, () {
          _error = code == 'game_not_found'
              ? 'Game not found.'
              : 'Failed to load participants. Please try again.';
          _loading = false;
        });
      }
    } catch (e) {
      AppLog.d('HostCheckinScreen load error: $e');
      if (mounted) {
        updateState(this, () {
          _error = 'Failed to load participants. Please try again.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    updateState(this, () {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await makeCloudCall('submitHostCheckin', {
        'gameId': widget.gameRef.id,
        'attendance': Map<String, dynamic>.from(
          _attendance.map((k, v) => MapEntry(k, v)),
        ),
      });

      if (result['success'] == true) {
        if (mounted) {
          updateState(this, () {
            _submitting = false;
            _successMessage = 'Attendance confirmed. Thanks!';
          });
        }
      } else {
        if (mounted)
          updateState(this, () {
            _submitting = false;
            _error = 'Submission failed. Please try again.';
          });
      }
    } catch (e) {
      AppLog.d('HostCheckinScreen submit error: $e');
      if (mounted)
        updateState(this, () {
          _submitting = false;
          _error = 'Something went wrong. Please try again.';
        });
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

    if (_successMessage != null) {
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
                    _successMessage!,
                    style: AppTypography.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  AppButtonEnhanced(
                    onPressed: () => Navigator.of(context).pop(),
                    text: 'Done',
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
        title: Text(
          'Confirm Attendance',
          style: AppTypography.titleMedium,
        ),
        centerTitle: true,
        leading: IconButton(
          icon:
              PhosphorIcon(AppPhosphorIcons.back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.only(
                  top: AppSpacing.md,
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                  bottom: AppSpacing.sm),
              child: Text(
                'Who played at $_courseName today?',
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            if (_error != null)
              Padding(
                padding: AppSpacing.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                child: Text(
                  _error!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: AppSpacing.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                itemCount: _participants.length,
                itemBuilder: (context, i) {
                  final p = _participants[i];
                  final isPresent = _attendance[p.key] ?? true;
                  return _ParticipantRow(
                    participant: p,
                    isPresent: isPresent,
                    onToggle: (val) {
                      updateState(this, () {
                        _attendance[p.key] = val;
                      });
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: AppSpacing.only(
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                  bottom: AppSpacing.xxl,
                  top: AppSpacing.md),
              child: AppButtonEnhanced(
                onPressed: _submitting ? null : _submit,
                text: _submitting ? 'Submitting...' : 'Confirm Attendance',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantEntry {
  const _ParticipantEntry({
    required this.key,
    required this.displayName,
    required this.photoUrl,
    required this.isGuest,
    required this.role,
  });

  final String key;
  final String displayName;
  final String photoUrl;
  final bool isGuest;
  final String role;
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.participant,
    required this.isPresent,
    required this.onToggle,
  });

  final _ParticipantEntry participant;
  final bool isPresent;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: AppSpacing.only(bottom: AppSpacing.sm),
      padding: AppSpacing.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: isPresent
              ? AppColors.green.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          _buildAvatar(),
          SizedBox(width: AppSpacing.md),
          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(participant.displayName, style: AppTypography.bodyLarge),
                if (participant.role == 'host')
                  Text('Host',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.gold,
                      ))
                else if (participant.isGuest)
                  Text('Guest',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      )),
              ],
            ),
          ),
          // Present / No-show toggle
          _AttendanceToggle(
            isPresent: isPresent,
            onToggle: onToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = participant.displayName
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase())
        .take(2)
        .join();
    return AppAvatar(
      imageUrl: participant.photoUrl.isNotEmpty ? participant.photoUrl : null,
      initials: initials.isEmpty ? '?' : initials,
      size: AppAvatarSize.medium,
    );
  }
}

class _AttendanceToggle extends StatelessWidget {
  const _AttendanceToggle({required this.isPresent, required this.onToggle});

  final bool isPresent;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToggleChip(
          label: 'Present',
          selected: isPresent,
          selectedColor: AppColors.green,
          onTap: () => onToggle(true),
        ),
        SizedBox(width: AppSpacing.sm),
        _ToggleChip(
          label: 'No-show',
          selected: !isPresent,
          selectedColor: AppColors.error,
          onTap: () => onToggle(false),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm - 2, vertical: AppSpacing.xs - 2),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          border: Border.all(
            color: selected
                ? selectedColor
                : AppColors.textMuted.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
