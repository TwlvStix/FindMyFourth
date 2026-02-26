import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/models/game.dart';
import '/utils/availability_text_helper.dart';

/// Displays flexible game availability as a compact single-line summary.
///
/// Optimized for scanning in list contexts:
/// - Green gradient calendar icon (36x36)
/// - Single line: week hint · time · spots (e.g., "Next Week · Afternoon · 3 spots open")
///
/// This widget is non-interactive. For tap-to-expand behavior with full details,
/// use [FlexibleGameInfoAccordion] instead.
class FlexibleAvailabilitySummary extends StatelessWidget {
  const FlexibleAvailabilitySummary({
    super.key,
    required this.game,
    this.showSpots = true,
    this.showIcon = true,
  });

  final Game game;

  /// Whether to show spots remaining.
  final bool showSpots;

  /// Whether to show the calendar icon. Set to false if the parent
  /// already provides an icon container.
  final bool showIcon;

  /// Returns just the relative week hint (e.g., "Next Week") without date range.
  String get _weekHint => getWeekHintOnly(game);

  String get _timeSummary =>
      formatTimeOfDay(game.flexibleTimeOfDay, joiner: ' & ') ?? 'Anytime';

  int get _spotsLeft =>
      game.maxPlayers -
      (game.joinedPlayers.length + game.guestPlayers.length);

  String get _spotsLabel => _spotsLeft <= 0 ? 'Full' : '$_spotsLeft spots open';

  String get _summaryText {
    if (showSpots) {
      return '$_weekHint · $_timeSummary · $_spotsLabel';
    }
    return '$_weekHint · $_timeSummary';
  }

  @override
  Widget build(BuildContext context) {
    if (!game.isFlexible) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (showIcon) ...[
          AppIcon(
            icon: AppPhosphorIcons.calendarCheck,
            color: AppColors.textSecondary,
            size: AppIconSize.listItem,
          ),
          SizedBox(width: AppSpacing.sm),
        ],
        // Single line summary
        Expanded(
          child: Text(
            _summaryText,
            style: AppTypography.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
