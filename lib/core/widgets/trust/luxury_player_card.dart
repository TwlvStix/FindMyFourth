import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '/backend/schema/trust_profile.dart';
import '/core/design_tokens/colors.dart';
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
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
              const SizedBox(width: 14),

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
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isFavorite) ...[
                          const SizedBox(width: 5),
                          Icon(
                            Icons.star_rounded,
                            color: _goldAccent,
                            size: 15,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.gold,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Match chip ───────────────────────────────────────────────
              if (percentWidget != null) ...[
                const SizedBox(width: 10),
                percentWidget!,
              ],

              // ── Trailing action (checkmark / remove) ─────────────────────
              if (trailingWidget != null) ...[
                const SizedBox(width: 10),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.5),
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
      color: Colors.white.withValues(alpha: 0.04),
      child: Icon(Icons.person_rounded, color: _textMuted, size: 26),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: Border(
          left: BorderSide(color: tierStyle.borderColor, width: 1),
          right: BorderSide(color: tierStyle.borderColor, width: 1),
          bottom: BorderSide(color: tierStyle.borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlayDark,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        tierStyle.label,
        style: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 10,
          fontWeight: FontWeight.w600,
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
