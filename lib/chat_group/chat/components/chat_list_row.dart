import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/chat_group_avatar.dart';
import '/providers/chat_provider.dart';
import '/utils/app_util.dart';

class ChatListRow extends StatelessWidget {
  const ChatListRow({
    super.key,
    required this.chatId,
    required this.displayName,
    required this.members,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  final String chatId;
  final String displayName;
  final List<ChatMemberInfo> members;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  void _safeHaptic() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {
      // Haptics can be unsupported on web/desktop; ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _safeHaptic();
        context.pushChatDetails(
          chatId: chatId,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.navy.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: unreadCount > 0
                ? AppColors.gold.withValues(alpha: 0.4)
                : AppColors.navyLight,
            width: unreadCount > 0 ? 2 : 1,
          ),
          boxShadow:
              unreadCount > 0 ? [AppElevation.glowGold] : [AppElevation.xs],
        ),
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Group avatar with member initials
            ChatGroupAvatar(
              members: members
                  .map((m) => GroupAvatarMember(
                        name: m.name,
                        photoUrl: m.photoUrl,
                      ))
                  .toList(),
              size: 50,
            ),
            SizedBox(width: AppSpacing.sm),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: unreadCount > 9 ? 6 : 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.gold,
                                AppColors.goldLight,
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.md),
                            boxShadow: [AppElevation.sm],
                          ),
                          constraints: BoxConstraints(minWidth: 24),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            textAlign: TextAlign.center,
                            style: AppTypography.labelMicro.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  AppSpacing.verticalXxs,
                  Text(
                    lastMessage.isNotEmpty ? lastMessage : 'No messages yet.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.glassTextSecondary,
                    ),
                  ),
                  if (lastMessageAt != null) ...[
                    AppSpacing.verticalXxs,
                    Text(
                      dateTimeFormat('relative', lastMessageAt),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.glassTextTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Arrow
            AppIcon(
              icon: AppPhosphorIcons.chevronRight,
              color: AppColors.textMuted.withValues(alpha: 0.5),
              size: AppIconSize.button,
            ),
          ],
        ),
      ),
    );
  }
}
