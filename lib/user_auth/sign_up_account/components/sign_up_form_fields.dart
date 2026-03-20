import '/core/app_model.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/utils/state_update.dart';
import '/user_auth/shared/auth_input_decoration.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';

class SignUpFormFields extends StatefulWidget {
  const SignUpFormFields({super.key});

  @override
  State<SignUpFormFields> createState() => SignUpFormFieldsState();
}

class SignUpFormFieldsState extends State<SignUpFormFields> {
  FocusNode? emailAddressFocusNode;
  TextEditingController? emailAddressTextController;
  String? Function(BuildContext, String?)? emailAddressTextControllerValidator;

  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  bool passwordVisibility = false;
  String? Function(BuildContext, String?)? passwordTextControllerValidator;
  FocusNode? passwordVisibilityIconFocusNode;

  FocusNode? passwordConfirmFocusNode;
  TextEditingController? passwordConfirmTextController;
  bool passwordConfirmVisibility = false;
  String? Function(BuildContext, String?)?
      passwordConfirmTextControllerValidator;
  FocusNode? passwordConfirmVisibilityIconFocusNode;

  String get email => emailAddressTextController?.text ?? '';
  String get password => passwordTextController?.text ?? '';
  String get confirmPassword => passwordConfirmTextController?.text ?? '';

  @override
  void initState() {
    super.initState();
    emailAddressTextController = TextEditingController();
    emailAddressFocusNode = FocusNode();

    passwordTextController = TextEditingController();
    passwordFocusNode = FocusNode();
    passwordVisibilityIconFocusNode = FocusNode(skipTraversal: true);

    passwordConfirmTextController = TextEditingController();
    passwordConfirmFocusNode = FocusNode();
    passwordConfirmVisibilityIconFocusNode = FocusNode(skipTraversal: true);
  }

  @override
  void dispose() {
    emailAddressFocusNode?.dispose();
    emailAddressTextController?.dispose();

    passwordFocusNode?.dispose();
    passwordTextController?.dispose();
    passwordVisibilityIconFocusNode?.dispose();

    passwordConfirmFocusNode?.dispose();
    passwordConfirmTextController?.dispose();
    passwordConfirmVisibilityIconFocusNode?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildEmailField(),
        _buildPasswordField(),
        _buildPasswordConfirmField(),
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
          onChanged: (_) => EasyDebounce.debounce(
            'emailAddressTextController',
            Duration(milliseconds: 2000),
            () {
              if (mounted) {
                updateState(this, () {});
              }
            },
          ),
          autofocus: false,
          autofillHints: [AutofillHints.email],
          textInputAction: TextInputAction.next,
          obscureText: false,
          decoration: authInputDecoration(
            labelText: 'Email',
            suffixIcon: emailAddressTextController!.text.isNotEmpty
                ? InkWell(
                    onTap: () async {
                      emailAddressTextController?.clear();
                      if (mounted) {
                        updateState(this, () {});
                      }
                    },
                    child: Icon(
                      AppPhosphorIcons.close,
                      color: AppColors.textMuted,
                      size: AppIconSize.md,
                    ),
                  )
                : null,
          ),
          style: AppTypography.bodyMedium.copyWith(
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
          textInputAction: TextInputAction.next,
          obscureText: !passwordVisibility,
          decoration: authInputDecoration(
            labelText: 'Password',
            suffixIcon: InkWell(
              onTap: () {
                if (mounted) {
                  updateState(
                      this, () => passwordVisibility = !passwordVisibility);
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
          ),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          cursorColor: AppColors.green,
          validator:
              passwordTextControllerValidator.asValidator(context),
        ),
      ),
    );
  }

  Widget _buildPasswordConfirmField() {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: TextFormField(
          controller: passwordConfirmTextController,
          focusNode: passwordConfirmFocusNode,
          autofocus: false,
          autofillHints: [AutofillHints.password],
          textInputAction: TextInputAction.next,
          obscureText: !passwordConfirmVisibility,
          decoration: authInputDecoration(
            labelText: 'Confirm Password',
            suffixIcon: InkWell(
              onTap: () {
                if (mounted) {
                  updateState(this,
                      () => passwordConfirmVisibility = !passwordConfirmVisibility);
                }
              },
              focusNode: passwordConfirmVisibilityIconFocusNode,
              child: Icon(
                passwordConfirmVisibility
                    ? AppPhosphorIcons.eye
                    : AppPhosphorIcons.eyeSlash,
                color: AppColors.textMuted,
                size: AppIconSize.md,
              ),
            ),
          ),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          minLines: 1,
          cursorColor: AppColors.green,
          validator: passwordConfirmTextControllerValidator
              .asValidator(context),
        ),
      ),
    );
  }
}
