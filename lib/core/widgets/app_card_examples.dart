import 'package:flutter/material.dart';
import 'app_card.dart';
import 'app_button_enhanced.dart';
import 'fairway_background.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/typography.dart';
import '../design_tokens/spacing.dart';

/// Examples showcasing AppCard variants and specialized cards
///
/// Demonstrates:
/// - All 4 card variants (standard, elevated, outlined, gradientAccent)
/// - Specialized cards (GameCard, StatCard, SectionCard)
/// - Interactive states (tappable cards)
/// - Real-world usage patterns
class AppCardExamples extends StatelessWidget {
  const AppCardExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Card System Examples',
          style: AppTypography.headlineMedium,
        ),
        backgroundColor: AppColors.pure,
      ),
      body: FairwayBackgroundLight(
        child: SingleChildScrollView(
          padding: AppSpacing.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Card Variants'),
              AppSpacing.verticalMdBox,
              _buildVariantExample(
                'Standard Card',
                'Default elevated card with shadow',
                AppCardVariant.standard,
              ),
              AppSpacing.verticalMdBox,
              _buildVariantExample(
                'Elevated Card',
                'Stronger shadow for emphasis',
                AppCardVariant.elevated,
              ),
              AppSpacing.verticalMdBox,
              _buildVariantExample(
                'Outlined Card',
                'Border instead of shadow',
                AppCardVariant.outlined,
              ),
              AppSpacing.verticalMdBox,
              _buildVariantExample(
                'Gradient Accent Card',
                'Accent bar for visual interest',
                AppCardVariant.gradientAccent,
              ),
              AppSpacing.verticalXxlBox,
              _buildSectionHeader('Specialized Cards'),
              AppSpacing.verticalMdBox,
              _buildGameCardExample(),
              AppSpacing.verticalMdBox,
              _buildStatCardExample(),
              AppSpacing.verticalMdBox,
              _buildSectionCardExample(),
              AppSpacing.verticalXxlBox,
              _buildSectionHeader('Interactive Cards'),
              AppSpacing.verticalMdBox,
              _buildInteractiveExample(),
              AppSpacing.verticalXxlBox,
              _buildSectionHeader('Real-World Examples'),
              AppSpacing.verticalMdBox,
              _buildGameListExample(),
              AppSpacing.verticalMdBox,
              _buildProfileStatsExample(),
              AppSpacing.verticalXxxlBox,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.displaySmall.withColor(AppColors.fairwayDark),
    );
  }

  Widget _buildVariantExample(
    String title,
    String description,
    AppCardVariant variant,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleLarge.withColor(AppColors.fairwayDark),
        ),
        AppSpacing.verticalXxs,
        Text(
          description,
          style: AppTypography.bodySmall.withColor(AppColors.slate),
        ),
        AppSpacing.verticalSmBox,
        AppCard(
          variant: variant,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Card Title',
                style:
                    AppTypography.headlineMedium.withColor(AppColors.fairwayDark),
              ),
              AppSpacing.verticalXsBox,
              Text(
                'This is example content showing how the card looks with this variant. The spacing and typography follow our design system.',
                style: AppTypography.bodyMedium.withColor(AppColors.slate),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameCardExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GameCard',
          style: AppTypography.titleLarge.withColor(AppColors.fairwayDark),
        ),
        AppSpacing.verticalXxs,
        Text(
          'Pre-configured for game listings',
          style: AppTypography.bodySmall.withColor(AppColors.slate),
        ),
        AppSpacing.verticalSmBox,
        GameCard(
          title: 'Pebble Beach Round',
          subtitle: 'Saturday, Jan 6 at 9:00 AM',
          metadata: '3/4 players',
          trailing: AppButtonEnhanced(
            text: 'Join',
            size: AppButtonSize.small,
            variant: AppButtonVariant.primary,
            onPressed: () {},
          ),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildStatCardExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'StatCard',
          style: AppTypography.titleLarge.withColor(AppColors.fairwayDark),
        ),
        AppSpacing.verticalXxs,
        Text(
          'Perfect for statistics and metrics',
          style: AppTypography.bodySmall.withColor(AppColors.slate),
        ),
        AppSpacing.verticalSmBox,
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Games',
                value: '24',
                icon: Icons.golf_course,
              ),
            ),
            AppSpacing.horizontalSmBox,
            Expanded(
              child: StatCard(
                label: 'Avg Score',
                value: '87',
                icon: Icons.analytics,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCardExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SectionCard',
          style: AppTypography.titleLarge.withColor(AppColors.fairwayDark),
        ),
        AppSpacing.verticalXxs,
        Text(
          'Elevated card with header and content',
          style: AppTypography.bodySmall.withColor(AppColors.slate),
        ),
        AppSpacing.verticalSmBox,
        SectionCard(
          title: 'Recent Activity',
          subtitle: 'Last 7 days',
          action: TextButton(
            onPressed: () {},
            child: Text(
              'View All',
              style: AppTypography.button.withColor(AppColors.fairway),
            ),
          ),
          child: Column(
            children: [
              _buildActivityItem('Joined Pebble Beach Round', '2 hours ago'),
              AppSpacing.verticalSmBox,
              _buildActivityItem('Completed Torrey Pines', 'Yesterday'),
              AppSpacing.verticalSmBox,
              _buildActivityItem('Invited to Spyglass Hill', '2 days ago'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.sunsetGold,
            shape: BoxShape.circle,
          ),
        ),
        AppSpacing.horizontalSmBox,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.withColor(AppColors.onyx),
              ),
              Text(
                time,
                style: AppTypography.bodySmall.withColor(AppColors.stone),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tappable Cards',
          style: AppTypography.titleLarge.withColor(AppColors.fairwayDark),
        ),
        AppSpacing.verticalXxs,
        Text(
          'Cards with onTap have scale animation',
          style: AppTypography.bodySmall.withColor(AppColors.slate),
        ),
        AppSpacing.verticalSmBox,
        AppCard(
          variant: AppCardVariant.gradientAccent,
          onTap: () {
            // Navigation or action
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tap Me',
                    style: AppTypography.headlineMedium
                        .withColor(AppColors.fairwayDark),
                  ),
                  AppSpacing.verticalXxs,
                  Text(
                    'Press to see scale animation',
                    style: AppTypography.bodyMedium.withColor(AppColors.slate),
                  ),
                ],
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.fairway,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameListExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Game List Pattern',
          style: AppTypography.titleLarge.withColor(AppColors.fairwayDark),
        ),
        AppSpacing.verticalXxs,
        Text(
          'How cards look in a real game list',
          style: AppTypography.bodySmall.withColor(AppColors.slate),
        ),
        AppSpacing.verticalSmBox,
        Column(
          children: [
            GameCard(
              title: 'Pebble Beach Golf Links',
              subtitle: 'Saturday, Jan 6 at 9:00 AM',
              metadata: '3/4 players',
              trailing: AppButtonEnhanced(
                text: 'Join',
                size: AppButtonSize.small,
                variant: AppButtonVariant.primary,
                onPressed: () {},
              ),
              onTap: () {},
            ),
            AppSpacing.verticalMdBox,
            GameCard(
              title: 'Torrey Pines South',
              subtitle: 'Sunday, Jan 7 at 8:30 AM',
              metadata: '2/4 players',
              trailing: AppButtonEnhanced(
                text: 'Join',
                size: AppButtonSize.small,
                variant: AppButtonVariant.primary,
                onPressed: () {},
              ),
              onTap: () {},
            ),
            AppSpacing.verticalMdBox,
            GameCard(
              title: 'Spyglass Hill',
              subtitle: 'Monday, Jan 8 at 10:00 AM',
              metadata: '4/4 players',
              trailing: Text(
                'Full',
                style: AppTypography.button.withColor(AppColors.stone),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileStatsExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Stats Pattern',
          style: AppTypography.titleLarge.withColor(AppColors.fairwayDark),
        ),
        AppSpacing.verticalXxs,
        Text(
          'Statistics display with stat cards',
          style: AppTypography.bodySmall.withColor(AppColors.slate),
        ),
        AppSpacing.verticalSmBox,
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Games Played',
                    value: '24',
                    icon: Icons.golf_course,
                  ),
                ),
                AppSpacing.horizontalSmBox,
                Expanded(
                  child: StatCard(
                    label: 'Avg Score',
                    value: '87',
                    icon: Icons.analytics,
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMdBox,
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Best Round',
                    value: '79',
                    icon: Icons.star,
                  ),
                ),
                AppSpacing.horizontalSmBox,
                Expanded(
                  child: StatCard(
                    label: 'Handicap',
                    value: '12',
                    icon: Icons.trending_down,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
