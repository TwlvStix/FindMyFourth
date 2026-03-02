import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

/// Data contract for BasicInfoStep props.
class BasicInfoFormData {
  const BasicInfoFormData({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.phone,
    required this.email,
    required this.firstNameFocus,
    required this.lastNameFocus,
    required this.usernameFocus,
    required this.phoneFocus,
    required this.emailFocus,
    required this.validateUsername,
    required this.validateEmail,
  });

  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController username;
  final TextEditingController phone;
  final TextEditingController email;
  final FocusNode firstNameFocus;
  final FocusNode lastNameFocus;
  final FocusNode usernameFocus;
  final FocusNode phoneFocus;
  final FocusNode emailFocus;
  final String? Function(String?) validateUsername;
  final String? Function(String?) validateEmail;
}

/// Basic info step of progressive onboarding.
///
/// Collects first name, last name, username, phone, and email.
class ProgressiveBasicInfoStep extends StatelessWidget {
  const ProgressiveBasicInfoStep({
    super.key,
    required this.data,
    required this.formKey,
  });

  final BasicInfoFormData data;
  final GlobalKey<FormState> formKey;

  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    bool hasErrorBorder = true,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: AppTypography.labelMedium,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.inputBorderIdle,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.inputBorderFocused,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      errorBorder: hasErrorBorder
          ? OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.error,
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            )
          : null,
      focusedErrorBorder: hasErrorBorder
          ? OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.error,
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            )
          : null,
      filled: true,
      fillColor: AppColors.inputBackground,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Let's set up your profile",
              style: AppTypography.headlineMediumSans.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.0,
              ),
            ),
            Padding(
              padding: AppSpacing.only(top: AppSpacing.xs),
              child: Text(
                'This helps other golfers find and connect with you.',
                style: AppTypography.bodyMedium,
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            // First Name
            TextFormField(
              controller: data.firstName,
              focusNode: data.firstNameFocus,
              autofocus: false,
              obscureText: false,
              decoration: _buildInputDecoration(
                labelText: 'First Name',
                hintText: 'Enter your first name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'First name is required';
                }
                return null;
              },
            ),
            SizedBox(height: AppSpacing.md),
            // Last Name
            TextFormField(
              controller: data.lastName,
              focusNode: data.lastNameFocus,
              obscureText: false,
              decoration: _buildInputDecoration(
                labelText: 'Last Name',
                hintText: 'Enter your last name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Last name is required';
                }
                return null;
              },
            ),
            SizedBox(height: AppSpacing.md),
            // Username
            TextFormField(
              controller: data.username,
              focusNode: data.usernameFocus,
              obscureText: false,
              decoration: _buildInputDecoration(
                labelText: 'Username',
                hintText: 'Choose a unique username',
              ),
              validator: data.validateUsername,
            ),
            SizedBox(height: AppSpacing.md),
            // Phone (Optional)
            TextFormField(
              controller: data.phone,
              focusNode: data.phoneFocus,
              obscureText: false,
              keyboardType: TextInputType.phone,
              decoration: _buildInputDecoration(
                labelText: 'Phone Number (Optional)',
                hintText: 'Enter your phone number',
                hasErrorBorder: false,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            // Email
            TextFormField(
              controller: data.email,
              focusNode: data.emailFocus,
              obscureText: false,
              keyboardType: TextInputType.emailAddress,
              decoration: _buildInputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
              ),
              validator: data.validateEmail,
            ),
          ],
        ),
      ),
    );
  }
}
