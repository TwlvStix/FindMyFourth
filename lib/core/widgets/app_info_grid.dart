import 'package:flutter/material.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/typography.dart';
import '../design_tokens/spacing.dart';
import '../design_tokens/border_radius.dart';

class AppInfoGrid extends StatelessWidget {
  final List<AppInfoGridItem> items;

  const AppInfoGrid({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItem(items[index]),
    );
  }

  Widget _buildItem(AppInfoGridItem item) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.cloud),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.stone,
            ),
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            item.value,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.onyx,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class AppInfoGridItem {
  final String label;
  final String value;

  const AppInfoGridItem({
    required this.label,
    required this.value,
  });
}
