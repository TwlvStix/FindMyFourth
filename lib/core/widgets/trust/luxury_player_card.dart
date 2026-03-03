import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '/backend/schema/trust_profile.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/trust/trust_badge_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Color tokens (card-local) — using design tokens
// ─────────────────────────────────────────────────────────────────────────────

final Color _textPrimary = AppColors.sand;
final Color _textMuted = AppColors.glassTextTertiary;
final Color _goldAccent = AppColors.goldLight;

// ─────────────────────────────────────────────────────────────────────────────
// LuxuryPlayerCard
// ─────────────────────────────────────────────────────────────────────────────

/// Premium player card with a hanging pendant badge for trust tier display.
///
/// The pendant sits flush on the card's top edge and hangs downward,
/// using Fraunces serif at tight letter spacing for a luxury feel.
/// The card surface is tier-agnostic — only the pendant color + label swap.
class LuxuryPlayerCard extends StatefulWidget {
  const LuxuryPlayerCard({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.tier,
    this.isFavorite = false,
    this.status = 'Ready',
    this.percentWidget,
    this.trailingWidget,
    this.onTap,
  });

  final String name;
  final String avatarUrl;
  final BadgeTier tier;
  final bool isFavorite;
  final String status;

  /// The percentage/match chip widget (PlayerMatchChip) — passed in from the
  /// parent so this widget stays decoupled from vibe/match logic.
  final Widget? percentWidget;

  /// The trailing action widget (checkmark icon or remove button).
  final Widget? trailingWidget;

  final VoidCallback? onTap;

  @override
  State<LuxuryPlayerCard> createState() => _LuxuryPlayerCardState();
}

class _LuxuryPlayerCardState extends State<LuxuryPlayerCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tierStyle = BadgeTierStyle.fromTier(widget.tier);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Card body ───────────────────────────────────────────────────
            _CardBody(
              name: widget.name,
              avatarUrl: widget.avatarUrl,
              isFavorite: widget.isFavorite,
              status: widget.status,
              percentWidget: widget.percentWidget,
              trailingWidget: widget.trailingWidget,
            ),

            // ── Pendant badge ────────────────────────────────────────────────
            Positioned(
              top: -1,
              right: 24,
              child: _PendantBadge(tierStyle: tierStyle),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card body — tier-agnostic surface
// ─────────────────────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.name,
    required this.avatarUrl,
    required this.isFavorite,
    required this.status,
    this.percentWidget,
    this.trailingWidget,
  });

  final String name;
  final String avatarUrl;
  final bool isFavorite;
  final String status;
  final Widget? percentWidget;
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg - 2),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: Border.all(
          color: AppColors.navyLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // ── Avatar ───────────────────────────────────────────────────
              _Avatar(url: avatarUrl),
              AppSpacing.horizontalMdBox,

              // ── Name + status ─────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            // TODO: fontSize 15 has no exact token match; using bodySmall + copyWith
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 15,
                              fontWeight: AppTypography.semiBold,
                              color: _textPrimary,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isFavorite) ...[
                          AppSpacing.horizontalXxs,
                          AppIcon(
                            icon: AppPhosphorIcons.starFill,
                            color: _goldAccent,
                            size: AppIconSize.xs,
                          ),
                        ],
                      ],
                    ),
                    AppSpacing.verticalXxs,
                    Text(
                      status,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Match chip ───────────────────────────────────────────────
              if (percentWidget != null) ...[
                AppSpacing.horizontalSmBox,
                percentWidget!,
              ],

              // ── Trailing action (checkmark / remove) ─────────────────────
              if (trailingWidget != null) ...[
                AppSpacing.horizontalSmBox,
                trailingWidget!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.navyLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _AvatarPlaceholder(),
              )
            : const _AvatarPlaceholder(),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.whiteSubtle,
      child: AppIcon(icon: AppPhosphorIcons.profile, color: _textMuted, size: AppIconSize.md),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pendant badge
// ─────────────────────────────────────────────────────────────────────────────

class _PendantBadge extends StatelessWidget {
  const _PendantBadge({required this.tierStyle});

  final BadgeTierStyle tierStyle;

  @override
  Widget build(BuildContext context) {
    // NEW tier gets subtle treatment; earned tiers get full pendant
    final isNewTier = tierStyle.label == 'NEW';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs - 2),
      decoration: BoxDecoration(
        // Match card background for integration; solid for earned tiers
        color: isNewTier
            ? AppColors.navy.withValues(alpha: 0.5)
            : AppColors.navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppBorderRadius.sm),
          bottomRight: Radius.circular(AppBorderRadius.sm),
        ),
        border: Border(
          left: BorderSide(color: tierStyle.borderColor, width: 1),
          right: BorderSide(color: tierStyle.borderColor, width: 1),
          bottom: BorderSide(color: tierStyle.borderColor, width: 1),
        ),
        // Remove shadow for NEW tier to reduce visual weight
        boxShadow: isNewTier ? null : [AppElevation.lg],
      ),
      child: Text(
        tierStyle.label,
        // Pendant badge: uses Fraunces with tight letter-spacing for luxury feel
        style: AppTypography.headlineMedium.copyWith(
          fontSize: 10,
          letterSpacing: 2.5,
          color: tierStyle.accent,
          height: 1.0,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
        .slideY(begin: -0.3, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}
