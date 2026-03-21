import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/motion/reduced_motion.dart';
import '/core/navigation/transition_standards.dart';
import '/core/utils/app_log.dart';
import '/providers/provider_extensions.dart';
import '/core/widgets/fairway_background.dart';
import '/user_onboarding/components/archetype_reveal_animations.dart';
import '/user_onboarding/components/archetype_reveal_compatibility.dart';
import '/user_onboarding/components/archetype_reveal_cta.dart';
import '/user_onboarding/components/archetype_reveal_description.dart';
import '/user_onboarding/components/archetype_reveal_icon.dart';
import '/user_onboarding/components/archetype_reveal_name.dart';
import '/user_onboarding/components/archetype_reveal_rarity.dart';
import '/user_onboarding/components/archetype_share_card.dart';
import '/utils/vibe_archetypes.dart';
import '/utils/vibe_archetype_metadata.dart';

/// Full-screen archetype reveal page with staged achievement unlock animation.
///
/// Displays the user's vibe archetype with a cinematic, phased reveal:
/// - Phase 1: Ambient glow bloom
/// - Phase 2: Icon appears with bounce
/// - Phase 3: Name, label, and tagline reveal
/// - Phase 4: Rarity stat
/// - Phase 5: Divider and description
/// - Phase 6: Compatibility teaser
/// - Phase 7: CTAs fade in
class VibeArchetypeRevealWidget extends StatefulWidget {
  const VibeArchetypeRevealWidget({super.key});

  static String routeName = 'VibeArchetypeReveal';
  static String routePath = '/vibeArchetypeReveal';

  @override
  State<VibeArchetypeRevealWidget> createState() =>
      _VibeArchetypeRevealWidgetState();
}

class _VibeArchetypeRevealWidgetState extends State<VibeArchetypeRevealWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final ArchetypeRevealAnimations _anims;

  final GlobalKey _shareCardKey = GlobalKey();
  bool _hapticTriggered = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _controller = ArchetypeRevealAnimations.createController(this);
    _anims = ArchetypeRevealAnimations(controller: _controller);
    _controller.addListener(_checkHapticTrigger);
    _controller.forward();
  }

  void _checkHapticTrigger() {
    if (!_hapticTriggered && _controller.value >= 0.30) {
      _hapticTriggered = true;
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkHapticTrigger);
    _controller.dispose();
    super.dispose();
  }

  VibeArchetypeMatch _getArchetypeMatch() {
    final state = GoRouterState.of(context);
    final extra = state.extra;

    if (extra is Map<String, dynamic>) {
      final match = extra['match'];
      if (match is VibeArchetypeMatch) {
        return match;
      }
    }

    return VibeArchetypes.everyman.withScore(100);
  }

  Future<void> _handleContinue() async {
    try {
      await context.userProvider.markOnboardingCompleted();
    } catch (e) {
      AppLog.d('❌ VibeArchetypeReveal: Failed to mark onboarding completed: $e');
    }

    if (!mounted) return;

    final state = GoRouterState.of(context);
    final nextRoute = state.uri.queryParameters['next'];

    if (nextRoute != null && nextRoute.isNotEmpty) {
      context.goWithTransition(
        nextRoute,
        transition: TransitionStandards.modalTransition,
      );
    } else {
      context.goWithTransition(
        'MainProfile',
        transition: TransitionStandards.modalTransition,
      );
    }
  }

  Future<void> _handleShare() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);
    HapticFeedback.lightImpact();

    try {
      final boundary = _shareCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        AppLog.d('❌ ArchetypeReveal: Share card boundary not found');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        AppLog.d('❌ ArchetypeReveal: Failed to convert image to bytes');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/vibe_archetype.png');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'I\'m ${_getArchetypeMatch().name}! What\'s your golf vibe?',
      );

      AppLog.d('✅ ArchetypeReveal: Share completed');
    } catch (e) {
      AppLog.d('❌ ArchetypeReveal: Share failed - $e');
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = _getArchetypeMatch();
    final accentColor = VibeArchetypeMetadata.colorFor(match.name);
    final icon = VibeArchetypeMetadata.iconFor(match.name);
    final tagline = VibeArchetypeMetadata.taglineFor(match.name);
    final rarity = VibeArchetypeMetadata.rarityFor(match.name);
    final percentage = VibeArchetypeMetadata.distributionFor(match.name);

    final compatibilityName = VibeArchetypeMetadata.compatibilityNameFor(match);
    final bestWith = VibeArchetypeMetadata.bestWithFor(compatibilityName);
    final watchOutFor = VibeArchetypeMetadata.watchOutForName(compatibilityName);

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: Stack(
        children: [
          FairwayBackgroundDark(
            showOrganic: true,
            showTexture: true,
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Column(
                    children: [
                      const Spacer(flex: 2),
                      ArchetypeRevealIcon(
                        accentColor: accentColor,
                        icon: icon,
                        glowValue: _anims.glow.value,
                        iconValue: ReducedMotionService.shouldScale
                            ? _anims.icon.value
                            : 1.0,
                      ),
                      SizedBox(height: AppSpacing.xl),
                      ArchetypeRevealName(
                        match: match,
                        tagline: tagline,
                        accentColor: accentColor,
                        labelValue: _anims.label.value,
                        nameValue: _anims.name.value,
                        taglineValue: _anims.tagline.value,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      ArchetypeRevealRarity(
                        rarityLabel: rarity,
                        percentage: percentage,
                        accentColor: accentColor,
                        animationValue: _anims.rarity.value,
                      ),
                      SizedBox(height: AppSpacing.lg),
                      ArchetypeRevealDescription(
                        description: match.description,
                        accentColor: accentColor,
                        dividerValue: _anims.divider.value,
                        descriptionValue: _anims.desc.value,
                      ),
                      SizedBox(height: AppSpacing.md),
                      ArchetypeRevealCompatibility(
                        bestWith: bestWith,
                        watchOutFor: watchOutFor,
                        animationValue: _anims.compatibility.value,
                      ),
                      const Spacer(flex: 3),
                      ArchetypeRevealCTA(
                        animationValue: _anims.cta.value,
                        isSharing: _isSharing,
                        onShare: _handleShare,
                        onContinue: _handleContinue,
                      ),
                      SizedBox(height: AppSpacing.lg),
                    ],
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: -2000,
            top: 0,
            child: RepaintBoundary(
              key: _shareCardKey,
              child: ArchetypeShareCard(
                match: match,
                tagline: tagline,
                rarity: rarity,
                percentage: percentage,
                accentColor: accentColor,
                icon: icon,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
