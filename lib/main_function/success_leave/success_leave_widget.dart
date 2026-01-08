import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/profile/main_profile/main_profile_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuccessLeaveWidget extends StatefulWidget {
  const SuccessLeaveWidget({super.key});

  static String routeName = 'success_leave';
  static String routePath = '/successLeave';

  @override
  State<SuccessLeaveWidget> createState() => _SuccessLeaveWidgetState();
}

class _SuccessLeaveWidgetState extends State<SuccessLeaveWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppTheme.of(context).secondaryBackground,
      body: FairwayBackgroundSunset(
        showOrganic: true,
        child: SafeArea(
          top: true,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                  Padding(
                    padding: AppSpacing.only(top: 150.0),
                    child: Container(
                      width: 140.0,
                      height: 140.0,
                      decoration: BoxDecoration(
                        color: AppTheme.of(context).primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.of(context).primaryBtnText,
                          width: 2.0,
                        ),
                      ),
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Padding(
                        padding: AppSpacing.only(left: 30.0, top: 30.0, right: 30.0, bottom: 30.0),
                        child: Icon(
                          Icons.check_rounded,
                          color: AppTheme.of(context).primaryBtnText,
                          size: 60.0,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: AppSpacing.only(top: AppSpacing.xl),
                    child: Text(
                      'Enjoy Your Boring Existence',
                      style: AppTheme.of(context).titleLarge.override(
                            font: GoogleFonts.outfit(
                              fontWeight: AppTheme.of(context)
                                  .titleLarge
                                  .fontWeight,
                              fontStyle: AppTheme.of(context)
                                  .titleLarge
                                  .fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: AppTheme.of(context)
                                .titleLarge
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .titleLarge
                                .fontStyle,
                          ),
                    ),
                  ),
                  Padding(
                    padding: AppSpacing.only(top: AppSpacing.md),
                    child: Text(
                      'We will have fun without you!',
                      style: AppTheme.of(context).titleLarge.override(
                            font: GoogleFonts.outfit(
                              fontWeight: AppTheme.of(context)
                                  .titleLarge
                                  .fontWeight,
                              fontStyle: AppTheme.of(context)
                                  .titleLarge
                                  .fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: AppTheme.of(context)
                                .titleLarge
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .titleLarge
                                .fontStyle,
                          ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: AppSpacing.only(bottom: AppSpacing.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 230.0,
                            child: AppButtonEnhanced(
                              onPressed: () async {
                                context.pushNamed(
                                  MainProfileWidget.routeName,
                                  extra: <String, dynamic>{
                                    kTransitionInfoKey: TransitionInfo(
                                      hasTransition: true,
                                      transitionType:
                                          PageTransitionType.topToBottom,
                                      duration: Duration(milliseconds: 220),
                                    ),
                                  },
                                );
                              },
                              text: 'Go Home',
                              variant: AppButtonVariant.primary,
                              size: AppButtonSize.large,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
