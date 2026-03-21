import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/utils/app_log.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/fairway_background.dart';
import '/utils/app_util.dart';
import '/backend/backend.dart';
import '/chat_group/chat/components/chat_list_stream_content.dart';
import '/chat_group/chat/components/suggested_golfers_section.dart';
import '/providers/block_provider.dart';
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
    final uid = currentUserUid;
    return uid.isEmpty ? null : uid;
  }

  void _safeHaptic() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {
      // Haptics can be unsupported on web/desktop; ignore.
    }
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
      context.pushChatDetails(
        chatId: chatRef.id,
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
    AppLog.d('💬 ChatList: Page build() called');
    AppLog.d('💬 ChatList: Current user ID: $currentUserId');

    if (currentUserId == null) {
      AppLog.d('❌ ChatList: No current user, showing sign-in message');

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
          backgroundColor: AppColors.transparent,
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
    final blockedIds = context.watch<BlockProvider>().blockedUserIds;

    return CustomScrollView(
      slivers: [
        // Suggested Golfers Section (non-scrollable header)
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SuggestedGolfersSection(
                currentUserId: currentUserId,
                onGolferTap: (user) =>
                    _openDirectChatForUser(user, currentUserId),
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
        ChatListStreamContent(
          currentUserId: currentUserId,
          chatProvider: chatProvider,
          profileProvider: profileProvider,
          blockedIds: blockedIds,
        ),
        // Bottom padding
        SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.xxl),
        ),
      ],
    );
  }

}
