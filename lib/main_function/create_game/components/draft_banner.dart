import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';

/// Draft continuation banner for game creation
///
/// Displays a yellow gradient banner with restore icon and message
/// when user has a saved draft. Includes clear action button.
class DraftBanner extends StatelessWidget {
  const DraftBanner({
    super.key,
    required this.onClear,
  });

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.sunsetGold.withValues(alpha: 0.2),
            AppColors.sunsetPeach.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.sunsetGold.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.restore_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue where you left off',
                  style: TextStyle(fontFamily: 'Manrope',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  'Your draft has been restored',
                  style: TextStyle(fontFamily: 'Manrope',
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: Text(
              'Clear',
              style: TextStyle(fontFamily: 'Manrope',
                color: AppColors.sunsetGold,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
