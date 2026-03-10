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
import '/core/motion/motion_tokens.dart';
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

class _HostCheckinScreenState extends State<HostCheckinScreen>
    with TickerProviderStateMixin {
  final _trustFlowService = TrustFlowService();

  bool _loading = true;
  bool _loadCalled = false;
  bool _submitting = false;
  String? _error;
  String? _successMessage;

  String _courseName = '';

  // All participants (app users + guests)
  final List<_ParticipantEntry> _participants = [];

  // Attendance map: uid or guestName → isPresent
  final Map<String, bool> _attendance = {};

  // Staggered entrance animation
  late AnimationController _staggerController;
  final List<Animation<double>> _fadeAnimations = [];
  final List<Animation<Offset>> _slideAnimations = [];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (!_loadCalled) {
      _loadCalled = true;
      _loadParticipants();
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _buildStaggerAnimations() {
    _fadeAnimations.clear();
    _slideAnimations.clear();

    final itemCount =
        _participants.length.clamp(0, MotionTokens.staggerMaxItems);
    if (itemCount == 0) return;

    for (int i = 0; i < _participants.length; i++) {
      final staggerIndex = i.clamp(0, MotionTokens.staggerMaxItems - 1);
      final startFraction = (staggerIndex * 24) / 600;
      final endFraction = (startFraction + 0.4).clamp(0.0, 1.0);

      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(startFraction, endFraction,
                curve: MotionTokens.curveEnter),
          ),
        ),
      );

      _slideAnimations.add(
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(startFraction, endFraction,
                curve: MotionTokens.curveEnter),
          ),
        ),
      );
    }
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
        _buildStaggerAnimations();
        _staggerController.forward();
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
      AppLog.d(
          '❌ HostCheckinScreen load error: $e gameRef=${widget.gameRef.path}');
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
        if (mounted) {
          updateState(this, () {
            _submitting = false;
            _error = 'Submission failed. Please try again.';
          });
        }
      }
    } catch (e) {
      AppLog.d('HostCheckinScreen submit error: $e');
      if (mounted) {
        updateState(this, () {
          _submitting = false;
          _error = 'Something went wrong. Please try again.';
        });
      }
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
          icon: PhosphorIcon(AppPhosphorIcons.back,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

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

            // Participant roster
            Expanded(
              child: ListView.builder(
                padding: AppSpacing.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: AppSpacing.xs),
                itemCount: _participants.length,
                itemBuilder: (context, i) {
                  final p = _participants[i];
                  final isPresent = _attendance[p.key] ?? true;

                  Widget row = _ParticipantRow(
                    participant: p,
                    isPresent: isPresent,
                    onToggle: (val) {
                      updateState(this, () {
                        _attendance[p.key] = val;
                      });
                    },
                  );

                  // Stagger animation
                  if (i < _fadeAnimations.length) {
                    row = AnimatedBuilder(
                      animation: _staggerController,
                      builder: (context, child) => Opacity(
                        opacity: _fadeAnimations[i].value,
                        child: SlideTransition(
                          position: _slideAnimations[i],
                          child: child,
                        ),
                      ),
                      child: row,
                    );
                  }

                  return Padding(
                    padding: AppSpacing.only(bottom: AppSpacing.xs),
                    child: row,
                  );
                },
              ),
            ),

            // Submit button
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

  Widget _buildHeader() {
    return Padding(
      padding: AppSpacing.only(
        top: AppSpacing.sm,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: AppSpacing.sm,
      ),
      child: Column(
        children: [
          PhosphorIcon(
            AppPhosphorIcons.golfCourse,
            color: AppColors.textSecondary,
            size: AppIconSize.xl,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            _courseName,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            'Who played today?',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

/// Compact roster row: [Avatar] [Name + badge] ····· [Present | No-show]
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
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.navyLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar with visible background + border
          _buildAvatar(),
          SizedBox(width: AppSpacing.sm),

          // Name + inline badge
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    participant.displayName,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (participant.role == 'host') ...[
                  SizedBox(width: AppSpacing.xs),
                  _HostBadge(),
                ] else if (participant.isGuest) ...[
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Guest',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(width: AppSpacing.sm),

          // Compact toggle pair
          _TogglePair(
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

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.navyLight,
          width: 1,
        ),
      ),
      child: AppAvatar(
        imageUrl:
            participant.photoUrl.isNotEmpty ? participant.photoUrl : null,
        initials: initials.isEmpty ? '?' : initials,
        size: AppAvatarSize.small,
        backgroundColor: AppColors.navyLight,
      ),
    );
  }
}

/// Inline gold pill badge for "Host" role.
class _HostBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        'Host',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.gold,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Compact segmented toggle pair: [Present | No-show]
/// Reads as a single binary control, right-aligned in the row.
class _TogglePair extends StatelessWidget {
  const _TogglePair({required this.isPresent, required this.onToggle});

  final bool isPresent;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(
          color: AppColors.navyLight,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToggleSegment(
              label: 'Present',
              selected: isPresent,
              selectedColor: AppColors.green,
              isLeft: true,
              onTap: () => onToggle(true),
            ),
            _ToggleSegment(
              label: 'No-show',
              selected: !isPresent,
              selectedColor: AppColors.error,
              isLeft: false,
              onTap: () => onToggle(false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual segment within the toggle pair.
class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.isLeft,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final bool isLeft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionTokens.microInteraction,
        curve: MotionTokens.curveEnter,
        height: 32,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? selectedColor : AppColors.transparent,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected ? AppColors.textPrimary : AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
