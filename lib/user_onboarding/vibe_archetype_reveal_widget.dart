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
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/navigation/transition_standards.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/user_onboarding/components/archetype_reveal_icon.dart';
import '/user_onboarding/components/archetype_reveal_rarity.dart';
import '/user_onboarding/components/archetype_reveal_compatibility.dart';
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
  late final Animation<double> _glowAnim;
  late final Animation<double> _iconAnim;
  late final Animation<double> _labelAnim;
  late final Animation<double> _nameAnim;
  late final Animation<double> _taglineAnim;
  late final Animation<double> _rarityAnim;
  late final Animation<double> _dividerAnim;
  late final Animation<double> _descAnim;
  late final Animation<double> _compatibilityAnim;
  late final Animation<double> _ctaAnim;

  final GlobalKey _shareCardKey = GlobalKey();
  bool _hapticTriggered = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _controller.forward();
  }

  void _initAnimations() {
    // Extended duration: 3000ms → 4500ms
    final baseDuration = const Duration(milliseconds: 4500);
    final totalDuration = ReducedMotionService.adjust(baseDuration);

    _controller = AnimationController(
      duration: totalDuration,
      vsync: this,
    );

    // Add listener to trigger haptic at icon reveal completion
    _controller.addListener(_checkHapticTrigger);

    // Phase intervals (normalized 0.0-1.0) - Updated for 4.5s sequence

    // Phase 1: Glow (0.0 - 0.10)
    _glowAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.10, curve: MotionTokens.curveEnter),
    );

    // Phase 2: Icon (0.10 - 0.30) with elastic bounce
    _iconAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.10, 0.30, curve: Curves.elasticOut),
    );

    // Phase 3a: Label (0.30 - 0.45)
    _labelAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 0.45, curve: MotionTokens.curveEnter),
    );

    // Phase 3b: Name (0.38 - 0.53)
    _nameAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.38, 0.53, curve: MotionTokens.curveEnter),
    );

    // Phase 3c: Tagline (0.50 - 0.58) - NEW
    _taglineAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 0.58, curve: MotionTokens.curveEnter),
    );

    // Phase 4: Rarity (0.55 - 0.65) - NEW
    _rarityAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.65, curve: MotionTokens.curveEnter),
    );

    // Phase 5a: Divider (0.60 - 0.70)
    _dividerAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 0.70, curve: MotionTokens.curveEnter),
    );

    // Phase 5b: Description (0.65 - 0.77)
    _descAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.77, curve: MotionTokens.curveEnter),
    );

    // Phase 6: Compatibility (0.72 - 0.82) - NEW
    _compatibilityAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.72, 0.82, curve: MotionTokens.curveEnter),
    );

    // Phase 7: CTAs (0.82 - 1.0)
    _ctaAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.82, 1.0, curve: MotionTokens.curveEnter),
    );
  }

  void _checkHapticTrigger() {
    // Trigger haptic when icon animation completes (~30% progress)
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

    // Extract match from route extra
    if (extra is Map<String, dynamic>) {
      final match = extra['match'];
      if (match is VibeArchetypeMatch) {
        return match;
      }
    }

    // Fallback: should not happen in normal flow
    return VibeArchetypes.everyman.withScore(100);
  }

  void _handleContinue() {
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
      // Capture the share card
      final boundary = _shareCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        AppLog.d('❌ ArchetypeReveal: Share card boundary not found');
        return;
      }

      // Render at 3x for high quality
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        AppLog.d('❌ ArchetypeReveal: Failed to convert image to bytes');
        return;
      }

      // Write to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/vibe_archetype.png');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      // Share
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

    // Compatibility uses base archetype for Wardens
    final compatibilityName = VibeArchetypeMetadata.compatibilityNameFor(match);
    final bestWith = VibeArchetypeMetadata.bestWithFor(compatibilityName);
    final watchOutFor = VibeArchetypeMetadata.watchOutForName(compatibilityName);

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: Stack(
        children: [
          // Main content
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
                      // Icon with glow
                      ArchetypeRevealIcon(
                        accentColor: accentColor,
                        icon: icon,
                        glowValue: _glowAnim.value,
                        iconValue: ReducedMotionService.shouldScale
                            ? _iconAnim.value
                            : 1.0,
                      ),
                      SizedBox(height: AppSpacing.xl),
                      // Label, name, and tagline
                      _buildNameSection(match, tagline, accentColor),
                      SizedBox(height: AppSpacing.sm),
                      // Rarity stat
                      ArchetypeRevealRarity(
                        rarityLabel: rarity,
                        percentage: percentage,
                        accentColor: accentColor,
                        animationValue: _rarityAnim.value,
                      ),
                      SizedBox(height: AppSpacing.lg),
                      // Divider and description
                      _buildDescriptionSection(match, accentColor),
                      SizedBox(height: AppSpacing.md),
                      // Compatibility teaser
                      ArchetypeRevealCompatibility(
                        bestWith: bestWith,
                        watchOutFor: watchOutFor,
                        animationValue: _compatibilityAnim.value,
                      ),
                      const Spacer(flex: 3),
                      // CTAs
                      _buildCTASection(),
                      SizedBox(height: AppSpacing.lg),
                    ],
                  );
                },
              ),
            ),
          ),
          // Offscreen share card for capture
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

  Widget _buildNameSection(
    VibeArchetypeMatch match,
    String tagline,
    Color accentColor,
  ) {
    final labelOffset = Offset(0, 12 * (1 - _labelAnim.value));
    final nameOffset = Offset(0, 12 * (1 - _nameAnim.value));
    final taglineOffset = Offset(0, 8 * (1 - _taglineAnim.value));

    return Column(
      children: [
        // "Your vibe style" label
        Transform.translate(
          offset: labelOffset,
          child: Opacity(
            opacity: _labelAnim.value,
            child: Text(
              'Your vibe style',
              style: AppTypography.labelSmall.copyWith(
                color: AppColorsDark.textMuted,
                letterSpacing: AppTypography.letterSpacingWide,
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.xxs),
        // Archetype name
        Transform.translate(
          offset: nameOffset,
          child: Opacity(
            opacity: _nameAnim.value,
            child: Semantics(
              header: true,
              child: Text(
                match.name,
                style: AppTypography.displaySmall.copyWith(
                  color: AppColorsDark.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        // Warden base archetype subtitle
        if (match.isWarden && match.baseLabel != null) ...[
          SizedBox(height: AppSpacing.xxs),
          Transform.translate(
            offset: nameOffset,
            child: Opacity(
              opacity: _nameAnim.value,
              child: Text(
                match.baseLabel!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColorsDark.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
        SizedBox(height: AppSpacing.sm),
        // Tagline
        Transform.translate(
          offset: taglineOffset,
          child: Opacity(
            opacity: _taglineAnim.value,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                tagline,
                style: AppTypography.titleSmall.copyWith(
                  color: accentColor,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(VibeArchetypeMatch match, Color accentColor) {
    final descOffset = Offset(0, 12 * (1 - _descAnim.value));
    final dividerWidth = 200.0 * _dividerAnim.value;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          // Animated divider
          Opacity(
            opacity: _dividerAnim.value,
            child: Container(
              width: dividerWidth,
              height: 1,
              color: accentColor.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          // Description text
          Transform.translate(
            offset: descOffset,
            child: Opacity(
              opacity: _descAnim.value,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Text(
                  match.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColorsDark.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection() {
    return Opacity(
      opacity: _ctaAnim.value,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: AppButtonEnhanced(
                text: _isSharing ? 'Sharing...' : 'Share',
                variant: AppButtonVariant.ghostDark,
                size: AppButtonSize.large,
                leadingIcon: AppPhosphorIcons.share,
                onPressed: _handleShare,
                enabled: _ctaAnim.value > 0.5 && !_isSharing,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButtonEnhanced(
                text: 'Continue',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                leadingIcon: AppPhosphorIcons.arrowRight,
                onPressed: _handleContinue,
                enabled: _ctaAnim.value > 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
