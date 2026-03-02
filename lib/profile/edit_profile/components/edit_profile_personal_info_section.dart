import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_text_field.dart';

/// Personal information section of the Edit Profile screen.
///
/// Displays editable fields for name, phone, and read-only
/// fields for display name, email, gender, and date of birth.
class EditProfilePersonalInfoSection extends StatelessWidget {
  const EditProfilePersonalInfoSection({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.usernameController,
    required this.phoneController,
    required this.emailController,
    required this.gender,
    required this.dateOfBirth,
    this.firstNameValidator,
    this.lastNameValidator,
    this.phoneValidator,
  });

  /// Controller for first name field
  final TextEditingController firstNameController;

  /// Controller for last name field
  final TextEditingController lastNameController;

  /// Controller for display name field (read-only)
  final TextEditingController usernameController;

  /// Controller for phone number field
  final TextEditingController phoneController;

  /// Controller for email field (read-only)
  final TextEditingController emailController;

  /// User's gender (read-only display)
  final String? gender;

  /// User's date of birth (read-only display)
  final DateTime? dateOfBirth;

  /// Validator for first name
  final String? Function(String?)? firstNameValidator;

  /// Validator for last name
  final String? Function(String?)? lastNameValidator;

  /// Validator for phone number
  final String? Function(String?)? phoneValidator;

  String get _genderDisplay =>
      gender?.isNotEmpty == true ? gender! : 'Gender';

  String get _dateOfBirthDisplay {
    if (dateOfBirth == null) return 'Birthday';
    final d = dateOfBirth!;
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // First & Last Name Row
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'First Name',
                  controller: firstNameController,
                  variant: AppTextFieldVariant.filledDark,
                  prefixPhosphorIcon: AppPhosphorIcons.profile,
                  validator: firstNameValidator,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: 'Last Name',
                  controller: lastNameController,
                  variant: AppTextFieldVariant.filledDark,
                  prefixPhosphorIcon: AppPhosphorIcons.profile,
                  validator: lastNameValidator,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),

          // Display Name (read-only)
          AppTextField(
            label: 'Display Name',
            controller: usernameController,
            variant: AppTextFieldVariant.filledDark,
            prefixPhosphorIcon: AppPhosphorIcons.atSign,
            readOnly: true,
            enabled: false,
          ),
          SizedBox(height: AppSpacing.md),

          // Phone
          AppTextField(
            label: 'Phone',
            controller: phoneController,
            variant: AppTextFieldVariant.filledDark,
            prefixPhosphorIcon: AppPhosphorIcons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: phoneValidator,
          ),
          SizedBox(height: AppSpacing.md),

          // Email (read-only)
          AppTextField(
            label: 'Email',
            controller: emailController,
            variant: AppTextFieldVariant.filledDark,
            prefixPhosphorIcon: AppPhosphorIcons.email,
            readOnly: true,
            enabled: false,
          ),
          SizedBox(height: AppSpacing.md),

          // Gender & Date of Birth Row (Read-only)
          Row(
            children: [
              // Gender (Read-only)
              Expanded(child: _buildReadOnlyField(
                icon: AppPhosphorIcons.profile,
                value: _genderDisplay,
                hasValue: gender?.isNotEmpty == true,
              )),
              SizedBox(width: AppSpacing.sm),
              // Date of Birth (Read-only)
              Expanded(child: _buildReadOnlyField(
                icon: AppPhosphorIcons.calendar,
                value: _dateOfBirthDisplay,
                hasValue: dateOfBirth != null,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required IconData icon,
    required String value,
    required bool hasValue,
  }) {
    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.inputBorderIdle),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.textMuted,
            size: AppIconSize.md,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: hasValue ? AppColors.textSecondary : AppColors.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
