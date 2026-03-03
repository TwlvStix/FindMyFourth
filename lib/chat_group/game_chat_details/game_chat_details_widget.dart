import 'dart:async';
import '/core/utils/state_update.dart';
import 'dart:ui' as ui;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '/core/utils/app_log.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/models/chat.dart';
import '/models/chat_message.dart';
import '/models/chat_message_view_model.dart';
import '/providers/chat_provider.dart';
import '/providers/profile_provider.dart';
import '/core/motion/motion_helpers.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_text.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import 'components/chat_details_actions.dart';
import 'components/chat_details_body.dart';
import 'components/chat_header_title.dart';
import 'components/chat_image_source_sheet.dart';
import 'components/chat_image_viewer.dart';
import 'components/chat_pending_upload_bubble.dart';
import 'components/chat_reaction_picker.dart';
import 'controllers/chat_details_controller.dart';
import 'controllers/chat_details_side_effects.dart';

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
  Stream<QuerySnapshot>? _messagesStream;
  Stream<List<ChatMessageViewModel>>? _messageViewModelsStream;
  StreamSubscription<Chat?>? _chatUiSubscription;
  StreamSubscription<QuerySnapshot>? _messagesSnapshotSubscription;
  // Visibility cutoff from memberJoinedAt — set when the first chat event arrives.
  DateTime? _visibleAfter;
  bool _streamsInitialized = false;
  static const int _initialPageSize = 40;
  static const int _pageSize = 30;
  final List<ChatMessageViewModel> _latestMessageVMs = [];
  DocumentSnapshot? _lastStreamDoc;
  final ChatDetailsController<DocumentSnapshot> _detailsController =
      ChatDetailsController<DocumentSnapshot>();
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
  bool _didMarkSeen = false;
  final List<PendingUploadItem> _pendingUploads = [];

  String? get _currentUserId {
    final uid = currentUserUid;
    return uid.isEmpty ? null : uid;
  }

  @override
  void initState() {
    super.initState();
    AppLog.d('📨 UI: Chat page loaded for chatId: ${widget.chatId}');
    AppLog.d('📨 UI: Current user ID: $_currentUserId');
    final chatProvider = context.read<ChatProvider>();
    _chatStream = chatProvider.chatStream(widget.chatId);
    _chatUiStream = _chatStream.distinct(_chatUiEquals);
    // Message streams are initialized lazily in _updateChatUiState on the first
    // chat event, so that we can read memberJoinedAt[uid] for fresh-start filtering.
    _chatUiSubscription = _chatUiStream.listen(
      (chat) {
        if (!mounted) return;
        _updateChatUiState(chat);
      },
      onError: (error) {
        if (!mounted) return;
        if (kDebugMode) {
          AppLog.d(
              '❌ UI: Chat stream error for chatId=${widget.chatId}: $error');
        }
        updateState(this, () {
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
      AppLog.d('📨 UI: Disposing ChatDetails for chatId=${widget.chatId}');
    }
    _typingTimer?.cancel();
    _chatUiSubscription?.cancel();
    _messagesSnapshotSubscription?.cancel();
    _detailsController.reset();
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
      AppLog.d(
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

  String? _typingTextForChat(Chat chat) {
    final typingUserIds = _getTypingUserNames(chat);
    if (typingUserIds.isEmpty) {
      return null;
    }

    final profileProvider = context.read<ProfileProvider>();
    final names = typingUserIds.map((uid) {
      final profile = profileProvider.getCachedProfile(uid);
      return profile?.displayName ?? 'Someone';
    }).toList();

    if (names.length == 1) {
      return '${names[0]} is typing...';
    }
    if (names.length == 2) {
      return '${names[0]} and ${names[1]} are typing...';
    }
    return 'Several people are typing...';
  }

  void _showImageFullscreen(String imageUrl) {
    showAppDialog(
      context: context,
      barrierColor: Colors.black87, // Keep: no 87% token
      builder: (BuildContext dialogContext) => ChatImageViewer(
        imageUrl: imageUrl,
        onClose: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  Future<void> _handleReaction(
      ChatMessage message, String emoji, bool hasReacted) async {
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

    showAppBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext context) => ChatReactionPicker(
        message: message,
        currentUserId: currentUserId,
        onReactionToggled: (emoji, hasReacted) =>
            _handleReaction(message, emoji, hasReacted),
      ),
    );
  }

  void _onScroll() {
    // Show FAB when scrolled up more than 200 pixels from bottom
    final showFab =
        _scrollController.hasClients && _scrollController.offset > 200;
    if (showFab != _showScrollToBottom) {
      updateState(this, () {
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
        previous.deletesAt == next.deletesAt;
  }

  void _updateChatUiState(Chat? chat) {
    if (chat == null) {
      _messagesSnapshotSubscription?.cancel();
      _messagesSnapshotSubscription = null;
      _detailsController.reset();
      _lastStreamDoc = null;
      _streamsInitialized = false;
      updateState(this, () {
        _chatLoaded = true;
        _chatError = null;
        _chatUi = null;
        _canSend = false;
        _bannerText = '';
        _isArchived = false;
      });
      return;
    }

    // Initialize message streams on the first valid chat event so we can apply
    // the memberJoinedAt visibility cutoff for fresh-start-on-rejoin.
    if (!_streamsInitialized) {
      _streamsInitialized = true;
      final currentUserId = _currentUserId;
      _visibleAfter =
          currentUserId != null ? chat.memberJoinedAt[currentUserId] : null;
      _detailsController.initializeSession(
        chatId: widget.chatId,
        pageSize: _pageSize,
        visibleAfterCutoff: _visibleAfter,
      );
      final chatProvider = context.read<ChatProvider>();
      final profileProvider = context.read<ProfileProvider>();
      _messagesStream = chatProvider.messagesSnapshotStream(
        chatId: widget.chatId,
        limit: _initialPageSize,
        visibleAfter: _visibleAfter,
      );
      _messagesSnapshotSubscription?.cancel();
      _messagesSnapshotSubscription = _messagesStream!.listen(
        (snapshot) {
          _lastStreamDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        },
      );
      _messageViewModelsStream = chatProvider.gameChatMessageViewModelsStream(
        chatId: widget.chatId,
        limit: _initialPageSize,
        profileProvider: profileProvider,
        visibleAfter: _visibleAfter,
      );
    }

    // isReadOnly is now the sole indicator of read-only state
    // (deletesAt is only for scheduling deletion, not for send permissions)
    final isArchived = chat.isReadOnly;
    final bannerText = chat.pinnedMessage.isNotEmpty
        ? chat.pinnedMessage
        : chat.isReadOnly
            ? 'This chat is read-only.'
            : '';
    final canSend = !chat.isReadOnly;

    updateState(this, () {
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

  Future<void> _markChatSeen() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;
    await ChatDetailsSideEffects.markChatSeen(
      chatProvider: context.read<ChatProvider>(),
      chatId: widget.chatId,
      uid: currentUserId,
      visibleAfter: _visibleAfter,
      isMounted: () => mounted,
    );
  }

  Future<void> _showLeaveConfirmation() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null || !mounted) return;
    await ChatDetailsSideEffects.showLeaveConfirmation(
      context: context,
      chatId: widget.chatId,
      uid: currentUserId,
      chatProvider: context.read<ChatProvider>(),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.navyDark,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppBorderRadius.lg)),
      ),
      builder: (sheetCtx) => ChatImageSourceSheet(
        onGallerySelected: () {
          Navigator.of(sheetCtx).pop();
          _pickAndSendImage(ImageSource.gallery);
        },
        onCameraSelected: () {
          Navigator.of(sheetCtx).pop();
          _pickAndSendImage(ImageSource.camera);
        },
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 70,
    );
    if (xFile == null || !mounted) return;

    final bytes = await xFile.readAsBytes();

    // Decode dimensions for aspect-ratio skeleton
    double? imgWidth, imgHeight;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      imgWidth = frame.image.width.toDouble();
      imgHeight = frame.image.height.toDouble();
      frame.image.dispose();
    } catch (_) {}

    final uploadId = DateTime.now().millisecondsSinceEpoch.toString();
    if (!mounted) return;
    updateState(this, () {
      _pendingUploads.add(PendingUploadItem(id: uploadId, previewBytes: bytes));
    });

    try {
      final path =
          'chat_images/${widget.chatId}/${uploadId}_$currentUserId.jpg';
      final ref = FirebaseStorage.instance.ref().child(path);
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putData(bytes, metadata);

      uploadTask.snapshotEvents.listen(
        (snapshot) {
          if (!mounted) return;
          final total = snapshot.totalBytes;
          final progress = total > 0 ? snapshot.bytesTransferred / total : 0.0;
          updateState(this, () {
            final idx = _pendingUploads.indexWhere((u) => u.id == uploadId);
            if (idx != -1) {
              _pendingUploads[idx] =
                  _pendingUploads[idx].copyWith(progress: progress);
            }
          });
        },
        onError: (_) {}, // errors are handled via await uploadTask below
        cancelOnError: true,
      );

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();

      if (!mounted) return;
      await context.read<ChatProvider>().sendImageMessage(
            chatId: widget.chatId,
            senderId: currentUserId,
            imageUrl: downloadUrl,
            thumbnailUrl: downloadUrl,
            imageWidth: imgWidth,
            imageHeight: imgHeight,
          );

      if (!mounted) return;
      updateState(
          this, () => _pendingUploads.removeWhere((u) => u.id == uploadId));
    } catch (error, stackTrace) {
      AppLog.d('📷 Image upload error: $error\n$stackTrace');
      if (!mounted) return;
      updateState(
          this, () => _pendingUploads.removeWhere((u) => u.id == uploadId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kDebugMode
                ? 'Upload error: $error'
                : 'Failed to send image. Please try again.',
          ),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _pickAndSendImage(source),
          ),
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
    updateState(this, () {
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
      if (!mounted) return;
      context
          .read<ChatProvider>()
          .logError('sendMessage failed', error, stackTrace);
      if (!mounted) {
        return;
      }
      _messageController.text = text;
      updateState(this, () {
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
    final chatProvider = context.read<ChatProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final statusFuture = _detailsController.loadOlderMessages(
      startAfterCursor: _lastStreamDoc,
      fetchPage: ({
        required String chatId,
        required int pageSize,
        required DateTime? visibleAfter,
        required DocumentSnapshot? startAfter,
      }) async {
        final page = await chatProvider.messagesPage(
          chatId: chatId,
          limit: pageSize,
          startAfter: startAfter,
          visibleAfter: visibleAfter,
        );
        final pageVMs = page.messages.map((message) {
          final profile = profileProvider.getCachedProfile(message.senderId);
          return ChatMessageViewModel(
            message: message,
            senderDisplayName: profile?.displayName ?? '',
            senderPhotoUrl: profile?.photoUrl ?? '',
          );
        }).toList();
        return OlderPageData<DocumentSnapshot>(
          messages: pageVMs,
          hasMore: page.messages.length >= pageSize,
          lastCursor: page.lastDoc,
        );
      },
    );
    if (!mounted) return;
    updateState(this, () {});

    final status = await statusFuture;
    if (!mounted) return;

    if (status.isError) {
      chatProvider.logError(
        'loadOlderMessages failed',
        status.error ?? Exception(status.errorMessage ?? 'Unknown error'),
        status.stackTrace ?? StackTrace.current,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load older messages.'),
        ),
      );
    }

    if (mounted) {
      updateState(this, () {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundGreen = AppColors.navy;
    if (kDebugMode) {
      AppLog.d(
        '🧱 UI: ChatDetails build chatId=${widget.chatId} '
        'chatLoaded=$_chatLoaded chatUi=${_chatUi?.id} '
        'chatError=${_chatError?.runtimeType} '
        'msgCtrl=${_messageController.hashCode} '
        'focus=${_messageFocusNode.hashCode} '
        'msgStream=${identityHashCode(_messagesStream ?? this)}',
      );
    }
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: backgroundGreen,
          appBar: AppBar(
            backgroundColor: AppColors.transparent,
            surfaceTintColor: AppColors.transparent,
            scrolledUnderElevation: 0,
            foregroundColor: AppColors.pure,
            elevation: 0.0,
            shadowColor: AppColors.transparent,
            leading: PremiumBackButton(
              onTap: () => Navigator.of(context).maybePop(),
            ),
            title: _chatUi != null
                ? ChatHeaderTitle(
                    chat: _chatUi!,
                    currentUserId: _currentUserId,
                  )
                : AppText.cardTitle('Chat'),
            centerTitle: false,
            actions: _chatUi == null
                ? const []
                : [
                    ChatDetailsActions(
                      onLeaveSelected: _showLeaveConfirmation,
                    ),
                  ],
          ),
          body: FairwayBackgroundDark(
            child: ChatDetailsBody(
              chatId: widget.chatId,
              chatStream: _chatStream,
              chatError: _chatError,
              chatLoaded: _chatLoaded,
              chatUi: _chatUi,
              bannerText: _bannerText,
              isArchived: _isArchived,
              currentUserId: _currentUserId,
              scrollController: _scrollController,
              messageController: _messageController,
              messageFocusNode: _messageFocusNode,
              messageViewModelsStream: _messageViewModelsStream,
              cachedLatestMessageVMs: _latestMessageVMs,
              detailsController: _detailsController,
              pendingUploads: _pendingUploads,
              canSend: _canSend,
              replyToMessage: _replyToMessage,
              showScrollToBottom: _showScrollToBottom,
              onLoadOlderMessages: _loadOlderMessages,
              onMessageLongPress: _showReactionPicker,
              onReplySwipe: (message) {
                updateState(this, () {
                  _replyToMessage = message;
                });
                _messageFocusNode.requestFocus();
              },
              onImageTap: _showImageFullscreen,
              onReactionTap: _handleReaction,
              onSendMessage: _sendMessage,
              onCancelReply: () {
                updateState(this, () {
                  _replyToMessage = null;
                });
              },
              onAttachImage:
                  (_canSend && _chatUi != null) ? _showImageSourceSheet : null,
              onScrollToBottom: _scrollToBottom,
              typingTextForChat: _typingTextForChat,
              onCacheLatestMessageVMs: (latestVMs) {
                _latestMessageVMs
                  ..clear()
                  ..addAll(latestVMs);
              },
            ),
          ),
        ),
      ),
    );
  }
}
