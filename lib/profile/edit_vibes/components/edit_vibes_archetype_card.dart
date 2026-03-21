import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_patterns/premium_ui_patterns.dart';
import '/core/motion/motion_tokens.dart';
import '/core/widgets/app_icon.dart';
import '/models/vibe_profile.dart';
import '/utils/vibe_archetypes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditVibesArchetypeCard extends StatefulWidget {
  const EditVibesArchetypeCard({super.key, required this.profile});

  final VibeProfile profile;

  @override
  State<EditVibesArchetypeCard> createState() => _EditVibesArchetypeCardState();
}

class _EditVibesArchetypeCardState extends State<EditVibesArchetypeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final archetypeMatch = VibeArchetypes.classifyProfile(widget.profile);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _expanded = !_expanded);
      },
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        opacity: 0.25,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColorsDark.navyLight,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(
                  color: AppColorsDark.glassBorder,
                ),
              ),
              child: Center(
                child: AppIcon(
                  icon: AppPhosphorIcons.trophy,
                  size: AppIconSize.md,
                  color: AppColorsDark.gold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your vibe style',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColorsDark.textMuted,
                      letterSpacing: AppTypography.letterSpacingWide,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    archetypeMatch.name,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  AnimatedCrossFade(
                    duration: MotionTokens.microInteraction,
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Text(
                      archetypeMatch.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColorsDark.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondChild: Text(
                      archetypeMatch.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColorsDark.textSecondary,
                      ),
                    ),
                  ),
                  if (!_expanded) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tap to read more',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColorsDark.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
