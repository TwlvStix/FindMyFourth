import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '/backend/backend.dart';
import '/models/chat.dart';
import '/models/chat_message.dart';
import '/providers/chat_provider.dart';
import '/providers/profile_provider.dart';
import '/core/app_theme.dart';
import '/core/motion/motion_helpers.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_text.dart';
import '/core/widgets/fairway_background.dart';
import 'components/chat_date_divider.dart';
import 'components/chat_message_bubble.dart';
import 'components/chat_header_title.dart';
import 'components/chat_input_bar.dart';

class GameChatDetailsWidget extends StatefulWidget {
  const GameChatDetailsWidget({
    super.key,
    required this.chatId,
  });

  final String chatId;

  @override
  State<GameChatDetailsWidget> createState() => _GameChatDetailsWidgetState();
}

class _GameChatDetailsWidgetState extends State<GameChatDetailsWidget>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late final Stream<Chat?> _chatStream;
  late final Stream<Chat?> _chatUiStream;
  late final Stream<QuerySnapshot> _messagesStream;
  late final Stream<List<ChatMessageViewModel>> _messageViewModelsStream;
  StreamSubscription<Chat?>? _chatUiSubscription;
  static const int _initialPageSize = 40;
  static const int _pageSize = 30;
  final List<ChatMessage> _olderMessages = [];
  final List<ChatMessageViewModel> _latestMessageVMs = [];
  final Set<String> _olderMessageIds = {};
  DocumentSnapshot? _lastStreamDoc;
  DocumentSnapshot? _lastLoadedDoc;
  bool _isLoadingOlder = false;
  bool _hasMoreOlder = true;
  bool _showScrollToBottom = false;
  bool _isTyping = false;
  Timer? _typingTimer;
  ChatMessage? _replyToMessage;
  Chat? _chatUi;
  bool _chatLoaded = false;
  Object? _chatError;
  bool _canSend = false;
  bool _isArchived = false;
  String _bannerText = '';
  String? _gameIdForOwnerLookup;
  Future<GamesRecord?>? _gameOwnerFuture;
  bool _didMarkSeen = false;

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    debugPrint('📨 UI: Chat page loaded for chatId: ${widget.chatId}');
    debugPrint('📨 UI: Current user ID: $_currentUserId');
    final chatProvider = context.read<ChatProvider>();
    final profileProvider = context.read<ProfileProvider>();
    _chatStream = chatProvider.chatStream(widget.chatId);
    _chatUiStream = _chatStream.distinct(_chatUiEquals);
    _messagesStream = chatProvider.messagesSnapshotStream(
      chatId: widget.chatId,
      limit: _initialPageSize,
    );
    // AUDIT #5 FIX: Single view-model stream replaces nested builders
    _messageViewModelsStream = chatProvider.gameChatMessageViewModelsStream(
      chatId: widget.chatId,
      limit: _initialPageSize,
      profileProvider: profileProvider,
    );
    _chatUiSubscription = _chatUiStream.listen(
      (chat) {
        if (!mounted) return;
        _updateChatUiState(chat);
      },
      onError: (error) {
        if (!mounted) return;
        if (kDebugMode) {
          debugPrint('❌ UI: Chat stream error for chatId=${widget.chatId}: $error');
        }
        setState(() {
          _chatError = error;
          _chatLoaded = true;
          _chatUi = null;
          _canSend = false;
          _bannerText = '';
          _isArchived = false;
        });
      },
    );
    _messageController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('📨 UI: Disposing ChatDetails for chatId=${widget.chatId}');
    }
    _typingTimer?.cancel();
    _chatUiSubscription?.cancel();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    final hasText = _messageController.text.trim().isNotEmpty;
    if (kDebugMode) {
      debugPrint(
        '✍️ UI: onTextChanged chatId=${widget.chatId} hasText=$hasText '
        'textLen=${_messageController.text.length} isTyping=$_isTyping',
      );
    }

    // Handle typing indicator
    if (hasText && !_isTyping) {
      _isTyping = true;
      context.read<ChatProvider>().setTypingStatus(
            chatId: widget.chatId,
            uid: currentUserId,
            isTyping: true,
          );
    }

    // Reset timer
    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        context.read<ChatProvider>().setTypingStatus(
              chatId: widget.chatId,
              uid: currentUserId,
              isTyping: false,
            );
      }
    });
  }

  List<String> _getTypingUserNames(Chat chat) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return [];

    final now = DateTime.now();
    final typingUserIds = chat.typingUsers.entries
        .where((entry) =>
            entry.key != currentUserId &&
            now.difference(entry.value).inSeconds < 3)
        .map((entry) => entry.key)
        .toList();

    return typingUserIds;
  }

  void _showImageFullscreen(String imageUrl) {
    showAppDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(10),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 48,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  tooltip: 'Close image',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleReaction(ChatMessage message, String emoji, bool hasReacted) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    if (hasReacted) {
      await context.read<ChatProvider>().removeReaction(
            chatId: widget.chatId,
            messageId: message.id,
            emoji: emoji,
            uid: currentUserId,
          );
    } else {
      await context.read<ChatProvider>().addReaction(
            chatId: widget.chatId,
            messageId: message.id,
            emoji: emoji,
            uid: currentUserId,
          );
    }
  }

  void _showReactionPicker(ChatMessage message) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    final quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

    showAppBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.of(context).primaryBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'React to message',
                style: AppTheme.of(context).titleMedium.override(
                      letterSpacing: 0.0,
                    ),
              ),
              SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: quickReactions.map((emoji) {
                  final hasReacted = message.reactions[emoji]?.contains(currentUserId) ?? false;

                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      if (hasReacted) {
                        await context.read<ChatProvider>().removeReaction(
                              chatId: widget.chatId,
                              messageId: message.id,
                              emoji: emoji,
                              uid: currentUserId,
                            );
                      } else {
                        await context.read<ChatProvider>().addReaction(
                              chatId: widget.chatId,
                              messageId: message.id,
                              emoji: emoji,
                              uid: currentUserId,
                            );
                      }
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: hasReacted
                            ? AppTheme.of(context).primary.withOpacity(0.3)
                            : AppTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: hasReacted
                            ? Border.all(
                                color: AppTheme.of(context).primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  void _onScroll() {
    // Show FAB when scrolled up more than 200 pixels from bottom
    final showFab = _scrollController.hasClients &&
                    _scrollController.offset > 200;
    if (showFab != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = showFab;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool _chatUiEquals(Chat? previous, Chat? next) {
    if (identical(previous, next)) {
      return true;
    }
    if (previous == null || next == null) {
      return previous == next;
    }
    return previous.id == next.id &&
        previous.type == next.type &&
        previous.gameName == next.gameName &&
        listEquals(previous.memberIds, next.memberIds) &&
        previous.isReadOnly == next.isReadOnly &&
        previous.pinnedMessage == next.pinnedMessage &&
        previous.archivedAt == next.archivedAt;
  }

  void _updateChatUiState(Chat? chat) {
    if (chat == null) {
      setState(() {
        _chatLoaded = true;
        _chatError = null;
        _chatUi = null;
        _canSend = false;
        _bannerText = '';
        _isArchived = false;
        _gameIdForOwnerLookup = null;
        _gameOwnerFuture = null;
      });
      return;
    }

    final isArchived = chat.archivedAt != null &&
        chat.archivedAt!.isBefore(DateTime.now());
    final bannerText = chat.pinnedMessage.isNotEmpty
        ? chat.pinnedMessage
        : chat.isReadOnly
            ? 'This chat is read-only.'
            : '';
    final canSend = !chat.isReadOnly && !isArchived;

    final chatGameId = (chat.gameId ?? '').trim();
    if (chat.type == 'game' && chatGameId.isNotEmpty) {
      if (_gameIdForOwnerLookup != chatGameId) {
        _gameIdForOwnerLookup = chatGameId;
        _gameOwnerFuture = GamesRecord.getDocumentOnce(
          FirebaseFirestore.instance.collection('games').doc(chatGameId),
        );
      }
    } else {
      _gameIdForOwnerLookup = null;
      _gameOwnerFuture = null;
    }

    setState(() {
      _chatLoaded = true;
      _chatError = null;
      _chatUi = chat;
      _isArchived = isArchived;
      _bannerText = bannerText;
      _canSend = canSend;
    });

    final currentUserId = _currentUserId;
    if (!_didMarkSeen &&
        currentUserId != null &&
        chat.memberIds.contains(currentUserId)) {
      _didMarkSeen = true;
      _markChatSeen();
    }
  }

  PopupMenuButton<String> _buildDeleteMenu() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: AppTheme.of(context).primaryBtnText,
      ),
      tooltip: 'More options',
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
                      color: Colors.red,
                      letterSpacing: 0.0,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildChatActions() {
    final chat = _chatUi;
    if (chat == null) {
      return const [];
    }

    if (chat.type != 'game') {
      return [_buildDeleteMenu()];
    }

    final currentUserId = _currentUserId;
    if (currentUserId == null || _gameOwnerFuture == null) {
      return const [];
    }

    return [
      FutureBuilder<GamesRecord?>(
        future: _gameOwnerFuture,
        builder: (context, snapshot) {
          final game = snapshot.data;
          final ownerUid = game?.uid;
          final ownerRefId = game?.userRef?.id;
          final isOwner =
              ownerUid == currentUserId || ownerRefId == currentUserId;

          if (!isOwner) {
            return const SizedBox.shrink();
          }
          return _buildDeleteMenu();
        },
      ),
    ];
  }

  // AUDIT #5: Removed _shouldShowDateDivider, _isFirstInGroup, _isLastInGroup
  // These are now computed inline in the VM-based StreamBuilder to avoid confusion

  /// Mark chat and messages as read using batched writes
  ///
  /// AUDIT #8 FIX: Replaced sequential per-message writes with a single
  /// WriteBatch operation. This reduces network calls from N+1 to 2
  /// (one for chat-level unread count, one batch for all messages).
  Future<void> _markChatSeen() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return;
    }
    try {
      if (kDebugMode) {
        debugPrint('📖 UI: _markChatSeen called for chatId=${widget.chatId}');
      }

      // Update chat-level unread count
      await context
          .read<ChatProvider>()
          .markChatRead(chatId: widget.chatId, uid: currentUserId);

      // Mark all unread messages as read in a single batched operation
      // This replaces the previous sequential loop with a single WriteBatch
      final stats = await context.read<ChatProvider>().markMessagesAsReadBatch(
            chatId: widget.chatId,
            uid: currentUserId,
            limit: 100, // Check up to 100 recent messages
          );

      if (kDebugMode) {
        debugPrint(
            '✅ UI: _markChatSeen complete - ${stats['unreadCount']} unread messages, '
            '${stats['updatedCount']} updated in ${stats['batchCount']} batch(es)');
      }
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
    showAppDialog(
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
            'Failed to delete chat: ${error.toString().length > 50 ? error.toString().substring(0, 50) : error.toString()}',
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
    final replyTo = _replyToMessage;
    setState(() {
      _replyToMessage = null;
    });
    try {
      await context.read<ChatProvider>().sendMessage(
            chatId: widget.chatId,
            senderId: currentUserId,
            text: text,
          );
      // TODO: In a full implementation, we would store the replyTo message ID
      // in the message document and display it in the message bubble
    } catch (error, stackTrace) {
      context
          .read<ChatProvider>()
          .logError('sendMessage failed', error, stackTrace);
      if (!mounted) {
        return;
      }
      _messageController.text = text;
      setState(() {
        _replyToMessage = replyTo;
      });
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

  // AUDIT #5 FIX: Removed old _mergeMessages, using _mergeMessageVMs instead
  List<ChatMessageViewModel> _mergeMessageVMs(List<ChatMessageViewModel> latestVMs) {
    final merged = <ChatMessageViewModel>[];
    final ids = <String>{};

    // Add latest view models first
    for (final vm in latestVMs) {
      if (ids.add(vm.id)) {
        merged.add(vm);
      }
    }

    // Add older messages as view models (profiles already resolved on first fetch)
    for (final message in _olderMessages) {
      if (ids.add(message.id)) {
        // For older messages, we need to create VMs with profile lookup
        // ProfileProvider cache should have these already
        final profile = context.read<ProfileProvider>().getCachedProfile(message.senderId);
        merged.add(ChatMessageViewModel(
          message: message,
          senderDisplayName: profile?.displayName ?? '',
          senderPhotoUrl: profile?.photoUrl ?? '',
        ));
      }
    }

    return merged;
  }



  @override
  Widget build(BuildContext context) {
    final backgroundGreen = AppTheme.of(context).secondary;
    if (kDebugMode) {
      debugPrint(
        '🧱 UI: ChatDetails build chatId=${widget.chatId} '
        'chatLoaded=$_chatLoaded chatUi=${_chatUi?.id} '
        'chatError=${_chatError?.runtimeType} '
        'msgCtrl=${_messageController.hashCode} '
        'focus=${_messageFocusNode.hashCode} '
        'msgStream=${identityHashCode(_messagesStream)}',
      );
    }
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: backgroundGreen,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            foregroundColor: AppTheme.of(context).primaryBtnText,
            elevation: 0.0,
            shadowColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.of(context).primaryBtnText,
              ),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: _chatUi != null
                ? ChatHeaderTitle(
                    chat: _chatUi!,
                    currentUserId: _currentUserId,
                  )
                : AppText.cardTitle('Chat'),
            centerTitle: false,
            actions: _buildChatActions(),
          ),
          body: FairwayBackgroundDark(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight,
                ),
                child: Stack(
                  children: [
                    Column(
                      children: [
                  if (_bannerText.isNotEmpty || _isArchived)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        0,
                      ),
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppTheme.of(context).primaryBackground,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: AppTheme.of(context)
                              .primary
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.of(context).primary,
                            size: 20.0,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _bannerText.isNotEmpty
                                      ? _bannerText
                                      : 'This chat is archived.',
                                  style: AppTheme.of(context)
                                      .bodyMedium
                                      .override(
                                                          letterSpacing: 0.0,
                                      ),
                                ),
                                if (_isArchived)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: AppSpacing.xs,
                                    ),
                                    child: Text(
                                      'Messages are disabled.',
                                      style: AppTheme.of(context)
                                          .labelMedium
                                          .override(
                                                                  letterSpacing: 0.0,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Typing Indicator (AUDIT #5 FIX: removed nested FutureBuilder)
                  ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: StreamBuilder<Chat?>(
                        stream: _chatStream,
                        builder: (context, chatSnapshot) {
                          if (!chatSnapshot.hasData) {
                            return const SizedBox(height: 0);
                          }

                          final typingUserIds =
                              _getTypingUserNames(chatSnapshot.data!);
                          if (typingUserIds.isEmpty) {
                            return const SizedBox(height: 0);
                          }

                          // AUDIT #5 FIX: Use synchronous cache lookup instead of Future
                          // ProfileProvider's cache should already have these profiles
                          // from the main message stream
                          final profileProvider = context.read<ProfileProvider>();
                          final names = typingUserIds.map((uid) {
                            final profile = profileProvider.getCachedProfile(uid);
                            return profile?.displayName ?? 'Someone';
                          }).toList();

                          String typingText;
                          if (names.length == 1) {
                            typingText = '${names[0]} is typing...';
                          } else if (names.length == 2) {
                            typingText =
                                '${names[0]} and ${names[1]} are typing...';
                          } else {
                            typingText = 'Several people are typing...';
                          }

                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                                SizedBox(width: AppSpacing.sm),
                                Text(
                                  typingText,
                                  style: AppTheme.of(context).bodySmall.override(
                                                      color: Colors.white.withOpacity(0.6),
                                        fontStyle: FontStyle.italic,
                                        letterSpacing: 0.0,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: _chatError != null
                        ? Center(
                            child: AppText.body(
                              'Unable to load chat.',
                              color: AppTheme.of(context).secondaryText,
                            ),
                          )
                        : !_chatLoaded
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : _chatUi == null
                                ? Center(
                                    child: AppText.body(
                                      'Chat not found.',
                                      color: AppTheme.of(context).secondaryText,
                                    ),
                                  )
                                : StreamBuilder<List<ChatMessageViewModel>>(
                                    stream: _messageViewModelsStream,
                                    builder: (context, snapshot) {
                                      if (kDebugMode) {
                                        debugPrint(
                                            '📨 UI: VM StreamBuilder called for chatId: ${widget.chatId}');
                                        debugPrint(
                                            '📨 UI: snapshot.connectionState = ${snapshot.connectionState}');
                                        debugPrint(
                                            '📨 UI: snapshot.hasError = ${snapshot.hasError}');
                                        debugPrint(
                                            '📨 UI: snapshot.hasData = ${snapshot.hasData}');
                                      }

                                      if (snapshot.hasError) {
                                        if (kDebugMode) {
                                          debugPrint(
                                              '❌ UI: VM StreamBuilder error: ${snapshot.error}');
                                        }
                                        return Center(
                                          child: AppText.body(
                                            'Unable to load messages.',
                                            color: AppTheme.of(context).secondaryText,
                                          ),
                                        );
                                      }

                                      final hasCachedMessages =
                                          _latestMessageVMs.isNotEmpty ||
                                              _olderMessages.isNotEmpty;

                                      if (!snapshot.hasData) {
                                        if (kDebugMode) {
                                          debugPrint(
                                              '📨 UI: No data yet, showing loading indicator');
                                        }
                                        if (!hasCachedMessages) {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }
                                      }

                                      final latestVMs = snapshot.data ?? [];

                                      if (kDebugMode) {
                                        debugPrint(
                                            '📨 UI: Received ${latestVMs.length} view model(s)');
                                      }

                                      if (latestVMs.isEmpty && !hasCachedMessages) {
                                        if (kDebugMode) {
                                          debugPrint(
                                              '📨 UI: VM list is empty - showing "No messages yet"');
                                        }
                                        return Center(
                                          child: AppText.body(
                                            'No messages yet.',
                                            color: AppTheme.of(context).secondaryText,
                                          ),
                                        );
                                      }

                                      // Update cached VMs
                                      if (latestVMs.isNotEmpty) {
                                        _latestMessageVMs
                                          ..clear()
                                          ..addAll(latestVMs);
                                      }

                                      // Merge with older messages
                                      final messageVMs = latestVMs.isNotEmpty
                                          ? _mergeMessageVMs(latestVMs)
                                          : _latestMessageVMs;

                                      if (kDebugMode) {
                                        debugPrint(
                                            '📨 UI: After merging: ${messageVMs.length} message VMs');
                                      }

                                      final itemCount =
                                          messageVMs.length + (_hasMoreOlder ? 1 : 0);

                                      if (kDebugMode) {
                                        debugPrint(
                                            '📨 UI: Rendering ListView with $itemCount items');
                                      }

                                      if (messageVMs.isNotEmpty && kDebugMode) {
                                        final firstMessageText = messageVMs.first.text;
                                        final previewLength = firstMessageText.length < 30
                                            ? firstMessageText.length
                                            : 30;
                                        debugPrint(
                                            '📨 UI: First message text: ${firstMessageText.substring(0, previewLength)}');
                                      }

                                      final chat = _chatUi!;
                                      final totalMembers = chat.memberIds.length;
                                      final isGroupChat = chat.type == 'game';

                                      return ListView.builder(
                                        controller: _scrollController,
                                        padding: EdgeInsets.symmetric(
                                          vertical: AppSpacing.md,
                                        ),
                                        reverse: true,
                                        itemCount: itemCount,
                                        itemBuilder: (context, index) {
                                          if (_hasMoreOlder &&
                                              index == messageVMs.length) {
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

                                          final vm = messageVMs[index];
                                          final message = vm.message;
                                          final isMe =
                                              message.senderId == _currentUserId;

                                          // Helper method to check date divider
                                          final showDateDivider = () {
                                            if (index >= messageVMs.length - 1) {
                                              return true;
                                            }
                                            final currentMsg = messageVMs[index].message;
                                            final nextMsg = messageVMs[index + 1].message;
                                            if (currentMsg.createdAt == null ||
                                                nextMsg.createdAt == null) {
                                              return false;
                                            }
                                            final currentDate = DateTime(
                                              currentMsg.createdAt!.year,
                                              currentMsg.createdAt!.month,
                                              currentMsg.createdAt!.day,
                                            );
                                            final nextDate = DateTime(
                                              nextMsg.createdAt!.year,
                                              nextMsg.createdAt!.month,
                                              nextMsg.createdAt!.day,
                                            );
                                            return currentDate != nextDate;
                                          }();

                                          // Helper method to check first in group
                                          final isFirstInGroup = () {
                                            if (index >= messageVMs.length - 1) {
                                              return true;
                                            }
                                            final currentMsg = messageVMs[index].message;
                                            final nextMsg = messageVMs[index + 1].message;
                                            if (currentMsg.senderId != nextMsg.senderId) {
                                              return true;
                                            }
                                            if (currentMsg.createdAt != null &&
                                                nextMsg.createdAt != null) {
                                              final timeDiff = currentMsg.createdAt!
                                                  .difference(nextMsg.createdAt!);
                                              if (timeDiff.inMinutes > 2) {
                                                return true;
                                              }
                                            }
                                            return false;
                                          }();

                                          // Helper method to check last in group
                                          final isLastInGroup = () {
                                            if (index == 0) {
                                              return true;
                                            }
                                            final currentMsg = messageVMs[index].message;
                                            final previousMsg = messageVMs[index - 1].message;
                                            if (currentMsg.senderId != previousMsg.senderId) {
                                              return true;
                                            }
                                            if (currentMsg.createdAt != null &&
                                                previousMsg.createdAt != null) {
                                              final timeDiff = previousMsg.createdAt!
                                                  .difference(currentMsg.createdAt!);
                                              if (timeDiff.inMinutes > 2) {
                                                return true;
                                              }
                                            }
                                            return false;
                                          }();

                                          // Use resolved profile data from view model
                                          final senderName = isMe
                                              ? null
                                              : vm.senderDisplayName.trim().isNotEmpty
                                                  ? vm.senderDisplayName
                                                  : 'Golfer';
                                          final senderPhotoUrl =
                                              isMe ? null : vm.senderPhotoUrl;

                                          return Column(
                                            children: [
                                              ChatMessageBubble(
                                                isSentByCurrentUser: isMe,
                                                messageText: message.text,
                                                imageUrl: message.imageUrl,
                                                timestamp: message.createdAt,
                                                isFirstInGroup: isFirstInGroup,
                                                isLastInGroup: isLastInGroup,
                                                senderId: message.senderId,
                                                senderName: senderName,
                                                senderPhotoUrl: senderPhotoUrl,
                                                isGroupChat: isGroupChat,
                                                message: message,
                                                totalMembers: totalMembers,
                                                currentUserId: _currentUserId,
                                                onLongPress: () =>
                                                    _showReactionPicker(message),
                                                onReplySwipe: () {
                                                  setState(() {
                                                    _replyToMessage = message;
                                                  });
                                                  _messageFocusNode.requestFocus();
                                                },
                                                onImageTap: message.imageUrl.isNotEmpty
                                                    ? () => _showImageFullscreen(
                                                        message.imageUrl)
                                                    : null,
                                                onReactionTap: (emoji, hasReacted) =>
                                                    _handleReaction(
                                                        message, emoji, hasReacted),
                                              ),
                                              if (showDateDivider &&
                                                  message.createdAt != null)
                                                ChatDateDivider(
                                                  date: message.createdAt!,
                                                ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                  ),
                  ChatInputBar(
                    messageController: _messageController,
                    messageFocusNode: _messageFocusNode,
                    enabled: _canSend && _chatUi != null && _chatError == null,
                    onSendMessage: _sendMessage,
                    replyToMessage: _replyToMessage,
                    onCancelReply: () {
                      setState(() {
                        _replyToMessage = null;
                      });
                    },
                  ),
                ],
              ),
              // Scroll to Bottom FAB
              if (_showScrollToBottom)
                Positioned(
                  bottom: 90,
                  right: 16,
                  child: Semantics(
                    button: true,
                    label: 'Scroll to bottom',
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.of(context).primary,
                              AppTheme.of(context).primary.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.of(context)
                                  .primary
                                  .withOpacity(0.4),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: _scrollToBottom,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }
}
