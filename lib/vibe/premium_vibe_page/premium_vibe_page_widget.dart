import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/navigation/app_router.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/premium_back_button.dart';
import '/providers/chat_provider.dart';
import '/services/vibe_match_explanation.dart';
import '/services/vibe_verdict_generator.dart';
import '/vibe/premium_vibe_page/components/archetype_pairing_card.dart';
import '/vibe/premium_vibe_page/components/vibe_full_breakdown_section.dart';
import '/vibe/premium_vibe_page/components/vibe_hero_section.dart';
import '/vibe/premium_vibe_page/components/vibe_strengths_list.dart';
import '/vibe/premium_vibe_page/components/vibe_watch_points_list.dart';
import '/vibe/premium_vibe_page/premium_vibe_page_data.dart';

/// Premium Vibe Page - Full-page vibe match analysis.
///
/// A mobile-first, single-scroll experience showing how two golfers vibe together.
/// Follows "caddie's scouting report" design: Verdict → Identity → Comfort → Tension → Evidence → Action.
class PremiumVibePageWidget extends StatefulWidget {
  const PremiumVibePageWidget({
    super.key,
    required this.userId,
    required this.data,
  });

  /// The matched user's ID (from route parameter)
  final String userId;

  /// Complete data for rendering the page
  final PremiumVibePageData data;

  @override
  State<PremiumVibePageWidget> createState() => _PremiumVibePageWidgetState();
}

class _PremiumVibePageWidgetState extends State<PremiumVibePageWidget> {
  /// State for expand/collapse of full breakdown section
  bool _isBreakdownExpanded = false;

  void _toggleBreakdown() {
    setState(() {
      _isBreakdownExpanded = !_isBreakdownExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    // Generate verdict sentence
    final verdict = generateVibeVerdict(data.matchResult, data.explanation);

    // Filter aligned categories (for strengths section)
    final alignedCategories = data.explanation.categories
        .where((c) => c.statusBadge == VibeStatusBadge.aligned)
        .toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));

    // Filter watch points (tension areas)
    final watchPoints = data.explanation.categories
        .where(
          (c) =>
              c.statusBadge == VibeStatusBadge.watchPoint ||
              c.statusBadge == VibeStatusBadge.dealbreakerRisk,
        )
        .toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        leading: PremiumBackButton(
          onTap: () => context.pop(),
        ),
        title: Text(
          data.userName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero: Fit score + verdict
            VibeHeroSection(
              fitScore: data.matchResult.myFitPercent.round(),
              verdict: verdict,
            ),

            const SizedBox(height: AppSpacing.md),

            // Archetype pairing
            ArchetypePairingCard(
              myArchetype: data.myArchetype,
              theirArchetype: data.theirArchetype,
            ),

            const SizedBox(height: AppSpacing.md),

            // Strengths (aligned categories)
            VibeStrengthsList(
              alignedCategories: alignedCategories,
            ),

            const SizedBox(height: AppSpacing.md),

            // Watch points (tension areas)
            VibeWatchPointsList(
              watchPoints: watchPoints,
              explanation: data.explanation,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Divider(
                color: AppColors.navyLight,
                thickness: 1,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Full breakdown (collapsible)
            VibeFullBreakdownSection(
              categories: data.explanation.categories,
              myProfile: data.myProfile,
              theirProfile: data.theirProfile,
              isExpanded: _isBreakdownExpanded,
              onToggle: _toggleBreakdown,
            ),

            const SizedBox(height: AppSpacing.xl),

            // CTA: Message button
            _buildCTA(context, data),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildCTA(BuildContext context, PremiumVibePageData data) {
    // Extract first name from full name
    final firstName = data.userName.split(' ').first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppButtonEnhanced(
        text: 'Message $firstName',
        variant: AppButtonVariant.primary,
        size: AppButtonSize.large,
        fullWidth: true,
        leadingIcon: AppPhosphorIcons.chat,
        onPressed: () => _openChatWithUser(context, data.userRef),
      ),
    );
  }

  Future<void> _openChatWithUser(
      BuildContext context, DocumentReference userRef) async {
    final currentUserRef = currentUserReference;
    if (currentUserRef == null) {
      return;
    }

    try {
      final chatRef = await context.read<ChatProvider>().createOrGetDirectChat(
            currentUid: currentUserRef.id,
            otherUid: userRef.id,
          );

      if (!mounted) return;

      context.pushNamed(
        'ChatDetails',
        pathParameters: {
          'chatId': chatRef.id,
        },
        extra: <String, dynamic>{
          kTransitionInfoKey: TransitionStandards.detailTransition,
        },
      );
    } catch (error, stackTrace) {
      if (!mounted) return;

      context
          .read<ChatProvider>()
          .logError('createOrGetDirectChat failed', error, stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start chat. Please try again.'),
        ),
      );
    }
  }
}
