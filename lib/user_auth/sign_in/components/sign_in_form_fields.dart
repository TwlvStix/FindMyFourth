import '/core/app_model.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/user_auth/shared/auth_input_decoration.dart';
import 'package:flutter/material.dart';

class SignInFormFields extends StatefulWidget {
  const SignInFormFields({super.key});

  @override
  State<SignInFormFields> createState() => SignInFormFieldsState();
}

class SignInFormFieldsState extends State<SignInFormFields> {
  FocusNode? emailAddressFocusNode;
  TextEditingController? emailAddressTextController;
  String? Function(BuildContext, String?)? emailAddressTextControllerValidator;

  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  bool passwordVisibility = false;
  String? Function(BuildContext, String?)? passwordTextControllerValidator;
  FocusNode? passwordVisibilityIconFocusNode;

  String get email => emailAddressTextController?.text ?? '';
  String get password => passwordTextController?.text ?? '';

  @override
  void initState() {
    super.initState();
    emailAddressTextController = TextEditingController();
    emailAddressFocusNode = FocusNode();

    passwordTextController = TextEditingController();
    passwordFocusNode = FocusNode();
    passwordVisibilityIconFocusNode = FocusNode(skipTraversal: true);
  }

  @override
  void dispose() {
    emailAddressFocusNode?.dispose();
    emailAddressTextController?.dispose();

    passwordFocusNode?.dispose();
    passwordTextController?.dispose();
    passwordVisibilityIconFocusNode?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildEmailField(),
        _buildPasswordField(),
      ],
    );
  }

  Widget _buildEmailField() {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: TextFormField(
          controller: emailAddressTextController,
          focusNode: emailAddressFocusNode,
          autofocus: false,
          autofillHints: [AutofillHints.email],
          obscureText: false,
          decoration: authInputDecoration(
            labelText: 'Email',
          ).copyWith(
            labelStyle: AppTypography.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          keyboardType: TextInputType.emailAddress,
          cursorColor: AppColors.green,
          validator:
              emailAddressTextControllerValidator.asValidator(context),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: TextFormField(
          controller: passwordTextController,
          focusNode: passwordFocusNode,
          autofocus: false,
          autofillHints: [AutofillHints.password],
          obscureText: !passwordVisibility,
          decoration: authInputDecoration(
            labelText: 'Password',
            suffixIcon: InkWell(
              onTap: () {
                if (mounted) {
                  setState(
                      () => passwordVisibility = !passwordVisibility);
                }
              },
              focusNode: passwordVisibilityIconFocusNode,
              child: Icon(
                passwordVisibility
                    ? AppPhosphorIcons.eye
                    : AppPhosphorIcons.eyeSlash,
                color: AppColors.textMuted,
                size: AppIconSize.md,
              ),
            ),
          ).copyWith(
            labelStyle: AppTypography.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          cursorColor: AppColors.green,
          validator:
              passwordTextControllerValidator.asValidator(context),
        ),
      ),
    );
  }
}
