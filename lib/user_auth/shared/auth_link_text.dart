import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import 'package:flutter/material.dart';

class AuthLinkText extends StatelessWidget {
  const AuthLinkText({
    super.key,
    required this.leadText,
    required this.linkText,
    required this.onTap,
  });

  final String leadText;
  final String linkText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Padding(
        padding: AppSpacing.verticalXs,
        child: InkWell(
          splashColor: AppColors.transparent,
          focusColor: AppColors.transparent,
          hoverColor: AppColors.transparent,
          highlightColor: AppColors.transparent,
          onTap: onTap,
          child: RichText(
            textScaler: MediaQuery.of(context).textScaler,
            text: TextSpan(
              children: [
                TextSpan(
                  text: leadText,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                TextSpan(
                  text: ' $linkText',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.greenLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
