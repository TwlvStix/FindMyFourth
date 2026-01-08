import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/core/app_theme.dart';
import '/core/design_tokens/spacing.dart';
import '/core/navigation/app_router.dart';
import '/core/utils/formatting_utils.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/widgets/fairway_background.dart';
import '/main_function/golfers/golfers_widget.dart';
import '/models/chat.dart';
import '/providers/chat_provider.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key});

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

  @override
  Widget build(BuildContext context) {
    final currentUserId = _currentUserId();
    debugPrint('💬 ChatList: Page build() called');
    debugPrint('💬 ChatList: Current user ID: $currentUserId');

    if (currentUserId == null) {
      debugPrint('❌ ChatList: No current user, showing sign-in message');

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

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AppTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          title: Text(
            'My Chats',
            style: AppTheme.of(context).headlineSmall.override(
                  font: GoogleFonts.outfit(
                    fontWeight: AppTheme.of(context).headlineSmall.fontWeight,
                    fontStyle: AppTheme.of(context).headlineSmall.fontStyle,
                  ),
                  color: AppTheme.of(context).primary,
                  letterSpacing: 0.0,
                  fontWeight: AppTheme.of(context).headlineSmall.fontWeight,
                  fontStyle: AppTheme.of(context).headlineSmall.fontStyle,
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
              child: AppIconButton(
                borderColor: AppTheme.of(context).primary,
                borderRadius: 12.0,
                borderWidth: 1.0,
                buttonSize: 40.0,
                fillColor: AppTheme.of(context).primary,
                icon: Icon(
                  Icons.add_comment,
                  color: AppTheme.of(context).primaryBtnText,
                  size: 24.0,
                ),
                onPressed: () {
                  context.goNamed(GolfersWidget.routeName);
                },
              ),
            ),
          ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: FairwayBackgroundDark(
          child: SafeArea(
            top: true,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(AppSpacing.md, 0.0, 0.0, 0.0),
                  child: Text(
                    'Below are your chats and group chats',
                    style: AppTheme.of(context).labelMedium.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .labelMedium
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .labelMedium
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              AppTheme.of(context).labelMedium.fontWeight,
                          fontStyle:
                              AppTheme.of(context).labelMedium.fontStyle,
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
                            style: AppTheme.of(context).bodyMedium,
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        debugPrint('💬 ChatList: No data yet, showing loading...');
                        return Center(
                          child: SizedBox(
                            width: 50.0,
                            height: 50.0,
                            child: CircularProgressIndicator(
                              color: AppTheme.of(context).secondary,
                            ),
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
                          child: Container(
                            width: MediaQuery.sizeOf(context).width * 0.9,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.mark_chat_unread_outlined,
                                  color: AppTheme.of(context).primary,
                                  size: 90.0,
                                ),
                                SizedBox(height: AppSpacing.sm),
                                Text(
                                  'No Chats',
                                  style: AppTheme.of(context)
                                      .headlineSmall
                                      .override(
                                        font: GoogleFonts.outfit(
                                          fontWeight: AppTheme.of(context)
                                              .headlineSmall
                                              .fontWeight,
                                          fontStyle: AppTheme.of(context)
                                              .headlineSmall
                                              .fontStyle,
                                        ),
                                        letterSpacing: 0.0,
                                        fontWeight: AppTheme.of(context)
                                            .headlineSmall
                                            .fontWeight,
                                        fontStyle: AppTheme.of(context)
                                            .headlineSmall
                                            .fontStyle,
                                      ),
                                ),
                                SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Start a chat by tapping the button in the top right.',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.of(context)
                                      .labelMedium
                                      .override(
                                        font: GoogleFonts.outfit(
                                          fontWeight: AppTheme.of(context)
                                              .labelMedium
                                              .fontWeight,
                                          fontStyle: AppTheme.of(context)
                                              .labelMedium
                                              .fontStyle,
                                        ),
                                        letterSpacing: 0.0,
                                        fontWeight: AppTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: AppTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          final otherUserId = chat.memberIds.firstWhere(
                            (id) => id != currentUserId,
                            orElse: () => currentUserId,
                          );
                          final lastMessage = chat.lastMessage;
                          final lastMessageAt = chat.lastMessageAt;
                          final unreadCount =
                              chat.unreadCountByUser[currentUserId] ?? 0;

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

                                  return InkWell(
                                onTap: () {
                                  context.pushNamed(
                                    'ChatDetails',
                                    pathParameters: {
                                      'chatId': chat.id,
                                    },
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.of(context)
                                        .secondaryBackground,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: AppTheme.of(context).alternate,
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                    AppSpacing.md,
                                    AppSpacing.sm,
                                    AppSpacing.md,
                                    AppSpacing.sm,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 44.0,
                                        height: 44.0,
                                        decoration: BoxDecoration(
                                          color: AppTheme.of(context).accent1,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          border: Border.all(
                                            color: AppTheme.of(context).primary,
                                            width: 2.0,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          child: photoUrl.isNotEmpty
                                              ? Image.network(
                                                  photoUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Image.asset(
                                                    'assets/images/error_image.png',
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : Image.asset(
                                                  'assets/images/error_image.png',
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                      ),
                                      SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    displayName,
                                                    style: AppTheme.of(context)
                                                        .bodyLarge
                                                        .override(
                                                          font:
                                                              GoogleFonts.outfit(
                                                            fontWeight:
                                                                AppTheme.of(context)
                                                                    .bodyLarge
                                                                    .fontWeight,
                                                            fontStyle:
                                                                AppTheme.of(context)
                                                                    .bodyLarge
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              AppTheme.of(context)
                                                                  .bodyLarge
                                                                  .fontWeight,
                                                          fontStyle:
                                                              AppTheme.of(context)
                                                                  .bodyLarge
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                                if (unreadCount > 0)
                                                  Container(
                                                    width: 12.0,
                                                    height: 12.0,
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.of(context)
                                                          .primary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            SizedBox(height: AppSpacing.xxs),
                                            Text(
                                              lastMessage.isNotEmpty
                                                  ? lastMessage
                                                  : 'No messages yet.',
                                              style: AppTheme.of(context)
                                                  .labelMedium
                                                  .override(
                                                    font: GoogleFonts.outfit(
                                                      fontWeight: AppTheme.of(context)
                                                          .labelMedium
                                                          .fontWeight,
                                                      fontStyle: AppTheme.of(context)
                                                          .labelMedium
                                                          .fontStyle,
                                                    ),
                                                    letterSpacing: 0.0,
                                                    fontWeight: AppTheme.of(context)
                                                        .labelMedium
                                                        .fontWeight,
                                                    fontStyle: AppTheme.of(context)
                                                        .labelMedium
                                                        .fontStyle,
                                                  ),
                                            ),
                                            if (lastMessageAt != null)
                                              Padding(
                                                padding:
                                                    EdgeInsets.only(top: 4.0),
                                                child: Text(
                                                  dateTimeFormat(
                                                    'relative',
                                                    lastMessageAt,
                                                  ),
                                                  style: AppTheme.of(context)
                                                      .labelSmall
                                                      .override(
                                                        font: GoogleFonts.outfit(
                                                          fontWeight:
                                                              AppTheme.of(context)
                                                                  .labelSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              AppTheme.of(context)
                                                                  .labelSmall
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            AppTheme.of(context)
                                                                .labelSmall
                                                                .fontWeight,
                                                        fontStyle:
                                                            AppTheme.of(context)
                                                                .labelSmall
                                                                .fontStyle,
                                                      ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
