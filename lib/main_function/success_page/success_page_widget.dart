import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/main_function/games_list/games_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuccessPageWidget extends StatefulWidget {
  const SuccessPageWidget({super.key});

  static String routeName = 'success_page';
  static String routePath = '/successPage';

  @override
  State<SuccessPageWidget> createState() => _SuccessPageWidgetState();
}

class _SuccessPageWidgetState extends State<SuccessPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // ✅ PERFORMANCE: Removed empty post-frame setState (no-op rebuild)
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
                      padding: AppSpacing.only(top: AppSpacing.xxxxl * 2.34),
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
                          padding: EdgeInsets.all(AppSpacing.xl + 6.0),
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
                        'You are in!',
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
                        'Enjoy the Game',
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
                        'Enjoy the Group',
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
                            AppButtonEnhanced(
                              onPressed: () async {
                                context.pushNamed(
                                  GamesListWidget.routeName,
                                  extra: <String, dynamic>{
                                    kTransitionInfoKey: TransitionInfo(
                  hasTransition: true,
                  transitionType: PageTransitionType.fade,
                  enterDuration: Duration(milliseconds: 200),
                  exitDuration: Duration(milliseconds: 170),
                  scaleOnPush: false,
                ),
                                  },
                                );
                              },
                              text: 'Go to Game Lists',
                              variant: AppButtonVariant.gradient,
                              size: AppButtonSize.large,
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
