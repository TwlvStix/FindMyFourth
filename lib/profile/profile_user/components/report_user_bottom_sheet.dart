import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/content/report_copy.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_text_field.dart';
import '/services/report_service.dart';

/// Bottom sheet for reporting a user.
///
/// Presents a list of report reasons and an optional details field.
/// Submits the report to Firestore and shows confirmation via snackbar.
class ReportUserBottomSheet extends StatefulWidget {
  const ReportUserBottomSheet({
    super.key,
    required this.reportedUid,
    required this.reportedDisplayName,
    this.reportContext = 'profile',
    this.chatId,
    this.messageId,
  });

  final String reportedUid;
  final String reportedDisplayName;
  final String reportContext;
  final String? chatId;
  final String? messageId;

  @override
  State<ReportUserBottomSheet> createState() => _ReportUserBottomSheetState();
}

class _ReportUserBottomSheetState extends State<ReportUserBottomSheet> {
  final ReportService _reportService = ReportService();
  final TextEditingController _detailsController = TextEditingController();
  String? _selectedReason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _selectedReason;
    if (reason == null) return;

    final currentUid = currentUserUid;
    if (currentUid.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await _reportService.submitReport(
        reporterUid: currentUid,
        reportedUid: widget.reportedUid,
        reason: reason,
        details: _detailsController.text,
        reportContext: widget.reportContext,
        chatId: widget.chatId,
        messageId: widget.messageId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ReportBlockCopy.reportSubmitted)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ReportBlockCopy.reportFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppBorderRadius.xl),
          topRight: Radius.circular(AppBorderRadius.xl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.navyLight,
                borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            ReportBlockCopy.reportTitle,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          // Reason tiles
          ...ReportReasons.all.map((reason) => _buildReasonTile(reason)),
          SizedBox(height: AppSpacing.md),
          // Details field
          AppTextField(
            controller: _detailsController,
            hint: ReportBlockCopy.reportDetailsHint,
            maxLines: 3,
            maxLength: 500,
          ),
          SizedBox(height: AppSpacing.lg),
          // Submit button
          AppButtonEnhanced(
            text: ReportBlockCopy.submitReport,
            variant: AppButtonVariant.primary,
            onPressed: _selectedReason != null && !_isSubmitting
                ? _submit
                : null,
            isLoading: _isSubmitting,
          ),
        ],
      ),
    );
  }

  Widget _buildReasonTile(String reason) {
    final isSelected = _selectedReason == reason;
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedReason = reason);
        },
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            border: Border.all(
              color: isSelected ? AppColors.green : AppColors.navyLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            ReportReasons.displayLabel(reason),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
