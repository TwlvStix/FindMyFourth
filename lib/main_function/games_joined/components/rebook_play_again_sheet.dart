import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/utils/state_update.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_time_picker.dart';
import '/models/game.dart';
import '/providers/provider_extensions.dart';
import '/services/rebook_service.dart';

/// Bottom sheet for the "Play Again" rebook flow.
///
/// Shows an inline calendar + time picker, then creates the game instantly
/// with the same course, settings, and players as the source game.
class RebookPlayAgainSheet extends StatefulWidget {
  const RebookPlayAgainSheet({
    super.key,
    required this.sourceGame,
    this.onGameCreated,
  });

  final Game sourceGame;
  final VoidCallback? onGameCreated;

  @override
  State<RebookPlayAgainSheet> createState() => _RebookPlayAgainSheetState();
}

class _RebookPlayAgainSheetState extends State<RebookPlayAgainSheet> {
  DateTime? _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isSubmitting = false;
  String? _errorMessage;

  DateTime get _today => DateTime.now();
  DateTime get _tomorrow => DateTime.now().add(const Duration(days: 1));

  DateTime? _buildSelectedDateTime() {
    if (_selectedDate == null) return null;
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _onSubmit() async {
    final dateTime = _buildSelectedDateTime();
    if (dateTime == null || _isSubmitting) return;

    updateState(this, () {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await RebookService().rebookGame(
      widget.sourceGame,
      dateTime,
    );

    if (!mounted) return;

    if (!result.success) {
      updateState(this, () {
        _isSubmitting = false;
        _errorMessage = result.errorMessage ?? 'Something went wrong.';
      });
      return;
    }

    // Invalidate caches so the new game appears
    context.gameProvider.invalidateAllGameCache();

    Navigator.pop(context);
    widget.onGameCreated?.call();
  }

  void _showTimePicker() {
    showAppTimePicker(
      context: context,
      title: 'Tee Time',
      initialTime: _selectedTime,
      onTimeSelected: (time) {
        updateState(this, () {
          _selectedTime = time;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppBorderRadius.xxl)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
                ),
              ),
              SizedBox(height: AppSpacing.sm),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Play Again',
                    style: AppTypography.headlineMediumSans.copyWith(
                      color: AppColors.pure,
                    ),
                  ),
                  IconButton(
                    icon: AppIcon(
                      icon: AppPhosphorIcons.close,
                      color: AppColors.pure,
                      size: AppIconSize.md,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xs),

              // Info row: course + game type
              _InfoRow(
                courseName: widget.sourceGame.coursePlay,
                gameType: widget.sourceGame.gameType,
              ),
              SizedBox(height: AppSpacing.sm),

              // Calendar
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: AppColors.green,
                    onPrimary: AppColors.pure,
                    surface: AppColors.navyDark,
                    onSurface: AppColors.pure,
                    onSurfaceVariant: AppColors.pure,
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: _tomorrow,
                  firstDate: _today,
                  lastDate: DateTime(2050),
                  onDateChanged: (date) {
                    HapticFeedback.selectionClick();
                    updateState(this, () {
                      _selectedDate = date;
                      _errorMessage = null;
                    });
                  },
                ),
              ),

              // Time picker trigger
              InkWell(
                onTap: _showTimePicker,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(
                      color: AppColors.greenLight.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      AppIcon(
                        icon: AppPhosphorIcons.clock,
                        color: AppColors.pure,
                        size: AppIconSize.button,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        _selectedTime.format(context),
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.pure,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      AppIcon(
                        icon: AppPhosphorIcons.edit,
                        color: AppColors.textSecondary,
                        size: AppIconSize.sm,
                      ),
                    ],
                  ),
                ),
              ),

              // Error message
              if (_errorMessage != null) ...[
                SizedBox(height: AppSpacing.sm),
                Text(
                  _errorMessage!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],

              SizedBox(height: AppSpacing.lg),

              // Create Game button
              SizedBox(
                width: double.infinity,
                child: AppButtonEnhanced(
                  text: 'Create Game',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  isLoading: _isSubmitting,
                  onPressed: _selectedDate != null && !_isSubmitting
                      ? _onSubmit
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Read-only info row showing course name and game type.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.courseName,
    required this.gameType,
  });

  final String courseName;
  final String gameType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Row(
        children: [
          AppIcon(
            icon: AppPhosphorIcons.course,
            color: AppColors.textSecondary,
            size: AppIconSize.sm,
          ),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              courseName.isNotEmpty ? courseName : 'Course not set',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (gameType.isNotEmpty) ...[
            SizedBox(width: AppSpacing.sm),
            Text(
              gameType,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
