import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/navigation/transition_standards.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/fairway_background.dart';
import '/utils/vibe_archetypes.dart';

/// Full-screen archetype reveal page with staged achievement unlock animation.
///
/// Displays the user's vibe archetype with a cinematic, phased reveal:
/// - Phase 1: Ambient glow bloom
/// - Phase 2: Icon appears with bounce
/// - Phase 3: Name and label reveal
/// - Phase 4: Description with animated divider
/// - Phase 5: CTAs fade in
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
  late final Animation<double> _dividerAnim;
  late final Animation<double> _descAnim;
  late final Animation<double> _ctaAnim;

  bool _hapticTriggered = false;

  /// Archetype-specific accent colors for glow and divider.
  static const Map<String, Color> _archetypeColors = {
    'The Grinder': Color(0xFFE05A3A),
    'The Shark': Color(0xFFE05A3A),
    'The Purist': Color(0xFF8BAAB5),
    'The Ghost': Color(0xFF7A8BA0),
    'The Tourist': Color(0xFF6BBF8A),
    'The Vibe King': Color(0xFFD4A017),
    'The Juggernaut': Color(0xFFE07B3A),
    'The Everyman': Color(0xFF6B8AFF),
    'The Hustler': Color(0xFF4CAF50),
    'The DJ': Color(0xFFD4A017),
    'The High Roller': Color(0xFFD4A017),
    'The Mayor': Color(0xFF6B8AFF),
    'The Warden': Color(0xFFB0B0B0),
  };

  Color _getAccentColor(String archetypeName) {
    return _archetypeColors[archetypeName] ?? AppColorsDark.gold;
  }

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _controller.forward();
  }

  void _initAnimations() {
    // Determine total duration based on reduced motion preference
    final baseDuration = const Duration(milliseconds: 3000);
    final totalDuration = ReducedMotionService.adjust(baseDuration);

    _controller = AnimationController(
      duration: totalDuration,
      vsync: this,
    );

    // Add listener to trigger haptic at icon reveal completion
    _controller.addListener(_checkHapticTrigger);

    // Phase intervals (normalized 0.0-1.0)
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

    // Phase 3: Label and Name (0.30 - 0.53) with stagger
    _labelAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 0.45, curve: MotionTokens.curveEnter),
    );
    _nameAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.38, 0.53, curve: MotionTokens.curveEnter),
    );

    // Phase 4: Divider and Description (0.53 - 0.77)
    _dividerAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.53, 0.65, curve: MotionTokens.curveEnter),
    );
    _descAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 0.77, curve: MotionTokens.curveEnter),
    );

    // Phase 5: CTAs (0.77 - 1.0)
    _ctaAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.77, 1.0, curve: MotionTokens.curveEnter),
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

  void _handleShare() {
    // Placeholder for share functionality
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final match = _getArchetypeMatch();
    final accentColor = _getAccentColor(match.name);

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: FairwayBackgroundDark(
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
                  _buildIconSection(accentColor),
                  SizedBox(height: AppSpacing.xl),
                  // Label and name
                  _buildNameSection(match),
                  SizedBox(height: AppSpacing.lg),
                  // Divider and description
                  _buildDescriptionSection(match, accentColor),
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
    );
  }

  Widget _buildIconSection(Color accentColor) {
    final shouldScale = ReducedMotionService.shouldScale;
    final iconScale = shouldScale ? _iconAnim.value : 1.0;
    final glowOpacity = _glowAnim.value * 0.30;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Ambient glow
        Opacity(
          opacity: _glowAnim.value,
          child: Transform.scale(
            scale: 0.8 + (_glowAnim.value * 0.2),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: glowOpacity),
                    accentColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Icon container with ring
        Semantics(
          label: 'Achievement unlocked',
          child: Transform.scale(
            scale: iconScale,
            child: Opacity(
              opacity: _iconAnim.value.clamp(0.0, 1.0),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColorsDark.navyLight,
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: AppIcon(
                    icon: AppPhosphorIcons.trophy,
                    size: AppIconSize.xxl,
                    color: AppColorsDark.gold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameSection(VibeArchetypeMatch match) {
    final labelOffset = Offset(0, 12 * (1 - _labelAnim.value));
    final nameOffset = Offset(0, 12 * (1 - _nameAnim.value));

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
                text: 'Share',
                variant: AppButtonVariant.ghostDark,
                size: AppButtonSize.large,
                leadingIcon: AppPhosphorIcons.share,
                onPressed: _handleShare,
                enabled: _ctaAnim.value > 0.5,
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
