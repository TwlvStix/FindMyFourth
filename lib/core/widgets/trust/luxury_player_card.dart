import 'package:flutter/material.dart';

import '/backend/schema/trust_profile.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/trust/trust_avatar_ring.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Color tokens (card-local) — using design tokens
// ─────────────────────────────────────────────────────────────────────────────

final Color _textPrimary = AppColors.sand;
final Color _goldAccent = AppColors.goldLight;

// ─────────────────────────────────────────────────────────────────────────────
// LuxuryPlayerCard
// ─────────────────────────────────────────────────────────────────────────────

/// Premium player card with a colored trust-tier ring around the avatar
/// and a small corner badge icon indicating the player's trust tier.
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
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: _CardBody(
          name: widget.name,
          avatarUrl: widget.avatarUrl,
          tier: widget.tier,
          isFavorite: widget.isFavorite,
          status: widget.status,
          percentWidget: widget.percentWidget,
          trailingWidget: widget.trailingWidget,
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
    required this.tier,
    required this.isFavorite,
    required this.status,
    this.percentWidget,
    this.trailingWidget,
  });

  final String name;
  final String avatarUrl;
  final BadgeTier tier;
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
              // ── Avatar with trust ring ─────────────────────────────────
              TrustAvatarRing(
                imageUrl: avatarUrl,
                tier: tier,
              ),
              AppSpacing.horizontalSmBox,

              // ── Name + status ─────────────────────────────────────────
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

              // ── Match chip ───────────────────────────────────────────
              if (percentWidget != null) ...[
                AppSpacing.horizontalSmBox,
                percentWidget!,
              ],

              // ── Trailing action (checkmark / remove) ─────────────────
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
