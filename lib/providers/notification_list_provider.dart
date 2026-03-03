import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '/core/utils/app_log.dart';
import '/services/notification_crud_service.dart';

/// Lightweight domain model for notification list items.
///
/// Maps Firestore notification documents to typed fields for UI consumption.
/// Keeps [reference] internal for mutation operations.
class NotificationListItem {
  final String id;
  final String type;
  final String? title;
  final String? body;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic> data;
  final DocumentReference reference;

  NotificationListItem._({
    required this.id,
    required this.type,
    this.title,
    this.body,
    required this.isRead,
    this.createdAt,
    required this.data,
    required this.reference,
  });

  factory NotificationListItem.fromDoc(QueryDocumentSnapshot doc) {
    final raw = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationListItem._(
      id: doc.id,
      type: (raw['type'] as String?) ?? '',
      title: raw['title'] as String?,
      body: raw['body'] as String?,
      isRead: raw['read'] == true,
      createdAt: (raw['createdAt'] as Timestamp?)?.toDate(),
      data: (raw['data'] as Map?)?.cast<String, dynamic>() ?? {},
      reference: doc.reference,
    );
  }
}

/// Immutable snapshot of notification list state for selector consumption.
///
/// Equality based on list identity (not deep) + primitive flags.
/// Provider caches unmodifiable list reference to ensure stable comparisons.
class NotificationListViewState {
  final List<NotificationListItem> notifications;
  final bool hasError;
  final bool isListening;
  final bool isLoadingMore;
  final bool hasMore;
  final bool loadMoreError;

  const NotificationListViewState({
    required this.notifications,
    required this.hasError,
    required this.isListening,
    required this.isLoadingMore,
    required this.hasMore,
    required this.loadMoreError,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationListViewState &&
          identical(notifications, other.notifications) &&
          hasError == other.hasError &&
          isListening == other.isListening &&
          isLoadingMore == other.isLoadingMore &&
          hasMore == other.hasMore &&
          loadMoreError == other.loadMoreError;

  @override
  int get hashCode => Object.hash(
        identityHashCode(notifications),
        hasError,
        isListening,
        isLoadingMore,
        hasMore,
        loadMoreError,
      );
}

/// Provider for notification list operations with lazy streaming and pagination.
///
/// Features:
/// - Lazy streaming: Widget calls [startListening]/[stopListening] in lifecycle
/// - Auth-reactive: Clears state on UID change via FirebaseAuth.authStateChanges
/// - Dedupe: First page stream + load-more fetch are merged without duplicates
/// - Domain model: Exposes [NotificationListItem] list, not Firestore types
/// - Unread count: Separate lightweight stream for badge via [unreadCountStream]
class NotificationListProvider extends ChangeNotifier {
  NotificationListProvider({NotificationCrudService? service})
      : _service = service ?? NotificationCrudService() {
    _init();
  }

  final NotificationCrudService _service;
  bool _disposed = false;
  Timer? _notifyTimer;

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH TRACKING (FirebaseAuth.authStateChanges only, NOT user doc stream)
  // ═══════════════════════════════════════════════════════════════════════════
  String? _activeUid;
  StreamSubscription<User?>? _authSubscription;

  // ═══════════════════════════════════════════════════════════════════════════
  // LISTENING STATE (LAZY - only active when widget calls startListening)
  // ═══════════════════════════════════════════════════════════════════════════
  bool _isListening = false;
  DocumentReference? _currentUserRef;

  // ═══════════════════════════════════════════════════════════════════════════
  // FIRST PAGE STATE (real-time stream)
  // ═══════════════════════════════════════════════════════════════════════════
  final Map<String, NotificationListItem> _notificationMap = {};
  List<String> _orderedIds = [];
  StreamSubscription<QuerySnapshot>? _firstPageSubscription;
  bool _hasStreamError = false;

  /// Cached unmodifiable list for stable selector comparisons.
  /// Updated only when list content/order actually changes.
  List<NotificationListItem> _cachedNotificationsList = const [];

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD-MORE STATE (fetch-based pagination)
  // ═══════════════════════════════════════════════════════════════════════════
  DocumentSnapshot? _lastDoc;
  int _firstPageSize = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _loadMoreError = false;

  static const int _pageSize = 50;

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS (expose domain models, not Firestore types)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Ordered list of notifications (first page + loaded more, deduped).
  /// Returns cached unmodifiable list for stable selector comparisons.
  List<NotificationListItem> get notifications => _cachedNotificationsList;

  /// True if the stream encountered an error.
  bool get hasError => _hasStreamError;

  /// True if a load-more operation is in progress.
  bool get isLoadingMore => _isLoadingMore;

  /// True if more pages are available to load.
  bool get hasMore => _hasMore;

  /// True if the last load-more attempt failed.
  bool get loadMoreError => _loadMoreError;

  /// True if no notifications exist and no error occurred.
  bool get isEmpty => _notificationMap.isEmpty && !_hasStreamError;

  /// True if there are notifications to display (regardless of error state).
  /// Use for app bar action visibility.
  bool get hasNotifications => _notificationMap.isNotEmpty;

  /// True if actively listening to the first-page stream.
  bool get isListening => _isListening;

  /// Snapshot of list state for Selector consumption.
  ///
  /// Use with context.select() to only rebuild when relevant state changes.
  NotificationListViewState get listViewState => NotificationListViewState(
        notifications: _cachedNotificationsList,
        hasError: _hasStreamError,
        isListening: _isListening,
        isLoadingMore: _isLoadingMore,
        hasMore: _hasMore,
        loadMoreError: _loadMoreError,
      );

  /// Update the cached notifications list.
  /// Call this whenever _orderedIds or _notificationMap content changes.
  void _updateCachedList() {
    _cachedNotificationsList = List.unmodifiable(
      _orderedIds.map((id) => _notificationMap[id]!),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INIT & AUTH STATE
  // ═══════════════════════════════════════════════════════════════════════════

  void _init() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        final newUid = user?.uid;
        if (newUid == _activeUid) return;

        // UID changed - stop any active listening and clear state
        if (_isListening) {
          _stopListeningInternal();
        }
        _clearState();
        _activeUid = newUid;
      },
      onError: (e) {
        AppLog.d('❌ NotificationListProvider._init auth error: $e');
      },
    );
  }

  void _clearState() {
    _notificationMap.clear();
    _orderedIds.clear();
    _lastDoc = null;
    _firstPageSize = 0;
    _hasMore = true;
    _isLoadingMore = false;
    _loadMoreError = false;
    _hasStreamError = false;
    _updateCachedList();
    _scheduleNotify();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAZY LISTENING (widget calls these in initState/dispose)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start listening to the notification stream for the given user.
  ///
  /// Call from widget's initState. Does nothing if already listening.
  void startListening(DocumentReference userRef) {
    if (_isListening) return;
    _currentUserRef = userRef;
    _isListening = true;
    _initFirstPageStream();
  }

  /// Stop listening to the notification stream.
  ///
  /// Call from widget's dispose. Safe to call multiple times.
  void stopListening() {
    _stopListeningInternal();
  }

  void _stopListeningInternal() {
    _firstPageSubscription?.cancel();
    _firstPageSubscription = null;
    _isListening = false;
    _currentUserRef = null;
  }

  void _initFirstPageStream() {
    final userRef = _currentUserRef;
    if (userRef == null) return;
    final uid = _activeUid;

    _firstPageSubscription?.cancel();
    _firstPageSubscription = _service
        .streamNotifications(userRef: userRef, limit: _pageSize)
        .listen(
      (snapshot) {
        if (_disposed || _activeUid != uid) return;
        _handleFirstPageUpdate(snapshot);
      },
      onError: (e) {
        if (_disposed || _activeUid != uid) return;
        _hasStreamError = true;
        _scheduleNotify();
        AppLog.d('❌ NotificationListProvider stream error: $e');
      },
    );
  }

  void _handleFirstPageUpdate(QuerySnapshot snapshot) {
    final newFirstPageIds = <String>{};
    final newDocs = <String, NotificationListItem>{};

    for (final doc in snapshot.docs) {
      final item = NotificationListItem.fromDoc(doc);
      newDocs[item.id] = item;
      newFirstPageIds.add(item.id);
    }

    // Detect material change - reset cursor if first page changed significantly
    final sizeChanged = snapshot.docs.length != _firstPageSize;
    final currentFirstPageIds = _orderedIds.take(_firstPageSize).toSet();
    final idsChanged = !_setEquals(newFirstPageIds, currentFirstPageIds);

    if (sizeChanged || idsChanged) {
      // First page changed materially - reset load-more state
      _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _firstPageSize = snapshot.docs.length;
      _hasMore = snapshot.docs.length >= _pageSize;

      // Clear all items and rebuild from first page only
      _notificationMap.clear();
      _orderedIds.clear();
    }

    // Merge new first page items (deduped by map key)
    _notificationMap.addAll(newDocs);

    // Rebuild ordered list: first page IDs + any load-more IDs not in first page
    final loadMoreIds = _orderedIds
        .skip(_firstPageSize)
        .where((id) => !newFirstPageIds.contains(id));
    _orderedIds = [...newFirstPageIds, ...loadMoreIds];

    _hasStreamError = false;
    _updateCachedList();
    _scheduleNotify();
  }

  bool _setEquals<T>(Set<T> a, Set<T> b) {
    return a.length == b.length && a.difference(b).isEmpty;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGINATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load the next page of notifications.
  ///
  /// Does nothing if already loading, no more pages, or no cursor available.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDoc == null) return;
    final userRef = _currentUserRef;
    final uid = _activeUid;
    if (userRef == null || uid == null) return;

    _isLoadingMore = true;
    _scheduleNotify();

    try {
      final docs = await _service.fetchNotificationsPage(
        userRef: userRef,
        pageSize: _pageSize,
        startAfterDocument: _lastDoc,
      );

      if (_disposed || _activeUid != uid) return;

      for (final doc in docs) {
        final item = NotificationListItem.fromDoc(doc);
        if (!_notificationMap.containsKey(item.id)) {
          _notificationMap[item.id] = item;
          _orderedIds.add(item.id);
        }
      }

      if (docs.isNotEmpty) {
        _lastDoc = docs.last;
      }
      _hasMore = docs.length >= _pageSize;
      _isLoadingMore = false;
      _loadMoreError = false;
      _updateCachedList();
      _scheduleNotify();
    } catch (e) {
      if (_disposed || _activeUid != uid) return;
      _isLoadingMore = false;
      _loadMoreError = true;
      _scheduleNotify();
      AppLog.d('❌ NotificationListProvider.loadMore error: $e');
    }
  }

  /// Refresh the list by clearing load-more state.
  ///
  /// The first-page stream will auto-refresh. Returns after a brief delay
  /// for visual feedback.
  Future<void> refresh() async {
    final firstPageIds = _orderedIds.take(_firstPageSize).toSet();
    _notificationMap.removeWhere((id, _) => !firstPageIds.contains(id));
    _orderedIds = _orderedIds.take(_firstPageSize).toList();
    _loadMoreError = false;
    _hasMore = true;
    _updateCachedList();
    _scheduleNotify();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UNREAD COUNT STREAM (for badge - lightweight, separate from list)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream of unread notification count for the given user.
  ///
  /// Use in badge widgets with StreamBuilder. Separate from list stream.
  Stream<int> unreadCountStream(DocumentReference userRef) {
    return _service
        .streamUnreadNotifications(userRef)
        .map((snap) => snap.docs.length);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD OPERATIONS (delegate to service, update local state)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mark all notifications as read.
  ///
  /// Local state updates via stream after Firestore write completes.
  Future<void> markAllAsRead() async {
    final userRef = _currentUserRef;
    if (userRef == null) return;
    await _service.markAllAsRead(userRef);
  }

  /// Mark a notification as read if not already read.
  Future<void> markReadIfNeeded(NotificationListItem item) async {
    if (item.isRead) return;
    await _service.markReadIfNeeded(item.reference, false);
  }

  /// Mark a notification as unread.
  Future<void> markAsUnread(NotificationListItem item) async {
    await _service.markAsUnread(item.reference);
  }

  /// Delete a single notification.
  ///
  /// Optimistically removes from local state. Stream will restore if delete fails.
  Future<void> deleteNotification(NotificationListItem item) async {
    // Optimistic removal
    _notificationMap.remove(item.id);
    _orderedIds.remove(item.id);
    _updateCachedList();
    _scheduleNotify();

    try {
      await _service.deleteNotification(item.reference);
    } catch (e) {
      // Stream will restore if delete failed
      AppLog.d('❌ NotificationListProvider.deleteNotification error: $e');
      rethrow;
    }
  }

  /// Delete all notifications for the current user.
  ///
  /// Returns the count of deleted notifications.
  Future<int> deleteAllNotifications() async {
    final userRef = _currentUserRef;
    if (userRef == null) return 0;

    final count = await _service.deleteAllNotifications(userRef);
    _clearState();
    return count;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY (delegate to service)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Resolve a game DocumentReference from notification payload fields.
  DocumentReference? resolveGameRefFromPayload(Map<String, dynamic> payload) {
    return _service.resolveGameRefFromPayload(payload);
  }

  /// Check if a friends-only game should be blocked for the current user.
  Future<bool> shouldBlockFriendsOnlyGame(
    DocumentReference gameRef,
    DocumentReference currentUserRef,
  ) {
    return _service.shouldBlockFriendsOnlyGame(
      gameRef: gameRef,
      currentUserRef: currentUserRef,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEBOUNCE & DISPOSE
  // ═══════════════════════════════════════════════════════════════════════════

  void _scheduleNotify() {
    if (_disposed) return;
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 50), () {
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _notifyTimer?.cancel();
    _firstPageSubscription?.cancel();
    _authSubscription?.cancel();
    _notificationMap.clear();
    _orderedIds.clear();
    super.dispose();
  }
}
