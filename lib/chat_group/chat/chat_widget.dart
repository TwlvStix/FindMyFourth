import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/fairway_background.dart';
import '/utils/app_util.dart';
import '/backend/backend.dart';
import '/chat_group/chat/components/suggested_golfers_section.dart';
import '/providers/chat_provider.dart';
import '/providers/profile_provider.dart';

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

  @override
  void initState() {
    super.initState();
  }

  String? _currentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  void _safeHaptic() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {
      // Haptics can be unsupported on web/desktop; ignore.
    }
  }

  Widget _buildChatRow({
    required String chatId,
    required String displayName,
    required String photoUrl,
    required String lastMessage,
    required DateTime? lastMessageAt,
    required int unreadCount,
  }) {
    return GestureDetector(
      onTap: () {
        _safeHaptic();
        context.pushNamed(
          'ChatDetails',
          pathParameters: {
            'chatId': chatId,
          },
          extra: <String, dynamic>{
            kTransitionInfoKey: TransitionStandards.detailTransition,
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.navy.withValues(alpha:0.3),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: unreadCount > 0
                ? AppColors.gold.withValues(alpha:0.4)
                : AppColors.glassSurface,
            width: unreadCount > 0 ? 2 : 1,
          ),
        ),
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Avatar with CachedNetworkImage
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.navyLight,
                    AppColors.navy,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(
                  color: AppColors.glassBorder,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                child: photoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => AppIcon(
                          icon: AppPhosphorIcons.profile,
                          color: AppColors.textPrimary,
                          size: AppIconSize.md,
                        ),
                        errorWidget: (context, url, error) => AppIcon(
                          icon: AppPhosphorIcons.profile,
                          color: AppColors.textPrimary,
                          size: AppIconSize.md,
                        ),
                      )
                    : AppIcon(
                        icon: AppPhosphorIcons.profile,
                        color: AppColors.textPrimary,
                        size: AppIconSize.md,
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
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
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
              color: AppColors.glassTextTertiary,
              size: AppIconSize.button,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDirectChatForUser(
    UsersRecord user,
    String currentUserId,
  ) async {
    try {
      final chatRef = await context.read<ChatProvider>().createOrGetDirectChat(
            currentUid: currentUserId,
            otherUid: user.reference.id,
          );
      if (!mounted) {
        return;
      }
      _safeHaptic();
      context.pushNamed(
        'ChatDetails',
        pathParameters: {
          'chatId': chatRef.id,
        },
        extra: <String, dynamic>{
          kTransitionInfoKey: TransitionStandards.detailTransition,
        },
      );
    } catch (error, stackTrace) {
      context
          .read<ChatProvider>()
          .logError('createOrGetDirectChat failed', error, stackTrace);
      if (mounted) {
        showSnackbar(context, 'Unable to start chat. Please try again.');
      }
    }
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
              color: AppColors.glassTextSecondary,
            ),
          ),
        );
      }

      return Scaffold(
        key: scaffoldKey,
        backgroundColor: AppColors.navy,
        body: Center(
          child: Text(
            'Please sign in to view chats.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.glassTextSecondary,
            ),
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
            style: AppTypography.headlineMediumSans.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
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
    final profileProvider = context.read<ProfileProvider>();
    final chatProvider = context.read<ChatProvider>();

    return CustomScrollView(
      slivers: [
        // Suggested Golfers Section (non-scrollable header)
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SuggestedGolfersSection(
                currentUserId: currentUserId,
                onGolferTap: (user) => _openDirectChatForUser(user, currentUserId),
              ),
              SizedBox(height: AppSpacing.lg),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Recent Chats',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.glassTextSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
        // Lazy chat list using SliverList
        _buildChatList(currentUserId, chatProvider, profileProvider),
        // Bottom padding
        SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.xxl),
        ),
      ],
    );
  }

  Widget _buildChatList(
    String currentUserId,
    ChatProvider chatProvider,
    ProfileProvider profileProvider,
  ) {
    return StreamBuilder<List<ChatRowViewModel>>(
      stream: chatProvider.chatRowsStream(
        currentUserId: currentUserId,
        profileProvider: profileProvider,
      ),
      builder: (context, snapshot) {
        debugPrint('💬 ChatList: StreamBuilder called');
        debugPrint('💬 ChatList: connectionState = ${snapshot.connectionState}');
        debugPrint('💬 ChatList: hasError = ${snapshot.hasError}');
        debugPrint('💬 ChatList: hasData = ${snapshot.hasData}');

        if (snapshot.hasError) {
          debugPrint('❌ ChatList: ERROR - ${snapshot.error}');
          debugPrint('❌ ChatList: Error type: ${snapshot.error.runtimeType}');
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
          debugPrint('💬 ChatList: No data yet, showing loading...');
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
        debugPrint('💬 ChatList: Received ${chatRows.length} chat row(s)');

        if (chatRows.isEmpty) {
          debugPrint('💬 ChatList: Chat rows array is empty, showing empty state');
          return SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.navy.withValues(alpha:0.3),
                      shape: BoxShape.circle,
                    ),
                    child: AppIcon(
                      icon: AppPhosphorIcons.chat,
                      color: AppColors.glassTextTertiary,
                      size: AppIconSize.xl,
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'No Chats Yet',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Start a conversation with other golfers',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.glassTextSecondary,
                    ),
                  ),
                ],
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
              child: _buildChatRow(
                chatId: row.chatId,
                displayName: row.displayName,
                photoUrl: row.photoUrl,
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
