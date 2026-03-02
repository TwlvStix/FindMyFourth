import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/form_field_controller.dart';
import '/core/widgets/app_drop_down.dart';
import '/core/widgets/app_text_field.dart';
import 'profile_date_picker_field.dart';

/// The personal information section of the create profile form.
///
/// Contains fields for: first name, last name, display name (username),
/// phone, email, gender, and date of birth.
class PersonalInfoSection extends StatelessWidget {
  const PersonalInfoSection({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.usernameController,
    required this.phoneController,
    required this.emailController,
    required this.usernameFocusNode,
    required this.genderValue,
    required this.genderValueController,
    required this.dateOfBirth,
    required this.onGenderChanged,
    required this.onDateOfBirthChanged,
    required this.validateUsername,
    required this.validateEmail,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController usernameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final FocusNode usernameFocusNode;
  final String? genderValue;
  final FormFieldController<String>? genderValueController;
  final DateTime? dateOfBirth;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<DateTime> onDateOfBirthChanged;
  final String? Function(BuildContext, String?) validateUsername;
  final String? Function(BuildContext, String?) validateEmail;

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
                child: _buildTextField(
                  context: context,
                  controller: firstNameController,
                  label: 'First Name *',
                  icon: AppPhosphorIcons.profile,
                  validator: (context, val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'First name is required';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildTextField(
                  context: context,
                  controller: lastNameController,
                  label: 'Last Name',
                  icon: AppPhosphorIcons.profile,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),

          // Display Name
          _buildTextField(
            context: context,
            controller: usernameController,
            label: 'Display Name',
            icon: AppPhosphorIcons.atSign,
            validator: validateUsername,
            focusNode: usernameFocusNode,
          ),
          SizedBox(height: AppSpacing.md),

          // Phone
          _buildTextField(
            context: context,
            controller: phoneController,
            label: 'Phone',
            icon: AppPhosphorIcons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          SizedBox(height: AppSpacing.md),

          // Email
          _buildTextField(
            context: context,
            controller: emailController,
            label: 'Email',
            icon: AppPhosphorIcons.email,
            validator: validateEmail,
            readOnly: true,
          ),
          SizedBox(height: AppSpacing.md),

          // Gender & Date of Birth Row
          Row(
            children: [
              // Gender Dropdown
              Expanded(child: _buildGenderDropdown(context)),
              SizedBox(width: AppSpacing.sm),
              // Date of Birth Picker
              Expanded(
                child: ProfileDatePickerField(
                  dateOfBirth: dateOfBirth,
                  onDateSelected: onDateOfBirthChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(BuildContext, String?)? validator,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    FocusNode? focusNode,
  }) {
    return AppTextField(
      label: label,
      controller: controller,
      variant: AppTextFieldVariant.filledDark,
      prefixIcon: icon,
      readOnly: readOnly,
      enabled: !readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator != null ? (val) => validator(context, val) : null,
      focusNode: focusNode,
    );
  }

  Widget _buildGenderDropdown(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.inputBorderIdle),
      ),
      child: AppDropDown<String>(
        controller: genderValueController ?? FormFieldController<String>(null),
        options: const ['Male', 'Female'],
        onChanged: onGenderChanged,
        width: double.infinity,
        height: 56,
        textStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        hintText: 'Gender *',
        icon: Icon(
          AppPhosphorIcons.profile,
          color: AppColors.textMuted,
          size: AppIconSize.md,
        ),
        fillColor: AppColors.inputBackground,
        elevation: 0,
        borderColor: Colors.transparent,
        borderWidth: 0,
        borderRadius: AppBorderRadius.card,
        margin: EdgeInsetsDirectional.only(start: AppSpacing.md),
      ),
    );
  }
}
