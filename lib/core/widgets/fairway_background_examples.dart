import 'package:flutter/material.dart';
import 'fairway_background.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/typography.dart';
import 'app_button_enhanced.dart';

/// Examples showcasing FairwayBackground variants and usage patterns
///
/// Demonstrates how to apply atmospheric backgrounds to different screen types:
/// - Game list screens
/// - Profile screens
/// - Detail views
/// - Hero/landing screens
/// - Modal dialogs
class FairwayBackgroundExamples extends StatelessWidget {
  const FairwayBackgroundExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Background System Examples',
          style: AppTypography.headlineMedium,
        ),
        backgroundColor: AppColors.pure,
      ),
      body: ListView(
        children: [
          _buildExample(
            context,
            'Light Background',
            'Default for most screens - sand/green tones',
            () => _LightBackgroundExample(),
          ),
          _buildExample(
            context,
            'Dark Background',
            'Immersive experiences - deep greens',
            () => _DarkBackgroundExample(),
          ),
          _buildExample(
            context,
            'Sunset Background',
            'Hero moments - warm gradient',
            () => _SunsetBackgroundExample(),
          ),
          _buildExample(
            context,
            'Minimal Background',
            'Content-focused - subtle',
            () => _MinimalBackgroundExample(),
          ),
          _buildExample(
            context,
            'Game List Example',
            'Real-world usage pattern',
            () => _GameListExample(),
          ),
          _buildExample(
            context,
            'Profile Example',
            'User profile screen',
            () => _ProfileExample(),
          ),
        ],
      ),
    );
  }

  Widget _buildExample(
    BuildContext context,
    String title,
    String description,
    Widget Function() builder,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleLarge.withColor(AppColors.fairwayDark),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTypography.bodySmall.withColor(AppColors.slate),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cloud, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => builder()),
                );
              },
              child: builder(),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// VARIANT EXAMPLES
// ============================================================================

class _LightBackgroundExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FairwayBackgroundLight(
        showOrganic: true,
        showTexture: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Light Background',
                style: AppTypography.displayMedium
                    .withColor(AppColors.fairwayDark),
              ),
              const SizedBox(height: 16),
              Text(
                'Sand and green tones with organic overlays',
                style: AppTypography.bodyLarge.withColor(AppColors.slate),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppButtonEnhanced(
                text: 'Example Button',
                variant: AppButtonVariant.primary,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkBackgroundExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Dark Background',
                style: AppTypography.displayMedium.withColor(AppColors.pure),
              ),
              const SizedBox(height: 16),
              Text(
                'Deep greens for immersive experiences',
                style: AppTypography.bodyLarge
                    .withColor(AppColors.pure.withOpacity(0.8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppButtonEnhanced(
                text: 'Example Button',
                variant: AppButtonVariant.gradient,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SunsetBackgroundExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FairwayBackgroundSunset(
        showOrganic: true,
        showTexture: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sunset Background',
                style: AppTypography.displayMedium
                    .withColor(AppColors.fairwayDark),
              ),
              const SizedBox(height: 16),
              Text(
                'Warm gradient for special moments',
                style: AppTypography.bodyLarge.withColor(AppColors.slate),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppButtonEnhanced(
                text: 'Get Started',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                trailingIcon: Icons.arrow_forward,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MinimalBackgroundExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FairwayBackgroundMinimal(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Minimal Background',
                style: AppTypography.displayMedium
                    .withColor(AppColors.fairwayDark),
              ),
              const SizedBox(height: 16),
              Text(
                'Subtle when content should dominate',
                style: AppTypography.bodyLarge.withColor(AppColors.slate),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppButtonEnhanced(
                text: 'Secondary Action',
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// REAL-WORLD USAGE EXAMPLES
// ============================================================================

class _GameListExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FairwayBackgroundLight(
        showOrganic: true,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(
                'Available Games',
                style: AppTypography.headlineLarge,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _GameCard(index: index),
                  childCount: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: AppColors.sunsetGold,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.fairwayDark.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pebble Beach Round ${index + 1}',
            style: AppTypography.headlineMedium
                .withColor(AppColors.fairwayDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Saturday, Jan ${7 + index} at 9:00 AM',
            style: AppTypography.bodyMedium.withColor(AppColors.slate),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '3/4',
                style: AppTypography.monoMedium.withColor(AppColors.stone),
              ),
              const Spacer(),
              AppButtonEnhanced(
                text: 'Join',
                size: AppButtonSize.small,
                variant: AppButtonVariant.primary,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FairwayBackgroundSunset(
        showOrganic: true,
        child: SafeArea(
          child: Column(
            children: [
              // Header with gradient background showing through
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.pure,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.fairway,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ryan Andrews',
                      style: AppTypography.displaySmall
                          .withColor(AppColors.fairwayDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Handicap: 12',
                      style: AppTypography.bodyLarge.withColor(AppColors.slate),
                    ),
                  ],
                ),
              ),

              // Stats cards
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.pure.withOpacity(0.95),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(24.0),
                    children: [
                      Text(
                        'Recent Games',
                        style: AppTypography.titleLarge
                            .withColor(AppColors.fairwayDark),
                      ),
                      const SizedBox(height: 16),
                      _StatCard(label: 'Games Played', value: '24'),
                      _StatCard(label: 'Avg Score', value: '87'),
                      _StatCard(label: 'Best Round', value: '79'),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.withColor(AppColors.slate),
          ),
          Text(
            value,
            style: AppTypography.monoLarge.withColor(AppColors.fairwayDark),
          ),
        ],
      ),
    );
  }
}
