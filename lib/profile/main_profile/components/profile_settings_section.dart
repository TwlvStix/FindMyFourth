import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';

/// Settings section of the main profile page.
///
/// Contains Notifications, Your Standing, Debug (if enabled), and Log Out rows.
class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({
    super.key,
    required this.onNotifications,
    required this.onYourStanding,
    required this.onLocation,
    required this.onPrivacyPolicy,
    required this.onTermsOfService,
    required this.onLogout,
    this.showDebugOptions = false,
    this.onDebugNotificationRouting,
    this.onDebugStreakPreview,
    this.onDebugNotificationAudit,
  });

  /// Called when the user taps "Notifications".
  final VoidCallback onNotifications;

  /// Called when the user taps "Your Standing".
  final VoidCallback onYourStanding;

  /// Called when the user taps "Location".
  final VoidCallback onLocation;

  /// Called when the user taps "Privacy Policy".
  final VoidCallback onPrivacyPolicy;

  /// Called when the user taps "Terms of Service".
  final VoidCallback onTermsOfService;

  /// Called when the user taps "Log Out".
  /// This should handle the confirmation dialog and logout flow.
  final Future<void> Function() onLogout;

  /// Whether to show debug options (only in debug mode).
  final bool showDebugOptions;

  /// Called when the user taps "Test Notification Routing" (debug only).
  final VoidCallback? onDebugNotificationRouting;

  /// Called when the user taps "Streak UI Preview" (debug only).
  final VoidCallback? onDebugStreakPreview;

  /// Called when the user taps "Notification Audit" (debug only).
  final VoidCallback? onDebugNotificationAudit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(color: AppColors.navyLight),
            ),
            child: Column(
              children: [
                _buildSettingsRow(
                  phosphorIcon: AppPhosphorIcons.notifications,
                  label: 'Notifications',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onNotifications();
                  },
                ),
                Divider(height: 1, color: AppColors.navyLight, indent: 56),
                _buildSettingsRow(
                  phosphorIcon: AppPhosphorIcons.standing,
                  label: 'Your Standing',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onYourStanding();
                  },
                ),
                Divider(height: 1, color: AppColors.navyLight, indent: 56),
                _buildSettingsRow(
                  phosphorIcon: AppPhosphorIcons.homeCourse,
                  label: 'Location',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onLocation();
                  },
                ),
                Divider(height: 1, color: AppColors.navyLight, indent: 56),
                _buildSettingsRow(
                  phosphorIcon: AppPhosphorIcons.privacyPolicy,
                  label: 'Privacy Policy',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onPrivacyPolicy();
                  },
                ),
                Divider(height: 1, color: AppColors.navyLight, indent: 56),
                _buildSettingsRow(
                  phosphorIcon: AppPhosphorIcons.termsOfService,
                  label: 'Terms of Service',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTermsOfService();
                  },
                ),
                // Debug options (only in debug mode)
                if (showDebugOptions && kDebugMode) ...[
                  Divider(height: 1, color: AppColors.navyLight, indent: 56),
                  _buildSettingsRow(
                    phosphorIcon: AppPhosphorIcons.bug,
                    label: 'Test Notification Routing',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onDebugNotificationRouting?.call();
                    },
                  ),
                  Divider(height: 1, color: AppColors.navyLight, indent: 56),
                  _buildSettingsRow(
                    phosphorIcon: AppPhosphorIcons.flame,
                    label: 'Streak UI Preview',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onDebugStreakPreview?.call();
                    },
                  ),
                  Divider(height: 1, color: AppColors.navyLight, indent: 56),
                  _buildSettingsRow(
                    phosphorIcon: AppPhosphorIcons.notifications,
                    label: 'Notification Audit',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onDebugNotificationAudit?.call();
                    },
                  ),
                ],
                Divider(height: 1, color: AppColors.navyLight, indent: 56),
                _buildSettingsRow(
                  phosphorIcon: AppPhosphorIcons.logOut,
                  label: 'Log Out',
                  isDestructive: true,
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    await onLogout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
    required PhosphorIconData phosphorIcon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
    Widget? trailing,
  }) {
    // Muted red for less alarm on destructive actions
    final color = isDestructive
        ? AppColors.error.withValues(alpha: 0.85)
        : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            AppIcon(
              icon: phosphorIcon,
              color: color,
              size: AppIconSize.md,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: color,
                  fontWeight: isDestructive ? AppTypography.medium : null,
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing,
              SizedBox(width: AppSpacing.xs),
            ],
            AppIcon(
              icon: AppPhosphorIcons.chevronRight,
              color: AppColors.textMuted,
              size: AppIconSize.md,
            ),
          ],
        ),
      ),
    );
  }
}
