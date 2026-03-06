import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '/backend/schema/hometown_record.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/form_field_controller.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_drop_down.dart';

/// Hometown dropdown field that streams hometown options from Firestore.
class ProfileHometownDropdown extends StatelessWidget {
  const ProfileHometownDropdown({
    super.key,
    this.hometownValue,
    this.hometownValueController,
    this.onHometownChanged,
  });

  final String? hometownValue;
  final FormFieldController<String>? hometownValueController;
  final ValueChanged<String?>? onHometownChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HometownRecord>>(
      stream: HometownRecord.streamAll(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          AppLog.d('❌ Hometown stream error: ${snapshot.error}');
          return _buildStateContainer(
            child: Text(
              'Error loading hometowns',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
          );
        }

        if (!snapshot.hasData) {
          return _buildStateContainer(
            child: SpinKitFadingCircle(
              color: AppColors.textMuted,
              size: 24.0,
            ),
          );
        }

        final hometowns = snapshot.data!..sort((a, b) => a.name.compareTo(b.name));
        final options = hometowns.map((h) => h.name).toList();

        if (options.isEmpty) {
          return _buildStateContainer(
            child: Text(
              'No hometowns available',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(color: AppColors.inputBorderIdle),
          ),
          child: AppDropDown<String>(
            controller: hometownValueController ?? FormFieldController<String>(null),
            options: options,
            onChanged: onHometownChanged,
            width: double.infinity,
            height: 56,
            textStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            hintText: 'Hometown',
            icon: Icon(
              AppPhosphorIcons.course,
              color: AppColors.textMuted,
              size: AppIconSize.md,
            ),
            fillColor: AppColors.inputBackground,
            elevation: 0,
            borderColor: AppColors.transparent,
            borderWidth: 0,
            borderRadius: AppBorderRadius.card,
            margin: EdgeInsetsDirectional.only(start: AppSpacing.md),
          ),
        );
      },
    );
  }

  Widget _buildStateContainer({required Widget child}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.inputBorderIdle),
      ),
      child: Center(child: child),
    );
  }
}
