import 'package:flutter/foundation.dart';

import '/backend/backend.dart';
import '/core/utils/app_log.dart';
import '/models/chat_message.dart';
import '/models/chat_message_view_model.dart';
import '/providers/chat_provider.dart';
import '/providers/profile_provider.dart';

/// Manages view model stream composition for ChatProvider.
///
/// Extracted from ChatProvider to keep it under the 500-line limit.
/// Combines raw Firestore streams with profile resolution to produce
/// ready-to-render view models.
class ChatViewModelManager {
  ChatViewModelManager({required ChatProvider chatProvider})
      : _chatProvider = chatProvider;

  final ChatProvider _chatProvider;
  bool _disposed = false;

  /// Stream of chat message view models with resolved profiles.
  ///
  /// Combines message snapshot stream with profile resolution in a single stream,
  /// avoiding nested StreamBuilder/FutureBuilder patterns and repeated profile fetches.
  ///
  /// Uses ProfileProvider's memoized cache to avoid re-fetching profiles on every rebuild.
  Stream<List<ChatMessageViewModel>> gameChatMessageViewModelsStream({
    required String chatId,
    required int limit,
    required ProfileProvider profileProvider,
    DateTime? visibleAfter,
  }) {
    if (kDebugMode) {
      AppLog.d(
          '🔵 ChatViewModelManager: Creating VM stream for chatId=$chatId (should happen once per screen)');
    }

    return _chatProvider
        .messagesSnapshotStream(
            chatId: chatId, limit: limit, visibleAfter: visibleAfter)
        .asyncMap((snapshot) async {
      if (_disposed) return <ChatMessageViewModel>[];

      final docs = snapshot.docs;

      if (docs.isEmpty) {
        return <ChatMessageViewModel>[];
      }

      // Convert docs to ChatMessage objects
      final messages = docs.map(ChatMessage.fromDoc).toList();

      // Derive unique sender IDs
      final senderIds = messages.map((msg) => msg.senderId).toSet().toList();

      if (kDebugMode) {
        AppLog.d(
            '🔵 ChatViewModelManager: VM stream emit - ${messages.length} messages, ${senderIds.length} unique senders');
      }

      // Fetch profiles using ProfileProvider's memoized cache
      Map<String, UsersRecord> profileMap = {};
      if (senderIds.isNotEmpty) {
        try {
          profileMap = await profileProvider.batchGetProfiles(senderIds);

          if (kDebugMode) {
            final newSenderIds = senderIds
                .where((id) => !profileProvider.isProfileCacheValid(id))
                .toList();
            if (newSenderIds.isNotEmpty) {
              AppLog.d(
                  '🆕 ChatViewModelManager: Profile fetch triggered for new senderIds: $newSenderIds');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            AppLog.d(
                '❌ ChatViewModelManager: Failed to fetch profiles: $e');
          }
        }
      }

      // Create view models
      return messages.map((msg) {
        final profile = profileMap[msg.senderId];
        return ChatMessageViewModel(
          message: msg,
          senderDisplayName: profile?.displayName ?? '',
          senderPhotoUrl: profile?.photoUrl ?? '',
        );
      }).toList();
    });
  }

  /// Stream of chat row view models with resolved profiles.
  ///
  /// Combines chat list stream with profile resolution in a single stream,
  /// avoiding nested StreamBuilder/FutureBuilder patterns and repeated profile fetches.
  ///
  /// Uses ProfileProvider's memoized cache to avoid re-fetching profiles on every rebuild.
  Stream<List<ChatRowViewModel>> chatRowsStream({
    required String currentUserId,
    required ProfileProvider profileProvider,
    int limit = 50,
  }) {
    if (kDebugMode) {
      AppLog.d(
          '💬 ChatViewModelManager: Creating chat rows VM stream for userId=$currentUserId (should happen once per screen)');
    }

    return _chatProvider
        .chatListStream(uid: currentUserId, limit: limit)
        .asyncMap((chats) async {
      if (_disposed) return <ChatRowViewModel>[];

      if (chats.isEmpty) {
        return <ChatRowViewModel>[];
      }

      // Collect ALL member IDs from all chats for group avatar display.
      // For game chats, include the current user so their avatar appears
      // in the group split; for direct chats, exclude them.
      final allMemberIds = <String>{};
      for (final chat in chats) {
        for (final memberId in chat.memberIds) {
          if (memberId.isEmpty) continue;
          if (chat.type == 'game' || memberId != currentUserId) {
            allMemberIds.add(memberId);
          }
        }
      }

      if (kDebugMode) {
        AppLog.d(
            '💬 ChatViewModelManager: Chat rows VM emit - ${chats.length} chats, ${allMemberIds.length} member profiles needed');
      }

      // Fetch profiles using ProfileProvider's memoized cache
      Map<String, UsersRecord> profileMap = {};
      if (allMemberIds.isNotEmpty) {
        try {
          profileMap =
              await profileProvider.batchGetProfiles(allMemberIds.toList());

          if (kDebugMode) {
            final newUserIds = allMemberIds
                .where((id) => !profileProvider.isProfileCacheValid(id))
                .toList();
            if (newUserIds.isNotEmpty) {
              AppLog.d(
                  '🆕 ChatViewModelManager: Profile fetch triggered for new userIds: $newUserIds');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            AppLog.d(
                '❌ ChatViewModelManager: Failed to fetch profiles: $e');
          }
        }
      }

      // Create view models
      return chats.map((chat) {
        final unreadCount = chat.unreadCountByUser[currentUserId] ?? 0;

        String displayName;
        String photoUrl = '';

        // Build members list for group avatar.
        // Game chats: include current user so the group avatar shows all members.
        // Direct chats: exclude current user (show the other person only).
        final members = <ChatMemberInfo>[];
        final avatarMemberIds = chat.type == 'game'
            ? chat.memberIds.where((id) => id.isNotEmpty).take(4).toList()
            : chat.memberIds
                .where((id) => id != currentUserId && id.isNotEmpty)
                .take(4)
                .toList();

        if (kDebugMode) {
          AppLog.d('💬 VM: chat=${chat.id} type=${chat.type} '
              'allMemberIds=${chat.memberIds.length} '
              'avatarMemberIds=${avatarMemberIds.length}');
        }

        for (final memberId in avatarMemberIds) {
          final profile = profileMap[memberId];
          final name = (profile?.displayName ?? '').trim().isNotEmpty
              ? profile!.displayName
              : 'Golfer';
          members.add(ChatMemberInfo(
            name: name,
            photoUrl: profile?.photoUrl,
          ));
        }

        if (kDebugMode) {
          AppLog.d('💬 VM: chat=${chat.id} '
              'resolvedMembers=${members.length}');
        }

        if (chat.type == 'game') {
          displayName = (chat.gameName ?? '').trim().isNotEmpty
              ? chat.gameName!
              : 'Game Chat';
        } else {
          final otherUserId = chat.memberIds.firstWhere(
            (id) => id != currentUserId,
            orElse: () => currentUserId,
          );
          final profile = profileMap[otherUserId];
          displayName = (profile?.displayName ?? '').trim().isNotEmpty
              ? profile!.displayName
              : 'Golfer';
          photoUrl = profile?.photoUrl ?? '';
        }

        return ChatRowViewModel(
          chatId: chat.id,
          displayName: displayName,
          photoUrl: photoUrl,
          lastMessage: chat.lastMessage,
          lastMessageAt: chat.lastMessageAt,
          unreadCount: unreadCount,
          members: members,
        );
      }).toList();
    });
  }

  void dispose() {
    _disposed = true;
  }
}
