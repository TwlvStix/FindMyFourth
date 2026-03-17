import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_button_enhanced.dart';

/// Which status view to display.
enum PeerRatingStatusType {
  loading,
  alreadyCompleted,
  windowClosed,
  submitted,
  empty,
}

/// Full-scaffold status views for PeerRatingScreen.
///
/// Covers loading, already-completed, window-closed, submitted, and
/// empty/error states so the main screen only handles the rating form.
class PeerRatingStatusView extends StatelessWidget {
  const PeerRatingStatusView({
    super.key,
    required this.type,
    this.error,
    this.onDone,
    this.onRetry,
  });

  final PeerRatingStatusType type;
  final String? error;
  final VoidCallback? onDone;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case PeerRatingStatusType.loading:
        return _buildLoading();
      case PeerRatingStatusType.alreadyCompleted:
        return _buildAlreadyCompleted();
      case PeerRatingStatusType.windowClosed:
        return _buildWindowClosed();
      case PeerRatingStatusType.submitted:
        return _buildSubmitted();
      case PeerRatingStatusType.empty:
        return _buildEmpty();
    }
  }

  Widget _buildLoading() {
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

  Widget _buildAlreadyCompleted() {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PhosphorIcon(AppPhosphorIcons.thumbsUp,
                    color: AppColors.green, size: AppIconSize.hero),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Ratings already submitted.',
                  style: AppTypography.titleMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Your feedback helps build better groups.',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.xxl),
                AppButtonEnhanced(
                  onPressed: onDone,
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

  Widget _buildWindowClosed() {
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
                  onPressed: onDone,
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

  Widget _buildSubmitted() {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PhosphorIcon(AppPhosphorIcons.thumbsUp,
                    color: AppColors.green, size: AppIconSize.hero),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Ratings submitted!',
                  style: AppTypography.titleMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Your feedback helps build better groups.',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.xxl),
                AppButtonEnhanced(
                  onPressed: onDone,
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

  Widget _buildEmpty() {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        title: Text('Rate Your Group', style: AppTypography.titleMedium),
        centerTitle: true,
        leading: IconButton(
          icon: PhosphorIcon(AppPhosphorIcons.back,
              color: AppColors.textPrimary),
          onPressed: onDone,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  error ?? 'No players to rate for this round.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: error != null
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (error != null) ...[
                  SizedBox(height: AppSpacing.lg),
                  AppButtonEnhanced(
                    onPressed: onRetry,
                    text: 'Try Again',
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.medium,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
