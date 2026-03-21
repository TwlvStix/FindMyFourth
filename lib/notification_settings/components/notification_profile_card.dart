import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/motion/motion_tokens.dart';
import '/models/notification_preferences.dart';

class NotificationProfileCard extends StatelessWidget {
  const NotificationProfileCard({
    super.key,
    required this.profile,
    required this.icon,
    required this.title,
    required this.description,
    required this.isActive,
    required this.onTap,
  });

  final NotificationProfile profile;
  final PhosphorIconData icon;
  final String title;
  final String description;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionTokens.routeEnter,
        curve: MotionTokens.curveEnter,
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          border: Border.all(
            color: isActive
                ? AppColors.green.withValues(alpha: 0.3)
                : AppColors.navyLight.withValues(alpha: 0.2),
            width: 1,
          ),
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.green.withValues(alpha: 0.08),
                    AppColors.transparent,
                  ],
                  stops: const [0.0, 0.5],
                )
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.navyLight.withValues(alpha: 0.5),
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Center(
                      child: AppIcon(
                        icon: icon,
                        size: AppIconSize.md,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    description,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isActive)
              const Positioned(
                top: 8,
                right: 8,
                child: _NotificationProfileCheckmark(),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationProfileCheckmark extends StatefulWidget {
  const _NotificationProfileCheckmark();

  @override
  State<_NotificationProfileCheckmark> createState() =>
      _NotificationProfileCheckmarkState();
}

class _NotificationProfileCheckmarkState
    extends State<_NotificationProfileCheckmark> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _visible ? 1.0 : 0.0,
      duration: MotionTokens.routeEnter,
      curve: MotionTokens.curveEnter,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: MotionTokens.routeEnter,
        curve: MotionTokens.curveEnter,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.green,
            shape: BoxShape.circle,
          ),
          child: AppIcon(
            icon: AppPhosphorIcons.check,
            size: AppIconSize.xs,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
