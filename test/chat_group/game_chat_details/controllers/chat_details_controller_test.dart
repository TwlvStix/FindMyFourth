import 'dart:async';

import 'package:test/test.dart';

import 'package:find_my_fourth/chat_group/game_chat_details/controllers/chat_details_controller.dart';
import 'package:find_my_fourth/models/chat_message.dart';
import 'package:find_my_fourth/models/chat_message_view_model.dart';

void main() {
  group('ChatDetailsController', () {
    ChatDetailsController<String> createController() {
      final controller = ChatDetailsController<String>();
      controller.initializeSession(
        chatId: 'chat-1',
        pageSize: 2,
        visibleAfterCutoff: DateTime(2025, 1, 1),
      );
      return controller;
    }

    test('mergeMessageVMs dedupes and resolves missing display names',
        () async {
      final controller = createController();

      await controller.loadOlderMessages(
        startAfterCursor: null,
        fetchPage: ({
          required String chatId,
          required int pageSize,
          required DateTime? visibleAfter,
          required String? startAfter,
        }) async {
          return OlderPageData<String>(
            messages: [
              _vm(
                id: 'm2',
                senderId: 'u2',
                createdAt: DateTime(2025, 1, 2, 10, 0),
                senderDisplayName: '',
              ),
            ],
            hasMore: false,
            lastCursor: 'cursor-1',
          );
        },
      );

      final resolvedUids = <String>[];
      final merged = controller.mergeMessageVMs(
        latestVMs: [
          _vm(
            id: 'm1',
            senderId: 'u1',
            createdAt: DateTime(2025, 1, 2, 10, 2),
            senderDisplayName: '',
          ),
          _vm(
            id: 'm2',
            senderId: 'u2',
            createdAt: DateTime(2025, 1, 2, 10, 0),
            senderDisplayName: 'Existing Name',
          ),
        ],
        resolveDisplayName: (uid) {
          resolvedUids.add(uid);
          if (uid == 'u1') return 'Alice';
          if (uid == 'u2') return 'Bob';
          return null;
        },
      );

      expect(merged.map((vm) => vm.id).toList(), ['m1', 'm2']);
      expect(merged.first.senderDisplayName, 'Alice');
      expect(merged.last.senderDisplayName, 'Existing Name');
      expect(resolvedUids, contains('u1'));
      expect(resolvedUids, isNot(contains('u2')));
    });

    test('showDateDivider returns true only on day boundary', () {
      final controller = createController();
      final current = _vm(
        id: 'm1',
        senderId: 'u1',
        createdAt: DateTime(2025, 1, 2, 10, 0),
      );
      final sameDay = _vm(
        id: 'm2',
        senderId: 'u2',
        createdAt: DateTime(2025, 1, 2, 9, 0),
      );
      final previousDay = _vm(
        id: 'm3',
        senderId: 'u2',
        createdAt: DateTime(2025, 1, 1, 23, 59),
      );

      expect(
        controller.showDateDivider(current: current, previous: sameDay),
        isFalse,
      );
      expect(
        controller.showDateDivider(current: current, previous: previousDay),
        isTrue,
      );
      expect(
        controller.showDateDivider(current: current, previous: null),
        isTrue,
      );
    });

    test('grouping helpers split by sender and >2 minute gap', () {
      final controller = createController();
      final current = _vm(
        id: 'm1',
        senderId: 'u1',
        createdAt: DateTime(2025, 1, 2, 10, 10),
      );
      final sameSenderClose = _vm(
        id: 'm2',
        senderId: 'u1',
        createdAt: DateTime(2025, 1, 2, 10, 9),
      );
      final sameSenderFar = _vm(
        id: 'm3',
        senderId: 'u1',
        createdAt: DateTime(2025, 1, 2, 10, 0),
      );
      final otherSender = _vm(
        id: 'm4',
        senderId: 'u2',
        createdAt: DateTime(2025, 1, 2, 10, 9),
      );

      expect(
        controller.isFirstInGroup(current: current, previous: sameSenderClose),
        isFalse,
      );
      expect(
        controller.isFirstInGroup(current: current, previous: sameSenderFar),
        isTrue,
      );
      expect(
        controller.isFirstInGroup(current: current, previous: otherSender),
        isTrue,
      );

      expect(
        controller.isLastInGroup(current: current, next: sameSenderClose),
        isFalse,
      );
      expect(
        controller.isLastInGroup(current: current, next: sameSenderFar),
        isTrue,
      );
      expect(
        controller.isLastInGroup(current: current, next: otherSender),
        isTrue,
      );
    });

    test('loadOlderMessages updates state from callback result', () async {
      final controller = createController();
      final status = await controller.loadOlderMessages(
        startAfterCursor: 'start-1',
        fetchPage: ({
          required String chatId,
          required int pageSize,
          required DateTime? visibleAfter,
          required String? startAfter,
        }) async {
          expect(chatId, 'chat-1');
          expect(pageSize, 2);
          expect(visibleAfter, DateTime(2025, 1, 1));
          expect(startAfter, 'start-1');
          return OlderPageData<String>(
            messages: [
              _vm(
                id: 'm1',
                senderId: 'u1',
                createdAt: DateTime(2025, 1, 2, 10, 0),
              ),
            ],
            hasMore: true,
            lastCursor: 'cursor-2',
          );
        },
      );

      expect(status.isError, isFalse);
      expect(status.newMessageCount, 1);
      expect(controller.hasMoreOlder, isTrue);
      expect(controller.lastCursor, 'cursor-2');
      expect(controller.olderMessages.map((m) => m.id).toList(), ['m1']);
    });

    test('loadOlderMessages returns no-op success when already loading',
        () async {
      final controller = createController();
      final completer = Completer<OlderPageData<String>>();
      var fetchCount = 0;

      final firstFuture = controller.loadOlderMessages(
        startAfterCursor: null,
        fetchPage: ({
          required String chatId,
          required int pageSize,
          required DateTime? visibleAfter,
          required String? startAfter,
        }) {
          fetchCount++;
          return completer.future;
        },
      );

      expect(controller.isLoadingOlder, isTrue);

      final secondStatus = await controller.loadOlderMessages(
        startAfterCursor: null,
        fetchPage: ({
          required String chatId,
          required int pageSize,
          required DateTime? visibleAfter,
          required String? startAfter,
        }) async {
          fetchCount++;
          return OlderPageData<String>(
            messages: const [],
            hasMore: false,
            lastCursor: null,
          );
        },
      );

      expect(secondStatus.isError, isFalse);
      expect(secondStatus.newMessageCount, 0);
      expect(fetchCount, 1);

      completer.complete(
        OlderPageData<String>(
          messages: [
            _vm(
              id: 'm1',
              senderId: 'u1',
              createdAt: DateTime(2025, 1, 2, 10, 0),
            ),
          ],
          hasMore: false,
          lastCursor: 'cursor-1',
        ),
      );
      await firstFuture;
      expect(controller.isLoadingOlder, isFalse);
    });

    test('loadOlderMessages returns failure and resets loading on exception',
        () async {
      final controller = createController();
      final status = await controller.loadOlderMessages(
        startAfterCursor: null,
        fetchPage: ({
          required String chatId,
          required int pageSize,
          required DateTime? visibleAfter,
          required String? startAfter,
        }) async {
          throw StateError('boom');
        },
      );

      expect(status.isError, isTrue);
      expect(status.errorMessage, 'Unable to load older messages.');
      expect(controller.isLoadingOlder, isFalse);
    });

    test('hasMoreOlder comes exclusively from callback hasMore', () async {
      final controller = createController();
      await controller.loadOlderMessages(
        startAfterCursor: null,
        fetchPage: ({
          required String chatId,
          required int pageSize,
          required DateTime? visibleAfter,
          required String? startAfter,
        }) async {
          return OlderPageData<String>(
            messages: [
              _vm(
                id: 'm1',
                senderId: 'u1',
                createdAt: DateTime(2025, 1, 2, 10, 0),
              ),
            ],
            hasMore: true,
            lastCursor: 'cursor-1',
          );
        },
      );

      expect(controller.hasMoreOlder, isTrue);
    });

    test('reset clears state and requires reinitialization', () async {
      final controller = createController();
      await controller.loadOlderMessages(
        startAfterCursor: null,
        fetchPage: ({
          required String chatId,
          required int pageSize,
          required DateTime? visibleAfter,
          required String? startAfter,
        }) async {
          return OlderPageData<String>(
            messages: [
              _vm(
                id: 'm1',
                senderId: 'u1',
                createdAt: DateTime(2025, 1, 2, 10, 0),
              ),
            ],
            hasMore: false,
            lastCursor: 'cursor-1',
          );
        },
      );

      controller.reset();

      expect(controller.olderMessages, isEmpty);
      expect(controller.lastCursor, isNull);
      expect(controller.hasMoreOlder, isTrue);
      expect(controller.isLoadingOlder, isFalse);

      final status = await controller.loadOlderMessages(
        startAfterCursor: null,
        fetchPage: ({
          required String chatId,
          required int pageSize,
          required DateTime? visibleAfter,
          required String? startAfter,
        }) async {
          return const OlderPageData<String>(
            messages: [],
            hasMore: false,
            lastCursor: null,
          );
        },
      );
      expect(status.isError, isTrue);
    });
  });
}

ChatMessageViewModel _vm({
  required String id,
  required String senderId,
  required DateTime? createdAt,
  String senderDisplayName = '',
}) {
  return ChatMessageViewModel(
    message: ChatMessage(
      id: id,
      senderId: senderId,
      text: 'text-$id',
      imageUrl: '',
      videoUrl: '',
      createdAt: createdAt,
      reactions: const <String, List<String>>{},
      readBy: const <String>[],
      type: 'text',
      thumbnailUrl: '',
    ),
    senderDisplayName: senderDisplayName,
    senderPhotoUrl: '',
  );
}
