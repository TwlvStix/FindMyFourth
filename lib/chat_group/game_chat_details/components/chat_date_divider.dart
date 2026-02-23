import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/utils/formatting_utils.dart';

/// A date divider component for chat messages showing formatted dates
/// with horizontal divider lines on each side.
///
/// Displays dates as:
/// - "Today" for messages sent today
/// - "Yesterday" for messages sent yesterday
/// - Day of week (e.g., "Monday") for messages within the last 7 days
/// - Full date (e.g., "Jan 15, 2024") for older messages
class ChatDateDivider extends StatelessWidget {
  final DateTime date;

  const ChatDateDivider({
    super.key,
    required this.date,
  });

  String _getDateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      return dateTimeFormat('EEEE', date); // Day of week
    } else {
      return dateTimeFormat('MMM d, yyyy', date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: AppColors.glassBorder,
              thickness: 1,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              _getDateLabel(),
              style: AppTypography.labelMicro.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: AppColors.glassBorder,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}
