import 'package:flutter/material.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/typography.dart';
import '../design_tokens/spacing.dart';
import '../design_tokens/app_icons.dart';
import 'app_icon.dart';

class AppEmptyState extends StatelessWidget {
  final IconData? icon;
  final String? svgPath;
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    this.icon,
    this.svgPath,
    required this.title,
    this.message,
    this.actionText,
    this.onAction,
  }) : assert(icon != null || svgPath != null, 'Either icon or svgPath must be provided');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (svgPath != null)
              AppIcon(
                assetPath: svgPath!,
                size: 64,
                color: AppColors.cloud,
              )
            else if (icon != null)
              Icon(
                icon,
                size: 64,
                color: AppColors.cloud,
              ),
            SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.slate,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.stone,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
