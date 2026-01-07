import 'package:flutter/material.dart';
import 'app_button_enhanced.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/typography.dart';

/// Examples and showcase of AppButtonEnhanced variants
///
/// This file demonstrates all button variants, sizes, and states.
/// Use this as a reference or run as a demo screen.
class AppButtonExamples extends StatefulWidget {
  const AppButtonExamples({super.key});

  @override
  State<AppButtonExamples> createState() => _AppButtonExamplesState();
}

class _AppButtonExamplesState extends State<AppButtonExamples> {
  bool _isLoading = false;

  void _simulateLoading() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        title: Text(
          'Button System Examples',
          style: AppTypography.headlineMedium,
        ),
        backgroundColor: AppColors.pure,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Variants',
              'Different visual styles for different purposes',
              _buildVariantExamples(),
            ),
            const SizedBox(height: 40),
            _buildSection(
              'Sizes',
              'Four size presets from compact to hero',
              _buildSizeExamples(),
            ),
            const SizedBox(height: 40),
            _buildSection(
              'With Icons',
              'Leading and trailing icon support',
              _buildIconExamples(),
            ),
            const SizedBox(height: 40),
            _buildSection(
              'States',
              'Loading, disabled, and normal states',
              _buildStateExamples(),
            ),
            const SizedBox(height: 40),
            _buildSection(
              'Full Width',
              'Buttons that expand to container width',
              _buildFullWidthExamples(),
            ),
            const SizedBox(height: 40),
            _buildSection(
              'Real World Examples',
              'Common usage patterns',
              _buildRealWorldExamples(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String description, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.headlineLarge.withColor(AppColors.fairwayDark),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: AppTypography.bodyMedium.withColor(AppColors.slate),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.pure,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.fairwayDark.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: content,
        ),
      ],
    );
  }

  Widget _buildVariantExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVariantRow(
          'Primary',
          'Main actions, CTAs',
          AppButtonVariant.primary,
        ),
        const SizedBox(height: 16),
        _buildVariantRow(
          'Secondary',
          'Secondary actions, cancel',
          AppButtonVariant.secondary,
        ),
        const SizedBox(height: 16),
        _buildVariantRow(
          'Ghost',
          'Tertiary, minimal actions',
          AppButtonVariant.ghost,
        ),
        const SizedBox(height: 16),
        _buildVariantRow(
          'Gradient',
          'Special CTAs, premium',
          AppButtonVariant.gradient,
        ),
      ],
    );
  }

  Widget _buildVariantRow(String name, String description, AppButtonVariant variant) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTypography.titleMedium.withColor(AppColors.fairwayDark),
              ),
              Text(
                description,
                style: AppTypography.bodySmall.withColor(AppColors.stone),
              ),
            ],
          ),
        ),
        AppButtonEnhanced(
          text: 'Example',
          variant: variant,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSizeExamples() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        AppButtonEnhanced(
          text: 'Small',
          size: AppButtonSize.small,
          variant: AppButtonVariant.primary,
          onPressed: () {},
        ),
        AppButtonEnhanced(
          text: 'Medium',
          size: AppButtonSize.medium,
          variant: AppButtonVariant.primary,
          onPressed: () {},
        ),
        AppButtonEnhanced(
          text: 'Large',
          size: AppButtonSize.large,
          variant: AppButtonVariant.primary,
          onPressed: () {},
        ),
        AppButtonEnhanced(
          text: 'Extra Large',
          size: AppButtonSize.xlarge,
          variant: AppButtonVariant.primary,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildIconExamples() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        AppButtonEnhanced(
          text: 'Add Player',
          leadingIcon: Icons.person_add,
          variant: AppButtonVariant.primary,
          onPressed: () {},
        ),
        AppButtonEnhanced(
          text: 'Continue',
          trailingIcon: Icons.arrow_forward,
          variant: AppButtonVariant.secondary,
          onPressed: () {},
        ),
        AppButtonEnhanced(
          text: 'Share Game',
          leadingIcon: Icons.share,
          trailingIcon: Icons.open_in_new,
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.large,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildStateExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppButtonEnhanced(
              text: 'Normal',
              variant: AppButtonVariant.primary,
              onPressed: () {},
            ),
            const SizedBox(width: 12),
            AppButtonEnhanced(
              text: 'Loading...',
              variant: AppButtonVariant.primary,
              isLoading: true,
              onPressed: () {},
            ),
            const SizedBox(width: 12),
            AppButtonEnhanced(
              text: 'Disabled',
              variant: AppButtonVariant.primary,
              enabled: false,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppButtonEnhanced(
          text: _isLoading ? 'Joining Game...' : 'Simulate Loading',
          variant: AppButtonVariant.gradient,
          size: AppButtonSize.large,
          isLoading: _isLoading,
          leadingIcon: _isLoading ? null : Icons.play_arrow,
          onPressed: _simulateLoading,
        ),
      ],
    );
  }

  Widget _buildFullWidthExamples() {
    return Column(
      children: [
        AppButtonEnhanced(
          text: 'Full Width Primary',
          fullWidth: true,
          variant: AppButtonVariant.primary,
          size: AppButtonSize.large,
          onPressed: () {},
        ),
        const SizedBox(height: 12),
        AppButtonEnhanced(
          text: 'Full Width Gradient',
          fullWidth: true,
          variant: AppButtonVariant.gradient,
          trailingIcon: Icons.arrow_forward,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildRealWorldExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Form actions
        Text(
          'Form Actions',
          style: AppTypography.titleMedium.withColor(AppColors.fairwayDark),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppButtonEnhanced(
              text: 'Cancel',
              variant: AppButtonVariant.ghost,
              onPressed: () {},
            ),
            AppButtonEnhanced(
              text: 'Save Game',
              variant: AppButtonVariant.primary,
              leadingIcon: Icons.save,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Game card actions
        Text(
          'Game Card Actions',
          style: AppTypography.titleMedium.withColor(AppColors.fairwayDark),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButtonEnhanced(
                text: 'View Details',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.small,
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButtonEnhanced(
                text: 'Join Game',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.small,
                onPressed: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Hero CTA
        Text(
          'Hero CTA',
          style: AppTypography.titleMedium.withColor(AppColors.fairwayDark),
        ),
        const SizedBox(height: 12),
        AppButtonEnhanced(
          text: 'Find Your Fourth Player',
          variant: AppButtonVariant.gradient,
          size: AppButtonSize.xlarge,
          fullWidth: true,
          trailingIcon: Icons.arrow_forward,
          onPressed: () {},
        ),
      ],
    );
  }
}
