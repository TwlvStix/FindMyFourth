import '/models/chat_message_view_model.dart';

class LoadOlderStatus {
  final int newMessageCount;
  final String? errorMessage;
  final Object? error;
  final StackTrace? stackTrace;

  bool get isError => errorMessage != null;

  const LoadOlderStatus.success({required this.newMessageCount})
      : errorMessage = null,
        error = null,
        stackTrace = null;

  const LoadOlderStatus.failure({
    required this.errorMessage,
    this.error,
    this.stackTrace,
  }) : newMessageCount = 0;
}

class OlderPageData<TCursor> {
  final List<ChatMessageViewModel> messages;
  final bool hasMore;
  final TCursor? lastCursor;

  const OlderPageData({
    required this.messages,
    required this.hasMore,
    required this.lastCursor,
  });
}

class ChatDetailsController<TCursor> {
  final List<ChatMessageViewModel> _olderMessages = <ChatMessageViewModel>[];
  final Set<String> _olderMessageIds = <String>{};
  bool _hasMoreOlder = true;
  bool _isLoadingOlder = false;
  TCursor? _lastCursor;
  String _chatId = '';
  int _pageSize = 30;
  DateTime? _visibleAfterCutoff;
  bool _sessionInitialized = false;

  bool get hasMoreOlder => _hasMoreOlder;
  bool get isLoadingOlder => _isLoadingOlder;
  TCursor? get lastCursor => _lastCursor;
  List<ChatMessageViewModel> get olderMessages =>
      List<ChatMessageViewModel>.unmodifiable(_olderMessages);

  void initializeSession({
    required String chatId,
    required int pageSize,
    required DateTime? visibleAfterCutoff,
  }) {
    _chatId = chatId;
    _pageSize = pageSize;
    _visibleAfterCutoff = visibleAfterCutoff;
    _sessionInitialized = true;
    _olderMessages.clear();
    _olderMessageIds.clear();
    _lastCursor = null;
    _hasMoreOlder = true;
    _isLoadingOlder = false;
  }

  Future<LoadOlderStatus> loadOlderMessages({
    required TCursor? startAfterCursor,
    required Future<OlderPageData<TCursor>> Function({
      required String chatId,
      required int pageSize,
      required DateTime? visibleAfter,
      required TCursor? startAfter,
    }) fetchPage,
  }) async {
    if (!_sessionInitialized) {
      return const LoadOlderStatus.failure(
        errorMessage: 'Chat session is not initialized.',
      );
    }
    if (_isLoadingOlder || !_hasMoreOlder) {
      return const LoadOlderStatus.success(newMessageCount: 0);
    }

    _isLoadingOlder = true;
    try {
      final page = await fetchPage(
        chatId: _chatId,
        pageSize: _pageSize,
        visibleAfter: _visibleAfterCutoff,
        startAfter: _lastCursor ?? startAfterCursor,
      );

      var newMessageCount = 0;
      for (final vm in page.messages) {
        if (_olderMessageIds.add(vm.id)) {
          _olderMessages.add(vm);
          newMessageCount++;
        }
      }
      _lastCursor = page.lastCursor;
      _hasMoreOlder = page.hasMore;
      return LoadOlderStatus.success(newMessageCount: newMessageCount);
    } catch (error, stackTrace) {
      return LoadOlderStatus.failure(
        errorMessage: 'Unable to load older messages.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isLoadingOlder = false;
    }
  }

  List<ChatMessageViewModel> mergeMessageVMs({
    required List<ChatMessageViewModel> latestVMs,
    required String? Function(String uid) resolveDisplayName,
  }) {
    final merged = <ChatMessageViewModel>[];
    final ids = <String>{};
    final resolvedNameCache = <String, String?>{};

    ChatMessageViewModel withResolvedName(ChatMessageViewModel vm) {
      if (vm.senderDisplayName.trim().isNotEmpty) {
        return vm;
      }
      final cached = resolvedNameCache[vm.senderId];
      final resolved = cached ?? resolveDisplayName(vm.senderId);
      resolvedNameCache[vm.senderId] = resolved;
      if (resolved == null || resolved.trim().isEmpty) {
        return vm;
      }
      return vm.copyWith(senderDisplayName: resolved.trim());
    }

    for (final vm in latestVMs) {
      if (ids.add(vm.id)) {
        merged.add(withResolvedName(vm));
      }
    }
    for (final vm in _olderMessages) {
      if (ids.add(vm.id)) {
        merged.add(withResolvedName(vm));
      }
    }
    return merged;
  }

  bool showDateDivider({
    required ChatMessageViewModel current,
    ChatMessageViewModel? previous,
  }) {
    if (previous == null) {
      return true;
    }
    final currentDateTime = current.createdAt;
    final previousDateTime = previous.createdAt;
    if (currentDateTime == null || previousDateTime == null) {
      return false;
    }

    final currentDate = DateTime(
      currentDateTime.year,
      currentDateTime.month,
      currentDateTime.day,
    );
    final previousDate = DateTime(
      previousDateTime.year,
      previousDateTime.month,
      previousDateTime.day,
    );
    return currentDate != previousDate;
  }

  bool isFirstInGroup({
    required ChatMessageViewModel current,
    ChatMessageViewModel? previous,
  }) {
    if (previous == null) {
      return true;
    }
    if (current.senderId != previous.senderId) {
      return true;
    }

    final currentDateTime = current.createdAt;
    final previousDateTime = previous.createdAt;
    if (currentDateTime != null && previousDateTime != null) {
      final diffMinutes =
          currentDateTime.difference(previousDateTime).inMinutes.abs();
      if (diffMinutes > 2) {
        return true;
      }
    }
    return false;
  }

  bool isLastInGroup({
    required ChatMessageViewModel current,
    ChatMessageViewModel? next,
  }) {
    if (next == null) {
      return true;
    }
    if (current.senderId != next.senderId) {
      return true;
    }

    final currentDateTime = current.createdAt;
    final nextDateTime = next.createdAt;
    if (currentDateTime != null && nextDateTime != null) {
      final diffMinutes =
          nextDateTime.difference(currentDateTime).inMinutes.abs();
      if (diffMinutes > 2) {
        return true;
      }
    }
    return false;
  }

  void reset() {
    _olderMessages.clear();
    _olderMessageIds.clear();
    _lastCursor = null;
    _hasMoreOlder = true;
    _isLoadingOlder = false;
    _chatId = '';
    _pageSize = 30;
    _visibleAfterCutoff = null;
    _sessionInitialized = false;
  }
}
