import 'dart:async';

import 'package:flutter/foundation.dart';

import '/core/utils/app_log.dart';
import '/models/chat.dart';
import '/providers/chat_provider.dart';
import '/providers/profile_provider.dart';

/// Helper for managing typing indicator state and display text.
///
/// Handles:
/// - Broadcasting typing status with 2-second debounce
/// - Timer lifecycle (start/cancel)
/// - Formatting "X is typing..." text from participant data
/// - Filtering stale typing entries (>3 seconds old)
class ChatTypingHelper {
  ChatTypingHelper({
    required this.chatId,
    required this.chatProvider,
    required this.getCurrentUserId,
  });

  final String chatId;
  final ChatProvider chatProvider;
  final String? Function() getCurrentUserId;

  bool _isTyping = false;
  Timer? _typingTimer;

  bool get isTyping => _isTyping;

  /// Call when text input changes to broadcast typing status.
  void onTextChanged(String text) {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return;

    final hasText = text.trim().isNotEmpty;
    if (kDebugMode) {
      AppLog.d(
        '✍️ UI: onTextChanged chatId=$chatId hasText=$hasText '
        'textLen=${text.length} isTyping=$_isTyping',
      );
    }

    // Start typing if we have text and weren't already typing
    if (hasText && !_isTyping) {
      _isTyping = true;
      chatProvider.setTypingStatus(
        chatId: chatId,
        uid: currentUserId,
        isTyping: true,
      );
    }

    // Reset the stop-typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        chatProvider.setTypingStatus(
          chatId: chatId,
          uid: currentUserId,
          isTyping: false,
        );
      }
    });
  }

  /// Returns the list of user IDs currently typing (excluding current user).
  List<String> getTypingUserIds(Chat chat) {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return [];

    final now = DateTime.now();
    return chat.typingUsers.entries
        .where((entry) =>
            entry.key != currentUserId &&
            now.difference(entry.value).inSeconds < 3)
        .map((entry) => entry.key)
        .toList();
  }

  /// Returns formatted typing text like "Alice is typing..." or null if no one is typing.
  String? getTypingText(Chat chat, ProfileProvider profileProvider) {
    final typingUserIds = getTypingUserIds(chat);
    if (typingUserIds.isEmpty) {
      return null;
    }

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

  /// Must be called in widget dispose to cancel the timer.
  void dispose() {
    _typingTimer?.cancel();
  }
}
