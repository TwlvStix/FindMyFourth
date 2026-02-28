import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/profile/main_profile/main_profile_widget.dart';
import 'package:flutter/material.dart';

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
      backgroundColor: AppColors.navy,
      body: FairwayBackgroundClubhouse(
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
                        color: AppColors.navyDark,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.pure,
                          width: 2.0,
                        ),
                      ),
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Padding(
                        padding: AppSpacing.only(left: 30.0, top: 30.0, right: 30.0, bottom: 30.0),
                        child: AppIcon(
                          icon: AppPhosphorIcons.check,
                          color: AppColors.pure,
                          size: AppIconSize.hero,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: AppSpacing.only(top: AppSpacing.xl),
                    child: Text(
                      'Enjoy Your Boring Existence',
                      style: AppTypography.titleLarge,
                    ),
                  ),
                  Padding(
                    padding: AppSpacing.only(top: AppSpacing.md),
                    child: Text(
                      'We will have fun without you!',
                      style: AppTypography.titleLarge,
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
                  transitionType: AppTransitionType.fade,
                  enterDuration: Duration(milliseconds: 200),
                  exitDuration: Duration(milliseconds: 170),
                  scaleOnPush: false,
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
