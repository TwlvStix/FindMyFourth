import '/auth/firebase_auth/auth_util.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_text.dart';
import '/user_auth/sign_in/sign_in_widget.dart';
import 'package:flutter/material.dart';

class RecoverPasswordWidget extends StatefulWidget {
  const RecoverPasswordWidget({super.key});

  static String routeName = 'RecoverPassword';
  static String routePath = '/recoverPassword';

  @override
  State<RecoverPasswordWidget> createState() => _RecoverPasswordWidgetState();
}

class _RecoverPasswordWidgetState extends State<RecoverPasswordWidget> {
  FocusNode? enterEmailFocusNode;
  TextEditingController? enterEmailTextController;
  String? Function(BuildContext, String?)? enterEmailTextControllerValidator;
  bool emailSent = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  void _returnToSignIn() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.goNamed(SignInWidget.routeName);
  }

  @override
  void initState() {
    super.initState();
    enterEmailTextController = TextEditingController();
    enterEmailFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    enterEmailFocusNode?.dispose();
    enterEmailTextController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AppTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppTheme.of(context).primary,
            ),
            onPressed: _returnToSignIn,
          ),
          title: AppText.screenTitle(
            'Recover Password',
            color: AppTheme.of(context).primary,
            textAlign: TextAlign.center,
          ),
          actions: [],
          centerTitle: true,
          elevation: 10.0,
        ),
        body: FairwayBackgroundLight(
          child: SafeArea(
            top: true,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, AppSpacing.md, 0.0, 0.0),
                      child: Container(
                        width: 100.0,
                        height: 100.0,
                        decoration: BoxDecoration(
                          color: AppTheme.of(context).primaryBackground,
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              AppSpacing.md, AppSpacing.md, AppSpacing.md, 0.0),
                          child: AppText.body(
                            'We will send you an email with a link to reset your password, please enter the email associated with your account below. ',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(AppSpacing.md, 0.0, AppSpacing.md, 0.0),
                      child: Container(
                        width: 100.0,
                        height: 75.0,
                        decoration: BoxDecoration(
                          color: AppTheme.of(context).primary,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 6.0,
                              color: Color(0x33000000),
                              offset: Offset(
                                0.0,
                                4.0,
                              ),
                            )
                          ],
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        child: Align(
                          alignment: AlignmentDirectional(-1.0, 0.0),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                AppSpacing.md, 0.0, AppSpacing.md, 0.0),
                            child: TextFormField(
                              controller: enterEmailTextController,
                              focusNode: enterEmailFocusNode,
                              autofocus: true,
                              obscureText: false,
                              decoration: InputDecoration(
                                labelText: 'Enter Email Here',
                                labelStyle: AppTypography.bodyLarge.copyWith(
                                  color: AppTheme.of(context).primaryBtnText,
                                  fontWeight: FontWeight.w500,
                                ),
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                              ),
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppTheme.of(context).primaryBtnText,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.start,
                              keyboardType: TextInputType.emailAddress,
                              validator: enterEmailTextControllerValidator
                                  .asValidator(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, AppSpacing.md, 0.0, 0.0),
                child: AppButtonEnhanced(
                  onPressed: () async {
                    if (enterEmailTextController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Email required!',
                          ),
                        ),
                      );
                      return;
                    }
                    final didSend = await authManager.resetPassword(
                      email: enterEmailTextController.text,
                      context: context,
                    );
                    if (didSend && mounted) {
                      setState(() => emailSent = true);
                    }
                  },
                  text: 'Send Link',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                ),
              ),
              if (emailSent)
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0.0),
                  child: AppText.body(
                    'Check your email for the reset link. You can return to sign in once you receive it.',
                    color: AppTheme.of(context).secondaryText,
                    textAlign: TextAlign.center,
                  ),
                ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, AppSpacing.xs, 0.0, 0.0),
                child: TextButton(
                  onPressed: _returnToSignIn,
                  child: AppText.label(
                    'Back to Sign In',
                    color: AppTheme.of(context).primary,
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
