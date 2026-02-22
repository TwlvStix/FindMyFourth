import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/typography.dart';
import '../design_tokens/spacing.dart';

enum AppLoadingVariant {
  /// Spinner only
  spinner,

  /// Spinner with message
  message,

  /// Linear progress indicator
  linear,
}

class AppLoadingState extends StatelessWidget {
  final AppLoadingVariant variant;
  final String? message;

  const AppLoadingState({
    super.key,
    this.variant = AppLoadingVariant.spinner,
    this.message,
  });

  const AppLoadingState.message(String this.message, {super.key})
      : variant = AppLoadingVariant.message;

  const AppLoadingState.linear({super.key, this.message})
      : variant = AppLoadingVariant.linear;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AppLoadingVariant.spinner:
        return Center(
          child: SpinKitFadingCircle(
            color: AppColors.navy,
            size: 50.0,
          ),
        );

      case AppLoadingVariant.message:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpinKitFadingCircle(
                color: AppColors.navy,
                size: 50.0,
              ),
              if (message != null) ...[
                SizedBox(height: AppSpacing.md),
                Text(
                  message!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.stone,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );

      case AppLoadingVariant.linear:
        return Column(
          children: [
            LinearProgressIndicator(
              color: AppColors.navy,
              backgroundColor: AppColors.sand,
            ),
            if (message != null) ...[
              SizedBox(height: AppSpacing.md),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  message!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.stone,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        );
    }
  }
}
