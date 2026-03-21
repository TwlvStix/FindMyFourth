import 'package:flutter/material.dart';

import '/core/utils/app_log.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_empty_state_premium.dart';
import '/chat_group/chat/components/chat_list_row.dart';
import '/providers/chat_provider.dart';
import '/providers/profile_provider.dart';

class ChatListStreamContent extends StatelessWidget {
  const ChatListStreamContent({
    super.key,
    required this.currentUserId,
    required this.chatProvider,
    required this.profileProvider,
    required this.blockedIds,
  });

  final String currentUserId;
  final ChatProvider chatProvider;
  final ProfileProvider profileProvider;
  final Set<String> blockedIds;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatRowViewModel>>(
      stream: chatProvider.chatRowsStream(
        currentUserId: currentUserId,
        profileProvider: profileProvider,
        blockedUserIds: blockedIds,
      ),
      builder: (context, snapshot) {
        AppLog.d('💬 ChatList: StreamBuilder called');
        AppLog.d('💬 ChatList: connectionState = ${snapshot.connectionState}');
        AppLog.d('💬 ChatList: hasError = ${snapshot.hasError}');
        AppLog.d('💬 ChatList: hasData = ${snapshot.hasData}');

        if (snapshot.hasError) {
          AppLog.d('❌ ChatList: ERROR - ${snapshot.error}');
          AppLog.d('❌ ChatList: Error type: ${snapshot.error.runtimeType}');
          return SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Failed to load chats.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.glassTextSecondary,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          AppLog.d('💬 ChatList: No data yet, showing loading...');
          return SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.gold,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Loading chats...',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.glassTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final chatRows = snapshot.data ?? <ChatRowViewModel>[];
        AppLog.d('💬 ChatList: Received ${chatRows.length} chat row(s)');

        if (chatRows.isEmpty) {
          AppLog.d(
              '💬 ChatList: Chat rows array is empty, showing empty state');
          return SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: AppEmptyStatePremium(
                icon: AppPhosphorIcons.chat,
                title: 'No Chats Yet',
                message: 'Start a conversation with other golfers',
              ),
            ),
          );
        }

        // Use SliverList.builder for lazy rendering
        return SliverList.builder(
          itemCount: chatRows.length,
          itemBuilder: (context, index) {
            final row = chatRows[index];
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: index < chatRows.length - 1 ? AppSpacing.sm : 0,
              ),
              child: ChatListRow(
                chatId: row.chatId,
                displayName: row.displayName,
                members: row.members,
                lastMessage: row.lastMessage,
                lastMessageAt: row.lastMessageAt,
                unreadCount: row.unreadCount,
              ),
            );
          },
        );
      },
    );
  }
}
