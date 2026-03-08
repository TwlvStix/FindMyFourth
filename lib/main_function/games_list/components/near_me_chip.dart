import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/motion/motion_tokens.dart';
import '/providers/provider_extensions.dart';

/// "Near Me" toggle chip for the games list.
///
/// Only shown when user has a default location (home course or hometown).
/// Toggles geo-filtering on/off and persists the preference to the user profile.
class NearMeChip extends StatefulWidget {
  const NearMeChip({super.key});

  @override
  State<NearMeChip> createState() => _NearMeChipState();
}

class _NearMeChipState extends State<NearMeChip> {
  bool _isPressed = false;

  Future<void> _handleTap() async {
    HapticFeedback.lightImpact();

    final geoFilter = context.geoFilterProvider;
    final userProvider = context.userProvider;

    final newValue = !geoFilter.isEnabled;
    geoFilter.setEnabled(newValue);

    // Persist to user profile (fire-and-forget)
    userProvider.updateProfile({'near_me_enabled': newValue});
  }

  @override
  Widget build(BuildContext context) {
    final hasDefaultLocation = context.selectUser((p) => p.hasDefaultLocation);
    final isEnabled = context.selectGeoFilter((p) => p.isEnabled);

    // Don't show if user has no location configured
    if (!hasDefaultLocation) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: MotionTokens.microInteraction,
        curve: MotionTokens.curveEnter,
        transform: _isPressed
            ? (Matrix4.identity()
              ..setEntry(0, 0, 0.96)
              ..setEntry(1, 1, 0.96))
            : Matrix4.identity(),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.green : AppColors.glassSurface,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: isEnabled ? AppColors.green : AppColors.glassBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon: AppPhosphorIcons.homeCourse,
              size: AppIconSize.sm,
              color: isEnabled ? AppColors.pure : AppColors.whiteStrong,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              'Near Me',
              style: AppTypography.labelMedium.copyWith(
                color: isEnabled ? AppColors.pure : AppColors.whiteStrong,
                fontWeight: isEnabled ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
