import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '/core/app_theme.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/navigation/app_router.dart';
import '/core/utils/formatting_utils.dart';
import '/core/widgets/fairway_background.dart';
import '/utils/app_util.dart';
import '/backend/backend.dart';
import '/friends/components/golfer_search_section.dart';
import '/chat_group/chat/components/suggested_golfers_section.dart';
import '/models/chat.dart';
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

  String? _chatListLabel(Chat chat) {
    if (chat.type == 'game') {
      return (chat.gameName ?? '').trim().isNotEmpty
          ? chat.gameName
          : 'Game Chat';
    }
    return null;
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
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.7),
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
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
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
    return ListView(
      padding: EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        SuggestedGolfersSection(
          currentUserId: currentUserId,
          onGolferTap: (user) => _openDirectChatForUser(user, currentUserId),
        ),
        SizedBox(height: AppSpacing.lg),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'Search All Golfers',
            style: AppTypography.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GolferSearchSection(
          currentUserId: currentUserId,
          autofocus: false,
          emptyStateBuilder: (clearSearch) => Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No golfers found',
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Try a different name or clear your search.',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: clearSearch,
                  child: Text(
                    'Clear search',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.sunsetGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          itemBuilder: (context, user) => _ChatSearchResultTile(
            user: user,
            onTap: () => _openDirectChatForUser(user, currentUserId),
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'Recent Chats',
            style: AppTypography.labelLarge.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        _buildChatList(currentUserId),
      ],
    );
  }

  Widget _buildChatList(String currentUserId) {
    return StreamBuilder<List<Chat>>(
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
          return Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
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
          return Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
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

          return Padding(
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

        final directUserIds = <String>{};
        for (final chat in chats) {
          if (chat.type == 'game') continue;
          final otherUserId = chat.memberIds.firstWhere(
            (id) => id != currentUserId,
            orElse: () => currentUserId,
          );
          if (otherUserId.isNotEmpty) {
            directUserIds.add(otherUserId);
          }
        }

        final profilesFuture = directUserIds.isEmpty
            ? Future.value(<String, UsersRecord>{})
            : context
                .read<ProfileProvider>()
                .batchGetProfiles(directUserIds.toList());

        return FutureBuilder<Map<String, UsersRecord>>(
          future: profilesFuture,
          builder: (context, profilesSnapshot) {
            final profileMap = profilesSnapshot.data ?? <String, UsersRecord>{};

            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: chats.length,
              separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final chat = chats[index];
                final lastMessage = chat.lastMessage;
                final lastMessageAt = chat.lastMessageAt;
                final unreadCount = chat.unreadCountByUser[currentUserId] ?? 0;

                Widget buildRow(String displayName, String photoUrl) {
                  return GestureDetector(
                    onTap: () {
                      _safeHaptic();
                      context.pushNamed(
                        'ChatDetails',
                        pathParameters: {
                          'chatId': chat.id,
                        },
                        extra: <String, dynamic>{
                          kTransitionInfoKey:
                              TransitionStandards.detailTransition,
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
                                          (context, error, stackTrace) => Icon(
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
                                          horizontal:
                                              unreadCount > 9 ? 6 : 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.sunsetGold,
                                              AppColors.sunsetPeach,
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.sunsetGold
                                                  .withOpacity(0.4),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        constraints:
                                            BoxConstraints(minWidth: 24),
                                        child: Text(
                                          unreadCount > 99
                                              ? '99+'
                                              : '$unreadCount',
                                          textAlign: TextAlign.center,
                                          style:
                                              AppTypography.text11.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
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
                                    style: AppTypography.labelSmall.copyWith(
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
                final profile = profileMap[otherUserId];
                final displayName =
                    (profile?.displayName ?? '').trim().isNotEmpty
                        ? profile!.displayName
                        : 'Golfer';
                final photoUrl = profile?.photoUrl ?? '';

                return buildRow(displayName, photoUrl);
              },
            );
          },
        );
      },
    );
  }
}

class _ChatSearchResultTile extends StatelessWidget {
  const _ChatSearchResultTile({
    required this.user,
    required this.onTap,
  });

  final UsersRecord user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName(user);
    final photoUrl = user.photoUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.fairway.withOpacity(0.28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.fairwayLight, AppColors.fairway],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      )
                    : Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap to message',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _displayName(UsersRecord user) {
    final displayName = user.displayName.trim();
    if (displayName.isNotEmpty) {
      return displayName;
    }
    final combined = '${user.firstName} ${user.lastName}'.trim();
    return combined.isNotEmpty ? combined : 'Golfer';
  }
}
