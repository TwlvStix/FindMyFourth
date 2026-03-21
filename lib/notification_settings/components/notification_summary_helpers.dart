import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/models/notification_preferences.dart';

// ============================================
// Summary Text Generation
// ============================================

String getGameAlertsSummary(NotificationPreferences prefs) {
  if (!prefs.gameAlerts.enabled) {
    return 'Off';
  }
  return _formatFrequency(prefs.gameAlerts.deliveryFrequency);
}

String getChatAlertsSummary(NotificationPreferences prefs) {
  if (!prefs.chatAlerts.enabled) {
    return 'Off';
  }
  return _formatFrequency(prefs.chatAlerts.deliveryFrequency);
}

String getTrustSummary(NotificationPreferences prefs) {
  final trust = prefs.trustCategories;

  if (!trust.enabled) {
    return 'Off';
  }

  // Count enabled sub-categories
  int count = 0;
  if (trust.postRound) count++;
  if (trust.trustAlerts) count++;
  if (trust.badges) count++;

  if (count == 0) {
    return 'Off';
  }

  final freq = _formatFrequency(trust.deliveryFrequency);
  if (count == 3) {
    return 'All on · $freq';
  }
  return '$count of 3 on · $freq';
}

bool isTrustEnabled(NotificationPreferences prefs) {
  final trust = prefs.trustCategories;
  return trust.enabled &&
      (trust.postRound || trust.trustAlerts || trust.badges);
}

String getQuietHoursSummary(NotificationPreferences prefs) {
  final qh = prefs.quietHours;
  final status = qh.enabled ? 'On' : 'Off';
  return '$status · ${_formatTime(qh.start)} – ${_formatTime(qh.end)}';
}

String _formatFrequency(DeliveryFrequency freq) {
  switch (freq) {
    case DeliveryFrequency.instant:
      return 'Instant';
    case DeliveryFrequency.hourly:
      return 'Hourly';
    case DeliveryFrequency.daily:
      return 'Daily';
  }
}

String _formatTime(String time24) {
  final parts = time24.split(':');
  if (parts.length != 2) return time24;

  int hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts[1];
  final period = hour >= 12 ? 'PM' : 'AM';

  if (hour > 12) {
    hour -= 12;
  } else if (hour == 0) {
    hour = 12;
  }

  return '$hour:$minute $period';
}

// ============================================
// Snackbar Utility
// ============================================

void showNotificationUpdateConfirmation(BuildContext context) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          AppIcon(
            icon: AppPhosphorIcons.success,
            size: AppIconSize.md,
            color: AppColors.green,
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            'Settings updated',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.navy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        side: BorderSide(
          color: AppColors.green.withValues(alpha: 0.15),
        ),
      ),
      duration: const Duration(seconds: 2),
      margin: EdgeInsets.all(AppSpacing.md),
    ),
  );
}
