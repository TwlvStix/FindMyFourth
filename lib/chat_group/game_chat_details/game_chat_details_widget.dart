import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/models/chat.dart';
import '/models/chat_message.dart';
import '/providers/chat_provider.dart';
import '/core/app_theme.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/fairway_background.dart';

class GameChatDetailsWidget extends StatefulWidget {
  const GameChatDetailsWidget({
    super.key,
    required this.chatId,
  });

  final String chatId;

  @override
  State<GameChatDetailsWidget> createState() => _GameChatDetailsWidgetState();
}

class _GameChatDetailsWidgetState extends State<GameChatDetailsWidget> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  static const int _initialPageSize = 40;
  static const int _pageSize = 30;
  final List<ChatMessage> _olderMessages = [];
  final Set<String> _olderMessageIds = {};
  DocumentSnapshot? _lastStreamDoc;
  DocumentSnapshot? _lastLoadedDoc;
  bool _isLoadingOlder = false;
  bool _hasMoreOlder = true;

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    debugPrint('📨 UI: Chat page loaded for chatId: ${widget.chatId}');
    debugPrint('📨 UI: Current user ID: $_currentUserId');
    _markChatSeen();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _markChatSeen() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return;
    }
    try {
      await context
          .read<ChatProvider>()
          .markChatRead(chatId: widget.chatId, uid: currentUserId);
    } catch (error, stackTrace) {
      context
          .read<ChatProvider>()
          .logError('markChatRead failed', error, stackTrace);
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Delete Chat?',
            style: AppTheme.of(context).headlineSmall,
          ),
          content: Text(
            'This will permanently delete all messages in this chat. This action cannot be undone.',
            style: AppTheme.of(context).bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: AppTheme.of(context).bodyLarge.override(
                      font: GoogleFonts.outfit(),
                      color: AppTheme.of(context).primaryText,
                      letterSpacing: 0.0,
                    ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Delete',
                style: AppTheme.of(context).bodyLarge.override(
                      font: GoogleFonts.outfit(),
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.0,
                    ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteChat();
    }
  }

  Future<void> _deleteChat() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return;
    }

    debugPrint('🔵 UI: Delete chat button pressed');
    debugPrint('🔵 UI: chatId=${widget.chatId}, userId=$currentUserId');

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            color: AppTheme.of(context).primary,
          ),
        );
      },
    );

    try {
      await context.read<ChatProvider>().deleteChat(
            chatId: widget.chatId,
            uid: currentUserId,
          );

      debugPrint('✅ UI: Chat deleted successfully');

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Navigate back to chat list
      if (!mounted) return;
      Navigator.of(context).pop();

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Chat deleted successfully'),
          backgroundColor: AppTheme.of(context).primary,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('❌ UI: Failed to delete chat: $error');

      context
          .read<ChatProvider>()
          .logError('deleteChat failed', error, stackTrace);

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete chat: ${error.toString().substring(0, error.toString().length > 50 ? 50 : error.toString().length)}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return;
    }
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }
    _messageController.clear();
    try {
      await context.read<ChatProvider>().sendMessage(
            chatId: widget.chatId,
            senderId: currentUserId,
            text: text,
          );
    } catch (error, stackTrace) {
      context
          .read<ChatProvider>()
          .logError('sendMessage failed', error, stackTrace);
      if (!mounted) {
        return;
      }
      _messageController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to send message. Please try again.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _sendMessage,
          ),
        ),
      );
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingOlder || !_hasMoreOlder) {
      return;
    }
    setState(() {
      _isLoadingOlder = true;
    });
    try {
      final page = await context.read<ChatProvider>().messagesPage(
            chatId: widget.chatId,
            limit: _pageSize,
            startAfter: _lastLoadedDoc ?? _lastStreamDoc,
          );
      if (page.messages.isEmpty) {
        _hasMoreOlder = false;
      } else {
        for (final message in page.messages) {
          if (_olderMessageIds.add(message.id)) {
            _olderMessages.add(message);
          }
        }
        _lastLoadedDoc = page.lastDoc;
        if (page.messages.length < _pageSize) {
          _hasMoreOlder = false;
        }
      }
    } catch (error, stackTrace) {
      context
          .read<ChatProvider>()
          .logError('loadOlderMessages failed', error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load older messages.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOlder = false;
        });
      }
    }
  }

  List<ChatMessage> _mergeMessages(List<ChatMessage> latestMessages) {
    final merged = <ChatMessage>[];
    final ids = <String>{};
    for (final message in latestMessages) {
      if (ids.add(message.id)) {
        merged.add(message);
      }
    }
    for (final message in _olderMessages) {
      if (ids.add(message.id)) {
        merged.add(message);
      }
    }
    return merged;
  }

  Widget _buildMessageBubble({
    required bool isMe,
    required String text,
    required String imageUrl,
  }) {
    final bubbleColor = isMe
        ? AppTheme.of(context).primary
        : AppTheme.of(context).secondaryBackground;
    final textColor = isMe
        ? AppTheme.of(context).primaryBtnText
        : AppTheme.of(context).primaryText;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: AppSpacing.xxs,
          horizontal: AppSpacing.md,
        ),
        padding: EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            if (text.isNotEmpty)
              Text(
                text,
                style: AppTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.outfit(
                        fontWeight:
                            AppTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            AppTheme.of(context).bodyMedium.fontStyle,
                      ),
                      color: textColor,
                      letterSpacing: 0.0,
                      fontWeight:
                          AppTheme.of(context).bodyMedium.fontWeight,
                      fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(Chat chat) {
    final memberIds = chat.memberIds;
    if (memberIds.length <= 1) {
      return Text(
        'Chat',
        style: AppTheme.of(context).titleMedium.override(
              font: GoogleFonts.outfit(
                fontWeight: AppTheme.of(context).titleMedium.fontWeight,
                fontStyle: AppTheme.of(context).titleMedium.fontStyle,
              ),
              letterSpacing: 0.0,
              fontWeight: AppTheme.of(context).titleMedium.fontWeight,
              fontStyle: AppTheme.of(context).titleMedium.fontStyle,
            ),
      );
    }

    if (memberIds.length == 2) {
      final currentUserId = _currentUserId;
      final otherUserId = memberIds.firstWhere(
        (id) => id != currentUserId,
        orElse: () => memberIds.first,
      );
      return FutureBuilder<Map<String, dynamic>>(
        future: context.read<ChatProvider>().getUserProfile(otherUserId),
        builder: (context, snapshot) {
          final otherData = snapshot.data ?? <String, dynamic>{};
          final displayName =
              (otherData['display_name'] as String?) ?? 'Golfer';
          final photoUrl = otherData['photo_url'] as String?;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (photoUrl != null && photoUrl.isNotEmpty)
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    0.0,
                    0.0,
                    AppSpacing.sm,
                    0.0,
                  ),
                  child: CircleAvatar(
                    radius: 18.0,
                    backgroundImage: NetworkImage(photoUrl),
                  ),
                ),
              Text(
                displayName,
                style: AppTheme.of(context).titleMedium.override(
                      font: GoogleFonts.outfit(
                        fontWeight:
                            AppTheme.of(context).titleMedium.fontWeight,
                        fontStyle:
                            AppTheme.of(context).titleMedium.fontStyle,
                      ),
                      letterSpacing: 0.0,
                      fontWeight:
                          AppTheme.of(context).titleMedium.fontWeight,
                      fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                    ),
              ),
            ],
          );
        },
      );
    }

    return Text(
      'Group Chat',
      style: AppTheme.of(context).titleMedium.override(
            font: GoogleFonts.outfit(
              fontWeight: AppTheme.of(context).titleMedium.fontWeight,
              fontStyle: AppTheme.of(context).titleMedium.fontStyle,
            ),
            letterSpacing: 0.0,
            fontWeight: AppTheme.of(context).titleMedium.fontWeight,
            fontStyle: AppTheme.of(context).titleMedium.fontStyle,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: StreamBuilder<Chat?>(
        stream:
            context.read<ChatProvider>().chatStream(widget.chatId),
        builder: (context, chatSnapshot) {
          if (chatSnapshot.hasError) {
            return Scaffold(
              backgroundColor: AppTheme.of(context).secondaryBackground,
              body: const Center(
                child: Text('Unable to load chat.'),
              ),
            );
          }
          if (!chatSnapshot.hasData) {
            return Scaffold(
              backgroundColor: AppTheme.of(context).secondaryBackground,
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          final chat = chatSnapshot.data;
          if (chat == null) {
            return Scaffold(
              backgroundColor: AppTheme.of(context).secondaryBackground,
              body: const Center(
                child: Text('Chat not found.'),
              ),
            );
          }

          return Scaffold(
            backgroundColor: AppTheme.of(context).secondaryBackground,
            appBar: AppBar(
              backgroundColor: AppTheme.of(context).primaryBackground,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.of(context).primaryText,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: _buildTitle(chat),
              centerTitle: false,
              elevation: 0.0,
              actions: [
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppTheme.of(context).primaryText,
                  ),
                  onSelected: (String value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20.0,
                          ),
                          SizedBox(width: 12.0),
                          Text(
                            'Delete Chat',
                            style: AppTheme.of(context).bodyMedium.override(
                                  font: GoogleFonts.outfit(),
                                  color: Colors.red,
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: FairwayBackgroundDark(
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: context.read<ChatProvider>().messagesSnapshotStream(
                            chatId: widget.chatId,
                            limit: _initialPageSize,
                          ),
                      builder: (context, snapshot) {
                        debugPrint('📨 UI: StreamBuilder called for chatId: ${widget.chatId}');
                        debugPrint('📨 UI: snapshot.connectionState = ${snapshot.connectionState}');
                        debugPrint('📨 UI: snapshot.hasError = ${snapshot.hasError}');
                        debugPrint('📨 UI: snapshot.hasData = ${snapshot.hasData}');

                        if (snapshot.hasError) {
                          debugPrint('❌ UI: StreamBuilder error: ${snapshot.error}');
                          return Center(
                            child: Text(
                              'Unable to load messages.',
                              style: AppTheme.of(context).bodyMedium,
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          debugPrint('📨 UI: No data yet, showing loading indicator');
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final docs = snapshot.data!.docs;
                        debugPrint('📨 UI: Received ${docs.length} document(s)');

                        if (docs.isEmpty) {
                          debugPrint('📨 UI: Docs array is empty - showing "No messages yet"');
                          return Center(
                            child: Text(
                              'No messages yet.',
                              style: AppTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.outfit(
                                      fontWeight: AppTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: AppTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: AppTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: AppTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: AppTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                          );
                        }

                        _lastStreamDoc =
                            docs.isNotEmpty ? docs.last : _lastStreamDoc;
                        final latestMessages =
                            docs.map(ChatMessage.fromDoc).toList();
                        debugPrint('📨 UI: Converted ${latestMessages.length} ChatMessage objects');
                        final messages = _mergeMessages(latestMessages);
                        debugPrint('📨 UI: After merging: ${messages.length} messages');
                        final itemCount =
                            messages.length + (_hasMoreOlder ? 1 : 0);
                        debugPrint('📨 UI: Rendering ListView with $itemCount items');

                        if (messages.isNotEmpty) {
                          debugPrint('📨 UI: First message text: ${messages.first.text.substring(0, messages.first.text.length > 30 ? 30 : messages.first.text.length)}');
                        }

                        return ListView.builder(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          reverse: true,
                          itemCount: itemCount,
                          itemBuilder: (context, index) {
                            if (_hasMoreOlder &&
                                index == messages.length) {
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                  horizontal: AppSpacing.md,
                                ),
                                child: Center(
                                  child: TextButton(
                                    onPressed: _isLoadingOlder
                                        ? null
                                        : _loadOlderMessages,
                                    child: _isLoadingOlder
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Load earlier messages'),
                                  ),
                                ),
                              );
                            }
                            final message = messages[index];
                            final isMe =
                                message.senderId == _currentUserId;
                            return _buildMessageBubble(
                              isMe: isMe,
                              text: message.text,
                              imageUrl: message.imageUrl,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.of(context).primaryBackground,
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 6.0,
                          color: Color(0x22000000),
                          offset: Offset(0.0, -2.0),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _messageFocusNode,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: 'Message...',
                              filled: true,
                              fillColor:
                                  AppTheme.of(context).secondaryBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        IconButton(
                          icon: Icon(
                            Icons.send,
                            color: AppTheme.of(context).primary,
                          ),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
