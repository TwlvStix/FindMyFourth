import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_text.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class AuthDesktopSidebar extends StatelessWidget {
  const AuthDesktopSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Container(
        width: 100.0,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.navyDark, AppColors.navy],
            stops: [0.0, 1.0],
            begin: AlignmentDirectional(1.0, -1.0),
            end: AlignmentDirectional(-1.0, 1.0),
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: 400.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pure,
                  boxShadow: [AppElevation.xs],
                  borderRadius:
                      BorderRadius.circular(AppBorderRadius.sm),
                  border: Border.all(
                    color: AppColors.sand,
                    width: 2.0,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxs),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: AppSpacing.xs,
                          top: AppSpacing.xs,
                          right: AppSpacing.xs,
                          bottom: AppSpacing.xxs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          crossAxisAlignment:
                              CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    right: AppSpacing.xxs,
                                  ),
                                  child: Container(
                                    width: 40.0,
                                    height: 40.0,
                                    decoration: BoxDecoration(
                                      color: AppColors.cloud,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      AppPhosphorIcons.profile,
                                      color: AppColors.navyDark,
                                      size: AppIconSize.md,
                                    ),
                                  ),
                                ),
                                AppText.cardTitle('UserName'),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                AppText.bodySmall('Overall'),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        right: AppSpacing.xxs,
                                      ),
                                      child:
                                          AppText.screenTitle('5'),
                                    ),
                                    Icon(
                                      AppPhosphorIcons.starFill,
                                      color: AppColors.navyDark,
                                      size: AppIconSize.button,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: AppSpacing.xs,
                          right: AppSpacing.xs,
                          bottom: AppSpacing.xxs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: AutoSizeText(
                                'Nice outdoor courts, solid concrete and good hoops for the neighborhood.',
                                style: AppTypography.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
