import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/core/app_theme.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/navigation/app_router.dart';
import '/core/utils/formatting_utils.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/widgets/fairway_background.dart';
import '/main_function/golfers/golfers_widget.dart';
import '/models/chat.dart';
import '/providers/chat_provider.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key, this.isEmbedded = false});

  final bool isEmbedded;
  static String routeName = 'Chat';
  static String routePath = '/chat';

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  String? _currentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  String? _chatListLabel(Chat chat) {
    if (chat.type == 'game') {
      return (chat.gameName ?? '').trim().isNotEmpty
          ? chat.gameName
          : 'Game Chat';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _currentUserId();
    debugPrint('💬 ChatList: Page build() called');
    debugPrint('💬 ChatList: Current user ID: $currentUserId');

    if (currentUserId == null) {
      debugPrint('❌ ChatList: No current user, showing sign-in message');

      if (widget.isEmbedded) {
        return Center(
          child: Text(
            'Please sign in to view chats.',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        );
      }

      return Scaffold(
        key: scaffoldKey,
        backgroundColor: AppTheme.of(context).secondaryBackground,
        body: Center(
          child: Text(
            'Please sign in to view chats.',
            style: AppTheme.of(context).bodyMedium,
          ),
        ),
      );
    }

    // Build the chat content
    Widget chatContent = _buildChatContent(currentUserId);

    // If embedded, just return the content
    if (widget.isEmbedded) {
      return chatContent;
    }

    // Otherwise, wrap in a Scaffold
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text(
            'My Chats',
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                0.0,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.goNamed(GolfersWidget.routeName);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add_comment_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: FairwayBackgroundDark(
          showOrganic: true,
          showTexture: true,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 56,
              ),
              child: chatContent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatContent(String currentUserId) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // New Chat button for embedded mode
        if (widget.isEmbedded)
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.goNamed(GolfersWidget.routeName);
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sunsetGold.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_comment_rounded, color: Colors.white, size: 18),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      'Start New Chat',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<Chat>>(
            stream: context.read<ChatProvider>().chatListStream(
                  uid: currentUserId,
                ),
            builder: (context, snapshot) {
              debugPrint('💬 ChatList: StreamBuilder called');
              debugPrint('💬 ChatList: connectionState = ${snapshot.connectionState}');
              debugPrint('💬 ChatList: hasError = ${snapshot.hasError}');
              debugPrint('💬 ChatList: hasData = ${snapshot.hasData}');

              if (snapshot.hasError) {
                debugPrint('❌ ChatList: ERROR - ${snapshot.error}');
                debugPrint('❌ ChatList: Error type: ${snapshot.error.runtimeType}');
                return Center(
                  child: Text(
                    'Failed to load chats.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                debugPrint('💬 ChatList: No data yet, showing loading...');
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.sunsetGold,
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'Loading chats...',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final chats = snapshot.data ?? <Chat>[];
              debugPrint('💬 ChatList: Received ${chats.length} chat(s)');

              if (chats.isNotEmpty) {
                debugPrint('💬 ChatList: First chat ID: ${chats.first.id}');
                debugPrint('💬 ChatList: First chat memberIds: ${chats.first.memberIds}');
              }

              if (chats.isEmpty) {
                debugPrint('💬 ChatList: Chats array is empty, showing empty state');

                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.fairway.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mark_chat_unread_outlined,
                          color: Colors.white.withOpacity(0.5),
                          size: 40,
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'No Chats Yet',
                        style: AppTypography.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Start a conversation with other golfers',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: chats.length,
                separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  final lastMessage = chat.lastMessage;
                  final lastMessageAt = chat.lastMessageAt;
                  final unreadCount =
                      chat.unreadCountByUser[currentUserId] ?? 0;

                  Widget buildRow(String displayName, String photoUrl) {
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.pushNamed(
                          'ChatDetails',
                          pathParameters: {
                            'chatId': chat.id,
                          },
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.fairway.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: unreadCount > 0
                                ? AppColors.sunsetGold.withOpacity(0.4)
                                : Colors.white.withOpacity(0.1),
                            width: unreadCount > 0 ? 2 : 1,
                          ),
                        ),
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.fairwayLight,
                                    AppColors.fairway,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: photoUrl.isNotEmpty
                                    ? Image.network(
                                        photoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                          Icons.person_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      )
                                    : Icon(
                                        Icons.person_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                              ),
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
                                          style:
                                              AppTypography.titleSmall.copyWith(
                                            color: Colors.white,
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
                                                AppColors.sunsetGold,
                                                AppColors.sunsetPeach,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.sunsetGold.withOpacity(0.4),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          constraints: BoxConstraints(minWidth: 24),
                                          child: Text(
                                            unreadCount > 99 ? '99+' : '$unreadCount',
                                            textAlign: TextAlign.center,
                                            style: AppTypography.labelSmall.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    lastMessage.isNotEmpty
                                        ? lastMessage
                                        : 'No messages yet.',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  if (lastMessageAt != null) ...[
                                    SizedBox(height: 4),
                                    Text(
                                      dateTimeFormat('relative', lastMessageAt),
                                      style:
                                          AppTypography.labelSmall.copyWith(
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Arrow
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white.withOpacity(0.5),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (chat.type == 'game') {
                    final displayName = _chatListLabel(chat) ?? 'Game Chat';
                    return buildRow(displayName, '');
                  }

                  final otherUserId = chat.memberIds.firstWhere(
                    (id) => id != currentUserId,
                    orElse: () => currentUserId,
                  );
                  return FutureBuilder<Map<String, dynamic>>(
                    future: context
                        .read<ChatProvider>()
                        .getUserProfile(otherUserId),
                    builder: (context, userSnapshot) {
                      final userData =
                          userSnapshot.data ?? <String, dynamic>{};
                      final displayName =
                          valueOrDefault<String>(
                              userData['display_name'] as String?, 'Golfer');
                      final photoUrl =
                          (userData['photo_url'] as String?) ?? '';

                      return buildRow(displayName, photoUrl);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
